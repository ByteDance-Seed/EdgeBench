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

"""Native judge/runner acceptance over loopback TCP, with synthetic grading only."""

from __future__ import annotations

import concurrent.futures
import hashlib
import inspect
import io
import json
import logging
import socket
import tarfile
import threading
import time
from types import SimpleNamespace

import pytest
import requests
import uvicorn

from sforge.harness import judge_server as judge
from sforge.harness import run_agent as runner
from sforge.harness.config import SForgeConfig
from sforge.harness.task_spec import JudgeSpec, TaskSpec, WorkSpec
from test_run_agent_grading import Backend, SyntheticAgent


def wait_until(predicate, timeout=5):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if predicate():
            return
        time.sleep(0.01)
    assert predicate(), "synthetic acceptance condition timed out"


def payload(score=80, pass_rate=0.5, valid=True, error=False):
    return json.dumps(dict(score=score, pass_rate=pass_rate,
                           valid=valid, error=error)).encode()


@pytest.fixture
def live_judge(tmp_path, monkeypatch):
    release = threading.Event()
    lock = threading.Lock()
    probe = SimpleNamespace(active=0, peak=0, started=[], paths=[], on_request=None)
    task = TaskSpec(
        task_id="tcp-fixture", name="TCP fixture", base_image="python",
        platform="linux/amd64", cwd="/workspace", submit_paths=["solution"],
        submit_exclude=[], work=WorkSpec("", "Synthetic task", image_tag="fixture"),
        judge=JudgeSpec("true", 1, "pytest", image_tag="fixture", selection="score_first"),
    )

    def grade(**kwargs):
        sample = json.loads(kwargs["archive"])
        with lock:
            probe.started.append(kwargs["submission_id"])
            probe.active += 1
            probe.peak = max(probe.peak, probe.active)
        try:
            assert release.wait(25), "synthetic grading was never released"
            if sample.pop("error"):
                raise RuntimeError("synthetic grading failure")
            return SimpleNamespace(to_dict=lambda: sample)
        finally:
            with lock:
                probe.active -= 1

    monkeypatch.setenv("NO_PROXY", "127.0.0.1,localhost")
    monkeypatch.setenv("no_proxy", "127.0.0.1,localhost")
    monkeypatch.setattr(judge, "judge_submission", grade)
    monkeypatch.setattr(
        judge,
        "create_backend_from_config",
        lambda _: SimpleNamespace(backend_name="synthetic"),
    )
    monkeypatch.setattr(judge, "load_benchmark", lambda *_: None)
    monkeypatch.setattr(judge, "load_all_tasks", lambda *_: [task])
    monkeypatch.setattr(judge, "get_admin_secret", lambda _: "synthetic-admin")
    config = SForgeConfig(log_dir=tmp_path, judge_max_concurrency=1,
                           judge_host_capacity=1, judge_max_backlog=2)
    app = judge.create_app(config)
    endpoint = next(r.endpoint for r in app.routes if r.path == "/api/v1/submit")
    state = inspect.getclosurevars(endpoint).nonlocals["state"]
    state.host_capacity = judge.HostJudgeCapacity(1, str(tmp_path / "slots.json"))

    @app.middleware("http")
    async def observe(request, call_next):
        response = await call_next(request)
        probe.paths.append((request.method, request.url.path, response.status_code))
        if probe.on_request is not None:
            probe.on_request(request.url.path, response.status_code)
        return response

    sock = socket.socket()
    sock.bind(("127.0.0.1", 0))
    server = uvicorn.Server(uvicorn.Config(app, log_level="error", access_log=False,
                                            lifespan="off", ws="none"))
    worker = threading.Thread(target=server.run, kwargs={"sockets": [sock]}, daemon=True)
    worker.start()
    url = f"http://127.0.0.1:{sock.getsockname()[1]}"
    wait_until(lambda: server.started)
    runtime = SimpleNamespace(url=url, state=state, task=task, config=config,
                              release=release, probe=probe, root=tmp_path)
    try:
        yield runtime
    finally:
        release.set()
        wait_until(lambda: state._judge_queue.unfinished_tasks == 0)
        state._reaper_stop.set()
        for _ in state._judge_workers:
            state._judge_queue.put(None)
        for grading_worker in state._judge_workers:
            grading_worker.join(3)
            assert not grading_worker.is_alive()
        state._reaper_thread.join(3)
        server.should_exit = True
        worker.join(3)
        sock.close()
        assert not worker.is_alive() and not state._reaper_thread.is_alive()
        if state.host_capacity.path.exists():
            assert json.loads(state.host_capacity.path.read_text())["holders"] == {}


def register(rt, **limits):
    response = requests.post(rt.url + "/api/v1/register", json={
        "task_id": rt.task.task_id, "run_id": "tcp-run",
        "admin_secret": "synthetic-admin", **limits}, timeout=5)
    response.raise_for_status()
    return response.json()["token"]


def submit(rt, token, kind="auto", archive=None):
    return requests.post(rt.url + "/api/v1/submit", data={
        "token": token, "kind": kind, "admin_secret": "synthetic-admin"},
        files={"archive": ("synthetic.tar", archive or payload())}, timeout=5)


def history(rt, token, admin=True):
    response = requests.get(rt.url + "/api/v1/history", params={
        "token": token, "admin_secret": "synthetic-admin" if admin else ""}, timeout=5)
    response.raise_for_status()
    return response.json()


def drain(rt, token, shutdown_event=None):
    return runner._wait_for_grading(rt.url, token, "synthetic-admin", eval_timeout=1,
                                   shutdown_event=shutdown_event,
                                   logger=logging.getLogger("tcp-acceptance"))


def test_tcp_concurrent_admission_rounds_cooldown_and_last_agent(live_judge):
    rt = live_judge
    token = register(rt, max_agent_submissions=2, submission_cooldown=60)
    barrier = threading.Barrier(6)

    def arrive(_):
        barrier.wait(timeout=5)
        return submit(rt, token)

    with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:
        responses = list(pool.map(arrive, range(6)))
    assert sorted(r.status_code for r in responses) == [200, 200, 429, 429, 429, 429]
    info = rt.state.resolve_token(token)
    assert (info["next_auto"], info["next_agent"], info["last_agent_submit_at"]) == (3, 1, 0)
    wait_until(lambda: len(rt.probe.started) == 1)
    full = history(rt, token)
    assert sorted(e["status"] for e in full["entries"]) == ["queued", "running"]
    assert all("score" not in entry for entry in full["entries"])
    # Probe before adding the agent submission: queued-only counting would
    # incorrectly admit a third auto while the first grader is still running.
    before_auto = rt.state.resolve_token(token)
    assert submit(rt, token).status_code == 429
    assert rt.state.resolve_token(token) == before_auto
    final = submit(rt, token, "agent", payload(12, 1.0))
    assert final.status_code == 200 and final.json()["round_id"] == "agent-1"
    assert final.json()["remaining_submissions"] == 1
    before = rt.state.resolve_token(token)
    assert submit(rt, token, "agent").status_code == 429
    assert submit(rt, token).status_code == 429
    assert rt.state.resolve_token(token) == before

    stopped = threading.Event()
    stopped.set()
    pending = drain(rt, token, stopped)
    assert pending.status == "pending" and pending.pending_submissions == 3
    assert pending.history["best_score"] is None
    assert all("score" not in entry for entry in pending.history["entries"])
    runner._write_grading(rt.root, "pending.json", pending, "tcp-run")
    sidecar = json.loads((rt.root / "grading_status.json").read_text())
    assert sidecar["status"] == "pending" and sidecar["pending_submissions"] == 3

    # The real drain polls while accepted grading is still in progress.
    timer = threading.Timer(0.1, rt.release.set)
    timer.start()
    try:
        complete = drain(rt, token)
    finally:
        timer.join(2)
    assert complete.status == "complete" and complete.reason == "drained"
    assert complete.pending_submissions == 0 and rt.probe.peak == 1
    assert len(complete.history["entries"]) == 3
    assert all(e["status"] == "completed" for e in complete.history["entries"])
    assert complete.history["best_score"] == 80
    assert history(rt, token, admin=False)["best_score"] == 12
    assert history(rt, token, admin=False)["auto_submissions"] == 0


@pytest.mark.parametrize("terminal", ["completed", "error", "stop_pending"])
def test_tcp_auto_producer_waits_for_terminal_and_hands_off_on_stop(live_judge, monkeypatch, terminal):
    rt = live_judge
    token = register(rt)
    stop = threading.Event()
    extracts = []
    polls = []

    def extract(*_args, **_kwargs):
        extracts.append(1)
        return payload(error=terminal == "error")

    def observed(path, status):
        if path.startswith("/api/v1/result/"):
            polls.append(path)
            if len(polls) == 3:
                if terminal == "stop_pending":
                    stop.set()
                else:
                    rt.release.set()
        if path == "/api/v1/submit" and status == 200 and len(extracts) == 2:
            stop.set()

    rt.probe.on_request = observed
    monkeypatch.setattr(runner, "_extract_archive_from_container", extract)
    producer = threading.Thread(target=runner._auto_eval_loop, kwargs=dict(
        backend=None, handle=None, task_spec=rt.task, host_judge_url=rt.url,
        session_token=token, eval_interval=0, stop_event=stop,
        logger=logging.getLogger("tcp-acceptance"), log_dir=rt.root,
        admin_secret="synthetic-admin"), daemon=True)
    producer.start()
    try:
        producer.join(5)
        assert not producer.is_alive()
        assert len(polls) >= 3 and len(set(polls)) == 1
        assert len(extracts) == (1 if terminal == "stop_pending" else 2)
        full = history(rt, token)
        assert full["auto_submissions"] == len(extracts)
        if terminal == "stop_pending":
            assert full["entries"][0]["status"] in ("queued", "running")
            assert "score" not in full["entries"][0]
            assert drain(rt, token, stop).status == "pending"
        rt.release.set()
        wait_until(lambda: rt.state._judge_queue.unfinished_tasks == 0)
        complete = drain(rt, token)
        assert complete.status == "complete"
        assert len(complete.history["entries"]) == len(extracts)
        assert rt.probe.peak == 1
        if terminal == "error":
            assert complete.history["best_score"] is None
            assert all(e["status"] == "error" and e["error"] == "synthetic grading failure"
                       and "score" not in e for e in complete.history["entries"])
    finally:
        stop.set()
        rt.release.set()
        producer.join(3)
        assert not producer.is_alive()


@pytest.mark.parametrize("policy,direction,score,round_id", [
    ("score_first", "maximize", 1000, "agent-2"),
    ("score_first", "minimize", 12, "agent-1"),
    ("pass_rate_first", "maximize", 1000, "agent-2"),
    ("pass_rate_first", "minimize", 12, "agent-1"),
    ("valid_then_score", "maximize", 80, "auto-1"),
    ("valid_then_score", "minimize", 12, "agent-1"),
])
def test_tcp_task_selection_policy_is_preserved(live_judge, policy, direction, score, round_id):
    rt = live_judge
    rt.task.judge.selection = policy
    rt.task.judge.score_direction = direction
    token = register(rt)
    for kind, archive in [("auto", payload()), ("agent", payload(12, 1.0)),
                          ("agent", payload(1000, 1.0, valid=False))]:
        assert submit(rt, token, kind, archive).status_code == 200
    rt.release.set()
    wait_until(lambda: rt.state._judge_queue.unfinished_tasks == 0)
    result = drain(rt, token)
    assert (result.history["best_score"], result.history["best_round"]) == (score, round_id)
    assert (result.history["agent_submissions"], result.history["auto_submissions"]) == (2, 1)


@pytest.mark.parametrize("code,observed,timed_out,execution_status", [
    (0, True, False, "normal_exit"),
    (7, True, False, "nonzero_exit"),
    (0, None, False, "unknown"),
    (-1, True, True, "timed_out"),
])
def test_native_runner_preserves_final_archive_and_judge_selection(
    live_judge, monkeypatch, code, observed, timed_out, execution_status,
):
    rt = live_judge
    final_archive = b"synthetic-final-archive"
    monkeypatch.setattr(runner, "get_admin_secret", lambda _: "synthetic-admin")
    monkeypatch.setattr(runner, "_build_agent_env", lambda *_: {})

    class WorkBackend(Backend):
        def exec_run_with_timeout(self, *args, **kwargs):
            result = super().exec_run_with_timeout(*args, **kwargs)
            if kwargs.get("log_file") is not None:
                result.exit_code = code
                result.terminal_observed = observed
                result.native_exit_code = (143 if timed_out else code) if observed else None
                result.timed_out = timed_out
            return result

        def create_container(self, *args, **kwargs):
            self.token = kwargs["environment"]["SFORGE_TOKEN"]
            return super().create_container(*args, **kwargs)

        def copy_from_container(self, *_args, **_kwargs):
            wrapped = io.BytesIO()
            with tarfile.open(fileobj=wrapped, mode="w") as archive:
                member = tarfile.TarInfo("archive.tar.gz")
                member.size = len(final_archive)
                archive.addfile(member, io.BytesIO(final_archive))
            return wrapped.getvalue()

    backend = WorkBackend(time)

    def solver_finished():
        assert submit(rt, backend.token).status_code == 200
        assert submit(rt, backend.token, "agent", payload(12, 1.0)).status_code == 200
        rt.release.set()
        wait_until(lambda: rt.state._judge_queue.unfinished_tasks == 0)

    backend.before_solver_return = solver_finished
    result = runner.run_agent(rt.task, SyntheticAgent(rt.config), rt.config,
        backend, "tcp-run", timeout=5, judge_url=rt.url,
        disable_auto_eval=True, disable_stop_hook=True, disable_auto_resume=True)
    assert (result.best_score, result.best_round) == (80, "auto-1")
    assert result.grading_status == "complete" and result.archive == final_archive
    assert (result.agent_submissions, result.auto_submissions) == (1, 1)
    assert backend.solver_calls == 1 and backend.cleaned_at is not None
    folder = rt.root / "runs" / "tcp-run" / rt.task.task_id
    assert (folder / "final_archive.tar.gz").read_bytes() == final_archive
    sidecar = json.loads((folder / "grading_status.json").read_text())
    assert sidecar["history_sha256"] == hashlib.sha256((folder / "run_history.json").read_bytes()).hexdigest()
    assert sidecar["pending_submissions"] == 0
    # A complete score must not erase a nonzero, unknown or timed-out solver
    # outcome; likewise, recording exit evidence must not change selection.
    execution = json.loads((folder / "solver_execution.json").read_text())
    assert result.solver_execution == execution
    assert execution["status"] == execution["segments"][0]["status"] == execution_status
    assert len(execution["segments"]) == 1
    assert execution["segments"][0]["terminal_observed"] is observed
    assert execution["segments"][0]["returned_exit_code"] == code
    assert execution["segments"][0]["termination_signal"] is None
    # Preserve official semantics: archiving does not silently add another evaluation.
    assert sum(path == "/api/v1/submit" for _, path, _ in rt.probe.paths) == 2
