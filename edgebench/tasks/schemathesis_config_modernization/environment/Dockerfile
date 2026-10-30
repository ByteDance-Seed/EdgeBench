# Work image for schemathesis_config_modernization (v1: edgebench.work.schemathesis_config_modernization:f9e5ec2c6f1f).
# Build context = the task directory:
#   sforge build --task schemathesis_config_modernization
#
# v1 work.setup_cmds -> this file:
#   0 git clone --branch sch-4-0-0-roadmap <original task repo, private> /tmp/bench-task
#   1 cp -r /tmp/bench-task/repo/. /app/      -> upstream schemathesis v3.39.16 (b142d029), the same git tree
#                                               (3e8d9582) as v1's /app; fetched by setup_app.sh
#   2 cat > /app/TODO.md <<... ; chmod 0644   -> COPY environment/TODO.md (byte-identical to the heredoc)
#   3 rm -rf /tmp/bench-task                  -> nothing to remove
#   4 pip install pytest ... (unpinned)       -> setup_app.sh: pip --require-hashes -r requirements.lock (v1's 72 versions)
#   5 pip install -e .                        -> setup_app.sh: same editable install, hatchling 1.30.1 pinned
#   6 rm -rf .git && git init && git config user.* && git add -A && git commit -m init
#                                             -> same, v1's date pinned: gives v1's exact commit b141a312
#   (template) chown -R agent:agent /app; USER agent -> dropped (root)
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

# Upstream schemathesis 3.39.16 (tag v3.39.16), GitHub archive tarball.
ARG SCHEMATHESIS_COMMIT=b142d029b70ae2cd369fd9c7b9697628caba48df
ARG SCHEMATHESIS_SHA256=8177f7c01563670285787451c0fd8b02037c4a17116cf2e2db75069f7aaf568f

COPY environment/requirements.lock environment/build-requirements.lock environment/setup_app.sh /tmp/ebv/
RUN SCHEMATHESIS_COMMIT=${SCHEMATHESIS_COMMIT} SCHEMATHESIS_SHA256=${SCHEMATHESIS_SHA256} bash /tmp/ebv/setup_app.sh

COPY environment/TODO.md /app/TODO.md
WORKDIR /app
# v1's commit b141a3122615a1316a1e0669afae32ca5aedc1d4 (tree fe637f34): bench <bench@local>, 'init',
# 1781168194 = 2026-06-11T08:56:34Z.
RUN chmod 0644 /app/TODO.md \
 && git init -q && git config user.email 'bench@local' && git config user.name 'bench' \
 && git add -A \
 && GIT_AUTHOR_DATE="1781168194 +0000" GIT_COMMITTER_DATE="1781168194 +0000" git commit -m 'init' --quiet \
 && test "$(git rev-parse HEAD)" = b141a3122615a1316a1e0669afae32ca5aedc1d4
CMD ["python3"]
