#!/usr/bin/env python3
"""Grade the v1 eval output (stdin) and write /opt/sforge/result.json.

Reproduces how v1 scored this task:
  * raw score = first `TOTAL_SCORE <n>` in the eval output (sforge/harness/grading.py:extract_score).
    pytest_shim.sh prints it as `TOTAL_SCORE {score:.6f}`, where score is compute_reward.py's
    round(total_passed / 29075, 6).
  * summary/details = parser `pytest_v` (sforge/harness/log_parsers/pytest_v.py) + _grade_legacy,
    copied below. They are informational only.
  * v1 had valid=True with score=None when no TOTAL_SCORE was printed (unrankable); here that
    is valid=false.
stdin is echoed to stdout unchanged (logs).
"""
import json
import os
import re
import sys

PASSED, FAILED, ERROR = "PASSED", "FAILED", "ERROR"


# ---- sforge/harness/grading.py:extract_score (verbatim) ----
def extract_score(test_output):
    m = re.search(r"TOTAL_SCORE\s+(inf|\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)", test_output)
    return float(m.group(1)) if m else None


# ---- sforge/harness/log_parsers/pytest_v.py (logic verbatim, docstrings dropped) ----
def _parse_summary(test_output):
    summary_match = re.search(r"=+\s+([\d\w, ]+)\s+in\s+[\d.]+", test_output)
    if not summary_match:
        return None
    summary_text = summary_match.group(1)
    counts = {"passed": 0, "failed": 0, "error": 0}
    for m in re.finditer(r"(\d+)\s+(\w+)", summary_text):
        count = int(m.group(1))
        label = m.group(2)
        if label in ("passed", "xfailed", "xpassed"):
            counts["passed"] += count
        elif label == "failed":
            counts["failed"] += count
        elif label in ("error", "errors"):
            counts["error"] += count
    return counts


def parse_pytest_v(test_output):
    results = []
    pattern = re.compile(
        r"^([\w/.\-\[\]]+(?:::[\w.\-\[\]]+)+)\s+(PASSED|FAILED|ERROR|XFAIL|XPASS|SKIPPED)",
        re.MULTILINE,
    )
    named_passed, named_failed, named_error = [], [], []
    for match in pattern.finditer(test_output):
        name = match.group(1)
        raw_status = match.group(2)
        if raw_status in ("PASSED", "XFAIL", "XPASS"):
            named_passed.append(name)
        elif raw_status == "FAILED":
            named_failed.append(name)
        elif raw_status == "SKIPPED":
            continue
        else:
            named_error.append(name)
    collection_pattern = re.compile(r"^ERROR\s+([\w/.\-]+\.py)(?:\s|$)", re.MULTILINE)
    for match in collection_pattern.finditer(test_output):
        name = match.group(1)
        if name not in named_error:
            named_error.append(name)
    summary = _parse_summary(test_output)
    if summary:
        total_passed, total_failed, total_error = summary["passed"], summary["failed"], summary["error"]
    elif named_passed or named_failed or named_error:
        total_passed, total_failed, total_error = len(named_passed), len(named_failed), len(named_error)
    else:
        return [{"name": "unknown", "status": ERROR}]
    for name in named_passed:
        results.append({"name": name, "status": PASSED})
    for name in named_failed:
        results.append({"name": name, "status": FAILED})
    for name in named_error:
        results.append({"name": name, "status": ERROR})
    for i in range(max(0, total_passed - len(named_passed))):
        results.append({"name": f"unnamed_passed_{i + 1}", "status": PASSED})
    for i in range(max(0, total_failed - len(named_failed))):
        results.append({"name": f"unnamed_crashed_{i + 1}", "status": FAILED})
    for i in range(max(0, total_error - len(named_error))):
        results.append({"name": f"unnamed_error_{i + 1}", "status": ERROR})
    return results


def main():
    chunks = []
    for line in sys.stdin.buffer:
        sys.stdout.buffer.write(line)
        sys.stdout.buffer.flush()
        chunks.append(line)
    output = b"".join(chunks).decode("utf-8", errors="replace")

    tests = parse_pytest_v(output)
    total = len(tests)
    passed = sum(1 for t in tests if t["status"] == PASSED)
    # _grade_legacy summary
    if total > 0:
        summary = f"{passed}/{total} tests passed"
        failed_names = [t["name"] for t in tests if t["status"] != PASSED]
        if failed_names:
            summary += f". Failed: {', '.join(failed_names[:10])}"
            if len(failed_names) > 10:
                summary += f" (+{len(failed_names) - 10} more)"
    else:
        summary = "No tests found"

    score = extract_score(output)
    metrics = {"pass_rate": passed / total if total else 0.0}
    try:
        with open("/logs/verifier/reward.json") as f:
            reward = json.load(f)
        for k in ("total_passed", "total_failed", "total_skipped", "total_attempted",
                  "scripts_run", "reason", "subscores"):
            if k in reward:
                metrics[k] = reward[k]
    except Exception as e:  # informational only
        metrics["reward_json_error"] = str(e)

    result = {
        "score": score,
        "valid": score is not None,
        "summary": summary if score is not None else summary + ". No TOTAL_SCORE in eval output",
        "details": [{"name": t["name"], "status": t["status"]} for t in tests],
        "metrics": metrics,
    }
    os.makedirs("/opt/sforge", exist_ok=True)
    tmp = "/opt/sforge/result.json.tmp"
    with open(tmp, "w") as f:
        json.dump(result, f, indent=2)
    os.replace(tmp, "/opt/sforge/result.json")
    print(f"--- result.json: score={score} valid={score is not None} summary={result['summary']}")


if __name__ == "__main__":
    main()
