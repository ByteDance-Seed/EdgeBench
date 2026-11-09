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

"""Service-observed evaluation inputs, distinct from a caller's version labels."""

from __future__ import annotations

import hashlib
import json
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field

from sforge.harness.backend import ContainerBackend
from sforge.harness.config import SForgeConfig
from sforge.harness.run_evaluation import judge_container_options
from sforge.harness.task_spec import TaskSpec, task_spec_sha256


class EvaluationConditions(BaseModel):
    model_config = ConfigDict(frozen=True, extra="forbid")

    schema_version: Literal["sforge_evaluation_conditions_v1"] = "sforge_evaluation_conditions_v1"
    task_sha256: str = Field(pattern=r"^[0-9a-f]{64}$")
    benchmark_sha256: str = Field(pattern=r"^[0-9a-f]{64}$")
    task_spec_sha256: str = Field(pattern=r"^[0-9a-f]{64}$")
    native_source_sha256: str = Field(pattern=r"^[0-9a-f]{64}$")
    judge_image_id: str = Field(pattern=r"^sha256:[0-9a-f]{64}$")
    execution_config_sha256: str = Field(pattern=r"^[0-9a-f]{64}$")
    score_direction: Literal["maximize", "minimize"]
    selection: str


class RunEvaluationContext(BaseModel):
    model_config = ConfigDict(frozen=True, extra="forbid")

    schema_version: Literal["sforge_run_evaluation_context_v1"] = "sforge_run_evaluation_context_v1"
    task_id: str
    run_id: str
    registration_id: str
    evaluation_conditions: EvaluationConditions | None


@dataclass(frozen=True)
class RegisteredEvaluator:
    """Keep accepted work on its own registration's executable inputs."""

    task: TaskSpec
    config: SForgeConfig
    backend: ContainerBackend
    context: RunEvaluationContext


def native_source_sha256(source_root: Path | None = None) -> str | None:
    """Observe the installed Python source once at service boot, not per read."""
    if source_root is None:
        import sforge

        source_root = Path(sforge.__file__).parent
    digest = hashlib.sha256()
    try:
        paths = sorted(source_root.rglob("*.py"))
        if not paths:
            return None
        for path in paths:
            digest.update(path.relative_to(source_root).as_posix().encode() + b"\0")
            digest.update(hashlib.sha256(path.read_bytes()).digest())
    except OSError:
        return None
    return digest.hexdigest()


def capture_conditions(
    task: TaskSpec, backend: ContainerBackend, source_sha256: str | None, config: SForgeConfig,
) -> EvaluationConditions | None:
    """Unknown image/data identity preserves feedback without claiming attribution.

    The Docker content ID identifies the evaluator and data in that image. It
    does not attest mutable external services or deterministic/hermetic grading.
    Reading context never builds an image or downloads a task blob.
    """
    revision = getattr(task, "_source_revision", None)
    if revision is None or source_sha256 is None or task.game_mode or backend.backend_name != "docker":
        return None
    try:
        effective = task_spec_sha256(task)
    except (TypeError, ValueError):
        return None
    if effective != revision.task_spec_sha256 or task.judge.direction not in ("maximize", "minimize"):
        return None
    try:
        image_id = backend.client.images.get(task.judge_image_key).id
    except Exception:
        return None
    if not isinstance(image_id, str) or not re.fullmatch(r"sha256:[0-9a-f]{64}", image_id):
        return None
    execution = {**judge_container_options(task, config),
                 "timeout": task.judge.timeout, "platform": task.platform}
    try:
        raw = json.dumps(execution, sort_keys=True, separators=(",", ":"),
                         ensure_ascii=False, allow_nan=False).encode()
    except (TypeError, ValueError):
        return None
    return EvaluationConditions(
        task_sha256=revision.task_sha256,
        benchmark_sha256=revision.benchmark_sha256,
        task_spec_sha256=effective,
        native_source_sha256=source_sha256,
        judge_image_id=image_id,
        execution_config_sha256=hashlib.sha256(raw).hexdigest(),
        score_direction=task.judge.direction,
        # Modern grading.select_best filters valid completed entries, compares
        # their raw score in this direction and retains the first tie.
        selection="valid_then_score",
    )
