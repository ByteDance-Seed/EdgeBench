"""Write /opt/sforge/result.json from the pytest log, reproducing v1 scoring.

v1: parser `pytest_v` (sforge/harness/log_parsers/pytest_v.py) gave per-test statuses and the
pass rate; the raw score was `extract_score` (sforge/harness/grading.py): the FIRST
`TOTAL_SCORE <n>` in the output. The regexes below are copied from those two files.

Verified raw score:
  * TOTAL_SCORE present           -> valid, score = that value (identical to v1's raw score).
  * pytest ran but no TOTAL_SCORE -> valid, score = 0.0 (v1: score=None; missing/invalid final_result.txt).
  * no pytest result at all       -> invalid (v1: the single synthetic `unknown` ERROR entry).
"""
from __future__ import annotations

import json
import math
import re
import sys

RESULT = "/opt/sforge/result.json"


def extract_score(out: str):
    m = re.search(r"TOTAL_SCORE\s+(inf|\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)", out)
    return float(m.group(1)) if m else None


def parse_summary(out: str):
    m = re.search(r"=+\s+([\d\w, ]+)\s+in\s+[\d.]+", out)
    if not m:
        return None
    c = {"passed": 0, "failed": 0, "error": 0}
    for mm in re.finditer(r"(\d+)\s+(\w+)", m.group(1)):
        n, label = int(mm.group(1)), mm.group(2)
        if label in ("passed", "xfailed", "xpassed"):
            c["passed"] += n
        elif label == "failed":
            c["failed"] += n
        elif label in ("error", "errors"):
            c["error"] += n
    return c


def parse_pytest_v(out: str) -> list[dict]:
    pat = re.compile(r"^([\w/.\-\[\]]+(?:::[\w.\-\[\]]+)+)\s+(PASSED|FAILED|ERROR|XFAIL|XPASS|SKIPPED)", re.MULTILINE)
    np_, nf, ne = [], [], []
    for m in pat.finditer(out):
        name, st = m.group(1), m.group(2)
        if st in ("PASSED", "XFAIL", "XPASS"):
            np_.append(name)
        elif st == "FAILED":
            nf.append(name)
        elif st == "SKIPPED":
            continue
        else:
            ne.append(name)
    for m in re.compile(r"^ERROR\s+([\w/.\-]+\.py)(?:\s|$)", re.MULTILINE).finditer(out):
        if m.group(1) not in ne:
            ne.append(m.group(1))
    s = parse_summary(out)
    if s:
        tp, tf, te = s["passed"], s["failed"], s["error"]
    elif np_ or nf or ne:
        tp, tf, te = len(np_), len(nf), len(ne)
    else:
        return [{"name": "unknown", "status": "ERROR"}]
    res = [{"name": n, "status": "PASSED"} for n in np_]
    res += [{"name": n, "status": "FAILED"} for n in nf]
    res += [{"name": n, "status": "ERROR"} for n in ne]
    res += [{"name": f"unnamed_passed_{i + 1}", "status": "PASSED"} for i in range(max(0, tp - len(np_)))]
    res += [{"name": f"unnamed_crashed_{i + 1}", "status": "FAILED"} for i in range(max(0, tf - len(nf)))]
    res += [{"name": f"unnamed_error_{i + 1}", "status": "ERROR"} for i in range(max(0, te - len(ne)))]
    return res


def main() -> None:
    out = open(sys.argv[1], encoding="utf-8", errors="replace").read()
    exit_code = int(sys.argv[2])
    tests = parse_pytest_v(out)
    total = len(tests)
    passed = sum(t["status"] == "PASSED" for t in tests)
    if total:
        summary = f"{passed}/{total} tests passed"
        bad = [t["name"] for t in tests if t["status"] != "PASSED"]
        if bad:
            summary += f". Failed: {', '.join(bad[:10])}"
            if len(bad) > 10:
                summary += f" (+{len(bad) - 10} more)"
    else:
        summary = "No tests found"
    v1_score = extract_score(out)
    ran = tests != [{"name": "unknown", "status": "ERROR"}]
    if v1_score is not None and math.isfinite(v1_score):
        valid, score = True, v1_score
    elif v1_score is None and ran:
        valid, score = True, 0.0
        summary += " (no TOTAL_SCORE: scored 0)"
    else:
        valid, score = False, None
    res = {
        "score": score,
        "valid": valid,
        "summary": summary,
        "details": tests,
        "metrics": {
            "v1_pass_rate": passed / total if total else 0.0,
            "v1_passed": passed,
            "v1_total": total,
            "v1_total_score": v1_score if v1_score is None or math.isfinite(v1_score) else str(v1_score),
            "pytest_exit_code": exit_code,
        },
    }
    with open(RESULT, "w") as f:
        json.dump(res, f)
    print(json.dumps({k: res[k] for k in ("score", "valid", "summary")}))


if __name__ == "__main__":
    main()
