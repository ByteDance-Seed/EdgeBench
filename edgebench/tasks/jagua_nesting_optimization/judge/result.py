#!/usr/bin/env python3
"""Translate the v1 eval output into /opt/sforge/result.json.

usage: result.py <eval log> <eval exit code>
Semantics are v1's: per-case statuses from sforge/harness/log_parsers/score_sum.py and the raw
score from sforge/harness/grading.py:extract_score (first TOTAL_SCORE in the output).
"""
import json
import re
import sys

log_path, eval_exit = sys.argv[1], int(sys.argv[2])
txt = open(log_path, encoding="utf-8", errors="replace").read()

# score_sum.parse_score_sum (same regex)
case_re = re.compile(r"^CASE\s+(\S+)\s+(OK|TLE|RE|WA|CE)\s+score=(inf|\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)", re.M)
details = []
for m in case_re.finditer(txt):
    cid, st, sc = m.groups()
    line_end = txt.find("\n", m.end())
    rest = txt[m.end(): None if line_end < 0 else line_end]
    reason = rest.split(" reason=", 1)[1] if " reason=" in rest else ""
    details.append({
        "name": f"case_{cid}" if st == "OK" else f"case_{cid}_{st}",
        "status": "PASSED" if st == "OK" else "FAILED",
        "score": None if sc == "inf" else float(sc),
        "message": reason[:1000],
    })
if not details:
    name = "compile" if ("CE" in txt or "compile" in txt.lower()) else "unknown"
    details.append({"name": name, "status": "FAILED", "score": None, "message": ""})

# grading._grade_legacy summary
passed = sum(d["status"] == "PASSED" for d in details)
summary = f"{passed}/{len(details)} tests passed"
failed = [d["name"] for d in details if d["status"] != "PASSED"]
if failed:
    summary += ". Failed: " + ", ".join(failed[:10])
    if len(failed) > 10:
        summary += f" (+{len(failed) - 10} more)"

# grading.extract_score
m = re.search(r"TOTAL_SCORE\s+(inf|\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)", txt)
score = float(m.group(1)) if m else None
if score is None or score == float("inf"):
    # v1 reported score=None (unrankable) here; the Verified contract expresses that as valid=false.
    score, valid = None, False
    summary += ". No TOTAL_SCORE in eval output"
else:
    valid = True

result = {"score": score, "valid": valid, "summary": summary, "details": details,
          "metrics": {"cases_passed": passed, "cases_total": len(details), "eval_exit_code": eval_exit}}
with open("/opt/sforge/result.json.tmp", "w") as f:
    json.dump(result, f, indent=1)
import os
os.replace("/opt/sforge/result.json.tmp", "/opt/sforge/result.json")
