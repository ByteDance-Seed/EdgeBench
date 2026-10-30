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

"""Exercise the actual image wrapper with synthetic evaluator boundary fixtures."""
from __future__ import annotations

import contextlib
import importlib.util
import io
import json
import os
import sys
import tempfile
import time
import unittest
from pathlib import Path

SOURCE = Path(sys.argv.pop(1)).resolve()
sys.path.insert(0, str(SOURCE.parent))


def alive(pid: int) -> bool:
    try:
        # A zombie has exited and cannot continue scoring or retain a pipe.
        return Path(f'/proc/{pid}/stat').read_text().rsplit(')', 1)[1].split()[0] != 'Z'
    except (FileNotFoundError, ProcessLookupError):
        return False


class WrapperContract(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory(prefix='cta-contract-')
        self.root = Path(self.temp.name)
        self.scoring = self.root / 'scoring'
        self.scoring.mkdir()
        spec = importlib.util.spec_from_file_location('cta_wrapper_under_test', SOURCE)
        self.wrapper = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.wrapper)
        self.wrapper.WORKSPACE = self.root
        self.wrapper.SCORING_DIR = self.scoring
        self.wrapper.SUBMISSION_DIR = self.root
        self.wrapper.DATA_DIR = self.root / 'input'
        self.wrapper.RESULTS_JSON = self.root / 'eval_results.json'
        self.wrapper.EVALUATOR_TIMEOUT_SECONDS = 0.5
        self.child_ids = []

    def tearDown(self) -> None:
        # Test-owned processes only; catch cleanup regressions without leaking.
        for name in ('evaluator.pid', 'child.pid'):
            p = self.root / name
            if p.exists():
                pid = int(p.read_text())
                if alive(pid):
                    try:
                        os.kill(pid, 9)
                    except ProcessLookupError:
                        pass
        self.temp.cleanup()

    def evaluate(self, code: str) -> tuple[dict, str]:
        (self.scoring / 'eval_script.py').write_text(code)
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            rc = self.wrapper.main()
        self.assertEqual(rc, 0)
        text = output.getvalue()
        self.assertIn('>>>>> Start Structured Result\n', text)
        payload = text.split('>>>>> Start Structured Result\n', 1)[1].split('\n>>>>> End Structured Result', 1)[0]
        return json.loads(payload), text

    def test_task_entry_executes_once(self):
        (self.root / 'run.py').write_text("from pathlib import Path\np=Path('executions');p.write_text(p.read_text()+'x' if p.exists() else 'x')\n")
        result, _ = self.evaluate("import subprocess,sys,json\nfrom pathlib import Path\nsubprocess.run([sys.executable,'run.py'],check=True)\nPath('eval_results.json').write_text(json.dumps({'scores':{'grand_total':50},'total_max_score':80}))\n")
        self.assertEqual((self.root / 'executions').read_text(), 'x')
        self.assertTrue(result['valid'])
        self.assertEqual(result['score'], 62.5)

    def test_valid_zero_is_not_failure(self):
        result, _ = self.evaluate("from pathlib import Path\nPath('eval_results.json').write_text('{\"scores\":{\"grand_total\":0},\"total_max_score\":80}')\n")
        self.assertTrue(result['valid'])
        self.assertEqual(result['score'], 0)

    def test_missing_result_is_typed_failure(self):
        result, _ = self.evaluate('pass\n')
        self.assertFalse(result['valid'])
        self.assertEqual(result['details'][0]['name'], 'missing_result')

    def test_malformed_numeric_result_is_typed_failure(self):
        result, _ = self.evaluate("from pathlib import Path\nPath('eval_results.json').write_text('{\"scores\":{\"grand_total\":\"broken\"}}')\n")
        self.assertFalse(result['valid'])
        self.assertEqual(result['details'][0]['name'], 'invalid_result')

    def test_nonfinite_scores_are_not_valid(self):
        for raw in ('NaN', 'Infinity', '-Infinity'):
            with self.subTest(raw=raw):
                result, _ = self.evaluate("from pathlib import Path\nPath('eval_results.json').write_text(" + repr('{"scores":{"grand_total":' + raw + '}}') + ')\n')
                self.assertFalse(result['valid'])
                self.assertEqual(result['details'][0]['name'], 'invalid_result')

    def test_missing_score_schema_is_not_valid_zero(self):
        for data in ('{}', '{"scores":{}}', '{"scores":[]}'):
            with self.subTest(data=data):
                result, _ = self.evaluate("from pathlib import Path\nPath('eval_results.json').write_text(" + repr(data) + ')\n')
                self.assertFalse(result['valid'])
                self.assertEqual(result['details'][0]['name'], 'invalid_result')

    def test_malformed_dimension_is_typed_failure(self):
        for value in ('"broken"', 'NaN'):
            with self.subTest(value=value):
                data = '{"scores":{"grand_total":50,"backtest_verification":' + value + '}}'
                result, _ = self.evaluate("from pathlib import Path\nPath('eval_results.json').write_text(" + repr(data) + ')\n')
                self.assertFalse(result['valid'])
                self.assertEqual(result['details'][0]['name'], 'invalid_result')

    def test_null_total_and_invalid_scale_are_not_valid(self):
        for data in ('{"scores":{"grand_total":null}}',
                     '{"scores":{"grand_total":50},"total_max_score":0}',
                     '{"scores":{"grand_total":50},"total_max_score":null}'):
            with self.subTest(data=data):
                result, _ = self.evaluate("from pathlib import Path\nPath('eval_results.json').write_text(" + repr(data) + ')\n')
                self.assertFalse(result['valid'])
                self.assertEqual(result['details'][0]['name'], 'invalid_result')

    def test_dimension_normalization_overflow_is_not_valid(self):
        result, _ = self.evaluate("from pathlib import Path\nPath('eval_results.json').write_text('{\"scores\":{\"grand_total\":50,\"backtest_verification\":1e308}}')\n")
        self.assertFalse(result['valid'])
        self.assertEqual(result['details'][0]['name'], 'invalid_result')

    def test_total_normalization_overflow_is_not_valid(self):
        for total, scale in ((1e308, 0.1), (-1e308, 0.1), (50, 5e-324)):
            with self.subTest(total=total, scale=scale):
                data = json.dumps({'scores': {'grand_total': total}, 'total_max_score': scale})
                result, _ = self.evaluate("from pathlib import Path\nPath('eval_results.json').write_text(" + repr(data) + ')\n')
                self.assertFalse(result['valid'])
                self.assertEqual(result['details'][0]['name'], 'invalid_result')

    def test_finite_total_clipping_is_preserved(self):
        for total, expected in ((100, 100), (-10, 0)):
            with self.subTest(total=total):
                data = json.dumps({'scores': {'grand_total': total}, 'total_max_score': 80})
                result, _ = self.evaluate("from pathlib import Path\nPath('eval_results.json').write_text(" + repr(data) + ')\n')
                self.assertTrue(result['valid'])
                self.assertEqual(result['score'], expected)

    def test_stale_result_is_not_reused(self):
        (self.root / 'eval_results.json').write_text('{"scores":{"grand_total":80}}')
        result, _ = self.evaluate('raise SystemExit(5)\n')
        self.assertFalse(result['valid'])
        self.assertEqual(result['score'], 0)
        self.assertEqual(result['details'][0]['name'], 'evaluator_exit')
        self.assertFalse((self.root / 'eval_results.json').exists())

    def test_evaluator_timeout_cleans_descendants_and_reports(self):
        code = """import os,subprocess,sys,time
from pathlib import Path
Path('evaluator.pid').write_text(str(os.getpid()))
p=subprocess.Popen([sys.executable,'-c','import time; time.sleep(60)'])
Path('child.pid').write_text(str(p.pid))
print('partial evaluator output',flush=True)
time.sleep(60)
"""
        started = time.monotonic()
        result, text = self.evaluate(code)
        self.assertLess(time.monotonic() - started, 4)
        self.assertFalse(result['valid'])
        self.assertEqual(result['details'][0]['name'], 'evaluator_timeout')
        self.assertIn('partial evaluator output', text)
        for name in ('evaluator.pid', 'child.pid'):
            pid = int((self.root / name).read_text())
            for _ in range(20):
                if not alive(pid):
                    break
                time.sleep(0.01)
            self.assertFalse(alive(pid), name)

    def test_completed_evaluator_cleans_background_descendants(self):
        result, _ = self.evaluate("""import subprocess,sys
from pathlib import Path
p=subprocess.Popen([sys.executable,'-c','import time; time.sleep(60)'])
Path('child.pid').write_text(str(p.pid))
Path('eval_results.json').write_text('{"scores":{"grand_total":50},"total_max_score":80}')
""")
        self.assertTrue(result['valid'])
        pid = int((self.root / 'child.pid').read_text())
        for _ in range(20):
            if not alive(pid):
                break
            time.sleep(0.01)
        self.assertFalse(alive(pid))


if __name__ == '__main__':
    unittest.main()
