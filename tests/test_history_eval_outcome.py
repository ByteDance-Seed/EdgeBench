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

"""Exercise grading outcome projection through the real judge HTTP endpoints."""

from __future__ import annotations

import json

import pytest
import requests

from sforge.harness.grading import EvalReport
from sforge.harness.selection import select_best
from test_judge_tcp_acceptance import (
    history,
    live_judge,  # noqa: F401 -- pytest fixture
    payload,
    register,
    submit,
    wait_until,
)


def result_report(runtime, submission_id):
    response = requests.get(
        runtime.url + "/api/v1/result/" + submission_id, timeout=5,
    )
    response.raise_for_status()
    return response.json()


@pytest.mark.parametrize("timed_out,score,seconds", [
    (True, None, 2400.25),
    (False, 0.0, 0.0),
    (False, 37.5, 2.75),
    (True, 5.0, 2400.0),
])
def test_completed_history_retains_original_evaluation_outcome(
    live_judge, timed_out, score, seconds,
):
    rt = live_judge
    token = register(rt)
    original = EvalReport(
        task_id=rt.task.task_id, submission_id="synthetic-report",
        timed_out=timed_out, runtime_seconds=seconds, score=score,
        valid=True, summary="synthetic outcome", metrics={"private_detail": 17},
    ).to_dict()
    submitted = submit(rt, token, "agent", json.dumps({**original, "error": False}).encode())
    submitted.raise_for_status()
    sid = submitted.json()["submission_id"]
    rt.release.set()
    wait_until(lambda: rt.state._judge_queue.unfinished_tasks == 0)

    report = result_report(rt, sid)
    # Existing native worker behavior removes only this rescaled-score field.
    expected = {k: v for k, v in original.items() if k != "score_0_100"}
    assert report["status"] == "completed" and report["report"] == expected
    host = history(rt, token)
    agent = history(rt, token, admin=False)
    assert host == agent
    entry = host["entries"][0]
    assert entry["timed_out"] is timed_out
    assert entry["runtime_seconds"] == seconds
    for key in ("score", "valid", "pass_rate", "passed", "failed", "total_tests", "summary"):
        assert entry[key] == expected[key]
    assert "metrics" not in entry and "test_details" not in entry
    without_outcome = {k: v for k, v in entry.items() if k not in ("timed_out", "runtime_seconds")}
    assert select_best([entry], policy="score_first") == select_best([without_outcome], policy="score_first")
    assert host["best_score"] == score


@pytest.mark.parametrize("fields", [
    {}, {"timed_out": False}, {"runtime_seconds": 0.0},
    {"timed_out": None, "runtime_seconds": None},
])
def test_legacy_report_omissions_are_not_filled_in(live_judge, fields):
    rt = live_judge
    token = register(rt)
    body = {"score": 0, "valid": False, "pass_rate": 0, **fields, "error": False}
    submitted = submit(rt, token, "agent", json.dumps(body).encode())
    submitted.raise_for_status()
    rt.release.set()
    wait_until(lambda: rt.state._judge_queue.unfinished_tasks == 0)
    entry = history(rt, token)["entries"][0]
    for key in ("timed_out", "runtime_seconds"):
        assert (key in entry) == (key in fields)
        if key in fields:
            assert entry[key] == fields[key]
    assert entry["score"] == 0 and entry["valid"] is False
    report = result_report(rt, submitted.json()["submission_id"])["report"]
    assert report == {k: v for k, v in body.items() if k != "error"}


def test_pending_and_error_history_have_no_terminal_outcome(live_judge):
    rt = live_judge
    token = register(rt)
    first = submit(rt, token, "agent", payload(error=True))
    first.raise_for_status()
    wait_until(lambda: len(rt.probe.started) == 1)
    second = submit(rt, token, "auto")
    second.raise_for_status()
    pending = history(rt, token)
    assert sorted(e["status"] for e in pending["entries"]) == ["queued", "running"]
    for entry in pending["entries"]:
        assert all(key not in entry for key in ("score", "timed_out", "runtime_seconds"))
        report = result_report(rt, entry["submission_id"])
        assert report["report"] is None and report["status"] == entry["status"]
    assert len(history(rt, token, admin=False)["entries"]) == 1
    rt.release.set()
    wait_until(lambda: rt.state._judge_queue.unfinished_tasks == 0)
    failed = result_report(rt, first.json()["submission_id"])
    assert failed["status"] == "error" and failed["report"] is None
    agent = history(rt, token, admin=False)
    assert agent["best_score"] is None
    assert agent["entries"][0]["status"] == "error"
    assert all(key not in agent["entries"][0] for key in ("score", "timed_out", "runtime_seconds"))
    assert history(rt, token)["best_score"] == 80
