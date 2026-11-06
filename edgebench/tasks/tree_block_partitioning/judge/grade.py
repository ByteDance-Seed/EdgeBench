#!/usr/bin/env python3
"""Turn the v1 eval.py --score-sum output into /opt/sforge/result.json.

v1 semantics reproduced exactly:
  * details  = sforge/harness/log_parsers/score_sum.py (case_<id> / case_<id>_<STATUS>,
               "compile"/"unknown" fallback when no CASE line was printed)
  * summary  = sforge/harness/grading.py:_grade_legacy ("P/N tests passed. Failed: ...")
  * score    = sforge/harness/grading.py:extract_score, i.e. the FIRST
               `TOTAL_SCORE <n>` anywhere in the output (0..100).
When no TOTAL_SCORE is found (eval.py died early), v1 reported score=None (unrankable);
here that is valid=false, score=null.
"""
import json
import os
import re
import sys

CASE_RE = re.compile(r"^CASE\s+(\S+)\s+(OK|TLE|RE|WA|CE)\s+score=(inf|\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)",
                     re.MULTILINE)
TOTAL_RE = re.compile(r"TOTAL_SCORE\s+(inf|\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)")


def main(log_path, eval_exit, out_path):
    out = open(log_path, encoding="utf-8", errors="replace").read()
    details = []
    for m in CASE_RE.finditer(out):
        cid, st = m.group(1), m.group(2)
        ok = st == "OK"
        details.append({"name": f"case_{cid}" if ok else f"case_{cid}_{st}",
                        "status": "PASSED" if ok else "FAILED", "score": float(m.group(3))})
    if not details:
        name = "compile" if ("CE" in out or "compile" in out.lower()) else "unknown"
        details.append({"name": name, "status": "FAILED", "score": None})
    passed = sum(d["status"] == "PASSED" for d in details)
    summary = f"{passed}/{len(details)} tests passed"
    failed = [d["name"] for d in details if d["status"] != "PASSED"]
    if failed:
        summary += f". Failed: {', '.join(failed[:10])}"
        if len(failed) > 10:
            summary += f" (+{len(failed) - 10} more)"
    m = TOTAL_RE.search(out)
    score = float(m.group(1)) if m else None
    if score is None or score == float("inf"):
        valid, score = False, None
        summary += ". No TOTAL_SCORE in eval output"
    else:
        valid = True
    # Per-problem lines printed by eval.py, e.g. "T1_P5611: 90/90 (1.000000)" (informational).
    problems = {pm.group(1): {"passed": int(pm.group(2)), "total": int(pm.group(3)), "fraction": float(pm.group(4))}
                for pm in re.finditer(r"^(T[1-6]_\S+): (\d+)/(\d+) \(([0-9.]+)\)$", out, re.MULTILINE)}
    result = {"score": score, "valid": valid, "summary": summary, "details": details,
              "metrics": {"units_passed": passed, "units_total": len(details),
                          "eval_exit_code": int(eval_exit), "problems": problems}}
    with open(out_path + ".tmp", "w") as f:
        json.dump(result, f)
    os.replace(out_path + ".tmp", out_path)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], sys.argv[3])
