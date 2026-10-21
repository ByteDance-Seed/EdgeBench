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

"""Budget propagation through the actual runner, without a paid solver or judge."""

from __future__ import annotations

import importlib
from types import SimpleNamespace
from typing import ClassVar
from unittest.mock import Mock

import pytest

from sforge.harness.agent.base import Agent
from sforge.harness.backend.base import ContainerBackend, StreamingExecResult
from sforge.harness.config import SForgeConfig
from sforge.harness.evolve_scripts import generate_evolve_prompt, generate_game_prompt
from sforge.harness.task_spec import JudgeSpec, TaskSpec, WorkSpec

runner = importlib.import_module("sforge.harness.run_agent")


class SyntheticAgent(Agent):
    name = "synthetic"
    install_cmds: ClassVar[list[str]] = []
    run_cmd = "synthetic-agent {prompt_file}"
    api_key_env = "SYNTHETIC_API_KEY"


@pytest.fixture
def harness(tmp_path, monkeypatch):
    config = SForgeConfig(log_dir=tmp_path)
    query = "Agent time limit: 2 hours. Each test must finish within 5 seconds."
    task = TaskSpec(
        task_id="budget-fixture", name="Budget fixture", base_image="python",
        platform="linux/amd64", cwd="/workspace", submit_paths=["submission/"],
        submit_exclude=[],
        work=WorkSpec(specs_dir="", agent_query=query, image_tag="fixture"),
        judge=JudgeSpec(eval_cmd="true", eval_timeout=1, parser="pytest", image_tag="fixture"),
    )
    backend = Mock(spec=ContainerBackend)
    backend.backend_name = "synthetic"
    backend.image_exists.return_value = True
    backend.exec_run.return_value = StreamingExecResult()
    backend.exec_run_with_exit_code.return_value = StreamingExecResult()
    captured = []
    segments = [StreamingExecResult(output="done", elapsed_seconds=2)]

    def execute(*args, **kwargs):
        if kwargs.get("log_file") is None:
            return StreamingExecResult(output="{}")
        captured.append({
            "prompt": (tmp_path / "runs/run/budget-fixture/agent_prompt.md").read_text(),
            "timeout": kwargs["timeout"],
            "environment": dict(kwargs["environment"]),
        })
        return segments.pop(0)

    backend.exec_run_with_timeout.side_effect = execute
    response = Mock()
    response.json.return_value = {
        "token": "synthetic-session", "entries": [], "best_score": None,
        "best_pass_rate": 0.0, "agent_submissions": 0, "auto_submissions": 0,
    }
    monkeypatch.setattr(runner.requests, "post", Mock(return_value=response))
    monkeypatch.setattr(runner.requests, "get", Mock(return_value=response))
    monkeypatch.setattr(runner.requests.sessions.Session, "request",
                        Mock(side_effect=AssertionError("Unexpected network access")))
    monkeypatch.setattr(runner, "get_admin_secret", lambda _: "synthetic-admin")
    monkeypatch.setattr(runner, "_extract_archive_from_container", lambda *a: b"fixture")
    agent = SyntheticAgent(config)

    def run(**kwargs):
        return runner.run_agent(
            task, agent, config, backend, "run",
            **{"disable_auto_eval": True, "disable_auto_resume": True,
               "disable_stop_hook": True, **kwargs},
        )

    return SimpleNamespace(run=run, config=config, task=task, agent=agent,
                           backend=backend, captured=captured, segments=segments)


@pytest.mark.parametrize("game_mode", [False, True])
@pytest.mark.parametrize("explicit,configured,expected", [
    (64800, 7200, 64800), (None, 7200, 7200), (None, None, 3600), (15, 7200, 15),
])
def test_dispatch_prompt_uses_effective_budget(harness, game_mode, explicit, configured, expected):
    harness.task.game_mode = game_mode
    harness.config.agent_timeout = configured
    result = harness.run(timeout=explicit)
    assert len(harness.captured) == 1  # A valid short run is not forced to continue.
    dispatch = harness.captured[0]
    assert dispatch["timeout"] == expected
    assert f"{expected} seconds" in dispatch["prompt"]
    assert "conflicting whole-run Agent time limits" in dispatch["prompt"]
    assert harness.task.work.agent_query in dispatch["prompt"]
    assert result.runtime_seconds == 2


def test_resume_receives_remaining_budget_without_replenishing_total(harness, monkeypatch):
    clock = iter(range(1000, 10000))
    monkeypatch.setattr(runner.time, "time", lambda: next(clock))
    harness.agent.resume_cmd = "resume-synthetic-agent"
    harness.config.agent_extra_env = {
        "SFORGE_AGENT_BUDGET_SECONDS": "999",
        "SFORGE_AGENT_REMAINING_SECONDS": "999",
        "SFORGE_AGENT_SEGMENT_STARTED_AT": "1",
        "SYNTHETIC_OPTION": "preserved",
    }
    harness.segments[:] = [
        StreamingExecResult(output="interrupted", elapsed_seconds=3),
        StreamingExecResult(output="timeout", elapsed_seconds=7, timed_out=True),
    ]
    result = harness.run(timeout=10, disable_auto_resume=False)
    assert [c["timeout"] for c in harness.captured] == [10, 7]
    for call, remaining in zip(harness.captured, [10, 7]):
        assert call["environment"]["SFORGE_AGENT_BUDGET_SECONDS"] == "10"
        assert call["environment"]["SFORGE_AGENT_REMAINING_SECONDS"] == str(remaining)
        assert float(call["environment"]["SFORGE_AGENT_SEGMENT_STARTED_AT"]) > 0
        assert call["environment"]["SYNTHETIC_OPTION"] == "preserved"
        assert "shared across all resumed executions" in call["prompt"]
    first, second = harness.captured
    assert float(second["environment"]["SFORGE_AGENT_SEGMENT_STARTED_AT"]) > float(
        first["environment"]["SFORGE_AGENT_SEGMENT_STARTED_AT"]
    )
    assert result.timed_out
    assert result.runtime_seconds == 10


@pytest.mark.parametrize("invalid", [0, -1, True, 1.5, float("inf"), "60"])
def test_invalid_explicit_budget_fails_before_side_effects(harness, invalid):
    with pytest.raises(ValueError, match="positive integer"):
        harness.run(timeout=invalid)
    harness.backend.create_container.assert_not_called()
    runner.requests.post.assert_not_called()


@pytest.mark.parametrize("source", ["config", "agent"])
@pytest.mark.parametrize("invalid", [0, -1, True, 1.5, float("inf"), "60"])
def test_invalid_fallback_budget_fails_before_side_effects(harness, source, invalid):
    if source == "config":
        harness.config.agent_timeout = invalid
    else:
        harness.agent.timeout = invalid
    with pytest.raises(ValueError, match="positive integer"):
        harness.run()
    harness.backend.create_container.assert_not_called()
    runner.requests.post.assert_not_called()


def test_subsecond_remainder_does_not_dispatch_zero_timeout(harness):
    harness.agent.resume_cmd = "resume-synthetic-agent"
    harness.segments[:] = [StreamingExecResult(output="interrupted", elapsed_seconds=1.6)]
    result = harness.run(timeout=2, disable_auto_resume=False)
    assert [c["timeout"] for c in harness.captured] == [2]
    assert result.timed_out
    assert result.runtime_seconds == 1.6


@pytest.mark.parametrize("generate", [generate_evolve_prompt, generate_game_prompt])
def test_standalone_prompt_does_not_invent_a_budget(generate):
    prompt = generate("Follow the task-specific time limit.")
    assert "Agent Execution Budget" not in prompt
    assert "Follow the task-specific time limit." in prompt
