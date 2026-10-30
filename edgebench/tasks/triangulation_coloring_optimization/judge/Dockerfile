# Judge image for triangulation_coloring_optimization.
# Build context = the task directory:
#   sforge build --task triangulation_coloring_optimization
#
# v1 judge.setup_cmds -> this file:
#   0 mkdir -p /home/workspace                                   -> implied
#   1 git clone .../ALE_problem.git /tmp/ALE_problem             -> sources committed in the task dir (ALE_problem@2e6be68)
#   2 mkdir -p <cwd>/tools/bin <cwd>/cases                       -> implied by COPY
#   3 cp .../workspace/tools/bin/* <cwd>/tools/bin/              -> COPY environment/workspace/tools/bin/
#   4 cp -r .../workspace/tools/src <cwd>/tools/src              -> COPY environment/workspace/tools/src/
#   5 cp .../workspace/README.md <cwd>/                          -> COPY environment/workspace/README.md
#   6 cp .../internal/cases/public/* <cwd>/cases/                -> COPY judge/cases/ (10 hidden cases)
#   7 rm -rf /tmp/ALE_problem                                    -> nothing to remove
#   8 chmod +x <cwd>/tools/bin/*                                 -> chmod below
#   9 heredoc > <cwd>/solution.py (starter)                      -> COPY environment/workspace/solution.py (same bytes)
#  10 rm -rf .git && git init && git config user.* && add && commit -m init
#                                                                -> kept, author/dates pinned to v1's commit
#  11 heredoc > /tmp/eval_triangulation_coloring.py; chmod +x    -> COPY judge/eval_triangulation_coloring.py
#                                                                   /judge/ (byte-identical, moved out of /tmp)
#   v1 eval_cmd + parser score_sum                               -> judge/grade.py (task.toml [judge].cmd)

# Base = bases/python310 (sforge build passes it as BASE_IMAGE).
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

COPY environment/workspace/tools/bin/ /home/workspace/triangulation_coloring/tools/bin/
COPY environment/workspace/tools/src/ /home/workspace/triangulation_coloring/tools/src/
COPY environment/workspace/README.md environment/workspace/solution.py /home/workspace/triangulation_coloring/
COPY judge/cases/ /home/workspace/triangulation_coloring/cases/
RUN chmod +x /home/workspace/triangulation_coloring/tools/bin/*
WORKDIR /home/workspace/triangulation_coloring
# Author, email, message and dates = v1's judge-image commit 29944c94 (2026-06-06T13:55:40Z).
RUN git init -q && git config user.email 'sebench@local' && git config user.name 'sebench' \
 && git add -A \
 && GIT_AUTHOR_DATE="2026-06-06T13:55:40Z" GIT_COMMITTER_DATE="2026-06-06T13:55:40Z" git commit -q -m 'init' \
 && git log --format='%H %s' -1
COPY judge/eval_triangulation_coloring.py judge/grade.py /judge/
RUN chmod 755 /judge/eval_triangulation_coloring.py /judge/grade.py
CMD ["python3"]
