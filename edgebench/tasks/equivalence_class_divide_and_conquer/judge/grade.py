#!/usr/bin/env python3
"""Grader for equivalence_class_divide_and_conquer (Verified judge contract, see SCHEMA.md).

Reproduces v1 exactly:
  v1 eval_cmd : cd /home/workspace/p2 && python3 /opt/p2_judge/prob/P2/eval.py
                --source-root /home/workspace/p2 --time-factor 1 --time-grace 0 --score-sum
  v1 parser   : score_sum  (sforge/harness/log_parsers/score_sum.py)
  v1 score    : first `TOTAL_SCORE <n>` in the eval output (sforge/harness/grading.py:extract_score)
/opt/p2_judge is byte-identical to v1. This wrapper only runs the v1 eval command and
translates its stdout into /opt/sforge/result.json. stdout = logs only.
"""
import json
import os
import re
import subprocess
import sys
import tempfile

CWD = "/home/workspace/p2"
EVAL_CMD = ("cd /home/workspace/p2 && python3 /opt/p2_judge/prob/P2/eval.py "
            "--source-root /home/workspace/p2 --time-factor 1 --time-grace 0 --score-sum")
RESULT_DIR = "/opt/sforge"
RESULT = os.path.join(RESULT_DIR, "result.json")

# score_sum.parse_score_sum and grading.extract_score, verbatim regexes.
CASE_RE = re.compile(r"^CASE\s+(\S+)\s+(OK|TLE|RE|WA|CE)\s+score=(inf|\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)",
                     re.MULTILINE)
TOTAL_RE = re.compile(r"TOTAL_SCORE\s+(inf|\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)")
# Per-problem lines printed by eval.py (informational metrics only).
TASK_RE = re.compile(r"^(T[1-6]_\S+): (\d+)/(\d+) \(([0-9.]+)\)$", re.MULTILINE)


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
    print(f"eval.py exit code: {proc.returncode}")

    details, passed = [], 0
    for m in CASE_RE.finditer(out):
        cid, st, sc = m.group(1), m.group(2), m.group(3)
        if st == "OK":
            details.append({"name": f"case_{cid}", "status": "PASSED", "score": float(sc)})
            passed += 1
        else:
            details.append({"name": f"case_{cid}_{st}", "status": "FAILED", "score": float(sc)})
    if not details:
        name = "compile" if ("CE" in out or "compile" in out.lower()) else "unknown"
        details.append({"name": name, "status": "FAILED", "score": None})

    summary = f"{passed}/{len(details)} tests passed"
    failed = [d["name"] for d in details if d["status"] != "PASSED"]
    if failed:
        summary += f". Failed: {', '.join(failed[:10])}"
        if len(failed) > 10:
            summary += f" (+{len(failed) - 10} more)"

    m = TOTAL_RE.search(out)
    if m is None or m.group(1) == "inf":
        # v1 reported score=None (unrankable); the Verified contract says valid=false.
        score, valid = None, False
        summary += ". No TOTAL_SCORE in eval output"
    else:
        score, valid = float(m.group(1)), True

    problems = {t: {"passed": int(p), "total": int(n), "fraction": float(f)}
                for t, p, n, f in TASK_RE.findall(out)}
    result = {"score": score, "valid": valid, "summary": summary, "details": details,
              "metrics": {"problems": problems, "units_passed": passed, "units_total": len(details),
                          "eval_exit_code": proc.returncode}}
    tmp = RESULT + ".tmp"
    with open(tmp, "w") as f:
        json.dump(result, f)
    os.replace(tmp, RESULT)
    print("--- result.json ---")
    print(json.dumps({k: result[k] for k in ("score", "valid", "summary")}))
    print(json.dumps(result["metrics"]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
