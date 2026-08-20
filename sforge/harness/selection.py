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

"""Selection policies for choosing the best submission."""

from __future__ import annotations

from typing import Any


def select_best(
    entries: list[dict[str, Any]],
    score_direction: str = "maximize",
    policy: str = "pass_rate_first",
) -> dict[str, Any]:
    """Select the best submission from a list of history entries.

    Returns dict with: best_score, best_pass_rate, best_round, best_valid.
    """
    fn = _POLICIES.get(policy)
    if fn is None:
        raise ValueError(f"Unknown selection policy: {policy}. Available: {list(_POLICIES)}")
    return fn(entries, score_direction)


def _completed_submissions(entries: list[dict]) -> list[dict]:
    return [
        e for e in entries
        if e.get("type", "submission") in ("submission", "game")
        and e.get("status") in (None, "completed")
    ]


def _is_better_score(new: float, old: float | None, direction: str) -> bool:
    if old is None:
        return True
    return new < old if direction == "minimize" else new > old


def _pass_rate_first(entries: list[dict], score_direction: str) -> dict:
    """Current legacy logic: higher pass_rate wins; at 100%, compare score."""
    best_score: float | None = None
    best_pass_rate: float = 0.0
    best_round: str = ""

    for e in _completed_submissions(entries):
        pr = e.get("pass_rate", 0.0) or 0.0
        s = e.get("score") if e.get("score") is not None else e.get("max_score")
        is_new_best = False

        if pr < 1.0 or best_pass_rate < 1.0:
            if pr > best_pass_rate:
                best_pass_rate = pr
                best_score = s
                is_new_best = True
        else:
            if s is not None and _is_better_score(s, best_score, score_direction):
                best_score = s
                is_new_best = True

        if is_new_best:
            best_round = e.get("round", "")

    return {
        "best_score": best_score,
        "best_pass_rate": best_pass_rate,
        "best_round": best_round,
        "best_valid": True,
    }


def _score_first(entries: list[dict], score_direction: str) -> dict:
    """Compare score directly, ignoring pass_rate for ordering."""
    best_score: float | None = None
    best_pass_rate: float = 0.0
    best_round: str = ""

    for e in _completed_submissions(entries):
        s = e.get("score")
        if s is None:
            continue
        if _is_better_score(s, best_score, score_direction):
            best_score = s
            best_pass_rate = e.get("pass_rate", 0.0) or 0.0
            best_round = e.get("round", "")

    return {
        "best_score": best_score,
        "best_pass_rate": best_pass_rate,
        "best_round": best_round,
        "best_valid": True,
    }


def _valid_then_score(entries: list[dict], score_direction: str) -> dict:
    """Filter out valid=false entries, then compare score."""
    valid_entries = [
        e for e in _completed_submissions(entries)
        if e.get("valid", True)
    ]
    if not valid_entries:
        return {
            "best_score": None,
            "best_pass_rate": 0.0,
            "best_round": "",
            "best_valid": False,
        }

    result = _score_first(valid_entries, score_direction)
    result["best_valid"] = True
    return result


_POLICIES = {
    "pass_rate_first": _pass_rate_first,
    "score_first": _score_first,
    "valid_then_score": _valid_then_score,
}
