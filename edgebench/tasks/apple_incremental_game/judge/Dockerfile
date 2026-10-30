# Judge image for apple_incremental_game.
# Build context = the task directory:
#   sforge build --task apple_incremental_game
#
# v1 judge.setup_cmds -> this file:
#   0 mkdir -p /home/workspace                                   -> implied
#   1 git clone .../ALE_problem.git /tmp/ALE_problem             -> sources committed in the task dir (ALE_problem@4b31ad9)
#   2 mkdir -p <cwd>/tools/bin <cwd>/cases                       -> implied by COPY
#   3 cp .../workspace/tools/bin/* <cwd>/tools/bin/              -> COPY environment/workspace/tools/bin/
#   4 cp .../workspace/README.md <cwd>/                          -> COPY environment/workspace/README.md
#   5 cp .../internal/cases/public/* <cwd>/cases/                -> COPY judge/cases/ (50 hidden cases)
#   6 rm -rf /tmp/ALE_problem                                    -> nothing to remove
#   7 chmod +x <cwd>/tools/bin/*                                 -> chmod below
#   8 heredoc > <cwd>/solution.py (starter)                      -> COPY environment/workspace/solution.py (same bytes)
#   9 rm -rf .git && git init && git config user.* && add && commit -m init
#                                                                -> kept, author/dates pinned to v1's commit
#  10 heredoc > /tmp/eval_apple_incremental_game.py; chmod +x    -> COPY judge/eval_apple_incremental_game.py /judge/
#                                                                   (byte-identical, moved out of /tmp)
#   v1 eval_cmd + parser score_sum                               -> judge/grade.py (task.toml [judge].cmd)

# Base = bases/python310 (sforge build passes it as BASE_IMAGE).
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

COPY environment/workspace/tools/bin/ /home/workspace/apple_incremental_game/tools/bin/
COPY environment/workspace/README.md environment/workspace/solution.py /home/workspace/apple_incremental_game/
COPY judge/cases/ /home/workspace/apple_incremental_game/cases/
RUN chmod +x /home/workspace/apple_incremental_game/tools/bin/*
WORKDIR /home/workspace/apple_incremental_game
# Author, email, message and dates = v1's judge-image commit c8aa63f1 (2026-06-05T10:23:22Z).
RUN git init -q && git config user.email 'sebench@local' && git config user.name 'sebench' \
 && git add -A \
 && GIT_AUTHOR_DATE="2026-06-05T10:23:22Z" GIT_COMMITTER_DATE="2026-06-05T10:23:22Z" git commit -q -m 'init' \
 && git log --format='%H %s' -1
COPY judge/eval_apple_incremental_game.py judge/grade.py /judge/
RUN chmod 755 /judge/eval_apple_incremental_game.py /judge/grade.py
CMD ["python3"]
