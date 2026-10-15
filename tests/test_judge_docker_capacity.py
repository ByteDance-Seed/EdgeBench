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

"""Opt-in ownership tests with real containers and a real JudgeState worker."""
from __future__ import annotations

import multiprocessing as mp
import os
import time
import types
import uuid
from pathlib import Path

import docker
import pytest

from sforge.harness import judge_server as js
from sforge.harness.backend.docker_backend import DockerBackend
from sforge.harness.config import SForgeConfig


def _launch_judge(image, label, root, ready, orphan):
    js.create_backend_from_config = lambda _cfg: None
    client = docker.from_env()

    def judge(**kwargs):
        owned = client.containers.run(
            image, ["sleep", "60" if orphan else "0.2"], detach=True,
            network_disabled=True, labels={"sforge-capacity-test": label},
            name=f"synthetic.judge.synthetic.{kwargs['submission_id']}",
        )
        token = f"{os.getpid()}:{kwargs['submission_id']}"
        ready.put({"container_id": owned.id, "slot_token": token})
        try:
            assert owned.wait(timeout=65)["StatusCode"] == 0
            return types.SimpleNamespace(to_dict=lambda: {
                "valid": True, "pass_rate": 1.0, "score": 1.0})
        finally:
            owned.remove(force=True)

    js.judge_submission = judge
    state = js.JudgeState(SForgeConfig(log_dir=Path(root), judge_max_concurrency=1,
                                      judge_host_capacity=1))
    state.host_capacity = js.HostJudgeCapacity(1, str(Path(root) / "slots.json"))
    state.tasks = {"synthetic": types.SimpleNamespace(task_id="synthetic")}
    sid = state.submit("synthetic", b"synthetic", "run", "auto-1")
    deadline = time.monotonic() + 70
    while state._judge_queue.unfinished_tasks and time.monotonic() < deadline:
        time.sleep(0.01)
    assert not state._judge_queue.unfinished_tasks
    assert state.get_result(sid)["status"] == "completed"
    state._reaper_stop.set()
    client.close()


@pytest.mark.parametrize("orphan", [False, True], ids=["normal_cleanup", "launcher_crash"])
def test_slot_release_requires_judge_cleanup(tmp_path, orphan):
    image = os.environ.get("SFORGE_DOCKER_TEST_IMAGE")
    if not image:
        pytest.skip("set SFORGE_DOCKER_TEST_IMAGE to a cached image")
    client = docker.from_env()
    client.images.get(image)  # Never pull or build.
    label = uuid.uuid4().hex
    ctx = mp.get_context("spawn")
    ready = ctx.Queue()
    process = ctx.Process(target=_launch_judge,
                          args=(image, label, str(tmp_path), ready, orphan))
    owned_id = None
    process.start()
    try:
        receipt = ready.get(timeout=15)
        owned_id = receipt["container_id"]
        slots = js.HostJudgeCapacity(1, str(tmp_path / "slots.json"))
        if orphan:
            process.terminate()
            process.join(5)
            assert process.exitcode is not None
            owned = client.containers.get(owned_id)
            assert owned.labels.get("sforge-capacity-test") == label
            assert owned.status == "running"
            assert not slots.try_acquire("replacement")
            backend = DockerBackend(client)
            assert slots.reconcile_stale_holders(
                backend.reconcile_judge_capacity_holder
            ) == [receipt["slot_token"]]
            assert not client.containers.list(all=True, filters={"id": owned_id})
        else:
            process.join(15)
            assert process.exitcode == 0
            assert not client.containers.list(all=True, filters={"id": owned_id})
        assert slots.try_acquire("replacement")
        slots.release("replacement")
    finally:
        if process.is_alive():
            process.terminate()
        process.join(5)
        # Only containers created by this test's unique ownership label.
        for owned in client.containers.list(all=True, filters={"label": f"sforge-capacity-test={label}"}):
            owned.remove(force=True)
        assert not client.containers.list(all=True, filters={"label": f"sforge-capacity-test={label}"})
        client.close()
