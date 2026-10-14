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

"""Host admission for an already restored judge registration.

The controller supplies its durable activation deadline. Agent-specific code,
model/session and research-state installation remains the Agent's responsibility;
this module never restores a model session or creates judge authority.
"""

from __future__ import annotations

import hashlib
import json
import math
import os
import re
import time
from dataclasses import dataclass
from pathlib import Path

import requests


@dataclass(frozen=True)
class RestoredRegistration:
    checkpoint_id: str
    manifest_sha256: str
    deadline_epoch: float
    manifest_path: Path

    def __post_init__(self):
        if not isinstance(self.checkpoint_id, str) or not re.fullmatch(
            r"[0-9a-f]{32}", self.checkpoint_id
        ):
            raise ValueError("A native checkpoint identifier is required")
        if not isinstance(self.manifest_sha256, str) or not re.fullmatch(
            r"[0-9a-f]{64}", self.manifest_sha256
        ):
            raise ValueError("A native checkpoint manifest digest is required")
        if (
            type(self.deadline_epoch) not in (int, float)
            or not math.isfinite(self.deadline_epoch)
            or self.deadline_epoch <= 0
        ):
            raise ValueError("An absolute finite activation deadline is required")


class RestoredExecution:
    """Exclusive host attempt; retries retain the original deadline and origin.

    No credentials are persisted. Once model work starts, a new invocation may
    not reinstall an old prefix over that work; ordinary in-process resume still
    uses run_agent's existing loop. Ambiguous launch crashes require inspection.
    """

    def __init__(
        self,
        registration: RestoredRegistration,
        log_dir: Path,
        run_id: str,
        task_id: str,
        shutdown_event,
    ):
        import fcntl

        self.registration = registration
        self.shutdown_event = shutdown_event
        self.monotonic_deadline = (
            time.monotonic() + registration.deadline_epoch - time.time()
        )
        self.file = None
        self.record = {
            "checkpoint_id": registration.checkpoint_id,
            "manifest_sha256": registration.manifest_sha256,
            "deadline_epoch": registration.deadline_epoch,
            "run_id": run_id,
            "task_id": task_id,
        }
        self.remaining()
        path = log_dir / "restored-execution.json"
        fd = os.open(path, os.O_CREAT | os.O_RDWR | os.O_NOFOLLOW, 0o600)
        self.file = os.fdopen(fd, "r+")
        try:
            fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
            raw = self.file.read()
            if raw:
                prior = json.loads(raw)
                if prior != {**self.record, "work_started": False}:
                    raise ValueError(
                        "Restored execution differs or has already entered work; inspect the retained attempt"
                    )
            else:
                self._save(False)
                directory = os.open(log_dir, os.O_RDONLY)
                try:
                    os.fsync(directory)
                finally:
                    os.close(directory)
        except BaseException:
            self.close()
            raise

    def _save(self, work_started: bool):
        self.file.seek(0)
        json.dump(
            {**self.record, "work_started": work_started},
            self.file,
            sort_keys=True,
            allow_nan=False,
        )
        self.file.truncate()
        self.file.flush()
        os.fsync(self.file.fileno())

    def remaining(self) -> float:
        if self.shutdown_event is not None and self.shutdown_event.is_set():
            raise InterruptedError("Restored execution was cancelled")
        remaining = min(
            self.registration.deadline_epoch - time.time(),
            self.monotonic_deadline - time.monotonic(),
        )
        if remaining < 1:
            raise TimeoutError("The original restored execution deadline is exhausted")
        return remaining

    def timeout(self, maximum: float) -> int:
        return max(1, int(min(maximum, self.remaining())))

    def start_work(self):
        self.remaining()
        self._save(True)

    def registration_result(self, url: str, admin_secret: str) -> dict:
        # The evaluator may deliberately run its original pinned source while
        # this host runner is newer. Read the exact native manifest confirmed by
        # restore-result, rather than requiring extra response fields or relaxing
        # the evaluator's source fingerprint. Native restore owns schema/policy
        # validation; this consumer binds its task and prompt to the same bytes.
        encoded = self.registration.manifest_path.read_bytes()
        if hashlib.sha256(encoded).hexdigest() != self.registration.manifest_sha256:
            raise ValueError("Restored registration manifest digest differs")
        packet = json.loads(encoded)
        if packet.get("task_id") != self.record["task_id"]:
            raise ValueError("Restored registration manifest names a different task")
        request = {
            key: self.record[key]
            for key in ("checkpoint_id", "manifest_sha256", "run_id")
        }
        response = requests.post(
            url + "/api/v1/checkpoint/restore-result",
            json={**request, "admin_secret": admin_secret},
            timeout=self.timeout(10),
        )
        response.raise_for_status()
        result = response.json()
        if any(result.get(key) != value for key, value in request.items()):
            raise ValueError(
                "Restored registration does not match the requested task and origin"
            )
        if not isinstance(result.get("token"), str) or not result["token"]:
            raise ValueError("Restored registration has no live authority")
        self.remaining()
        return {
            **result,
            "max_agent_submissions": packet["opportunity"]["max_agent_submissions"],
            "submission_cooldown": packet["opportunity"]["submission_cooldown"],
            "judge_cpu_limit": packet["resources"]["judge_cpu_limit"],
            "judge_mem_limit": packet["resources"]["judge_mem_limit"],
        }

    def close(self):
        if self.file is not None:
            self.file.close()
            self.file = None
