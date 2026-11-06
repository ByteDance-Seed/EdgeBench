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

import os
import secrets
import stat
from pathlib import Path, PurePosixPath

# --- Paths ---
# Resolved from env vars or cwd-relative defaults so sforge works as a
# pip-installed tool without depending on the source checkout location.
LOG_DIR = Path(os.environ.get("SFORGE_LOG_DIR", "logs")).resolve()

# Benchmark directory used when neither -b nor SFORGE_BENCHMARK is given:
# EdgeBench, in this repository.
DEFAULT_BENCHMARK_DIR = Path("edgebench")

# Everything SForge puts into a work/judge container lives here.
CONTAINER_DIR = PurePosixPath("/opt/sforge")

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
    import fcntl  # POSIX-only; imported lazily so Windows can still import the package

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


UTF8 = "utf-8"
