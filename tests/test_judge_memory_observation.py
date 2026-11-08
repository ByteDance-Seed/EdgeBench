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

import json
import logging
from types import SimpleNamespace

import pytest

from sforge.harness.backend import docker_backend
from sforge.harness.backend.docker_backend import DockerBackend, DockerContainerHandle
from sforge.harness.run_evaluation import _record_judge_resources


CONTAINER_ID = "a" * 64
IMAGE_ID = "sha256:" + "b" * 64


@pytest.mark.parametrize(("relative_path", "memory_max", "limit"), [
    (f"docker/{CONTAINER_ID}", "1048576", 1048576),
    (f"system.slice/docker-{CONTAINER_ID}.scope", "max", None),
])
def test_judge_resource_file_uses_exact_cgroup_and_native_identity(
    tmp_path, monkeypatch, relative_path, memory_max, limit,
):
    monkeypatch.setattr(docker_backend, "_CGROUP_ROOT", tmp_path / "cgroups")
    cgroup = tmp_path / "cgroups" / relative_path
    cgroup.mkdir(parents=True)
    (cgroup / "memory.peak").write_text("65536\n")
    (cgroup / "memory.max").write_text(memory_max + "\n")
    log_dir = tmp_path / "submission"
    log_dir.mkdir()
    backend = DockerBackend(client=object())
    logger = logging.getLogger(__name__)

    foreign = DockerContainerHandle(SimpleNamespace(id="c" * 64, attrs={"Image": IMAGE_ID}))
    _record_judge_resources(backend, foreign, log_dir, "case", "foreign", logger)
    assert not list(log_dir.iterdir())

    handle = DockerContainerHandle(SimpleNamespace(id=CONTAINER_ID, attrs={"Image": IMAGE_ID}))
    _record_judge_resources(backend, handle, log_dir, "case", "submission", logger)
    [record] = log_dir.iterdir()
    assert record.name == "judge_resources.json"
    assert json.loads(record.read_text()) == {
        "task_id": "case",
        "submission_id": "submission",
        "container_id": CONTAINER_ID,
        "image_id": IMAGE_ID,
        "memory_peak_bytes": 65536,
        "memory_limit_bytes": limit,
        "source": "local_docker_cgroup_v2",
    }


def test_judge_resource_write_failure_leaves_no_partial_file(tmp_path, monkeypatch, caplog):
    backend = DockerBackend(client=object())
    monkeypatch.setattr(backend, "local_memory_observation", lambda _: {"memory_peak_bytes": 65536})
    (tmp_path / "judge_resources.json").mkdir()
    _record_judge_resources(backend, object(), tmp_path, "case", "submission", logging.getLogger(__name__))
    assert list(tmp_path.iterdir()) == [tmp_path / "judge_resources.json"]
    assert "Judge resource observation unavailable" in caplog.text
