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

"""One transport contract for every SForge Judge HTTP request."""

from __future__ import annotations

import logging
import time
from collections.abc import Callable
from dataclasses import dataclass, field

import requests

E2B_TRAFFIC_ACCESS_HEADER = "e2b-traffic-access-token"
SFORGE_ADMIN_SECRET_HEADER = "X-SForge-Admin-Secret"

logger = logging.getLogger(__name__)

E2B_CONNECT_ATTEMPTS = 3
E2B_CONNECT_TIMEOUT = 10


@dataclass(frozen=True)
class JudgeConnection:
    url: str
    headers: dict[str, str] = field(default_factory=dict)
    connect_attempts: int = 1
    request_handler: Callable[..., requests.Response] | None = field(
        default=None, repr=False, compare=False,
    )

    @classmethod
    def from_e2b_traffic_token(
        cls,
        url: str,
        token: str | None,
    ) -> JudgeConnection:
        """Create a Judge connection through an optional secured E2B gateway."""
        headers = {E2B_TRAFFIC_ACCESS_HEADER: token} if token else {}
        return cls(
            url=url.rstrip("/"),
            headers=headers,
            connect_attempts=E2B_CONNECT_ATTEMPTS if token else 1,
        )

    def request(self, method: str, path: str, **kwargs):
        headers = {**self.headers, **(kwargs.pop("headers", None) or {})}
        if self.request_handler is not None:
            return self.request_handler(
                method, path, headers=headers, **kwargs,
            )
        url = f"{self.url}/{path.lstrip('/')}"
        timeout = kwargs.get("timeout")
        if self.connect_attempts > 1 and isinstance(timeout, (int, float)):
            # A scalar applies to both connect and response reads. Keep the
            # caller's response budget, but fail fast enough to retry a flaky
            # E2B public-gateway connection. A ConnectTimeout happens before
            # the request is sent, so retrying POST is safe here.
            kwargs["timeout"] = (min(E2B_CONNECT_TIMEOUT, timeout), timeout)

        for attempt in range(1, self.connect_attempts + 1):
            try:
                return requests.request(
                    method, url, headers=headers, **kwargs,
                )
            except requests.ConnectTimeout:
                if attempt == self.connect_attempts:
                    raise
                logger.warning(
                    "E2B Judge gateway connect timed out for %s %s "
                    "(attempt %d/%d); retrying",
                    method, path, attempt, self.connect_attempts,
                )
                time.sleep(attempt)
        raise AssertionError("unreachable")

    def agent_env(self) -> dict[str, str]:
        env = {"SFORGE_JUDGE_URL": self.url}
        token = self.headers.get(E2B_TRAFFIC_ACCESS_HEADER)
        if token:
            env["SFORGE_JUDGE_ACCESS_TOKEN"] = token
        return env


def merge_no_proxy(current: str, hostname: str) -> str:
    """Append one exact hostname without substring-based false matches."""
    entries = [item.strip() for item in current.split(",") if item.strip()]
    if hostname and hostname not in entries:
        entries.append(hostname)
    return ",".join(entries)
