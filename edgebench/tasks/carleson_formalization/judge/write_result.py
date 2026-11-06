#!/usr/bin/env python3
"""Turn the v1 eval output of carleson_formalization into /opt/sforge/result.json.

v1 ran the eval command, parsed its output with SForge's `structured_json` parser,
ranked submissions with `pass_rate_first` and rescaled `score` linearly over 0..1.
This file reproduces that parsing exactly (functions below are copied from
sforge/harness/log_parsers/structured_json.py and sforge/harness/grading.py,
Apache-2.0, Copyright (c) 2026 ByteDance Ltd. and/or its affiliates) and emits a
single raw score:

  v1 output                                   v1 score / pass_rate   result.json
  eval_lean JSON, valid                       s / s                  valid=true,  score=s
  eval_lean JSON, valid=false (error)         0.0 / 0.0              valid=false, score=0.0
  no JSON (build failed, no submission ...)   None / 0.0             valid=false, no score
  no JSON but "TOTAL_SCORE x" in output       x / 0.0                valid=false, score=x

s = repaired / 3004, or 0 when the protected `classical_carleson_check` HASH check fails (eval_lean
sets score == pass_rate, so ranking by pass_rate
and by score agree). Entries without an eval_lean JSON have pass_rate 0 in v1 and
are never chosen by pass_rate_first, so they are invalid here; a score is still
reported when v1 had one, so the per-submission 0-100 equals v1's.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

# ---- copied from sforge/harness/log_parsers/structured_json.py -------------------


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


# ---- copied from sforge/harness/grading.py ---------------------------------------


def extract_score(test_output: str) -> float | None:
    m = re.search(r"TOTAL_SCORE\s+(inf|\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)", test_output)
    return float(m.group(1)) if m else None


def grade_structured(test_output: str) -> dict:
    """The fields of sforge's _grade_structured that matter for scoring."""
    data = parse_structured_json(test_output)
    raw_details = data.get("details", [])
    if raw_details:
        passed = sum(1 for d in raw_details if d.get("status") == "PASSED")
        total = len(raw_details)
    else:
        passed = data.get("passed", 0)
        total = data.get("total_tests", 0)
    pass_rate = data.get("pass_rate")
    if pass_rate is None and total > 0:
        pass_rate = passed / total
    elif pass_rate is None:
        pass_rate = 0.0
    score = data.get("score")
    if score is None:
        score = extract_score(test_output)
    return {"data": data, "score": score, "pass_rate": pass_rate,
            "valid": data.get("valid", True), "passed": passed, "total": total}


# ---- result.json -----------------------------------------------------------------


def main() -> int:
    log_path, out_path = Path(sys.argv[1]), Path(sys.argv[2])
    text = log_path.read_text(encoding="utf-8", errors="replace") if log_path.exists() else ""
    g = grade_structured(text)
    data = g["data"]
    score = g["score"]
    result = {
        # no JSON -> v1 score None (or a TOTAL_SCORE fallback) with pass_rate 0,
        # which pass_rate_first never selects; eval_lean error -> v1 valid=false.
        "valid": bool(data) and bool(g["valid"]) and score is not None,
        "summary": data.get("summary") or ("no structured result in eval output" if not data else None),
        "details": data.get("details", []),
        "metrics": {
            **({k: data["metrics"].get(k) for k in (
                "baseline_total", "repaired_count", "remaining_bad_count", "disappeared_count",
                "type_changed_count", "new_bad_count", "declaration_changed_count")}
               if isinstance(data.get("metrics"), dict) else {}),
            "v1_pass_rate": g["pass_rate"],
            "v1_valid": g["valid"],
        },
    }
    if score is not None:
        result["score"] = float(score)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(result, ensure_ascii=False), encoding="utf-8")
    print(f"result: valid={result['valid']} score={result.get('score')} "
          f"v1_pass_rate={g['pass_rate']} summary={result['summary']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
