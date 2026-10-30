#!/bin/bash
# Verifier for port-git-to-zig task.
# Collects evidence into /logs/verifier/evidence.json.
# compute_reward.py makes all scoring decisions.

set -o pipefail

VERIFIER_DIR="/logs/verifier"
TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
AGENT_DIR="/app/zig-port"

mkdir -p "$VERIFIER_DIR"

find /tests -type f -name '*.sh' -exec chmod +x {} + 2>/dev/null || true

# Unpack test suite from tarball to avoid Harbor's slow per-file upload
# (4500+ individual files over Modal hangs the transfer).
if [ -f "$TESTS_DIR/git-test-suite.tar.gz" ]; then
    rm -rf /tmp/git-test-suite
    tar xzf "$TESTS_DIR/git-test-suite.tar.gz" -C /tmp
    GIT_TEST_SUITE="/tmp/git-test-suite"
    echo "Unpacked git-test-suite.tar.gz ($(find "$GIT_TEST_SUITE" -type f | wc -l) files)"
elif [ -f "/app/git-test-suite-assets/git-test-suite.tar.gz" ]; then
    rm -rf /tmp/git-test-suite
    tar xzf "/app/git-test-suite-assets/git-test-suite.tar.gz" -C /tmp
    GIT_TEST_SUITE="/tmp/git-test-suite"
    echo "Unpacked image-provided git-test-suite.tar.gz ($(find "$GIT_TEST_SUITE" -type f | wc -l) files)"
elif [ -d "$TESTS_DIR/git-test-suite" ]; then
    GIT_TEST_SUITE="$TESTS_DIR/git-test-suite"
elif [ -d /app/git-src ]; then
    # Fallback: use the image-fetched Git source tree directly as the test suite.
    # Keep a /tmp copy because Step 2 deletes /app/git-src to prevent solutions
    # from compiling or wrapping the C implementation during verify.
    rm -rf /tmp/git-test-suite
    cp -a /app/git-src /tmp/git-test-suite
    GIT_TEST_SUITE="/tmp/git-test-suite"
    echo "Copied image-provided Git source as test suite ($(find "$GIT_TEST_SUITE" -type f | wc -l) files)"
else
    echo "ERROR: No git-test-suite or image-provided Git source found"
    exit 1
fi
exec > "$VERIFIER_DIR/verifier.log" 2>&1

echo "========================================"
echo "  Harbor Git-to-Zig Port Verifier"
echo "========================================"
echo "Start time: $(date)"

# Evidence accumulator — compute_reward.py reads this
EVIDENCE="$VERIFIER_DIR/evidence.json"
RESULTS_DIR="$VERIFIER_DIR/test-results"
mkdir -p "$RESULTS_DIR"

IS_ORACLE=false
[ "${HARBOR_ORACLE_MODE:-}" = "1" ] && IS_ORACLE=true

# ── Step 1: Anti-cheat ──────────────────────────────────────────

echo ""
echo "=== Step 1: Anti-cheat ==="

ANTI_CHEAT_RESULT="pass"
ANTI_CHEAT_VIOLATIONS=""
ANTI_CHEAT_C_LOC=0

if [ "$IS_ORACLE" = true ]; then
    echo "Oracle solution detected — skipping anti-cheat."
    ANTI_CHEAT_RESULT="oracle_bypass"
else
    C_LOC=$(find "$AGENT_DIR" -name "*.c" \
        -not -path "*/.zig-cache/*" -not -path "*/zig-cache/*" -not -path "*/zig-out/*" \
        -exec cat {} + 2>/dev/null | wc -l)
    ANTI_CHEAT_C_LOC=$C_LOC
    echo "C LOC in workspace: $C_LOC"
    if [ "$C_LOC" -gt 2000 ]; then
        ANTI_CHEAT_RESULT="fail"
        ANTI_CHEAT_VIOLATIONS="${ANTI_CHEAT_VIOLATIONS}excessive_c_code(${C_LOC}_lines);"
    fi

    if [ -f "$AGENT_DIR/build.zig" ]; then
        if grep -qE 'addCSourceFiles|addCSourceFile' "$AGENT_DIR/build.zig" 2>/dev/null; then
            if grep -oE 'addCSourceFiles?[^;]*' "$AGENT_DIR/build.zig" 2>/dev/null | grep -qiE 'git.src|git-src|/app/git'; then
                ANTI_CHEAT_RESULT="fail"
                ANTI_CHEAT_VIOLATIONS="${ANTI_CHEAT_VIOLATIONS}build_zig_references_git_src;"
            fi
        fi
    fi

    EXEC_CALLS=$(grep -rn 'std\.process\.Child\|std\.posix\.execve\|std\.os\.execve' \
        "$AGENT_DIR/src/" 2>/dev/null | grep -v 'zig-cache' || true)
    if [ -n "$EXEC_CALLS" ] && echo "$EXEC_CALLS" | grep -qiE '"git"|"/usr/bin/git"'; then
        ANTI_CHEAT_RESULT="fail"
        ANTI_CHEAT_VIOLATIONS="${ANTI_CHEAT_VIOLATIONS}shells_out_to_git;"
    fi

    GIT_IMPORTS=$(grep -rn '@cImport' "$AGENT_DIR/src/" 2>/dev/null \
        | grep -v 'zig-cache' \
        | grep -viE 'zlib\.h|openssl|stdio\.h|stdlib\.h|string\.h|unistd\.h|errno\.h|fcntl\.h|sys/' \
        || true)
    if [ -n "$GIT_IMPORTS" ] && echo "$GIT_IMPORTS" | grep -qiE 'cache\.h|builtin\.h|commit\.h|tree\.h|blob\.h|object\.h|strbuf\.h|refs\.h|config\.h|diff\.h|revision\.h'; then
        ANTI_CHEAT_RESULT="fail"
        ANTI_CHEAT_VIOLATIONS="${ANTI_CHEAT_VIOLATIONS}imports_git_c_headers;"
    fi

    PREBUILT=$(find "$AGENT_DIR" \
        -not -path "*/.zig-cache/*" -not -path "*/zig-cache/*" -not -path "*/zig-out/*" \
        \( -name "*.o" -o -name "*.a" -o -name "*.so" -o -name "*.so.*" -o -name "*.dylib" \) \
        -print 2>/dev/null)
    if [ -n "$PREBUILT" ]; then
        ANTI_CHEAT_RESULT="fail"
        ANTI_CHEAT_VIOLATIONS="${ANTI_CHEAT_VIOLATIONS}precompiled_objects;"
    fi

    STRAY_ELFS=$(find "$AGENT_DIR" \
        -not -path "*/.zig-cache/*" -not -path "*/zig-cache/*" -not -path "*/zig-out/*" \
        -type f -executable -exec file {} \; 2>/dev/null \
        | grep 'ELF' || true)
    if [ -n "$STRAY_ELFS" ]; then
        ANTI_CHEAT_RESULT="fail"
        ANTI_CHEAT_VIOLATIONS="${ANTI_CHEAT_VIOLATIONS}stray_elf_binaries;"
    fi

    echo "Anti-cheat result: $ANTI_CHEAT_RESULT"
    [ -n "$ANTI_CHEAT_VIOLATIONS" ] && echo "Violations: $ANTI_CHEAT_VIOLATIONS"
fi

# ── Step 2: Clean build ─────────────────────────────────────────

echo ""
echo "=== Step 2: Clean build ==="

BUILD_EXIT_CODE=0
BUILD_BINARY_TYPE=""
BUILD_LINKS_LIBGIT2=false
AGENT_BIN=""

if [ "$IS_ORACLE" = true ]; then
    echo "Oracle solution — skipping clean build."
    AGENT_BIN="$AGENT_DIR/zig-out/bin/git"
    [ ! -f "$AGENT_BIN" ] && AGENT_BIN=$(find "$AGENT_DIR/zig-out" -name "git" -type f 2>/dev/null | head -1)
    [ -z "$AGENT_BIN" ] && BUILD_EXIT_CODE=1
else
    rm -rf /app/git-src
    rm -rf "$AGENT_DIR/zig-out" "$AGENT_DIR/.zig-cache" "$AGENT_DIR/zig-cache"
    find "$AGENT_DIR" -type f \( -name "*.o" -o -name "*.a" -o -name "*.so" \) -delete 2>/dev/null

    cd "$AGENT_DIR"
    zig build > "$VERIFIER_DIR/build.log" 2>&1
    BUILD_EXIT_CODE=$?
    echo "zig build exit code: $BUILD_EXIT_CODE"
    tail -20 "$VERIFIER_DIR/build.log"

    if [ "$BUILD_EXIT_CODE" -eq 0 ]; then
        AGENT_BIN="$AGENT_DIR/zig-out/bin/git"
        [ ! -f "$AGENT_BIN" ] && AGENT_BIN=$(find "$AGENT_DIR/zig-out" -name "git" -type f 2>/dev/null | head -1)

        if [ -n "$AGENT_BIN" ] && [ -f "$AGENT_BIN" ]; then
            chmod +x "$AGENT_BIN"
            BUILD_BINARY_TYPE=$(file "$AGENT_BIN" 2>/dev/null || echo "unknown")
            echo "Binary type: $BUILD_BINARY_TYPE"
            if ldd "$AGENT_BIN" 2>/dev/null | grep -qi 'libgit2'; then
                BUILD_LINKS_LIBGIT2=true
            fi
        fi
    fi
fi

echo "Agent binary: ${AGENT_BIN:-none}"

# ── Step 2.5: Strace smoke test (detect wrapper binaries) ──────

echo ""
echo "=== Step 2.5: Strace smoke test ==="

STRACE_CHEAT=false
STRACE_DETAILS=""

if [ "$IS_ORACLE" = true ]; then
    echo "Oracle — skipping strace check."
elif [ -n "$AGENT_BIN" ] && [ -f "$AGENT_BIN" ]; then
    SMOKE_DIR="/tmp/strace-smoke-$$"
    STRACE_LOG1="/tmp/strace-$$.1.log"
    STRACE_LOG2="/tmp/strace-$$.2.log"
    STRACE_LOG3="/tmp/strace-$$.3.log"
    rm -rf "$SMOKE_DIR" "$STRACE_LOG1" "$STRACE_LOG2" "$STRACE_LOG3"
    mkdir -p "$SMOKE_DIR"

    AGENT_BIN_DIR=$(dirname "$AGENT_BIN")

    strace -f -e trace=execve -o "$STRACE_LOG1" \
        "$AGENT_BIN" init "$SMOKE_DIR/repo" >/dev/null 2>&1 || true
    strace -f -e trace=execve -o "$STRACE_LOG2" \
        "$AGENT_BIN" -C "$SMOKE_DIR/repo" status >/dev/null 2>&1 || true
    strace -f -e trace=execve -o "$STRACE_LOG3" \
        "$AGENT_BIN" -C "$SMOKE_DIR/repo" hash-object -t blob --stdin </dev/null >/dev/null 2>&1 || true

    EXEC_BINS=$(cat "$STRACE_LOG1" "$STRACE_LOG2" "$STRACE_LOG3" 2>/dev/null \
        | grep 'execve("' \
        | grep -v '= -1' \
        | sed 's/.*execve("\([^"]*\)".*/\1/' \
        | sort -u)

    for bin in $EXEC_BINS; do
        case "$bin" in "$AGENT_BIN_DIR"/*|"$AGENT_BIN") continue ;; esac
        if strings "$bin" 2>/dev/null | grep -qE 'GIT_EXEC_PATH|git-upload-pack|git.version'; then
            STRACE_CHEAT=true
            STRACE_DETAILS="${STRACE_DETAILS}${bin};"
            echo "CHEAT DETECTED: agent binary exec'd external git: $bin"
        fi
    done

    rm -rf "$SMOKE_DIR" "$STRACE_LOG1" "$STRACE_LOG2" "$STRACE_LOG3"
    echo "Strace check result: cheat=$STRACE_CHEAT"
else
    echo "No binary — skipping strace check."
fi

if [ "$STRACE_CHEAT" = true ]; then
    ANTI_CHEAT_RESULT="fail"
    ANTI_CHEAT_VIOLATIONS="${ANTI_CHEAT_VIOLATIONS}exec_external_git:${STRACE_DETAILS}"
fi

# ── Step 2.6: Nuke system git (prevent wrappers during tests) ──

echo ""
echo "=== Step 2.6: Nuke system git ==="

if [ "$IS_ORACLE" = true ]; then
    echo "Oracle — skipping nuke."
else
    rm -f /usr/bin/git /usr/bin/git-*
    rm -rf /usr/lib/git-core /usr/libexec/git-core
    hash -r
    echo "System git removed."
fi

# ── Step 3: Build test helpers (only if we have a binary to test) ──

echo ""
echo "=== Step 3: Build test helpers ==="

GIT_BUILD="/tmp/git-build"
TEST_HELPERS_OK=false

if [ -n "$AGENT_BIN" ] && [ -f "$AGENT_BIN" ]; then
    rm -rf "$GIT_BUILD"
    cp -r "$GIT_TEST_SUITE" "$GIT_BUILD"
    chmod -R u+w "$GIT_BUILD"

    cd "$GIT_BUILD"
    if make -j"$(nproc)" NO_TCLTK=1 NO_EXPAT=1 NO_GETTEXT=1 2>&1 | tail -10; then
        TEST_HELPERS_OK=true
    fi
    echo "test-tool: $([ -f "$GIT_BUILD/t/helper/test-tool" ] && echo OK || echo MISSING)"

    # Remove the C git binaries from the build (keep only test helpers)
    find "$GIT_BUILD" -maxdepth 1 \( -name "git" -o -name "git-*" \) -type f -delete 2>/dev/null
    rm -rf "$GIT_BUILD/git-core"
    echo "C git binaries removed from test build."
else
    echo "No binary to test — skipping test helper build."
fi

# ── Step 4: Run git test suite ──────────────────────────────────

echo ""
echo "=== Step 4: Run git test suite ==="

TESTS_RAN=false

if [ -n "$AGENT_BIN" ] && [ -f "$AGENT_BIN" ] && [ "$TEST_HELPERS_OK" = true ]; then
    # Wipe temp dirs to remove any stashed binaries (skip for oracle)
    if [ "$IS_ORACLE" != true ]; then
        find /tmp -maxdepth 1 -mindepth 1 ! -name "git-build" -exec rm -rf {} + 2>/dev/null || true
        rm -rf /var/tmp/* 2>/dev/null || true
    fi

    TESTS_RAN=true
    AGENT_BIN_DIR=$(dirname "$AGENT_BIN")

    cd "$GIT_BUILD/t"

    TOTAL_SCRIPTS=$(ls t[0-9]*.sh 2>/dev/null | wc -l)
    echo "Found $TOTAL_SCRIPTS test scripts"

    NPARALLEL=$(nproc)
    echo "Running with $NPARALLEL parallel workers"

    run_one_test() {
        local test_script="$1"
        local results_dir="$2"
        local agent_bin_dir="$3"

        local script_name
        script_name=$(basename "$test_script" .sh)
        local result_file="$results_dir/${script_name}.out"
        local tmpdir="/tmp/test-$$-${script_name}"

        mkdir -p "$tmpdir"

        timeout 120 bash -c "
            GIT_TEST_INSTALLED='$agent_bin_dir' \
            GIT_TEST_CMP='diff -u' \
            HOME='$tmpdir' \
            ./$test_script --no-color 2>&1
        " > "$result_file" 2>&1

        local exit_code=$?
        if [ "$exit_code" -eq 124 ]; then
            echo "# TIMEOUT after 120s" >> "$result_file"
        fi

        rm -rf "$tmpdir"

        local passes fails
        passes=$(grep -c '^ok ' "$result_file" 2>/dev/null || echo 0)
        fails=$(grep -c '^not ok ' "$result_file" 2>/dev/null || echo 0)
        echo "  $script_name ... ok:$passes fail:$fails"
    }

    export -f run_one_test

    ls t[0-9]*.sh | xargs -P "$NPARALLEL" -I {} bash -c 'run_one_test "$@"' _ {} "$RESULTS_DIR" "$AGENT_BIN_DIR"

    COMPLETED=$(ls "$RESULTS_DIR"/t*.out 2>/dev/null | wc -l)
    SCRIPTS_WITH_PASSES=$(grep -l '^ok ' "$RESULTS_DIR"/t*.out 2>/dev/null | wc -l)
    echo ""
    echo "Ran $COMPLETED of $TOTAL_SCRIPTS test scripts, $SCRIPTS_WITH_PASSES had at least one pass"
else
    echo "Skipping test suite (no working binary or test helpers failed)."
fi

# ── Step 5: Write evidence, hand off to compute_reward.py ───────

echo ""
echo "=== Step 5: Write evidence ==="

_bool() { [ "$1" = true ] && echo true || echo false; }

cat > "$EVIDENCE" <<EVIDENCE_EOF
{
  "timestamp": $(date +%s),
  "is_oracle": $(_bool "$IS_ORACLE"),
  "anti_cheat": {
    "result": "$ANTI_CHEAT_RESULT",
    "violations": "$ANTI_CHEAT_VIOLATIONS",
    "c_loc": $ANTI_CHEAT_C_LOC,
    "strace_cheat": $(_bool "$STRACE_CHEAT"),
    "strace_details": "$STRACE_DETAILS"
  },
  "build": {
    "exit_code": $BUILD_EXIT_CODE,
    "binary_path": "${AGENT_BIN:-}",
    "binary_type": "$BUILD_BINARY_TYPE",
    "links_libgit2": $(_bool "$BUILD_LINKS_LIBGIT2")
  },
  "tests_ran": $(_bool "$TESTS_RAN"),
  "results_dir": "$RESULTS_DIR"
}
EVIDENCE_EOF

cat "$EVIDENCE"

echo ""
echo "=== Step 6: Compute reward ==="

python3 "$TESTS_DIR/compute_reward.py" \
    --output-dir "$VERIFIER_DIR" \
    --evidence "$EVIDENCE" \
    2>&1

echo ""
echo "End time: $(date)"
echo "========================================"
