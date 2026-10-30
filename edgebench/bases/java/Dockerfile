# EdgeBench base image: java
#
# Reproduces the v1 `edgebench.base.java` toolchain layer (BENCHMARK.yaml `java`:
# maven:3.9-eclipse-temurin-17 + git curl jq build-essential ant unzip python3),
# minus `sudo` and the `agent` user (EdgeBench images run as root).
#
# FROM = maven:3.9-eclipse-temurin-17 (Maven 3.9, Temurin jdk-17.0.19+10, Ubuntu
# 24.04, built 2026-06-02), the exact linux/amd64 build under the published v1
# image (all 10 rootfs diff_ids match, top sha256:dc9919d4...7044). Pinned by its
# platform manifest digest.
FROM maven:3.9-eclipse-temurin-17@sha256:9f43af45b81b1505b907768c55da4e3df34064267c89354d0707c827e79de949

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# apt is pinned to the Ubuntu archive snapshot of the v1 base build time
# (2026-06-17 12:13 UTC), so every version equals the published image. apt
# verifies the GPG-signed InRelease and every .deb's sha256. The stock sources
# file is restored afterwards so /etc/apt matches the upstream image.
# As in v1, `ant` pulls in default-jre-headless (openjdk-21-jre-headless); the
# JDK on PATH stays Temurin 17 (/opt/java/openjdk/bin comes first).
# The upstream image ships an empty /tmp/hsperfdata_root; it is removed so the
# image leaves nothing under /tmp.
ARG UBUNTU_SNAPSHOT=20260617T120000Z
RUN set -eux; \
    cp /etc/apt/sources.list.d/ubuntu.sources /root/ubuntu.sources.orig; \
    sed -i -e "s|http://archive.ubuntu.com/ubuntu/|https://snapshot.ubuntu.com/ubuntu/${UBUNTU_SNAPSHOT}/|" \
           -e "s|http://security.ubuntu.com/ubuntu/|https://snapshot.ubuntu.com/ubuntu/${UBUNTU_SNAPSHOT}/|" \
           /etc/apt/sources.list.d/ubuntu.sources; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      git=1:2.43.0-1ubuntu7.3 \
      curl=8.5.0-2ubuntu10.9 \
      jq=1.7.1-3ubuntu0.24.04.2 \
      build-essential=12.10ubuntu1 \
      ant=1.10.14-1 \
      unzip=6.0-28ubuntu4.1 \
      python3=3.12.3-0ubuntu2.1; \
    mv /root/ubuntu.sources.orig /etc/apt/sources.list.d/ubuntu.sources; \
    rm -rf /var/lib/apt/lists/* /tmp/* /tmp/.[!.]*; \
    git config --global safe.directory '*'
