# EdgeBench base image: cpp
#
# Reproduces the v1 `edgebench.base.cpp` toolchain layer (BENCHMARK.yaml `cpp`:
# ubuntu:22.04 + git curl jq build-essential cmake gcc g++ libffi-dev pkg-config
# ca-certificates), minus `sudo` and the `agent` user (EdgeBench images run as root).
#
# FROM = ubuntu:jammy-20260509, the exact ubuntu:22.04 build under the published
# v1 images (rootfs diff_id sha256:8bba68e7...938d).
FROM ubuntu@sha256:4f838adc7181d9039ac795a7d0aba05a9bd9ecd480d294483169c5def983b64d

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# Packages come from the Ubuntu archive snapshot taken just before the v1 base
# was built (2026-06-17 12:12 UTC), so every version matches the published image.
# Integrity: apt verifies the GPG-signed InRelease of the snapshot and the
# sha256 of every .deb. snapshot.ubuntu.com is https-only and the stock image
# has no CA bundle, so only the first bootstrap step (index fetch +
# ca-certificates) skips TLS peer verification; GPG still covers it.
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
      cmake=3.22.1-1ubuntu1.22.04.2 \
      gcc=4:11.2.0-1ubuntu1 \
      g++=4:11.2.0-1ubuntu1 \
      libffi-dev=3.4.2-4 \
      pkg-config=0.29.2-1ubuntu3 \
      ca-certificates=20260601~22.04.1; \
    rm -rf /var/lib/apt/lists/*; \
    git config --global safe.directory '*'

WORKDIR /root
CMD ["/bin/bash"]
