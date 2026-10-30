# Judge image for vliw_kernel_optimization (v1: edgebench.judge.vliw_kernel_optimization:5cdef0021634).
# Build context = the task directory:
#   sforge build --task vliw_kernel_optimization
#
# v1 judge.setup_cmds -> this file:
#   0 mkdir -p /home/workspace /root/sebench_private           -> implied by COPY (the empty, unused
#                                                                 /root/sebench_private is not created)
#   1 sparse git clone se-bmk-intern (branch <author>)          -> sources committed under judge/evaluation/
#   2 cp -a .../private_files/evaluation <specs_dir>           -> COPY judge/evaluation/ (the hidden cases stay at
#                                                                 v1's test_cases/hidden_cases.json in the cwd)
#   3 rm -rf __pycache__ tests/__pycache__                     -> same (no-ops)
#   (no git init in the v1 judge; no public files in the v1 judge)
#   v1 eval_cmd + parser structured_json                       -> judge/run.sh, judge/eval_hidden.py, judge/write_result.py
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

COPY judge/evaluation/ /home/workspace/sebench_performance_takehome/
COPY judge/run.sh judge/eval_hidden.py judge/write_result.py /judge/
WORKDIR /home/workspace/sebench_performance_takehome
RUN find . -type d -exec chmod 755 {} + \
 && find . -type f -exec chmod 644 {} + \
 && rm -rf __pycache__ tests/__pycache__ \
 && chmod 755 /judge/run.sh && chmod 644 /judge/eval_hidden.py /judge/write_result.py
