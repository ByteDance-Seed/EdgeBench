# Judge image for carleson_formalization. Build context = the task directory:
#   sforge build --task carleson_formalization
# Needs network for one pinned fetch (checkdecls), as the work image.
#
# v1 judge setup_cmds -> this file:
#   mkdir -p /home/workspace/judge; git clone -b Lean .../se-bmk-intern.git
#       -> COPY the unsolved carleson/ (same files as the workspace) + eval_lean.py
#          (v1's published judge image also held only these two paths of the clone)
#   cd judge/se-bmk-intern/carleson; lake exe cache get && lake build
#       -> same package setup as environment/Dockerfile (symlinks to the base's Mathlib
#          packages + checkdecls clone), then lake build (prebuilds the baseline Carleson +
#          ListDeclAxiom, whose cached output `lake build ListDeclAxiom` replays at judge time).
#          v1's eval_cmd copies this .lake into the submission; it is now ~165 MB of
#          build products plus symlinks instead of 6.6 GB.
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

COPY environment/se-bmk-intern/carleson /home/workspace/judge/se-bmk-intern/carleson
COPY judge/se-bmk-intern/eval_lean.py /home/workspace/judge/se-bmk-intern/eval_lean.py

WORKDIR /home/workspace/judge/se-bmk-intern/carleson
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
    lake build

COPY judge/run.sh judge/write_result.py /judge/

WORKDIR /home/workspace/
CMD ["bash"]
