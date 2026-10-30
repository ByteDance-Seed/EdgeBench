# Work image for vliw_kernel_optimization (v1: edgebench.work.vliw_kernel_optimization:9fa380a0ebef).
# Build context = the task directory:
#   sforge build --task vliw_kernel_optimization
#
# v1 work.setup_cmds (SE-bench-harness vliw_kernel.json) -> this file:
#   0 mkdir -p /home/workspace                                 -> implied by COPY
#   1 sparse git clone se-bmk-intern (branch <author>)          -> sources committed under environment/workspace/
#                                                                 (original task repo @ cc45561, see NOTES.md)
#   2 cp -a .../public_files/workspace <specs_dir>             -> COPY environment/workspace/
#   3 rm -rf __pycache__                                       -> same (no-op)
#   4 git init, user sebench/sebench@local, add -A,            -> same, dates pinned to v1's commit
#     commit -m init                                              2026-06-11T08:57:53Z (same commit hash)
#   (template) chown -R agent:agent <specs_dir>; USER agent    -> dropped (root)
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

COPY environment/workspace/ /home/workspace/sebench_performance_takehome/
WORKDIR /home/workspace/sebench_performance_takehome
RUN find . -type d -exec chmod 755 {} + \
 && find . -type f -exec chmod 644 {} + \
 && rm -rf __pycache__ \
 && git init -q && git config user.email 'sebench@local' && git config user.name 'sebench' \
 && git add -A \
 && GIT_AUTHOR_DATE='2026-06-11T08:57:53Z' GIT_COMMITTER_DATE='2026-06-11T08:57:53Z' git commit -q -m 'init' \
 && git log --format='%H %an <%ae> %ad' -1
