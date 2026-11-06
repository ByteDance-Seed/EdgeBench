#!/usr/bin/env python3
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

"""Build and push the pre-built task images (run by .github/workflows/images.yml).

Usage:
  ci_images.py plan               # bases=[...] and tasks=[...] whose images the registry lacks
  ci_images.py base <name>        # build bases/<name> and push it
  ci_images.py task <id> [--push] # pull the task's base, build work + judge, optionally push

Image tags are content hashes, so a tag the registry has is up to date and only
new or changed images are built. Benchmark: SFORGE_BENCHMARK; registry: SFORGE_REGISTRY,
else the benchmark's.
"""

from __future__ import annotations

import json
import subprocess
import sys

from sforge.harness.config import load_config
from sforge.harness.docker_build import (
    build_all_images,
    build_base_image,
    image_exists,
    push_all_images,
    registry_has,
    remote_ref,
)
from sforge.harness.task_spec import load_all_tasks


def docker(*args: str) -> None:
    subprocess.run(["docker", *args], check=True)


def main() -> int:
    config = load_config()
    reg = config.image_registry
    specs = {s.task_id: s for s in load_all_tasks(config.benchmark)}
    cmd, *rest = sys.argv[1:]
    if cmd == "plan":
        bases = {s.base: s for s in specs.values() if s.base}
        missing_bases = [b for b, s in sorted(bases.items())
                         if not registry_has(remote_ref(reg, s.base_image_key))]
        missing_tasks = [t for t, s in sorted(specs.items())
                         if not all(registry_has(remote_ref(reg, k)) for k in (s.work_image_key, s.judge_image_key))]
        print(f"bases={json.dumps(missing_bases)}")
        print(f"tasks={json.dumps(missing_tasks)}")
    elif cmd == "base":
        spec = next(s for s in specs.values() if s.base == rest[0])
        build_base_image(spec, config, verbose=True)
        ref = remote_ref(reg, spec.base_image_key)
        docker("tag", spec.base_image_key, ref)
        docker("push", ref)
    elif cmd == "task":
        spec = specs[rest[0]]
        # Reuse the base the bases job pushed instead of rebuilding it here.
        if spec.base and not image_exists(spec.base_image_key):
            ref = remote_ref(reg, spec.base_image_key)
            if registry_has(ref):
                docker("pull", ref)
                docker("tag", ref, spec.base_image_key)
        build_all_images(spec, config, verbose=True)
        if "--push" in rest:
            failed = [k for k, ok in push_all_images(spec, reg).items() if not ok]
            if failed:
                print(f"push failed: {failed}", file=sys.stderr)
                return 1
    else:
        print(__doc__, file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
