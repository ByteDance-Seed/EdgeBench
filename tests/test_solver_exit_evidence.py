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

"""Retain real subprocess outcomes through the native runner and its sidecar."""

import json
import subprocess
import sys
import threading

import pytest

from sforge.harness import run_agent as runner
from test_run_agent_grading import SyntheticAgent, harness  # noqa: F401 -- pytest fixture


def observe_backend(harness, monkeypatch, results):
    original = harness.backend.exec_run_with_timeout
    pending = iter(results)

    def execute(*args, **kwargs):
        result = original(*args, **kwargs)
        if kwargs.get("log_file") is not None:
            for key, value in next(pending).items():
                setattr(result, key, value)
        return result

    monkeypatch.setattr(harness.backend, "exec_run_with_timeout", execute)


def evidence(harness, result):
    saved = json.loads((harness.log_dir / "solver_execution.json").read_text())
    assert result.to_dict()["solver_execution"] == saved
    assert harness.backend.cleaned_at is not None
    return saved


@pytest.mark.parametrize("body,status,code,term_signal", [
    ("raise SystemExit(0)", "normal_exit", 0, None),
    ("raise SystemExit(7)", "nonzero_exit", 7, None),
    ("raise SystemExit(143)", "nonzero_exit", 143, None),
    ("import os,signal; os.kill(os.getpid(),signal.SIGTERM)", "signaled", -15, 15),
])
def test_native_runner_retains_real_process_exit(harness, monkeypatch, body, status, code, term_signal):
    completed = subprocess.run([sys.executable, "-c", body], capture_output=True, timeout=5)
    assert completed.returncode == code
    observe_backend(harness, monkeypatch, [dict(
        exit_code=completed.returncode, native_exit_code=completed.returncode,
        terminal_observed=True, termination_signal=term_signal)])
    result = harness.run()
    saved = evidence(harness, result)
    assert saved["status"] == status and len(saved["segments"]) == 1
    segment = saved["segments"][0]
    assert segment["returned_exit_code"] == segment["native_exit_code"] == code
    assert segment["termination_signal"] == term_signal
    assert segment["terminal_observed"] is True
    assert result.best_score == 99 and result.grading_status == "complete"


@pytest.mark.parametrize("metadata,expected", [
    (dict(exit_code=0, native_exit_code=None, terminal_observed=None), "unknown"),
    (dict(exit_code=None, native_exit_code=None, terminal_observed=False), "unknown"),
    (dict(exit_code=-1, native_exit_code=143, terminal_observed=True, timed_out=True), "timed_out"),
])
def test_missing_terminal_and_timeout_are_not_normal_exit(harness, monkeypatch, metadata, expected):
    observe_backend(harness, monkeypatch, [metadata])
    result = harness.run()
    saved = evidence(harness, result)
    assert saved["status"] == expected
    assert saved["segments"][0]["termination_signal"] is None
    assert saved["segments"][0]["native_exit_code"] == metadata["native_exit_code"]


def test_exception_retains_started_segment_as_unknown(harness):
    harness.backend.solver_error = RuntimeError("synthetic transport failure")
    saved = evidence(harness, harness.run())
    assert saved["status"] == "unknown"
    assert len(saved["segments"]) == 1
    assert saved["segments"][0]["status"] == "unknown"
    assert saved["segments"][0]["error_type"] == "RuntimeError"
    assert saved["segments"][0]["native_exit_code"] is None


def test_interrupted_segment_is_not_a_confirmed_solver_signal(harness):
    harness.backend.interrupt_solver = True
    saved = evidence(harness, harness.run())
    assert saved["status"] == "unknown"
    assert saved["segments"][0]["status"] == "unknown"
    assert saved["segments"][0]["error_type"] == "KeyboardInterrupt"
    assert saved["segments"][0]["termination_signal"] is None


def test_cancel_receipt_retains_confirmation_separately(harness, monkeypatch):
    stop = threading.Event()
    original = harness.backend.exec_run_with_timeout

    def cancelled(*args, **kwargs):
        result = original(*args, **kwargs)
        if kwargs.get("log_file") is not None:
            stop.set()
            result.exit_code = -1
            result.native_exit_code = 0
            result.terminal_observed = True
            result.timed_out = True
        return result

    monkeypatch.setattr(harness.backend, "exec_run_with_timeout", cancelled)
    saved = evidence(harness, harness.run(shutdown_event=stop))
    assert saved["status"] == "cancelled"
    assert saved["segments"][0]["terminal_observed"] is True
    assert saved["segments"][0]["native_exit_code"] == 0


def test_install_failure_is_not_a_started_solver(harness, monkeypatch):
    def fail_install(*_args, **_kwargs):
        raise RuntimeError("synthetic install failure")

    monkeypatch.setattr(harness.backend, "exec_run_with_exit_code", fail_install)
    saved = evidence(harness, harness.run())
    assert saved["status"] == "not_started" and saved["segments"] == []
    assert harness.backend.solver_calls == 0


def test_before_dispatch_records_pending_receipt_not_process_liveness(harness, monkeypatch):
    original = harness.backend.exec_run_with_timeout

    def inspect_before_dispatch(*args, **kwargs):
        if kwargs.get("log_file") is not None:
            saved = json.loads((harness.log_dir / "solver_execution.json").read_text())
            assert saved["status"] == saved["segments"][-1]["status"] == "pending"
            assert saved["segments"][-1]["terminal_observed"] is None
        return original(*args, **kwargs)

    monkeypatch.setattr(harness.backend, "exec_run_with_timeout", inspect_before_dispatch)
    result = harness.run()
    assert harness.backend.solver_calls == 1, result.agent_output


def test_resume_preserves_each_segment_and_existing_resume_policy(harness, monkeypatch):
    native_run = runner.run_agent
    monkeypatch.setattr(runner, "run_agent", lambda *args, **kwargs:
        native_run(*args, **{**kwargs, "disable_auto_resume": False}))
    monkeypatch.setattr(SyntheticAgent, "resume_cmd", "resume-synthetic")
    observe_backend(harness, monkeypatch, [
        dict(exit_code=7, native_exit_code=7, terminal_observed=True, elapsed_seconds=2),
        dict(exit_code=0, native_exit_code=0, terminal_observed=True, elapsed_seconds=2),
        dict(exit_code=-1, native_exit_code=143, terminal_observed=True, elapsed_seconds=1, timed_out=True),
    ])
    result = harness.run()
    saved = evidence(harness, result)
    assert result.resume_count == 2 and harness.backend.solver_calls == 3
    assert [s["status"] for s in saved["segments"]] == ["nonzero_exit", "normal_exit", "timed_out"]
    assert [s["index"] for s in saved["segments"]] == [1, 2, 3]
    assert result.best_score == 99
