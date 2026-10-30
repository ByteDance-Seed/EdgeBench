# Work image for dabic_gravity_inversion (agent workspace).
# Build context = the task directory:
#   sforge build --task dabic_gravity_inversion
#
# v1 work.setup_cmds -> this file:
#   0 curl .../dabic_task_files.tar.gz (internal object storage) -o /tmp/...
#   1 tar xzf ... -C /opt/ && rm ...           -> COPY environment/task_files/ /opt/dabic_task_files/
#                                                 (the tarball's 6 files, sha256-identical; v1 never removed /opt/dabic_task_files)
#   2 pip install --no-cache-dir 'simpeg>=0.22.0' 'discretize>=0.10.0' 'numpy>=1.24' 'scipy>=1.11' 'matplotlib>=3.7'
#                                              -> pip install --require-hashes of environment/requirements.lock
#                                                 (the 18 exact versions in the published image; simpeg and pymatsolver
#                                                 are sdist-only and are built with v1's exact build backend,
#                                                 environment/build-requirements.lock)
#   3 mkdir -p <cwd>/outputs                   -> same
#   4-6 cp -r /opt/dabic_task_files/{docs,data,starter} <cwd>/
#                                              -> docs/ and data/ from environment/task_files/; starter/ from
#                                                 environment/workspace/starter/ (the English starter files of the
#                                                 published image, see NOTES.md)
#   7 chmod -R 555 <cwd>/docs <cwd>/data       -> same
#   8 chmod 555 starter/explore_xu_data.py starter/starter.py
#                                              -> not repeated: the published image has them 644 (patch replaced them)
#   9 git init && git config user.* && git add -A && git commit -m init
#                                              -> same, on branch master, dates pinned to the published commit
#                                                 (gives v1's commit 5355d78a)
#   (template) chown -R agent:agent <cwd>; USER agent  -> dropped (root)

# Base = bases/python (sforge build passes it as BASE_IMAGE).
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

# Python deps from public PyPI, every file checked by sha256 (pip --require-hashes).
# The sdist builds use a hash-pinned backend from a throwaway dir (no build isolation, so no
# unpinned download); it is deleted in the same layer. --ignore-installed keeps pip from
# counting the backend's own copy of packaging (in /tmp/bdeps) as already installed.
COPY environment/requirements.lock environment/build-requirements.lock /tmp/
RUN set -eux; \
    pip install --no-cache-dir --require-hashes --target /tmp/bdeps -r /tmp/build-requirements.lock; \
    PYTHONPATH=/tmp/bdeps pip install --no-cache-dir --no-build-isolation --ignore-installed --require-hashes -r /tmp/requirements.lock; \
    rm -rf /tmp/bdeps /tmp/requirements.lock /tmp/build-requirements.lock

# v1 left the extracted task tarball in /opt (agent-visible).
COPY environment/task_files/ /opt/dabic_task_files/

COPY environment/task_files/docs/ /home/workspace/dabic_gravity_vinton/docs/
COPY environment/task_files/data/ /home/workspace/dabic_gravity_vinton/data/
COPY environment/workspace/starter/ /home/workspace/dabic_gravity_vinton/starter/
WORKDIR /home/workspace/dabic_gravity_vinton
# v1 workspace repo: one "init" commit on master. Author/email/message/date = the published
# commit 5355d78a (1782991033 = 2026-07-02T11:17:13Z, when v1 re-initialised the repo).
RUN set -eux; \
    mkdir -p outputs; \
    chmod -R 555 docs data; \
    git init -q; git symbolic-ref HEAD refs/heads/master; \
    git config user.email 'sebench@local'; git config user.name 'sebench'; \
    git add -A; \
    GIT_AUTHOR_DATE="1782991033 +0000" GIT_COMMITTER_DATE="1782991033 +0000" git commit -q -m init; \
    git log --format='%H %an <%ae> %ad' -1
CMD ["python3"]
