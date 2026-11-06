#!/bin/sh
# v1 setup_cmds[0] (identical in v1 work and judge):
#   apt-get install -y --no-install-recommends build-essential cmake ninja-build pkg-config git curl
#       wget xz-utils unzip nasm yasm python3 python3-pip python3-numpy ca-certificates
# from the Ubuntu snapshot of v1's build day (2026-06-09); the packages new to this layer are
# pinned to the versions in the published v1 image. Packages already in bases/cpp stay at the
# base's versions (see NOTES.md).
set -eux
SNAP="${UBUNTU_TASK_SNAPSHOT:-20260609T120000Z}"
cp /etc/apt/sources.list /etc/apt/sources.list.base
sed -i -E "s|(snapshot\.ubuntu\.com/ubuntu/)[0-9]{8}T[0-9]{6}Z|\1${SNAP}|" /etc/apt/sources.list
apt-get update
apt-get install -y --no-install-recommends \
    build-essential cmake ninja-build=1.10.1-1 pkg-config git curl wget=1.21.2-2ubuntu1.1 xz-utils \
    unzip=6.0-26ubuntu3.2 nasm=2.15.05-1 yasm=1.3.0-2.1 python3=3.10.6-1~22.04.1 \
    python3-pip=22.0.2+dfsg-1ubuntu0.7 python3-numpy=1:1.21.5-1ubuntu22.04.1 \
    python3.10=3.10.12-1~22.04.15 ca-certificates
mv /etc/apt/sources.list.base /etc/apt/sources.list
rm -rf /var/lib/apt/lists/*

