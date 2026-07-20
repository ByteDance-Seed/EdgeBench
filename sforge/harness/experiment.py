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

"""Experiment configuration: YAML-based per-task overrides with a single model.

An experiment config decouples "how to run" (model, per-task overrides)
from "what to test" (task JSON definitions).

YAML format:

    env:
      SFORGE_MAVEN_MIRROR_URL: "https://maven.aliyun.com/repository/public"
      SFORGE_AGENT_API_KEY: "sk-..."

    model:
      api_key: ${OPUS_KEY}
      api_base_url: https://api.anthropic.com
      model: claude-opus-4-6

    defaults:
      agent: claude-code
      timeout: 7200
      eval_interval: 300

    tasks:
      minitorch:
        eval_interval: 1800
      tinykv:
        extra_env:
          GOPROXY: "https://goproxy.cn"
"""

from __future__ import annotations

import os
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

import yaml


@dataclass
class ModelConfig:
    api_key: str | None = None
    api_base_url: str | None = None
    model: str | None = None


@dataclass
class TaskOverrides:
    agent: str | None = None
    model: str | None = None
    effort: str | None = None
    timeout: int | None = None
    eval_interval: int | None = None
    disable_stop_hook: bool | None = None
    disable_auto_eval: bool | None = None
    disable_auto_resume: bool | None = None
    internet: bool | None = None
    work_cpu_limit: int | None = None
    work_mem_limit: str | None = None
    judge_cpu_limit: int | None = None
    judge_mem_limit: str | None = None
    extra_env: dict[str, str] | None = None
    backend: str | None = None
    judge_url: str | None = None
    max_submissions: int | None = None
    submission_cooldown: int | None = None


@dataclass
class ExperimentConfig:
    model: ModelConfig = field(default_factory=ModelConfig)
    defaults: TaskOverrides = field(default_factory=TaskOverrides)
    tasks: dict[str, TaskOverrides] = field(default_factory=dict)
    stagger: int | None = None


_ENV_VAR_RE = re.compile(r"\$\{([^}]+)\}")


def _expand_env_vars(value: str) -> str:
    """Expand ${VAR_NAME} patterns using os.environ. Raises on missing vars."""

    def _replace(match: re.Match) -> str:
        var_name = match.group(1)
        val = os.environ.get(var_name)
        if val is None:
            raise ValueError(
                f"Environment variable '{var_name}' referenced in experiment "
                f"config but not set"
            )
        return val

    return _ENV_VAR_RE.sub(_replace, value)


def _parse_model_config(data: dict) -> ModelConfig:
    cfg = ModelConfig()
    for key in ("api_key", "api_base_url", "model"):
        val = data.get(key)
        if val is not None:
            setattr(cfg, key, _expand_env_vars(str(val)))
    unknown = set(data) - {"api_key", "api_base_url", "model"}
    if unknown:
        print(
            f"Warning: unknown fields in model config: {unknown}",
            file=sys.stderr,
        )
    return cfg


def _parse_task_overrides(data: dict | None) -> TaskOverrides:
    if not data:
        return TaskOverrides()
    ovr = TaskOverrides()
    for key in ("agent", "model", "effort"):
        val = data.get(key)
        if val is not None:
            setattr(ovr, key, str(val))
    for key in ("timeout", "eval_interval", "max_submissions", "submission_cooldown"):
        val = data.get(key)
        if val is not None:
            setattr(ovr, key, int(val))
    for key in ("disable_stop_hook", "disable_auto_eval", "disable_auto_resume", "internet"):
        val = data.get(key)
        if val is not None:
            setattr(ovr, key, bool(val))
    if data.get("cpu_limit") is not None:
        ovr.work_cpu_limit = int(data["cpu_limit"])
        ovr.judge_cpu_limit = int(data["cpu_limit"])
    if data.get("mem_limit") is not None:
        ovr.work_mem_limit = str(data["mem_limit"])
        ovr.judge_mem_limit = str(data["mem_limit"])
    for key in ("work_cpu_limit", "judge_cpu_limit"):
        val = data.get(key)
        if val is not None:
            setattr(ovr, key, int(val))
    for key in ("work_mem_limit", "judge_mem_limit"):
        val = data.get(key)
        if val is not None:
            setattr(ovr, key, str(val))
    if "extra_env" in data and data["extra_env"]:
        ovr.extra_env = {str(k): str(v) for k, v in data["extra_env"].items()}
    for key in ("backend", "judge_url"):
        val = data.get(key)
        if val is not None:
            setattr(ovr, key, str(val))
    return ovr


def load_experiment(path: Path) -> ExperimentConfig:
    """Load and validate an experiment config from a YAML file."""
    if not path.exists():
        print(f"Error: experiment config not found: {path}", file=sys.stderr)
        sys.exit(1)

    with open(path) as f:
        raw = yaml.safe_load(f)

    if not isinstance(raw, dict):
        print(f"Error: experiment config must be a YAML mapping", file=sys.stderr)
        sys.exit(1)

    if "tasks" not in raw or not raw["tasks"]:
        print(
            f"Error: experiment config must have a non-empty 'tasks' section",
            file=sys.stderr,
        )
        sys.exit(1)

    config = ExperimentConfig()

    # Inject top-level env vars into process environment before parsing
    # the rest, so ${VAR} expansion and load_config() env lookups work.
    if raw.get("env") and isinstance(raw["env"], dict):
        for key, val in raw["env"].items():
            os.environ[str(key)] = str(val)

    if raw.get("model"):
        config.model = _parse_model_config(raw["model"])

    config.defaults = _parse_task_overrides(raw.get("defaults"))

    if raw.get("stagger") is not None:
        config.stagger = int(raw["stagger"])

    for task_id, task_data in raw["tasks"].items():
        config.tasks[str(task_id)] = _parse_task_overrides(task_data)

    return config


def resolve_task_overrides(
    experiment: ExperimentConfig, task_id: str
) -> TaskOverrides:
    """Merge per-task overrides with experiment defaults.

    Per-task values win over defaults for scalar fields.
    For extra_env, dicts are merged (per-task wins on key conflicts).
    """
    defaults = experiment.defaults
    task_ovr = experiment.tasks.get(task_id, TaskOverrides())

    merged = TaskOverrides(
        agent=task_ovr.agent if task_ovr.agent is not None else defaults.agent,
        model=task_ovr.model if task_ovr.model is not None else defaults.model,
        effort=(
            task_ovr.effort if task_ovr.effort is not None else defaults.effort
        ),
        timeout=(
            task_ovr.timeout if task_ovr.timeout is not None else defaults.timeout
        ),
        eval_interval=(
            task_ovr.eval_interval
            if task_ovr.eval_interval is not None
            else defaults.eval_interval
        ),
        disable_stop_hook=(
            task_ovr.disable_stop_hook
            if task_ovr.disable_stop_hook is not None
            else defaults.disable_stop_hook
        ),
        disable_auto_eval=(
            task_ovr.disable_auto_eval
            if task_ovr.disable_auto_eval is not None
            else defaults.disable_auto_eval
        ),
        disable_auto_resume=(
            task_ovr.disable_auto_resume
            if task_ovr.disable_auto_resume is not None
            else defaults.disable_auto_resume
        ),
        internet=(
            task_ovr.internet
            if task_ovr.internet is not None
            else defaults.internet
        ),
        work_cpu_limit=(
            task_ovr.work_cpu_limit
            if task_ovr.work_cpu_limit is not None
            else defaults.work_cpu_limit
        ),
        work_mem_limit=(
            task_ovr.work_mem_limit
            if task_ovr.work_mem_limit is not None
            else defaults.work_mem_limit
        ),
        judge_cpu_limit=(
            task_ovr.judge_cpu_limit
            if task_ovr.judge_cpu_limit is not None
            else defaults.judge_cpu_limit
        ),
        judge_mem_limit=(
            task_ovr.judge_mem_limit
            if task_ovr.judge_mem_limit is not None
            else defaults.judge_mem_limit
        ),
        extra_env={
            **(defaults.extra_env or {}),
            **(task_ovr.extra_env or {}),
        }
        or None,
        max_submissions=(
            task_ovr.max_submissions
            if task_ovr.max_submissions is not None
            else defaults.max_submissions
        ),
        submission_cooldown=(
            task_ovr.submission_cooldown
            if task_ovr.submission_cooldown is not None
            else defaults.submission_cooldown
        ),
    )

    return merged
