#!/bin/sh
# Shared by environment/Dockerfile and judge/Dockerfile. Reproduces v1 setup_cmds[1]
# (identical in v1 work and judge):
#   apt-get install -y --no-install-recommends curl tar gzip clang lld libsqlite3-dev pkg-config \
#       build-essential python3 jq && rustup toolchain install 1.88.0 && rustup default 1.88.0
# with every fetch pinned:
#   * apt from the Debian snapshot of v1's build day (2026-06-09);
#   * toolchain 1.88.0 is installed by the base's rustup 1.27.0 (as in v1; it also writes the
#     toolchain's multirust-*.toml metadata in 1.27's format), profile minimal from rustup
#     settings, then checked file-by-file against the v1 image (rust-1.88.0-toolchain.sha256);
#   * in v1 that same command then auto-self-updated rustup 1.27.0 -> 1.29.0 (latest on
#     2026-06-09), replacing the hard-linked cargo/rustc/... proxies with symlinks, and the next
#     command (`rustup default 1.88.0`) ran under 1.29.0. We pass --no-self-update and install
#     the exact rustup 1.29.0 binary (sha256-pinned) the same way.
set -eux
SNAP="${DEBIAN_SNAPSHOT:-20260609T120000Z}"
HERE="$(cd "$(dirname "$0")" && pwd)"

cp /etc/apt/sources.list.d/debian.sources /tmp/debian.sources.orig
sed -i -e "s|http://deb.debian.org/debian-security|http://snapshot.debian.org/archive/debian-security/${SNAP}|" \
       -e "s|http://deb.debian.org/debian\$|http://snapshot.debian.org/archive/debian/${SNAP}|" \
       /etc/apt/sources.list.d/debian.sources
apt-get -o Acquire::Check-Valid-Until=false update
apt-get install -y --no-install-recommends curl tar gzip clang lld libsqlite3-dev pkg-config \
    build-essential python3 jq
mv /tmp/debian.sources.orig /etc/apt/sources.list.d/debian.sources
rm -rf /var/lib/apt/lists/*

rustup toolchain install --no-self-update 1.88.0
sha256sum -c --quiet "$HERE/rust-1.88.0-toolchain.sha256"

curl -fsSL -o /tmp/rustup-init \
    https://static.rust-lang.org/rustup/archive/1.29.0/x86_64-unknown-linux-gnu/rustup-init
echo "4acc9acc76d5079515b46346a485974457b5a79893cfb01112423c89aeb5aa10  /tmp/rustup-init" | sha256sum -c -
cd /usr/local/cargo/bin
install -m 0755 /tmp/rustup-init rustup
rm -f /tmp/rustup-init
for p in cargo cargo-clippy cargo-fmt cargo-miri clippy-driver rls rust-analyzer rust-gdb \
         rust-gdbgui rust-lldb rustc rustdoc rustfmt; do
    ln -sf rustup "$p"
done
cd /
# v1 ran `rustup default 1.88.0` after the self-update, i.e. with rustup 1.29.0.
rustup default 1.88.0
rustup --version
rustc --version
cargo --version
