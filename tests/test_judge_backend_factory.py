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

"""Backend composition through the native judge API, without a cloud account."""

from __future__ import annotations

import json
import time
from pathlib import Path
from types import SimpleNamespace

import pytest
from fastapi.testclient import TestClient

from sforge.harness.backend.base import ExecResult, StreamingExecResult
from sforge.harness.config import SForgeConfig
from sforge.harness.constants import get_admin_secret
from sforge.harness.judge_server import JudgeState, create_app


class Sandbox:
    """External execution seam; the native judge still parses and selects scores."""

    backend_name = "e2b"

    def __init__(self, config, output=None):
        self.config = config
        self.output = output
        self.created = []
        self.cleaned = []

    def create_container(self, image, name, **kwargs):
        handle = SimpleNamespace(id=name, name=name)
        self.created.append((handle, kwargs))
        return handle

    def start_container(self, handle):
        pass

    def copy_to_container(self, *args):
        pass

    def exec_run(self, *args, **kwargs):
        return ExecResult(output="solution\n")

    def exec_run_with_timeout(self, *args, **kwargs):
        if isinstance(self.output, Exception):
            raise self.output
        return StreamingExecResult(output=self.output)

    def cleanup_container(self, handle, logger=None):
        self.cleaned.append(handle)


def config_at(root: Path):
    tasks = root / "tasks"
    tasks.mkdir(parents=True)
    (tasks / "BENCHMARK.yaml").write_text(
        "name: synthetic\nbase_images:\n  base: {dockerfile: synthetic}\n"
    )
    (tasks / "sample.json").write_text(
        json.dumps(
            {
                "task_id": "sample",
                "name": "sample",
                "base_image": "base",
                "platform": "linux/amd64",
                "cwd": "/work",
                "submit_paths": ["solution"],
                "work": {"agent_query": "synthetic", "image_tag": "work"},
                "judge": {
                    "eval_cmd": "synthetic",
                    "parser": "structured_json",
                    "selection": "score_first",
                    "image_tag": "judge",
                },
            }
        )
    )
    return SForgeConfig(
        tasks_dir=tasks,
        log_dir=root / "logs",
        backend="e2b",
        e2b_template_map={"synthetic": "first"},
    )


def register(client, config, **overrides):
    return client.post(
        "/api/v1/register",
        json={
            "task_id": "sample",
            "run_id": "trial",
            "admin_secret": get_admin_secret(config.log_dir),
            **overrides,
        },
    )


@pytest.mark.parametrize(
    "output,expected",
    [
        (json.dumps({"score": 7, "valid": True}), 7),
        (json.dumps({"score": 0, "valid": False}), 0),
        (RuntimeError("synthetic backend failure"), None),
    ],
)
def test_http_registration_override_uses_app_factory(tmp_path, output, expected):
    config = config_at(tmp_path)
    backends = []

    def factory(effective):
        result = Sandbox(effective, output=output)
        backends.append(result)
        return result

    with TestClient(create_app(config, backend_factory=factory)) as client:
        response = register(
            client,
            config,
            backend="e2b",
            e2b_template_map={"synthetic": "second"},
            e2b_sandbox_ttl=3600,
            judge_cpu_limit=3,
        )
        assert response.status_code == 200
        token = response.json()["token"]
        submission = client.post(
            "/api/v1/submit",
            data={"token": token},
            files={"archive": ("patch.tar.gz", b"synthetic")},
        )
        assert submission.status_code == 200
        submission_id = submission.json()["submission_id"]
        deadline = time.monotonic() + 5
        while time.monotonic() < deadline:
            result = client.get(f"/api/v1/result/{submission_id}").json()
            if result["status"] in ("completed", "error"):
                break
            time.sleep(0.01)
        assert result["status"] == "completed"
        assert result["report"]["score"] == expected
        assert (
            client.get("/api/v1/history", params={"token": token}).json()["best_score"]
            == expected
        )
    assert len(backends) == 2
    assert not backends[0].created
    assert backends[1].config.e2b_template_map == {"synthetic": "second"}
    assert backends[1].config.e2b_sandbox_ttl == 3600
    assert backends[1].created[0][1]["cpu_limit"] == 3
    assert backends[1].cleaned == [backends[1].created[0][0]]


@pytest.mark.parametrize("failure", ["raise", "none"])
def test_rejected_registration_preserves_existing_session(tmp_path, failure):
    config = config_at(tmp_path)

    def factory(effective):
        if effective.e2b_sandbox_ttl == 1:
            if failure == "raise":
                raise ValueError("unsupported lease")
            return None
        return Sandbox(effective)

    state = JudgeState(config, backend_factory=factory)
    try:
        state.load_tasks()
        token = state.register_session("sample", "trial", judge_cpu_limit=2)
        original_tokens = dict(state.tokens)
        original_resources = dict(state.run_resource_limits)
        original_backends = dict(state.run_backends)
        with pytest.raises((ValueError, TypeError)):
            state.register_session(
                "sample", "trial", e2b_sandbox_ttl=1, judge_cpu_limit=99
            )
        assert state.tokens == original_tokens
        assert state.run_resource_limits == original_resources
        assert state.run_backends == original_backends
        assert state.resolve_token(token)["judge_cpu_limit"] == 2
    finally:
        state._reaper_stop.set()
        state._reaper_thread.join(timeout=1)


def test_factory_is_app_local_and_checks_unchanged_backend(tmp_path):
    configs = [config_at(tmp_path / name) for name in ("first", "second")]
    seen = [[], []]

    def factory(index):
        def build(config):
            seen[index].append(config)
            if config.judge_cpu_limit == 99:
                raise ValueError("unsupported resource request")
            return Sandbox(config)

        return build

    apps = [create_app(c, backend_factory=factory(i)) for i, c in enumerate(configs)]
    for i, app in enumerate(apps):
        with TestClient(app) as client:
            assert (
                register(client, configs[i], judge_cpu_limit=i + 1).status_code == 200
            )
            # No backend name was supplied; resource policy must still execute.
            assert register(client, configs[i], judge_cpu_limit=99).status_code != 200
    assert [[c.judge_cpu_limit for c in calls] for calls in seen] == [
        [None, 1, 99],
        [None, 2, 99],
    ]


def test_default_factory_still_handles_config_overrides(tmp_path, monkeypatch):
    config = config_at(tmp_path)
    seen = []

    def default_factory(effective):
        seen.append(effective)
        return Sandbox(effective)

    # Replace only the backend construction seam; no optional factory is passed.
    monkeypatch.setattr(
        "sforge.harness.judge_server.create_backend_from_config", default_factory
    )
    state = JudgeState(config)
    try:
        state.load_tasks()
        state.register_session("sample", "trial", backend="e2b")
        assert len(seen) == 1
        state.register_session("sample", "other", backend="e2b", e2b_sandbox_ttl=3600)
        assert len(seen) == 2
        assert seen[1].e2b_sandbox_ttl == 3600
        assert seen[1].e2b_template_map == config.e2b_template_map
    finally:
        state._reaper_stop.set()
        state._reaper_thread.join(timeout=1)
