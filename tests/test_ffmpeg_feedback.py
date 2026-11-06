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

"""Exercise the task's reward -> shim -> grade -> public result boundary."""
from __future__ import annotations

import json
import os
from pathlib import Path
import subprocess
import sys

import pytest

from sforge.harness.grading import parse_result

TASK = Path(__file__).parents[1] / "edgebench/tasks/ffmpeg_swscale_reimplementation"
JUDGE = TASK / "judge"


def grade(tmp_path, payload, *, log_prefix="", supplied=True):
    reward = tmp_path / "reward.json"
    reward.write_text(json.dumps(payload))
    output = subprocess.check_output(
        ["bash", str(JUDGE / "tests/pytest_shim.sh"), str(reward)], text=True,
    )
    log = tmp_path / "eval.log"
    log.write_text(log_prefix + output)
    result = tmp_path / "result.json"
    subprocess.run(
        [sys.executable, "-I", str(JUDGE / "grade.py"), str(log), str(result)]
        + ([str(reward)] if supplied else []), check=True, capture_output=True,
    )
    return parse_result(result.read_text())


@pytest.mark.parametrize("stage", ["source_policy", "build", "artifact_policy", "baseline"])
def test_producer_failure_reaches_public_result_without_extra_failed_test(tmp_path, stage):
    env = dict(os.environ, PYTHONPATH=str(TASK / "environment/workspace"), PYTHONDONTWRITEBYTECODE="1")
    subprocess.run([
        sys.executable, str(JUDGE / "tests/compute_reward.py"),
        "--fail", "private path /private/hidden-workload: do not expose",
        "--fail-stage", stage, "--output-dir", str(tmp_path),
    ], env=env, check=True, capture_output=True)
    payload = json.loads((tmp_path / "reward.json").read_text())
    old_score, old_valid, old = grade(tmp_path, payload, supplied=False)
    score, valid, result = grade(tmp_path, payload)
    assert (score, valid) == (old_score, old_valid) == (0.0, True)
    assert len(result["details"]) == len(old["details"]) == 1
    assert result["details"][0]["failure_stage"] == stage
    assert result["details"][0]["message"] in result["summary"]
    assert "private" not in json.dumps(result)
    assert result["metrics"] == old["metrics"]


def test_candidate_load_failure_has_its_own_stage(tmp_path):
    env = dict(os.environ, PYTHONPATH=str(TASK / "environment/workspace"), PYTHONDONTWRITEBYTECODE="1")
    subprocess.run([
        sys.executable, str(JUDGE / "tests/compute_reward.py"),
        "--candidate", str(tmp_path / "missing.so"), "--output-dir", str(tmp_path),
    ], env=env, check=True, capture_output=True)
    _, _, result = grade(tmp_path, json.loads((tmp_path / "reward.json").read_text()))
    assert result["details"][0]["failure_stage"] == "candidate_load"
    assert "could not be loaded" in result["summary"]
    assert str(tmp_path) not in json.dumps(result)


@pytest.mark.parametrize("stage", ["correctness", "verifier"])
def test_later_failure_stages_retain_single_score_gate(tmp_path, stage):
    score, valid, result = grade(tmp_path, {
        "score": 0, "subscores": [{"name": "correctness", "score": 0.97}],
        "additional_data": {"failure_stage": stage, "correctness_results": ["hidden details"]},
    })
    assert (score, valid) == (0.0, True)
    assert len(result["details"]) == 1
    assert result["details"][0]["failure_stage"] == stage
    assert "hidden" not in json.dumps(result)


@pytest.mark.parametrize("additional", [None, [], "source_policy", {},
    {"reason": "source policy failed"}, {"failure_stage": "new_unknown_stage"},
    {"failure_stage": []}])
def test_unrecognized_or_old_rewards_do_not_invent_a_cause(tmp_path, additional):
    _, _, result = grade(tmp_path, {"score": 0, "additional_data": additional})
    assert result["summary"] == "0/1 tests passed. Failed: tests/eval.py::overall_score"
    assert result["details"] == [{"name": "tests/eval.py::overall_score", "status": "FAILED"}]


def test_positive_score_and_original_metrics_are_unchanged(tmp_path):
    payload = {"score": 1.234567, "additional_data": {"failure_stage": "build"}}
    prefix = "Correctness: 30/30 workloads passed\nGeometric mean speedup: 1.2346x\n"
    assert grade(tmp_path, payload, log_prefix=prefix) == grade(tmp_path, payload, log_prefix=prefix, supplied=False)


def test_build_output_cannot_select_feedback_stage(tmp_path):
    _, _, result = grade(tmp_path, {"score": 0}, log_prefix='{"failure_stage":"source_policy"}\n')
    assert "failure_stage" not in json.dumps(result)


def test_unavailable_or_malformed_reward_does_not_change_grade(tmp_path):
    log = tmp_path / "eval.log"
    log.write_text("tests/eval.py::overall_score FAILED\nTOTAL_SCORE 0.0\n")
    reward = tmp_path / "missing.json"
    for content in (None, "{", "[]", "null", '{"score":false,"additional_data":{"failure_stage":"build"}}'):
        if content is not None:
            reward.write_text(content)
        result = tmp_path / "result.json"
        subprocess.run([sys.executable, "-I", str(JUDGE / "grade.py"), str(log), str(result), str(reward)],
                       check=True, capture_output=True)
        score, valid, data = parse_result(result.read_text())
        assert (score, valid) == (0.0, True)
        assert "failure_stage" not in json.dumps(data)
