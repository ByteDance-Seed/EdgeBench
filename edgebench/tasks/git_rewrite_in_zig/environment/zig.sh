#!/bin/sh
# Zig 0.14.0 for linux x86_64 (v1 setup_cmds[1]): ziglang.org release tarball, sha256 from
# https://ziglang.org/download/index.json. Unpacked as root with plain `tar xf`, so the
# archive's uid/gid 1000 are kept, as in v1. Result: /usr/local/zig (symlink added later).
set -eux
cd /root
curl -fsSL --retry 3 -o zig-linux-x86_64-0.14.0.tar.xz https://ziglang.org/download/0.14.0/zig-linux-x86_64-0.14.0.tar.xz
echo "473ec26806133cf4d1918caf1a410f8403a13d979726a9045b421b685031a982  zig-linux-x86_64-0.14.0.tar.xz" | sha256sum -c -
tar xf zig-linux-x86_64-0.14.0.tar.xz
mv zig-linux-x86_64-0.14.0 /usr/local/zig
rm zig-linux-x86_64-0.14.0.tar.xz
