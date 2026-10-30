# Work image for schemathesis_datagen_pipeline (v1: edgebench.work.schemathesis_datagen_pipeline:b52953fc6612).
# Build context = the task directory:
#   sforge build --task schemathesis_datagen_pipeline
#
# v1 work.setup_cmds -> this file:
#   0 git clone --branch sch-4-15-0-roadmap <original task repo, private> /tmp/bench-task
#   1 cp -r /tmp/bench-task/repo/. /app/      -> upstream schemathesis v4.14.3 (d4b9c504) with its two symlinks
#                                               (TROPHY_CASE.md, docs/migration.md) as regular files: the same
#                                               git tree (2131c639) as v1's judge /app; fetched by setup_app.sh
#   2 cat > /app/TODO.md <<... ; chmod 0644   -> COPY environment/TODO.md (byte-identical to the heredoc)
#   3 rm -rf /tmp/bench-task                  -> nothing to remove
#   4 pip install -e ".[tests]" (unpinned)    -> setup_app.sh: pip --require-hashes -r requirements.lock (v1's 80
#   5 pip install pytest-json-ctrf (unpinned)    versions) + the same editable install, hatchling 1.30.1 pinned
#   6 rm -rf .git && git init && git config user.* && git add -A && git commit -m init
#                                             -> same, v1's date pinned: gives v1's exact commit 409ef747
#   (template) chown -R agent:agent /app; USER agent -> dropped (root)
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

# Upstream schemathesis 4.14.3 (tag v4.14.3), GitHub archive tarball.
ARG SCHEMATHESIS_COMMIT=d4b9c5048f09a38f851866f5633c47234b9849f0
ARG SCHEMATHESIS_SHA256=0a38425a6700cbb21c0c10a1873075e8d1b77d899372e0496c09b2bd0edc4cb6

COPY environment/requirements.lock environment/build-requirements.lock environment/setup_app.sh /tmp/ebv/
RUN SCHEMATHESIS_COMMIT=${SCHEMATHESIS_COMMIT} SCHEMATHESIS_SHA256=${SCHEMATHESIS_SHA256} bash /tmp/ebv/setup_app.sh

# Upstream stores TROPHY_CASE.md and docs/migration.md as symlinks (to docs/reference/trophy-case.md
# and MIGRATION.md); in v1's /app they are regular files with the target's content (mode 0644).
WORKDIR /app
RUN for f in TROPHY_CASE.md docs/migration.md; do \
      test -L "$f" && cp --remove-destination "$(readlink -f "$f")" "$f" && chmod 0644 "$f"; \
    done \
 && test -z "$(find /app -type l)"

COPY environment/TODO.md /app/TODO.md
# v1's commit 409ef7473d46e90747dcf9e0071d608d18e18ef1 (tree a492e4bf): bench <bench@local>, 'init',
# 1781168203 = 2026-06-11T08:56:43Z.
RUN chmod 0644 /app/TODO.md \
 && git init -q && git config user.email 'bench@local' && git config user.name 'bench' \
 && git add -A \
 && GIT_AUTHOR_DATE="1781168203 +0000" GIT_COMMITTER_DATE="1781168203 +0000" git commit -m 'init' --quiet \
 && test "$(git rev-parse HEAD)" = 409ef7473d46e90747dcf9e0071d608d18e18ef1
CMD ["python3"]
