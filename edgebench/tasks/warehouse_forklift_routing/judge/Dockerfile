# Judge image for warehouse_forklift_routing.
# Build context = the task directory:
#   sforge build --task warehouse_forklift_routing
#
# v1 judge.setup_cmds -> this file:
#   0 mkdir -p /home/workspace                                   -> implied
#   1 git clone .../ALE_problem.git /tmp/ALE_problem             -> sources committed in the task dir (ALE_problem@d0a6656)
#   2 mkdir -p <cwd>/tools/bin <cwd>/cases                       -> implied by COPY
#   3 cp .../workspace/tools/bin/* <cwd>/tools/bin/              -> COPY environment/workspace/tools/bin/
#   4 cp .../workspace/README.md <cwd>/                          -> COPY environment/workspace/README.md
#   5 cp .../internal/cases/public/* <cwd>/cases/                -> COPY judge/cases/ (50 hidden cases)
#   6 rm -rf /tmp/ALE_problem                                    -> nothing to remove
#   7 chmod +x <cwd>/tools/bin/*                                 -> chmod below
#   8 python3 -c "... write solution.py" (starter)               -> COPY environment/workspace/solution.py (same bytes)
#   9 rm -rf .git && git init && git config user.* && add && commit -m init
#                                                                -> kept, author/dates pinned to v1's commit
#  10 heredoc > /tmp/eval_warehouse_manager.py; chmod +x         -> COPY judge/eval_warehouse_manager.py
#                                                                   /judge/ (byte-identical, moved out of /tmp)
#   v1 eval_cmd + parser score_sum                               -> judge/grade.py (task.toml [judge].cmd)
# (v1 judge image has no tools/src/ and no tools/README.md; neither is needed: tester is self-contained.)

# Base = bases/python310 (sforge build passes it as BASE_IMAGE).
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

COPY environment/workspace/tools/bin/ /home/workspace/warehouse_manager/tools/bin/
COPY environment/workspace/README.md environment/workspace/solution.py /home/workspace/warehouse_manager/
COPY judge/cases/ /home/workspace/warehouse_manager/cases/
RUN chmod +x /home/workspace/warehouse_manager/tools/bin/*
WORKDIR /home/workspace/warehouse_manager
# Author, email, message and dates = v1's judge-image commit a200e739 (2026-06-09T12:47:33Z).
RUN git init -q && git config user.email 'sebench@local' && git config user.name 'sebench' \
 && git add -A \
 && GIT_AUTHOR_DATE="2026-06-09T12:47:33Z" GIT_COMMITTER_DATE="2026-06-09T12:47:33Z" git commit -q -m 'init' \
 && git log --format='%H %s' -1
COPY judge/eval_warehouse_manager.py judge/grade.py /judge/
RUN chmod 755 /judge/eval_warehouse_manager.py /judge/grade.py
CMD ["python3"]
