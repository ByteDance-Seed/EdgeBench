# Judge image for order_addition_permutation_optimization.
# Build context = the task directory:
#   sforge build --task order_addition_permutation_optimization
#
# v1 judge.setup_cmds -> this file:
#   1 git clone (sparse) .../ALE_problem.git /tmp/ALE_problem @7642dd8 -> files committed in the task dir
#   2 mkdir -p <cwd> && cp -a .../complex_job_scheduling/. <cwd>/      -> COPY environment/workspace/ + judge/tests/
#   3 pip install --upgrade pip setuptools wheel; pip install -r requirements.txt -> same hash-locked install as work
#   later published-image fix layer: README.md, score_vcpom_result.py and tests/score_vcpom_result.py replaced by
#     English translations                                              -> the committed files are those translations
#   v1 eval_cmd + parser pytest_v                                       -> judge/run.sh + judge/result.py
# The hidden tests stay at v1's path <cwd>/tests/ (test_final_result.py locates its private copies and the project
# root relative to its own file). tests/ is excluded from submissions.

ARG BASE_IMAGE
FROM ${BASE_IMAGE}

COPY environment/pip-bootstrap.lock environment/requirements.lock /tmp/pylock/
RUN python -m pip install --no-cache-dir --disable-pip-version-check --require-hashes --no-deps --only-binary :all: \
      -r /tmp/pylock/pip-bootstrap.lock \
 && python -m pip install --no-cache-dir --disable-pip-version-check --require-hashes --no-deps --only-binary :all: \
      -r /tmp/pylock/requirements.lock \
 && rm -rf /tmp/pylock

COPY environment/workspace/ /home/workspace/complex_job_scheduling/
COPY judge/tests/ /home/workspace/complex_job_scheduling/tests/
COPY judge/run.sh judge/result.py /judge/
RUN chmod 755 /judge/run.sh
WORKDIR /home/workspace/complex_job_scheduling
CMD ["python3"]
