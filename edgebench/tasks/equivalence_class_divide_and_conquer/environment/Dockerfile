# Work image for equivalence_class_divide_and_conquer (agent workspace).
# Build context = the task directory:
#   sforge build --task equivalence_class_divide_and_conquer
#
# v1 work.setup_cmds -> this file:
#   1 apt-get install python3                          -> apt-get install below (versions pinned to v1)
#   2 mkdir -p /home/workspace/p2                       -> implied by COPY
#   3 curl <internal TOS>/p2_work.tar.gz                -> files committed under environment/workspace/
#   4 tar xzf ... -C /home/workspace/p2 --strip 1       -> COPY environment/workspace/ <cwd>
#                                                          (English statements as published, see NOTES.md)
#   5 rm -f tarball                                     -> nothing to remove
#   6 rm -rf .git && git init && commit 'init'          -> kept, author/date pinned to the published v1 commit
#   (template) chown -R agent:agent <cwd>; USER agent   -> dropped (root)

# Base = bases/cpp (sforge build passes it as BASE_IMAGE).
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

# python3 from the base's pinned Ubuntu snapshot; versions = the published v1 image.
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      python3=3.10.6-1~22.04.1 python3-minimal=3.10.6-1~22.04.1 \
      python3.10=3.10.12-1~22.04.15 python3.10-minimal=3.10.12-1~22.04.15 \
      libpython3-stdlib=3.10.6-1~22.04.1 \
      libpython3.10-minimal=3.10.12-1~22.04.15 libpython3.10-stdlib=3.10.12-1~22.04.15 \
 && rm -rf /var/lib/apt/lists/*

COPY environment/workspace/ /home/workspace/p2/
WORKDIR /home/workspace/p2
# v1: fresh repo with one "init" commit on master (re-made by the v1 image fix-up on
# 2026-07-02 11:17:17 UTC as sebench <sebench@local>). Same tree + same metadata
# reproduces the published commit fb3f8c9e.
RUN git init -q && git symbolic-ref HEAD refs/heads/master \
 && git config user.email "sebench@local" && git config user.name "sebench" \
 && git add -A \
 && GIT_AUTHOR_DATE="2026-07-02T11:17:17Z" GIT_COMMITTER_DATE="2026-07-02T11:17:17Z" git commit -q -m init \
 && git log --format='%H %an <%ae> %ad' -1
CMD ["/bin/bash"]
