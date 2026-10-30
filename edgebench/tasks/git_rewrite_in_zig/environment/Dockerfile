# Work image for git_rewrite_in_zig (v1: edgebench.work.git_rewrite_in_zig:3e1aae9f830c).
# Build context = the task directory:
#   sforge build --task git_rewrite_in_zig
#
# v1 work.setup_cmds -> this file:
#   0 apt-get install wget xz-utils python3 zlib1g-dev           -> environment/setup.sh work (versions pinned)
#   1 wget zig-linux-x86_64-0.14.0 + untar to /usr/local/zig      -> stage `zig` (environment/zig.sh, sha256-checked)
#   2 git clone (sparse) of the original task repo                -> files committed under environment/
#   3 fetch_git_to_zig_assets.sh (FrontierSWE git-src) +          -> stage `gitsrc` (git-2.47.0 release, sha256-checked)
#     cp zig-port + instruction.md                                -> COPY environment/zig-port, environment/workspace
#   4 rm -rf .git && git init && git config user.* && commit init -> kept, v1 dates pinned
#   (template) chown -R agent:agent zig-port; USER agent          -> dropped (root)
ARG BASE_IMAGE

# ---- stage `zig`: /usr/local/zig ----
FROM ${BASE_IMAGE} AS zig
COPY environment/zig.sh /build/zig.sh
RUN sh /build/zig.sh

# ---- stage `gitsrc`: /home/workspace/git-src from the public git-2.47.0 release ----
FROM ${BASE_IMAGE} AS gitsrc
COPY environment/git-release.sh environment/git-release.exclude /build/
RUN sh /build/git-release.sh src /out/git-src

# ---- the work image ----
FROM ${BASE_IMAGE}
COPY environment/setup.sh /setup/setup.sh
RUN sh /setup/setup.sh work && rm -rf /setup
COPY --from=zig /usr/local/zig/ /usr/local/zig/
# COPY creates the top dir as root; v1's root `tar xf` left it uid/gid 1000 like the rest of the tree.
RUN chown 1000:1000 /usr/local/zig && ln -sf /usr/local/zig/zig /usr/local/bin/zig && zig version

COPY --from=gitsrc /out/git-src/ /home/workspace/git-src/
COPY environment/workspace/instruction.md /home/workspace/instruction.md
COPY environment/zig-port/ /home/workspace/zig-port/

WORKDIR /home/workspace/zig-port
# v1 setup_cmds[4]: fresh repo with one "init" commit (agent-visible baseline for git diff).
# Author and dates pinned to v1's commit 23bd6c83b2d1efbe146530ed25833ba01edf1300.
RUN git init -q && git config user.email 'sebench@local' && git config user.name 'sebench' \
 && git add -A \
 && GIT_AUTHOR_DATE='2026-06-12T13:07:04Z' GIT_COMMITTER_DATE='2026-06-12T13:07:04Z' git commit -q -m 'init' \
 && git log --format='%H %s' -1

CMD ["/bin/bash"]
