# EdgeBench base image: lean-4.30.0-rc2-mathlib-1a4917a
#
# Lean v4.30.0-rc2 + Mathlib commit 1a4917a18b30ea1333c195e597067fe044ac9176 (and the
# dependency revs that commit pins), with prebuilt oleans from Mathlib's cache.
# Made for tasks whose v1 base was `lean_4` (elan only) and whose own project pins
# exactly this toolchain + Mathlib (first user: carleson_formalization). v1 had no
# shared Mathlib for them: each task image cloned and downloaded its own copy.
#
# System layer = bases/lean-4 (the v1 `lean_4` base: ubuntu:22.04 + the same apt
# packages from the same snapshot), but with elan v4.2.2, which is what the v1
# task images carry (/opt/elan/bin/elan sha256 dee1f289...a557).
#
# The Mathlib project lives at /opt/mathlib (outside the agent's /home/workspace,
# where v1 had nothing extra). Tasks point their project's `.lake/packages/<pkg>` at
# /opt/mathlib/.lake/packages/<pkg> (symlinks) instead of copying, so the ~6.5 GB
# Mathlib tree exists in exactly one shared layer.
#
# Build (needs network; GitHub + Mathlib cache server):
#   built by `sforge build` as base-lean-4.30.0-rc2-mathlib-1a4917a:<tree hash>

# ------------------------------------------------------------------ fetch stage
# Downloads elan + the Lean toolchain, checks sha256, unpacks. Needs zstd, which
# the final image does not carry (v1 did not have it either).
FROM ubuntu@sha256:4f838adc7181d9039ac795a7d0aba05a9bd9ecd480d294483169c5def983b64d AS fetch
ARG DEBIAN_FRONTEND=noninteractive
ARG UBUNTU_SNAPSHOT=20260617T120000Z
RUN set -eux; \
    printf '%s\n' \
      "deb https://snapshot.ubuntu.com/ubuntu/${UBUNTU_SNAPSHOT} jammy main restricted universe multiverse" \
      "deb https://snapshot.ubuntu.com/ubuntu/${UBUNTU_SNAPSHOT} jammy-updates main restricted universe multiverse" \
      "deb https://snapshot.ubuntu.com/ubuntu/${UBUNTU_SNAPSHOT} jammy-security main restricted universe multiverse" \
      > /etc/apt/sources.list; \
    apt-get -o Acquire::https::Verify-Peer=false update; \
    apt-get -o Acquire::https::Verify-Peer=false install -y --no-install-recommends \
      ca-certificates=20260601~22.04.1; \
    apt-get update; \
    apt-get install -y --no-install-recommends curl=7.81.0-1ubuntu1.24 zstd; \
    rm -rf /var/lib/apt/lists/*
# elan v4.2.2 (commit 35628cce1, 2026-05-28). Its elan-init binary is byte-identical
# to the /opt/elan/bin/elan of the v1 carleson images (dee1f289...a557).
ARG ELAN_URL=https://github.com/leanprover/elan/releases/download/v4.2.2/elan-x86_64-unknown-linux-gnu.tar.gz
ARG ELAN_SHA256=40ec208731c4696ac80982ca29e7ad4c2c7c4fe410964d0131c581dd3240de79
# Lean v4.30.0-rc2 release tarball. Unpacked, it is file-for-file identical to v1's
# /opt/elan/toolchains/leanprover--lean4---v4.30.0-rc2 (13904 files, same sha256).
ARG LEAN_URL=https://github.com/leanprover/lean4/releases/download/v4.30.0-rc2/lean-4.30.0-rc2-linux.tar.zst
ARG LEAN_SHA256=5b51625f154f0a13b37bd892f1d95f79e9fd5b9f0d095b4126215ee2bc8dbe86
RUN set -eux; mkdir -p /dl /out/toolchain; cd /dl; \
    curl -fsSL -o elan.tar.gz "$ELAN_URL"; \
    echo "$ELAN_SHA256  elan.tar.gz" | sha256sum -c; \
    tar xzf elan.tar.gz; \
    curl -fsSL -o lean.tar.zst "$LEAN_URL"; \
    echo "$LEAN_SHA256  lean.tar.zst" | sha256sum -c; \
    tar --zstd -xf lean.tar.zst --strip-components=1 -C /out/toolchain; \
    rm lean.tar.zst

# ------------------------------------------------------------------ final image
FROM ubuntu@sha256:4f838adc7181d9039ac795a7d0aba05a9bd9ecd480d294483169c5def983b64d
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC
# Same snapshot and versions as bases/lean-4 (= the published v1 lean_4 base). apt
# verifies the GPG-signed InRelease and every .deb's sha256; only the bootstrap step
# (index fetch + ca-certificates, the stock image has no CA bundle) skips TLS peer checks.
ARG UBUNTU_SNAPSHOT=20260617T120000Z
RUN set -eux; \
    printf '%s\n' \
      "deb https://snapshot.ubuntu.com/ubuntu/${UBUNTU_SNAPSHOT} jammy main restricted universe multiverse" \
      "deb https://snapshot.ubuntu.com/ubuntu/${UBUNTU_SNAPSHOT} jammy-updates main restricted universe multiverse" \
      "deb https://snapshot.ubuntu.com/ubuntu/${UBUNTU_SNAPSHOT} jammy-security main restricted universe multiverse" \
      > /etc/apt/sources.list; \
    apt-get -o Acquire::https::Verify-Peer=false update; \
    apt-get -o Acquire::https::Verify-Peer=false install -y --no-install-recommends \
      ca-certificates=20260601~22.04.1; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      git=1:2.34.1-1ubuntu1.17 \
      curl=7.81.0-1ubuntu1.24 \
      jq=1.6-2.1ubuntu3.2 \
      build-essential=12.9ubuntu3 \
      gcc=4:11.2.0-1ubuntu1 \
      g++=4:11.2.0-1ubuntu1 \
      python3=3.10.6-1~22.04.1 \
      make=4.3-4.1build1 \
      procps=2:3.3.17-6ubuntu2.1 \
      ca-certificates=20260601~22.04.1; \
    rm -rf /var/lib/apt/lists/*; \
    git config --global safe.directory '*'

ENV ELAN_HOME=/opt/elan
ENV PATH="/opt/elan/bin:${PATH}"
COPY --from=fetch /dl/elan-init /tmp/elan-init
RUN set -eux; /tmp/elan-init -y --default-toolchain none; rm /tmp/elan-init; elan --version
COPY --from=fetch /out/toolchain /opt/elan/toolchains/leanprover--lean4---v4.30.0-rc2

# Mathlib project. `lake update` clones Mathlib at the pinned commit and its
# dependencies at the revs Mathlib's own manifest pins (git checks every commit
# hash), then Mathlib's post-update hook runs `lake exe cache get` for the oleans.
# This Mathlib's cache tool unpacks in parallel and runs out of file descriptors
# under Docker's default soft limit (1024), so the soft limit is raised first.
COPY lakefile.toml lean-toolchain /opt/mathlib/
WORKDIR /opt/mathlib
RUN set -eux; ulimit -n 65536; lake update
# The generated manifest must equal the committed pin byte for byte, every package
# HEAD must equal its manifest rev, and `lake build --no-build Mathlib` proves the
# downloaded oleans are complete and up to date (it fails if anything would need
# rebuilding).
ARG MANIFEST_SHA256=26ed4e11d7bc9ccc1979d6d233b70b61d2764ba0a4321330036afa22a71835b0
RUN set -eux; \
    echo "$MANIFEST_SHA256  lake-manifest.json" | sha256sum -c; \
    for n in $(jq -r '.packages[].name' lake-manifest.json); do \
      want=$(jq -r --arg n "$n" '.packages[] | select(.name==$n) | .rev' lake-manifest.json); \
      have=$(git -C ".lake/packages/$n" rev-parse HEAD); \
      [ "$want" = "$have" ] || { echo "rev mismatch: $n $have != $want"; exit 1; }; \
      test -z "$(git -C ".lake/packages/$n" status --porcelain --untracked-files=no)"; \
    done; \
    lake build --no-build Mathlib

# The oleans come from `lake exe cache get`; pin them as one combined hash (8365 files).
ARG OLEANS_SHA256=a17068158d8d99dcb0a10051650a074e4e2d4b1022e3564406c34a09f2467a85
RUN find .lake/packages -name '*.olean' -type f | LC_ALL=C sort \
    | xargs -d '\n' sha256sum | sha256sum | tee /dev/stderr | grep -q "^$OLEANS_SHA256 "

WORKDIR /home/workspace
ENTRYPOINT []
CMD ["/bin/bash"]
