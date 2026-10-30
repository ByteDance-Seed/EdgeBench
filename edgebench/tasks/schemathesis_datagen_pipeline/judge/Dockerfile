# Judge image for schemathesis_datagen_pipeline (v1: edgebench.judge.schemathesis_datagen_pipeline:c4be4b8d9369).
# Build context = the task directory:
#   sforge build --task schemathesis_datagen_pipeline
#
# v1 judge.setup_cmds -> this file:
#   0 git clone --branch sch-4-15-0-roadmap <original task repo, private> /tmp/bench-task
#   1 cp -r /tmp/bench-task/repo/. /app/      -> upstream schemathesis v4.14.3 via setup_app.sh + the two symlinks
#                                               made regular files (no TODO.md in the judge, as in v1)
#   2 mkdir -p /tests && cp -r tests/* /tests/ -> COPY judge/tests/ (taken from the published judge image)
#   3 rm -rf /tmp/bench-task                  -> nothing to remove
#   4 pip install -e ".[tests]"; 5 pip install pytest-json-ctrf -> setup_app.sh (same as the work image)
#   6 rm -rf .git && git init ... commit init -> same, v1's date pinned: gives v1's exact commit bbc240b2
#   7 sed -i '/^exit 0$/d; /^exit$/d' /tests/test.sh && cat >> /tests/test.sh <<SEBENCH_EOF ...
#                                             -> already applied: judge/tests/test.sh is the post-step-7 file
#   v1 eval_cmd + parser structured_json      -> judge/run.sh, judge/structured_result.py, judge/write_result.py
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ARG SCHEMATHESIS_COMMIT=d4b9c5048f09a38f851866f5633c47234b9849f0
ARG SCHEMATHESIS_SHA256=0a38425a6700cbb21c0c10a1873075e8d1b77d899372e0496c09b2bd0edc4cb6

COPY environment/requirements.lock environment/build-requirements.lock environment/setup_app.sh /tmp/ebv/
RUN SCHEMATHESIS_COMMIT=${SCHEMATHESIS_COMMIT} SCHEMATHESIS_SHA256=${SCHEMATHESIS_SHA256} bash /tmp/ebv/setup_app.sh

# Same symlink handling as the work image (v1 /app has regular files there).
WORKDIR /app
RUN for f in TROPHY_CASE.md docs/migration.md; do \
      test -L "$f" && cp --remove-destination "$(readlink -f "$f")" "$f" && chmod 0644 "$f"; \
    done \
 && test -z "$(find /app -type l)"

# v1's commit bbc240b2da41bc2197570c044200d79fea460bca (tree 2131c639 = upstream v4.14.3 with the
# symlinks dereferenced): bench <bench@local>, 'init', 1781168202 = 2026-06-11T08:56:42Z.
RUN git init -q && git config user.email 'bench@local' && git config user.name 'bench' \
 && git add -A \
 && GIT_AUTHOR_DATE="1781168202 +0000" GIT_COMMITTER_DATE="1781168202 +0000" git commit -m 'init' --quiet \
 && test "$(git rev-parse HEAD)" = bbc240b2da41bc2197570c044200d79fea460bca

# Hidden tests stay at v1's /tests (test.sh hard-codes it; structured_result.py reads /tests/test.sh).
COPY judge/tests/ /tests/
COPY judge/run.sh judge/structured_result.py judge/write_result.py /judge/
RUN chmod 755 /tests /tests/test.sh /judge/run.sh \
 && chmod 644 /tests/test_0*.py /judge/structured_result.py /judge/write_result.py
CMD ["python3"]
