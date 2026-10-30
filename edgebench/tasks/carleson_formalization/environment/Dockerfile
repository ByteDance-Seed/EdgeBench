# Work image for carleson_formalization. Build context = the task directory:
#   sforge build --task carleson_formalization
# Needs network for one pinned fetch (checkdecls, see below).
#
# v1 setup_cmds (base lean_4 = elan only) -> this file:
#   git clone -b Lean .../se-bmk-intern.git; rm all top-level entries but carleson
#       -> COPY environment/se-bmk-intern (carleson/ from commit 36361ad, see NOTES.md)
#   printf '*/.lake\n' >> .gitignore      -> environment/se-bmk-intern/.gitignore
#   git init && git config ... && git add -A && git commit -m init
#       -> same commands below (fixed dates so the commit is reproducible)
#   cd carleson; lake exe cache get && lake build
#       -> Lean v4.30.0-rc2 + Mathlib 1a4917a (+ its deps) with cached oleans come from the
#          base; each of those packages is a symlink .lake/packages/<pkg> ->
#          /opt/mathlib/.lake/packages/<pkg> (no copy). The one package the base lacks,
#          checkdecls, is cloned at the manifest's commit as Lake would. Then lake build.
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
    GIT_AUTHOR_DATE='2026-07-02T11:16:51+0000' GIT_COMMITTER_DATE='2026-07-02T11:16:51+0000' \
      git commit -q -m init

WORKDIR /home/workspace/se-bmk-intern/carleson
RUN set -eux; \
    mkdir -p .lake/packages; \
    for n in $(jq -r '.packages[].name' lake-manifest.json); do \
      rev=$(jq -r --arg n "$n" '.packages[] | select(.name==$n) | .rev' lake-manifest.json); \
      if [ -d "/opt/mathlib/.lake/packages/$n" ]; then \
        ln -s "/opt/mathlib/.lake/packages/$n" ".lake/packages/$n"; \
      else \
        url=$(jq -r --arg n "$n" '.packages[] | select(.name==$n) | .url' lake-manifest.json); \
        git clone -q "$url" ".lake/packages/$n"; \
        git -C ".lake/packages/$n" checkout -q --detach "$rev"; \
      fi; \
      [ "$(git -C ".lake/packages/$n" rev-parse HEAD)" = "$rev" ] || { echo "rev mismatch: $n"; exit 1; }; \
    done; \
    lake build; \
    test -z "$(git -C /home/workspace/se-bmk-intern status --porcelain)"

WORKDIR /home/workspace/
CMD ["bash"]
