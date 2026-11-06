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

from sforge.harness.config import resource_env
from sforge.harness.task_spec import load_task


def test_resource_env_reports_only_known_limits():
    assert resource_env(4, "8g") == {"SFORGE_CPUS": "4", "SFORGE_MEMORY": "8g"}
    assert resource_env(None, None) == {}


def test_task_toml_limits(tmp_path):
    d = tmp_path / "tasks" / "t1"
    d.mkdir(parents=True)
    (d / "instruction.md").write_text("x")
    (d / "task.toml").write_text(
        'id = "t1"\n[environment]\ncwd = "/w"\ncpus = 4\nmemory = "16g"\n'
        '[judge]\ncmd = "true"\ncpus = 2\nmemory = "8g"\n'
    )
    (tmp_path / "benchmark.toml").write_text('name = "bench"\n')
    spec = load_task(d)
    assert (spec.work.cpu_limit, spec.work.mem_limit) == (4, "16g")
    assert (spec.judge.cpu_limit, spec.judge.mem_limit) == (2, "8g")
