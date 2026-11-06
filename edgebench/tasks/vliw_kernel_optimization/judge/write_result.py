#!/usr/bin/env python3
"""Turn the vliw_kernel_optimization eval output into /opt/sforge/result.json.

v1 parsed the eval output with SForge's `structured_json` parser (`_grade_structured`),
selected `valid_then_score`, direction minimize, rescale `log_min`. The parsing below is
copied from sforge/harness/log_parsers/structured_json.py and sforge/harness/grading.py
(marker strategy disabled, see V1_MARKER_STRATEGY_REACHABLE)
(Apache-2.0, Copyright (c) 2026 ByteDance Ltd. and/or its affiliates), as in the other
migrated structured_json tasks, so the raw score is v1's:

  v1 output (eval_hidden.py)                       v1 score       result.json
  first `{` line with a result key is the block:
    all cases correct (report all_correct)         s = max cycles  valid=true, score=s
    some case wrong / runner error / 600 s timeout None, invalid   valid=false, no score
  a `{` line printed earlier by the submission     whatever it says (Known issue in NOTES.md)
  no `{` result line at all, no TOTAL_SCORE        None            valid=false, no score
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

# ---- copied from sforge/harness/log_parsers/structured_json.py -------------------


# In v1 the marker strategy below never succeeded for this task. The harness ran eval_cmd from /tmp/eval.sh
# with `set -x`, so the parsed test output always contained, before any program output, the xtrace line
# `+ python -c 'exec("...\nprint('\''>>>>> Start Structured Result'\'')\nprint(json.dumps(...))\nprint('\''>>>>> End Structured Result'\'')")'`
# (one line: the newlines in the program are the two characters backslash-n there). The first Start and End
# markers were therefore both on that fixed line, the text between them is not JSON, and v1 always fell
# through to strategy 2 (the first line starting with `{` that parses as a result object). Without a forged
# `{` line from the submission that is the eval program's own block. The new run.sh has no such xtrace
# line, so strategy 1 is switched off to keep v1's behaviour (otherwise a marker pair printed by solution.py
# would win; see NOTES.md, Deviation 2).
V1_MARKER_STRATEGY_REACHABLE = False


def parse_structured_json(output: str) -> dict:
    marker_start = ">>>>> Start Structured Result"
    marker_end = ">>>>> End Structured Result"
    si = output.find(marker_start)
    ei = output.find(marker_end)
    if V1_MARKER_STRATEGY_REACHABLE and si != -1 and ei != -1:
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
    data, score = g["data"], g["score"]
    try:
        score = None if score is None else float(score)
    except (TypeError, ValueError):
        score = None
    metrics = data.get("metrics") if isinstance(data.get("metrics"), dict) else {}
    result = {
        "valid": bool(g["valid"]) and score is not None,
        "summary": data.get("summary") or ("no structured result in eval output" if not data else None),
        "details": data.get("details", []) if isinstance(data.get("details", []), list) else [],
        "metrics": {**metrics, "v1_pass_rate": g["pass_rate"], "v1_valid": g["valid"],
                    "v1_passed": g["passed"], "v1_total_tests": g["total"]},
    }
    if score is not None:
        result["score"] = score
    out_path.parent.mkdir(parents=True, exist_ok=True)
    tmp = out_path.with_name(out_path.name + ".tmp")
    tmp.write_text(json.dumps(result, ensure_ascii=False), encoding="utf-8")
    tmp.replace(out_path)
    print(f"result: valid={result['valid']} score={result.get('score')} summary={result['summary']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
