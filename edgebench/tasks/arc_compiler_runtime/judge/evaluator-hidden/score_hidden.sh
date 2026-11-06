#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ORIGINAL_SUBMISSION_ROOT="${1:-${SUBMISSION_ROOT:-}}"
PER_TEST_TIMEOUT="${PER_TEST_TIMEOUT:-90}"
KEEP_HIDDEN_EVAL_TMP="${KEEP_HIDDEN_EVAL_TMP:-0}"

fail_infra() {
  echo "HIDDEN_INFRA_ERROR: $*" >&2
  echo "SCORE_STATUS=INFRA_FAIL"
  exit 70
}
warn() { echo "  [WARN] $*" >&2; }

usage() {
  cat >&2 <<'USAGE'
Usage: bash evaluator-hidden/score_hidden.sh /path/to/submission-root-or-agent-start
   or: SUBMISSION_ROOT=/path/to/submission-root-or-agent-start bash evaluator-hidden/score_hidden.sh

The submission path may be either the public package root containing agent-start/
or the agent-start/ directory itself.
USAGE
}

if [ -z "$ORIGINAL_SUBMISSION_ROOT" ]; then
  usage
  exit 64
fi

resolve_submission_agent_start() {
  local root="$1"
  [ -d "$root" ] || return 1
  root="$(cd "$root" 2>/dev/null && pwd)" || return 1
  if [ -d "$root/agent-start" ]; then
    printf '%s\n' "$(cd "$root/agent-start" && pwd)"
    return 0
  fi
  if [ -d "$root/compiler" ] && { [ -f "$root/score.sh" ] || [ -d "$root/tests" ] || [ -f "$root/package.json" ]; }; then
    printf '%s\n' "$root"
    return 0
  fi
  return 1
}

SUBMISSION_AGENT_START="$(resolve_submission_agent_start "$ORIGINAL_SUBMISSION_ROOT")" || fail_infra "submission root must be a package root with agent-start/ or an agent-start directory: $ORIGINAL_SUBMISSION_ROOT"

run_limited() {
  local seconds="$1"; shift
  if command -v timeout >/dev/null 2>&1; then
    timeout "$seconds" "$@"
  else
    "$@"
  fi
}

[ -d "$SUBMISSION_AGENT_START" ] || fail_infra "submission agent-start missing: $SUBMISSION_AGENT_START"
[ -d "$SUBMISSION_AGENT_START/node_modules" ] || fail_infra "submission node_modules missing; hidden evaluator is offline and expects vendored deps"
[ -x "$SUBMISSION_AGENT_START/node_modules/.bin/tsx" ] || fail_infra "submission tsx runner missing or not executable"
[ -d "$SUBMISSION_AGENT_START/compiler" ] || fail_infra "submission compiler directory missing"
[ -d "$SCRIPT_DIR/tests" ] || fail_infra "hidden tests directory missing: $SCRIPT_DIR/tests"

TEST_SPECS=(
  "strengthened/round2-lexer-parser:8:5:HARD:parser"
  "strengthened/round2-type-system:8:5:HARD:type-system"
  "strengthened/round2-interpreter:8:5:HARD:interpreter"
  "strengthened/round2-stdlib:8:5:HARD:stdlib"
  "strengthened/round2-codegen:8:5:HARD:codegen"
  "strengthened/round2-toolchain:8:5:HARD:toolchain"
  "strengthened/compact-parser-boundary:25:5:HARD:parser"
  "strengthened/compact-codegen-consistency:30:7:ADVERSARIAL:codegen"
  "strengthened/compact-stdlib-composition:30:7:ADVERSARIAL:stdlib"
  "strengthened/compact-toolchain-edge:20:5:HARD:toolchain"
  "strengthened/compact-integration:35:7:ADVERSARIAL:integration"
  "extra/hidden-parser-boundary:12:5:HARD:parser"
  "extra/hidden-codegen-consistency:12:8:ADVERSARIAL:codegen"
  "extra/hidden-stdlib-composition:12:5:HARD:stdlib"
  "extra/hidden-toolchain-edge:8:2:MEDIUM:toolchain"
  "extra/hidden-integration:16:8:ADVERSARIAL:integration"
  "extra/hidden-type-system-adversarial-1:40:8:ADVERSARIAL:type-system"
  "extra/hidden-type-system-adversarial-2:40:8:ADVERSARIAL:type-system"
  "extra/hidden-type-system-adversarial-3:40:8:ADVERSARIAL:type-system"
  "extra/hidden-parser-boundary-round2:40:5:HARD:parser"
  "extra/hidden-codegen-consistency-round2:40:8:ADVERSARIAL:codegen"
)

safe() { printf '%s' "$1" | sed 's#[/-]#_#g'; }
set_metric() { local key="$1" val="$2"; eval "$key=\"$val\""; }
get_metric() { local key="$1"; eval "printf '%s' \"\${$key:-0}\""; }

EXPECTED_TOTAL=0
EXPECTED_WEIGHTED_TOTAL=0
for spec in "${TEST_SPECS[@]}"; do
  IFS=: read -r name total weight tier module <<< "$spec"
  file="$SCRIPT_DIR/tests/${name}.test.ts"
  [ -f "$file" ] || fail_infra "hidden test file missing: $file"
  EXPECTED_TOTAL=$((EXPECTED_TOTAL + total))
  EXPECTED_WEIGHTED_TOTAL=$((EXPECTED_WEIGHTED_TOTAL + total * weight))
done

TMP_WORK="$(mktemp -d "${TMPDIR:-/tmp}/arc-hidden-eval-XXXXXX")" || fail_infra "could not create temp workspace"
cleanup() {
  if [ "${KEEP_HIDDEN_EVAL_TMP:-0}" = "1" ]; then
    echo "HIDDEN_EVAL_TMP=$TMP_WORK" >&2
  else
    chmod -R u+w "$TMP_WORK" 2>/dev/null || true
    rm -rf "$TMP_WORK"
  fi
}
trap cleanup EXIT

mkdir -p "$TMP_WORK"
cp -R "$SUBMISSION_AGENT_START" "$TMP_WORK/agent-start" || fail_infra "failed to copy submission into temp workspace"
chmod -R u+w "$TMP_WORK/agent-start" 2>/dev/null || true
mkdir -p "$TMP_WORK/agent-start/tests/hidden-evaluator"
cp -R "$SCRIPT_DIR/tests/." "$TMP_WORK/agent-start/tests/hidden-evaluator/" || fail_infra "failed to copy hidden tests into temp workspace"
WORK_AGENT_START="$TMP_WORK/agent-start"

trim_output() { sed -n '1,120p'; }

run_one() {
  local name="$1" expected="$2" file="$WORK_AGENT_START/tests/hidden-evaluator/${name}.test.ts" output status line pass fail reported_total
  [ -f "$file" ] || fail_infra "copied hidden test file missing: $file"

  output="$(cd "$WORK_AGENT_START" && ARC_TEST_ROOT="$WORK_AGENT_START" TEST_FILE="$file" EXPECTED_CASES="$expected" run_limited "$PER_TEST_TIMEOUT" node_modules/.bin/tsx --eval '
    import { pathToFileURL } from "url";
    import { inspect } from "util";

    const stringify = (value) => {
      if (typeof value === "string") return value;
      if (value instanceof Error) return value.stack || value.message || String(value);
      return inspect(value, { depth: 6, breakLength: Infinity });
    };

    const parseSummary = (lines) => {
      let found;
      const re = /(\d+)\s+passed\s*,\s*(\d+)\s+failed/ig;
      for (const line of lines) {
        re.lastIndex = 0;
        let match;
        while ((match = re.exec(line)) !== null) {
          found = { passed: Number(match[1]), failed: Number(match[2]), source: line };
        }
      }
      return found;
    };

    (async () => {
      const file = process.env.TEST_FILE;
      const expected = Number(process.env.EXPECTED_CASES || "0");
      const arcRoot = process.env.ARC_TEST_ROOT || "";
      const captured = [];
      const originalLog = console.log.bind(console);
      const originalError = console.error.bind(console);
      console.log = (...args) => {
        captured.push(args.map(stringify).join(" "));
        originalLog(...args);
      };
      console.error = (...args) => {
        captured.push(args.map(stringify).join(" "));
        originalError(...args);
      };

      let moduleExports;
      try {
        moduleExports = await import(pathToFileURL(file).href);
      } catch (e) {
        const stack = String(e?.stack || e?.message || e);
        const candidateCompilerPath = arcRoot ? `${arcRoot}/compiler/` : "";
        if (expected > 0 && candidateCompilerPath && stack.includes(candidateCompilerPath)) {
          originalError("RUNNER_CANDIDATE_IMPORT_FAILURE: candidate compiler module import failed; scoring this suite as 0/" + expected);
          originalError(stack);
          originalLog("SCORE_RESULT:", 0, expected);
          process.exit(0);
        }
        originalError("RUNNER_ERROR:");
        originalError(stack);
        process.exit(91);
      }

      const sources = [moduleExports, moduleExports?.default, moduleExports?.["module.exports"]].filter(Boolean);
      let exported;
      for (const source of sources) {
        const passed = Number(source.passed);
        const failed = Number(source.failed);
        if (Number.isFinite(passed) && Number.isFinite(failed)) {
          exported = { passed, failed };
          break;
        }
      }

      const summary = parseSummary(captured);
      let result;
      if (summary) {
        result = { passed: summary.passed, failed: summary.failed, source: "stdout" };
      } else if (exported) {
        result = { passed: exported.passed, failed: exported.failed, source: "exports" };
      }

      if (!result) {
        originalError("RUNNER_ERROR: hidden test module did not expose numeric counters and stdout did not contain N passed, M failed");
        originalError("RUNNER_DEBUG_KEYS:", Object.keys(moduleExports || {}).join(","));
        process.exit(92);
      }
      originalLog("SCORE_RESULT:", result.passed, result.failed, result.source);
    })();
  ' 2>&1)"
  status=$?
  if [ "$status" -ne 0 ]; then
    printf '%s\n' "$output" | trim_output >&2
    fail_infra "suite $name runner exited $status before reporting valid counters"
  fi

  line="$(printf '%s\n' "$output" | grep 'SCORE_RESULT:' | tail -1)"
  if [ -z "$line" ]; then
    printf '%s\n' "$output" | trim_output >&2
    fail_infra "suite $name did not report SCORE_RESULT"
  fi

  pass="$(printf '%s\n' "$line" | awk '{print $2+0}')"
  fail="$(printf '%s\n' "$line" | awk '{print $3+0}')"
  reported_total=$((pass + fail))

  if [ "$reported_total" -eq 0 ]; then
    printf '%s\n' "$output" | trim_output >&2
    fail_infra "suite $name reported 0/0; hidden tests were not executed or counters were not captured"
  fi
  if [ "$reported_total" -ne "$expected" ]; then
    printf '%s\n' "$output" | trim_output >&2
    fail_infra "suite $name reported $pass/$reported_total but expected denominator $expected"
  fi
  if [ "$pass" -lt 0 ] || [ "$pass" -gt "$expected" ]; then
    printf '%s\n' "$output" | trim_output >&2
    fail_infra "suite $name reported invalid pass count $pass for denominator $expected"
  fi

  printf '  %-42s %3d / %3d\n' "$name" "$pass" "$expected" >&2
  local id; id="$(safe "$name")"
  set_metric "PASS_$id" "$pass"
  set_metric "TOTAL_$id" "$expected"
}

echo "=== Arc Hidden Evaluator ==="
echo "SUBMISSION_INPUT=$ORIGINAL_SUBMISSION_ROOT"
echo "SUBMISSION_AGENT_START=$SUBMISSION_AGENT_START"
echo "TMP_WORK=$TMP_WORK"
echo "EXPECTED_TOTAL=$EXPECTED_TOTAL"
echo "EXPECTED_WEIGHTED_TOTAL=$EXPECTED_WEIGHTED_TOTAL"

RAW_PASSED=0
RAW_TOTAL=0
WEIGHTED_PASSED=0
WEIGHTED_TOTAL=0
for spec in "${TEST_SPECS[@]}"; do
  IFS=: read -r name total weight tier module <<< "$spec"
  echo "Running hidden $name..." >&2
  run_one "$name" "$total"
  id="$(safe "$name")"
  pass="$(get_metric "PASS_$id")"
  RAW_PASSED=$((RAW_PASSED + pass))
  RAW_TOTAL=$((RAW_TOTAL + total))
  WEIGHTED_PASSED=$((WEIGHTED_PASSED + pass * weight))
  WEIGHTED_TOTAL=$((WEIGHTED_TOTAL + total * weight))
  msafe="$(safe "MODULE_$module")"; dsafe="$(safe "DIFF_$tier")"
  set_metric "${msafe}_RAW" $(( $(get_metric "${msafe}_RAW") + total ))
  set_metric "${msafe}_WEIGHT" $(( $(get_metric "${msafe}_WEIGHT") + total * weight ))
  set_metric "${msafe}_PASS" $(( $(get_metric "${msafe}_PASS") + pass ))
  set_metric "${msafe}_WPASS" $(( $(get_metric "${msafe}_WPASS") + pass * weight ))
  set_metric "${dsafe}_RAW" $(( $(get_metric "${dsafe}_RAW") + total ))
  set_metric "${dsafe}_WEIGHT" $(( $(get_metric "${dsafe}_WEIGHT") + total * weight ))
  set_metric "${dsafe}_PASS" $(( $(get_metric "${dsafe}_PASS") + pass ))
  set_metric "${dsafe}_WPASS" $(( $(get_metric "${dsafe}_WPASS") + pass * weight ))
done

[ "$RAW_TOTAL" -eq "$EXPECTED_TOTAL" ] || fail_infra "raw denominator mismatch: $RAW_TOTAL != $EXPECTED_TOTAL"
[ "$WEIGHTED_TOTAL" -eq "$EXPECTED_WEIGHTED_TOTAL" ] || fail_infra "weighted denominator mismatch: $WEIGHTED_TOTAL != $EXPECTED_WEIGHTED_TOTAL"

printf '\n=== Hidden Module Distribution ===\n'
for module in parser type-system interpreter stdlib codegen toolchain integration; do
  msafe="$(safe "MODULE_$module")"
  raw="$(get_metric "${msafe}_RAW")"; weight="$(get_metric "${msafe}_WEIGHT")"
  pass="$(get_metric "${msafe}_PASS")"; wpass="$(get_metric "${msafe}_WPASS")"
  [ "$raw" -gt 0 ] || continue
  printf '  %-16s raw=%3s weighted=%4s pass=%3s wpass=%4s\n' "$module" "$raw" "$weight" "$pass" "$wpass"
done
printf '\n=== Hidden Difficulty Distribution ===\n'
for tier in EASY MEDIUM HARD ADVERSARIAL; do
  dsafe="$(safe "DIFF_$tier")"
  raw="$(get_metric "${dsafe}_RAW")"; weight="$(get_metric "${dsafe}_WEIGHT")"
  pass="$(get_metric "${dsafe}_PASS")"; wpass="$(get_metric "${dsafe}_WPASS")"
  [ "$raw" -gt 0 ] || continue
  printf '  %-12s raw=%3s weighted=%4s pass=%3s wpass=%4s\n' "$tier" "$raw" "$weight" "$pass" "$wpass"
done

SCORE="0.00"
if [ "$WEIGHTED_TOTAL" -gt 0 ]; then
  SCORE="$(awk -v p="$WEIGHTED_PASSED" -v t="$WEIGHTED_TOTAL" 'BEGIN { printf "%.2f", (100*p)/t }')"
fi
printf '\n=== Hidden Final Score ===\n'
echo "SCORE_STATUS=OK"
echo "RAW_PASSED=$RAW_PASSED"
echo "RAW_TOTAL=$RAW_TOTAL"
echo "WEIGHTED_PASSED=$WEIGHTED_PASSED"
echo "WEIGHTED_TOTAL=$WEIGHTED_TOTAL"
echo "SCORE=$SCORE"
