#!/bin/sh
# Task apt layer shared by the work and judge images (v1 setup_cmds[0]).
#   setup.sh work | judge
# apt: the base's dated Ubuntu snapshot (bases/cpp, 20260617T120000Z); the explicitly
# requested packages are pinned to the versions in the published v1 images.
set -eux
role=$1
export DEBIAN_FRONTEND=noninteractive

pkgs="wget=1.21.2-2ubuntu1.1 xz-utils=5.2.5-2ubuntu1.1 python3=3.10.6-1~22.04.1 zlib1g-dev=1:1.2.11.dfsg-2ubuntu9.2"
if [ "$role" = judge ]; then
    pkgs="$pkgs strace=5.16-0ubuntu3 file=1:5.41-3ubuntu0.1 libssl-dev=3.0.2-0ubuntu1.25 libcurl4-openssl-dev=7.81.0-1ubuntu1.24"
fi
apt-get update -qq
# shellcheck disable=SC2086
apt-get install -y --no-install-recommends -qq $pkgs
rm -rf /var/lib/apt/lists/*
