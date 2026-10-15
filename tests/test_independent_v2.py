# Copyright (c) 2026 ByteDance Ltd. and/or its affiliates
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Independent real-entry tests; synthetic tasks, no containers or model calls."""
from __future__ import annotations

import concurrent.futures
import contextlib
import json
import logging
import multiprocessing as mp
import os
import threading
import time
import types
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

from sforge.harness import judge_server as js
from sforge.harness import run_agent as ra
from sforge.harness.config import SForgeConfig, load_config


def task():
    return types.SimpleNamespace(task_id="t", judge=types.SimpleNamespace(
        selection="pass_rate_first", score_direction="maximize"))

def report(score=1.0):
    return types.SimpleNamespace(to_dict=lambda: {
        "valid": True, "pass_rate": 1.0, "score": score})

def wait_for(predicate, seconds=3):
    until = time.monotonic() + seconds
    while time.monotonic() < until:
        if predicate():
            return True
        time.sleep(0.005)
    return bool(predicate())

@pytest.fixture
def runtime(tmp_path, monkeypatch):
    release = threading.Event()
    entered = threading.Event()
    def judge(**kwargs):
        entered.set()
        assert release.wait(5), "synthetic judge was not released"
        return report()
    monkeypatch.setattr(js, "judge_submission", judge)
    monkeypatch.setattr(
        js,
        "create_backend_from_config",
        lambda cfg: types.SimpleNamespace(backend_name="synthetic"),
    )
    monkeypatch.setattr(js, "load_benchmark", lambda *args: None)
    monkeypatch.setattr(js, "load_all_tasks", lambda *args: [task()])
    cfg = SForgeConfig(log_dir=tmp_path, judge_max_concurrency=1,
                       judge_max_backlog=1, judge_host_capacity=8)
    app = js.create_app(cfg)
    submit = next(r.endpoint for r in app.routes if r.path == "/api/v1/submit")
    import inspect
    state = inspect.getclosurevars(submit).nonlocals["state"]
    state.host_capacity = js.HostJudgeCapacity(8, str(tmp_path / "slots.json"))
    token = state.register_session("t", "r", max_agent_submissions=2,
                                   submission_cooldown=60)
    client = TestClient(app)
    yield state, client, token, release, entered
    release.set()
    assert wait_for(lambda: state._judge_queue.unfinished_tasks == 0)
    state._reaper_stop.set()
    for _ in state._judge_workers:
        state._judge_queue.put(None)
    for worker in state._judge_workers:
        worker.join(1)
    state._reaper_thread.join(1)
    client.close()

def post(client, state, token, kind="auto"):
    return client.post("/api/v1/submit", data={
        "token": token, "kind": kind, "admin_secret": state.admin_secret},
        files={"archive": ("synthetic.tar", b"synthetic", "application/octet-stream")})

def test_http_capacity_refusal_does_not_consume_round_or_cooldown(runtime):
    state, client, token, release, entered = runtime
    assert post(client, state, token).status_code == 200
    assert entered.wait(2)
    before = state.resolve_token(token)
    response = post(client, state, token)
    assert response.status_code == 429
    assert state.resolve_token(token) == before
    # Agent budget/cooldown still applies, independently of auto backlog.
    agent = post(client, state, token, "agent")
    assert agent.status_code == 200
    assert agent.json()["remaining_submissions"] == 1
    assert post(client, state, token, "agent").status_code == 429

def test_http_auto_admission_is_atomic_under_concurrent_arrivals(runtime, monkeypatch):
    state, client, token, release, entered = runtime
    gate = threading.Barrier(2)
    original = state.auto_capacity_available
    def pause_after_observation():
        available = original()
        # Let an unlocked peer observe the same snapshot, without requiring
        # a correctly serialized implementation to enter this probe twice.
        with contextlib.suppress(threading.BrokenBarrierError):
            gate.wait(timeout=0.2)
        return available
    monkeypatch.setattr(state, "auto_capacity_available", pause_after_observation)
    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
        responses = list(pool.map(lambda _: post(client, state, token), range(2)))
    codes = sorted(r.status_code for r in responses)
    assert codes == [200, 429], {
        "status_codes": codes,
        "accepted": len(state.submissions),
        "backlog_limit": state.judge_max_backlog,
        "next_auto": state.resolve_token(token)["next_auto"]}

def test_worker_pool_creation_is_atomic(runtime, monkeypatch):
    state, client, token, release, entered = runtime
    barrier = threading.Barrier(2)
    real_start = threading.Thread.start
    def paused_start(thread):
        if thread.name.startswith("sforge-judge-"):
            with contextlib.suppress(threading.BrokenBarrierError):
                barrier.wait(timeout=0.2)
        return real_start(thread)
    monkeypatch.setattr(threading.Thread, "start", paused_start)
    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
        list(pool.map(lambda i: state.submit("t", b"x", "r", f"auto-{i}"), range(2)))
    assert len(state._judge_workers) == 1, {
        "workers": len(state._judge_workers), "configured": 1}

def test_history_and_result_agree_while_waiting_for_a_host_slot(runtime):
    state, client, token, release, entered = runtime
    state.host_capacity.capacity = 1
    holder = f"{os.getpid()}:synthetic-blocker"
    assert state.host_capacity.try_acquire(holder)
    try:
        response = post(client, state, token)
        assert response.status_code == 200
        sid = response.json()["submission_id"]
        result = client.get(f"/api/v1/result/{sid}").json()
        history = client.get("/api/v1/history", params={
            "token": token, "admin_secret": state.admin_secret}).json()
        entry = next(e for e in history["entries"] if e["submission_id"] == sid)
        assert not entered.is_set()
        assert result["status"] == entry["status"] == "queued", {
            "result_status": result["status"], "history_status": entry["status"]}
    finally:
        state.host_capacity.release(holder)

def test_host_capacity_cannot_be_enlarged_by_a_second_launcher(tmp_path):
    path = str(tmp_path / "slots.json")
    small, large = js.HostJudgeCapacity(1, path), js.HostJudgeCapacity(2, path)
    a, b = f"{os.getpid()}:first", f"{os.getpid()}:second"
    assert small.try_acquire(a)
    try:
        try:
            accepted = large.try_acquire(b)
        except RuntimeError:
            accepted = False
        assert not accepted, "capacity=2 admitted over active shared capacity=1"
    finally:
        small.release(a)
        large.release(b)


def test_host_capacity_accounts_for_weighted_resource_units(tmp_path):
    capacity = js.HostJudgeCapacity(10, str(tmp_path / "capacity.json"))
    first = f"{os.getpid()}:first"
    second = f"{os.getpid()}:second"
    assert capacity.try_acquire(first, "docker:synthetic", units=7)
    try:
        assert not capacity.try_acquire(second, "docker:synthetic", units=4)
        assert capacity.try_acquire(second, "docker:synthetic", units=3)
    finally:
        capacity.release(first)
        capacity.release(second)


def test_single_slot_holder_remains_legacy_reader_compatible(tmp_path):
    path = tmp_path / "slots.json"
    capacity = js.HostJudgeCapacity(2, str(path))
    token = f"{os.getpid()}:owned"
    assert capacity.try_acquire(token, "docker:synthetic")
    try:
        holder = json.loads(path.read_text())["holders"][token]
        assert isinstance(holder, (int, float))
        owners = json.loads((tmp_path / "slots.json.owners").read_text())
        assert owners["owners"] == {token: "docker:synthetic"}
    finally:
        capacity.release(token)

def test_corrupt_slot_state_does_not_grant_new_capacity(tmp_path):
    path = tmp_path / "slots.json"
    slots = js.HostJudgeCapacity(1, str(path))
    a, b = f"{os.getpid()}:first", f"{os.getpid()}:second"
    assert slots.try_acquire(a)
    try:
        path.write_text('{"incomplete":')
        try:
            accepted = slots.try_acquire(b)
        except (ValueError, RuntimeError):
            accepted = False
        assert not accepted, "corrupt state was treated as an empty host"
    finally:
        # Test owns both synthetic holders and the private file.
        path.write_text("{}")

@pytest.mark.parametrize("mode", ["running", "poll_error", "completed", "error"])
def test_auto_loop_preserves_previous_until_terminal(tmp_path, monkeypatch, mode):
    stop = threading.Event()
    requests_seen, extracts, polls = [], [], []
    class Resp:
        def __init__(self, value): self.value = value
        def json(self): return self.value
        def raise_for_status(self): pass
    def send(url, **kwargs):
        requests_seen.append(url)
        if len(requests_seen) == 2:
            stop.set()
        return Resp({"submission_id": f"s{len(requests_seen)}", "round_id": "auto"})
    def get(url, **kwargs):
        polls.append(url)
        if mode not in ("completed", "error") and len(polls) >= 3:
            stop.set()
        if mode == "poll_error":
            raise ra.requests.Timeout("synthetic poll timeout")
        return Resp({"status": mode})
    monkeypatch.setattr(ra.requests, "post", send)
    monkeypatch.setattr(ra.requests, "get", get)
    monkeypatch.setattr(ra, "_extract_archive_from_container",
                        lambda *a, **kw: (extracts.append(1), b"x")[1])
    ra._auto_eval_loop(
        backend=None, handle=None, task_spec=None,
        host_judge_url="http://synthetic.invalid", session_token="synthetic",
        eval_interval=0, stop_event=stop, logger=logging.getLogger("test"),
        log_dir=tmp_path, admin_secret="synthetic")
    expected = 2 if mode in ("completed", "error") else 1
    assert len(requests_seen) == len(extracts) == expected
    assert polls and all(url.endswith("/s1") for url in polls)

def _host_process(path, ready, release, active, peak, completed, lock, root):
    from sforge.harness import judge_server as child
    child.create_backend_from_config = lambda cfg: types.SimpleNamespace(
        backend_name="synthetic"
    )
    def judge(**kwargs):
        with lock:
            active.value += 1
            peak.value = max(peak.value, active.value)
        time.sleep(0.08)
        with lock:
            active.value -= 1
            completed.value += 1
        return report()
    child.judge_submission = judge
    state = child.JudgeState(SForgeConfig(log_dir=Path(root),
        judge_max_concurrency=2, judge_host_capacity=2, judge_max_backlog=4))
    state.host_capacity = child.HostJudgeCapacity(2, path)
    state.tasks = {"t": task()}
    ready.put(os.getpid())
    assert release.wait(4)
    for i in range(3):
        state.submit("t", b"x", f"r{os.getpid()}", f"auto-{i}")
    assert wait_for(lambda: state._judge_queue.unfinished_tasks == 0, 6)
    state._reaper_stop.set()

def test_two_real_states_share_simultaneous_capacity(tmp_path):
    ctx = mp.get_context("spawn")
    ready, release = ctx.Queue(), ctx.Event()
    active, peak, completed = ctx.Value("i", 0), ctx.Value("i", 0), ctx.Value("i", 0)
    lock = ctx.Lock()
    processes = [ctx.Process(target=_host_process, args=(
        str(tmp_path/"slots.json"), ready, release, active, peak, completed, lock,
        str(tmp_path/f"p{i}"))) for i in range(2)]
    try:
        for p in processes: p.start()
        assert len({ready.get(timeout=3) for _ in processes}) == 2
        release.set()
        for p in processes: p.join(8)
        assert all(p.exitcode == 0 for p in processes)
        assert completed.value == 6
        assert 1 <= peak.value <= 2
    finally:
        release.set()
        for p in processes:
            if p.is_alive(): p.terminate()
            p.join(2)


def test_slot_path_is_resolved_at_runtime(tmp_path, monkeypatch):
    path = tmp_path / "local-slots.json"
    monkeypatch.setenv("SFORGE_JUDGE_HOST_SLOT_FILE", str(path))
    assert js.HostJudgeCapacity(1).path == path


@pytest.mark.parametrize("content", ['[]', '{}', '{"version":1,"capacity":1,"holders":[]}'])
def test_invalid_slot_shape_is_rejected(tmp_path, content):
    path = tmp_path / "slots.json"
    path.write_text(content)
    with pytest.raises(RuntimeError):
        js.HostJudgeCapacity(1, str(path)).try_acquire("synthetic-holder")
    assert path.read_text() == content


def _reserve_and_exit(path):
    assert js.HostJudgeCapacity(1, path).try_acquire(f"{os.getpid()}:orphan")


def _reserve_owned_and_exit(path):
    assert js.HostJudgeCapacity(1, path).try_acquire(
        f"{os.getpid()}:orphan", "synthetic:engine"
    )


def test_dead_launcher_requires_cleanup_evidence_before_reclaim(tmp_path):
    path = str(tmp_path / "slots.json")
    ctx = mp.get_context("spawn")
    process = ctx.Process(target=_reserve_and_exit, args=(path,))
    process.start()
    process.join(4)
    try:
        assert process.exitcode == 0
        slots = js.HostJudgeCapacity(1, path)
        assert not slots.try_acquire(f"{os.getpid()}:next")
        observed = []
        assert slots.reconcile_stale_holders(
            lambda token, _owner_id: observed.append(token) is None and False
        ) == []
        assert observed == [f"{process.pid}:orphan"]
        assert not slots.try_acquire(f"{os.getpid()}:next")
        assert slots.reconcile_stale_holders(lambda _token, _owner_id: True) == [
            f"{process.pid}:orphan"
        ]
        assert slots.try_acquire(f"{os.getpid()}:next")
    finally:
        if process.is_alive():
            process.terminate()
        process.join(2)


def test_live_capacity_owner_is_never_reconciled(tmp_path):
    slots = js.HostJudgeCapacity(1, str(tmp_path / "slots.json"))
    token = f"{os.getpid()}:live"
    assert slots.try_acquire(token)
    cleanup_calls = []
    try:
        assert slots.reconcile_stale_holders(
            lambda token, _owner_id: cleanup_calls.append(token)
        ) == []
        assert cleanup_calls == []
        assert not slots.try_acquire(f"{os.getpid()}:other")
    finally:
        slots.release(token)


def test_state_startup_reconciles_backend_owned_dead_holder(tmp_path, monkeypatch):
    path = str(tmp_path / "slots.json")
    ctx = mp.get_context("spawn")
    process = ctx.Process(target=_reserve_owned_and_exit, args=(path,))
    process.start()
    process.join(4)
    assert process.exitcode == 0
    monkeypatch.setenv("SFORGE_JUDGE_HOST_SLOT_FILE", path)
    monkeypatch.setenv("SFORGE_JUDGE_HOST_OWNER_FILE", path + ".owners")
    cleaned = []

    class Backend:
        backend_name = "synthetic"

        def reconcile_judge_capacity_holder(self, token, owner_id):
            cleaned.append((token, owner_id))
            return owner_id == "synthetic:engine"

    state = js.JudgeState(
        SForgeConfig(log_dir=tmp_path, judge_host_capacity=1),
        backend_factory=lambda _config: Backend(),
    )
    try:
        assert cleaned == [(f"{process.pid}:orphan", "synthetic:engine")]
        replacement = f"{os.getpid()}:replacement"
        assert state.host_capacity.try_acquire(replacement)
        state.host_capacity.release(replacement)
    finally:
        state._reaper_stop.set()
        state._reaper_thread.join(2)


def test_judge_memory_budget_uses_declared_limit_and_serializes_unknown(
    tmp_path, monkeypatch,
):
    monkeypatch.setenv("SFORGE_JUDGE_HOST_SLOT_FILE", str(tmp_path / "slots.json"))
    monkeypatch.setenv("SFORGE_JUDGE_HOST_MEMORY_FILE", str(tmp_path / "memory.json"))
    backend = types.SimpleNamespace(backend_name="synthetic")
    state = js.JudgeState(
        SForgeConfig(
            log_dir=tmp_path,
            judge_host_capacity=2,
            judge_host_memory_capacity="10g",
        ),
        backend_factory=lambda _config: backend,
    )
    state.tasks = {
        "declared": types.SimpleNamespace(
            task_id="declared", judge=types.SimpleNamespace(mem_limit="3g")
        ),
        "unknown": types.SimpleNamespace(
            task_id="unknown", judge=types.SimpleNamespace(mem_limit=None)
        ),
    }
    try:
        assert state._judge_memory_requirement("declared", None) == 3 * 1024**3
        assert state._judge_memory_requirement("unknown", None) == 10 * 1024**3
        with pytest.raises(RuntimeError, match="exceeds host memory capacity"):
            state._judge_memory_requirement("declared", "11g")
    finally:
        state._reaper_stop.set()
        state._reaper_thread.join(2)


def test_capacity_read_error_is_terminal_and_worker_recovers(runtime):
    state, client, token, release, entered = runtime
    state.host_capacity.path.write_text("{corrupt")
    sid = post(client, state, token).json()["submission_id"]
    assert wait_for(lambda: state.get_result(sid)["status"] == "error")
    assert not entered.is_set()
    error = state.get_result(sid)["error"]
    assert error and state.get_run_history("r", "t")["entries"][0]["error"] == error
    state.host_capacity.path.write_text(json.dumps({"version": 1, "capacity": 8, "holders": {}}))
    second = post(client, state, token).json()["submission_id"]
    assert entered.wait(2)
    release.set()
    assert wait_for(lambda: state.get_result(second)["status"] == "completed")


def test_cancelled_capacity_wait_never_starts_judge(runtime):
    state, client, token, release, entered = runtime
    state.host_capacity.capacity = 1
    holder = f"{os.getpid()}:blocker"
    assert state.host_capacity.try_acquire(holder)
    try:
        state._judge_queue_drained.set()
        sid = post(client, state, token).json()["submission_id"]
        assert wait_for(lambda: state.get_result(sid)["status"] == "error")
        assert not entered.is_set()
        assert not state.host_capacity.try_acquire(f"{os.getpid()}:extra")
    finally:
        state.host_capacity.release(holder)


def test_drain_and_official_selection_retain_auto_and_agent(runtime, monkeypatch):
    state, client, token, release, entered = runtime
    first = post(client, state, token).json()["submission_id"]
    assert entered.wait(2)
    second = post(client, state, token, "agent").json()["submission_id"]
    monkeypatch.setattr(ra.requests, "get", lambda url, **kw:
                        client.get("/api/v1/history", params=kw["params"]))
    stop = threading.Event()
    stop.set()
    pending = ra._wait_for_grading("http://synthetic.invalid", token, state.admin_secret,
        eval_timeout=0, shutdown_event=stop, logger=logging.getLogger("test"))
    assert pending.status == "pending" and pending.pending_submissions == 2
    release.set()
    assert wait_for(lambda: state._judge_queue.unfinished_tasks == 0)
    drained = ra._wait_for_grading("http://synthetic.invalid", token, state.admin_secret,
        eval_timeout=0, shutdown_event=None, logger=logging.getLogger("test"))
    assert drained.status == "complete" and drained.reason == "drained"
    assert drained.pending_submissions == 0
    history = drained.history
    assert {entry["submission_id"] for entry in history["entries"]} == {first, second}
    assert all(entry["status"] == "completed" for entry in history["entries"])
    assert history["agent_submissions"] == history["auto_submissions"] == 1
    expected = js.select_best(history["entries"], "maximize", "pass_rate_first")
    assert all(history[key] == expected[key] for key in ("best_score", "best_pass_rate", "best_round"))


def test_real_configuration_accepts_caps_and_rejects_invalid_values(monkeypatch):
    monkeypatch.setenv("SFORGE_JUDGE_MAX_CONCURRENCY", "2")
    monkeypatch.setenv("SFORGE_JUDGE_MAX_BACKLOG", "3")
    monkeypatch.setenv("SFORGE_JUDGE_HOST_CAPACITY", "4")
    monkeypatch.setenv("SFORGE_JUDGE_HOST_MEMORY_CAPACITY", "24g")
    cfg = load_config()
    assert (
        cfg.judge_max_concurrency,
        cfg.judge_max_backlog,
        cfg.judge_host_capacity,
        cfg.judge_host_memory_capacity,
    ) == (2, 3, 4, "24g")
    for invalid in ("abc", "0", "-1"):
        monkeypatch.setenv("SFORGE_JUDGE_HOST_CAPACITY", invalid)
        with pytest.raises(ValueError):
            load_config()
