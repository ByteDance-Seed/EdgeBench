#!/usr/bin/env bash
# Local helper to create a submission tarball.
# Usage: tools/submit.sh [output.tar.gz]

set -euo pipefail

TARBALL="${1:-_submit_$(date +%s).tar.gz}"

make submit TAR="$TARBALL"

echo "Submission package ready: $TARBALL"
echo "You can hand this archive to the external evaluation workflow."
