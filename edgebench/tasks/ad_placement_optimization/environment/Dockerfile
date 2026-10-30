# Work image for ad_placement_optimization (agent workspace).
# Build context = the task directory:
#   sforge build --task ad_placement_optimization
#
# v1 work.setup_cmds -> this file:
#   1 mkdir -p /home/workspace                          -> implied by COPY below
#   2 git clone .../ALE_problem.git /tmp/ALE_problem    -> sources committed under environment/workspace/
#                                                          (ALE_problem@273ff38, ad_placement/workspace)
#   3 cp -r .../ad_placement/workspace <cwd>; rm clone  -> COPY environment/workspace/ <cwd>
#   4 chmod +x <cwd>/tools/bin/*                         -> tools/bin built from tools/src in stage `tools`
#   5 rm -rf .git && git init && git add -A && commit    -> dropped (no .git in Verified images, see NOTES.md)
#   (template) chown -R agent:agent <cwd>; USER agent    -> dropped (root)

# Base = bases/cpp (sforge build passes it as BASE_IMAGE).
ARG BASE_IMAGE

# ---- stage 1: build tools/bin/{gen,tester} from the committed Rust sources ----
# rustc 1.93.0 + x86_64-unknown-linux-musl = the toolchain recorded in the v1 binaries' .comment section.
FROM rust:1.93.0-slim-bookworm@sha256:776861219cd851131c1cec3bbd7cbeb16b99a794048097eb69ad9682a8ed0d57 AS tools
RUN rustup target add x86_64-unknown-linux-musl
COPY environment/workspace/tools /build/tools
WORKDIR /build/tools
# --locked: crates are fetched from crates.io and checked against Cargo.lock checksums.
RUN cargo build --release --locked --target x86_64-unknown-linux-musl --bin gen --bin tester \
 && mkdir -p /out && cp target/x86_64-unknown-linux-musl/release/gen target/x86_64-unknown-linux-musl/release/tester /out/

# ---- stage 2: workspace ----
FROM ${BASE_IMAGE}
COPY environment/workspace/ /home/workspace/ad-placement/
COPY --from=tools /out/gen /out/tester /home/workspace/ad-placement/tools/bin/
RUN chmod 755 /home/workspace/ad-placement/tools/bin/gen /home/workspace/ad-placement/tools/bin/tester
WORKDIR /home/workspace/ad-placement
# v1 setup: fresh git repo with one "init" commit (agent-visible baseline for git diff).
# Author and dates pinned to v1's commit; the hash differs because gen/tester are rebuilt.
RUN git init -q && git config user.email "sebench@example.com" && git config user.name "sebench" \
 && git add -A \
 && GIT_AUTHOR_DATE="2026-07-02T09:52:22Z" GIT_COMMITTER_DATE="2026-07-02T09:52:22Z" git commit -q -m init \
 && git log --oneline -1
CMD ["/bin/bash"]
