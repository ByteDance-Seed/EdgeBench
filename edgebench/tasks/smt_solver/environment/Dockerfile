# Work image for smt_solver (agent workspace).
# Build context = the task directory:
#   sforge build --task smt_solver
#
# v1 work.setup_cmds -> this file:
#   1 mkdir -p /tmp/sebench_resources <cwd>                 -> implied by COPY
#   2 git clone se-bmk-intern (branch <author>)              -> sources committed under environment/workspace/
#                                                               (SMT/problem/ @ 5e59079d5, see NOTES.md)
#   3 cp -a .../SMT/problem/. <cwd>/                         -> COPY environment/workspace/ (README.md, smtlib_spec.md,
#                                                               paper-md/, papers/, scripts/evaluate.py)
#   4 download SMT-benchmarks.zip (internal TOS), extract    -> environment/workspace/benchmarks/ committed in plaintext,
#     into <cwd>/benchmarks                                     taken from the published work image
#   5 rm -rf /tmp/sebench_resources /tmp/sebench_data        -> nothing to remove
#   6 heredocs > build.sh, solve; mkdir -p src; chmod +x     -> environment/workspace/{build.sh,solve} (byte-identical)
#                                                               + mkdir src below (git cannot hold an empty dir)
#   7 rm -rf .git && git init, user sebench/sebench@local,   -> same commands below, dates pinned to v1's commit
#     git add -A && git commit -m init                          (2026-06-05T14:26:51Z)
#   (template) chown -R agent:agent <cwd>; USER agent         -> dropped (root)

# Base = bases/python310 (sforge build passes it as BASE_IMAGE).
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

COPY environment/workspace/ /home/workspace/smt_solver/
WORKDIR /home/workspace/smt_solver
# Modes as in v1 (zip/cp gave 644 files and 755 dirs; build.sh and solve 755).
RUN mkdir -p src \
 && find . -type d -exec chmod 755 {} + \
 && find . -type f -exec chmod 644 {} + \
 && chmod 755 build.sh solve \
 && git init -q && git config user.email 'sebench@local' && git config user.name 'sebench' \
 && git add -A \
 && GIT_AUTHOR_DATE="2026-06-05T14:26:51Z" GIT_COMMITTER_DATE="2026-06-05T14:26:51Z" git commit -q -m 'init' \
 && git log --format='%H %an <%ae> %ad' -1
CMD ["python3"]
