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

"""Pass actual wrapper output through a caller-selected SForge parser checkout."""
from __future__ import annotations

import json
import runpy
import sys
from pathlib import Path

source, parser_source, receipt = map(Path, sys.argv[1:])
sys.path.insert(0, str(parser_source))
from sforge.harness.grading import grade_output
from sforge.harness.task_spec import JudgeSpec, TaskSpec, WorkSpec

sys.argv = ['verify.py', str(source)]
fixtures = runpy.run_path(str(Path(__file__).with_name('verify.py')), run_name='fixtures')
spec = TaskSpec('synthetic_cta', 'Synthetic CTA', 'python', 'linux/amd64', '/tmp', [], [],
                WorkSpec('', ''), JudgeSpec('', 600, 'structured_json'))
rows = []
for name, code, valid, reason in [
    ('valid_zero', "from pathlib import Path\nPath('eval_results.json').write_text('{\"scores\":{\"grand_total\":0}}')\n", True, None),
    ('missing', 'pass\n', False, 'missing_result'),
    ('malformed', "from pathlib import Path\nPath('eval_results.json').write_text('{}')\n", False, 'invalid_result'),
    ('dimension_overflow', "from pathlib import Path\nPath('eval_results.json').write_text('{\"scores\":{\"grand_total\":50,\"backtest_verification\":1e308}}')\n", False, 'invalid_result'),
    ('total_overflow', "from pathlib import Path\nPath('eval_results.json').write_text('{\"scores\":{\"grand_total\":1e308},\"total_max_score\":0.1}')\n", False, 'invalid_result'),
    ('exit', 'raise SystemExit(3)\n', False, 'evaluator_exit'),
    ('timeout', 'import time\ntime.sleep(60)\n', False, 'evaluator_timeout'),
]:
    case = fixtures['WrapperContract']()
    case.setUp()
    try:
        payload, text = case.evaluate(code)
        report = grade_output(spec, text, 'synthetic-' + name)
        assert report.valid is valid
        assert report.score == 0
        if reason:
            assert report.details[0].name == reason
            assert report.errors == 1
            assert reason in report.summary
        rows.append({'case': name, 'ok': True, 'valid': report.valid,
                     'score': report.score, 'errors': report.errors, 'summary': report.summary})
    except Exception as exc:  # noqa: BLE001 - retain each failing fixture in the receipt
        rows.append({'case': name, 'ok': False, 'error': type(exc).__name__ + ': ' + str(exc)})
    finally:
        case.tearDown()
result = {'ok': all(row['ok'] for row in rows), 'parser_source': str(parser_source), 'rows': rows}
receipt.write_text(json.dumps(result, indent=2) + '\n')
print(json.dumps(result, indent=2))
raise SystemExit(0 if result['ok'] else 1)
