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

"""Benchmarks and their tasks.

A benchmark is a directory with ``benchmark.toml``, ``tasks/<id>/{task.toml,
instruction.md, environment/, judge/}`` and optional shared toolchain images in
``bases/<name>/``, passed to task Dockerfiles as ``--build-arg BASE_IMAGE``.
The task directory is the source of truth for a task. Image tags are content
hashes of what goes into each image, so an image is rebuilt exactly when its
inputs change.
"""

from __future__ import annotations

import hashlib
import tomllib
from dataclasses import dataclass
from functools import cache, cached_property
from pathlib import Path

from sforge.harness.constants import CONTAINER_DIR
from sforge.harness.score_rescale import RescaleSpec, parse_rescale_spec

# Written by the grader inside the judge container (see the task-format docs).
RESULT_PATH = f"{CONTAINER_DIR}/result.json"


@dataclass(frozen=True)
class WorkSpec:
    instruction: str
    cpu_limit: int | None = None
    mem_limit: str | None = None


@dataclass(frozen=True)
class JudgeSpec:
    cmd: str
    timeout: int
    direction: str = "maximize"
    rescale: RescaleSpec | None = None
    cpu_limit: int | None = None
    mem_limit: str | None = None
    game_server_cmd: str | None = None
    # Graders run submission code; they get no network unless the task needs it
    # (e.g. an LLM-judged task).
    internet: bool = False


@dataclass(frozen=True)
class Blob:
    """A large file kept out of git: fetched by sha256 into ``task_dir/path``."""
    path: str
    sha256: str


@dataclass(frozen=True)
class Benchmark:
    root: Path
    name: str                   # image name prefix: <name>.{base,work,judge}.<id>
    registry: str | None = None  # where pre-built images live (sforge pull, k8s)
    blob_url: str | None = None  # where task blobs are downloaded from, as <url>/<sha256>


@cache
def load_benchmark(root: Path) -> Benchmark:
    root = root.resolve()
    path = root / "benchmark.toml"
    if not path.exists():
        raise FileNotFoundError(f"{path} not found: pass --benchmark <dir> or set SFORGE_BENCHMARK")
    data = tomllib.loads(path.read_text())
    return Benchmark(root, data["name"], data.get("registry"), data.get("blob_url"))


@dataclass(frozen=True)
class TaskSpec:
    task_id: str
    name: str
    version: str
    task_dir: Path
    benchmark: Benchmark
    platform: str
    cwd: str
    internet: bool
    submit_paths: list[str]
    submit_exclude: list[str]
    work: WorkSpec
    judge: JudgeSpec
    base: str | None = None
    blobs: tuple[Blob, ...] = ()

    @property
    def game_mode(self) -> bool:
        return self.judge.game_server_cmd is not None

    @property
    def base_dir(self) -> Path | None:
        return self.benchmark.root / "bases" / self.base if self.base else None

    @cached_property
    def base_image_key(self) -> str | None:
        if not self.base:
            return None
        return f"{self.benchmark.name}.base.{self.base}:{_tree_hash(self.base_dir)}"

    @cached_property
    def work_image_key(self) -> str:
        return f"{self.benchmark.name}.work.{self.task_id}:{self._hash('environment')}"

    @cached_property
    def judge_image_key(self) -> str:
        return f"{self.benchmark.name}.judge.{self.task_id}:{self._hash('environment', 'judge')}"

    def _hash(self, *parts: str) -> str:
        # Blobs count by their declared sha256, so the key is the same whether
        # or not they have been downloaded yet.
        blobs = {self.task_dir / b.path for b in self.blobs}
        h = hashlib.sha256((self.base_image_key or "").encode())
        for part in parts:
            h.update(_tree_hash(self.task_dir / part, skip=blobs).encode())
        for b in self.blobs:
            if b.path.split("/", 1)[0] in parts:
                h.update(f"B {b.path} {b.sha256}\n".encode())
        return h.hexdigest()[:12]


def _tree_hash(root: Path, skip: set[Path] = frozenset()) -> str:
    """Hash of every file under *root*: relative path, executable bit, content."""
    h = hashlib.sha256()
    for path in sorted(p for p in root.rglob("*") if (p.is_file() or p.is_symlink()) and p not in skip):
        rel = path.relative_to(root).as_posix()
        if path.is_symlink():
            h.update(f"L {rel} {path.readlink()}\n".encode())
            continue
        mode = "x" if path.stat().st_mode & 0o111 else "-"
        h.update(f"F {rel} {mode} ".encode())
        with open(path, "rb") as fh:
            for chunk in iter(lambda: fh.read(1 << 20), b""):
                h.update(chunk)
        h.update(b"\n")
    return h.hexdigest()[:12]


def load_task(task_dir: Path, benchmark: Benchmark | None = None) -> TaskSpec:
    """Load ``<benchmark>/tasks/<id>/``; the benchmark defaults to the one that contains it."""
    task_dir = task_dir.resolve()
    benchmark = benchmark or load_benchmark(task_dir.parent.parent)
    data = tomllib.loads((task_dir / "task.toml").read_text())
    env = data["environment"]
    sub = data.get("submission", {})
    judge = data["judge"]
    score = data.get("score", {})
    game = data.get("game", {})
    if data["id"] != task_dir.name:
        raise ValueError(f"{task_dir}: task.toml id {data['id']!r} does not match the directory name")
    return TaskSpec(
        task_id=data["id"],
        name=data.get("name", data["id"]),
        version=data.get("version", "0"),
        task_dir=task_dir,
        benchmark=benchmark,
        platform=env.get("platform", "linux/amd64"),
        cwd=env["cwd"],
        internet=env.get("internet", False),
        submit_paths=sub.get("paths", ["."]),
        submit_exclude=[e.rstrip("/") for e in sub.get("exclude", [])],
        work=WorkSpec(
            instruction=(task_dir / "instruction.md").read_text(),
            cpu_limit=env.get("cpus"),
            mem_limit=env.get("memory"),
        ),
        judge=JudgeSpec(
            cmd=judge["cmd"],
            timeout=judge.get("timeout_sec", 600),
            direction=score.get("direction", "maximize"),
            rescale=parse_rescale_spec(score.get("rescale")),
            cpu_limit=judge.get("cpus"),
            mem_limit=judge.get("memory"),
            game_server_cmd=game.get("server_cmd"),
            internet=judge.get("internet", False),
        ),
        base=env.get("base"),
        blobs=tuple(Blob(b["path"], b["sha256"]) for b in data.get("blobs", [])),
    )


def load_all_tasks(benchmark: Benchmark) -> list[TaskSpec]:
    """Every ``tasks/<id>/task.toml`` of the benchmark."""
    return [load_task(p.parent, benchmark) for p in sorted((benchmark.root / "tasks").glob("*/task.toml"))]
