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

import fcntl
import os
import secrets
import stat
from pathlib import Path

from typing_extensions import NotRequired, TypedDict

# --- Paths ---
# Resolved from env vars or cwd-relative defaults so sforge works as a
# pip-installed tool without depending on the source checkout location.
LOG_DIR = Path(os.environ.get("SFORGE_LOG_DIR", "logs")).resolve()
TASKS_DIR = Path(os.environ.get("SFORGE_TASKS_DIR", "tasks")).resolve()

BUILD_DIR = LOG_DIR / "build_images"
BASE_IMAGE_BUILD_DIR = BUILD_DIR / "base"
WORK_IMAGE_BUILD_DIR = BUILD_DIR / "work"
JUDGE_IMAGE_BUILD_DIR = BUILD_DIR / "judge"
RUNS_LOG_DIR = LOG_DIR / "runs"

# --- Benchmark registry (name → HuggingFace repo) ---
BENCHMARK_REGISTRY: dict[str, str] = {
    "edgebench": "ByteDance-Seed/EdgeBench",
}
DEFAULT_BENCHMARK = "edgebench"

# --- Defaults ---
DEFAULT_EVAL_INTERVAL = 300  # seconds


def get_admin_secret(log_dir: Path | None = None) -> str:
    """Load or create the host/controller secret without import side effects."""
    configured = os.environ.get("SFORGE_ADMIN_SECRET")
    if configured:
        return configured
    path = (log_dir or LOG_DIR) / ".judge-admin-secret"
    path.parent.mkdir(parents=True, exist_ok=True)
    flags = os.O_RDWR | os.O_CREAT
    if hasattr(os, "O_NOFOLLOW"):
        flags |= os.O_NOFOLLOW
    fd = os.open(path, flags, 0o600)
    with os.fdopen(fd, "r+") as secret_file:
        fcntl.flock(secret_file.fileno(), fcntl.LOCK_EX)
        mode = os.fstat(secret_file.fileno()).st_mode
        if not stat.S_ISREG(mode):
            raise RuntimeError(f"Judge admin secret is not a regular file: {path}")
        os.fchmod(secret_file.fileno(), 0o600)
        secret = secret_file.read().strip()
        if not secret:
            secret = secrets.token_urlsafe(32)
            secret_file.seek(0)
            secret_file.write(secret)
            secret_file.truncate()
            secret_file.flush()
            os.fsync(secret_file.fileno())
        return secret

# --- Docker ---
DOCKER_USER = "root"
UTF8 = "utf-8"

# --- Log markers (reuse SWE-bench convention) ---
START_TEST_OUTPUT = ">>>>> Start Test Output"
END_TEST_OUTPUT = ">>>>> End Test Output"

# --- Test status ---
PASSED = "PASSED"
FAILED = "FAILED"
ERROR = "ERROR"
SKIPPED = "SKIPPED"


class WorkConfig(TypedDict):
    specs_dir: NotRequired[str]
    agent_query: NotRequired[str]
    setup_cmds: NotRequired[list[str]]
    image_tag: NotRequired[str]


class JudgeConfig(TypedDict):
    eval_cmd: str
    eval_timeout: int
    parser: str
    score_direction: NotRequired[str]
    selection: NotRequired[str]
    setup_cmds: NotRequired[list[str]]
    image_tag: NotRequired[str]


class SForgeTask(TypedDict):
    task_id: str
    name: str
    base_image: str
    platform: str
    cwd: str
    submit_paths: list[str]
    work: WorkConfig
    judge: JudgeConfig
    internet: NotRequired[bool]
