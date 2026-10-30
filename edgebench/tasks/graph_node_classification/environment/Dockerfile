# Work image for graph_node_classification (agent workspace).
# Build context = the task directory:
#   sforge build --task graph_node_classification
#
# v1 work.setup_cmds -> this file:
#   0 mkdir -p /tmp/sebench_resources <cwd>/solution             -> implied by COPY below
#   1 git clone original task repo (branch <author>)             -> files committed under environment/workspace/
#   2 pip install torch==2.2.2+cpu (PyTorch CPU index)             -> environment/pipinstall.sh + requirements.lock (hashed)
#   3 cp README.md                                                 -> environment/workspace/README.md (English version
#                                                                     from the published image, see NOTES.md)
#   4 cp codex_solver_sandbox/problem.md -> solution/problem.md    -> same (English version from the published image)
#   5-6 cp solution_template.py -> solution/{solution_template,solution}.py
#   7 rm -rf /tmp/sebench_resources                                -> nothing to remove
#   8-12 git init + config + add + commit -m init                  -> kept; author/date/branch pinned to v1's commit cfece788
#   (template) chown -R agent:agent <cwd>; USER agent              -> dropped (root)

# Base = bases/python, built locally as base-python.
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

RUN --mount=type=bind,source=environment,target=/mnt/lock sh /mnt/lock/pipinstall.sh

COPY environment/workspace/ /home/workspace/045_graph_node_classification/
WORKDIR /home/workspace/045_graph_node_classification
# v1 (fix layer of 2026-07-02): fresh repo on branch master with one "init" commit.
# Author, email, message, date = v1's commit cfece788 (2026-07-02T11:17:34Z); same tree -> same hash.
RUN git init -q && git symbolic-ref HEAD refs/heads/master \
 && git config user.email 'sebench@local' && git config user.name 'sebench' \
 && git add -A \
 && GIT_AUTHOR_DATE="2026-07-02T11:17:34Z" GIT_COMMITTER_DATE="2026-07-02T11:17:34Z" git commit -q -m 'init' \
 && git log --format='%H %s' -1
CMD ["python3"]
