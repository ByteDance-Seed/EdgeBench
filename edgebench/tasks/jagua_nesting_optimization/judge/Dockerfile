# Judge image for jagua_nesting_optimization (v1: edgebench.judge.jagua_nesting_optimization:bba393b2dd53).
# Build context = the task directory:
#   sforge build --task jagua_nesting_optimization
#
# v1 judge.setup_cmds -> here:
#   [0-1] sparse protocol / mirror config.toml          -> dropped (see environment/Dockerfile)
#   [2] apt-get install python3                          -> no-op (python3 3.11.2 is in the base)
#   [3] rustup toolchain 1.88.0                          -> setup_toolchain.sh (pinned)
#   [4-5] download the v1 judge bundle, untar to /home/workspace/jagua-rs (the candidate tree)
#   [7] untar the same bundle to /home/workspace/jagua-rs-ref (the frozen reference)
#       -> the judge bundle = the work bundle (environment/jagua-rs) + 29 hidden instance files
#          (judge/hidden/assets) + the unfiltered lbf/tests/tests.rs (judge/hidden/lbf)
#   [6,8] sed feature line into lib.rs + .cargo/config.toml, in both trees -> same RUN below
#   [9-11] evaluate.py / score.sh heredocs + chmod      -> COPY judge/jagua_task_scorer/ (byte-identical)
#   [12-13] cargo build --release --bin lbf in both trees -> same (prebuilt target/ as in v1)
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

COPY environment/setup_toolchain.sh environment/rust-1.88.0-toolchain.sha256 /tmp/toolchain/
RUN sh /tmp/toolchain/setup_toolchain.sh && rm -rf /tmp/toolchain

COPY environment/jagua-rs/ /home/workspace/jagua-rs/
COPY judge/hidden/ /home/workspace/jagua-rs/
COPY environment/jagua-rs/ /home/workspace/jagua-rs-ref/
COPY judge/hidden/ /home/workspace/jagua-rs-ref/
RUN for d in /home/workspace/jagua-rs /home/workspace/jagua-rs-ref; do \
      cd "$d" && sed -i '1i#![feature(let_chains, integer_sign_cast)]' jagua-rs/src/lib.rs \
      && mkdir -p .cargo && printf '[env]\nRUSTC_BOOTSTRAP = "1"\n' > .cargo/config.toml || exit 1; \
    done
COPY judge/jagua_task_scorer/ /home/workspace/jagua_task_scorer/
RUN chmod +x /home/workspace/jagua_task_scorer/evaluate.py /home/workspace/jagua_task_scorer/score.sh

# Same fetch as the work image (crates.io, checked against Cargo.lock by --locked).
RUN cd /home/workspace/jagua-rs && cargo build --locked --release --bin lbf \
 && cd /home/workspace/jagua-rs-ref && cargo build --locked --release --bin lbf

COPY judge/run.sh judge/result.py /judge/
WORKDIR /home/workspace/jagua-rs
CMD ["bash"]
