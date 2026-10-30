# Work image for integer_compression_codec (agent workspace).
# Build context = the task directory:
#   sforge build --task integer_compression_codec
#
# v1 work.setup_cmds -> this file:
#   0 rm -rf /tmp/sebench-src <cwd> && mkdir -p ...          -> implied by COPY
#   1 git clone se-bmk-intern (branch <author>)           -> sources committed in environment/workspace/
#   2 cp -R .../integer-compression-codec-agent/. <cwd>/       -> COPY environment/workspace/ <cwd>
#                                                                (five docs are the English versions from the published image, see NOTES.md)
#   3 apt-get install python3 python3-numpy                    -> environment/install_python.sh (versions pinned)
#   4 python3 tools/gen_data.py                                -> same command, output checked against v1 sha256
#   5 rm -rf outputs .git                                      -> nothing to remove (no clone .git is copied)
#   6 git init && git config user.* && git add -A && commit    -> kept, as re-made by the v1 fix layer (master, pinned dates)
#   (template) chown -R agent:agent <cwd>; USER agent          -> dropped (root)

ARG BASE_IMAGE
FROM ${BASE_IMAGE}

COPY environment/install_python.sh /tmp/install_python.sh
RUN sh /tmp/install_python.sh && rm /tmp/install_python.sh

COPY environment/workspace/ /home/workspace/integer-compression-codec/
COPY environment/datasets.sha256 /tmp/datasets.sha256
WORKDIR /home/workspace/integer-compression-codec
# Public small-sample datasets (8 files, 45 MB total), generated exactly as in v1.
RUN python3 tools/gen_data.py \
 && sha256sum -c /tmp/datasets.sha256 \
 && rm /tmp/datasets.sha256

# Agent-visible baseline commit. v1 committed once in setup and then re-made the repo in
# a later fix layer (same author, branch master, message "init") after translating the
# docs; author/committer dates are pinned to that commit, so the hash equals v1's 0084ff3b.
RUN git init -q && git symbolic-ref HEAD refs/heads/master \
 && git config user.email "sebench@local" && git config user.name "sebench" \
 && git add -A \
 && GIT_AUTHOR_DATE="2026-07-02T11:17:40+0000" GIT_COMMITTER_DATE="2026-07-02T11:17:40+0000" git commit -q -m init \
 && git log --format=%H -1
CMD ["/bin/bash"]
