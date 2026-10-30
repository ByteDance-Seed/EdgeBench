# Judge image for schemathesis_config_modernization (v1: edgebench.judge.schemathesis_config_modernization:affdace5163f).
# Build context = the task directory:
#   sforge build --task schemathesis_config_modernization
#
# v1 judge.setup_cmds -> this file:
#   0 git clone --branch sch-4-0-0-roadmap <original task repo, private> /tmp/bench-task
#   1 cp -r /tmp/bench-task/repo/. /app/      -> upstream schemathesis v3.39.16 via setup_app.sh (no TODO.md in the judge, as in v1)
#   2 mkdir -p /tests && cp -r tests/* /tests/ -> COPY judge/tests/ (taken from the published judge image)
#   3 rm -rf /tmp/bench-task                  -> nothing to remove
#   4 pip install ... ; 5 pip install -e .    -> setup_app.sh (same as the work image)
#   6 rm -rf .git && git init ... commit init -> same, v1's date pinned: gives v1's exact commit 4ce14f61
#   7 sed -i '/^exit 0$/d; /^exit$/d' /tests/test.sh && cat >> /tests/test.sh <<SEBENCH_EOF ...
#                                             -> already applied: judge/tests/test.sh is the post-step-7 file
#   v1 eval_cmd + parser structured_json      -> judge/run.sh, judge/structured_result.py, judge/write_result.py
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ARG SCHEMATHESIS_COMMIT=b142d029b70ae2cd369fd9c7b9697628caba48df
ARG SCHEMATHESIS_SHA256=8177f7c01563670285787451c0fd8b02037c4a17116cf2e2db75069f7aaf568f

COPY environment/requirements.lock environment/build-requirements.lock environment/setup_app.sh /tmp/ebv/
RUN SCHEMATHESIS_COMMIT=${SCHEMATHESIS_COMMIT} SCHEMATHESIS_SHA256=${SCHEMATHESIS_SHA256} bash /tmp/ebv/setup_app.sh

WORKDIR /app
# v1's commit 4ce14f61571682005fe7c98cbf2399f0590dbcc8 (tree 3e8d9582 = upstream v3.39.16):
# bench <bench@local>, 'init', 1781168200 = 2026-06-11T08:56:40Z.
RUN git init -q && git config user.email 'bench@local' && git config user.name 'bench' \
 && git add -A \
 && GIT_AUTHOR_DATE="1781168200 +0000" GIT_COMMITTER_DATE="1781168200 +0000" git commit -m 'init' --quiet \
 && test "$(git rev-parse HEAD)" = 4ce14f61571682005fe7c98cbf2399f0590dbcc8

# Hidden tests stay at v1's /tests (test.sh hard-codes it; structured_result.py reads /tests/test.sh).
COPY judge/tests/ /tests/
COPY judge/run.sh judge/structured_result.py judge/write_result.py /judge/
RUN chmod 755 /tests /tests/test.sh /judge/run.sh \
 && chmod 644 /tests/test_0*.py /judge/structured_result.py /judge/write_result.py
CMD ["python3"]
