# Work image for vehicle_routing_time_windows (v1: edgebench.work.vehicle_routing_time_windows:53214fda231b).
# Build context = the task directory:
#   sforge build --task vehicle_routing_time_windows
#
# v1 work.setup_cmds -> this file:
#   0 mkdir -p /home/workspace/task_cvrptw_905da6dd             -> implied by COPY
#   1 git clone se-bmk-intern (branch <author>, sparse)           -> sources committed in environment/workspace/
#   2 cp -a .../other/attachments/workspace_unzipped/workspace   -> COPY environment/workspace/
#   3 rm instances/public/*.bks fetch_solomon.sh tools/bench.sh,
#     rm cvrptw_solver tools/verify                              -> those files are not committed here
#   4 python heredoc: write README.md                           -> committed result (byte-identical)
#   5 python heredoc: patch Makefile `bench` target              -> committed result (byte-identical)
#   6 git init + config sebench@local + add -A + commit 'init'   -> same, dates pinned to v1's commit
#   (template) chown -R agent:agent; USER agent                  -> dropped (root)
# instances/public/README.md is the English version from the published image (see NOTES.md).
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

COPY environment/workspace/ /home/workspace/task_cvrptw_905da6dd/workspace/
WORKDIR /home/workspace/task_cvrptw_905da6dd/workspace
RUN chmod 755 /home/workspace /home/workspace/task_cvrptw_905da6dd \
 && find . -type d -exec chmod 755 {} + \
 && find . -type f -exec chmod 644 {} + \
 && chmod 755 tools/format_check.py \
 && git init -q && git config user.email 'sebench@local' && git config user.name 'sebench' \
 && git add -A \
 && GIT_AUTHOR_DATE="2026-07-02T11:16:24Z" GIT_COMMITTER_DATE="2026-07-02T11:16:24Z" git commit -q -m init \
 && git log --format='%H %s' -1
CMD ["python3"]
