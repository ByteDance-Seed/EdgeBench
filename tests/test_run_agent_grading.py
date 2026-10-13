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

"""Real runner + local HTTP judge protocol; synthetic clock, agent and backend."""

from __future__ import annotations

import hashlib
import importlib
import io
import json
import tarfile
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from types import SimpleNamespace
from typing import ClassVar
from urllib.parse import parse_qs, urlsplit

import pytest

from sforge.harness.agent.base import Agent
from sforge.harness.backend.base import StreamingExecResult
from sforge.harness.config import SForgeConfig
from sforge.harness.selection import select_best
from sforge.harness.task_spec import JudgeSpec, TaskSpec, WorkSpec

runner = importlib.import_module("sforge.harness.run_agent")


class Clock:
    elapsed = 0.0

    def time(self):
        return 1_700_000_000 + self.elapsed

    def monotonic(self):
        return self.elapsed

    def sleep(self, seconds):
        self.elapsed += seconds

    def strftime(self, _format):
        return "2026-01-01T00:00:00"


class SyntheticAgent(Agent):
    name = "synthetic"
    install_cmds: ClassVar[list[str]] = ["install-synthetic-agent"]
    run_cmd = "run-synthetic-agent {prompt_file}"
    api_key_env = "SYNTHETIC_API_KEY"


class Backend:
    backend_name = "synthetic"

    def __init__(self, clock):
        self.clock = clock
        self.cleaned_at = None
        self.solver_calls = 0
        self.interrupt_solver = False
        self.solver_error = None
        self.solver_timed_out = False
        self.before_solver_return = lambda: None

    def image_exists(self, _image):
        return True

    def create_container(self, *_args, **_kwargs):
        return SimpleNamespace(id="synthetic-work")

    def remove_container_by_name(self, *_args):
        pass

    def start_container(self, *_args):
        pass

    def copy_to_container(self, *_args):
        pass

    def copy_from_container(self, _handle, _path, **_kwargs):
        data = b"synthetic-submission"
        wrapped = io.BytesIO()
        with tarfile.open(fileobj=wrapped, mode="w") as archive:
            item = tarfile.TarInfo("archive.tar.gz")
            item.size = len(data)
            archive.addfile(item, io.BytesIO(data))
        return wrapped.getvalue()

    def exec_run(self, *_args, **_kwargs):
        return StreamingExecResult()

    def exec_run_with_exit_code(self, *_args, **_kwargs):
        return StreamingExecResult()

    def exec_run_with_timeout(self, *_args, **kwargs):
        if kwargs.get("log_file") is not None:
            self.solver_calls += 1
            if self.interrupt_solver:
                raise KeyboardInterrupt
            if self.solver_error is not None:
                raise self.solver_error
            self.before_solver_return()
            return StreamingExecResult(output="solver done", elapsed_seconds=1,
                                       timed_out=self.solver_timed_out)
        return StreamingExecResult(output="{}")

    def cleanup_container(self, *_args):
        self.cleaned_at = self.clock.monotonic()


@pytest.fixture
def harness(tmp_path, monkeypatch):
    clock = Clock()
    state = SimpleNamespace(
        clock=clock, complete_at=1005, fail_reads=0, reads=0,
        close_status=200, close_calls=0, close_body={"closed": 1}, malformed=False, game=False,
        fail_after=None, read_delay=0, summary_override={},
        history_requests=[], block_submit=False, submit_entered=threading.Event(),
        release_submit=threading.Event(), submit_completed=False,
    )

    class Handler(BaseHTTPRequestHandler):
        def log_message(self, *_args):
            pass

        def reply(self, status, body):
            raw = json.dumps(body).encode()
            self.send_response(status)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(raw)))
            self.end_headers()
            self.wfile.write(raw)

        def do_POST(self):
            self.rfile.read(int(self.headers.get("Content-Length", "0")))
            if self.path.endswith("/register"):
                self.reply(200, {"token": "synthetic-session"})
            elif self.path.endswith("/submit"):
                state.submit_entered.set()
                if not state.release_submit.wait(timeout=2):
                    self.reply(503, {})
                    return
                state.submit_completed = True
                state.complete_at = clock.monotonic()
                self.reply(200, {"submission_id": "last", "round_id": "auto-1"})
            elif self.path.endswith("/close-all"):
                state.close_calls += 1
                self.reply(state.close_status, state.close_body)
            else:
                self.reply(404, {})

        def do_GET(self):
            query = parse_qs(urlsplit(self.path).query)
            assert query["token"] == ["synthetic-session"]
            state.history_requests.append(query)
            state.reads += 1
            clock.sleep(state.read_delay)
            if state.reads <= state.fail_reads or (
                state.fail_after is not None and state.reads > state.fail_after
            ):
                self.reply(503, {"error": "synthetic unavailable"})
                return
            if state.malformed:
                self.reply(200, {"entries": "not a history"})
                return
            entries = [{"type": "submission", "status": "completed",
                        "submission_id": "first", "round": "agent-1", "score": 7}]
            if state.block_submit and not state.submit_completed:
                pass  # The request has not yet entered the official history.
            elif state.game:
                entries = [{"type": "game", "round": "game-1", "score": 7}]
            elif clock.monotonic() >= state.complete_at:
                entries.append({"type": "submission", "status": "completed",
                                "submission_id": "last", "round": "auto-1", "score": 99})
            else:
                entries.append({"type": "submission", "status": "running",
                                "submission_id": "last", "round": "auto-1"})
            history = {"run_id": "synthetic-run", "entries": entries,
                       "agent_submissions": 1, "auto_submissions": 1,
                       **select_best(entries, policy="score_first")}
            history.update(state.summary_override)
            self.reply(200, history)

    server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
    worker = threading.Thread(target=lambda: server.serve_forever(poll_interval=0.01), daemon=True)
    worker.start()
    config = SForgeConfig(log_dir=tmp_path)
    task = TaskSpec(
        task_id="grading-fixture", name="Grading fixture", base_image="python",
        platform="linux/amd64", cwd="/workspace", submit_paths=["solution"], submit_exclude=[],
        work=WorkSpec(specs_dir="", agent_query="Synthetic task", image_tag="fixture"),
        judge=JudgeSpec(eval_cmd="true", eval_timeout=1200, parser="pytest", image_tag="fixture"),
    )
    backend = Backend(clock)
    monkeypatch.setattr(runner, "time", clock)
    monkeypatch.setattr(runner, "get_admin_secret", lambda _: "synthetic-admin")

    def run(**kwargs):
        task.game_mode = state.game
        return runner.run_agent(
            task, SyntheticAgent(config), config, backend, "synthetic-run",
            timeout=5, disable_auto_resume=True, disable_stop_hook=True,
            judge_url=f"http://127.0.0.1:{server.server_port}",
            **{"disable_auto_eval": True, **kwargs},
        )

    state.run = run
    state.task = task
    state.backend = backend
    state.log_dir = tmp_path / "runs" / "synthetic-run" / "grading-fixture"
    try:
        yield state
    finally:
        server.shutdown()
        server.server_close()
        worker.join(timeout=2)


@pytest.mark.parametrize("solver_timed_out", [False, True])
def test_long_evaluation_finishes_before_run_returns(harness, solver_timed_out):
    harness.backend.solver_timed_out = solver_timed_out
    result = harness.run()
    assert result.timed_out == solver_timed_out
    assert result.best_score == 99, "the last submission finishes after the old 900s drain"
    assert harness.backend.cleaned_at >= harness.complete_at
    history = json.loads((harness.log_dir / "run_history.json").read_text())
    assert history["entries"][-1]["status"] == "completed"
    assert harness.backend.solver_calls == 1
    assert all(q.get("admin_secret") == ["synthetic-admin"] for q in harness.history_requests)


@pytest.mark.parametrize("failure", ["pending", "unavailable", "malformed"])
def test_incomplete_grading_is_bounded_and_recorded(harness, failure):
    harness.task.judge.eval_timeout = 1
    harness.complete_at = float("inf")
    if failure == "unavailable":
        harness.fail_reads = 10000
    if failure == "malformed":
        harness.malformed = True
    result = harness.run()
    status = json.loads((harness.log_dir / "grading_status.json").read_text())
    expected = "pending" if failure == "pending" else "unknown"
    assert status["status"] == expected
    assert result.grading_status == expected
    assert result.to_dict()["grading_status"] == expected
    assert 900 <= harness.clock.elapsed <= 915
    assert harness.backend.cleaned_at is not None
    assert harness.backend.solver_calls == 1


def test_transient_history_failure_does_not_end_the_drain(harness):
    harness.fail_reads = 2
    result = harness.run()
    assert result.best_score == 99
    assert result.grading_status == "complete"


def test_failed_game_close_cannot_claim_final_grading(harness):
    harness.game = True
    harness.close_status = 500
    result = harness.run()
    assert harness.close_calls == 1
    assert result.best_score == 7
    status = json.loads((harness.log_dir / "grading_status.json").read_text())
    assert status["status"] == "unknown"
    assert status["reason"] == "game_close_failed"
    assert result.grading_status == "unknown"


def test_game_close_and_history_are_both_needed(harness):
    harness.game = True
    result = harness.run()
    status = json.loads((harness.log_dir / "grading_status.json").read_text())
    assert status["status"] == "complete"
    assert status["history_file"] == "game_history.json"
    assert result.best_score == 7
    assert harness.backend.solver_calls == 1


def test_interruption_preserves_nonfinal_evidence(harness):
    harness.backend.interrupt_solver = True
    result = harness.run()
    assert result.agent_output == "Stopped by user (Ctrl+C)"
    status = json.loads((harness.log_dir / "grading_status.json").read_text())
    assert status["status"] != "complete"
    assert status["reason"] == "interrupted"
    assert harness.clock.elapsed < 900
    assert harness.backend.cleaned_at is not None


def test_shutdown_event_stops_waiting_without_claiming_completion(harness):
    cancelled = threading.Event()
    cancelled.set()
    result = harness.run(shutdown_event=cancelled)
    assert result.grading_status == "pending"
    assert result.grading_reason == "interrupted"
    assert harness.clock.elapsed < 900


def test_harness_failure_retains_failure_and_nonfinal_history(harness):
    harness.backend.solver_error = RuntimeError("synthetic solver failure")
    result = harness.run()
    assert result.agent_output == "synthetic solver failure"
    assert result.best_score == 7
    status = json.loads((harness.log_dir / "grading_status.json").read_text())
    assert status["status"] != "complete"
    assert status["reason"] == "harness_error"
    assert harness.backend.cleaned_at is not None


def test_stop_waits_for_the_inflight_automatic_submit(harness):
    harness.block_submit = True

    def solver_returns():
        assert harness.submit_entered.wait(timeout=2)
        # Complete a real HTTP request after the solver has returned. The
        # old event.set-only path observes an empty pending set before this.
        threading.Timer(0.2, harness.release_submit.set).start()

    harness.backend.before_solver_return = solver_returns
    result = harness.run(disable_auto_eval=False, eval_interval=0.001)
    assert harness.submit_completed
    assert result.best_score == 99
    assert result.grading_status == "complete"
    assert harness.backend.solver_calls == 1


@pytest.mark.parametrize("stage", ["construct", "start"])
def test_auto_eval_start_failure_preserves_error_and_cleanup(harness, monkeypatch, stage):
    class FailedThread:
        def __init__(self, **_kwargs):
            if stage == "construct":
                raise RuntimeError("synthetic thread construction failed")

        def start(self):
            raise RuntimeError("synthetic thread start failed")

        def join(self, **_kwargs):
            raise RuntimeError("cannot join an unstarted thread")

    thread_api = SimpleNamespace(**vars(threading))
    thread_api.Thread = FailedThread
    monkeypatch.setattr(runner, "threading", thread_api)
    result = harness.run(disable_auto_eval=False)
    assert "synthetic thread" in result.agent_output
    assert harness.backend.solver_calls == 0
    assert harness.backend.cleaned_at is not None


def test_unstopped_auto_eval_cannot_claim_final_grading(harness, monkeypatch):
    joins = []

    class ActiveThread:
        def __init__(self, **_kwargs):
            pass

        def start(self):
            pass

        def join(self, timeout):
            joins.append(timeout)

        def is_alive(self):
            return True

    thread_api = SimpleNamespace(**vars(threading))
    thread_api.Thread = ActiveThread
    monkeypatch.setattr(runner, "threading", thread_api)
    harness.complete_at = 0
    result = harness.run(disable_auto_eval=False)
    assert result.grading_status == "unknown"
    assert result.grading_reason == "auto_eval_active"
    assert len(joins) == 1 and 0 < joins[0] < 600
    assert harness.backend.cleaned_at is not None


def test_failed_later_reads_retain_last_history_and_qualify_it(harness):
    harness.task.judge.eval_timeout = 1
    harness.fail_after = 1
    result = harness.run()
    assert result.best_score == 7
    assert result.grading_status == "unknown"
    assert result.grading_reason == "history_unavailable"
    raw = (harness.log_dir / "run_history.json").read_bytes()
    status = json.loads((harness.log_dir / "grading_status.json").read_text())
    assert status["history_observed"]
    assert status["history_sha256"] == hashlib.sha256(raw).hexdigest()
    assert json.loads(raw)["entries"][-1]["status"] == "running"
    assert b"synthetic-session" not in raw and b"synthetic-admin" not in raw


def test_slow_response_after_deadline_remains_nonfinal(harness):
    harness.task.judge.eval_timeout = 1
    harness.read_delay = 1000
    harness.complete_at = 0
    result = harness.run()
    assert result.grading_status != "complete"
    assert result.grading_reason == "deadline"
    assert harness.reads == 1


@pytest.mark.parametrize("interrupted", [False, True])
def test_malformed_summary_cannot_replace_original_failure(harness, interrupted):
    harness.summary_override = {"best_score": {"invalid": True}}
    harness.backend.interrupt_solver = interrupted
    if not interrupted:
        harness.backend.solver_error = RuntimeError("original solver failure")
    result = harness.run()
    expected = "Stopped by user (Ctrl+C)" if interrupted else "original solver failure"
    assert result.agent_output == expected
    assert result.best_score is None
    assert result.grading_status == "unknown"
    assert harness.backend.cleaned_at is not None


@pytest.mark.parametrize("interrupted", [False, True])
def test_evidence_write_failure_preserves_original_outcome(harness, monkeypatch, interrupted):
    class LegacyError(RuntimeError):
        # Python 3.10 has no BaseException.add_note.
        add_note = None

    harness.backend.interrupt_solver = interrupted
    if not interrupted:
        harness.backend.solver_error = LegacyError("original solver failure")

    def failed_write(*_args):
        raise OSError("synthetic disk failure")

    monkeypatch.setattr(runner, "_write_grading", failed_write)
    result = harness.run()
    expected = "Stopped by user (Ctrl+C)" if interrupted else "original solver failure"
    assert result.agent_output == expected
    assert result.grading_status == "unknown"
    assert result.grading_reason == "evidence_write_failed"
    assert harness.backend.cleaned_at is not None


@pytest.mark.parametrize("body", [{"closed": True}, {"closed": -1}, [], {}])
def test_game_close_needs_recognized_acknowledgement(harness, body):
    harness.game = True
    harness.close_body = body
    result = harness.run()
    assert result.grading_status == "unknown"
    assert result.grading_reason == "game_close_failed"
