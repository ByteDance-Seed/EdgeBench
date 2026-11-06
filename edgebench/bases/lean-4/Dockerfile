# EdgeBench base image: lean-4
#
# Reproduces the v1 `edgebench.base.lean_4` image (BENCHMARK.yaml `lean_4`):
# ubuntu:22.04 + git curl jq build-essential gcc g++ python3 make procps
# ca-certificates, elan in /opt/elan with no default toolchain, WORKDIR
# /home/workspace, ENTRYPOINT []. No Lean toolchain and no Mathlib: tasks install
# the toolchain they pin (or use a Mathlib base). Minus `sudo` and the `agent`
# user (EdgeBench images run as root, so /opt/elan is owned by root).
#
# FROM = ubuntu:jammy-20260509, the exact ubuntu:22.04 build under the published
# v1 image (rootfs diff_id sha256:8bba68e7...938d).
FROM ubuntu@sha256:4f838adc7181d9039ac795a7d0aba05a9bd9ecd480d294483169c5def983b64d

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# Ubuntu archive snapshot taken just before the v1 base was built (2026-06-17
# 12:14 UTC), so every version equals the published image. apt verifies the
# GPG-signed InRelease and every .deb's sha256; only the bootstrap step (index
# fetch + ca-certificates, the stock image has no CA bundle) skips TLS peer checks.
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
# elan v4.2.3 (commit b6cec7e10, 2026-06-08): the release v1's `elan-init.sh`
# installed; its elan-init binary has the same sha256 as v1's /opt/elan/bin/elan
# (840179e7...6385). The download lives in /tmp only within this step.
ARG ELAN_URL=https://github.com/leanprover/elan/releases/download/v4.2.3/elan-x86_64-unknown-linux-gnu.tar.gz
ARG ELAN_SHA256=df0b2b3a439961ffcbb3985214365ffe40f49bc871df04dff268c7d8e21ca8b2
RUN set -eux; d=$(mktemp -d); cd "$d"; \
    curl -fsSL -o elan.tar.gz "$ELAN_URL"; \
    echo "$ELAN_SHA256  elan.tar.gz" | sha256sum -c; \
    tar xzf elan.tar.gz; \
    ./elan-init -y --default-toolchain none; \
    cd /; rm -rf "$d"; \
    elan --version

# v1 set `USER root` explicitly (BENCHMARK.yaml user_directive); same here.
USER root
WORKDIR /home/workspace
ENTRYPOINT []
