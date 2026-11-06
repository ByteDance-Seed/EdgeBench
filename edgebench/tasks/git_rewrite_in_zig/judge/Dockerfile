# Judge image for git_rewrite_in_zig (v1: edgebench.judge.git_rewrite_in_zig:0d404251e9c9).
# Build context = the task directory:
#   sforge build --task git_rewrite_in_zig
#
# v1 judge.setup_cmds -> this file:
#   0 apt-get install wget xz-utils python3 strace zlib1g-dev file  -> environment/setup.sh judge (versions pinned)
#     libssl-dev libcurl4-openssl-dev
#   1 wget zig 0.14.0 + untar to /usr/local/zig                     -> stage `zig` (environment/zig.sh, sha256-checked)
#   2 git clone (sparse) of the original task repo                   -> files committed in the task dir
#   3 fetch_git_to_zig_assets.sh: /home/workspace/git-src and        -> stages `gitsrc` / `suite` (git-2.47.0 release,
#     /opt/tests/git-test-suite.tar.gz; cp zig-port scaffold            sha256-checked, + judge/test-lib.sh.patch)
#   4 cp tests/. /opt/tests/ (test.sh, compute_reward.py, ...)       -> COPY judge/tests/
#   5 heredoc > /opt/tests/pytest_shim.sh                            -> judge/tests/pytest_shim.sh (byte-identical)
#   v1 eval_cmd + parser pytest_v                                    -> judge/run.sh + judge/result.py
ARG BASE_IMAGE

FROM ${BASE_IMAGE} AS zig
COPY environment/zig.sh /build/zig.sh
RUN sh /build/zig.sh

FROM ${BASE_IMAGE} AS gitsrc
COPY environment/git-release.sh environment/git-release.exclude /build/
RUN sh /build/git-release.sh src /out/git-src

# ---- the git test suite (v1 tests/git-test-suite.tar.gz), packed reproducibly ----
FROM ${BASE_IMAGE} AS suite
COPY environment/git-release.sh environment/git-release.exclude /build/
COPY judge/test-lib.sh.patch /build/
RUN sh /build/git-release.sh suite /out/git-test-suite /build/test-lib.sh.patch \
 && cd /out && tar --sort=name --owner=0 --group=0 --numeric-owner --mtime='2026-04-01 04:13:21Z' \
      -cf - git-test-suite | gzip -n -9 > /out/git-test-suite.tar.gz

FROM ${BASE_IMAGE}
COPY environment/setup.sh /setup/setup.sh
RUN sh /setup/setup.sh judge && rm -rf /setup
COPY --from=zig /usr/local/zig/ /usr/local/zig/
# COPY creates the top dir as root; v1's root `tar xf` left it uid/gid 1000 like the rest of the tree.
RUN chown 1000:1000 /usr/local/zig && ln -sf /usr/local/zig/zig /usr/local/bin/zig && zig version

COPY --from=gitsrc /out/git-src/ /home/workspace/git-src/
COPY environment/zig-port/ /home/workspace/zig-port/
COPY --from=suite /out/git-test-suite.tar.gz /opt/tests/git-test-suite.tar.gz
COPY judge/tests/ /opt/tests/
COPY judge/run.sh judge/result.py /judge/
RUN chmod +x /opt/tests/*.sh && chmod 755 /judge/run.sh

# The submission is extracted here by the harness (task.toml environment.cwd).
WORKDIR /home/workspace/zig-port
CMD ["/bin/bash"]
