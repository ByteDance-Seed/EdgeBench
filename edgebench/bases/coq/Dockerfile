# EdgeBench base image: coq
#
# Reproduces the v1 `edgebench.base.coq` image (BENCHMARK.yaml `coq`:
# coqorg/coq:8.20 + git curl jq build-essential gcc g++ python3 make procps,
# USER root, opam switch bin on PATH, `chmod -R a+rX /home/coq/.opam`,
# ENTRYPOINT []), minus `sudo` and the `agent` user (EdgeBench images run as root).
#
# FROM = coqorg/coq:8.20 (Coq 8.20.1, OCaml 4.13.1+flambda, opam 2.3.0, Debian
# bookworm, built 2026-03-30), the exact build under the published v1 image (all
# 7 rootfs diff_ids match, top sha256:6e5d6f3a...c6f8).
FROM coqorg/coq:8.20@sha256:e50d77c4c5a9aa0d76ae1b343d79c5f922da3a75054b79c5dc635895438e4674

USER root
# As in v1: the image's `coq` user (uid 1000) is removed; /home/coq keeps its
# numeric owner 1000:1000 (in v1 that uid was reused by `agent`).
RUN userdel coq && groupdel coq 2>/dev/null; true

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# apt is pinned to the Debian snapshot of the v1 base build time (2026-06-17
# 12:10 UTC), so every version equals the published image. apt verifies the
# GPG-signed InRelease and every .deb's sha256. The stock sources file is
# restored afterwards so /etc/apt matches the upstream image.
# The upstream image ships `sudo`; it is purged (EdgeBench images have no sudo).
# The upstream image also ships an empty /tmp/opam-xxx-7; it is removed so the
# image leaves nothing under /tmp.
ARG DEBIAN_SNAPSHOT=20260617T120000Z
RUN set -eux; \
    cp /etc/apt/sources.list.d/debian.sources /root/debian.sources.orig; \
    sed -i -e "s|http://deb.debian.org/debian-security|http://snapshot.debian.org/archive/debian-security/${DEBIAN_SNAPSHOT}|" \
           -e "s|http://deb.debian.org/debian\$|http://snapshot.debian.org/archive/debian/${DEBIAN_SNAPSHOT}|" \
           /etc/apt/sources.list.d/debian.sources; \
    apt-get -o Acquire::Check-Valid-Until=false update; \
    apt-get install -y --no-install-recommends \
      git=1:2.39.5-0+deb12u3 \
      curl=7.88.1-10+deb12u14 \
      jq=1.6-2.1+deb12u1 \
      build-essential=12.9 \
      gcc=4:12.2.0-3 \
      g++=4:12.2.0-3 \
      python3=3.11.2-1+b1 \
      make=4.3-4.1 \
      procps=2:4.0.2-3; \
    SUDO_FORCE_REMOVE=yes apt-get purge -y sudo; \
    mv /root/debian.sources.orig /etc/apt/sources.list.d/debian.sources; \
    rm -rf /var/lib/apt/lists/* /tmp/* /tmp/.[!.]*; \
    git config --global safe.directory '*'

ENV PATH="/home/coq/.opam/${COMPILER}/bin:${PATH}"
RUN chmod -R a+rX /home/coq/.opam
ENTRYPOINT []
