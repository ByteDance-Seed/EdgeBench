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

"""Opt-in build-time repair of the published Portfolio wrapper failure policy."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

WRAPPER_SHA256 = "4ba07668bf5051c871069b2a4c69783e0df6108584abd29d133a37ca17d84b1d"
MANIFEST_SHA256 = "b88f9924ecaca621f66bc2580504da9301551cb7dc7b8cada64ad49170a6f2e7"


def repair(manifest: bytes, wrapper: bytes) -> bytes:
    """Keep explicit strategy zeros; an absent score is not an observed zero."""
    for source, expected in ((manifest, MANIFEST_SHA256), (wrapper, WRAPPER_SHA256)):
        if hashlib.sha256(source).hexdigest() != expected:
            raise ValueError("Unsupported scorer revision; inspect before porting this repair")
    updated = json.loads(manifest)
    policy = updated["failure_policy"]
    for key in ("parse_failure", "nonzero_exit_without_score"):
        policy[key] = "infra_error"
    return (json.dumps(updated, indent=2, ensure_ascii=False) + "\n").encode()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("manifest", type=Path)
    parser.add_argument("wrapper", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    if args.output.resolve() in (args.manifest.resolve(), args.wrapper.resolve()):
        parser.error("Use a separate output path; retain original inputs")
    result = repair(args.manifest.read_bytes(), args.wrapper.read_bytes())
    # Exclusive creation also rejects repeat application and concurrent writers.
    with args.output.open("xb") as output:
        output.write(result)


if __name__ == "__main__":
    main()
