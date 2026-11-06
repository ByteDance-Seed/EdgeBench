# EdgeBench base image: lean-4.28.0-mathlib-8f9d9cf
#
# Reproduces the v1 `edgebench.base.lean_4_28_0_main` image (BENCHMARK.yaml
# `lean_4_28_0_main`): ubuntu:22.04 + git curl jq build-essential gcc g++ python3
# make procps ca-certificates, elan in /opt/elan, and the Mathlib project
# /home/workspace/baseline made by `lake +leanprover/lean4:v4.28.0 new baseline math`
# (Mathlib tag v4.28.0 = 8f9d9cff6bd728b17a24e163c9402775d9e6a365, oleans from
# `lake exe cache get`). Minus `sudo` and the `agent` user (EdgeBench images run as root).
#
# Lean tasks build FROM this image and point their project's `.lake/packages` at
# /home/workspace/baseline/.lake/packages (symlink) instead of copying it, so the
# ~7 GB Mathlib tree exists in exactly one shared layer.
#
# Build (needs network; GitHub + Mathlib cache server):
#   built by `sforge build` as base-lean-4.28.0-mathlib-8f9d9cf:<tree hash>

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
# elan v4.2.2 (commit 35628cce1, 2026-05-28): same `elan --version` as v1.
ARG ELAN_URL=https://github.com/leanprover/elan/releases/download/v4.2.2/elan-x86_64-unknown-linux-gnu.tar.gz
ARG ELAN_SHA256=40ec208731c4696ac80982ca29e7ad4c2c7c4fe410964d0131c581dd3240de79
# Lean v4.28.0 release tarball. Unpacked, it is file-for-file identical to v1's
# /opt/elan/toolchains/leanprover--lean4---v4.28.0 (12860 files, same sha256).
ARG LEAN_URL=https://github.com/leanprover/lean4/releases/download/v4.28.0/lean-4.28.0-linux.tar.zst
ARG LEAN_SHA256=ceb3a3f844f7aebf63245e2b51c28d5b0ed38942c19f93cf3febd520302160bd
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
# Ubuntu archive snapshot taken just before the v1 base was built (2026-06-17
# ~12:12 UTC), so every version equals the published image (dpkg-query on
# edgebench.base.lean_4_28_0_main:fca39c54aec8). apt verifies the GPG-signed
# InRelease and every .deb's sha256; only the bootstrap step (index fetch +
# ca-certificates, the stock image has no CA bundle) skips TLS peer checks.
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
COPY --from=fetch /out/toolchain /opt/elan/toolchains/leanprover--lean4---v4.28.0

WORKDIR /home/workspace
# Same command as v1. Integrity: git checks out the commit hashes pinned by
# Mathlib v4.28.0; the generated lake-manifest.json must equal the published v1
# manifest byte for byte; every package HEAD must equal its manifest rev; and
# `lake build --no-build Mathlib` proves the downloaded oleans are complete and
# up to date (it fails if anything would need rebuilding).
ARG MANIFEST_SHA256=12b2bbd2636ff7aa03e6936795d6f3dba727576cc0f600e0b7d4ca277d1112a0
RUN set -eux; \
    lake +leanprover/lean4:v4.28.0 new baseline math; \
    cd baseline; \
    echo "$MANIFEST_SHA256  lake-manifest.json" | sha256sum -c; \
    for n in $(jq -r '.packages[].name' lake-manifest.json); do \
      want=$(jq -r --arg n "$n" '.packages[] | select(.name==$n) | .rev' lake-manifest.json); \
      have=$(git -C ".lake/packages/$n" rev-parse HEAD); \
      [ "$want" = "$have" ] || { echo "rev mismatch: $n $have != $want"; exit 1; }; \
    done; \
    lake build --no-build Mathlib

# The oleans come from `lake exe cache get`; pin them as one combined hash (8018 files).
ARG OLEANS_SHA256=de2f7878ed3bc4fa3337067baaaa24274681173404caf53e17f589db1adbf5f7
RUN cd baseline && find .lake/packages -name '*.olean' -type f | LC_ALL=C sort \
    | xargs -d '\n' sha256sum | sha256sum | grep -q "^$OLEANS_SHA256 "

ENTRYPOINT []
CMD ["/bin/bash"]
