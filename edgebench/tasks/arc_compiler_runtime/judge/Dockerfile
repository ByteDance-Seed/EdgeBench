# Judge image for arc_compiler_runtime (v1: edgebench.judge.arc_compiler_runtime:200e176a8e30).
# Build context = the task directory:
#   sforge build --task arc_compiler_runtime
#
# v1 judge.setup_cmds -> this file:
#   0 apt-get install nodejs npm wget                          -> environment/setup_node.sh (as in the work image)
#   1 mkdir -p .../arc-compiler-runtime-implementation           -> implied by COPY
#   2 git clone se-bmk-intern (branch <author>, sparse)          -> sources committed in the task dir
#   3 cp agent-start, problem.md; cp evaluator-hidden/{score_hidden.sh,README.md}
#                                                              -> COPY environment/workspace/agent-start/ (same files as
#                                                                 the work image) and judge/evaluator-hidden/
#   4 datasets tarball: public-smoke -> agent-start/tests/,     -> committed: environment/.../tests/public-smoke/ and
#     hidden/tests -> evaluator-hidden/tests                       judge/evaluator-hidden/tests/ (from the published judge image)
#   5 npm ci; chmod +x score.sh node_modules/.bin/tsx           -> same
#   6 chmod +x evaluator-hidden/score_hidden.sh; delete .DS_Store -> same
#   (no git init in the v1 judge)
#   v1 eval_cmd + parser structured_json                        -> judge/run.sh, judge/eval_hidden.py, judge/write_result.py
ARG BASE_IMAGE
FROM ${BASE_IMAGE}
ARG DEBIAN_FRONTEND=noninteractive

COPY environment/setup_node.sh environment/node-packages.lock /tmp/node-setup/
RUN sh /tmp/node-setup/setup_node.sh && rm -rf /tmp/node-setup

COPY environment/workspace/agent-start/ /home/workspace/arc-compiler-runtime-implementation/agent-start/
COPY judge/evaluator-hidden/ /home/workspace/arc-compiler-runtime-implementation/evaluator-hidden/
WORKDIR /home/workspace/arc-compiler-runtime-implementation
RUN find . -type d -exec chmod 755 {} + \
 && find . -type f -exec chmod 644 {} + \
 && cd agent-start && if [ ! -d node_modules ]; then npm ci; fi && chmod +x score.sh node_modules/.bin/tsx \
 && cd .. && chmod +x evaluator-hidden/score_hidden.sh && find . -name '.DS_Store' -delete

COPY judge/run.sh judge/eval_hidden.py judge/write_result.py /judge/
RUN chmod 755 /judge/run.sh && chmod 644 /judge/eval_hidden.py /judge/write_result.py
# The submission (compiler/src/) is extracted here by the harness (task.toml environment.cwd).
WORKDIR /home/workspace/arc-compiler-runtime-implementation/agent-start
CMD ["python3"]
