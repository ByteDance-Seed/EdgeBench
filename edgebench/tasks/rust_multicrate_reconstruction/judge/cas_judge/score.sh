#!/usr/bin/env bash
set -euo pipefail

TASK_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE="${1:-${TASK_DIR}/agent-start}"
OUTPUT="${OUTPUT:-${TASK_DIR}/score-results.json}"

if [ ! -d "$WORKSPACE" ]; then
  if [ -d "${TASK_DIR}/skeleton" ]; then
    WORKSPACE="${TASK_DIR}/skeleton"
  else
    echo "SCORE_STATUS=INFRA_FAIL"
    echo "ERROR=workspace not found: ${WORKSPACE}" >&2
    exit 2
  fi
fi

ARGS=("${TASK_DIR}/tools/score.py" --workspace "$WORKSPACE" --output "$OUTPUT")
HAS_HIDDEN_SOURCES=0

if [ -f "${TASK_DIR}/hidden-tests/split-manifest.json" ]; then
  ARGS+=(--manifest "${TASK_DIR}/hidden-tests/split-manifest.json")
fi
if [ -d "${TASK_DIR}/hidden-tests/hidden-sources" ]; then
  ARGS+=(--hidden-source-dir "${TASK_DIR}/hidden-tests/hidden-sources")
  HAS_HIDDEN_SOURCES=1
fi
if [ "$HAS_HIDDEN_SOURCES" -eq 0 ] && [ -d "${TASK_DIR}/repo" ]; then
  ARGS+=(--original-dir "${TASK_DIR}/repo")
fi

if ! python3 "${ARGS[@]}"; then
  echo "SCORE_STATUS=INFRA_FAIL"
  echo "ERROR=scorer execution failed" >&2
  exit 2
fi

set +e
python3 - "$OUTPUT" <<'PY'
import json, sys
path = sys.argv[1]
try:
    with open(path) as f:
        data = json.load(f)
except Exception as exc:
    print("SCORE_STATUS=INFRA_FAIL")
    print(f"ERROR=failed to read score output: {exc}", file=sys.stderr)
    sys.exit(3)
status = data.get('score_status', 'OK')
print(f"RAW_PASSED={data.get('raw_passed', sum(c.get('passed', 0) for c in data.get('crates', [])))}")
print(f"RAW_TOTAL={data.get('raw_total', sum(c.get('total', 0) for c in data.get('crates', [])))}")
print(f"WEIGHTED_PASSED={data.get('weighted_passed', data.get('total_score', 0.0))}")
print(f"WEIGHTED_TOTAL={data.get('weighted_total', data.get('max_score', 100.0))}")
print(f"SCORE={data.get('total_score', 0.0):.4f}")
print(f"SCORE_STATUS={status}")
if status != 'OK':
    for err in data.get('infra_errors', []):
        print(f"INFRA_ERROR={err}", file=sys.stderr)
    sys.exit(2)
PY
scalar_rc=$?
set -e
exit "$scalar_rc"
