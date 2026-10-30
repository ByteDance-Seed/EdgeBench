#!/usr/bin/env python3
"""Turn the output of /opt/evaluator/eval_dabic_v2.py into /opt/sforge/result.json.

Reproduces v1 grading for parser `structured_json`: `parse_structured_json`
(SForge sforge/harness/log_parsers/structured_json.py, copied below unchanged) and
`_grade_structured` / `extract_score` (sforge/harness/grading.py):
  score = data["score"], else the first `TOTAL_SCORE <n>` in the output;
  valid = data.get("valid", True); summary/details/metrics passed through.
For this task a normal run prints one ">>>>> Start Structured Result" block whose
`score` is eval_dabic_v2.py's `total` and whose `valid` is its E_behavior
`valid_for_selection`; both are passed through unchanged.
Differences from v1 (both cases were unrankable in v1):
  * no score at all (eval_dabic_v2.py crashed before printing the block): v1 reported
    valid=true with score=None; Verified writes valid=false, score=null.
  * score NaN (a NaN metric in results.json, e.g. a NaN cap-rock depth): v1 reported valid=<as printed>,
    score=NaN; Verified writes valid=false, score=null (NaN is not a number in JSON).
    NaN/inf inside details/metrics (informational only) are written as null.

The parser code is Copyright (c) 2026 ByteDance Ltd. and/or its affiliates,
Apache License 2.0.
"""

from __future__ import annotations

import json
import math
import re
import sys


# ---- BEGIN copy of sforge/harness/log_parsers/structured_json.py ----
def parse_structured_json(output: str) -> dict:
    marker_start = ">>>>> Start Structured Result"
    marker_end = ">>>>> End Structured Result"
    si = output.find(marker_start)
    ei = output.find(marker_end)
    if si != -1 and ei != -1:
        block = output[si + len(marker_start) : ei].strip()
        try:
            return json.loads(block)
        except json.JSONDecodeError:
            pass

    for m in re.finditer(r"^\s*\{", output, re.MULTILINE):
        try:
            candidate = output[m.start():]
            obj = json.loads(candidate[:_find_json_end(candidate)])
            if isinstance(obj, dict) and _looks_like_result(obj):
                return obj
        except (json.JSONDecodeError, ValueError):
            continue

    try:
        obj = json.loads(output.strip())
        if isinstance(obj, dict):
            return obj
    except json.JSONDecodeError:
        pass

    return {}


def _find_json_end(text: str) -> int:
    depth = 0
    in_string = False
    escape = False
    for i, ch in enumerate(text):
        if escape:
            escape = False
            continue
        if ch == '\\' and in_string:
            escape = True
            continue
        if ch == '"' and not escape:
            in_string = not in_string
            continue
        if in_string:
            continue
        if ch == '{':
            depth += 1
        elif ch == '}':
            depth -= 1
            if depth == 0:
                return i + 1
    return len(text)


_RESULT_KEYS = {"valid", "score", "summary", "details", "metrics", "pass_rate"}


def _looks_like_result(obj: dict) -> bool:
    return bool(set(obj.keys()) & _RESULT_KEYS)
# ---- END copy ----


def extract_score(test_output: str):
    m = re.search(r"TOTAL_SCORE\s+(inf|\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)", test_output)
    return float(m.group(1)) if m else None


def _finite(x):
    """Non-finite floats (NaN/inf) in the informational fields become null, so
    result.json is strict JSON."""
    if isinstance(x, float) and not math.isfinite(x):
        return None
    if isinstance(x, dict):
        return {k: _finite(v) for k, v in x.items()}
    if isinstance(x, list):
        return [_finite(v) for v in x]
    return x


def main() -> int:
    log_path, out_path = sys.argv[1], sys.argv[2]
    with open(log_path, encoding="utf-8", errors="replace") as f:
        output = f.read()
    data = parse_structured_json(output)
    score = data.get("score")
    if score is None:
        score = extract_score(output)
    valid = bool(data.get("valid", True))
    try:
        score = float(score) if score is not None else None
    except (TypeError, ValueError):
        score = None
    if score is None or not math.isfinite(score):
        valid, score = False, None
    result = {
        "score": score,
        "valid": valid,
        "summary": data.get("summary") or ("no structured result in judge output" if not data else None),
        "details": _finite(data.get("details", [])),
        "metrics": _finite(data.get("metrics", {})),
    }
    with open(out_path, "w") as f:
        json.dump(result, f, allow_nan=False, ensure_ascii=False)
    print(json.dumps({k: result[k] for k in ("score", "valid", "summary")}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
