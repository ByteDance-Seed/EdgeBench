# Work image for flt_regular_formalization. Build context = the task directory:
#   sforge build --task flt_regular_formalization
#
# v1 setup_cmds -> this file:
#   git clone -b Lean .../se-bmk-intern.git; rm all top-level entries but FltRegular
#       -> COPY environment/se-bmk-intern (FltRegular/ from commit 36361ad, see NOTES.md)
#   printf '*/.lake\n' >> .gitignore      -> environment/se-bmk-intern/.gitignore
#   git init && git config ... && git add -A && git commit -m init
#       -> same commands below (fixed dates so the commit is reproducible)
#   cd FltRegular; cp -r /home/workspace/baseline/.lake . && lake build
#       -> .lake/packages is a symlink to the base's Mathlib packages (no copy), then lake build
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

COPY environment/se-bmk-intern /home/workspace/se-bmk-intern

WORKDIR /home/workspace/se-bmk-intern
RUN set -eux; \
    git init -q; \
    git symbolic-ref HEAD refs/heads/master; \
    git config user.email 'sebench@local'; \
    git config user.name 'sebench'; \
    git add -A; \
    GIT_AUTHOR_DATE='2026-07-02T11:17:21+0000' GIT_COMMITTER_DATE='2026-07-02T11:17:21+0000' \
      git commit -q -m init

WORKDIR /home/workspace/se-bmk-intern/FltRegular
RUN set -eux; \
    mkdir -p .lake; \
    ln -s /home/workspace/baseline/.lake/packages .lake/packages; \
    lake build; \
    test -z "$(git -C /home/workspace/se-bmk-intern status --porcelain)"

WORKDIR /home/workspace/
CMD ["bash"]
