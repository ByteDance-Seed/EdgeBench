#!/bin/sh
# Shared by environment/Dockerfile and judge/Dockerfile. Reproduces v1's
#   rustup toolchain install 1.88.0 && rustup default 1.88.0
# (work setup_cmds[2], judge setup_cmds[3]) with every fetch pinned. Same recipe as
# tasks/rust_multicrate_reconstruction/environment/setup_toolchain.sh minus its apt step
# (this task's v1 work image installs no apt packages, and the judge's `apt-get install python3`
# is a no-op on the base, which already ships python3 3.11.2):
#   * toolchain 1.88.0 is installed by the base's rustup 1.27.0 (as in v1; it also writes the
#     toolchain's multirust-*.toml metadata in 1.27's format), profile minimal from rustup
#     settings, then checked file-by-file against the v1 image (rust-1.88.0-toolchain.sha256;
#     /usr/local/rustup of this task's v1 images is identical to the pilot's);
#   * in v1 that same command then auto-self-updated rustup 1.27.0 -> 1.29.0, replacing the
#     hard-linked cargo/rustc/... proxies with symlinks, and `rustup default 1.88.0` ran under
#     1.29.0. We pass --no-self-update and install the exact rustup 1.29.0 binary (sha256-pinned).
set -eux
HERE="$(cd "$(dirname "$0")" && pwd)"

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
rustup default 1.88.0
rustup --version
rustc --version
cargo --version
