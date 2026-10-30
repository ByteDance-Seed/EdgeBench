# Work image for wireless_electricity_layout (agent workspace).
# Build context = the task directory:
#   sforge build --task wireless_electricity_layout
#
# v1 work.setup_cmds -> this file:
#   0 mkdir -p /home/workspace                            -> implied by COPY below
#   1 git clone .../ALE_problem.git /tmp/ALE_problem      -> sources committed under environment/workspace/
#                                                            (ALE_problem@edbd7c6, wirel/workspace)
#   2 cp -r .../wirel/workspace <cwd>; rm clone           -> COPY environment/workspace/ <cwd>
#   3 g++ -std=c++17 -O2 -o bin/gen src/gen.cpp; same for tester  -> same command, same compiler (base cpp)
#   4 rm -rf .git && git init && git config user.* && git add -A && git commit -m init
#                                                          -> same, with v1's commit dates pinned
#   (template) chown -R agent:agent <cwd>; USER agent      -> dropped (root)

# Base = bases/cpp (sforge build passes it as BASE_IMAGE).
ARG BASE_IMAGE
FROM ${BASE_IMAGE}
COPY environment/workspace/ /home/workspace/wirel/
WORKDIR /home/workspace/wirel
RUN cd tools && g++ -std=c++17 -O2 -o bin/gen src/gen.cpp && g++ -std=c++17 -O2 -o bin/tester src/tester.cpp
# v1 setup: fresh git repo with one "init" commit (agent-visible baseline for git diff).
# Author/email/message/dates = v1's commit af9aef80 (2026-06-05T12:54:40Z).
RUN git init -q && git config user.email 'sebench@local' && git config user.name 'sebench' \
 && git add -A \
 && GIT_AUTHOR_DATE="1780664080 +0000" GIT_COMMITTER_DATE="1780664080 +0000" git commit -q -m 'init' \
 && git log --format='%H %an <%ae> %ad' -1
CMD ["/bin/bash"]
