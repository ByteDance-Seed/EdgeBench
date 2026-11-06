# EdgeBench base image: lean-4.29.0-mathlib-8a17838
#
# Same recipe as bases/lean-4.28.0-mathlib-8f9d9cf, for Lean v4.29.0:
# ubuntu:22.04 + git curl jq build-essential gcc g++ python3 make procps
# ca-certificates (the v1 `lean_4` / `lean_4_28_0_main` package set), elan 4.2.2 in
# /opt/elan, the Lean v4.29.0 toolchain, and the Mathlib project
# /home/workspace/baseline made by `lake +leanprover/lean4:v4.29.0 new baseline math`
# (Mathlib tag v4.29.0 = 8a178386ffc0f5fef0b77738bb5449d50efeea95, oleans from
# `lake exe cache get`). Minus `sudo` and the `agent` user (EdgeBench images run as root).
# First user: pfr_formalization (v1 base `lean_4`, which ran `lake exe cache get`
# inside the task project instead; its oleans equal the ones pinned below).
#
# Lean tasks build FROM this image and point their project's `.lake/packages` at
# /home/workspace/baseline/.lake/packages (symlink) instead of copying it, so the
# ~7 GB Mathlib tree exists in exactly one shared layer.
#
# Build (needs network; GitHub + Mathlib cache server):
#   built by `sforge build` as base-lean-4.29.0-mathlib-8a17838:<tree hash>

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
# elan v4.2.2 (commit 35628cce1, 2026-05-28): its binary is byte-identical to the
# /opt/elan/bin/elan of the v1 pfr_formalization images (sha256 dee1f289...).
ARG ELAN_URL=https://github.com/leanprover/elan/releases/download/v4.2.2/elan-x86_64-unknown-linux-gnu.tar.gz
ARG ELAN_SHA256=40ec208731c4696ac80982ca29e7ad4c2c7c4fe410964d0131c581dd3240de79
# Lean v4.29.0 release tarball (unpacked: compared with v1's
# /opt/elan/toolchains/leanprover--lean4---v4.29.0, see NOTES.md).
ARG LEAN_URL=https://github.com/leanprover/lean4/releases/download/v4.29.0/lean-4.29.0-linux.tar.zst
ARG LEAN_SHA256=089f7e513ed3e9436d191f4986330c0b53809c86b5997f5eb7f25550c374fa48
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
# edgebench.base.lean_4_28_0_main:fca39c54aec8, the same list as v1 `lean_4`). apt verifies the GPG-signed
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
COPY --from=fetch /out/toolchain /opt/elan/toolchains/leanprover--lean4---v4.29.0

WORKDIR /home/workspace
# Same command as the lean-4.28.0 base (v1 `lean_4_28_0_main`). Integrity: git checks
# out the commit hashes pinned by Mathlib v4.29.0; the generated lake-manifest.json
# must have the pinned sha256; every package HEAD must equal its manifest rev; and
# `lake build --no-build Mathlib` proves the downloaded oleans are complete and up
# to date (it fails if anything would need rebuilding).
# (Retried up to 3 times: GitHub clones through the build proxy fail intermittently.)
RUN set -eux; \
    for i in 1 2 3; do \
      lake +leanprover/lean4:v4.29.0 new baseline math && break; \
      rm -rf baseline; [ "$i" -lt 3 ] || exit 1; sleep 30; \
    done

ARG MANIFEST_SHA256=88e2a097956efde7cfa815e600daea7d93988ac8be556dc9a3a403da5f3a53ae
RUN set -eux; \
    cd baseline; \
    sha256sum lake-manifest.json; \
    echo "$MANIFEST_SHA256  lake-manifest.json" | sha256sum -c; \
    for n in $(jq -r '.packages[].name' lake-manifest.json); do \
      want=$(jq -r --arg n "$n" '.packages[] | select(.name==$n) | .rev' lake-manifest.json); \
      have=$(git -C ".lake/packages/$n" rev-parse HEAD); \
      [ "$want" = "$have" ] || { echo "rev mismatch: $n $have != $want"; exit 1; }; \
    done; \
    lake build --no-build Mathlib

# The oleans come from `lake exe cache get`; pin them as one combined hash (8239 files).
# The two Lake config caches `.lake/config/*/lakefile.olean` (mathlib, proofwidgets) are
# left out: Lake regenerates them per workspace path. The same command over the nine
# Mathlib packages of v1's pfr workspace gives the same value.
ARG OLEANS_SHA256=57a1218883b63754d8db92fd3103727f97f2011e8b92fd93cfb2c6a81225e8f8
RUN cd baseline && find .lake/packages -name '*.olean' -type f -not -path '*/.lake/config/*' \
    | LC_ALL=C sort | xargs -d '\n' sha256sum | sha256sum | grep -q "^$OLEANS_SHA256 "

ENTRYPOINT []
CMD ["/bin/bash"]
