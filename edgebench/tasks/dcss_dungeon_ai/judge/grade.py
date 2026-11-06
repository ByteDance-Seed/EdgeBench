#!/usr/bin/env python3
"""Grader for dcss_dungeon_ai (Verified judge contract, see SCHEMA.md).

Reproduces v1 exactly:
  v1 eval_cmd : python3 /tmp/eval_dcss.py   (run with workdir = /home/dcss_agent)
  v1 parser   : structured_json  (sforge/harness/log_parsers/structured_json.py)
  v1 grading  : sforge/harness/grading.py:_grade_structured (score from the JSON block, else the
                first `TOTAL_SCORE <n>`; valid from the JSON block, default true)
/judge/eval_dcss.py is byte-identical to the v1 /tmp/eval_dcss.py.
This wrapper only runs it and translates its stdout into /opt/sforge/result.json.
stdout = logs only.
"""
import json
import os
import re
import subprocess
import sys
import tempfile

CWD = "/home/dcss_agent"
EVAL_CMD = "python3 /judge/eval_dcss.py"
RESULT_DIR = "/opt/sforge"
RESULT = os.path.join(RESULT_DIR, "result.json")


# --- v1 sforge/harness/log_parsers/structured_json.py, verbatim logic -----------------------
def parse_structured_json(output: str) -> dict:
    marker_start = ">>>>> Start Structured Result"
    marker_end = ">>>>> End Structured Result"
    si = output.find(marker_start)
    ei = output.find(marker_end)
    if si != -1 and ei != -1:
        block = output[si + len(marker_start):ei].strip()
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


# --- v1 sforge/harness/grading.py:extract_score, verbatim regex ---------------------------
def extract_score(test_output: str):
    m = re.search(r"TOTAL_SCORE\s+(inf|\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)", test_output)
    return float(m.group(1)) if m else None


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
    print(f"eval_dcss.py exit code: {proc.returncode}")

    # v1 _grade_structured
    data = parse_structured_json(out)
    raw_details = data.get("details", []) or []
    details = [{"name": d.get("name", ""), "status": d.get("status", ""), "score": d.get("score"),
                "message": d.get("message")} for d in raw_details]
    if raw_details:
        passed = sum(1 for d in raw_details if d.get("status") == "PASSED")
        total = len(raw_details)
    else:
        passed, total = data.get("passed", 0), data.get("total_tests", 0)
    pass_rate = data.get("pass_rate")
    if pass_rate is None:
        pass_rate = passed / total if total > 0 else 0.0

    score = data.get("score")
    if score is None:
        score = extract_score(out)
    valid = bool(data.get("valid", True))
    summary = data.get("summary")
    if summary is None:
        summary = "No structured result in eval output"
    if score is None or score == float("inf"):
        # v1: score None -> unrankable. The Verified contract expresses that as valid=false.
        score, valid = None, False
        summary += "; no score in eval output"

    metrics = dict(data.get("metrics", {}) or {})
    metrics.update({"v1_pass_rate": pass_rate, "v1_passed": passed, "v1_total": total,
                    "eval_exit_code": proc.returncode})
    result = {"score": score, "valid": valid, "summary": summary, "details": details,
              "metrics": metrics}
    tmp = RESULT + ".tmp"
    with open(tmp, "w") as f:
        json.dump(result, f)
    os.replace(tmp, RESULT)
    print("--- result.json ---")
    print(json.dumps(result)[:600])
    return 0


if __name__ == "__main__":
    sys.exit(main())
