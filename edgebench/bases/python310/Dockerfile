# EdgeBench base image: python310
#
# Reproduces the v1 `edgebench.base.python310` toolchain layer (BENCHMARK.yaml
# `python310`: python:3.10 + git curl jq build-essential), minus `sudo` and the
# `agent` user (EdgeBench images run as root).
#
# FROM = python:3.10 (Python 3.10.20, Debian trixie), the exact build under the
# published v1 image (all 7 rootfs diff_ids match, top sha256:4fe3b08b...f421).
FROM python:3.10@sha256:11a7f29da0d339f0bbf647555e082015da58509f493f196ddc3512858f0311f3

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# apt is pinned to the Debian snapshot of the v1 base build time (2026-06-09
# 06:04 UTC), so every version equals the published image. apt verifies the
# GPG-signed InRelease and every .deb's sha256. The stock sources file is
# restored afterwards so /etc/apt matches the upstream image.
ARG DEBIAN_SNAPSHOT=20260609T060000Z
RUN set -eux; \
    cp /etc/apt/sources.list.d/debian.sources /tmp/debian.sources.orig; \
    sed -i -e "s|http://deb.debian.org/debian-security|http://snapshot.debian.org/archive/debian-security/${DEBIAN_SNAPSHOT}|" \
           -e "s|http://deb.debian.org/debian\$|http://snapshot.debian.org/archive/debian/${DEBIAN_SNAPSHOT}|" \
           /etc/apt/sources.list.d/debian.sources; \
    apt-get -o Acquire::Check-Valid-Until=false update; \
    apt-get install -y --no-install-recommends \
      git=1:2.47.3-0+deb13u1 \
      curl=8.14.1-2+deb13u3 \
      jq=1.7.1-6+deb13u2 \
      build-essential=12.12; \
    mv /tmp/debian.sources.orig /etc/apt/sources.list.d/debian.sources; \
    rm -rf /var/lib/apt/lists/*; \
    git config --global safe.directory '*'

CMD ["python3"]
