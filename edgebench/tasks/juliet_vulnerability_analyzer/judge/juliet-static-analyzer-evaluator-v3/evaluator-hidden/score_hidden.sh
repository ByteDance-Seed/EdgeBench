#!/usr/bin/env bash
set -euo pipefail
if [[ $# -lt 1 ]]; then
  echo "usage: $0 <submission-root-or-agent-start>" >&2
  exit 2
fi
EVAL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SUB="$1"
if [[ -f "$SUB/analyzer.py" ]]; then
  ANALYZER="$SUB/analyzer.py"
  SUBROOT="$SUB"
elif [[ -f "$SUB/agent-start/analyzer.py" ]]; then
  ANALYZER="$SUB/agent-start/analyzer.py"
  SUBROOT="$SUB/agent-start"
else
  echo "INFRA_FAIL: analyzer.py not found in $SUB" >&2
  exit 2
fi
python3 "$EVAL_ROOT/scoring/score.py" \
  --facts "$EVAL_ROOT/data/hidden/facts.jsonl" \
  --labels "$EVAL_ROOT/data/hidden/labels.jsonl" \
  --analyzer "$ANALYZER" \
  --submission-root "$SUBROOT"
