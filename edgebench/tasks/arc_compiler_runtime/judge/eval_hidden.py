import json
import re
import subprocess

proc = subprocess.run(['bash', 'evaluator-hidden/score_hidden.sh', 'agent-start'], text=True, capture_output=True, timeout=1400)
output = (proc.stdout or '') + (proc.stderr or '')
print(output, end='')
score_match = re.search(r'^SCORE=([-+]?\d+(?:\.\d+)?)$', output, re.MULTILINE)
raw_passed_match = re.search(r'^RAW_PASSED=(\d+)$', output, re.MULTILINE)
raw_total_match = re.search(r'^RAW_TOTAL=(\d+)$', output, re.MULTILINE)
weighted_passed_match = re.search(r'^WEIGHTED_PASSED=(\d+)$', output, re.MULTILINE)
weighted_total_match = re.search(r'^WEIGHTED_TOTAL=(\d+)$', output, re.MULTILINE)
score = float(score_match.group(1)) if score_match else 0.0
raw_passed = int(raw_passed_match.group(1)) if raw_passed_match else 0
raw_total = int(raw_total_match.group(1)) if raw_total_match else 1
weighted_passed = int(weighted_passed_match.group(1)) if weighted_passed_match else 0
weighted_total = int(weighted_total_match.group(1)) if weighted_total_match else 1
valid = proc.returncode == 0 and score_match is not None
pass_rate = (raw_passed / raw_total) if raw_total else 0.0
print('>>>>> Start Structured Result')
print(json.dumps({
    'valid': valid,
    'score': score,
    'pass_rate': pass_rate if valid else 0.0,
    'total_tests': raw_total,
    'passed': raw_passed if valid else 0,
    'failed': max(raw_total - raw_passed, 0) if valid else raw_total,
    'errors': 0 if valid else 1,
    'summary': 'Score: {:.2f}, raw: {}/{}, weighted: {}/{}'.format(score, raw_passed, raw_total, weighted_passed, weighted_total),
    'details': [{
        'name': 'hidden_score',
        'status': 'PASSED' if valid and score > 0.0 else 'FAILED',
        'score': score,
        'message': output[-2000:]
    }],
    'metrics': {
        'score': score,
        'raw_passed': raw_passed,
        'raw_total': raw_total,
        'weighted_passed': weighted_passed,
        'weighted_total': weighted_total,
        'runner_returncode': proc.returncode
    }
}, ensure_ascii=False))
print('>>>>> End Structured Result')
