# Work image for treant_forest (agent workspace).
# Build context = the task directory:
#   sforge build --task treant_forest
#
# v1 work.setup_cmds -> this file:
#   0 mkdir -p /home/workspace                            -> implied by COPY below
#   1 git clone .../ALE_problem.git /tmp/ALE_problem      -> sources committed under environment/workspace/
#                                                            (ALE_problem@4b31ad9, treants_forest/workspace)
#   2 cp -r .../treants_forest/workspace <cwd>; rm clone  -> COPY environment/workspace/ <cwd>
#   3 chmod +x <cwd>/tools/bin/*                          -> chmod below (gen/tester are Python scripts)
#   4 heredoc > <cwd>/solution.py (baseline)              -> environment/workspace/solution.py (byte-identical)
#   5 rm -rf .git && git init && git config user.* && git add -A && git commit -m init
#                                                          -> same, with v1's commit dates pinned
#   (template) chown -R agent:agent <cwd>; USER agent      -> dropped (root)

# Base = bases/python310 (sforge build passes it as BASE_IMAGE).
ARG BASE_IMAGE
FROM ${BASE_IMAGE}
COPY environment/workspace/ /home/workspace/treants_forest/
WORKDIR /home/workspace/treants_forest
RUN chmod +x tools/bin/*
# v1 setup: fresh git repo with one "init" commit (agent-visible baseline for git diff).
# Author/email/message/dates = v1's commit 0f62bf72 (2026-06-05T10:23:22Z).
RUN git init -q && git config user.email 'sebench@local' && git config user.name 'sebench' \
 && git add -A \
 && GIT_AUTHOR_DATE="1780655002 +0000" GIT_COMMITTER_DATE="1780655002 +0000" git commit -q -m 'init' \
 && git log --format='%H %an <%ae> %ad' -1
CMD ["python3"]
