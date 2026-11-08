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

"""Synthetic children exercise the actual image wrapper, without benchmark data."""
from __future__ import annotations

import contextlib
import importlib.util
import io
import json
import subprocess
import sys
import tempfile
from pathlib import Path

from failure_policy import repair


def validate(manifest_path: Path, wrapper_path: Path) -> None:
    original = manifest_path.read_bytes()
    wrapper = wrapper_path.read_bytes()
    repaired = repair(original, wrapper)
    baseline, candidate = json.loads(original), json.loads(repaired)
    expected = dict(baseline, failure_policy=dict(baseline["failure_policy"],
                    parse_failure="infra_error", nonzero_exit_without_score="infra_error"))
    assert candidate == expected  # All other semantics must survive.
    for manifest, source in ((original + b" ", wrapper), (original, wrapper + b"\n"),
                             (repaired, wrapper)):
        try:
            repair(manifest, source)
        except ValueError:
            pass
        else:
            raise AssertionError("Unsupported or already repaired input accepted")

    spec = importlib.util.spec_from_file_location("image_wrapper", wrapper_path)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    # Rule-derived expected outcomes, independent of the wrapper's classification.
    cases = (
        ("child crash", "import sys; sys.exit(7)", False, 0.0),
        ("unparseable success", "print('unparseable')", False, 0.0),
        ("empty success", "pass", False, 0.0),
        ("explicit strategy failure", "print('Evaluation terminated: strategy run failed, total score 0')", True, 0.0),
        ("explicit timeout", "print('Run timed out, total score 0')", True, 0.0),
        ("explicit numeric zero", "print('Final total score: 0')", True, 0.0),
        ("normal score", "print('Final total score: 12.5')", True, 12.5),
    )
    for policy_name, policy in (("original", baseline), ("repaired", candidate)):
        for name, child, valid_after, score in cases:
            with tempfile.TemporaryDirectory() as temp:
                root = Path(temp)
                synthetic = dict(policy, required_submission_files=[], required_input_files=[],
                                 required_scoring_files=[], command=[sys.executable, "-c", child])
                module.SCORING_DIR = root
                module.WORKSPACE = root
                module.MANIFEST = root / "scorer_manifest.json"
                module.MANIFEST.write_text(json.dumps(synthetic))
                output = io.StringIO()
                with contextlib.redirect_stdout(output):
                    assert module.main() == 0
                lines = output.getvalue().splitlines()
                result = json.loads(lines[lines.index(">>>>> Start Structured Result") + 1])
                status = json.loads(next(line.removeprefix("SCORER_STATUS_JSON ")
                                        for line in lines if line.startswith("SCORER_STATUS_JSON ")))
                valid = True if policy_name == "original" else valid_after
                assert result["valid"] is valid, (policy_name, name, result)
                assert result["score"] == score, (policy_name, name, result)
                assert status["status"] == ("ok" if valid else "infra_error")
                assert result["details"][0]["status"] == ("PASSED" if valid else "FAILED")
    with tempfile.TemporaryDirectory() as temp:
        destination = Path(temp) / "result.json"
        args = [sys.executable, str(Path(__file__).with_name("failure_policy.py")),
                str(manifest_path), str(wrapper_path), str(destination)]
        subprocess.run(args, check=True, capture_output=True)
        assert destination.read_bytes() == repaired
        assert subprocess.run(args, capture_output=True).returncode != 0
        assert destination.read_bytes() == repaired
    print("14 wrapper cases, revision guards, exact policy delta and CLI overwrite protection passed")


if __name__ == "__main__":
    validate(Path(sys.argv[1]), Path(sys.argv[2]))
