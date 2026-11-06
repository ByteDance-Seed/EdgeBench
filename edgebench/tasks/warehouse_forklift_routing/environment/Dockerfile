# Work image for warehouse_forklift_routing (agent workspace).
# Build context = the task directory:
#   sforge build --task warehouse_forklift_routing
#
# v1 work.setup_cmds -> this file:
#   0 mkdir -p /home/workspace                                  -> implied by COPY below
#   1 git clone .../ALE_problem.git /tmp/ALE_problem            -> sources committed under environment/workspace/
#                                                                 (ALE_problem@d0a6656, warehouse_manager/workspace)
#   2 cp -r .../warehouse_manager/workspace <cwd>; rm clone     -> COPY environment/workspace/ <cwd>
#   3 chmod +x <cwd>/tools/bin/*                                -> chmod below
#   4 python3 -c "... write solution.py" (starter)              -> environment/workspace/solution.py (byte-identical)
#   5 rm -rf .git && git init && git config user.* && add && commit -m init
#                                                               -> kept, author/dates pinned to v1's commit
#   (template) chown -R agent:agent <cwd>; USER agent            -> dropped (root)

# Base = bases/python310 (sforge build passes it as BASE_IMAGE).
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

COPY environment/workspace/ /home/workspace/warehouse_manager/
RUN chmod +x /home/workspace/warehouse_manager/tools/bin/*
WORKDIR /home/workspace/warehouse_manager
# v1 setup: fresh git repo with one "init" commit (agent-visible baseline for git diff).
# Author, email, message and dates = v1's commit e41169c2 (2026-06-09T12:47:36Z).
RUN git init -q && git config user.email 'sebench@local' && git config user.name 'sebench' \
 && git add -A \
 && GIT_AUTHOR_DATE="2026-06-09T12:47:36Z" GIT_COMMITTER_DATE="2026-06-09T12:47:36Z" git commit -q -m 'init' \
 && git log --format='%H %s' -1
CMD ["python3"]
