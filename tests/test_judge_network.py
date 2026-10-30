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

from sforge.harness.backend.docker_backend import DockerBackend
from sforge.harness.task_spec import load_task


class _FakeContainers:
    def __init__(self):
        self.kwargs = None

    def create(self, image, **kwargs):
        self.kwargs = kwargs
        return object()


class _FakeClient:
    def __init__(self):
        self.containers = _FakeContainers()


def _task(tmp_path, judge_extra=""):
    d = tmp_path / "tasks" / "t1"
    d.mkdir(parents=True)
    (d / "instruction.md").write_text("x")
    (d / "task.toml").write_text(
        f'id = "t1"\n[environment]\ncwd = "/w"\n[judge]\ncmd = "true"\n{judge_extra}'
    )
    (tmp_path / "benchmark.toml").write_text('name = "bench"\n')
    return load_task(d)


def test_judge_is_offline_unless_the_task_asks(tmp_path):
    assert _task(tmp_path).judge.internet is False
    assert _task(tmp_path / "x", "internet = true\n").judge.internet is True


def test_docker_offline_container_has_no_network(tmp_path):
    client = _FakeClient()
    backend = DockerBackend(client=client)
    backend.create_container("img", "n", network=False, extra_hosts={"h": "host-gateway"})
    assert client.containers.kwargs["network_mode"] == "none"
    assert "extra_hosts" not in client.containers.kwargs
    backend.create_container("img", "n", extra_hosts={"h": "host-gateway"})
    assert "network_mode" not in client.containers.kwargs
