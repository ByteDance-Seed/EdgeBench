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

from __future__ import annotations

import hashlib
import json
from dataclasses import dataclass
from pathlib import Path

from sforge.harness.benchmark import BenchmarkMeta
from sforge.harness.constants import (
    SForgeTask,
    START_TEST_OUTPUT,
    END_TEST_OUTPUT,
)
from sforge.harness.score_rescale import RescaleSpec, parse_rescale_spec


@dataclass
class WorkSpec:
    specs_dir: str
    agent_query: str
    setup_cmds: list[str] | None = None
    image_tag: str | None = None
    cpu_limit: int | None = None
    mem_limit: str | None = None


@dataclass
class JudgeSpec:
    eval_cmd: str
    eval_timeout: int
    parser: str
    setup_cmds: list[str] | None = None
    image_tag: str | None = None
    game_server_cmd: str | None = None
    score_direction: str = "maximize"
    selection: str = "pass_rate_first"
    rescale: RescaleSpec | None = None
    cpu_limit: int | None = None
    mem_limit: str | None = None


def _compute_base_image_hash(base_image_key: str, base_image_spec: dict) -> str:
    data = json.dumps({"key": base_image_key, "spec": base_image_spec}, sort_keys=True)
    return hashlib.sha256(data.encode()).hexdigest()


@dataclass
class TaskSpec:
    task_id: str
    name: str
    base_image: str  # key into BENCHMARK.json base_images, e.g. "python310"
    platform: str
    cwd: str
    submit_paths: list[str]
    submit_exclude: list[str]
    work: WorkSpec
    judge: JudgeSpec
    benchmark_name: str = ""
    base_image_spec: dict | None = None
    game_mode: bool = False
    internet: bool = True

    @property
    def base_image_tag(self) -> str:
        """Full Docker image name with hash tag, e.g. 'edgebench.base.python310:a1b2c3d4e5f6'."""
        return f"{self.benchmark_name}.base.{self.base_image}:{self.base_image_hash[:12]}"

    @property
    def work_image_key(self) -> str:
        tag = self.work.image_tag if self.work.image_tag else self.work_image_hash[:12]
        return f"{self.benchmark_name}.work.{self.task_id}:{tag}"

    @property
    def judge_image_key(self) -> str:
        tag = self.judge.image_tag if self.judge.image_tag else self.judge_image_hash[:12]
        return f"{self.benchmark_name}.judge.{self.task_id}:{tag}"

    @property
    def base_image_hash(self) -> str:
        return _compute_base_image_hash(self.base_image, self.base_image_spec or {})

    @property
    def work_image_hash(self) -> str:
        if self.work.setup_cmds is None:
            raise ValueError(
                f"Task '{self.task_id}': cannot compute work image hash without setup_cmds"
            )
        data = json.dumps({
            "base_hash": self.base_image_hash,
            "platform": self.platform,
            "cwd": self.cwd,
            "setup_cmds": self.work.setup_cmds,
        }, sort_keys=True)
        return hashlib.sha256(data.encode()).hexdigest()

    @property
    def judge_image_hash(self) -> str:
        if self.judge.setup_cmds is None:
            raise ValueError(
                f"Task '{self.task_id}': cannot compute judge image hash without setup_cmds"
            )
        data = json.dumps({
            "base_hash": self.base_image_hash,
            "platform": self.platform,
            "cwd": self.cwd,
            "setup_cmds": self.judge.setup_cmds,
        }, sort_keys=True)
        return hashlib.sha256(data.encode()).hexdigest()

    @property
    def work_needs_build(self) -> bool:
        return self.work.setup_cmds is not None

    @property
    def judge_needs_build(self) -> bool:
        return self.judge.setup_cmds is not None

    def base_remote_ref(self, registry: str) -> str:
        return f"{registry}/{self.base_image_tag}"

    def work_remote_ref(self, registry: str) -> str:
        return f"{registry}/{self.work_image_key}"

    def judge_remote_ref(self, registry: str) -> str:
        return f"{registry}/{self.judge_image_key}"

    @property
    def setup_workspace_script(self) -> str:
        if self.work.setup_cmds is None:
            raise ValueError(
                f"Task '{self.task_id}': no setup_cmds for work image (using pre-built image_tag)"
            )
        lines = ["#!/bin/bash", "set -euxo pipefail"] + self.work.setup_cmds
        return "\n".join(lines) + "\n"

    @property
    def setup_judge_script(self) -> str:
        if self.judge.setup_cmds is None:
            raise ValueError(
                f"Task '{self.task_id}': no setup_cmds for judge image (using pre-built image_tag)"
            )
        lines = ["#!/bin/bash", "set -euxo pipefail"] + self.judge.setup_cmds
        return "\n".join(lines) + "\n"

    @property
    def eval_script(self) -> str:
        """Generate eval.sh for the judge container."""
        lines = [
            "#!/bin/bash",
            "set -uxo pipefail",
            f'echo "{START_TEST_OUTPUT}"',
            f"{self.judge.eval_cmd} 2>&1",
            "EXIT_CODE=$?",
            f'echo "{END_TEST_OUTPUT}"',
            'echo "Exit code: $EXIT_CODE"',
            "exit 0",
        ]
        return "\n".join(lines) + "\n"


def _validate_image_tag_consistency(
    task_id: str,
    role: str,
    setup_cmds: list[str] | None,
    image_tag: str | None,
    computed_hash_fn,
) -> None:
    """When both setup_cmds and image_tag are present, verify the hash matches."""
    if setup_cmds is not None and image_tag is not None:
        computed = computed_hash_fn()[:12]
        if computed != image_tag:
            raise ValueError(
                f"Task '{task_id}' {role}: image_tag '{image_tag}' does not match "
                f"hash computed from setup_cmds '{computed}'. "
                f"Update image_tag or setup_cmds to make them consistent."
            )
    if setup_cmds is None and image_tag is None:
        raise ValueError(
            f"Task '{task_id}' {role}: must have either setup_cmds or image_tag (or both)."
        )


def make_task_spec(task_path: Path, benchmark: BenchmarkMeta) -> TaskSpec:
    """Load a TaskSpec from a task JSON file, resolving base image from benchmark metadata."""
    with open(task_path) as f:
        data: SForgeTask = json.load(f)

    base_image_key = data["base_image"]
    base_image_spec = benchmark.base_images.get(base_image_key)
    if base_image_spec is None:
        raise ValueError(
            f"Task '{data['task_id']}' references base_image '{base_image_key}' "
            f"which is not defined in BENCHMARK.json. "
            f"Available: {list(benchmark.base_images.keys())}"
        )

    work_data = data["work"]
    work = WorkSpec(
        specs_dir=work_data.get("specs_dir", ""),
        agent_query=work_data.get("agent_query", ""),
        setup_cmds=work_data.get("setup_cmds"),
        image_tag=work_data.get("image_tag"),
        cpu_limit=work_data.get("cpu_limit"),
        mem_limit=work_data.get("mem_limit"),
    )
    judge_data = data["judge"]
    judge = JudgeSpec(
        eval_cmd=judge_data.get("eval_cmd", ""),
        eval_timeout=judge_data.get("eval_timeout", 600),
        parser=judge_data.get("parser", ""),
        setup_cmds=judge_data.get("setup_cmds"),
        image_tag=judge_data.get("image_tag"),
        game_server_cmd=judge_data.get("game_server_cmd"),
        score_direction=judge_data.get("score_direction", "maximize"),
        selection=judge_data.get("selection", "pass_rate_first"),
        rescale=parse_rescale_spec(judge_data.get("rescale")),
        cpu_limit=judge_data.get("cpu_limit"),
        mem_limit=judge_data.get("mem_limit"),
    )

    task_spec = TaskSpec(
        task_id=data["task_id"],
        name=data["name"],
        base_image=base_image_key,
        platform=data["platform"],
        cwd=data["cwd"],
        submit_paths=data["submit_paths"],
        submit_exclude=[e.rstrip("/") for e in data.get("submit_exclude", ["tests/"])],
        work=work,
        judge=judge,
        benchmark_name=benchmark.name,
        base_image_spec=base_image_spec,
        game_mode=data.get("game_mode", False),
        internet=data.get("internet", True),
    )

    _validate_image_tag_consistency(
        data["task_id"], "work",
        work.setup_cmds, work.image_tag,
        lambda: task_spec.work_image_hash,
    )
    _validate_image_tag_consistency(
        data["task_id"], "judge",
        judge.setup_cmds, judge.image_tag,
        lambda: task_spec.judge_image_hash,
    )

    return task_spec


def load_all_tasks(tasks_dir: Path, benchmark: BenchmarkMeta) -> list[TaskSpec]:
    """Load all task specs from a directory of JSON files."""
    tasks = []
    for task_path in sorted(tasks_dir.glob("*.json")):
        tasks.append(make_task_spec(task_path, benchmark))
    return tasks
