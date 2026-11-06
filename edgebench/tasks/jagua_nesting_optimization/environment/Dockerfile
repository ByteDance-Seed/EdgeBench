# Work image for jagua_nesting_optimization (v1: edgebench.work.jagua_nesting_optimization:992b06cb3f8e).
# Build context = the task directory:
#   sforge build --task jagua_nesting_optimization
# The base is built from bases/rust (no registry digest exists for it yet).
#
# v1 work.setup_cmds -> here:
#   [0] export CARGO_REGISTRIES_CRATES_IO_PROTOCOL=sparse      -> cargo 1.88's default anyway
#   [1] /usr/local/cargo/config.toml replacing crates-io by a mirror -> dropped (a mirror never
#       appears in task files); crates come from crates.io, verified by Cargo.lock checksums
#   [2] rustup toolchain install 1.88.0 && rustup default        -> setup_toolchain.sh (pinned)
#   [3] download + untar the v1 work bundle, rm rust-toolchain.toml -> COPY environment/jagua-rs/
#       (the bundle has only rust-toolchain.toml.disabled, so the rm was a no-op)
#   [4] sed feature line into jagua-rs/src/lib.rs, .cargo/config.toml -> same RUN below
#   [5] sed hidden instances out of lbf/tests/tests.rs, delete hidden assets -> no-op on the
#       work bundle (it already lacks them); kept below for fidelity
#   [6] SEBENCH_TASK.md heredoc -> COPY environment/SEBENCH_TASK.md (the published image carries
#       the English version that replaced the Chinese heredoc text, see NOTES.md)
#   [7-8] cargo build --release --bin lbf; cargo test ... --list > /tmp/lbf-test-list.txt -> same,
#       but the listing goes to /judge/lbf-test-list.txt (nothing the task ships lives in /tmp)
#   [9] chmod -R a+rwX /usr/local/cargo                          -> same
#   [10] rm -rf .git && git init && git add -A && git commit -m init -> same, dates pinned
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

COPY environment/setup_toolchain.sh environment/rust-1.88.0-toolchain.sha256 /tmp/toolchain/
RUN sh /tmp/toolchain/setup_toolchain.sh && rm -rf /tmp/toolchain

COPY environment/jagua-rs/ /home/workspace/jagua-rs/
WORKDIR /home/workspace/jagua-rs
RUN sed -i '1i#![feature(let_chains, integer_sign_cast)]' jagua-rs/src/lib.rs \
 && mkdir -p .cargo && printf '[env]\nRUSTC_BOOTSTRAP = "1"\n' > .cargo/config.toml \
 && sed -i '/blaz1/d;/jakobs2/d;/mao/d;/marques/d;/shapes1/d;/shirts/d;/swim/d;/swim_cr/d;/trousers/d;/gardeyn0/d;/gardeyn1/d;/gardeyn2/d;/gardeyn3/d;/gardeyn4/d;/gardeyn5/d;/gardeyn6/d;/gardeyn7/d' lbf/tests/tests.rs \
 && find assets -maxdepth 1 -type f -name '*.json' ! -name 'config_lbf.json' ! -name 'albano.json' ! -name 'dagli.json' ! -name 'fu.json' ! -name 'jakobs1.json' ! -name 'shapes0.json' ! -name 'baldacci1.json' ! -name 'baldacci2.json' ! -name 'baldacci3.json' ! -name 'baldacci4.json' ! -name 'baldacci5.json' ! -name 'baldacci6.json' ! -name 'self_intersecting.json' -delete
COPY environment/SEBENCH_TASK.md /home/workspace/jagua-rs/SEBENCH_TASK.md

# Crates are fetched from crates.io at build time (proxy only via build args); --locked makes
# cargo verify every crate against the checksums in the committed Cargo.lock. This fetches
# exactly the crates v1 fetched (the same two commands) and leaves the prebuilt target/ that v1 had.
RUN cargo build --locked --release --bin lbf \
 && mkdir -p /judge && cargo test --locked --release --bin lbf -- --list > /judge/lbf-test-list.txt \
 && chmod -R a+rwX /usr/local/cargo

# Fresh git repo with one "init" commit (agent-visible baseline for git diff). Dates pinned to
# v1's commit time, so the commit hash equals v1's (059d3290bd2057a8682ff4e710257b29e57c3d9e).
RUN rm -rf .git && git init -q && git config user.email 'sebench@local' && git config user.name 'sebench' \
 && git add -A \
 && GIT_AUTHOR_DATE='2026-07-02T11:17:44Z' GIT_COMMITTER_DATE='2026-07-02T11:17:44Z' git commit -q -m 'init' \
 && git log --format='%H %T' -1

CMD ["bash"]
