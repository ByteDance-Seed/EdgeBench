# Work image for pfr_formalization. Build context = the task directory:
#   sforge build --task pfr_formalization
#
# v1 setup_cmds (base `lean_4` = elan only) -> this file:
#   git clone -b Lean .../se-bmk-intern.git; rm all top-level entries but pfr
#       -> COPY environment/se-bmk-intern (pfr/ from commit 36361ad, see NOTES.md)
#   printf '*/.lake\n' >> .gitignore      -> environment/se-bmk-intern/.gitignore
#   git init && git config ... && git add -A && git commit -m init
#       -> same commands below (fixed dates so the commit is reproducible)
#   cd pfr; lake exe cache get && lake build
#       -> Mathlib v4.29.0 and its eight dependencies come from the shared base
#          (one symlink per package into /home/workspace/baseline/.lake/packages, no
#          copy); the two PFR-only packages (AddCombi, checkdecls) are cloned by Lake
#          at the commits pinned in lake-manifest.json; then lake build
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
    GIT_AUTHOR_DATE='2026-07-02T11:18:15+0000' GIT_COMMITTER_DATE='2026-07-02T11:18:15+0000' \
      git commit -q -m init

# Needs network for the two GitHub clones (pass http(s)_proxy build args if required).
# Every package HEAD (base symlinks included) must equal its lake-manifest.json rev.
WORKDIR /home/workspace/se-bmk-intern/pfr
RUN set -eux; \
    mkdir -p .lake/packages; \
    for n in mathlib plausible LeanSearchClient importGraph proofwidgets aesop Qq batteries Cli; do \
      ln -s "/home/workspace/baseline/.lake/packages/$n" ".lake/packages/$n"; \
    done; \
    lake build; \
    for n in $(jq -r '.packages[].name' lake-manifest.json); do \
      want=$(jq -r --arg n "$n" '.packages[] | select(.name==$n) | .rev' lake-manifest.json); \
      have=$(git -C ".lake/packages/$n" rev-parse HEAD); \
      [ "$want" = "$have" ] || { echo "rev mismatch: $n $have != $want"; exit 1; }; \
    done; \
    test -z "$(git -C /home/workspace/se-bmk-intern status --porcelain)"

WORKDIR /home/workspace/
CMD ["bash"]
