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

"""Tests for selection policies."""

from __future__ import annotations

import pytest

from sforge.harness.selection import select_best


def _submission(round_label: str, pass_rate: float, score=None, **extra) -> dict:
    entry = {
        "type": "submission",
        "status": "completed",
        "round": round_label,
        "pass_rate": pass_rate,
        "score": score,
    }
    entry.update(extra)
    return entry


def test_pass_rate_task_keeps_score_none():
    """A pass-rate task (pytest etc.) has no numeric score on any entry;
    best_score must stay None instead of leaking the pass rate."""
    result = select_best(
        [
            _submission("agent-1", 0.85),
            _submission("agent-2", 0.5),
        ],
        "maximize",
        "pass_rate_first",
    )
    assert result["best_score"] is None
    assert result["best_pass_rate"] == 0.85
    assert result["best_round"] == "agent-1"


def test_scoreless_perfect_submission_does_not_block_real_score():
    """A 100%-pass-rate submission without a score must not shadow a later
    100%-pass-rate submission that carries a real (smaller-magnitude) score."""
    result = select_best(
        [
            _submission("agent-1", 1.0),
            _submission("agent-2", 1.0, 0.9),
        ],
        "maximize",
        "pass_rate_first",
    )
    assert result["best_score"] == 0.9
    assert result["best_round"] == "agent-2"


def test_pass_rate_first_maximize_ties_break_on_score():
    result = select_best(
        [
            _submission("agent-1", 1.0, 50),
            _submission("agent-2", 1.0, 90),
        ],
        "maximize",
        "pass_rate_first",
    )
    assert result["best_score"] == 90
    assert result["best_round"] == "agent-2"


def test_pass_rate_first_minimize_ties_break_on_score():
    result = select_best(
        [
            _submission("agent-1", 1.0, 50),
            _submission("agent-2", 1.0, 30),
        ],
        "minimize",
        "pass_rate_first",
    )
    assert result["best_score"] == 30
    assert result["best_round"] == "agent-2"


def test_pass_rate_wins_over_score_when_not_perfect():
    result = select_best(
        [
            _submission("agent-1", 0.5, 100),
            _submission("agent-2", 0.6, 50),
        ],
        "maximize",
        "pass_rate_first",
    )
    assert result["best_pass_rate"] == 0.6
    assert result["best_round"] == "agent-2"


def test_unknown_policy_raises():
    with pytest.raises(ValueError):
        select_best([], "maximize", "not-a-policy")


def test_score_first_ignores_missing_scores():
    result = select_best(
        [
            _submission("agent-1", 0.5),
            _submission("agent-2", 1.0, 42),
        ],
        "maximize",
        "score_first",
    )
    assert result["best_score"] == 42
    assert result["best_round"] == "agent-2"


def test_valid_then_score_filters_invalid():
    result = select_best(
        [
            _submission("agent-1", 0.9, 10, valid=False),
            _submission("agent-2", 0.6, 20),
        ],
        "maximize",
        "valid_then_score",
    )
    assert result["best_score"] == 20
    assert result["best_round"] == "agent-2"
