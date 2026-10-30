# Judge image for ad_placement_optimization.
# Build context = the task directory:
#   sforge build --task ad_placement_optimization
#
# v1 judge.setup_cmds -> this file:
#   1 mkdir -p /home/workspace                                   -> implied
#   2 git clone .../ALE_problem.git /tmp/ALE_problem             -> sources committed in the task dir
#   3 mkdir -p <cwd>/tools <cwd>/cases                           -> implied by COPY
#   4 cp -r .../workspace/tools/bin <cwd>/tools/bin              -> built from environment/workspace/tools (stage `tools`)
#   5 cp .../internal/cases/public/*.txt <cwd>/cases/            -> COPY judge/cases/ (50 public cases, ALE_problem@273ff38)
#   6 rm -rf /tmp/ALE_problem                                    -> nothing to remove
#   7 chmod +x <cwd>/tools/bin/*                                 -> chmod below
#   8 heredoc > /tmp/eval_ahc.sh; chmod +x                       -> COPY judge/eval_ahc.sh /judge/eval_ahc.sh (byte-identical)
#   v1 eval_cmd + parser score_sum                               -> judge/run.sh (task.toml [judge].cmd)

# Base = bases/cpp (sforge build passes it as BASE_IMAGE).
ARG BASE_IMAGE

# ---- stage 1: build tools/bin/{gen,tester} (identical recipe to environment/Dockerfile) ----
FROM rust:1.93.0-slim-bookworm@sha256:776861219cd851131c1cec3bbd7cbeb16b99a794048097eb69ad9682a8ed0d57 AS tools
RUN rustup target add x86_64-unknown-linux-musl
COPY environment/workspace/tools /build/tools
WORKDIR /build/tools
RUN cargo build --release --locked --target x86_64-unknown-linux-musl --bin gen --bin tester \
 && mkdir -p /out && cp target/x86_64-unknown-linux-musl/release/gen target/x86_64-unknown-linux-musl/release/tester /out/

# ---- stage 2: judge ----
FROM ${BASE_IMAGE}
COPY --from=tools /out/gen /out/tester /home/workspace/ad-placement/tools/bin/
COPY judge/cases/ /home/workspace/ad-placement/cases/
COPY judge/eval_ahc.sh judge/run.sh /judge/
RUN chmod 755 /home/workspace/ad-placement/tools/bin/gen /home/workspace/ad-placement/tools/bin/tester \
              /judge/eval_ahc.sh /judge/run.sh
WORKDIR /home/workspace/ad-placement
CMD ["/bin/bash"]
