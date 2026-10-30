# Copyright (c) 2026 ByteDance Ltd. and/or its affiliates
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Build-time repair of the inspected CTA wrapper; evaluator scoring is retained."""
from __future__ import annotations

import argparse
import hashlib
from pathlib import Path

WRAPPER_SHA256 = '0aa263ba1d42a8c5ac225f9e8174d6b5b401bb0cc706cb9741e65650fe32f680'
EVALUATOR_SHA256 = '252f864a1a515fb48283644268938afd75f417fcfe34bba09fc8bab49cd41300'


def replace_one(text: str, before: str, after: str) -> str:
    if text.count(before) != 1:
        raise ValueError('Unexpected wrapper shape; refusing partial repair')
    return text.replace(before, after, 1)


def repair(wrapper: bytes, evaluator: bytes) -> bytes:
    if hashlib.sha256(wrapper).hexdigest() != WRAPPER_SHA256:
        raise ValueError('Unsupported wrapper revision')
    if hashlib.sha256(evaluator).hexdigest() != EVALUATOR_SHA256:
        raise ValueError('Unsupported evaluator revision')
    text = wrapper.decode('utf-8')
    text = replace_one(text, 'import json\n', 'import json\nimport math\nfrom cta_process import run_evaluator\n\n# Keep headroom below the published 600-second outer judge deadline.\nEVALUATOR_TIMEOUT_SECONDS = 540\n')
    text = replace_one(text, '    _run_agent_entry()\n\n    eval_script =', '    # eval_script executes the task once and retains its compliance checks.\n    eval_script =')
    text = replace_one(text, '    scores = data.get("scores") or {}', '    if not isinstance(data, dict) or not isinstance(data.get("scores"), dict):\n        raise ValueError("Missing score object")\n    scores = data["scores"]\n    if "grand_total" not in scores and "auto_total" not in scores:\n        raise ValueError("Missing total score")')
    text = replace_one(text, '    raw_score = float(scores.get("grand_total", scores.get("auto_total", 0.0)) or 0.0)', '    raw_score = float(scores.get("grand_total", scores.get("auto_total")))')
    text = replace_one(text, '    max_score = float(data.get("total_max_score", 80) or 80)', '    max_score = float(data.get("total_max_score", 80))')
    text = replace_one(text, '    normalized = raw_score / max_score * 100.0 if max_score > 0 else 0.0', '    if not math.isfinite(raw_score) or not math.isfinite(max_score) or max_score <= 0:\n        raise ValueError("Non-finite score or invalid score scale")\n    normalized = raw_score / max_score * 100.0\n    if not math.isfinite(normalized):\n        raise ValueError("Non-finite normalized score")')
    text = replace_one(text, '        raw_score = float(scores.get(key, 0.0) or 0.0)', '        raw_score = float(scores.get(key, 0.0) or 0.0)\n        if not math.isfinite(raw_score) or (max_score and not math.isfinite(raw_score / max_score * 100.0)):\n            raise ValueError("Non-finite dimension score")')
    text = replace_one(text, 'def _emit_structured_result(valid: bool, score: float, results: dict | None = None) -> None:', 'def _emit_structured_result(valid: bool, score: float, results: dict | None = None, *, failure_reason: str | None = None) -> None:')
    text = replace_one(text, '    payload_text = json.dumps(payload,', '    if failure_reason:\n        payload["summary"] = "Evaluation failed: " + failure_reason\n        payload["details"] = [{"name": failure_reason, "status": "ERROR", "message": payload["summary"]}]\n        payload["errors"] = 1\n        payload["failed"] = 0\n    payload_text = json.dumps(payload,')
    before = '''        proc = subprocess.run(
            cmd,
            cwd=str(WORKSPACE),
            text=True,
            capture_output=True,
            timeout=600,
        )
    except subprocess.TimeoutExpired:
        print("TOTAL_SCORE 0")
        print("FEEDBACK: evaluator timed out after 600s")
        _emit_structured_result(False, 0.0)
'''
    after = '''        RESULTS_JSON.unlink(missing_ok=True)
        proc = run_evaluator(cmd, cwd=str(WORKSPACE), timeout=EVALUATOR_TIMEOUT_SECONDS)
    except subprocess.TimeoutExpired as exc:
        if exc.output:
            print(exc.output)
        if exc.stderr:
            print(exc.stderr)
        print("TOTAL_SCORE 0")
        print(f"FEEDBACK: evaluator timed out after {EVALUATOR_TIMEOUT_SECONDS}s")
        _emit_structured_result(False, 0.0, failure_reason="evaluator_timeout")
'''
    text = replace_one(text, before, after)
    text = replace_one(text, '        print(f"FEEDBACK: evaluator launch failed: {exc}")\n        _emit_structured_result(False, 0.0)', '        print(f"FEEDBACK: evaluator launch failed: {exc}")\n        _emit_structured_result(False, 0.0, failure_reason="evaluator_launch")')
    text = replace_one(text, '    score, feedback, results = _load_score()', '''    try:
        score, feedback, results = _load_score()
        _build_metrics(results)
    except (ValueError, TypeError, AttributeError, OverflowError) as exc:
        print("TOTAL_SCORE 0")
        print(f"FEEDBACK: invalid evaluator result: {exc}")
        _emit_structured_result(False, 0.0, failure_reason="invalid_result")
        return 0''')
    text = replace_one(text, '    _emit_structured_result(proc.returncode == 0 and results is not None, score, results)', '''    failure = ("evaluator_exit" if proc.returncode != 0 else
               "invalid_result" if results is None and RESULTS_JSON.exists() else
               "missing_result" if results is None else None)
    _emit_structured_result(failure is None, score, results, failure_reason=failure)''')
    compile(text, '<repaired CTA wrapper>', 'exec')
    return text.encode('utf-8')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('wrapper', type=Path)
    parser.add_argument('evaluator', type=Path)
    parser.add_argument('destination', type=Path)
    args = parser.parse_args()
    result = repair(args.wrapper.read_bytes(), args.evaluator.read_bytes())
    with args.destination.open('xb') as output:
        output.write(result)
