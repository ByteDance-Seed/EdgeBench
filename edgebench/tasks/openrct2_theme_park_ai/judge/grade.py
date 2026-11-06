#!/usr/bin/env python3
"""Grader for openrct2_theme_park_ai (Verified judge contract, see SCHEMA.md).

Reproduces v1 exactly:
  v1 eval_cmd : cd /home/workspace/openrct2 && OPENRCT2_TIMEOUT=120 python3 /tmp/eval_openrct2.py
  v1 parser   : score_sum (case lines -> details/summary)
  v1 score    : first `TOTAL_SCORE <n>` anywhere in the eval output (grading.extract_score)

/judge/eval_openrct2.py is the v1 wrapper with one change (it calls
/judge/openrct2_original_eval.py instead of /tmp/...). /judge/openrct2_original_eval.py is
byte-identical to v1. This file only runs the wrapper and turns its output into
/opt/sforge/result.json. stdout = logs only.
"""
import json
import os
import re
import subprocess
import sys
import tempfile

CWD = "/home/workspace/openrct2"
RESULT_DIR = "/opt/sforge"
RESULT = os.path.join(RESULT_DIR, "result.json")

# sforge/harness/log_parsers/score_sum.py
CASE_RE = re.compile(
    r"^CASE\s+(\S+)\s+(OK|TLE|RE|WA|CE)\s+score=(inf|\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)",
    re.MULTILINE,
)
# sforge/harness/grading.py:extract_score
TOTAL_RE = re.compile(r"TOTAL_SCORE\s+(inf|\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)")


def main():
    os.makedirs(RESULT_DIR, exist_ok=True)
    try:
        os.remove(RESULT)
    except FileNotFoundError:
        pass

    env = dict(os.environ, OPENRCT2_TIMEOUT="120")
    with tempfile.TemporaryFile() as log:
        proc = subprocess.run([sys.executable, "/judge/eval_openrct2.py"], cwd=CWD, env=env,
                              stdout=log, stderr=subprocess.STDOUT)
        log.seek(0)
        out = log.read().decode("utf-8", errors="replace")
    sys.stdout.write(out)
    print("eval_openrct2.py exit code: %d" % proc.returncode)
    # v1 graded the text between the eval.sh markers, .strip()ped.
    out = out.strip()

    details = []
    passed = 0
    for m in CASE_RE.finditer(out):
        case_id, status, sc = m.groups()
        if status == "OK":
            details.append({"name": "case_" + case_id, "status": "PASSED"})
            passed += 1
        else:
            details.append({"name": "case_%s_%s" % (case_id, status), "status": "FAILED"})
        details[-1]["score"] = None if sc == "inf" else float(sc)
    if not details:
        name = "compile" if ("CE" in out or "compile" in out.lower()) else "unknown"
        details.append({"name": name, "status": "FAILED", "score": None})

    summary = "%d/%d tests passed" % (passed, len(details))
    failed = [d["name"] for d in details if d["status"] != "PASSED"]
    if failed:
        summary += ". Failed: " + ", ".join(failed[:10])
        if len(failed) > 10:
            summary += " (+%d more)" % (len(failed) - 10)

    m = TOTAL_RE.search(out)
    if m and m.group(1) != "inf":
        score, valid = float(m.group(1)), True
    else:
        # v1: score=None (unrankable); the Verified contract says valid=false.
        score, valid = None, False
        summary += ". No TOTAL_SCORE in eval output"

    result = {
        "score": score,
        "valid": valid,
        "summary": summary,
        "details": details,
        "metrics": {"cases_passed": passed, "cases_total": len(details),
                    "eval_exit_code": proc.returncode},
    }
    with open(RESULT + ".tmp", "w") as f:
        json.dump(result, f)
    os.replace(RESULT + ".tmp", RESULT)
    print("--- result.json ---")
    print(json.dumps(result)[:400])


if __name__ == "__main__":
    main()
