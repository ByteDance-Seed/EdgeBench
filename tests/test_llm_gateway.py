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

"""LLM gateway: forwarding, key swap and usage accounting."""

from __future__ import annotations

import json

import httpx
from fastapi import FastAPI
from fastapi.testclient import TestClient

from sforge.harness.llm_gateway import (
    PLACEHOLDER_KEY,
    UsageLog,
    add_gateway_routes,
    normalize_usage,
)

SSE = (
    'event: message_start\n'
    'data: {"type":"message_start","message":{"model":"m","usage":{"input_tokens":0,'
    '"cache_read_input_tokens":0,"output_tokens":1}}}\n\n'
    'event: content_block_delta\n'
    'data: {"type":"content_block_delta","delta":{"text":"hi"}}\n\n'
    'event: message_delta\n'
    'data: {"type":"message_delta","usage":{"input_tokens":1200,'
    '"cache_read_input_tokens":800,"cache_creation_input_tokens":50,"output_tokens":42}}\n\n'
)


class State:
    def __init__(self, tmp_path):
        self.log = UsageLog(tmp_path / "llm_requests.jsonl")

    def gateway_run(self, token):
        if token != "tok":
            raise KeyError(token)
        return {"llm_base_url": "https://up.example/api", "llm_api_key": "REAL",
                "usage_log": self.log}


def make(tmp_path, seen):
    def upstream(request: httpx.Request) -> httpx.Response:
        seen.append(request)
        if request.url.path.endswith("/v1/messages"):
            return httpx.Response(200, text=SSE, headers={"content-type": "text/event-stream"})
        body = {"usage": {"prompt_tokens": 100, "completion_tokens": 7,
                          "prompt_tokens_details": {"cached_tokens": 60}}}
        return httpx.Response(200, json=body)

    state = State(tmp_path)
    app = FastAPI()
    add_gateway_routes(app, state, httpx.AsyncClient(transport=httpx.MockTransport(upstream)))
    return TestClient(app), state


def test_stream_forwarding_key_swap_and_late_usage(tmp_path):
    seen = []
    client, state = make(tmp_path, seen)
    r = client.post("/api/v1/llm/tok/v1/messages?beta=true",
                    headers={"x-api-key": PLACEHOLDER_KEY, "anthropic-version": "2023-06-01"},
                    json={"model": "m", "stream": True})
    assert r.status_code == 200 and "message_delta" in r.text
    req = seen[0]
    assert str(req.url) == "https://up.example/api/v1/messages?beta=true"
    assert req.headers["x-api-key"] == "REAL"
    rec = json.loads((tmp_path / "llm_requests.jsonl").read_text().splitlines()[0])
    assert rec["usage"] == {"input_tokens": 1200, "cache_read_tokens": 800,
                            "cache_write_tokens": 50, "output_tokens": 42, "reasoning_tokens": 0}
    assert rec["model"] == "m" and rec["status"] == 200


def test_json_response_and_totals(tmp_path):
    seen = []
    client, state = make(tmp_path, seen)
    r = client.post("/api/v1/llm/tok/v1/chat/completions",
                    headers={"authorization": f"Bearer {PLACEHOLDER_KEY}"}, json={"model": "g"})
    assert r.status_code == 200
    assert seen[0].headers["authorization"] == "Bearer REAL"
    s = state.log.summary()
    assert s["requests"] == 1 and s["input_tokens"] == 40 and s["cache_read_tokens"] == 60
    assert s["by_model"]["g"]["output_tokens"] == 7


def test_invalid_token(tmp_path):
    client, _ = make(tmp_path, [])
    assert client.post("/api/v1/llm/nope/v1/messages", json={}).status_code == 401


def test_normalize_responses_api():
    u = normalize_usage({"input_tokens": 50, "output_tokens": 9,
                         "input_tokens_details": {"cached_tokens": 20},
                         "output_tokens_details": {"reasoning_tokens": 4}})
    assert u == {"input_tokens": 30, "cache_read_tokens": 20, "cache_write_tokens": 0,
                 "output_tokens": 9, "reasoning_tokens": 4}


def test_route_through_gateway_rewrites_env():
    from sforge.harness.agent import create_agent
    from sforge.harness.config import SForgeConfig
    from sforge.harness.run_agent import _build_agent_env, _route_through_gateway

    cfg = SForgeConfig()
    cfg.agent_api_base_url = "https://relay.example"
    cfg.agent_api_key = "sk-real-123"
    gw = "http://judge:8080/api/v1/llm/tok"
    for spec in ("claude-code", "codex", "opencode"):
        agent = create_agent(spec, cfg)
        env = _build_agent_env(agent, "some-model")
        _route_through_gateway(env, agent, cfg.agent_api_base_url, cfg.agent_api_key, gw)
        blob = json.dumps(env)
        assert "sk-real-123" not in blob and "relay.example" not in blob, spec
        assert gw in blob, spec


def test_make_client_bypasses_no_proxy_hosts():
    from sforge.harness.llm_gateway import make_client

    client = make_client("http://proxy.example:8118", ".corp.example,localhost,10.0.0.0/8")
    direct = client._transport_for_url(httpx.URL("https://llm.corp.example/v1/messages"))
    proxied = client._transport_for_url(httpx.URL("https://api.openai.com/v1/responses"))
    assert direct is not proxied
    assert client._transport_for_url(httpx.URL("http://localhost:1/x")) is not proxied
