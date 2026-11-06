#!/usr/bin/env python3
"""Turn the v1 eval output into /opt/sforge/result.json (Verified judge contract).

v1 graded this task with the legacy `score_sum` parser (sforge/harness/grading.py
_grade_legacy): `valid` was always true, the raw score was the FIRST
`TOTAL_SCORE <n>` anywhere in the test output (extract_score), and the CASE lines
only fed pass_rate/details. With `selection = score_first`, pass_rate was a
tie-breaker after the score. The regexes below are copied from
sforge/harness/log_parsers/score_sum.py and grading.py (Apache-2.0,
Copyright (c) 2026 ByteDance Ltd. and/or its affiliates).

  eval output                                   v1 score   result.json
  TOTAL_SCORE <n> (OK, WA, RE, TLE paths)        n          valid=true, score=n
  no TOTAL_SCORE (eval script crashed)          None       valid=false (v1: unrankable)
"""
import json
import re
import sys

CASE_RE = re.compile(r"^CASE\s+(\S+)\s+(OK|TLE|RE|WA|CE)\s+score=(inf|\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)",
                     re.MULTILINE)
TOTAL_RE = re.compile(r"TOTAL_SCORE\s+(inf|\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)")
RESULT = "/opt/sforge/result.json"


def main() -> None:
    out = open(sys.argv[1], encoding="utf-8", errors="replace").read()
    eval_exit = int(sys.argv[2])

    details = []
    for m in CASE_RE.finditer(out):
        cid, st, sc = m.group(1), m.group(2), float(m.group(3))
        details.append({"name": f"case_{cid}" if st == "OK" else f"case_{cid}_{st}",
                        "status": "PASSED" if st == "OK" else "FAILED",
                        "score": None if sc == float("inf") else sc})
    if not details:
        details.append({"name": "compile" if ("CE" in out or "compile" in out.lower()) else "unknown",
                        "status": "FAILED"})
    passed = sum(d["status"] == "PASSED" for d in details)
    summary = f"{passed}/{len(details)} tests passed"
    failed = [d["name"] for d in details if d["status"] != "PASSED"]
    if failed:
        summary += f". Failed: {', '.join(failed[:10])}" + (f" (+{len(failed) - 10} more)" if len(failed) > 10 else "")

    m = TOTAL_RE.search(out)
    score = float(m.group(1)) if m else None
    mt = re.search(r"Average=(\d+\.\d+) MT/s", out)
    result = {
        "valid": score is not None and score != float("inf"),
        "summary": summary if m else summary + ". No TOTAL_SCORE in eval output",
        "details": details,
        "metrics": {"pass_rate": passed / len(details), "cases_ok": passed, "cases_total": len(details),
                    "average_mt_s": float(mt.group(1)) if mt else None, "eval_exit_code": eval_exit},
    }
    if result["valid"]:
        result["score"] = score
    with open(RESULT, "w") as f:
        json.dump(result, f, indent=1)
    print("--- result.json ---")
    print(json.dumps({k: v for k, v in result.items() if k != "details"}))


if __name__ == "__main__":
    main()
