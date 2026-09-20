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

"""Process metrics for iterative agent evaluation trajectories."""

from __future__ import annotations

import math
from typing import Any


def _finite_float(value: Any) -> float | None:
    try:
        number = float(value)
    except (TypeError, ValueError):
        return None
    return number if math.isfinite(number) else None


def _stable_difference(left: float, right: float) -> float | None:
    difference = left - right
    return round(difference, 12) if math.isfinite(difference) else None


def compute_trajectory_metrics(
    entries: list[dict[str, Any]],
    score_direction: str = "maximize",
) -> dict[str, Any]:
    """Summarize score improvement across completed, valid submissions."""
    submissions = [
        entry
        for entry in entries
        if entry.get("type") == "submission"
        and entry.get("status") == "completed"
        and entry.get("valid", True)
    ]

    use_score = any(
        _finite_float(entry.get("score")) is not None for entry in submissions
    )
    value_field = "score" if use_score else "pass_rate"
    direction = score_direction if use_score else "maximize"

    points: list[tuple[float, float | None]] = []
    for entry in submissions:
        value = _finite_float(entry.get(value_field))
        if value is None:
            continue
        points.append((value, _finite_float(entry.get("submitted_at"))))

    # Judge workers may finish out of order. Reports carry the evaluation start
    # time, so use it when every point has one; otherwise retain insertion order
    # rather than inventing a position for an undated submission.
    if points and all(timestamp is not None for _, timestamp in points):
        points.sort(key=lambda point: point[1] if point[1] is not None else 0.0)

    if not points:
        return {
            "value_field": value_field,
            "direction": direction,
            "submission_count": 0,
            "initial_value": None,
            "final_value": None,
            "best_value": None,
            "total_improvement": 0.0,
            "improving_submissions": 0,
            "non_improving_submissions": 0,
            "first_improvement_seconds": None,
            "time_to_best_seconds": None,
        }

    better = (
        (lambda value, best: value < best)
        if direction == "minimize"
        else (lambda value, best: value > best)
    )
    initial_value = points[0][0]
    best_value = initial_value
    best_index = 0
    first_improvement_index: int | None = None
    improving_submissions = 0

    for index, (value, _) in enumerate(points[1:], start=1):
        if better(value, best_value):
            best_value = value
            best_index = index
            improving_submissions += 1
            if first_improvement_index is None:
                first_improvement_index = index

    timestamps = [timestamp for _, timestamp in points if timestamp is not None]
    start_time = min(timestamps) if timestamps else None

    def elapsed(index: int | None) -> float | None:
        if index is None or start_time is None:
            return None
        timestamp = points[index][1]
        if timestamp is None:
            return None
        difference = timestamp - start_time
        return max(difference, 0.0) if math.isfinite(difference) else None

    total_improvement = (
        _stable_difference(initial_value, best_value)
        if direction == "minimize"
        else _stable_difference(best_value, initial_value)
    )
    return {
        "value_field": value_field,
        "direction": direction,
        "submission_count": len(points),
        "initial_value": initial_value,
        "final_value": points[-1][0],
        "best_value": best_value,
        "total_improvement": total_improvement,
        "improving_submissions": improving_submissions,
        "non_improving_submissions": len(points) - improving_submissions - 1,
        "first_improvement_seconds": elapsed(first_improvement_index),
        "time_to_best_seconds": elapsed(best_index),
    }
