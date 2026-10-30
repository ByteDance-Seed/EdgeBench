#!/bin/bash
# Builds /app for a schemathesis roadmap task (work and judge images), from:
#   - the pinned Python packages in requirements.lock (public PyPI, sha256-checked),
#   - the public upstream schemathesis source at commit $SCHEMATHESIS_COMMIT
#     (GitHub archive tarball, sha256-checked against $SCHEMATHESIS_SHA256),
#   - an editable install of /app (v1: `pip install -e .`), built with the pinned build
#     backend in build-requirements.lock from a throw-away --target dir.
# Expects the two lock files in /tmp/ebv/ and removes /tmp/ebv when done.
# Same script in the sibling tasks; only the commit/sha256 build args and the locks differ.
set -euxo pipefail
: "${SCHEMATHESIS_COMMIT:?}" "${SCHEMATHESIS_SHA256:?}"
export PIP_DISABLE_PIP_VERSION_CHECK=1

# v1: pip install pytest pytest-cov ... (unpinned) -> the exact versions v1 resolved.
pip install --no-cache-dir --require-hashes -r /tmp/ebv/requirements.lock

# v1: git clone <original task repo> && cp -r repo/. /app/  -> upstream source, same tree.
curl -fsSL -o /tmp/ebv/src.tar.gz \
  "https://github.com/schemathesis/schemathesis/archive/${SCHEMATHESIS_COMMIT}.tar.gz"
echo "${SCHEMATHESIS_SHA256}  /tmp/ebv/src.tar.gz" | sha256sum -c -
mkdir -p /app
# GitHub archives store modes 664/775; --no-same-permissions applies the umask (022) so modes
# are 644/755 as after v1's git clone + cp.
tar -xzf /tmp/ebv/src.tar.gz -C /app --strip-components=1 --no-same-owner --no-same-permissions

# v1: cd /app && pip install -e .  (hatchling editable: a .pth with /app/src + console scripts)
pip install --no-cache-dir --require-hashes --target /tmp/ebv/buildenv -r /tmp/ebv/build-requirements.lock
PYTHONPATH=/tmp/ebv/buildenv pip install --no-cache-dir --no-build-isolation --no-deps -e /app

rm -rf /tmp/ebv
