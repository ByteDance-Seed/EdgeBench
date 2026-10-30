# EdgeBench base image: python
#
# Reproduces the v1 `edgebench.base.python` toolchain layer (BENCHMARK.yaml
# `python`: python:3.11 + git curl jq build-essential), minus `sudo` and the
# `agent` user (EdgeBench images run as root).
#
# FROM = python:3.11 (Python 3.11.15, Debian trixie, built 2026-05-08), the exact
# linux/amd64 build under the
# published v1 image (all 7 rootfs diff_ids match, top sha256:dbecdc58...d707).
# Pinned by its platform manifest digest (the multi-arch index digest of this
# build changed several times while the amd64 image stayed the same).
FROM python:3.11@sha256:5359ebb07451406650903c2e97103ed598a2b1fe20da5a227e3eb6b3b5973e14

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# apt is pinned to the Debian snapshot of the v1 base build time (2026-06-17
# 12:15 UTC), so every version equals the published image. apt verifies the
# GPG-signed InRelease and every .deb's sha256. The stock sources file is
# restored afterwards so /etc/apt matches the upstream image.
ARG DEBIAN_SNAPSHOT=20260617T120000Z
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
