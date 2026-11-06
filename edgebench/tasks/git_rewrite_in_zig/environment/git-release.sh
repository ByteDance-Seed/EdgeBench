#!/bin/sh
# Rebuild v1's git v2.47.0 trees from the public git release tarball.
#
#   git-release.sh src   <out-dir>                 -> v1 /home/workspace/git-src
#   git-release.sh suite <out-dir> <patch>         -> v1 git-test-suite/ (inside git-test-suite.tar.gz)
#
# v1 copied both trees from the FrontierSWE task assets (tasks/git-to-zig/environment/git-src
# and tasks/git-to-zig/tests/git-test-suite.tar.gz). Both are the git-2.47.0 release with the
# paths in git-release.exclude removed; git-src additionally drops t/, and the test suite has
# one patch to t/test-lib.sh. Files are extracted under umask 022 (644/755, owner root), as
# v1's `cp -a` from a git checkout produced them.
set -eu
mode=$1; out=$2
here=$(dirname "$0")
url=https://mirrors.edge.kernel.org/pub/software/scm/git/git-2.47.0.tar.xz
sha=1ce114da88704271b43e027c51e04d9399f8c88e9ef7542dae7aebae7d87bc4e

umask 022
work=$(mktemp -d)
curl -fsSL --retry 3 -o "$work/git.tar.xz" "$url"
echo "$sha  $work/git.tar.xz" | sha256sum -c -
tar -xJf "$work/git.tar.xz" -C "$work" --no-same-owner --no-same-permissions
tree="$work/git-2.47.0"
grep -v '^#' "$here/git-release.exclude" | grep -v '^$' | while read -r p; do
    [ -e "$tree/$p" ] || { echo "missing excluded path $p" >&2; exit 1; }
    rm -rf "${tree:?}/$p"
done
case "$mode" in
  src)   rm -rf "$tree/t" ;;
  suite) patch -d "$tree" -p1 --no-backup-if-mismatch < "$3" ;;
  *)     echo "usage: $0 src|suite <out> [patch]" >&2; exit 2 ;;
esac
mkdir -p "$(dirname "$out")"
rm -rf "$out"
mv "$tree" "$out"
rm -rf "$work"
