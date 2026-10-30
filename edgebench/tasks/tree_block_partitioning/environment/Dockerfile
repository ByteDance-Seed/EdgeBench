# Work image for tree_block_partitioning (agent workspace).
# Build context = the task directory:
#   sforge build --task tree_block_partitioning
#
# v1 work.setup_cmds -> this file:
#   1 apt-get install --no-install-recommends python3            -> RUN apt-get below (versions pinned to the
#                                                                    published image, from the base's snapshot)
#   2 mkdir -p /home/workspace/p1                                -> implied by COPY
#   3 curl <internal TOS>/p1_work.tar.gz                         -> files committed under environment/workspace/
#   4 tar xzf ... -C /home/workspace/p1 --strip-components=1     -> COPY environment/workspace/ (problem.md and
#                                                                    prompt.txt are the English versions of the
#                                                                    published image, see NOTES.md)
#   5 rm -f /tmp/p1_work.tar.gz                                  -> nothing to remove
#   6 rm -rf .git && git init && git add -A && git commit 'init' -> RUN git below; v1 re-made this commit after the
#                                                                    translation (2026-07-02T11:18:37Z), pinned here
#   (template) chown -R agent:agent <cwd>; USER agent            -> dropped (root)

# Base = bases/cpp (sforge build passes it as BASE_IMAGE).
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ARG DEBIAN_FRONTEND=noninteractive
# apt sources = the base's dated snapshot (bases/cpp); apt checks GPG + per-.deb sha256.
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      python3=3.10.6-1~22.04.1 \
      python3-minimal=3.10.6-1~22.04.1 \
      libpython3-stdlib=3.10.6-1~22.04.1 \
      python3.10=3.10.12-1~22.04.15 \
      python3.10-minimal=3.10.12-1~22.04.15 \
      libpython3.10-minimal=3.10.12-1~22.04.15 \
      libpython3.10-stdlib=3.10.12-1~22.04.15 \
      libmpdec3=2.5.1-2build2 \
      libreadline8=8.1.2-1 \
      readline-common=8.1.2-1 \
      libsqlite3-0=3.37.2-2ubuntu0.5 \
      media-types=7.0.0; \
    rm -rf /var/lib/apt/lists/*

COPY environment/workspace/ /home/workspace/p1/
# Modes as in v1 (the tarball's down/ files are 0755; statements, prompt and stubs 0644).
RUN set -eux; cd /home/workspace/p1; \
    find . -type d -exec chmod 755 {} +; \
    chmod 644 T1.cpp T2.cpp T3.cpp T4.cpp T5.cpp T6.cpp prompt.txt */problem.md; \
    chmod 755 */down/*
WORKDIR /home/workspace/p1
# v1: fresh repo with one "init" commit (agent-visible baseline for git diff), author/dates pinned.
RUN git init -q && git symbolic-ref HEAD refs/heads/master \
 && git config user.email "sebench@local" && git config user.name "sebench" \
 && git add -A \
 && GIT_AUTHOR_DATE="2026-07-02T11:18:37+00:00" GIT_COMMITTER_DATE="2026-07-02T11:18:37+00:00" git commit -q -m init \
 && git log --format='%H %s' -1
CMD ["/bin/bash"]
