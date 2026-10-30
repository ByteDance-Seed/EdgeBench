# Work image for ordinal_notation_well_foundedness
# (v1: edgebench.work.ordinal_notation_well_foundedness:690c1a245369, v1 name ordinal_notation_wf).
# Build context = the task directory:
#   sforge build --task ordinal_notation_well_foundedness
#
# v1 work.setup_cmds -> this file:
#   0 mkdir -p /home/workspace                                  -> RUN below
#   1 symlink coqc coqtop coq_makefile coqdep coqchk coqdoc     -> same command
#     from the opam switch into /usr/local/bin; coqc --version
#   2-4 git clone SE-bench-coq-proof, cp ordinal_notation_wf/   -> COPY environment/workspace/ (same files)
#     workspace to the cwd, rm the clone
#   5 rm -rf .git; git init; user sebench/sebench@local;        -> same commands, dates pinned to v1's commit
#     git add -A; git commit -m init                               (2026-06-12T06:52:23Z), branch master
#   (sanitize step: chown -R agent:agent cwd)                   -> dropped, root owns everything (SCHEMA rule 3)
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

RUN set -eux; \
    mkdir -p /home/workspace; \
    COQC_BIN=$(find /home/coq/.opam -path '*/bin/coqc' -type f -executable | head -1); \
    if [ -z "$COQC_BIN" ]; then echo 'coqc not found under /home/coq/.opam' >&2; exit 1; fi; \
    COQ_BIN_DIR=$(dirname "$COQC_BIN"); \
    for b in coqc coqtop coq_makefile coqdep coqchk coqdoc; do \
      if [ -x "$COQ_BIN_DIR/$b" ]; then ln -sf "$COQ_BIN_DIR/$b" "/usr/local/bin/$b"; fi; \
    done; \
    coqc --version

COPY environment/workspace/ /home/workspace/ordinal_notation_wf/
WORKDIR /home/workspace/ordinal_notation_wf
# Modes as in v1 (the v1 clone was copied with umask 002: dirs 775, files 664).
RUN set -eux; \
    chmod 775 /home/workspace /home/workspace/ordinal_notation_wf; \
    chmod 664 /home/workspace/ordinal_notation_wf/*; \
    git -c init.defaultBranch=master init -q; \
    git config user.email 'sebench@local'; \
    git config user.name 'sebench'; \
    git add -A; \
    GIT_AUTHOR_DATE='1781247143 +0000' GIT_COMMITTER_DATE='1781247143 +0000' git commit -q -m 'init'; \
    test "$(git rev-parse HEAD)" = c683ad4961c8c2159448558d7aceda57c46aec03
