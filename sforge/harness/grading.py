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

"""Grading: the grader's ``result.json`` is the whole result. Score only.

The grader writes ``{"score": <raw>, "valid": <bool>, "summary": ..., "details": [...],
"metrics": {...}}``. ``score`` ranks submissions (after the task's rescale);
``details`` and ``metrics`` are informational. stdout is never parsed.
"""

from __future__ import annotations

import json
import math
from dataclasses import asdict, dataclass, field
from typing import Any

SUMMARY_MAX_LEN = 4096


@dataclass
class EvalReport:
    task_id: str
    submission_id: str
    score: float | None = None
    score_0_100: float | None = None
    valid: bool = False
    summary: str | None = None
    details: list[dict] = field(default_factory=list)
    metrics: dict[str, Any] = field(default_factory=dict)
    timed_out: bool = False
    runtime_seconds: float = 0.0
    submitted_at: float = 0.0
    error: str | None = None

    def to_dict(self) -> dict:
        d = asdict(self)
        if d.get("summary") and len(d["summary"]) > SUMMARY_MAX_LEN:
            d["summary"] = d["summary"][:SUMMARY_MAX_LEN]
        return d


def parse_result(text: str) -> tuple[float | None, bool, dict]:
    """``(score, valid, result)`` from result.json text. A missing, malformed
    or non-finite score makes the submission invalid."""
    try:
        result = json.loads(text)
    except ValueError:
        return None, False, {}
    if not isinstance(result, dict):
        return None, False, {}
    score = result.get("score")
    if isinstance(score, bool) or not isinstance(score, (int, float)) or not math.isfinite(score):
        return None, False, result
    return float(score), bool(result.get("valid", True)), result


def select_best(entries: list[dict], direction: str = "maximize") -> dict | None:
    """Best valid, completed entry by score (first one wins ties)."""
    best = None
    for e in entries:
        if e.get("status", "completed") != "completed" or not e.get("valid"):
            continue
        s = e.get("score")
        if s is None:
            continue
        if best is None or (s < best["score"] if direction == "minimize" else s > best["score"]):
            best = e
    return best
