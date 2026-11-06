#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

BASELINE="${1:-history/build-benchmark-baseline.env}"
LATEST="${2:-history/build-benchmark-latest.env}"
MAX_PCT="${MAX_REGRESSION_PCT:-25}"

if [[ ! -f "$LATEST" ]]; then
  echo "[build-regression] latest file missing: $LATEST"
  exit 1
fi

if [[ ! -f "$BASELINE" ]]; then
  echo "[build-regression] baseline missing ($BASELINE), skipping regression check."
  exit 0
fi

get_value() {
  local file="$1"
  local key="$2"
  awk -F= -v k="$key" '$1==k {print $2}' "$file" | tail -n 1
}

check_metric() {
  local metric="$1"
  local b l limit
  b="$(get_value "$BASELINE" "$metric")"
  l="$(get_value "$LATEST" "$metric")"
  if [[ -z "$b" || -z "$l" ]]; then
    echo "[build-regression] metric missing, skipping: $metric"
    return 0
  fi

  limit=$(( b + (b * MAX_PCT / 100) ))
  if (( l > limit )); then
    echo "[build-regression] FAIL $metric baseline=${b}s latest=${l}s allowed=${limit}s (${MAX_PCT}% max)"
    return 1
  fi
  echo "[build-regression] OK   $metric baseline=${b}s latest=${l}s allowed=${limit}s"
}

rc=0
check_metric clean_debug_minimal || rc=1
check_metric incr_debug_minimal || rc=1
check_metric release_fast || rc=1

exit "$rc"
