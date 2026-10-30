# Judge image for wireless_electricity_layout.
# Build context = the task directory:
#   sforge build --task wireless_electricity_layout
#
# v1 judge.setup_cmds -> this file:
#   0 mkdir -p /home/workspace                                  -> implied
#   1 git clone .../ALE_problem.git /tmp/ALE_problem            -> sources committed in the task dir
#   2 cp -r .../wirel/workspace <cwd>                           -> COPY environment/workspace/ <cwd>
#                                                                  (includes the baseline solution.cpp, which v1
#                                                                  grades when the submission has no solution.cpp)
#   3 cp internal/{generate_cases,eval_wirel}.sh /tmp/; chmod   -> COPY judge/eval_wirel.sh /judge/ (byte-identical);
#                                                                  judge/generate_cases.sh is kept for provenance only
#   4 rm -rf /tmp/ALE_problem                                   -> nothing to remove
#   5 g++ ... bin/gen, bin/tester                               -> same command, same compiler
#   6 WIREL_WORK_DIR=<cwd> /tmp/generate_cases.sh               -> COPY judge/cases/ (its 50 outputs, committed)
#   7 rm -rf .git && git init && ... commit -m init             -> dropped (the judge never reads it)
#   v1 eval_cmd + parser score_sum                              -> judge/run.sh (task.toml [judge].cmd)

# Base = bases/cpp (sforge build passes it as BASE_IMAGE).
ARG BASE_IMAGE
FROM ${BASE_IMAGE}
COPY environment/workspace/ /home/workspace/wirel/
WORKDIR /home/workspace/wirel
RUN cd tools && g++ -std=c++17 -O2 -o bin/gen src/gen.cpp && g++ -std=c++17 -O2 -o bin/tester src/tester.cpp
COPY judge/cases/ /home/workspace/wirel/cases/
COPY judge/eval_wirel.sh judge/run.sh /judge/
RUN chmod 755 /judge/eval_wirel.sh /judge/run.sh
CMD ["/bin/bash"]
