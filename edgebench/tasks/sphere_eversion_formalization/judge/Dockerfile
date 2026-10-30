# Judge image for sphere_eversion_formalization. Build context = the task directory:
#   sforge build --task sphere_eversion_formalization
#
# v1 judge setup_cmds -> this file:
#   mkdir -p /home/workspace/judge; git clone -b Lean .../se-bmk-intern.git
#       -> COPY the unsolved sphere-eversion/ (same files as the workspace) + eval_lean.py
#          (v1's published judge image also held only these two paths of the clone)
#   cd judge/se-bmk-intern/sphere-eversion; cp -r /home/workspace/baseline/.lake . && lake build
#       -> .lake/packages symlink to the base's Mathlib packages, then lake build
#          (prebuilds the baseline SphereEversion + ListDeclAxiom, whose cached output
#          `lake build ListDeclAxiom` replays at judge time)
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

COPY environment/se-bmk-intern/sphere-eversion /home/workspace/judge/se-bmk-intern/sphere-eversion
COPY judge/se-bmk-intern/eval_lean.py /home/workspace/judge/se-bmk-intern/eval_lean.py

WORKDIR /home/workspace/judge/se-bmk-intern/sphere-eversion
RUN set -eux; \
    mkdir -p .lake; \
    ln -s /home/workspace/baseline/.lake/packages .lake/packages; \
    lake build

COPY judge/run.sh judge/write_result.py /judge/

WORKDIR /home/workspace/
CMD ["bash"]
