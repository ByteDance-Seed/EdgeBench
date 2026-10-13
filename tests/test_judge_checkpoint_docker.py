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

"""Explicit isolated Docker/HTTP qualification; no agent/model/benchmark jobs."""

from __future__ import annotations

import copy
import io
import json
import os
import shutil
import socket
import tarfile
import threading
import time
import uuid
from contextlib import contextmanager
from dataclasses import replace
from types import SimpleNamespace

import pytest

pytestmark = pytest.mark.skipif(
    os.environ.get("SFORGE_CHECKPOINT_DOCKER_TEST") != "1",
    reason="Requires explicit isolated Docker qualification",
)


def wait_for(predicate, timeout=30):
    until = time.monotonic() + timeout
    while time.monotonic() < until:
        value = predicate()
        if value:
            return value
        time.sleep(0.05)
    raise AssertionError("Isolated native HTTP operation did not finish")


@contextmanager
def server(app):
    import uvicorn

    with socket.socket() as probe:
        probe.bind(("127.0.0.1", 0))
        port = probe.getsockname()[1]
    host = uvicorn.Server(
        uvicorn.Config(
            app, host="127.0.0.1", port=port, log_level="error", access_log=False
        )
    )
    thread = threading.Thread(target=host.run)
    thread.start()
    try:
        wait_for(lambda: host.started)
        yield f"http://127.0.0.1:{port}"
    finally:
        host.should_exit = True
        thread.join(timeout=10)
        app.state.judge._reaper_stop.set()
        app.state.judge._reaper_thread.join(timeout=1)
        assert not thread.is_alive()


def candidate(score):
    raw = io.BytesIO()
    with tarfile.open(fileobj=raw, mode="w:gz") as archive:
        member = tarfile.TarInfo("candidate.json")
        body = json.dumps({"score": score}).encode()
        member.size = len(body)
        archive.addfile(member, io.BytesIO(body))
    return raw.getvalue()


@pytest.mark.parametrize("lose_restore_response", [False, True])
def test_real_native_checkpoint_continues_without_regrading_or_refill(
    tmp_path, monkeypatch, lose_restore_response
):
    import docker
    import requests
    from sforge.harness import checkpoint
    from sforge.harness import judge_server as native
    from sforge.harness.config import SForgeConfig
    from test_judge_checkpoint import task_files

    name = "checkpoint-native-" + uuid.uuid4().hex[:10]
    docker_client = docker.from_env()
    base = docker_client.images.get("python:3.12-slim")
    task_files(tmp_path / "tasks")
    (tmp_path / "tasks/BENCHMARK.yaml").write_text(
        f"name: {name}\nbase_images: {{python: {{}}}}\n"
    )
    image_tag = f"{name}.judge.fixture:fixture"
    base.tag(f"{name}.judge.fixture", tag="fixture")
    grades = []
    release = threading.Event()
    actual = native.judge_submission

    def held_actual(**kwargs):
        grades.append(kwargs["archive"])
        assert release.wait(30)
        return actual(**kwargs)

    monkeypatch.setattr(native, "judge_submission", held_actual)
    config = SForgeConfig(
        tasks_dir=tmp_path / "tasks",
        log_dir=tmp_path / "source",
        judge_cpu_limit=1,
        judge_mem_limit="256m",
    )
    source = native.create_app(config, checkpoints=True)

    def post(url, route, body):
        return requests.post(url + route, json=body, timeout=20)

    def grade(url, token, archive):
        return requests.post(
            url + "/api/v1/submit",
            data={"token": token},
            files={"archive": ("candidate.tar.gz", archive)},
            timeout=20,
        )

    def result(url, sid):
        response = requests.get(url + "/api/v1/result/" + sid, timeout=10)
        response.raise_for_status()
        packet = response.json()
        return packet if packet["status"] in ("completed", "error") else None

    try:
        with server(source) as source_url:
            state = source.state.judge
            registered = post(
                source_url,
                "/api/v1/register",
                {
                    "task_id": "fixture",
                    "run_id": "source",
                    "max_agent_submissions": 2,
                    "submission_cooldown": 3600,
                    "admin_secret": state.admin_secret,
                },
            )
            registered.raise_for_status()
            token = registered.json()["token"]
            archive = candidate(7)
            first = grade(source_url, token, archive)
            first.raise_for_status()
            assert first.json()["round_id"] == "agent-1"
            pending = post(
                source_url,
                "/api/v1/checkpoint/capture",
                {"token": token, "admin_secret": state.admin_secret},
            )
            assert pending.status_code == 409
            release.set()
            graded = wait_for(lambda: result(source_url, first.json()["submission_id"]))
            assert graded["status"] == "completed" and graded["report"]["score"] == 7
            point_response = post(
                source_url,
                "/api/v1/checkpoint/capture",
                {"token": token, "admin_secret": state.admin_secret},
            )
            point_response.raise_for_status()
            point = point_response.json()
            assert point["opportunity"]["next_agent"] == 2
            assert 0 < point["opportunity"]["remaining_cooldown_seconds"] <= 3600
            before = copy.deepcopy((state.tokens, state.submissions, state.run_history))
            new_config = replace(config, log_dir=tmp_path / "destination")
            new_config.log_dir.mkdir()
            shutil.copytree(
                config.log_dir / "checkpoints", new_config.log_dir / "checkpoints"
            )
            destination = native.create_app(new_config, checkpoints=True)
            if lose_restore_response:
                from starlette.responses import Response

                @destination.middleware("http")
                async def lose_committed_reply(request, call_next):
                    response = await call_next(request)
                    if (
                        request.url.path == "/api/v1/checkpoint/restore"
                        and response.status_code == 200
                    ):
                        # Fault only the outbound HTTP result; real registration
                        # publication, files, locking and subsequent grading run.
                        return Response(status_code=502)
                    return response

            with server(destination) as url:
                fresh_state = destination.state.judge
                assert fresh_state.admin_secret != state.admin_secret
                # Inject elapsed staging time into only the native admission
                # clock. HTTP, file synchronization and grading remain real.
                admission_now = [time.time()]
                admission_clock = SimpleNamespace(time=lambda: admission_now[0])
                original_sync = checkpoint._sync_directory

                def elapsed_staging(path):
                    original_sync(path)
                    admission_now[0] += 7200

                monkeypatch.setattr(native, "time", admission_clock)
                monkeypatch.setattr(checkpoint, "time", admission_clock)
                with monkeypatch.context() as patch:
                    patch.setattr(checkpoint, "_sync_directory", elapsed_staging)
                    restored = post(
                        url,
                        "/api/v1/checkpoint/restore",
                        {
                            "checkpoint_id": point["checkpoint_id"],
                            "manifest_sha256": point["manifest_sha256"],
                            "run_id": "branch",
                            "admin_secret": fresh_state.admin_secret,
                        },
                    )
                assert restored.status_code == (502 if lose_restore_response else 200)
                published = copy.deepcopy(
                    (
                        fresh_state.tokens,
                        fresh_state.submissions,
                        fresh_state.run_history,
                    )
                )
                recovered = post(
                    url,
                    "/api/v1/checkpoint/restore-result",
                    {
                        "checkpoint_id": point["checkpoint_id"],
                        "manifest_sha256": point["manifest_sha256"],
                        "run_id": "branch",
                        "admin_secret": fresh_state.admin_secret,
                    },
                )
                recovered.raise_for_status()
                fresh = recovered.json()["token"]
                assert (
                    fresh_state.tokens,
                    fresh_state.submissions,
                    fresh_state.run_history,
                ) == published
                assert fresh in published[0]
                if not lose_restore_response:
                    assert recovered.json() == restored.json()
                assert fresh != token and len(grades) == 1
                history = requests.get(
                    url + "/api/v1/history", params={"token": fresh}, timeout=10
                ).json()
                assert (
                    history["best_round"],
                    history["best_score"],
                    history["agent_submissions"],
                ) == ("agent-1", 7, 1)
                sid = history["entries"][0]["submission_id"]
                assert sid != first.json()["submission_id"]
                assert result(url, sid)["report"] == graded["report"]
                selected = (
                    new_config.log_dir
                    / "runs/branch/fixture/submissions/agent-1/submission.tar.gz"
                )
                assert selected.read_bytes() == archive
                assert (
                    grade(url, fresh, candidate(3)).status_code == 429
                    and len(grades) == 1
                )
                # Advance only the native admission clock. Evaluation/container
                # execution retains the real wall clock and real Docker backend.
                admission_now[0] += 3601
                second = grade(url, fresh, candidate(3))
                second.raise_for_status()
                assert (
                    second.json()["round_id"] == "agent-2"
                    and second.json()["remaining_submissions"] == 0
                )
                second_result = wait_for(
                    lambda: result(url, second.json()["submission_id"])
                )
                assert (
                    second_result["status"] == "completed"
                    and second_result["report"]["score"] == 3
                )
                assert (
                    grade(url, fresh, candidate(11)).status_code == 429
                    and len(grades) == 2
                )
                final = requests.get(
                    url + "/api/v1/history", params={"token": fresh}, timeout=10
                ).json()
                assert (
                    final["best_round"],
                    final["best_score"],
                    final["agent_submissions"],
                ) == ("agent-1", 7, 2)
                assert (
                    post(
                        url,
                        "/api/v1/checkpoint/restore",
                        {
                            "checkpoint_id": point["checkpoint_id"],
                            "manifest_sha256": point["manifest_sha256"],
                            "run_id": "branch",
                            "admin_secret": fresh_state.admin_secret,
                        },
                    ).status_code
                    == 409
                )
            assert (state.tokens, state.submissions, state.run_history) == before
    finally:
        release.set()
        leftovers = docker_client.containers.list(all=True, filters={"name": name})
        for container in leftovers:
            container.remove(force=True)
        docker_client.images.remove(image_tag)
        docker_client.close()
        assert not leftovers, "Native grade failed to clean up its own containers"
