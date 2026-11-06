#!/bin/sh
# Shared by environment/Dockerfile and judge/Dockerfile. Reproduces v1 setup_cmds[0..2]
# (identical in v1 work and judge), with every fetch pinned:
#   0 apt packages -> environment/setup_apt.sh
#   1 Zig 0.14.0 tarball -> same URL, sha256-checked.
#   2 `curl https://sh.rustup.rs | sh` + `rustup default stable` + `rustup toolchain install nightly`
#       -> rustup-init 1.29.0 (the version in the v1 image, sha256-checked), then the stable and
#       nightly channels as they were on 2026-06-09 (stable = 1.96.0 dist 2026-05-28,
#       nightly = dist 2026-06-09), installed under their dated names and renamed to the v1
#       names `stable-…`/`nightly-…`. rustup verifies every component against the channel
#       manifest, and the manifests themselves are sha256-checked below.
set -eux

# ---- 1: Zig 0.14.0 ----
curl -fsSL -o /tmp/zig.tar.xz https://ziglang.org/download/0.14.0/zig-linux-x86_64-0.14.0.tar.xz
echo "473ec26806133cf4d1918caf1a410f8403a13d979726a9045b421b685031a982  /tmp/zig.tar.xz" | sha256sum -c -
tar xJf /tmp/zig.tar.xz -C /opt
rm -f /tmp/zig.tar.xz
ln -sf /opt/zig-linux-x86_64-0.14.0/zig /usr/local/bin/zig
zig version

# ---- 2: Rust (rustup 1.29.0, stable 1.96.0, nightly 2026-06-09) ----
export CARGO_HOME=/usr/local/cargo RUSTUP_HOME=/usr/local/rustup PATH=/usr/local/cargo/bin:$PATH
curl -fsSL -o /tmp/rustup-init \
    https://static.rust-lang.org/rustup/archive/1.29.0/x86_64-unknown-linux-gnu/rustup-init
echo "4acc9acc76d5079515b46346a485974457b5a79893cfb01112423c89aeb5aa10  /tmp/rustup-init" | sha256sum -c -
chmod 755 /tmp/rustup-init
/tmp/rustup-init -y --no-modify-path --profile default --default-toolchain none
rm -f /tmp/rustup-init
T=x86_64-unknown-linux-gnu
for pair in stable:2026-05-28 nightly:2026-06-09; do
    ch=${pair%%:*}; d=${pair#*:}
    rustup toolchain install --no-self-update --profile default "$ch-$d"
    mv "$RUSTUP_HOME/toolchains/$ch-$d-$T" "$RUSTUP_HOME/toolchains/$ch-$T"
    mv "$RUSTUP_HOME/update-hashes/$ch-$d-$T" "$RUSTUP_HOME/update-hashes/$ch-$T"
done
sha256sum -c - <<SUMS
05f944dcb8056d866baef94e971ecad5804e6e52ac88518cbbb2c20d06461624  $RUSTUP_HOME/toolchains/stable-$T/lib/rustlib/multirust-channel-manifest.toml
3a239f398cc9d00d5f40edae7888aae837be87ec2ef67a3e9a6a0144b96e06f8  $RUSTUP_HOME/toolchains/nightly-$T/lib/rustlib/multirust-channel-manifest.toml
SUMS
rustup default stable
ln -sf /usr/local/cargo/bin/cargo /usr/local/bin/cargo
ln -sf /usr/local/cargo/bin/rustc /usr/local/bin/rustc
ln -sf /usr/local/cargo/bin/rustup /usr/local/bin/rustup
printf 'export CARGO_HOME=/usr/local/cargo\nexport RUSTUP_HOME=/usr/local/rustup\nexport PATH=/usr/local/cargo/bin:$PATH\n' > /etc/profile.d/rust.sh
chmod -R a+rX /usr/local/cargo /usr/local/rustup
cargo --version
rustc --version
rustc +nightly --version
rustup --version
