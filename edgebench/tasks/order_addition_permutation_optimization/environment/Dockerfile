# Work image for order_addition_permutation_optimization (agent workspace).
# Build context = the task directory:
#   sforge build --task order_addition_permutation_optimization
#
# v1 work.setup_cmds -> this file:
#   1 git clone (sparse) .../ALE_problem.git /tmp/ALE_problem @7642dd8 -> files committed in environment/workspace/
#   2 mkdir -p <cwd> && cp -a .../complex_job_scheduling/. <cwd>/      -> COPY environment/workspace/ <cwd>/
#   3 pip install --upgrade pip setuptools wheel; pip install -r requirements.txt
#                                                                       -> pip install --require-hashes from
#                                                                          pip-bootstrap.lock + requirements.lock
#                                                                          (exact versions of the v1 image's pip freeze)
#   4 rm -rf <cwd>/tests                                                -> tests/ is never copied into the work image
#   5 rm -rf .git && git init && git add -A && git commit -m init       -> kept, author/date/branch pinned to v1's
#                                                                          commit 97ff0ff (re-made on 2026-07-02)
#   later published-image fix layers: English README.md and score_vcpom_result.py -> environment/workspace/ (from
#                                                                          the published image)
#   (template) chown -R agent:agent <cwd>; USER agent                   -> dropped (root)

# Base = bases/python (sforge build passes it as BASE_IMAGE).
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

# Same Python packages as v1 (exact versions and PyPI wheel sha256s). --no-deps: the lock is the full closure.
COPY environment/pip-bootstrap.lock environment/requirements.lock /tmp/pylock/
RUN python -m pip install --no-cache-dir --disable-pip-version-check --require-hashes --no-deps --only-binary :all: \
      -r /tmp/pylock/pip-bootstrap.lock \
 && python -m pip install --no-cache-dir --disable-pip-version-check --require-hashes --no-deps --only-binary :all: \
      -r /tmp/pylock/requirements.lock \
 && rm -rf /tmp/pylock

COPY environment/workspace/ /home/workspace/complex_job_scheduling/
WORKDIR /home/workspace/complex_job_scheduling
# v1's workspace repo (same tree, author, date, branch and message, so the commit hash is v1's 97ff0ff).
RUN git init -q \
 && git symbolic-ref HEAD refs/heads/master \
 && git config user.email "sebench@local" && git config user.name "sebench" \
 && git add -A \
 && GIT_AUTHOR_DATE="2026-07-02T11:18:10Z" GIT_COMMITTER_DATE="2026-07-02T11:18:10Z" git commit -q -m init \
 && git log --format=%H -1
CMD ["python3"]
