# Judge image for ffmpeg_swscale_reimplementation (v1: edgebench.judge.ffmpeg_swscale_reimplementation:d3c0aa3fa987).
# Build context = the task directory:
#   sforge build --task ffmpeg_swscale_reimplementation
#
# v1 judge.setup_cmds -> this file:
#   0    apt packages                                           -> environment/setup_apt.sh (pinned)
#   1-2  Zig 0.14.0, rustup stable + nightly                    -> environment/setup_toolchain.sh (pinned)
#   3    FFmpeg n7.1 --disable-asm build -> /usr/local          -> environment/build_ffmpeg.sh judge
#   4    sparse clone of the original task repo; tests -> /opt/tests; workspace helpers copied to
#        /opt/tests and /tmp                                     -> COPY judge/tests/ + environment/workspace/ files;
#                                                                   the two /tmp copies now live in /judge/
#   5    baseline .so -> /verifier-data (+ sha256) and /home/workspace/libswscale_public_baseline.so
#                                                                -> RUN below (compiled from /judge/baseline_wrapper.c)
#   6    git init + empty "init" commit in swscale-impl          -> RUN below, dates pinned to v1
#   7    heredoc /opt/tests/pytest_shim.sh (SE-bench-harness version) -> judge/tests/pytest_shim.sh (byte-identical)
#   v1 eval_cmd + parser pytest_v                               -> judge/eval.sh (v1's generated eval.sh) + judge/run.sh + judge/grade.py

ARG BASE_IMAGE
FROM ${BASE_IMAGE}
ARG DEBIAN_FRONTEND=noninteractive

COPY environment/setup_apt.sh /tmp/ebv-setup/
RUN sh /tmp/ebv-setup/setup_apt.sh
COPY environment/setup_toolchain.sh environment/build_ffmpeg.sh /tmp/ebv-setup/
RUN sh /tmp/ebv-setup/setup_toolchain.sh
RUN sh /tmp/ebv-setup/build_ffmpeg.sh judge && rm -rf /tmp/ebv-setup

COPY judge/tests/ /opt/tests/
COPY environment/workspace/pixel_formats.py environment/workspace/baseline_wrapper.c \
     environment/workspace/swscale_api.h environment/workspace/verify_correctness.py \
     environment/workspace/run_dev_bench.py /opt/tests/
COPY environment/workspace/pixel_formats.py environment/workspace/baseline_wrapper.c /judge/
COPY judge/run.sh judge/eval.sh judge/grade.py /judge/
RUN set -eux; \
    chmod +x /opt/tests/*.sh; \
    chmod 755 /judge/run.sh /judge/eval.sh; \
    mkdir -p /home/workspace/swscale-impl /verifier-data; \
    ln -sfn /home/workspace /app; \
    gcc -shared -fPIC -O2 -o /verifier-data/libswscale_baseline.so /judge/baseline_wrapper.c \
        -I/usr/local/include -Wl,--whole-archive /usr/local/lib/libswscale.a -Wl,--no-whole-archive \
        /usr/local/lib/libavutil.a -lm -lpthread; \
    cp /verifier-data/libswscale_baseline.so /home/workspace/libswscale_public_baseline.so; \
    sha256sum /verifier-data/libswscale_baseline.so | awk '{print $1}' > /verifier-data/baseline_hash.txt

WORKDIR /home/workspace/swscale-impl
# v1 setup_cmds[6]: empty "init" commit (7a934f8b..., 2026-06-09T12:53:17Z).
RUN git init -q && git config user.email 'sebench@local' && git config user.name 'sebench' \
 && git add -A \
 && GIT_AUTHOR_DATE='2026-06-09T12:53:17+00:00' GIT_COMMITTER_DATE='2026-06-09T12:53:17+00:00' \
    git commit -q -m 'init' --allow-empty \
 && git log --format='%H %s' -1

CMD ["/bin/bash"]
