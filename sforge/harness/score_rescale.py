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

"""Deterministic raw-score-to-0-100 rescaling per task.

Each task may define a ``rescale`` table in its task.toml with a ``kind``
and associated parameters.  The :func:`rescale_score` function applies the
mapping and clips the result to ``[0, 100]``.  Unknown or missing rescale
configs fall back to ``clip(raw, 0, 100)``.
"""

from __future__ import annotations

import math
from dataclasses import dataclass


@dataclass(frozen=True)
class RescaleSpec:
    kind: str
    lower: float | None = None
    upper: float | None = None
    baseline: float | None = None
    expert: float | None = None
    rank30: float | None = None
    rank1: float | None = None
    super_anchor: float | None = None
    anchor_raw: float | None = None
    anchor_score: float | None = None


def parse_rescale_spec(data: dict | None) -> RescaleSpec | None:
    if not data or "kind" not in data:
        return None
    return RescaleSpec(
        kind=data["kind"],
        lower=data.get("lower"),
        upper=data.get("upper"),
        baseline=data.get("baseline"),
        expert=data.get("expert"),
        rank30=data.get("rank30"),
        rank1=data.get("rank1"),
        super_anchor=data.get("super_anchor"),
        anchor_raw=data.get("anchor_raw"),
        anchor_score=data.get("anchor_score"),
    )


def _clip(v: float, lo: float = 0.0, hi: float = 100.0) -> float:
    if math.isnan(v):
        return v
    return max(lo, min(hi, v))


def rescale_score(spec: RescaleSpec | None, raw_score: float | None) -> float | None:
    """Convert a raw score to a clipped 0-100 score using *spec*.

    Returns ``None`` when *raw_score* is ``None`` or *spec* is ``None``.
    Returns ``NaN`` for degenerate parameter combinations.
    """
    if spec is None or raw_score is None:
        return None
    raw = raw_score
    if not math.isfinite(raw):
        return None

    k = spec.kind

    if k == "linear":
        assert spec.lower is not None and spec.upper is not None
        if spec.upper == spec.lower:
            return math.nan
        return _clip(100.0 * (raw - spec.lower) / (spec.upper - spec.lower))

    if k == "min_linear":
        assert spec.baseline is not None and spec.expert is not None
        if spec.baseline == spec.expert:
            return math.nan
        return _clip(100.0 * (spec.baseline - raw) / (spec.baseline - spec.expert))

    if k == "min_linear_positive":
        assert spec.baseline is not None and spec.expert is not None
        if raw <= 0 or spec.baseline == spec.expert:
            return 0.0
        return _clip(100.0 * (spec.baseline - raw) / (spec.baseline - spec.expert))

    if k == "min_inverse_anchor":
        assert spec.anchor_raw is not None and spec.anchor_score is not None
        if raw <= 0 or spec.anchor_raw <= 0:
            return 0.0
        return _clip(spec.anchor_score * spec.anchor_raw / raw)

    if k == "compression_ratio_cropped_guarded":
        assert spec.baseline is not None and spec.expert is not None
        if raw < 0.05 or spec.baseline == spec.expert:
            return 0.0
        return _clip(100.0 * (spec.baseline - raw) / (spec.baseline - spec.expert))

    if k == "log_anchor":
        assert spec.anchor_raw is not None and spec.anchor_score is not None
        if raw <= 1.0 or spec.anchor_raw <= 1.0:
            return 0.0
        return _clip(spec.anchor_score * math.log(raw) / math.log(spec.anchor_raw))

    if k == "log_max":
        assert spec.baseline is not None and spec.expert is not None
        if raw <= 0 or spec.baseline <= 0 or spec.expert <= 0 or spec.baseline == spec.expert:
            return 0.0
        return _clip(100.0 * math.log(raw / spec.baseline) / math.log(spec.expert / spec.baseline))

    if k == "log1p_max":
        assert spec.baseline is not None and spec.upper is not None
        if raw <= 0 or spec.baseline <= 0 or spec.upper <= 0:
            return 0.0
        denom = math.log1p(spec.upper / spec.baseline)
        if denom == 0.0:
            return math.nan
        return _clip(100.0 * math.log1p(raw / spec.baseline) / denom)

    if k == "log_min":
        assert spec.baseline is not None and spec.expert is not None
        if raw <= 0 or spec.baseline <= 0 or spec.expert <= 0 or spec.baseline == spec.expert:
            return 0.0
        return _clip(100.0 * math.log(spec.baseline / raw) / math.log(spec.baseline / spec.expert))

    if k == "piecewise_max":
        assert spec.baseline is not None and spec.rank30 is not None and spec.rank1 is not None and spec.super_anchor is not None
        if raw <= spec.baseline:
            return 0.0
        if raw <= spec.rank30:
            if spec.rank30 == spec.baseline:
                return math.nan
            return _clip(20.0 * (raw - spec.baseline) / (spec.rank30 - spec.baseline), 0.0, 20.0)
        if raw <= spec.rank1:
            if spec.rank1 == spec.rank30:
                return math.nan
            return _clip(20.0 + 60.0 * (raw - spec.rank30) / (spec.rank1 - spec.rank30), 20.0, 80.0)
        if raw <= spec.super_anchor:
            if spec.super_anchor == spec.rank1:
                return math.nan
            return _clip(80.0 + 20.0 * (raw - spec.rank1) / (spec.super_anchor - spec.rank1), 80.0, 100.0)
        return 100.0

    if k == "piecewise_min":
        assert spec.baseline is not None and spec.rank30 is not None and spec.rank1 is not None and spec.super_anchor is not None
        if raw <= 0 or raw >= spec.baseline:
            return 0.0
        if raw >= spec.rank30:
            if spec.baseline == spec.rank30:
                return math.nan
            return _clip(20.0 * (spec.baseline - raw) / (spec.baseline - spec.rank30), 0.0, 20.0)
        if raw >= spec.rank1:
            if spec.rank30 == spec.rank1:
                return math.nan
            return _clip(20.0 + 60.0 * (spec.rank30 - raw) / (spec.rank30 - spec.rank1), 20.0, 80.0)
        if raw >= spec.super_anchor:
            if spec.rank1 == spec.super_anchor:
                return math.nan
            return _clip(80.0 + 20.0 * (spec.rank1 - raw) / (spec.rank1 - spec.super_anchor), 80.0, 100.0)
        return 100.0

    if k == "piecewise_log_min":
        assert spec.baseline is not None and spec.rank30 is not None and spec.rank1 is not None and spec.super_anchor is not None
        if raw <= 0 or spec.baseline <= 0 or spec.rank30 <= 0 or spec.rank1 <= 0 or spec.super_anchor <= 0:
            return 0.0
        if raw >= spec.baseline:
            return 0.0
        if raw >= spec.rank30:
            denom = math.log(spec.baseline / spec.rank30)
            if denom == 0.0:
                return math.nan
            return _clip(20.0 * math.log(spec.baseline / raw) / denom, 0.0, 20.0)
        if raw >= spec.rank1:
            denom = math.log(spec.rank30 / spec.rank1)
            if denom == 0.0:
                return math.nan
            return _clip(20.0 + 60.0 * math.log(spec.rank30 / raw) / denom, 20.0, 80.0)
        if raw >= spec.super_anchor:
            denom = math.log(spec.rank1 / spec.super_anchor)
            if denom == 0.0:
                return math.nan
            return _clip(80.0 + 20.0 * math.log(spec.rank1 / raw) / denom, 80.0, 100.0)
        return 100.0

    return _clip(raw)
