# Work image for rust_multicrate_reconstruction (v1: edgebench.work.rust_multicrate_reconstruction:7f639fc9d090).
# Build context = the task directory:
#   sforge build --task rust_multicrate_reconstruction
# The base is built from bases/rust (no registry digest exists for it in the pilot).
ARG BASE_IMAGE

# ---- stage 1: rebuild v1's agent-start/vendor-deps/ from crates.io (sha256-checked) ----
FROM ${BASE_IMAGE} AS vendor
COPY environment/vendor/build_vendor.py environment/vendor/vendor-manifest.tsv /tmp/vendor/
RUN python3 -I /tmp/vendor/build_vendor.py --manifest /tmp/vendor/vendor-manifest.tsv --out /vendor-deps
# claude_rs is a path dependency of cas-cli that is not published on crates.io.
COPY environment/vendor/claude_rs/ /vendor-deps/claude_rs/

# ---- stage 2: the work image ----
FROM ${BASE_IMAGE}
ARG DEBIAN_FRONTEND=noninteractive

# v1 setup_cmds[1]: task apt packages + rustup toolchain 1.88.0 (default).
COPY environment/setup_toolchain.sh environment/rust-1.88.0-toolchain.sha256 /tmp/toolchain/
RUN sh /tmp/toolchain/setup_toolchain.sh && rm -rf /tmp/toolchain

# v1 setup_cmds[0,2-6]: the bundle's workspace/ unpacked into the task root
# (README.md + agent-start/; the bundle's judge/ never reaches the work image).
COPY environment/workspace/ /home/workspace/cas_rust_benchmark/
COPY --from=vendor /vendor-deps/ /home/workspace/cas_rust_benchmark/agent-start/vendor-deps/

WORKDIR /home/workspace/cas_rust_benchmark

# v1 setup_cmds[7]: fresh git repo with one "init" commit (agent-visible baseline for git diff).
# Dates pinned to v1's commit time so the tree is reproducible.
RUN git init -q && git config user.email 'sebench@local' && git config user.name 'sebench' \
 && git add -A \
 && GIT_AUTHOR_DATE='2026-06-09T13:04:57Z' GIT_COMMITTER_DATE='2026-06-09T13:04:57Z' git commit -q -m 'init' \
 && git log --oneline -1

CMD ["bash"]
