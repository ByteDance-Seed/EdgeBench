#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

MODE="${CAS_BENCH_MODE:-quick}" # quick|full
OUT_MD="${1:-history/build-benchmark-latest.md}"
OUT_ENV="${2:-history/build-benchmark-latest.env}"

mkdir -p "$(dirname "$OUT_MD")"

timestamp() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

measure() {
  local key="$1"
  shift
  local start end elapsed
  start="$(date +%s)"
  "$@"
  end="$(date +%s)"
  elapsed=$((end - start))
  echo "${key}=${elapsed}" >> "$OUT_ENV"
}

{
  echo "timestamp=$(timestamp)"
  echo "mode=${MODE}"
  echo "rustc=$(rustc --version | tr ' ' '_')"
  echo "cargo=$(cargo --version | tr ' ' '_')"
} > "$OUT_ENV"

echo "[build-bench] mode=${MODE}"

# Quick loop: clean + incremental + fast release.
cargo clean
measure clean_debug_minimal cargo build -p cas --no-default-features
measure incr_debug_minimal cargo build -p cas --no-default-features
measure release_fast cargo build -p cas --profile release-fast

if [[ "$MODE" == "full" ]]; then
  cargo clean
  measure clean_debug_all_features cargo build -p cas --all-features
  measure test_norun_all_features cargo test -p cas --all-features --no-run
  measure release_full cargo build -p cas --release
fi

{
  echo "# Build Benchmark (Latest)"
  echo
  echo "- Timestamp: $(grep '^timestamp=' "$OUT_ENV" | cut -d= -f2-)"
  echo "- Mode: $(grep '^mode=' "$OUT_ENV" | cut -d= -f2-)"
  echo "- rustc: $(grep '^rustc=' "$OUT_ENV" | cut -d= -f2- | tr '_' ' ')"
  echo "- cargo: $(grep '^cargo=' "$OUT_ENV" | cut -d= -f2- | tr '_' ' ')"
  echo
  echo "| Metric | Seconds |"
  echo "|---|---:|"
  grep -E '^(clean_debug_minimal|incr_debug_minimal|release_fast|clean_debug_all_features|test_norun_all_features|release_full)=' "$OUT_ENV" \
    | while IFS='=' read -r k v; do
        echo "| \`$k\` | $v |"
      done
} > "$OUT_MD"

echo "[build-bench] wrote $OUT_MD and $OUT_ENV"
