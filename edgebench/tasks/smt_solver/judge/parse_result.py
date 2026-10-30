# v1's /tmp/sebench_parse_result.py (heredoc in judge.eval_cmd), verbatim except that the
# score file path comes from argv[1] instead of the fixed /tmp/smt_hidden_score.json.
import json, pathlib, sys
p = pathlib.Path(sys.argv[1])
raw = json.loads(p.read_text()) if p.exists() else {'final_score': 0.0, 'logic_summary': {}}
raw_score = float(raw.get('final_score', 0.0) or 0.0)
score = raw_score / 100.0 if raw_score > 1.0 else raw_score
by = raw.get('logic_summary', {}) or {}
def clean(g):
    out = {}
    for k, item in sorted(g.items()):
        t = int(item.get('total', 0) or 0); c = int(item.get('correct', 0) or 0)
        out[k] = {'total': t, 'correct': c, 'wrong': int(item.get('wrong', max(0, t-c)) or 0), 'timeout': int(item.get('timeout', 0) or 0), 'unknown': int(item.get('unknown', 0) or 0), 'error': int(item.get('error', 0) or 0), 'no_reference': int(item.get('no_reference', 0) or 0), 'invalid_model': int(item.get('invalid_model', 0) or 0), 'score': float(item.get('score', 0.0) or 0.0)}
    return out
by = clean(by)
total = sum(v['total'] for v in by.values()); correct = sum(v['correct'] for v in by.values())
wrong = max(0, total - correct)
result = {'valid': True, 'score': score, 'pass_rate': correct/total if total else 0.0, 'total_tests': total, 'passed': correct, 'failed': wrong, 'errors': 0, 'summary': 'score={:.6f} ({:.2f}/100), correct={}/{}'.format(score, 100*score, correct, total), 'details': [], 'metrics': {'score': score, 'score_percent': 100*score, 'total': total, 'correct': correct, 'wrong_or_failed': wrong, 'by_logic': by}}
print('>>>>> Start Structured Result')
print(json.dumps(result, ensure_ascii=False))
print('>>>>> End Structured Result')
