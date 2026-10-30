# Judge image for new_foundations_consistency. Build context = the task directory:
#   sforge build --task new_foundations_consistency
#
# v1 judge setup_cmds -> this file:
#   mkdir -p /home/workspace/judge; git clone -b Lean .../se-bmk-intern.git
#       -> COPY the unsolved con-nf/ (same files as the workspace) + eval_lean.py
#          (v1's published judge image also held only these two paths of the clone)
#   cd judge/se-bmk-intern/con-nf; lake exe cache get && lake build
#       -> .lake/packages symlink to the base's packages, then lake build (prebuilds the
#          baseline ConNF + ListDeclAxiom; eval_cmd copies this .lake into the
#          submission, and `lake build ListDeclAxiom` here replays the cached output)
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

COPY environment/se-bmk-intern/con-nf /home/workspace/judge/se-bmk-intern/con-nf
COPY judge/se-bmk-intern/eval_lean.py /home/workspace/judge/se-bmk-intern/eval_lean.py

WORKDIR /home/workspace/judge/se-bmk-intern/con-nf
RUN set -eux; \
    mkdir -p .lake; \
    ln -s /home/workspace/baseline/.lake/packages .lake/packages; \
    lake build

COPY judge/run.sh judge/write_result.py /judge/

WORKDIR /home/workspace/
CMD ["bash"]
