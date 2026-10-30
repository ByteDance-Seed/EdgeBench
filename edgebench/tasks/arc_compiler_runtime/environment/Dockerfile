# Work image for arc_compiler_runtime (v1: edgebench.work.arc_compiler_runtime:c92a7b116597).
# Build context = the task directory:
#   sforge build --task arc_compiler_runtime
#
# v1 work.setup_cmds (SE-bench-harness arc_compiler_runtime_implementation.json) -> this file:
#   0 apt-get install nodejs npm wget                         -> environment/setup_node.sh (Debian snapshot, versions
#                                                                checked against environment/node-packages.lock)
#   1 mkdir -p /home/workspace/arc-compiler-runtime-implementation -> implied by COPY
#   2 git clone se-bmk-intern (branch <author>, sparse)        -> sources committed under environment/workspace/agent-start/
#   3 cp -a .../arc-lang-starter-public/agent-start <cwd>;       (original task repo @ cc45561, see NOTES.md)
#     cp .../arc-lang-starter-public/problem.md <cwd>/         -> COPY environment/workspace/agent-start/
#   4 download datasets tarball (internal object storage),    -> environment/workspace/agent-start/tests/public-smoke/
#     copy public/public-smoke to <cwd>/tests/public-smoke        committed, taken from the published work image
#   5 npm ci (no node_modules in the repo); chmod +x score.sh  -> same below (registry.npmjs.org, lockfile with sha512
#     node_modules/.bin/tsx                                       integrity for all 94 packages)
#   6 rm -rf compiler/dist; delete .DS_Store                  -> same (both no-ops)
#   7 git init, user sebench/sebench@local, add -A, commit init -> same, dates pinned to v1's commit 2026-06-11T08:58:32Z
#   (template) chown -R agent:agent <cwd>; USER agent          -> dropped (root)
ARG BASE_IMAGE
FROM ${BASE_IMAGE}
ARG DEBIAN_FRONTEND=noninteractive

COPY environment/setup_node.sh environment/node-packages.lock /tmp/node-setup/
RUN sh /tmp/node-setup/setup_node.sh && rm -rf /tmp/node-setup

COPY environment/workspace/agent-start/ /home/workspace/arc-compiler-runtime-implementation/agent-start/
WORKDIR /home/workspace/arc-compiler-runtime-implementation/agent-start
RUN find . -type d -exec chmod 755 {} + \
 && find . -type f -exec chmod 644 {} + \
 && if [ ! -d node_modules ]; then npm ci; fi && chmod +x score.sh node_modules/.bin/tsx \
 && rm -rf compiler/dist && find . -name '.DS_Store' -delete \
 && git init -q && git config user.email 'sebench@local' && git config user.name 'sebench' \
 && git add -A \
 && GIT_AUTHOR_DATE='2026-06-11T08:58:32Z' GIT_COMMITTER_DATE='2026-06-11T08:58:32Z' git commit -q -m 'init' \
 && git log --format='%H %an <%ae> %ad' -1

CMD ["python3"]
