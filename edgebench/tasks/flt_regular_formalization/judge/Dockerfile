# Judge image for flt_regular_formalization. Build context = the task directory:
#   sforge build --task flt_regular_formalization
#
# v1 judge setup_cmds -> this file:
#   mkdir -p /home/workspace/judge; git clone -b Lean .../se-bmk-intern.git
#       -> COPY the unsolved FltRegular/ (same files as the workspace), eval_lean.py and
#          task/FltRegular_weight.json (v1's published judge image held only these paths)
#   cd judge/se-bmk-intern/FltRegular; cp -r /home/workspace/baseline/.lake . && lake build
#       -> dropped: eval_cmd runs eval_lean.py in weights-only mode (no --baseline-repo),
#          so the judge copy is only the source of ListDeclAxiom.lean and its build
#          output is never read (see NOTES.md)
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

COPY environment/se-bmk-intern/FltRegular /home/workspace/judge/se-bmk-intern/FltRegular
COPY judge/se-bmk-intern /home/workspace/judge/se-bmk-intern
COPY judge/run.sh judge/write_result.py /judge/

WORKDIR /home/workspace/
CMD ["bash"]
