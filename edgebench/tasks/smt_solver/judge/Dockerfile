# Judge image for smt_solver.
# Build context = the task directory:
#   sforge build --task smt_solver
#
# v1 judge.setup_cmds -> this file:
#   1 mkdir -p /tmp/sebench_resources <cwd> /home/workspace/smt_judge  -> implied by COPY
#   2 git clone se-bmk-intern (branch <author>)                         -> sources committed in the task dir
#   3 cp -a .../SMT/problem/. <cwd>/                                    -> COPY README.md, smtlib_spec.md, paper-md/, papers/
#                                                                          from environment/workspace/ (benchmarks/, scripts/
#                                                                          and .git are removed again by step 7)
#   4 cp -a .../SMT/evaluate/scripts /home/workspace/smt_judge/scripts  -> COPY judge/smt_judge/scripts/
#   5 download SMT-hidden_benchmarks.zip (internal TOS, sha256          -> blob judge/blobs/hidden_benchmarks.tar.gz = that
#     d51f1ee9...) to /home/workspace/smt_judge/                           zip's content (the v1 eval_cmd extracted the zip
#                                                                          there at the start of every run)
#   6 rm -rf /tmp/sebench_resources /tmp/sebench_data                   -> nothing to remove
#   7 rm -rf .git benchmarks scripts; mkdir -p src;                     -> mkdir src + chmod below
#     chmod +x .../smt_judge/scripts/evaluate.py
#   v1 eval_cmd + parser structured_json                                -> judge/run.sh, judge/parse_result.py,
#                                                                          judge/write_result.py ([judge].cmd)

# Base = bases/python310 (sforge build passes it as BASE_IMAGE).
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

COPY environment/workspace/README.md environment/workspace/smtlib_spec.md /home/workspace/smt_solver/
COPY environment/workspace/paper-md/ /home/workspace/smt_solver/paper-md/
COPY environment/workspace/papers/ /home/workspace/smt_solver/papers/
COPY judge/smt_judge/scripts/ /home/workspace/smt_judge/scripts/
# Hidden set = blob judge/blobs/hidden_benchmarks.tar.gz (task.toml [[blobs]]); ADD unpacks it to
# /home/workspace/smt_judge/hidden_benchmarks/ (files 644, dirs 755, owner root).
ADD judge/blobs/hidden_benchmarks.tar.gz /home/workspace/smt_judge/
COPY judge/run.sh judge/parse_result.py judge/write_result.py /judge/
RUN mkdir -p /home/workspace/smt_solver/src \
 && find /home/workspace -type d -exec chmod 755 {} + \
 && find /home/workspace -type f -exec chmod 644 {} + \
 && chmod 755 /home/workspace/smt_judge/scripts/evaluate.py /judge/run.sh \
 && chmod 644 /judge/parse_result.py /judge/write_result.py
WORKDIR /home/workspace/smt_solver
CMD ["python3"]
