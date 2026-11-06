#!/bin/sh
# Shared FFmpeg n7.1 build (v1 work setup_cmds[3..6], judge setup_cmds[3]).
# Usage: build_ffmpeg.sh work|judge
#   v1 cloned `--depth 1 --branch n7.1` of a GitHub mirror of FFmpeg whose tag n7.1 is the
#   upstream commit b08d7969c550a804a59511c7b83f2dd8cc0499b8. We fetch the upstream archive of
#   that commit (sha256-checked) and write VERSION=n7.1, which is what ffbuild/version.sh
#   derived from `git describe` in the v1 shallow clone (so the libraries report "n7.1").
#   work : build 1 (full, with ASM) -> /reference/ffmpeg; distclean; build 2 (--disable-asm,
#          static+shared+PIC) -> /usr/local; copy libswscale/libavutil/compat -> /reference/ffmpeg-src
#   judge: build 2 only.
set -eux
MODE="$1"
mkdir -p /build/ffmpeg-src
curl -fsSL -o /build/ffmpeg.tar.gz \
    https://github.com/FFmpeg/FFmpeg/archive/b08d7969c550a804a59511c7b83f2dd8cc0499b8.tar.gz
echo "02fa6d9827da3b6786e4df821218cc036db2b4481e7f48267c2dcda695633afc  /build/ffmpeg.tar.gz" | sha256sum -c -
tar xzf /build/ffmpeg.tar.gz -C /build/ffmpeg-src --strip-components=1
rm -f /build/ffmpeg.tar.gz
echo n7.1 > /build/ffmpeg-src/VERSION
cd /build/ffmpeg-src
if [ "$MODE" = work ]; then
    ./configure --prefix=/build/ffmpeg-full --enable-gpl --enable-static --disable-shared \
        --disable-doc --disable-ffplay --disable-ffprobe
    make -j"$(nproc)"
    make install
    mkdir -p /reference
    cp /build/ffmpeg-full/bin/ffmpeg /reference/ffmpeg
    chmod +x /reference/ffmpeg
    make distclean
fi
./configure --prefix=/usr/local --enable-gpl --enable-static --enable-shared --enable-pic \
    --disable-doc --disable-asm --disable-programs
make -j"$(nproc)"
make install
ldconfig
if [ "$MODE" = work ]; then
    mkdir -p /reference/ffmpeg-src
    cp -r /build/ffmpeg-src/libswscale /reference/ffmpeg-src/
    cp -r /build/ffmpeg-src/libavutil /reference/ffmpeg-src/
    cp -r /build/ffmpeg-src/compat /reference/ffmpeg-src/
fi
cd /
rm -rf /build/ffmpeg-src /build/ffmpeg-full
