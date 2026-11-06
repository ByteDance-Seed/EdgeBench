#!/usr/bin/env bash
set -euo pipefail

cat <<'MSG'
This benchmark starter is configured for offline solving. Network bootstrap of Zig
is intentionally disabled in the solver-visible package. The benchmark uses the
prebuilt Ghostty VT stub in .ghostty-stub/; verifier full mode can rebuild that
stub for the current host with the system C toolchain.
MSG
exit 0
