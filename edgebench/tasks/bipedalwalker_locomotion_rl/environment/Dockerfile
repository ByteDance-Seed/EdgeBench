# Work image for bipedalwalker_locomotion_rl (agent workspace).
# Build context = the task directory:
#   sforge build --task bipedalwalker_locomotion_rl
#
# v1 work.setup_cmds -> this file:
#   0 echo loco-agent-trained-checkpoint-judge-only-20260530   -> (cache-busting no-op) dropped
#   1 mkdir -p /tmp/loco-src <cwd>                              -> implied by COPY below
#   2 sparse clone SE-bench-<author>, cp sebench-loco-rl-integrated.zip
#   3 unzip -> /tmp/loco-src; 4 cp -a sebench-loco-rl/. <cwd>  -> zip contents committed under environment/workspace/
#   5 rm -rf <cwd>/eval <cwd>/sebench_eval.py                   -> those two live under judge/ only
#   6-9 pip install (filelock..fsspec; torch 2.3.1+cpu --no-deps; swig; numpy scipy gymnasium[box2d])
#                                                               -> environment/pipinstall.sh: hashed wheels from
#                                                                  requirements.lock + box2d-py sdist built locally
#  10 rm -rf /tmp/loco-src /tmp/loco.zip /tmp/sebench_task_assets -> nothing to remove
#  11 rm -rf .git && git init && config && add && commit -m init -> kept, author/dates pinned to v1's commit b544a464
#   (template) chown -R agent:agent <cwd>; USER agent           -> dropped (root)

# Base = bases/python (sforge build passes it as BASE_IMAGE).
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

RUN --mount=type=bind,source=environment,target=/mnt/lock sh /mnt/lock/pipinstall.sh

COPY environment/workspace/ /home/workspace/loco-rl/
WORKDIR /home/workspace/loco-rl
# v1 setup: fresh git repo with one "init" commit (agent-visible baseline for git diff).
# Author, email, message and dates = v1's commit b544a464 (2026-06-09T12:52:10Z); same tree -> same hash.
RUN git init -q && git config user.email 'sebench@local' && git config user.name 'sebench' \
 && git add -A \
 && GIT_AUTHOR_DATE="2026-06-09T12:52:10Z" GIT_COMMITTER_DATE="2026-06-09T12:52:10Z" git commit -q -m 'init' \
 && git log --format='%H %s' -1
CMD ["python3"]
