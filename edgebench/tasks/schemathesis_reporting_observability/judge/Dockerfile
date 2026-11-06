# Judge image for schemathesis_reporting_observability (v1: edgebench.judge.schemathesis_reporting_observability:21a26db29432).
# Build context = the task directory:
#   sforge build --task schemathesis_reporting_observability
#
# v1 judge.setup_cmds -> this file:
#   0 git clone --branch sch-4-14-0-roadmap <original task repo, private> /tmp/bench-task
#   1 cp -r /tmp/bench-task/repo/. /app/      -> upstream schemathesis v4.13.0 via setup_app.sh, symlinks dereferenced
#                                               as in the work image (no TODO.md in the judge, as in v1)
#   2 mkdir -p /tests && cp -r tests/* /tests/ -> COPY judge/tests/ (taken from the published judge image)
#   3 rm -rf /tmp/bench-task                  -> nothing to remove
#   4 pip install -e ".[tests]" ; 5 pip install pytest-json-ctrf allure-python-commons
#                                             -> setup_app.sh (same as the work image)
#   6 rm -rf .git && git init ... commit init -> same, v1's date pinned: gives v1's exact commit c06ecadf
#   7 sed -i '/^exit 0$/d; /^exit$/d' /tests/test.sh && cat >> /tests/test.sh <<SEBENCH_EOF ...
#                                             -> already applied: judge/tests/test.sh is the post-step-7 file
#   v1 eval_cmd + parser structured_json      -> judge/run.sh, judge/structured_result.py, judge/write_result.py
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ARG SCHEMATHESIS_COMMIT=c759d3c681c777a8a77c5070db655360c7be1af4
ARG SCHEMATHESIS_SHA256=ede6a18e8994d558e60258c76e611da727dc580f326d28036cef6a28d8dab35c

COPY environment/requirements.lock environment/build-requirements.lock environment/setup_app.sh /tmp/ebv/
RUN SCHEMATHESIS_COMMIT=${SCHEMATHESIS_COMMIT} SCHEMATHESIS_SHA256=${SCHEMATHESIS_SHA256} bash /tmp/ebv/setup_app.sh

WORKDIR /app
RUN cp --remove-destination docs/reference/trophy-case.md TROPHY_CASE.md \
 && cp --remove-destination MIGRATION.md docs/migration.md \
 && test -z "$(find /app -type l)"
# v1's commit c06ecadf10636e8ca5006649fd17a5e298d0b0b1 (tree 4e62aa54 = upstream v4.13.0, symlinks dereferenced):
# bench <bench@local>, 'init', 1781168201 = 2026-06-11T08:56:41Z.
RUN git init -q && git config user.email 'bench@local' && git config user.name 'bench' \
 && git add -A \
 && GIT_AUTHOR_DATE="1781168201 +0000" GIT_COMMITTER_DATE="1781168201 +0000" git commit -m 'init' --quiet \
 && test "$(git rev-parse HEAD)" = c06ecadf10636e8ca5006649fd17a5e298d0b0b1

# Hidden tests stay at v1's /tests (test.sh hard-codes it; structured_result.py reads /tests/test.sh).
COPY judge/tests/ /tests/
COPY judge/run.sh judge/structured_result.py judge/write_result.py /judge/
RUN chmod 755 /tests /tests/test.sh /judge/run.sh \
 && chmod 644 /tests/test_0*.py /judge/structured_result.py /judge/write_result.py
CMD ["python3"]
