# Judge image for vehicle_routing_time_windows (v1: edgebench.judge.vehicle_routing_time_windows:d5abb8bb08d2).
# Build context = the task directory:
#   sforge build --task vehicle_routing_time_windows
#
# v1 judge.setup_cmds -> this file:
#   0 mkdir -p /home/workspace/task_cvrptw_905da6dd              -> implied by COPY
#   1 git clone se-bmk-intern (branch <author>, sparse)            -> sources committed in the task dir
#   2 cp -a .../workspace_unzipped/workspace <ws>                 -> COPY environment/workspace/ (same files as the
#                                                                    work image) + judge/workspace/ (the original
#                                                                    Makefile and the files the work setup deletes:
#                                                                    *.bks, fetch_solomon.sh, tools/bench.sh)
#   3 cp -a .../evaluation/attachments/cases_unzipped/cases       -> COPY judge/internal/ (56 hidden instances in raw/,
#        <root>/internal/cases                                      bks_snapshot.csv, generator scripts)
#   4 rm -f cvrptw_solver tools/verify                           -> those binaries are not committed
#   (no git init in the v1 judge)
#   v1 eval_cmd (python heredoc) + parser structured_json        -> judge/run.sh, judge/eval.py, judge/write_result.py
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

COPY environment/workspace/ /home/workspace/task_cvrptw_905da6dd/workspace/
COPY judge/workspace/ /home/workspace/task_cvrptw_905da6dd/workspace/
COPY judge/internal/ /home/workspace/task_cvrptw_905da6dd/internal/
WORKDIR /home/workspace/task_cvrptw_905da6dd
RUN chmod 755 /home/workspace . \
 && find workspace internal -type d -exec chmod 755 {} + \
 && find workspace internal -type f -exec chmod 644 {} + \
 && chmod 755 workspace/tools/format_check.py workspace/tools/bench.sh workspace/instances/public/fetch_solomon.sh

COPY judge/run.sh judge/eval.py judge/write_result.py /judge/
RUN chmod 755 /judge/run.sh && chmod 644 /judge/eval.py /judge/write_result.py
# The submission is extracted here by the harness (task.toml environment.cwd).
WORKDIR /home/workspace/task_cvrptw_905da6dd/workspace
CMD ["python3"]
