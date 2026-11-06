#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python3 "$ROOT/tools/check_environment.py"
bash "$ROOT/score.sh" >/tmp/juliet-v3-public-score.log
grep -q 'SCORE_STATUS=OK' /tmp/juliet-v3-public-score.log
ROOT_ENV="$ROOT" python3 - <<'PY'
import json, pathlib, os
root=pathlib.Path(os.environ['ROOT_ENV'])
facts=[json.loads(l) for l in (root/'data/public/facts.jsonl').read_text().splitlines() if l.strip()]
labels=[json.loads(l) for l in (root/'data/public/labels.jsonl').read_text().splitlines() if l.strip()]
assert len(labels) >= 150, len(labels)
assert facts, 'missing facts'
forbidden=['hidden','evaluator-hidden','reference_analyzer','manifest.xml','goodB2G','goodG2B']
public_text='\n'.join((root/p).read_text(errors='ignore') for p in ['README.md','problem.md','task.yaml'])
assert 'manifest.xml' not in public_text
print('VERIFY_TASK_OK public_cases=%d public_labels=%d' % (len(facts), len(labels)))
PY
