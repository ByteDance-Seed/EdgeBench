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

"""Run/task admission isolation using synthetic evaluations, never containers."""
from __future__ import annotations

import hashlib
import socket
import subprocess
import sys
import threading
import time
from concurrent.futures import ThreadPoolExecutor
from types import SimpleNamespace

import pytest
import requests
import uvicorn

from sforge import cli
from sforge.harness import judge_server as js
from sforge.harness.config import SForgeConfig, load_config


def task():
    return SimpleNamespace(judge=SimpleNamespace(selection="pass_rate_first", score_direction="maximize"))


def report(**kw):
    return SimpleNamespace(to_dict=lambda: {
        "score": 7, "pass_rate": 1, "submission_id": kw["submission_id"],
        "source_sha256": hashlib.sha256(kw["archive"]).hexdigest(),
        "submitted_at": kw["submitted_at"],
    })


@pytest.fixture
def make_judge(tmp_path, monkeypatch):
    monkeypatch.setattr(js, "create_backend_from_config", lambda _: object())
    monkeypatch.setattr(js, "judge_submission", report)
    states = []
    def make(**overrides):
        config = dict(log_dir=tmp_path / str(len(states)), judge_max_concurrent=1,
                      judge_max_pending=8, judge_max_outstanding_per_run=1)
        state = js.JudgeState(SForgeConfig(**(config | overrides)))
        state.tasks.update(test=task(), other=task())
        states.append(state)
        return state
    yield make
    for state in states:
        state.close()


def test_simultaneous_tokens_kinds_and_direct_calls_share_key(make_judge, monkeypatch):
    state = make_judge()
    release = threading.Event()
    def grade(**kw):
        assert release.wait(10)
        return report(**kw)
    monkeypatch.setattr(js, "judge_submission", grade)
    tokens = [state.register_session("test", "run") for _ in range(10)]
    def submit(n):
        try:
            if n < 10:
                return state.submit_for_token(tokens[n], b"source", "agent" if n % 2 else "auto")[0]
            return state.submit("test", b"source", "run", "host")
        except js.JudgeCapacityExceeded:
            return None
    try:
        with ThreadPoolExecutor(max_workers=12) as pool:
            results = list(pool.map(submit, range(12)))
        assert sum(sid is not None for sid in results) == 1
        assert state._outstanding_by_run == {("run", "test"): 1}
        sid = next(sid for sid in results if sid)
        before = [state.resolve_token(token) for token in tokens]
        outstanding = dict(state._outstanding_by_run)
        for _ in range(3):
            state.get_result(sid)
            state.get_run_history("run", "test")
        assert [state.resolve_token(token) for token in tokens] == before
        assert state._outstanding_by_run == outstanding
        # Distinct tasks and runs have separate keys; absent run IDs stay aggregate-only.
        state.submit("other", b"other-task", "run")
        state.submit("test", b"other-run", "another")
        state.submit("test", b"anonymous-one")
        state.submit("test", b"anonymous-two")
        assert len(state._outstanding_by_run) == 3
    finally:
        release.set()
    state.close()
    assert state._outstanding_by_run == {}
    assert state.get_result(sid)["report"]["source_sha256"] == hashlib.sha256(b"source").hexdigest()


def test_limit_above_one_and_aggregate_rejection_do_not_leak(make_judge, monkeypatch):
    state = make_judge(judge_max_outstanding_per_run=2, judge_max_pending=1)
    release = threading.Event()
    def grade(**kw):
        assert release.wait(10)
        return report(**kw)
    monkeypatch.setattr(js, "judge_submission", grade)
    try:
        state.submit("test", b"one", "run")
        state.submit("test", b"two", "run")
        with pytest.raises(js.JudgeCapacityExceeded):
            state.submit("test", b"three", "run")
        with pytest.raises(js.JudgeCapacityExceeded):
            state.submit("test", b"global-full", "another")
        assert state._outstanding_by_run == {("run", "test"): 2}
    finally:
        release.set()
    state._executor.submit(lambda: None).result(timeout=5)
    sid = state.submit("test", b"retry", "another")
    state.close()
    assert state.get_result(sid)["status"] == js.SubmissionStatus.COMPLETED
    assert state._outstanding_by_run == {}


def test_queued_work_blocks_reregistration_before_spool_or_spend(make_judge, monkeypatch):
    state = make_judge()
    entered, release = threading.Event(), threading.Event()
    def grade(**kw):
        entered.set()
        assert release.wait(10)
        return report(**kw)
    monkeypatch.setattr(js, "judge_submission", grade)
    try:
        state.submit("test", b"occupy-worker", "another")
        assert entered.wait(2)
        queued = state.submit("test", b"queued", "run", "host")
        assert state.get_result(queued)["status"] == js.SubmissionStatus.QUEUED
        token = state.register_session("test", "run", max_agent_submissions=1, submission_cooldown=3600)
        before = state.resolve_token(token)
        spools = sorted(state.config.log_dir.joinpath("judge-pending").iterdir())
        for kind in ("agent", "auto"):
            with pytest.raises(js.JudgeCapacityExceeded):
                state.submit_for_token(token, b"rejected", kind)
        with pytest.raises(js.JudgeCapacityExceeded):
            state.submit("test", b"rejected", "run")
        assert state.resolve_token(token) == before
        assert sorted(state.config.log_dir.joinpath("judge-pending").iterdir()) == spools
        assert len(state.submissions) == 2
    finally:
        release.set()
    state.close()
    assert state._outstanding_by_run == {}
    assert not list(state.config.log_dir.joinpath("judge-pending").iterdir())
    with pytest.raises(js.JudgeCapacityExceeded):
        state.submit("test", b"closed", "run")


@pytest.mark.parametrize("failure", ["spool", "budget", "cooldown", "dispatch", "history"])
def test_synchronous_failure_releases_both_reservations(make_judge, monkeypatch, failure):
    state = make_judge(judge_max_pending=0)
    token = state.register_session("test", "run", max_agent_submissions=0 if failure == "budget" else 3)
    if failure == "cooldown":
        state.tokens[token].update(submission_cooldown=3600, last_agent_submit_at=time.time())
    before = state.resolve_token(token)
    def fail(*args, **kwargs):
        raise OSError("synthetic failure")
    with monkeypatch.context() as patch:
        if failure == "spool":
            patch.setattr(state, "_spool", fail)
        elif failure == "dispatch":
            patch.setattr(state._executor, "submit", fail)
        elif failure == "history":
            patch.setattr(state, "_record_submission", fail)
        expected = js.SubmissionBudgetExceeded if failure == "budget" else (
            js.SubmissionCooldownActive if failure == "cooldown" else OSError)
        with pytest.raises(expected):
            state.submit_for_token(token, b"source", "agent")
    assert state._outstanding_by_run == {}
    assert not list(state.config.log_dir.joinpath("judge-pending").glob("*"))
    if failure in ("dispatch", "history"):
        assert state.resolve_token(token)["next_agent"] == 2  # Accepted rounds are not refunded.
        assert all(row["status"] == js.SubmissionStatus.ERROR for row in state.submissions.values())
    else:
        assert state.resolve_token(token) == before
    sid = state.submit("test", b"recovered", "run")
    state.close()
    assert state.get_result(sid)["status"] == js.SubmissionStatus.COMPLETED


@pytest.mark.parametrize("failure", ["read", "evaluate", "unlink"])
def test_worker_failure_releases_key_and_allows_next_source(make_judge, monkeypatch, failure):
    from pathlib import Path
    state = make_judge(judge_max_pending=0)
    original_read, original_unlink = Path.read_bytes, Path.unlink
    def fail_read(path):
        if path.parent.name == "judge-pending":
            raise OSError("synthetic spool read failure")
        return original_read(path)
    def fail_unlink(path, *args, **kwargs):
        if path.parent.name == "judge-pending":
            raise OSError("synthetic cleanup failure")
        return original_unlink(path, *args, **kwargs)
    def fail_grade(**kw):
        raise RuntimeError("synthetic evaluator failure")
    with monkeypatch.context() as patch:
        if failure == "read":
            patch.setattr(Path, "read_bytes", fail_read)
        elif failure == "evaluate":
            patch.setattr(js, "judge_submission", fail_grade)
        else:
            patch.setattr(Path, "unlink", fail_unlink)
        sid = state.submit("test", b"first", "run")
        state._executor.submit(lambda: None).result(timeout=5)
        assert state._outstanding_by_run == {}
        assert state.get_result(sid)["status"] == (
            js.SubmissionStatus.COMPLETED if failure == "unlink" else js.SubmissionStatus.ERROR)
    for spool in state.config.log_dir.joinpath("judge-pending").iterdir():
        spool.unlink()
    next_sid = state.submit("test", b"second", "run")
    state.close()
    assert state.get_result(next_sid)["report"]["source_sha256"] == hashlib.sha256(b"second").hexdigest()
    assert state._outstanding_by_run == {}


@pytest.mark.parametrize("limit,second_status,first_accepted", [(None, 200, 8), (1, 503, 9)])
def test_nine_run_overlap_on_real_http(tmp_path, monkeypatch, limit, second_status, first_accepted):
    """Controlled clock + synthetic grader proves admission, not real load or elapsed-hour readiness."""
    monkeypatch.setattr(js, "create_backend_from_config", lambda _: object())
    monkeypatch.setattr(js.JudgeState, "load_tasks", lambda self: self.tasks.update(test=task()))
    clock = [10000.0]
    monkeypatch.setattr(js, "time", SimpleNamespace(time=lambda: clock[0]))
    release = threading.Event()
    def grade(**kw):
        assert release.wait(20)
        return report(**kw)
    monkeypatch.setattr(js, "judge_submission", grade)
    app = js.create_app(SForgeConfig(
        log_dir=tmp_path, judge_max_concurrent=3, judge_max_pending=6,
        judge_max_outstanding_per_run=limit,
    ))
    state = app.state.judge
    sock = socket.socket()
    sock.bind(("127.0.0.1", 0))
    port = sock.getsockname()[1]
    server = uvicorn.Server(uvicorn.Config(app, log_level="error", lifespan="on"))
    thread = threading.Thread(target=server.run, kwargs={"sockets": [sock]})
    thread.start()
    base = f"http://127.0.0.1:{port}"
    accepted = []
    try:
        deadline = time.monotonic() + 5
        while not server.started and thread.is_alive() and time.monotonic() < deadline:
            time.sleep(0.01)
        assert server.started
        tokens = []
        for n in range(9):
            response = requests.post(base + "/api/v1/register", json={
                "task_id": "test", "run_id": f"run-{n}", "admin_secret": state.admin_secret,
                "submission_cooldown": 3600, "max_agent_submissions": 3,
            }, timeout=3)
            assert response.status_code == 200
            tokens.append(response.json()["token"])
        def submit(token, source):
            response = requests.post(base + "/api/v1/submit", data={"token": token},
                                     files={"archive": ("source.tar.gz", source)}, timeout=3)
            if response.status_code == 200:
                accepted.append((response.json()["submission_id"], source))
            return response
        assert submit(tokens[0], b"run-0-first").status_code == 200
        clock[0] += 3600  # Cooldown expires while the first evaluation remains unfinished.
        before = state.resolve_token(tokens[0])
        spools = set(tmp_path.joinpath("judge-pending").iterdir())
        second = submit(tokens[0], b"run-0-second")
        assert second.status_code == second_status
        if limit == 1:
            assert second.headers["retry-after"] == "5"
            assert state.resolve_token(tokens[0]) == before
            assert set(tmp_path.joinpath("judge-pending").iterdir()) == spools
        firsts = 1 + sum(submit(token, f"run-{n}-first".encode()).status_code == 200
                         for n, token in enumerate(tokens[1:], 1))
        assert firsts == first_accepted
        if limit == 1:
            assert set(state._outstanding_by_run.values()) == {1}
            assert len(state._outstanding_by_run) == 9
        else:
            assert state.resolve_token(tokens[-1])["next_agent"] == 1
        sid = accepted[0][0]
        before = state.resolve_token(tokens[0])
        assert requests.get(base + "/api/v1/result/" + sid, timeout=3).status_code == 200
        assert requests.get(base + "/api/v1/history", params={"token": tokens[0]}, timeout=3).status_code == 200
        assert state.resolve_token(tokens[0]) == before
    finally:
        release.set()
        server.should_exit = True
        thread.join(timeout=10)
        sock.close()
        state.close()
    assert not thread.is_alive() and not state._reaper_thread.is_alive()
    assert state._outstanding_by_run == {}
    assert not list(tmp_path.joinpath("judge-pending").iterdir())
    for sid, source in accepted:
        result = state.get_result(sid)
        assert result["status"] == js.SubmissionStatus.COMPLETED
        assert result["report"]["submission_id"] == sid
        assert result["report"]["source_sha256"] == hashlib.sha256(source).hexdigest()
    assert sum(len(rows) for rows in state.run_history.values()) == len(accepted)


def test_limit_environment_and_actual_cli_config_readback(make_judge, monkeypatch):
    monkeypatch.delenv("SFORGE_JUDGE_MAX_OUTSTANDING_PER_RUN", raising=False)
    assert load_config().judge_max_outstanding_per_run is None
    monkeypatch.setenv("SFORGE_JUDGE_MAX_OUTSTANDING_PER_RUN", "2")
    assert load_config().judge_max_outstanding_per_run == 2
    seen = []
    def serve(args):
        config = cli._make_config(args)
        seen.append(config.judge_max_outstanding_per_run)
    monkeypatch.setattr(cli, "cmd_serve", serve)
    monkeypatch.setattr(sys, "argv", ["sforge", "serve", "--judge-max-outstanding-per-run", "1"])
    cli.main()
    assert seen == [1]
    help_result = subprocess.run([sys.executable, "-m", "sforge.cli", "serve", "--help"],
                                 capture_output=True, text=True, timeout=10)
    assert help_result.returncode == 0 and "--judge-max-outstanding-per-run" in help_result.stdout
    for value in ("0", "-1"):
        result = subprocess.run([sys.executable, "-m", "sforge.cli", "serve",
                                 "--judge-max-outstanding-per-run", value],
                                capture_output=True, text=True, timeout=10)
        assert result.returncode != 0
        assert "judge_max_outstanding_per_run must be >= 1 or unset" in result.stderr
