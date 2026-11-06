# Work image for triangulation_coloring_optimization (agent workspace).
# Build context = the task directory:
#   sforge build --task triangulation_coloring_optimization
#
# v1 work.setup_cmds -> this file:
#   0 mkdir -p /home/workspace                                  -> implied by COPY below
#   1 git clone .../ALE_problem.git /tmp/ALE_problem            -> sources committed under environment/workspace/
#                                                                 (ALE_problem@2e6be68, triangulation_coloring/workspace)
#   2 cp -r .../triangulation_coloring/workspace <cwd>; rm clone -> COPY environment/workspace/ <cwd>
#   3 chmod +x <cwd>/tools/bin/* <cwd>/eval_sample_data.sh      -> chmod below
#   4 heredoc > <cwd>/solution.py (starter)                      -> environment/workspace/solution.py (byte-identical)
#   5 rm -rf .git && git init && git config user.* && add && commit -m init
#                                                               -> kept, author/dates pinned to v1's commit
#   (template) chown -R agent:agent <cwd>; USER agent            -> dropped (root)

# Base = bases/python310 (sforge build passes it as BASE_IMAGE).
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

COPY environment/workspace/ /home/workspace/triangulation_coloring/
RUN chmod +x /home/workspace/triangulation_coloring/tools/bin/* /home/workspace/triangulation_coloring/eval_sample_data.sh
WORKDIR /home/workspace/triangulation_coloring
# v1 setup: fresh git repo with one "init" commit (agent-visible baseline for git diff).
# Author, email, message and dates = v1's commit 12e8e1e1 (2026-06-06T13:55:37Z).
RUN git init -q && git config user.email 'sebench@local' && git config user.name 'sebench' \
 && git add -A \
 && GIT_AUTHOR_DATE="2026-06-06T13:55:37Z" GIT_COMMITTER_DATE="2026-06-06T13:55:37Z" git commit -q -m 'init' \
 && git log --format='%H %s' -1
CMD ["python3"]
