#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python3 "$ROOT/scoring/score.py" \
  --facts "$ROOT/data/public/facts.jsonl" \
  --labels "$ROOT/data/public/labels.jsonl" \
  --analyzer "$ROOT/agent-start/analyzer.py" \
  --submission-root "$ROOT/agent-start"
