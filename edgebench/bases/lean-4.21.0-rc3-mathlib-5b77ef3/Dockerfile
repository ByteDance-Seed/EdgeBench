# EdgeBench base image: lean-4.21.0-rc3-mathlib-5b77ef3
#
# Toolchain + Mathlib for the con-nf project (new_foundations_consistency). v1 had no
# such base: the task ran on `edgebench.base.lean_4` (elan only) and each of its work
# and judge images ran `lake exe cache get && lake build` inside its own copy of the
# project, so both carried a private ~5.3 GB `.lake/packages`. Here the packages live
# once, in /home/workspace/baseline, and the task links `.lake/packages` to them.
#
# Contents: ubuntu:22.04 + the v1 `lean_4` apt set (git curl jq build-essential gcc g++
# python3 make procps ca-certificates; same versions), elan 4.2.2 in /opt/elan (the
# elan v1's con-nf images carry), Lean v4.21.0-rc3, and /home/workspace/baseline: a
# project whose lake-manifest.json lists exactly con-nf's packages (Mathlib
# 5b77ef3c3fcca1da8ca4f54da448f092cc629f8d, doc-gen4 86d735ec... and their
# dependencies), fetched with `lake exe cache get` (Mathlib oleans from the public cache).
# doc-gen4 and its own dependencies (Cli, UnicodeBasic, BibtexQuery, MD4Lean) are only
# checked out, not built, as in v1 (con-nf's default target does not need them).
#
# Build (needs network; GitHub + Mathlib cache server):
#   built by `sforge build` as base-lean-4.21.0-rc3-mathlib-5b77ef3:<tree hash>

# ------------------------------------------------------------------ fetch stage
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
# elan v4.2.2 (35628cce1, 2026-05-28): its elan-init is byte-identical to the
# /opt/elan/bin/elan of v1's con-nf images (dee1f289...).
ARG ELAN_URL=https://github.com/leanprover/elan/releases/download/v4.2.2/elan-x86_64-unknown-linux-gnu.tar.gz
ARG ELAN_SHA256=40ec208731c4696ac80982ca29e7ad4c2c7c4fe410964d0131c581dd3240de79
# Lean v4.21.0-rc3 release tarball. Unpacked, it is file-for-file identical to v1's
# /opt/elan/toolchains/leanprover--lean4---v4.21.0-rc3 (5698 files, same sha256).
ARG LEAN_URL=https://github.com/leanprover/lean4/releases/download/v4.21.0-rc3/lean-4.21.0-rc3-linux.tar.zst
ARG LEAN_SHA256=f5ce69e27b2fc2540088fe364ac280f2b97f15c8fa2673e79da1114921980021
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
# Same snapshot and versions as bases/lean-4 (dpkg list equal to v1's con-nf images).
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
COPY --from=fetch /dl/elan-init /usr/local/bin/elan-init
RUN set -eux; elan-init -y --default-toolchain none; rm /usr/local/bin/elan-init; elan --version
COPY --from=fetch /out/toolchain /opt/elan/toolchains/leanprover--lean4---v4.21.0-rc3

# The baseline project: con-nf's lean-toolchain, its two [[require]]s and its
# lake-manifest.json (only the root "name" changed to "baseline").
COPY baseline /home/workspace/baseline
WORKDIR /home/workspace/baseline
# Integrity (package dir names drop Lake's «» quoting, e.g. «doc-gen4» -> doc-gen4):
# git checks out the commits pinned in the manifest; every package HEAD
# must equal its manifest rev; `lake build --no-build Mathlib` proves the downloaded
# oleans are complete and up to date; the manifest must be unchanged afterwards.
ARG MANIFEST_SHA256=4018bd8f58b129a9aa93fb2f88ec7c5b17e36ad057071d2d399e98d97041684e
RUN set -eux; \
    echo "$MANIFEST_SHA256  lake-manifest.json" | sha256sum -c; \
    lake exe cache get; \
    echo "$MANIFEST_SHA256  lake-manifest.json" | sha256sum -c; \
    for n in $(jq -r '.packages[].name | ltrimstr("«") | rtrimstr("»")' lake-manifest.json); do \
      want=$(jq -r --arg n "$n" '.packages[] | select((.name | ltrimstr("«") | rtrimstr("»")) == $n) | .rev' lake-manifest.json); \
      have=$(git -C ".lake/packages/$n" rev-parse HEAD); \
      [ "$want" = "$have" ] || { echo "rev mismatch: $n $have != $want"; exit 1; }; \
    done; \
    lake build --no-build Mathlib

# The oleans come from `lake exe cache get`; pin them as one combined hash (6860 files,
# equal to the value computed over .lake/packages in both v1 con-nf images).
ARG OLEANS_SHA256=3e35c7565102fc056bdfc346f71b07807ed6aa77b7109e8add09cb84939bb984
RUN cd /home/workspace/baseline && find .lake/packages -name '*.olean' -type f | LC_ALL=C sort \
    | xargs -d '\n' sha256sum | sha256sum | tee /dev/stderr | grep -q "^$OLEANS_SHA256 "

USER root
WORKDIR /home/workspace
ENTRYPOINT []
CMD ["/bin/bash"]
