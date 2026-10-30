#!/usr/bin/env bash
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="${APP_DIR:-/app}"
IMPL_DIR="${APP_DIR}/swscale-impl"
VERIFIER_DIR="/logs/verifier"
mkdir -p "$VERIFIER_DIR"

PY_RUN=(python3)

HARBOR_START_MS=$(python3 -c "import time; print(int(time.time()*1000))")

echo "=== FFmpeg libswscale Re-implementation — Verifier ==="
echo ""

# ── Step 1: Delete reference material ────────────────────────────────────────

echo "Step 1: Removing agent reference material and system FFmpeg..."
rm -rf /reference/ffmpeg /reference/ffmpeg-src

# Delete system-installed FFmpeg libraries, headers, and pkgconfig.
# The baseline .so is self-contained (statically linked) so it still works.
# This prevents the agent from wrapping system libswscale via dlopen or linking.
rm -rf /usr/local/lib/libswscale* /usr/local/lib/libavutil* \
       /usr/local/lib/libavformat* /usr/local/lib/libavcodec* \
       /usr/local/lib/libswresample* /usr/local/lib/libavfilter* \
       /usr/local/lib/libpostproc* /usr/local/lib/libavdevice*
rm -rf /usr/local/include/libswscale /usr/local/include/libavutil \
       /usr/local/include/libavformat /usr/local/include/libavcodec \
       /usr/local/include/libswresample /usr/local/include/libavfilter \
       /usr/local/include/libpostproc /usr/local/include/libavdevice
rm -f /usr/local/lib/pkgconfig/libsw* /usr/local/lib/pkgconfig/libav*
ldconfig 2>/dev/null || true

# Scan for copies of FFmpeg binaries or libraries in agent-accessible paths
while IFS= read -r -d '' f; do
    FTYPE=$(file "$f" 2>/dev/null || true)
    if echo "$FTYPE" | grep -q "ELF"; then
        FNAME=$(basename "$f")
        if [[ "$FNAME" == *ffmpeg* ]] || [[ "$FNAME" == *ffprobe* ]] || \
           [[ "$FNAME" == *libswscale* && "$FNAME" != *libswscale_candidate* && "$FNAME" != *libswscale_public_baseline* ]] || \
           [[ "$FNAME" == *libavutil* ]]; then
            echo "WARNING: Removing possible FFmpeg copy: $f"
            rm -f "$f"
        fi
    fi
done < <(find "${APP_DIR}" -type f -executable -print0 2>/dev/null || true)
echo "PASS: reference material and system FFmpeg removed"

# ── Step 2: Baseline integrity ───────────────────────────────────────────────

echo ""
echo "Step 2: Checking baseline integrity..."
BASELINE_LIB="/verifier-data/libswscale_baseline.so"
if [ ! -f "$BASELINE_LIB" ]; then
    "${PY_RUN[@]}" "${SCRIPT_DIR}/compute_reward.py" \
        --fail "baseline library missing" \
        --total-time-ms "$(( $(python3 -c "import time; print(int(time.time()*1000))") - HARBOR_START_MS ))" \
        --output-dir "$VERIFIER_DIR"
    exit 0
fi

EXPECTED_HASH=$(cat /verifier-data/baseline_hash.txt 2>/dev/null | tr -d '[:space:]')
ACTUAL_HASH=$(sha256sum "$BASELINE_LIB" | awk '{print $1}')
if [ "${EXPECTED_HASH}" != "${ACTUAL_HASH}" ]; then
    "${PY_RUN[@]}" "${SCRIPT_DIR}/compute_reward.py" \
        --fail "baseline library integrity check failed" \
        --total-time-ms "$(( $(python3 -c "import time; print(int(time.time()*1000))") - HARBOR_START_MS ))" \
        --output-dir "$VERIFIER_DIR"
    exit 0
fi
echo "PASS: baseline integrity"

# ── Step 3: Source code scan ─────────────────────────────────────────────────

echo ""
echo "Step 3: Scanning agent source for verifier references..."

IS_ORACLE=false
if [ "${HARBOR_ORACLE_MODE:-}" = "1" ]; then
    IS_ORACLE=true
    echo "INFO: oracle marker detected — relaxed source scan"
fi

# Patterns that indicate the agent is referencing verifier internals
SUSPICIOUS_PATTERNS="/tests/|compute_reward|hidden_workloads|/verifier-data|reward\\.json|reward\\.txt|baseline_hash\\.txt|\\.oracle_solution|HARBOR_ORACLE_MODE"

# Patterns that indicate the agent is wrapping FFmpeg rather than reimplementing
# (skipped for oracle solutions which legitimately wrap FFmpeg)
FFMPEG_WRAP_PATTERNS="sws_getContext|sws_scale|sws_freeContext|sws_alloc_context|libswscale\\.so|libavutil\\.so|/usr/local/lib/lib(sw|av)|dlopen|dlsym|RTLD_|dlfcn\\.h"

SCAN_FAILED=false
while IFS= read -r -d '' f; do
    if grep -q -E "${SUSPICIOUS_PATTERNS}" "$f" 2>/dev/null; then
        echo "FAIL: Source code references verifier internals: ${f}"
        SCAN_FAILED=true
        break
    fi
    if [ "$IS_ORACLE" != "true" ]; then
        if grep -q -E "${FFMPEG_WRAP_PATTERNS}" "$f" 2>/dev/null; then
            echo "FAIL: Source code references FFmpeg API (possible wrapper): ${f}"
            SCAN_FAILED=true
            break
        fi
    fi
done < <(find "${IMPL_DIR}" \
    -not -path "*/.zig-cache/*" \
    -not -path "*/zig-out/*" \
    -not -path "*/target/*" \
    -not -path "*/__pycache__/*" \
    -type f \( -name "*.zig" -o -name "*.rs" -o -name "*.c" -o -name "*.h" -o -name "*.cc" -o -name "*.cpp" -o -name "*.hpp" -o -name "*.inc" -o -name "*.toml" -o -name "*.py" -o -name "*.sh" -o -name "*.json" -o -name "*.txt" -o -name "*.cfg" -o -name "*.ld" -o -name "*.S" -o -name "*.asm" -o -name "Makefile" -o -name "CMakeLists.txt" -o -name "*.mk" -o -name "*.cmake" \) -print0 2>/dev/null)
if [ "$SCAN_FAILED" = "true" ]; then
    "${PY_RUN[@]}" "${SCRIPT_DIR}/compute_reward.py" \
        --fail "source code references verifier internals or wraps FFmpeg" \
        --total-time-ms "$(( $(python3 -c "import time; print(int(time.time()*1000))") - HARBOR_START_MS ))" \
        --output-dir "$VERIFIER_DIR"
    exit 0
fi
echo "PASS: source scan"

# ── Step 4: Build candidate from source ──────────────────────────────────────

echo ""
echo "Step 4: Building candidate from source..."
BUILD_OK=false
CANDIDATE_LIB=""

if [ ! -d "${IMPL_DIR}" ]; then
    echo "FAIL: implementation directory ${IMPL_DIR} does not exist"
    "${PY_RUN[@]}" "${SCRIPT_DIR}/compute_reward.py" \
        --fail "implementation directory not found" \
        --total-time-ms "$(( $(python3 -c "import time; print(int(time.time()*1000))") - HARBOR_START_MS ))" \
        --output-dir "$VERIFIER_DIR"
    exit 0
fi
cd "${IMPL_DIR}"

# Remove pre-built ELF shared libraries and static archives from the
# implementation directory before rebuild. This prevents the agent from
# injecting pre-compiled FFmpeg wrappers or copied .a/.so files.
# IMPORTANT: Skip build cache dirs (.zig-cache, target) — deleting cached
# build objects breaks the subsequent zig build / cargo build.
if [ "$IS_ORACLE" != "true" ]; then
    echo "Cleaning pre-built binaries from ${IMPL_DIR}..."
    CLEANED=0
    while IFS= read -r -d '' f; do
        FTYPE=$(file -b "$f" 2>/dev/null || true)
        # Only remove shared libraries (.so) and static archives (.a)
        # Skip .o object files in build caches (needed for zig/cargo rebuild)
        if echo "$FTYPE" | grep -q "^ELF.*shared object\|^current ar archive"; then
            echo "  Removing pre-built: $f"
            rm -f "$f"
            CLEANED=$((CLEANED + 1))
        fi
    done < <(find "${IMPL_DIR}" \
        -not -path "*/.zig-cache/*" \
        -not -path "*/zig-cache/*" \
        -not -path "*/target/*" \
        -type f -print0 2>/dev/null || true)
    echo "Cleaned $CLEANED pre-built binaries"
fi

if [ "$IS_ORACLE" = "true" ]; then
    # Oracle solutions may link against system FFmpeg (now deleted).
    # Skip rebuild and use the pre-built .so from the oracle solve phase.
    echo "INFO: oracle — using pre-built candidate (skipping source rebuild)"
    CANDIDATE_LIB=$(find "${IMPL_DIR}" \( -name "libswscale_candidate.so" -o -name "libswscale_candidate.so.[0-9]*" \) -not -name "*.so.o" -type f 2>/dev/null | head -1)
    if [ -n "$CANDIDATE_LIB" ]; then
        BUILD_OK=true
    fi
else
    # Normal agent — rebuild from source (system FFmpeg is already deleted)
    if [ -f "build.zig" ]; then
        echo "Detected Zig project, running: zig build -Doptimize=ReleaseFast"
        if zig build -Doptimize=ReleaseFast 2>&1; then
            CANDIDATE_LIB=$(find "${IMPL_DIR}" \( -name "libswscale_candidate.so" -o -name "libswscale_candidate.so.[0-9]*" \) -not -name "*.so.o" -type f 2>/dev/null | head -1)
            if [ -n "$CANDIDATE_LIB" ]; then
                BUILD_OK=true
            fi
        fi
    elif [ -f "Cargo.toml" ]; then
        echo "Detected Rust project, running: cargo build --release"
        if cargo build --release 2>&1; then
            CANDIDATE_LIB=$(find "${IMPL_DIR}" \( -name "libswscale_candidate.so" -o -name "libswscale_candidate.so.[0-9]*" \) -not -name "*.so.o" -type f 2>/dev/null | head -1)
            if [ -n "$CANDIDATE_LIB" ]; then
                BUILD_OK=true
            fi
        fi
    elif [ -f "Makefile" ]; then
        echo "Detected Makefile, running: make release"
        if make release 2>&1; then
            CANDIDATE_LIB=$(find "${IMPL_DIR}" \( -name "libswscale_candidate.so" -o -name "libswscale_candidate.so.[0-9]*" \) -not -name "*.so.o" -type f 2>/dev/null | head -1)
            if [ -n "$CANDIDATE_LIB" ]; then
                BUILD_OK=true
            fi
        fi
    fi
fi

if [ "$BUILD_OK" != "true" ] || [ -z "$CANDIDATE_LIB" ]; then
    echo "FAIL: build failed or no libswscale_candidate.so produced"
    "${PY_RUN[@]}" "${SCRIPT_DIR}/compute_reward.py" \
        --fail "build failed or library not found" \
        --total-time-ms "$(( $(python3 -c "import time; print(int(time.time()*1000))") - HARBOR_START_MS ))" \
        --output-dir "$VERIFIER_DIR"
    exit 0
fi
echo "PASS: built candidate at ${CANDIDATE_LIB}"

# ── Step 5: Dynamic dependency check ────────────────────────────────────────

echo ""
echo "Step 5: Checking candidate dynamic dependencies..."
if [ "$IS_ORACLE" != "true" ]; then
    # Verify candidate does not link against FFmpeg shared libraries
    if ldd "$CANDIDATE_LIB" 2>/dev/null | grep -qiE 'libswscale|libavutil|libavcodec|libavformat|libswresample'; then
        echo "FAIL: candidate dynamically links against FFmpeg libraries"
        "${PY_RUN[@]}" "${SCRIPT_DIR}/compute_reward.py" \
            --fail "candidate dynamically links FFmpeg (wrapper detected)" \
            --total-time-ms "$(( $(python3 -c "import time; print(int(time.time()*1000))") - HARBOR_START_MS ))" \
            --output-dir "$VERIFIER_DIR"
        exit 0
    fi
    echo "PASS: no FFmpeg dynamic dependencies"
    # Check for statically linked FFmpeg symbols (catches .a archive embedding)
    if nm -D "$CANDIDATE_LIB" 2>/dev/null | grep -qiE '\bsws_init|\bsws_get|\bsws_free|\bsws_scale|\bav_image|\bav_pix_fmt|\bavutil_'; then
        echo "FAIL: candidate exports/imports FFmpeg symbols (static linking detected)"
        "${PY_RUN[@]}" "${SCRIPT_DIR}/compute_reward.py" \
            --fail "candidate contains FFmpeg symbols (static link detected)" \
            --total-time-ms "$(( $(python3 -c "import time; print(int(time.time()*1000))") - HARBOR_START_MS ))" \
            --output-dir "$VERIFIER_DIR"
        exit 0
    fi
    echo "PASS: no FFmpeg symbols in candidate"

    # Check candidate is not a byte-for-byte copy of the baseline
    CANDIDATE_HASH=$(sha256sum "$CANDIDATE_LIB" | awk '{print $1}')
    BASELINE_HASH_VAL=$(sha256sum "$BASELINE_LIB" 2>/dev/null | awk '{print $1}')
    if [ -n "$CANDIDATE_HASH" ] && [ "$CANDIDATE_HASH" = "$BASELINE_HASH_VAL" ]; then
        echo "FAIL: candidate is identical to baseline (copy detected)"
        "${PY_RUN[@]}" "${SCRIPT_DIR}/compute_reward.py" \
            --fail "candidate is a copy of the baseline library" \
            --total-time-ms "$(( $(python3 -c "import time; print(int(time.time()*1000))") - HARBOR_START_MS ))" \
            --output-dir "$VERIFIER_DIR"
        exit 0
    fi
    echo "PASS: candidate is not a baseline copy"
else
    echo "INFO: oracle — skipping dependency and symbol checks"
fi

# ── Step 6: Run correctness + performance scoring ────────────────────────────

echo ""
echo "Step 6: Running correctness and performance scoring..."

ORACLE_FLAG=""
if [ "${HARBOR_ORACLE_MODE:-}" = "1" ]; then
    ORACLE_FLAG="--oracle"
    echo "INFO: oracle marker detected"
fi

HARBOR_END_MS=$(python3 -c "import time; print(int(time.time()*1000))")
HARBOR_TOTAL_MS=$(( HARBOR_END_MS - HARBOR_START_MS ))

"${PY_RUN[@]}" "${SCRIPT_DIR}/compute_reward.py" \
    --candidate "$CANDIDATE_LIB" \
    --baseline "$BASELINE_LIB" \
    --output-dir "$VERIFIER_DIR" \
    --total-time-ms "$HARBOR_TOTAL_MS" \
    ${ORACLE_FLAG} || true

# Fallback: if compute_reward.py crashed without writing reward, emit 0
if [ ! -f "$VERIFIER_DIR/reward.json" ]; then
    echo '{"reward": 0.0, "score": 0.0, "subscores": [], "additional_data": {"reason": "verifier crashed"}}' \
        > "$VERIFIER_DIR/reward.json"
    echo "0.0" > "$VERIFIER_DIR/reward.txt"
fi

echo ""
echo "=== Verifier complete ==="
if [ -f "$VERIFIER_DIR/reward.txt" ]; then
    echo "Score: $(cat "$VERIFIER_DIR/reward.txt")"
fi
exit 0
