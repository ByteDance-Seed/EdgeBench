# Work image for ffmpeg_swscale_reimplementation (v1: edgebench.work.ffmpeg_swscale_reimplementation:0557f5e37b71).
# Build context = the task directory:
#   sforge build --task ffmpeg_swscale_reimplementation
#
# v1 work.setup_cmds -> this file:
#   0    apt packages                                           -> environment/setup_apt.sh (pinned)
#   1-2  Zig 0.14.0, rustup stable + nightly                    -> environment/setup_toolchain.sh (pinned)
#   3-6  FFmpeg n7.1: full build -> /reference/ffmpeg; --disable-asm build -> /usr/local;
#        libswscale/libavutil/compat -> /reference/ffmpeg-src   -> environment/build_ffmpeg.sh work
#   7    sparse clone of the original task repo                 -> files committed under environment/
#   8    workspace files, /app -> /home/workspace, build.zig linkLibC sed
#                                                                -> COPY environment/workspace/ (sed already applied)
#   9    heredoc scaffold/rust/src/lib.rs; copy scaffold/rust into swscale-impl
#                                                                -> lib.rs committed; cp below
#   10   gcc baseline wrapper -> libswscale_public_baseline.so   -> RUN below
#   11   prepare_media.py; copy media into swscale-impl          -> RUN below (prepare_media.py is build-only)
#   12   results dirs (777)                                      -> RUN below (/tmp/verifier dropped: nothing ships under /tmp)
#   13   rm -rf /tmp/assets                                      -> nothing to remove
#   14   git init + "init" commit in swscale-impl                -> RUN below, author/dates pinned to v1
#   (template) chown -R agent:agent swscale-impl; USER agent    -> dropped (root)

# Base = bases/cpp (sforge build passes it as BASE_IMAGE).
ARG BASE_IMAGE
FROM ${BASE_IMAGE}
ARG DEBIAN_FRONTEND=noninteractive

COPY environment/setup_apt.sh /tmp/ebv-setup/
RUN sh /tmp/ebv-setup/setup_apt.sh
COPY environment/setup_toolchain.sh environment/build_ffmpeg.sh /tmp/ebv-setup/
RUN sh /tmp/ebv-setup/setup_toolchain.sh
RUN sh /tmp/ebv-setup/build_ffmpeg.sh work && rm -rf /tmp/ebv-setup

COPY environment/workspace/ /home/workspace/
COPY environment/prepare_media.py /root/ebv-prepare_media.py
RUN set -eux; \
    mkdir -p /home/workspace/swscale-impl /home/workspace/media; \
    ln -sfn /home/workspace /app; \
    cp -a /home/workspace/scaffold/rust/. /home/workspace/swscale-impl/; \
    gcc -shared -fPIC -O2 -o /home/workspace/libswscale_public_baseline.so /home/workspace/baseline_wrapper.c \
        -I/usr/local/include -Wl,--whole-archive /usr/local/lib/libswscale.a -Wl,--no-whole-archive \
        /usr/local/lib/libavutil.a -lm -lpthread; \
    python3 /root/ebv-prepare_media.py; \
    rm -f /root/ebv-prepare_media.py; \
    cp -a /home/workspace/media /home/workspace/swscale-impl/media; \
    mkdir -p /home/workspace/results /home/workspace/swscale-impl/results; \
    chmod 777 /home/workspace/results /home/workspace/swscale-impl/results; \
    test -w /app/results && test -w /home/workspace/results && test -w /home/workspace/swscale-impl/results

WORKDIR /home/workspace/swscale-impl
# v1 setup_cmds[14]: fresh repo with one "init" commit; author and dates pinned to v1's commit
# (d05836fa..., 2026-06-09T12:53:47Z), so the commit hash is reproduced when the tree matches.
RUN git init -q && git config user.email 'sebench@local' && git config user.name 'sebench' \
 && git add -A \
 && GIT_AUTHOR_DATE='2026-06-09T12:53:47+00:00' GIT_COMMITTER_DATE='2026-06-09T12:53:47+00:00' \
    git commit -q -m 'init' --allow-empty \
 && git log --format='%H %s' -1

CMD ["/bin/bash"]
