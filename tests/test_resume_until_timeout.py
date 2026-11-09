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

"""The explicit resume policy through the production runner and CLI adapter."""
from __future__ import annotations

import importlib
import json
import threading
from types import SimpleNamespace

import pytest

from sforge.harness.agent.base import Agent
from sforge.harness.backend.base import ExecResult, StreamingExecResult
from sforge.harness.config import SForgeConfig

runner = importlib.import_module("sforge.harness.run_agent")


class ProbeAgent(Agent):
    name = "probe"
    npm_package = "synthetic-probe"
    default_version = "fixture"
    api_key_env = "SYNTHETIC_UNUSED_KEY"
    run_cmd = "initial {prompt_file}"
    resume_cmd = "resume-same-session"
    blocked = None

    def install(self, *args):
        pass

    def resume_block_reason(self, result):
        return self.blocked


class ProbeBackend:
    backend_name = "fixture"
    public_dns = ()
    uses_hostname_egress = True

    def __init__(self, clock):
        self.clock = clock
        self.calls = []
        self.creates = 0
        self.duration = 1.0
        self.overhead = 0.0
        self.exit_code = 0
        self.after_exec = lambda: None

    def image_exists(self, image):
        return True

    def remove_container_by_name(self, *args):
        pass

    def create_container(self, *args, **kwargs):
        self.creates += 1
        return SimpleNamespace(id="same-worker")

    def start_container(self, handle):
        pass

    def cleanup_container(self, *args):
        pass

    def copy_to_container(self, *args):
        pass

    def exec_run(self, *args, **kwargs):
        return ExecResult()

    def exec_run_with_timeout(self, handle, cmd, **kwargs):
        self.calls.append((handle.id, cmd, kwargs["timeout"], kwargs["log_append"]))
        self.clock.now += self.duration + self.overhead
        self.after_exec()
        return StreamingExecResult("successful fixture", self.exit_code, False, self.duration)


@pytest.fixture
def execution(tmp_path, monkeypatch):
    clock = SimpleNamespace(now=0.0)
    monkeypatch.setattr(runner, "time", SimpleNamespace(
        monotonic=lambda: clock.now, time=lambda: 1800000000 + clock.now))
    backend = ProbeBackend(clock)
    config = SForgeConfig(log_dir=tmp_path)
    agent = ProbeAgent(config)
    task = SimpleNamespace(task_id="toy", game_mode=False, work_image_key="work",
        judge_image_key="judge", work=SimpleNamespace(cpu_limit=1, mem_limit="128m", instruction="Write answer.txt"),
        submit_paths=["answer.txt"], cwd="/work", internet=True)
    registrations = []

    class Response:
        def __init__(self, payload):
            self.payload = payload

        def raise_for_status(self):
            pass

        def json(self):
            return self.payload

    def post(url, **kwargs):
        registrations.append(kwargs["json"])
        return Response({"token": "synthetic-registration"})

    monkeypatch.setattr(runner.requests, "post", post)
    monkeypatch.setattr(runner.requests, "get", lambda *a, **k: Response({"entries": [], "agent_submissions": 0, "auto_submissions": 0}))
    monkeypatch.setattr(runner, "_install_tools", lambda *a, **k: None)
    monkeypatch.setattr(runner, "_extract_archive_from_container", lambda *a, **k: b"")
    monkeypatch.setattr(runner, "_sync_agent_sessions", lambda *a, **k: None)
    monkeypatch.setattr(runner, "_session_sync_loop", lambda *a, **k: None)

    def run(**kwargs):
        return runner.run_agent(task, agent, config, backend, "probe", timeout=130,
            disable_auto_eval=True, disable_stop_hook=True, **kwargs)

    return SimpleNamespace(run=run, backend=backend, agent=agent, config=config,
        task=task, clock=clock, registrations=registrations,
        trial=tmp_path/"runs/probe/toy")


def test_opt_in_crosses_100_without_replacing_worker_or_session(execution):
    x = execution
    result = x.run(resume_until_timeout=True, max_submissions=7, submission_cooldown=3600)
    assert len(x.backend.calls) == 130
    assert result.resume_count == 129
    assert x.backend.creates == len(x.registrations) == 1
    assert x.registrations[0]["submission_cooldown"] == 3600
    assert x.registrations[0]["max_agent_submissions"] == 7
    assert x.backend.calls[0][1][-1].startswith("initial ")
    assert all(c[0] == "same-worker" and c[1][-1] == "resume-same-session" and c[3] for c in x.backend.calls[1:])
    policy = result.to_dict()["resume_policy"]
    assert policy["stop_reason"] == "budget_exhausted"
    assert policy["deadline_unix"] - policy["started_at_unix"] == 130
    assert policy["remaining_seconds"] == 0
    assert policy["phase_elapsed_seconds"] == result.runtime_seconds == 130
    assert json.loads((x.trial/"resume-policy.json").read_text()) == policy


def test_default_retains_100_resumes_and_wire(execution):
    result = execution.run()
    assert len(execution.backend.calls) == 101
    assert result.resume_count == 100
    assert not result.timed_out
    assert "resume_policy" not in result.to_dict()
    assert not (execution.trial/"resume-policy.json").exists()


def test_deadline_charges_between_segment_overhead(execution):
    x = execution
    x.backend.duration, x.backend.overhead = 20, 30
    result = x.run(resume_until_timeout=True)
    assert [c[2] for c in x.backend.calls] == [130, 80, 30]
    assert result.runtime_seconds == 60
    assert result.resume_policy["phase_elapsed_seconds"] == 150
    assert result.resume_policy["deadline_unix"] - result.resume_policy["started_at_unix"] == 130


@pytest.mark.parametrize("kind,reason", [("stop", "shutdown_requested"), ("failure", "process_failed"), ("provider", "provider_blocked"), ("short", "short_segment")])
def test_real_stop_and_failure_guards_remain_terminal(execution, kind, reason):
    x = execution
    stop = threading.Event()
    if kind == "stop":
        x.backend.after_exec = stop.set
    elif kind == "failure":
        x.backend.exit_code = 1  # Includes provider quota failures; no prose classifier.
    elif kind == "provider":
        x.agent.blocked = "quota_exhausted"
    else:
        x.backend.duration = 0.2
    result = x.run(resume_until_timeout=True, shutdown_event=stop)
    assert len(x.backend.calls) == 1
    assert result.resume_count == 0
    assert result.resume_policy["stop_reason"] == reason
    assert result.resume_policy["remaining_seconds"] > 0


def test_preexisting_stop_dispatches_nothing(execution):
    stop = threading.Event()
    stop.set()
    result = execution.run(resume_until_timeout=True, shutdown_event=stop)
    assert not execution.backend.calls
    assert not execution.backend.creates and not execution.registrations
    assert result.resume_policy["stop_reason"] == "shutdown_requested"


@pytest.mark.parametrize("timeout", [None, 0, -1, True, 1.5, float("inf")])
def test_invalid_or_implicit_budget_rejected_before_registration(execution, timeout):
    x = execution
    with pytest.raises(ValueError, match="explicit positive integer"):
        runner.run_agent(x.task, x.agent, x.config, x.backend, "invalid", timeout=timeout, resume_until_timeout=True)
    assert not x.registrations and not x.backend.creates


def test_disabled_resume_cannot_be_overridden(execution):
    with pytest.raises(ValueError, match="enabled auto-resume"):
        execution.run(resume_until_timeout=True, disable_auto_resume=True)
    assert not execution.registrations


@pytest.mark.parametrize("command", [None, "", "  "])
def test_missing_resume_command_cannot_fall_back_to_cold_start(execution, command):
    execution.agent.resume_cmd = command
    with pytest.raises(ValueError, match="Agent resume command"):
        execution.run(resume_until_timeout=True)
    assert not execution.registrations


def test_explicit_config_timeout_uses_same_owner(execution):
    x = execution
    x.config.agent_timeout = 5
    result = runner.run_agent(x.task, x.agent, x.config, x.backend, "probe",
        resume_until_timeout=True, disable_auto_eval=True, disable_stop_hook=True)
    assert len(x.backend.calls) == 5
    assert result.resume_policy["timeout_seconds"] == 5


def test_initial_format_is_separate_setup_cost(execution):
    x = execution
    original = x.agent.format_run_cmd

    def format_cmd(*args, resume=False, **kwargs):
        if not resume:
            x.clock.now += 5
        return original(*args, resume=resume, **kwargs)

    x.agent.format_run_cmd = format_cmd
    result = x.run(resume_until_timeout=True)
    assert len(x.backend.calls) == 130
    assert result.resume_policy["phase_elapsed_seconds"] == 130
    assert result.resume_policy["total_elapsed_seconds"] == 135


def test_resume_format_cannot_spend_stale_remaining_timeout(execution):
    x = execution
    original = x.agent.format_run_cmd

    def format_cmd(*args, resume=False, **kwargs):
        if resume:
            x.clock.now += 130
        return original(*args, resume=resume, **kwargs)

    x.agent.format_run_cmd = format_cmd
    result = x.run(resume_until_timeout=True)
    assert len(x.backend.calls) == 1
    assert result.resume_count == 0
    assert result.resume_policy["stop_reason"] == "budget_exhausted"


def test_stop_during_format_cannot_enter_backend(execution):
    x = execution
    stop = threading.Event()
    original = x.agent.format_run_cmd

    def format_cmd(*args, **kwargs):
        stop.set()
        return original(*args, **kwargs)

    x.agent.format_run_cmd = format_cmd
    result = x.run(resume_until_timeout=True, shutdown_event=stop)
    assert not x.backend.calls
    assert result.resume_policy["phase_elapsed_seconds"] == 0


@pytest.mark.parametrize("error", [OSError, KeyboardInterrupt])
def test_failed_resume_excludes_final_collection_from_phase(execution, monkeypatch, error):
    x = execution
    original_format = x.agent.format_run_cmd
    original_get = runner.requests.get

    def format_cmd(*args, resume=False, **kwargs):
        if resume:
            x.clock.now += 2
            raise error("Synthetic resume preparation failure")
        return original_format(*args, resume=resume, **kwargs)

    def collect(*args, **kwargs):
        x.clock.now += 10
        return original_get(*args, **kwargs)

    x.agent.format_run_cmd = format_cmd
    monkeypatch.setattr(runner.requests, "get", collect)
    result = x.run(resume_until_timeout=True)
    assert len(x.backend.calls) == len(x.registrations) == 1
    assert result.resume_policy["phase_elapsed_seconds"] == 3
    assert result.resume_policy["remaining_seconds"] == 127
    assert result.resume_policy["total_elapsed_seconds"] == 13
    assert result.runtime_seconds == 1


def test_initial_preparation_failure_keeps_phase_unstarted(execution, monkeypatch):
    x = execution
    original_get = runner.requests.get

    def format_cmd(*args, **kwargs):
        x.clock.now += 2
        raise OSError("Synthetic first preparation failure")

    def collect(*args, **kwargs):
        x.clock.now += 10
        return original_get(*args, **kwargs)

    x.agent.format_run_cmd = format_cmd
    monkeypatch.setattr(runner.requests, "get", collect)
    result = x.run(resume_until_timeout=True)
    assert not x.backend.calls
    assert result.resume_policy["phase_elapsed_seconds"] == 0
    assert result.resume_policy["remaining_seconds"] == 130
    assert result.resume_policy["total_elapsed_seconds"] == 12


def test_unconfirmed_exec_failure_keeps_conservative_phase_boundary(execution, monkeypatch):
    x = execution
    original_get = runner.requests.get

    def uncertain_exec(*args, **kwargs):
        x.clock.now += 1
        raise OSError("Synthetic stream failure without confirmed process exit")

    def collect(*args, **kwargs):
        x.clock.now += 10
        return original_get(*args, **kwargs)

    monkeypatch.setattr(x.backend, "exec_run_with_timeout", uncertain_exec)
    monkeypatch.setattr(runner.requests, "get", collect)
    result = x.run(resume_until_timeout=True)
    assert len(x.registrations) == 1
    assert result.resume_policy["phase_elapsed_seconds"] == 11
    assert result.resume_policy["remaining_seconds"] == 119
    assert result.resume_policy["total_elapsed_seconds"] == 11


def test_old_attempt_cannot_gain_new_deadline(execution):
    x = execution
    x.trial.mkdir(parents=True)
    (x.trial/"started_at").write_text("1800000000\n")
    with pytest.raises(ValueError, match="fresh run"):
        x.run(resume_until_timeout=True)
    assert not x.registrations


def test_policy_receipt_prevents_uncertain_invocation_replay(execution):
    execution.run(resume_until_timeout=True)
    with pytest.raises((ValueError, FileExistsError)):
        execution.run(resume_until_timeout=True)
    assert len(execution.registrations) == 1


def test_cli_adapter_forwards_policy_and_reads_result(execution, monkeypatch):
    from sforge import cli
    import sforge.harness.agent
    x = execution
    x.config.log_dir.joinpath("runs/probe/toy").mkdir(parents=True)
    monkeypatch.setattr(sforge.harness.agent, "create_agent", lambda *a: x.agent)
    args = SimpleNamespace(agent="probe", model=None, timeout=130, eval_interval=0,
        judge_url="http://127.0.0.1:1", resume_until_timeout=True)
    value = cli._run_single_task(x.task, args, x.config, x.backend, "probe")
    assert value["resume_policy"]["mode"] == "until_timeout"
    assert value["resume_count"] == 129
    assert json.loads((x.trial/"final_result.json").read_text())["resume_policy"] == value["resume_policy"]
