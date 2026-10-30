# Work image for apple_incremental_game (agent workspace).
# Build context = the task directory:
#   sforge build --task apple_incremental_game
#
# v1 work.setup_cmds -> this file:
#   0 mkdir -p /home/workspace                                  -> implied by COPY below
#   1 git clone .../ALE_problem.git /tmp/ALE_problem            -> sources committed under environment/workspace/
#                                                                 (ALE_problem@4b31ad9, apple_incremental_game/workspace)
#   2 cp -r .../apple_incremental_game/workspace <cwd>; rm clone -> COPY environment/workspace/ <cwd>
#   3 chmod +x <cwd>/tools/bin/*                                -> chmod below
#   4 heredoc > <cwd>/solution.py (starter)                     -> environment/workspace/solution.py (byte-identical)
#   5 rm -rf .git && git init && git config user.* && add && commit -m init
#                                                               -> kept, author/dates pinned to v1's commit
#   (template) chown -R agent:agent <cwd>; USER agent           -> dropped (root)

# Base = bases/python310 (sforge build passes it as BASE_IMAGE).
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

COPY environment/workspace/ /home/workspace/apple_incremental_game/
RUN chmod +x /home/workspace/apple_incremental_game/tools/bin/*
WORKDIR /home/workspace/apple_incremental_game
# v1 setup: fresh git repo with one "init" commit (agent-visible baseline for git diff).
# Author, email, message and dates = v1's commit 628c6037 (2026-06-05T10:23:23Z).
RUN git init -q && git config user.email 'sebench@local' && git config user.name 'sebench' \
 && git add -A \
 && GIT_AUTHOR_DATE="2026-06-05T10:23:23Z" GIT_COMMITTER_DATE="2026-06-05T10:23:23Z" git commit -q -m 'init' \
 && git log --format='%H %s' -1
CMD ["python3"]
