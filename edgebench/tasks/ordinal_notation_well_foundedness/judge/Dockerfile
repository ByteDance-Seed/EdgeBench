# Judge image for ordinal_notation_well_foundedness
# (v1: edgebench.judge.ordinal_notation_well_foundedness:064b4eb91e22, v1 name ordinal_notation_wf).
# Build context = the task directory:
#   sforge build --task ordinal_notation_well_foundedness
#
# v1 judge.setup_cmds -> this file:
#   0 mkdir -p /home/workspace /opt/sebench                    -> mkdir -p /home/workspace (/opt/sebench not used, see below)
#   1 symlink the Coq binaries into /usr/local/bin              -> same command
#   2-4 git clone SE-bench-coq-proof, cp workspace to the cwd   -> COPY environment/workspace/ (same files as the work image)
#   5 cp judge/eval_task*.v into the cwd                        -> COPY judge/eval_task*.v into the cwd (same v1 path)
#   6 cp judge/eval.py /opt/sebench/ordinal_notation_wf_eval.py -> COPY judge/eval.py /judge/eval.py (moved, see NOTES.md)
#   7-8 rm the clone; chmod +x the eval script                  -> chmod 775 /judge/eval.py
#   (no git init in the v1 judge)
#   v1 eval_cmd `python3 /opt/sebench/ordinal_notation_wf_eval.py` + parser structured_json
#                                                               -> judge/run.sh, judge/write_result.py
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
COPY judge/eval_task*.v /home/workspace/ordinal_notation_wf/
COPY judge/eval.py judge/run.sh judge/write_result.py /judge/
# Modes as in v1 (umask 002 copies: dirs 775, files 664, eval script 775).
RUN set -eux; \
    chmod 775 /home/workspace /home/workspace/ordinal_notation_wf; \
    chmod 664 /home/workspace/ordinal_notation_wf/*; \
    chmod 775 /judge/eval.py; \
    chmod 755 /judge /judge/run.sh; \
    chmod 644 /judge/write_result.py

# The submission is extracted here by the harness (task.toml environment.cwd).
WORKDIR /home/workspace/ordinal_notation_wf
