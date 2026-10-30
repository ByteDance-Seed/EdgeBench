#!/usr/bin/env python3
"""Grade the output of /judge/eval.sh exactly like v1 SForge did for this task.

v1: parser `pytest_v` (sforge/harness/log_parsers/pytest_v.py) via _grade_legacy, raw score =
extract_score() = the FIRST `TOTAL_SCORE <n>` anywhere in the test output (sforge/harness/grading.py).
The test output is the text between the START/END markers (extract_test_output); in this task
the END marker is never printed (see NOTES.md, Known issue 2), so it is the whole output.

Usage: grade.py <eval output file> <result.json path>
"""
import json
import re
import sys

START, END = ">>>>> Start Test Output", ">>>>> End Test Output"


def extract_test_output(raw: str) -> str:
    start_idx, found = raw.find("\n" + START), False
    if start_idx != -1:
        start_idx += 1
        found = True
    elif raw.startswith(START):
        start_idx, found = 0, True
    end_idx = raw.rfind("\n" + END)
    if found and end_idx != -1 and end_idx > start_idx:
        return raw[start_idx + len(START):end_idx].strip()
    return raw


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
    pat = re.compile(r"^([\w/.\-\[\]]+(?:::[\w.\-\[\]]+)+)\s+(PASSED|FAILED|ERROR|XFAIL|XPASS|SKIPPED)", re.M)
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
    for m in re.finditer(r"^ERROR\s+([\w/.\-]+\.py)(?:\s|$)", out, re.M):
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


def main() -> int:
    raw = open(sys.argv[1], encoding="utf-8", errors="replace").read()
    out = extract_test_output(raw)
    tests = parse_pytest_v(out)
    total = len(tests)
    passed = sum(1 for t in tests if t["status"] == "PASSED")
    summary = f"{passed}/{total} tests passed"
    bad = [t["name"] for t in tests if t["status"] != "PASSED"]
    if bad:
        summary += f". Failed: {', '.join(bad[:10])}"
        if len(bad) > 10:
            summary += f" (+{len(bad) - 10} more)"
    m = re.search(r"TOTAL_SCORE\s+(inf|\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)", out)
    score = float(m.group(1)) if m else None
    metrics = {}
    r = re.search(r"Correctness: (\d+)/(\d+) workloads passed", out)
    if r:
        metrics["correctness_passed"], metrics["correctness_total"] = int(r.group(1)), int(r.group(2))
    g = re.search(r"Geometric mean speedup: ([\d.]+)x", out)
    if g:
        metrics["geometric_mean_speedup"] = float(g.group(1))
    result = {"score": score, "valid": score is not None, "summary": summary,
              "details": tests, "metrics": metrics}
    with open(sys.argv[2], "w") as f:
        json.dump(result, f, indent=1)
    print(json.dumps({k: v for k, v in result.items() if k != "details"}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
