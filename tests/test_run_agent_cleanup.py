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

"""Exercise run_agent cleanup without a container, model, or judge service."""

from __future__ import annotations

import importlib
import signal
from types import SimpleNamespace
from typing import ClassVar
from unittest.mock import Mock

import pytest

from sforge.harness.agent.base import Agent
from sforge.harness.backend.base import ContainerBackend, StreamingExecResult
from sforge.harness.config import SForgeConfig
from sforge.harness.task_spec import JudgeSpec, TaskSpec, WorkSpec

runner = importlib.import_module("sforge.harness.run_agent")


class SyntheticAgent(Agent):
    name = "synthetic"
    install_cmds: ClassVar[list[str]] = ["install-synthetic-agent"]
    run_cmd = "run-synthetic-agent {prompt_file}"
    api_key_env = "SYNTHETIC_API_KEY"


@pytest.fixture
def harness(monkeypatch, tmp_path):
    config = SForgeConfig(log_dir=tmp_path)
    task = TaskSpec(
        task_id="cleanup-fixture", name="Cleanup fixture", base_image="python",
        platform="linux/amd64", cwd="/workspace", submit_paths=["."],
        submit_exclude=[],
        work=WorkSpec(specs_dir="", agent_query="Synthetic task", image_tag="fixture"),
        judge=JudgeSpec(eval_cmd="true", eval_timeout=1, parser="pytest", image_tag="fixture"),
    )
    backend = Mock(spec=ContainerBackend)
    backend.backend_name = "docker"
    backend.image_exists.return_value = True
    handle = backend.create_container.return_value
    backend.exec_run_with_exit_code.return_value = StreamingExecResult(output="installed")
    backend.exec_run_with_timeout.side_effect = [
        StreamingExecResult(output="solver-output", elapsed_seconds=2),
        StreamingExecResult(output="{}"),
    ]

    history = {"best_score": 0.7, "best_pass_rate": 0.5, "best_round": "round-1",
               "agent_submissions": 1, "auto_submissions": 2, "entries": []}
    registration = Mock()
    registration.json.return_value = {"token": "synthetic-session"}
    history_response = Mock()
    history_response.json.return_value = history
    monkeypatch.setattr(runner.requests, "post", Mock(return_value=registration))
    monkeypatch.setattr(runner.requests, "get", Mock(return_value=history_response))
    # Reject all unmocked HTTP paths rather than relying on unreachable URLs.
    monkeypatch.setattr(runner.requests.sessions.Session, "request",
                        Mock(side_effect=AssertionError("Unexpected network access")))
    monkeypatch.setattr(runner, "get_admin_secret", lambda _: "synthetic-admin")
    monkeypatch.setattr("sforge.harness.network_isolation.cleanup_stale_chains", Mock())
    archive = Mock(return_value=b"synthetic-archive")
    monkeypatch.setattr(runner, "_extract_archive_from_container", archive)
    closed = Mock(wraps=runner.close_logger)
    monkeypatch.setattr(runner, "close_logger", closed)
    previous_sigint = signal.getsignal(signal.SIGINT)

    def run(**kwargs):
        return runner.run_agent(
            task, SyntheticAgent(config), config, backend, "synthetic-run",
            timeout=5, disable_auto_resume=True, disable_stop_hook=True,
            **{"disable_auto_eval": True, **kwargs},
        )

    yield SimpleNamespace(backend=backend, handle=handle, run=run, close=closed,
                          archive=archive, history=history, previous_sigint=previous_sigint)
    signal.signal(signal.SIGINT, previous_sigint)


def assert_cleaned(harness, handle):
    harness.backend.cleanup_container.assert_called_once()
    assert harness.backend.cleanup_container.call_args.args[0] is handle
    harness.close.assert_called_once()
    assert signal.getsignal(signal.SIGINT) == harness.previous_sigint


@pytest.mark.parametrize("backend_name", ["docker", "k8s", "e2b"])
@pytest.mark.parametrize("timed_out", [False, True], ids=["nonzero-exit", "timeout"])
def test_install_failure_preserves_failure_and_cleans_up(harness, backend_name, timed_out):
    harness.backend.backend_name = backend_name
    harness.backend.exec_run_with_exit_code.return_value = StreamingExecResult(
        output="synthetic install failure", exit_code=23, timed_out=timed_out,
    )
    expected = "Install command timed out" if timed_out else "Install command failed (exit 23)"
    if backend_name == "e2b":
        with pytest.raises(RuntimeError, match=expected.replace("(", r"\(").replace(")", r"\)")) as error:
            harness.run()
        assert type(error.value) is RuntimeError
    else:
        result = harness.run()
        assert expected in result.agent_output
        assert result.best_score == harness.history["best_score"]
        assert result.resume_count == 0
    harness.backend.exec_run_with_timeout.assert_not_called()
    assert_cleaned(harness, harness.handle)


@pytest.mark.parametrize("backend_name", ["docker", "e2b"])
@pytest.mark.parametrize("stage", ["image", "create"])
def test_failure_before_handle_keeps_original_error(harness, backend_name, stage):
    harness.backend.backend_name = backend_name
    if stage == "image":
        harness.backend.image_exists.return_value = False
        expected = "not found"
    else:
        harness.backend.create_container.side_effect = RuntimeError("synthetic create failure")
        expected = "synthetic create failure"
    if backend_name == "e2b":
        with pytest.raises(RuntimeError, match=expected) as error:
            harness.run()
        assert type(error.value) is RuntimeError
    else:
        result = harness.run()
        assert expected in result.agent_output
    if stage == "image":
        harness.backend.create_container.assert_not_called()
    harness.backend.exec_run_with_timeout.assert_not_called()
    assert_cleaned(harness, None)


def test_interrupt_during_install_returns_interrupted_result(harness):
    harness.backend.exec_run_with_exit_code.side_effect = KeyboardInterrupt
    result = harness.run()
    assert result.agent_output == "Stopped by user (Ctrl+C)"
    assert result.resume_count == 0
    assert result.archive == b"synthetic-archive"
    harness.backend.exec_run_with_timeout.assert_not_called()
    assert_cleaned(harness, harness.handle)


@pytest.mark.parametrize("auto_eval", [False, True])
def test_success_preserves_result_and_stops_auto_eval(harness, monkeypatch, auto_eval):
    thread_factory = Mock()
    monkeypatch.setattr(runner.threading, "Thread", thread_factory)
    result = harness.run(disable_auto_eval=not auto_eval)
    assert result.agent_output == "solver-output"
    assert result.archive == b"synthetic-archive"
    assert result.best_score == 0.7
    assert result.total_rounds == 3
    assert result.runtime_seconds == 2
    assert not result.timed_out
    assert result.resume_count == 0
    if auto_eval:
        thread_factory.return_value.start.assert_called_once()
        stop_event = thread_factory.call_args.kwargs["args"][6]
        assert stop_event.is_set()
    else:
        thread_factory.assert_not_called()
    assert_cleaned(harness, harness.handle)
