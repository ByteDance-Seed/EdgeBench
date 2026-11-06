#!/usr/bin/env bash
set -euo pipefail

TASK_DIR="$(cd "$(dirname "$0")" && pwd)"
START_DIR="${TASK_DIR}/agent-start"
[ -d "$START_DIR" ] || START_DIR="${TASK_DIR}/skeleton"

PASS=0
FAIL=0
check() {
  local name="$1"; shift
  if "$@" >/tmp/cas-verify-check.log 2>&1; then
    echo "[PASS] $name"
    PASS=$((PASS + 1))
  else
    echo "[FAIL] $name"
    sed 's/^/       /' /tmp/cas-verify-check.log | tail -40
    FAIL=$((FAIL + 1))
  fi
}

check_file() { test -f "${TASK_DIR}/$1"; }
check_dir() { test -d "${TASK_DIR}/$1"; }
rebuild_ghostty_stub() {
  local stub_dir="${START_DIR}/.ghostty-stub"
  test -f "${stub_dir}/ghostty_vt_stub.c"
  cc -c "${stub_dir}/ghostty_vt_stub.c" -o "${stub_dir}/ghostty_vt_stub.o"
  if [ "$(uname -s)" = "Darwin" ] && command -v libtool >/dev/null 2>&1; then
    libtool -static -o "${stub_dir}/libghostty_vt.a" "${stub_dir}/ghostty_vt_stub.o"
  else
    ar rcs "${stub_dir}/libghostty_vt.a" "${stub_dir}/ghostty_vt_stub.o"
  fi
}
clean_ghostty_build_cache() {
  cd "$START_DIR"
  cargo clean -p ghostty_vt_sys >/dev/null 2>&1 || true
  cargo clean -p ghostty_vt >/dev/null 2>&1 || true
}

check "task.yaml exists" check_file task.yaml
check "problem.md exists" check_file problem.md
check "README.md exists" check_file README.md
check "README_zh.md exists" check_file README_zh.md
check "score.sh exists" check_file score.sh
check "tools/score.py exists" check_file tools/score.py
check "starter workspace exists" test -d "$START_DIR"
check "Python scorer compiles" python3 -m py_compile "${TASK_DIR}/tools/score.py"
if [ -f "${TASK_DIR}/tools/skeletonize.py" ]; then
  check "skeletonizer compiles" python3 -m py_compile "${TASK_DIR}/tools/skeletonize.py"
fi
if [ -f "${TASK_DIR}/tools/split_tests.py" ]; then
  check "splitter compiles" python3 -m py_compile "${TASK_DIR}/tools/split_tests.py"
fi
check "offline vendor exists" test -d "${START_DIR}/vendor-deps"
check "cargo source replacement configured" grep -q 'replace-with = "vendored-sources"' "${START_DIR}/.cargo/config.toml"
check "ghostty stub present" test -f "${START_DIR}/.ghostty-stub/libghostty_vt.a"
check "starter contains todo blanks" bash -c "find '$START_DIR' -name '*.rs' -not -path '*/vendor-deps/*' -exec grep -q 'todo!()' {} +"
check "starter has no private hidden snippets directory" bash -c "[ ! -e '$START_DIR/hidden-tests' ] && [ ! -e '$START_DIR/hidden-sources' ] && [ ! -e '$START_DIR/repo' ]"
check "scorer scalar contract" bash -c "grep -q 'RAW_PASSED' '${TASK_DIR}/score.sh' && grep -q 'SCORE_STATUS' '${TASK_DIR}/score.sh'"

if [ "${CAS_VERIFY_EVALUATOR:-0}" = "1" ] || [ -e "${TASK_DIR}/hidden-tests" ]; then
  check "private evaluator source exists" bash -c "[ -d '${TASK_DIR}/hidden-tests/hidden-sources' ] || [ -d '${TASK_DIR}/repo' ]"
  check "hidden split manifest exists" check_file hidden-tests/split-manifest.json
  check "hidden snippets exist" check_dir hidden-tests/hidden-sources
fi

if [ "${CAS_VERIFY_FULL:-0}" = "1" ]; then
  check "ghostty stub rebuilt for current host" rebuild_ghostty_stub
  check "ghostty build cache refreshed" clean_ghostty_build_cache
  check "cargo build starter workspace" bash -c "cd '$START_DIR' && cargo build --workspace --frozen"
  check "cas-types test discovery" bash -c "cd '$START_DIR' && cargo test --frozen -p cas-types -- --list | grep -q ': test$'"
fi

if [ "$FAIL" -gt 0 ]; then
  echo "VERIFY_RESULT=FAIL PASS=$PASS FAIL=$FAIL"
  exit 1
fi

echo "VERIFY_RESULT=OK PASS=$PASS FAIL=$FAIL"
