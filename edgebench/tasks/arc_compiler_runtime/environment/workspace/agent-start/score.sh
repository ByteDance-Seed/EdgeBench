#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

EXPECTED_DENOMINATOR=48
EXPECTED_WEIGHTED_DENOMINATOR=48
PER_TEST_TIMEOUT="${PER_TEST_TIMEOUT:-60}"

fail_infra() {
  echo "INFRASTRUCTURE_ERROR: $*" >&2
  echo "SCORE_STATUS=INFRA_FAIL"
  exit 70
}
warn() { echo "  [WARN] $*" >&2; }

run_limited() {
  local seconds="$1"; shift
  if command -v timeout >/dev/null 2>&1; then
    timeout "$seconds" "$@"
  else
    if [ "${REQUIRE_TIMEOUT:-0}" = "1" ]; then fail_infra "timeout command is required in the evaluation container"; fi
    "$@"
  fi
}

TEST_SPECS=(
  "public-smoke/smoke-lexer-parser:8:1:lexer/parser"
  "public-smoke/smoke-interpreter:8:1:interpreter"
  "public-smoke/smoke-stdlib:8:1:stdlib"
  "public-smoke/smoke-codegen:8:1:codegen"
  "public-smoke/smoke-toolchain:8:1:toolchain"
  "public-smoke/smoke-integration:8:1:integration"
)

preflight() {
  [ -d tests/public-smoke ] || fail_infra "tests/public-smoke directory missing"
  [ -d node_modules ] || fail_infra "node_modules/ missing; offline dependencies are not vendored"
  [ -x node_modules/.bin/tsx ] || fail_infra "node_modules/.bin/tsx missing or not executable"
  command -v node >/dev/null 2>&1 || fail_infra "node executable missing"
  command -v awk >/dev/null 2>&1 || fail_infra "awk executable missing"
  local sum=0 weighted=0
  for spec in "${TEST_SPECS[@]}"; do
    IFS=: read -r name total weight stage <<< "$spec"
    [ -f "tests/${name}.test.ts" ] || fail_infra "public smoke test missing: tests/${name}.test.ts"
    sum=$((sum + total))
    weighted=$((weighted + total * weight))
  done
  [ "$sum" -eq "$EXPECTED_DENOMINATOR" ] || fail_infra "internal denominator mismatch: $sum != $EXPECTED_DENOMINATOR"
  [ "$weighted" -eq "$EXPECTED_WEIGHTED_DENOMINATOR" ] || fail_infra "internal weighted denominator mismatch: $weighted != $EXPECTED_WEIGHTED_DENOMINATOR"
}

run_one() {
  local name="$1" expected="$2" output status line pass fail reported_total
  output="$(ARC_TEST_ROOT="$SCRIPT_DIR" TEST_FILE="$SCRIPT_DIR/tests/${name}.test.ts" run_limited "$PER_TEST_TIMEOUT" node_modules/.bin/tsx --eval '
    import { pathToFileURL } from "url";
    const file = process.env.TEST_FILE;
    import(pathToFileURL(file).href)
      .then(m => { console.log("SCORE_RESULT:", m.passed ?? 0, m.failed ?? 0); })
      .catch(e => { console.error("RUNNER_ERROR:", e?.code || e?.message || e); console.log("SCORE_RESULT: 0 0"); });
  ' 2>&1)"
  status=$?
  if [ "$status" -ne 0 ]; then
    warn "$name: runner exited $status; scoring as 0/$expected"
    pass=0
  else
    line="$(printf '%s\n' "$output" | grep 'SCORE_RESULT:' | tail -1)"
    if [ -z "$line" ]; then
      warn "$name: no SCORE_RESULT; scoring as 0/$expected"
      pass=0
    else
      pass="$(printf '%s\n' "$line" | awk '{print $2+0}')"
      fail="$(printf '%s\n' "$line" | awk '{print $3+0}')"
      reported_total=$((pass + fail))
      if [ "$reported_total" -ne "$expected" ]; then
        warn "$name: runner reported $pass/$reported_total; normalizing denominator to $expected"
        [ "$pass" -gt "$expected" ] && pass="$expected"
      fi
    fi
  fi
  printf '%s\n' "$pass"
}

preflight

echo "=== Arc Public Smoke Scoring ==="
echo "This public scorer runs solver-visible smoke tests only. Final evaluation is performed by the evaluator-only hidden package."
echo "EXPECTED_TOTAL=$EXPECTED_DENOMINATOR"
echo "EXPECTED_WEIGHTED_TOTAL=$EXPECTED_WEIGHTED_DENOMINATOR"

RAW_PASSED=0
RAW_TOTAL=0
WEIGHTED_PASSED=0
WEIGHTED_TOTAL=0
printf '\n=== Per-File Public Smoke Results ===\n'
for spec in "${TEST_SPECS[@]}"; do
  IFS=: read -r name total weight stage <<< "$spec"
  echo "Running $name..." >&2
  pass="$(run_one "$name" "$total")"
  RAW_PASSED=$((RAW_PASSED + pass))
  RAW_TOTAL=$((RAW_TOTAL + total))
  WEIGHTED_PASSED=$((WEIGHTED_PASSED + pass * weight))
  WEIGHTED_TOTAL=$((WEIGHTED_TOTAL + total * weight))
  printf '  %-36s %2d / %2d weight=%d weighted=%2d/%2d stage=%s\n' "$name" "$pass" "$total" "$weight" $((pass * weight)) $((total * weight)) "$stage"
done

[ "$RAW_TOTAL" -eq "$EXPECTED_DENOMINATOR" ] || fail_infra "observed raw denominator $RAW_TOTAL does not match fixed denominator $EXPECTED_DENOMINATOR"
[ "$WEIGHTED_TOTAL" -eq "$EXPECTED_WEIGHTED_DENOMINATOR" ] || fail_infra "observed weighted denominator $WEIGHTED_TOTAL does not match fixed weighted denominator $EXPECTED_WEIGHTED_DENOMINATOR"

SCORE="0.00"
if [ "$WEIGHTED_TOTAL" -gt 0 ]; then
  SCORE="$(awk -v p="$WEIGHTED_PASSED" -v t="$WEIGHTED_TOTAL" 'BEGIN { printf "%.2f", (100*p)/t }')"
fi

printf '\n=== Public Smoke Final Score ===\n'
echo "SCORE_STATUS=OK"
echo "RAW_PASSED=$RAW_PASSED"
echo "RAW_TOTAL=$RAW_TOTAL"
echo "WEIGHTED_PASSED=$WEIGHTED_PASSED"
echo "WEIGHTED_TOTAL=$WEIGHTED_TOTAL"
echo "SCORE=$SCORE"
