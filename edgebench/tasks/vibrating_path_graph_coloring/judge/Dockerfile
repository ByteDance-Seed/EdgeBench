# Judge image for vibrating_path_graph_coloring.
# Build context = the task directory:
#   sforge build --task vibrating_path_graph_coloring
#
# v1 judge.setup_cmds (old id `vbr`) -> this file:
#   0 mkdir -p /home/workspace                                  -> implied
#   1 git clone .../ALE_problem.git /tmp/ALE_problem            -> sources committed in the task dir
#   2 mkdir -p <cwd>/tools/bin <cwd>/cases                      -> implied by COPY
#   3 cp .../workspace/tools/bin/* <cwd>/tools/bin/             -> COPY environment/workspace/tools/bin/
#   4 cp .../workspace/README.md <cwd>/                         -> COPY environment/workspace/README.md
#   5 cp .../internal/cases/public/* <cwd>/cases/               -> COPY judge/cases/ (50 cases, ALE_problem@d0a6656)
#   6 rm -rf /tmp/ALE_problem                                   -> nothing to remove
#   7 chmod +x <cwd>/tools/bin/*                                -> chmod below
#   8 heredoc > <cwd>/solution.py (baseline)                    -> COPY environment/workspace/solution.py (byte-identical;
#                                                                  v1 grades it when the submission has no solution.py)
#   9 rm -rf .git && git init && ... commit -m 'init'           -> same, v1's commit dates pinned (the judge never reads it)
#  10 heredoc > /tmp/eval_vibrating_path.py; chmod +x           -> COPY judge/eval_vibrating_path.py /judge/ (byte-identical)
#   v1 eval_cmd + parser score_sum                              -> judge/grade.py (task.toml [judge].cmd)

# Base = bases/python310 (sforge build passes it as BASE_IMAGE).
ARG BASE_IMAGE
FROM ${BASE_IMAGE}
COPY environment/workspace/tools/bin/ /home/workspace/vibrating_path/tools/bin/
COPY environment/workspace/README.md environment/workspace/solution.py /home/workspace/vibrating_path/
COPY judge/cases/ /home/workspace/vibrating_path/cases/
WORKDIR /home/workspace/vibrating_path
RUN chmod +x tools/bin/*
# Author/email/message/dates = v1's judge-image commit 551a3acc (2026-06-06T13:55:45Z).
RUN git init -q && git config user.email 'sebench@local' && git config user.name 'sebench' \
 && git add -A \
 && GIT_AUTHOR_DATE="2026-06-06T13:55:45Z" GIT_COMMITTER_DATE="2026-06-06T13:55:45Z" git commit -q -m 'init' \
 && git log --format='%H %an <%ae> %ad' -1
COPY judge/eval_vibrating_path.py judge/grade.py /judge/
RUN chmod 755 /judge/eval_vibrating_path.py /judge/grade.py
CMD ["python3"]
