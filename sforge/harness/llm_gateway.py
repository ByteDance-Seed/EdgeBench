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

"""LLM gateway on the judge server: per-run forwarding + token accounting.

Agents talk to ``{judge_url}/api/v1/llm/{session_token}/...`` instead of the
model API. The judge server forwards each request to the run's upstream,
swaps the placeholder key the sandbox holds for the real one (the real key
never enters the sandbox), and records the usage the upstream reports —
including usage that only arrives in late stream events, which agents
themselves often miss.
"""

from __future__ import annotations

import json
import logging
import threading
import time
from pathlib import Path
from typing import Any

import httpx
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse, StreamingResponse

logger = logging.getLogger(__name__)

# Value the sandbox sees wherever the real API key would be.
PLACEHOLDER_KEY = "sforge-gateway"
ROUTE_PREFIX = "/api/v1/llm"

_HOP_HEADERS = {
    "host", "content-length", "transfer-encoding", "connection", "keep-alive",
    "accept-encoding", "content-encoding",
}
USAGE_FIELDS = ("input_tokens", "cache_read_tokens", "cache_write_tokens",
                "output_tokens", "reasoning_tokens")


def normalize_usage(u: dict) -> dict[str, int]:
    """Map Anthropic / OpenAI Responses / Chat Completions usage onto one
    shape. ``input_tokens`` excludes cached input in every dialect."""
    def n(*keys: str, src: dict = u) -> int:
        for k in keys:
            v = src.get(k)
            if isinstance(v, (int, float)):
                return int(v)
        return 0

    if "prompt_tokens" in u or "completion_tokens" in u:  # chat completions
        cached = n("cached_tokens", src=u.get("prompt_tokens_details") or {})
        return {
            "input_tokens": max(n("prompt_tokens") - cached, 0),
            "cache_read_tokens": cached,
            "cache_write_tokens": 0,
            "output_tokens": n("completion_tokens"),
            "reasoning_tokens": n("reasoning_tokens", src=u.get("completion_tokens_details") or {}),
        }
    if "input_tokens_details" in u or "output_tokens_details" in u:  # responses
        cached = n("cached_tokens", src=u.get("input_tokens_details") or {})
        return {
            "input_tokens": max(n("input_tokens") - cached, 0),
            "cache_read_tokens": cached,
            "cache_write_tokens": 0,
            "output_tokens": n("output_tokens"),
            "reasoning_tokens": n("reasoning_tokens", src=u.get("output_tokens_details") or {}),
        }
    return {  # anthropic messages
        "input_tokens": n("input_tokens"),
        "cache_read_tokens": n("cache_read_input_tokens"),
        "cache_write_tokens": n("cache_creation_input_tokens"),
        "output_tokens": n("output_tokens"),
        "reasoning_tokens": 0,
    }


def _usage_in(obj: Any) -> dict | None:
    """The usage object carried by one response body or stream event."""
    if not isinstance(obj, dict):
        return None
    for holder in (obj, obj.get("message"), obj.get("response")):
        if isinstance(holder, dict) and isinstance(holder.get("usage"), dict):
            return holder["usage"]
    return None


class UsageTracker:
    """Collects the usage of one response: Anthropic streams split it across
    ``message_start`` and ``message_delta``, so each field keeps its maximum."""

    def __init__(self) -> None:
        self.usage = dict.fromkeys(USAGE_FIELDS, 0)
        self.seen = False
        self._buf = b""

    def feed_event(self, obj: Any) -> None:
        u = _usage_in(obj)
        if u is None:
            return
        self.seen = True
        for k, v in normalize_usage(u).items():
            self.usage[k] = max(self.usage[k], v)

    def feed_sse(self, chunk: bytes) -> None:
        self._buf += chunk
        *lines, self._buf = self._buf.split(b"\n")
        for line in lines:
            line = line.strip()
            if line.startswith(b"data:"):
                try:
                    self.feed_event(json.loads(line[5:]))
                except ValueError:
                    pass


class UsageLog:
    """Per-run request log (``llm_requests.jsonl``) and running totals."""

    def __init__(self, path: Path) -> None:
        self.path = path
        self.totals: dict[str, Any] = {"requests": 0, "errors": 0,
                                       "missing_usage": 0, **dict.fromkeys(USAGE_FIELDS, 0)}
        self.by_model: dict[str, dict[str, int]] = {}
        self._lock = threading.Lock()

    def add(self, record: dict) -> None:
        with self._lock:
            self.totals["requests"] += 1
            if record["status"] >= 400:
                self.totals["errors"] += 1
            elif record["usage"] is None:
                self.totals["missing_usage"] += 1
            if record["usage"]:
                model = self.by_model.setdefault(
                    record.get("model") or "?", dict.fromkeys(USAGE_FIELDS, 0))
                for k in USAGE_FIELDS:
                    self.totals[k] += record["usage"][k]
                    model[k] += record["usage"][k]
            self.path.parent.mkdir(parents=True, exist_ok=True)
            with open(self.path, "a") as f:
                f.write(json.dumps(record) + "\n")

    def summary(self) -> dict:
        with self._lock:
            return {**self.totals, "by_model": {k: dict(v) for k, v in self.by_model.items()}}


def add_gateway_routes(app: FastAPI, state, client: httpx.AsyncClient) -> None:
    """Register the forwarding route. ``state`` resolves tokens to run info
    holding ``llm_base_url``, ``llm_api_key`` and a ``usage_log``."""

    @app.api_route(
        ROUTE_PREFIX + "/{token}/{path:path}",
        methods=["GET", "POST", "PUT", "PATCH", "DELETE"],
    )
    async def llm_forward(token: str, path: str, request: Request):
        try:
            run = state.gateway_run(token)
        except KeyError:
            return JSONResponse({"error": "invalid token"}, status_code=401)

        body = await request.body()
        headers = {k: v for k, v in request.headers.items() if k.lower() not in _HOP_HEADERS}
        key = run["llm_api_key"] or ""
        for name in list(headers):
            if PLACEHOLDER_KEY in headers[name]:
                headers[name] = headers[name].replace(PLACEHOLDER_KEY, key)
        url = f"{run['llm_base_url'].rstrip('/')}/{path}"
        if request.url.query:
            url += f"?{request.url.query}"

        record: dict[str, Any] = {"ts": time.time(), "path": "/" + path, "model": None,
                                  "request_bytes": len(body)}
        try:
            req_json = json.loads(body) if body else {}
            record["model"] = req_json.get("model") if isinstance(req_json, dict) else None
        except ValueError:
            pass

        started = time.monotonic()
        try:
            upstream = await client.send(
                client.build_request(request.method, url, headers=headers, content=body),
                stream=True,
            )
        except httpx.HTTPError as exc:
            record.update(status=502, usage=None, error=str(exc)[:500],
                          elapsed_s=round(time.monotonic() - started, 3))
            run["usage_log"].add(record)
            return JSONResponse({"error": f"upstream unreachable: {exc}"}, status_code=502)

        tracker = UsageTracker()
        streaming = "text/event-stream" in upstream.headers.get("content-type", "")
        resp_headers = {k: v for k, v in upstream.headers.items() if k.lower() not in _HOP_HEADERS}

        async def relay():
            first = None
            body_parts: list[bytes] = []
            try:
                async for chunk in upstream.aiter_bytes():
                    if first is None:
                        first = time.monotonic() - started
                    if streaming:
                        tracker.feed_sse(chunk)
                    else:
                        body_parts.append(chunk)
                    yield chunk
            finally:
                await upstream.aclose()
                if not streaming and body_parts:
                    try:
                        tracker.feed_event(json.loads(b"".join(body_parts)))
                    except ValueError:
                        pass
                record.update(
                    status=upstream.status_code,
                    usage=tracker.usage if tracker.seen else None,
                    first_byte_s=None if first is None else round(first, 3),
                    elapsed_s=round(time.monotonic() - started, 3),
                )
                run["usage_log"].add(record)

        return StreamingResponse(relay(), status_code=upstream.status_code,
                                 headers=resp_headers)


def make_client(https_proxy: str | None, no_proxy: str | None = None) -> httpx.AsyncClient:
    """Upstream client: through ``https_proxy`` except for ``no_proxy`` hosts
    (domain suffixes like ``.example.com`` and exact hosts; CIDRs are ignored)."""
    mounts: dict[str, httpx.AsyncBaseTransport | None] = {}
    if https_proxy:
        for entry in (no_proxy or "").split(","):
            host = entry.strip().lstrip("*").lstrip(".")
            if host and "/" not in host:
                mounts[f"all://{host}"] = httpx.AsyncHTTPTransport()
                mounts[f"all://*.{host}"] = httpx.AsyncHTTPTransport()
        mounts["all://"] = httpx.AsyncHTTPTransport(proxy=https_proxy)
    # Long reads: reasoning models stream 20k-token turns; a short connect
    # timeout already bit us (TLS handshakes > 30s under load).
    return httpx.AsyncClient(
        timeout=httpx.Timeout(connect=120, read=1800, write=300, pool=None),
        mounts=mounts or None,
        trust_env=False,
    )
