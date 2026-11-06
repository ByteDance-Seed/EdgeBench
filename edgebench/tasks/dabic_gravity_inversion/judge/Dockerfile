# Judge image for dabic_gravity_inversion.
# Build context = the task directory:
#   sforge build --task dabic_gravity_inversion
#
# v1 judge.setup_cmds -> this file:
#   0 curl .../dabic_judge_files.tar.gz (internal object storage) -o /tmp/...
#   1 tar xzf ... -C /opt/ && rm ...           -> dropped: /opt/dabic_judge_files (a second copy of eval_dabic_v2.py
#                                                 plus stray cpython-310/314 .pyc) is never read by the grader
#   2 pip install --no-cache-dir simpeg discretize numpy scipy matplotlib
#                                              -> same pinned install as the work image
#   3 mkdir -p /opt/evaluator; 4 cp eval_dabic_v2.py /opt/evaluator/; 5 chmod -R 555 /opt/evaluator
#                                              -> COPY judge/eval_dabic_v2.py (sha256-identical), chmod 555
#   (template) WORKDIR <cwd> (empty directory, root)
#   v1 eval_cmd + parser structured_json       -> judge/run.sh + judge/emit_result.py (task.toml [judge].cmd)

# Base = bases/python (sforge build passes it as BASE_IMAGE).
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

COPY environment/requirements.lock environment/build-requirements.lock /tmp/
RUN set -eux; \
    pip install --no-cache-dir --require-hashes --target /tmp/bdeps -r /tmp/build-requirements.lock; \
    PYTHONPATH=/tmp/bdeps pip install --no-cache-dir --no-build-isolation --ignore-installed --require-hashes -r /tmp/requirements.lock; \
    rm -rf /tmp/bdeps /tmp/requirements.lock /tmp/build-requirements.lock

COPY judge/eval_dabic_v2.py /opt/evaluator/
COPY judge/run.sh judge/emit_result.py /judge/
RUN chmod -R 555 /opt/evaluator && chmod 755 /judge/run.sh /judge/emit_result.py \
 && mkdir -p /home/workspace/dabic_gravity_vinton
WORKDIR /home/workspace/dabic_gravity_vinton
CMD ["python3"]
