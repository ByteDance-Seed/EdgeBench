# Judge image for pfr_formalization. Build context = the task directory:
#   sforge build --task pfr_formalization
#
# v1 judge setup_cmds -> this file:
#   mkdir -p /home/workspace/judge; git clone -b Lean .../se-bmk-intern.git
#       -> COPY the unsolved pfr/ (same files as the workspace) and eval_lean.py
#          (v1's published judge image held only these two paths)
#   cd judge/se-bmk-intern/pfr; lake exe cache get && lake build
#       -> same package layout as the work image (symlinks into the base for Mathlib
#          and its dependencies, AddCombi + checkdecls cloned by Lake at the manifest
#          revs), then lake build. This prebuilt baseline is used at judge time: eval_cmd
#          copies its .lake into the submission and eval_lean.py runs
#          `lake build ListDeclAxiom` on it (--baseline-repo).
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

COPY environment/se-bmk-intern/pfr /home/workspace/judge/se-bmk-intern/pfr
COPY judge/se-bmk-intern/eval_lean.py /home/workspace/judge/se-bmk-intern/eval_lean.py

WORKDIR /home/workspace/judge/se-bmk-intern/pfr
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
    done

COPY judge/run.sh judge/write_result.py /judge/

WORKDIR /home/workspace/
CMD ["bash"]
