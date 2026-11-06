#!/usr/bin/env python3
"""Grader for apple_incremental_game (Verified judge contract, see SCHEMA.md).

Reproduces v1 exactly:
  v1 eval_cmd : cd /home/workspace/apple_incremental_game && python3 /tmp/eval_apple_incremental_game.py
  v1 parser   : score_sum  (sforge/harness/log_parsers/score_sum.py)
  v1 score    : first `TOTAL_SCORE <n>` in the eval output (sforge/harness/grading.py:extract_score)
/judge/eval_apple_incremental_game.py is byte-identical to the v1 /tmp/eval_apple_incremental_game.py.
This wrapper only runs it and translates its stdout into /opt/sforge/result.json.
stdout = logs only.
"""
import json
import math
import os
import re
import subprocess
import sys
import tempfile

CWD = "/home/workspace/apple_incremental_game"
EVAL_CMD = "cd /home/workspace/apple_incremental_game && python3 /judge/eval_apple_incremental_game.py"
RESULT_DIR = "/opt/sforge"
RESULT = os.path.join(RESULT_DIR, "result.json")

# score_sum.parse_score_sum and grading.extract_score, verbatim regexes.
CASE_RE = re.compile(r"^CASE\s+(\S+)\s+(OK|TLE|RE|WA|CE)\s+score=(inf|\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)",
                     re.MULTILINE)
TOTAL_RE = re.compile(r"TOTAL_SCORE\s+(inf|\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)")


def num(s: str):
    v = float(s)
    return None if math.isinf(v) else v


def main() -> int:
    os.makedirs(RESULT_DIR, exist_ok=True)
    try:
        os.remove(RESULT)
    except FileNotFoundError:
        pass

    with tempfile.TemporaryFile() as log:
        proc = subprocess.run(["bash", "-c", EVAL_CMD], cwd=CWD, stdout=log, stderr=subprocess.STDOUT)
        log.seek(0)
        out = log.read().decode("utf-8", errors="replace")
    sys.stdout.write(out)
    print(f"eval_apple_incremental_game.py exit code: {proc.returncode}")

    details, passed = [], 0
    for m in CASE_RE.finditer(out):
        cid, st, sc = m.group(1), m.group(2), m.group(3)
        if st == "OK":
            details.append({"name": f"case_{cid}", "status": "PASSED", "score": num(sc)})
            passed += 1
        else:
            details.append({"name": f"case_{cid}_{st}", "status": "FAILED", "score": num(sc)})
    if not details:  # score_sum fallback when no CASE line was printed
        name = "compile" if ("CE" in out or "compile" in out.lower()) else "unknown"
        details.append({"name": name, "status": "FAILED", "score": None})

    # _grade_legacy summary
    summary = f"{passed}/{len(details)} tests passed"
    failed = [d["name"] for d in details if d["status"] != "PASSED"]
    if failed:
        summary += f". Failed: {', '.join(failed[:10])}"
        if len(failed) > 10:
            summary += f" (+{len(failed) - 10} more)"

    m = TOTAL_RE.search(out)
    if m is None or m.group(1) == "inf":
        # v1: no TOTAL_SCORE -> score None (unrankable). The eval script sums integer
        # case scores, so `TOTAL_SCORE inf` cannot occur; it would also be unrankable in v1.
        # The Verified contract expresses "not rankable" as valid=false.
        score, valid = None, False
        summary += ". TOTAL_SCORE inf" if m else ". No TOTAL_SCORE in eval output"
    else:
        score, valid = float(m.group(1)), True

    result = {"score": score, "valid": valid, "summary": summary, "details": details,
              "metrics": {"cases_passed": passed, "cases_total": len(details),
                          "eval_exit_code": proc.returncode}}
    tmp = RESULT + ".tmp"
    with open(tmp, "w") as f:
        json.dump(result, f)
    os.replace(tmp, RESULT)
    print("--- result.json ---")
    print(json.dumps(result)[:400])
    return 0


if __name__ == "__main__":
    sys.exit(main())
