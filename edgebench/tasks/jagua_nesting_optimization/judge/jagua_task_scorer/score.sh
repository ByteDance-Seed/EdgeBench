#!/usr/bin/env bash
set -u

CANDIDATE_ROOT="${CANDIDATE_ROOT:-$(pwd)}"
REFERENCE_ROOT="${REFERENCE_ROOT:-/home/workspace/jagua-rs-ref}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

python3 "$SCRIPT_DIR/evaluate.py" \
  --candidate "$CANDIDATE_ROOT" \
  --reference "$REFERENCE_ROOT" \
  --cases "${JAGUA_EVAL_CASES:-16}" \
  --samples "${JAGUA_EVAL_SAMPLES:-900}" \
  --time-limit "${JAGUA_CASE_TIMEOUT:-20}" \
  --build-timeout "${JAGUA_BUILD_TIMEOUT:-300}" \
  --min-improvement "${JAGUA_MIN_IMPROVEMENT:-0.025}" \
  --target-improvement "${JAGUA_TARGET_IMPROVEMENT:-0.18}" \
  --quality-exponent "${JAGUA_QUALITY_EXPONENT:-2.0}" \
  --soft-time-frac "${JAGUA_SOFT_TIME_FRAC:-0.40}" \
  --min-soft-time "${JAGUA_MIN_SOFT_TIME:-2.0}" \
  --max-slowdown "${JAGUA_MAX_SLOWDOWN:-5.0}" \
  --min-reference-runtime "${JAGUA_MIN_REFERENCE_RUNTIME:-0.15}" \
  --runtime-exponent "${JAGUA_RUNTIME_EXPONENT:-1.25}"

