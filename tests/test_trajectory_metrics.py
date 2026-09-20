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

import json
import threading
from types import SimpleNamespace

from fastapi.testclient import TestClient

from sforge.harness import judge_server
from sforge.harness.trajectory_metrics import compute_trajectory_metrics


def submission(
    *,
    pass_rate=0.0,
    score=None,
    submitted_at=None,
    status="completed",
    valid=True,
):
    return {
        "type": "submission",
        "status": status,
        "valid": valid,
        "pass_rate": pass_rate,
        "score": score,
        "submitted_at": submitted_at,
    }


def test_pass_rate_trajectory_reports_improvement_and_timing():
    metrics = compute_trajectory_metrics(
        [
            submission(pass_rate=0.2, submitted_at=100),
            submission(pass_rate=0.2, submitted_at=130),
            submission(pass_rate=0.5, submitted_at=160),
            submission(pass_rate=0.4, submitted_at=190),
            submission(pass_rate=0.7, submitted_at=220),
        ]
    )

    assert metrics == {
        "value_field": "pass_rate",
        "direction": "maximize",
        "submission_count": 5,
        "initial_value": 0.2,
        "final_value": 0.7,
        "best_value": 0.7,
        "total_improvement": 0.5,
        "improving_submissions": 2,
        "non_improving_submissions": 2,
        "first_improvement_seconds": 60.0,
        "time_to_best_seconds": 120.0,
    }


def test_score_trajectory_respects_minimize_direction():
    metrics = compute_trajectory_metrics(
        [
            submission(score=10, submitted_at=20),
            submission(score=8, submitted_at=30),
            submission(score=9, submitted_at=40),
            submission(score=6, submitted_at=50),
        ],
        score_direction="minimize",
    )

    assert metrics["value_field"] == "score"
    assert metrics["direction"] == "minimize"
    assert metrics["initial_value"] == 10
    assert metrics["final_value"] == 6
    assert metrics["best_value"] == 6
    assert metrics["total_improvement"] == 4
    assert metrics["improving_submissions"] == 2
    assert metrics["non_improving_submissions"] == 1
    assert metrics["first_improvement_seconds"] == 10
    assert metrics["time_to_best_seconds"] == 30


def test_invalid_and_failed_submissions_are_excluded():
    metrics = compute_trajectory_metrics(
        [
            submission(pass_rate=0.1, submitted_at=10),
            submission(pass_rate=1.0, submitted_at=20, valid=False),
            submission(pass_rate=1.0, submitted_at=30, status="error"),
        ]
    )

    assert metrics["submission_count"] == 1
    assert metrics["best_value"] == 0.1
    assert metrics["total_improvement"] == 0.0
    assert metrics["improving_submissions"] == 0
    assert metrics["non_improving_submissions"] == 0
    assert metrics["first_improvement_seconds"] is None
    assert metrics["time_to_best_seconds"] == 0


def test_empty_trajectory_returns_stable_shape():
    metrics = compute_trajectory_metrics([])

    assert metrics["submission_count"] == 0
    assert metrics["initial_value"] is None
    assert metrics["best_value"] is None
    assert metrics["first_improvement_seconds"] is None


def test_trajectory_is_ordered_by_submission_time():
    metrics = compute_trajectory_metrics(
        [
            submission(pass_rate=0.8, submitted_at=20),
            submission(pass_rate=0.2, submitted_at=10),
            submission(pass_rate=0.5, submitted_at=15),
        ]
    )

    assert metrics["initial_value"] == 0.2
    assert metrics["final_value"] == 0.8
    assert metrics["best_value"] == 0.8
    assert metrics["improving_submissions"] == 2
    assert metrics["first_improvement_seconds"] == 5
    assert metrics["time_to_best_seconds"] == 10


def test_non_finite_and_missing_rewards_are_excluded():
    metrics = compute_trajectory_metrics(
        [
            submission(score=1, submitted_at=10),
            submission(score=float("nan"), submitted_at=20),
            submission(score=float("inf"), submitted_at=30),
            submission(score=None, submitted_at=40),
            submission(score=1, submitted_at=50),
        ]
    )

    assert metrics["value_field"] == "score"
    assert metrics["submission_count"] == 2
    assert metrics["improving_submissions"] == 0
    assert metrics["non_improving_submissions"] == 1
    json.dumps(metrics, allow_nan=False)


def test_overflowed_differences_remain_json_serializable():
    metrics = compute_trajectory_metrics(
        [
            submission(pass_rate=-1e308, submitted_at=-1e308),
            submission(pass_rate=1e308, submitted_at=1e308),
        ]
    )

    assert metrics["total_improvement"] is None
    assert metrics["first_improvement_seconds"] is None
    assert metrics["time_to_best_seconds"] is None
    json.dumps(metrics, allow_nan=False)


def test_agent_history_includes_metrics_for_visible_entries(monkeypatch):
    def fake_init(self, config):
        self.tasks = {
            "task": SimpleNamespace(
                judge=SimpleNamespace(
                    selection="pass_rate_first",
                    score_direction="maximize",
                )
            )
        }
        self.tokens = {"token": {"run_id": "run", "task_id": "task"}}
        self.run_history = {
            "run/task": [
                submission(pass_rate=0.2, submitted_at=10)
                | {"round": "agent-1", "task_id": "task"},
                submission(pass_rate=0.9, submitted_at=20)
                | {"round": "auto-1", "task_id": "task"},
                submission(pass_rate=0.5, submitted_at=30)
                | {"round": "agent-2", "task_id": "task"},
            ]
        }
        self._history_lock = threading.Lock()
        self._tokens_lock = threading.Lock()

    monkeypatch.setattr(judge_server.JudgeState, "__init__", fake_init)
    monkeypatch.setattr(judge_server.JudgeState, "load_tasks", lambda self: None)

    response = TestClient(judge_server.create_app(object())).get(
        "/api/v1/history",
        params={"token": "token"},
    )

    assert response.status_code == 200
    body = response.json()
    assert body["trajectory_metrics"]["submission_count"] == 2
    assert body["trajectory_metrics"]["best_value"] == 0.5
    assert body["auto_submissions"] == 0
