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

"""Native HTTP admission with controlled work backend/clock; Docker separately."""

from __future__ import annotations

import copy
import importlib
import json
import threading
import time
from dataclasses import replace
from types import SimpleNamespace
from unittest.mock import Mock

import pytest
from test_judge_checkpoint import capture, register, restore, service, submit  # noqa: F401

from sforge.harness.agent import Agent
from sforge.harness.restored_registration import RestoredExecution, RestoredRegistration

runner = importlib.import_module("sforge.harness.run_agent")
warm = importlib.import_module("sforge.harness.restored_registration")


class SyntheticAgent(Agent):
    name = "fixture"
    api_key_env = "UNUSED_FIXTURE_KEY"

    def __init__(self, config):
        super().__init__(config)
        self.install_cmds = ["install fixture"]

    run_cmd = "run fixture"
    resume_cmd = "resume fixture"


@pytest.fixture
def entry(service, monkeypatch):  # noqa: F811 - imported pytest fixture
    state, client = service
    token = register(state, client, max_agent_submissions=2, submission_cooldown=3600)
    submit(client, token, 7)
    point = capture(state, client, token)
    restored = restore(state, client, point)
    assert restored.status_code == 200
    before = copy.deepcopy((state.tokens, state.run_history, state.submissions))
    calls = []

    def post(url, **kwargs):
        calls.append(url)
        native_response = client.post(
            url.split("http://fixture")[1], json=kwargs["json"]
        )
        response = warm.requests.Response()
        response.status_code = native_response.status_code
        response._content = native_response.content
        response.url = url
        return response

    monkeypatch.setattr(warm.requests, "post", post)
    monkeypatch.setattr(
        runner.requests,
        "get",
        lambda url, **kw: client.get(
            url.split("http://fixture")[1], params=kw.get("params")
        ),
    )
    monkeypatch.setattr(
        "sforge.harness.network_isolation.cleanup_stale_chains", lambda logger: None
    )
    monkeypatch.setattr(
        runner, "_extract_archive_from_container", lambda *args, **kwargs: b"fixture"
    )
    backend = Mock(backend_name="docker")
    backend.image_exists.return_value = True
    backend.exec_run_with_exit_code.return_value = SimpleNamespace(
        output="installed", exit_code=0, timed_out=False, elapsed_seconds=0
    )
    clock = [1000.0]
    monkeypatch.setattr(
        warm, "time", SimpleNamespace(time=lambda: clock[0], monotonic=lambda: clock[0])
    )
    spec = RestoredRegistration(
        point["checkpoint_id"],
        point["manifest_sha256"],
        1100,
        state.config.log_dir / "checkpoints" / point["checkpoint_id"] / "manifest.json",
    )
    config = state.config
    agent = SyntheticAgent(config)

    def run(**options):
        return runner.run_agent(
            state.tasks["fixture"],
            agent,
            config,
            backend,
            "branch",
            judge_url="http://fixture",
            disable_auto_eval=True,
            disable_stop_hook=True,
            restored_registration=spec,
            **options,
        )

    return SimpleNamespace(
        state=state,
        client=client,
        before=before,
        backend=backend,
        clock=clock,
        spec=spec,
        run=run,
        calls=calls,
        agent=agent,
        config=config,
    )


def test_install_and_resume_gaps_are_charged_to_original_deadline(entry):
    e = entry

    def install(*args, **kwargs):
        assert kwargs["timeout"] == 100
        e.clock[0] += 35
        return SimpleNamespace(
            output="installed", exit_code=0, timed_out=False, elapsed_seconds=1
        )

    e.backend.exec_run_with_exit_code.side_effect = install
    timeouts = []

    def execute(handle, cmd, **kwargs):
        if "cat /tmp/sforge_state" in str(cmd):
            return SimpleNamespace(output="{}")
        timeouts.append(kwargs["timeout"])
        e.clock[0] += 20
        return SimpleNamespace(
            output="work", elapsed_seconds=2, timed_out=len(timeouts) == 2
        )

    e.backend.exec_run_with_timeout.side_effect = execute
    result = e.run()
    assert timeouts == [65, 45]  # wall time, not the backend's reported 2 seconds
    assert result.timed_out and result.resume_count == 1
    assert e.calls == ["http://fixture/api/v1/checkpoint/restore-result"]
    assert (e.state.tokens, e.state.run_history, e.state.submissions) == e.before
    assert result.agent_submissions == 1 and result.best_score == 7
    log = e.config.log_dir / "runs/branch/fixture/run_agent.log"
    prior_log = log.read_bytes()
    with pytest.raises(ValueError, match="already entered"):
        e.run()
    assert log.read_bytes() == prior_log
    assert e.backend.create_container.call_count == 1


@pytest.mark.parametrize(
    "failure",
    [
        "missing",
        "wrong_task",
        "wrong_origin",
        "auth",
        "conflicting_limit",
        "cancelled",
        "expired",
    ],
)
def test_warm_admission_never_falls_back_to_cold_or_creates_container(
    entry, monkeypatch, failure
):
    e = entry
    if failure == "missing":
        e.state._checkpoint_runs.clear()
    elif failure == "wrong_task":
        e.state.tasks["fixture"] = replace(e.state.tasks["fixture"], task_id="other")
    elif failure == "wrong_origin":
        for path in e.config.log_dir.glob("runs/branch/checkpoint-origin.json"):
            value = json.loads(path.read_text())
            value["manifest_sha256"] = "0" * 64
            path.write_text(json.dumps(value))
    elif failure == "auth":
        monkeypatch.setattr(runner, "get_admin_secret", lambda root: "invalid")
    elif failure == "expired":
        e.clock[0] = 1101
    event = threading.Event()
    if failure == "cancelled":
        event.set()
    kwargs = {"shutdown_event": event}
    if failure == "conflicting_limit":
        kwargs["max_submissions"] = 99
    expected = {
        "missing": warm.requests.HTTPError,
        "wrong_task": ValueError,
        "wrong_origin": warm.requests.HTTPError,
        "auth": warm.requests.HTTPError,
        "conflicting_limit": ValueError,
        "cancelled": InterruptedError,
        "expired": TimeoutError,
    }[failure]
    with pytest.raises(expected):
        e.run(**kwargs)
    e.backend.create_container.assert_not_called()
    assert all(url.endswith("/checkpoint/restore-result") for url in e.calls)


def test_install_consuming_budget_cannot_start_model(entry):
    e = entry

    def install(*args, **kw):
        e.clock[0] = 1101
        return SimpleNamespace(
            output="late", exit_code=0, timed_out=False, elapsed_seconds=1
        )

    e.backend.exec_run_with_exit_code.side_effect = install
    with pytest.raises(TimeoutError, match="deadline"):
        e.run()
    e.backend.exec_run_with_timeout.assert_not_called()
    assert e.backend.cleanup_container.called


def test_retry_before_work_keeps_deadline_and_is_exclusive(tmp_path):
    spec = RestoredRegistration(
        "a" * 32, "b" * 64, time.time() + 100, tmp_path / "manifest.json"
    )
    first = RestoredExecution(spec, tmp_path, "run", "task", None)
    with pytest.raises(BlockingIOError):
        RestoredExecution(spec, tmp_path, "run", "task", None)
    first.close()
    with pytest.raises(ValueError, match="differs"):
        RestoredExecution(
            replace(spec, deadline_epoch=spec.deadline_epoch + 10),
            tmp_path,
            "run",
            "task",
            None,
        )
    retry = RestoredExecution(spec, tmp_path, "run", "task", None)
    retry.start_work()
    retry.close()
    with pytest.raises(ValueError, match="already entered"):
        RestoredExecution(spec, tmp_path, "run", "task", None)


@pytest.mark.parametrize("deadline", [True, 0, -1, float("inf"), float("nan")])
def test_invalid_deadlines_rejected(deadline, tmp_path):
    with pytest.raises(ValueError):
        RestoredRegistration("a" * 32, "b" * 64, deadline, tmp_path / "manifest.json")


def test_cold_default_still_registers_and_uses_relative_work_timeout(entry):
    e = entry
    e.backend.exec_run_with_timeout.return_value = SimpleNamespace(
        output="{}", elapsed_seconds=2, timed_out=False
    )
    runner.run_agent(
        e.state.tasks["fixture"],
        e.agent,
        e.config,
        e.backend,
        "cold",
        judge_url="http://fixture",
        timeout=100,
        disable_auto_eval=True,
        disable_auto_resume=True,
        disable_stop_hook=True,
    )
    assert e.calls == ["http://fixture/api/v1/register"]
    assert e.backend.exec_run_with_timeout.call_args_list[0].kwargs["timeout"] == 100
    assert not (e.config.log_dir / "runs/cold/fixture/restored-execution.json").exists()


def test_lost_readback_response_retry_does_not_allocate_or_reset_deadline(
    entry, monkeypatch
):
    e = entry
    post = warm.requests.post

    def lose_reply(*args, **kwargs):
        post(*args, **kwargs)
        raise warm.requests.ConnectionError("injected lost response")

    monkeypatch.setattr(warm.requests, "post", lose_reply)
    with pytest.raises(warm.requests.ConnectionError):
        e.run()
    e.backend.create_container.assert_not_called()
    e.clock[0] += 20
    monkeypatch.setattr(warm.requests, "post", post)
    e.backend.exec_run_with_timeout.return_value = SimpleNamespace(
        output="{}", elapsed_seconds=1, timed_out=True
    )
    e.run()
    assert e.backend.exec_run_with_timeout.call_args_list[0].kwargs["timeout"] == 80
    assert (e.state.tokens, e.state.run_history, e.state.submissions) == e.before
    assert all(url.endswith("/checkpoint/restore-result") for url in e.calls)


def test_warm_entry_rejects_new_relative_budget(entry):
    with pytest.raises(ValueError, match="original absolute deadline"):
        entry.run(timeout=500)
    entry.backend.create_container.assert_not_called()
    assert entry.calls == []


def test_cancellation_between_segments_does_not_resume(entry):
    event = threading.Event()
    calls = []

    def execute(*args, **kwargs):
        calls.append(kwargs["timeout"])
        event.set()
        return SimpleNamespace(output="work", elapsed_seconds=2, timed_out=False)

    entry.backend.exec_run_with_timeout.side_effect = execute
    with pytest.raises(InterruptedError):
        entry.run(shutdown_event=event)
    assert calls == [100]
    assert entry.backend.cleanup_container.called


def test_warm_entry_requires_explicit_agent_only_evaluation(entry):
    with pytest.raises(ValueError, match="automatic evaluation disabled"):
        runner.run_agent(
            entry.state.tasks["fixture"],
            entry.agent,
            entry.config,
            entry.backend,
            "branch",
            restored_registration=entry.spec,
        )
    entry.backend.create_container.assert_not_called()
    assert entry.calls == []


def test_changed_local_manifest_cannot_enter_work(entry):
    entry.spec.manifest_path.write_bytes(b"{}")
    with pytest.raises(ValueError, match="manifest digest differs"):
        entry.run()
    entry.backend.create_container.assert_not_called()
    assert entry.calls == []
