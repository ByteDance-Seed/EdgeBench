# Work image for schemathesis_reporting_observability (v1: edgebench.work.schemathesis_reporting_observability:cd6879e59e62).
# Build context = the task directory:
#   sforge build --task schemathesis_reporting_observability
#
# v1 work.setup_cmds -> this file:
#   0 git clone --branch sch-4-14-0-roadmap <original task repo, private> /tmp/bench-task
#   1 cp -r /tmp/bench-task/repo/. /app/      -> upstream schemathesis v4.13.0 (c759d3c6) fetched by setup_app.sh,
#                                               with its two symlinks replaced by copies of their targets (as in
#                                               v1's /app): the same git tree (4e62aa54) as v1's judge /app
#   2 cat > /app/TODO.md <<... ; chmod 0644   -> COPY environment/TODO.md (byte-identical to the heredoc)
#   3 rm -rf /tmp/bench-task                  -> nothing to remove
#   4 pip install -e ".[tests]" (unpinned)    -> setup_app.sh: pip --require-hashes -r requirements.lock (v1's 80 versions)
#   5 pip install pytest-json-ctrf allure-python-commons (unpinned) -> same lock
#                                             + setup_app.sh: editable install of /app, hatchling 1.30.1 pinned
#   6 rm -rf .git && git init && git config user.* && git add -A && git commit -m init
#                                             -> same, v1's date pinned: gives v1's exact commit 675e0fc2
#   (template) chown -R agent:agent /app; USER agent -> dropped (root)
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

# Upstream schemathesis 4.13.0 (tag v4.13.0), GitHub archive tarball.
ARG SCHEMATHESIS_COMMIT=c759d3c681c777a8a77c5070db655360c7be1af4
ARG SCHEMATHESIS_SHA256=ede6a18e8994d558e60258c76e611da727dc580f326d28036cef6a28d8dab35c

COPY environment/requirements.lock environment/build-requirements.lock environment/setup_app.sh /tmp/ebv/
RUN SCHEMATHESIS_COMMIT=${SCHEMATHESIS_COMMIT} SCHEMATHESIS_SHA256=${SCHEMATHESIS_SHA256} bash /tmp/ebv/setup_app.sh

# v1's /app has TROPHY_CASE.md and docs/migration.md as regular files (mode 0644) holding the
# content of their upstream symlink targets; the private repo stored them dereferenced.
WORKDIR /app
RUN cp --remove-destination docs/reference/trophy-case.md TROPHY_CASE.md \
 && cp --remove-destination MIGRATION.md docs/migration.md \
 && test -z "$(find /app -type l)"

COPY environment/TODO.md /app/TODO.md
# v1's commit 675e0fc2600686b960d7897dfc3c7cd840dcf010 (tree 8410e719): bench <bench@local>, 'init',
# 1781168202 = 2026-06-11T08:56:42Z.
RUN chmod 0644 /app/TODO.md \
 && git init -q && git config user.email 'bench@local' && git config user.name 'bench' \
 && git add -A \
 && GIT_AUTHOR_DATE="1781168202 +0000" GIT_COMMITTER_DATE="1781168202 +0000" git commit -m 'init' --quiet \
 && test "$(git rev-parse HEAD)" = 675e0fc2600686b960d7897dfc3c7cd840dcf010
CMD ["python3"]
