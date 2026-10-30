#!/bin/sh
# v1 setup_cmds[0] (identical in v1 work and judge):
#   apt-get update && apt-get install -y --no-install-recommends nodejs npm wget && rm -rf /var/lib/apt/lists/*
# Here apt reads the Debian snapshot of v1's build time (the v1 images were built 2026-06-11
# 08:58 UTC). apt verifies the signed InRelease and every .deb's sha256. The three requested
# packages are pinned to the versions in the published v1 image, and afterwards every package
# that v1's step added (environment/node-packages.lock, 361 packages: nodejs, npm and their
# Debian node-* dependencies) is checked to be installed at exactly v1's version.
# `wget` is already in bases/python at v1's version (1.25.0-2). The stock sources file is restored.
set -eux
SNAP="${DEBIAN_TASK_SNAPSHOT:-20260611T080000Z}"
LOCK="$(dirname "$0")/node-packages.lock"
cp /etc/apt/sources.list.d/debian.sources /tmp/debian.sources.orig
sed -i -e "s|http://deb.debian.org/debian-security|http://snapshot.debian.org/archive/debian-security/${SNAP}|" \
       -e "s|http://deb.debian.org/debian\$|http://snapshot.debian.org/archive/debian/${SNAP}|" \
       /etc/apt/sources.list.d/debian.sources
apt-get -o Acquire::Check-Valid-Until=false update
apt-get install -y --no-install-recommends \
    nodejs=20.19.2+dfsg-1+deb13u2 npm=9.2.0~ds1-3 wget=1.25.0-2
mv /tmp/debian.sources.orig /etc/apt/sources.list.d/debian.sources
rm -rf /var/lib/apt/lists/*
dpkg-query -W -f '${Package}:${Architecture}=${Version}\n' | sort > /tmp/installed.txt
missing="$(sort "$LOCK" | comm -23 - /tmp/installed.txt)"
rm -f /tmp/installed.txt
if [ -n "$missing" ]; then echo "packages not at v1 versions:"; echo "$missing"; exit 1; fi
