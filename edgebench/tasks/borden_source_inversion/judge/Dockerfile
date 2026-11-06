# Judge image for borden_source_inversion.
# Build context = the task directory:
#   sforge build --task borden_source_inversion
#
# v1 judge.setup_cmds -> this file:
#   0 apt-get update && apt-get install -y curl unzip        -> dropped (already in the base)
#   1 mkdir -p <cwd> /tmp/borden_inverse_bundle               -> implied by COPY
#   2 curl .../borden_inverse_private_judge_bundle.zip (internal object storage, v0.1.0)
#   3 unzip; 4 cp -a bundle/borden_inverse/. <cwd>; 5 rm bundle
#                                                             -> the 10 public files = environment/workspace/ (same bytes
#                                                                in both bundles); scoring/ committed as judge/scoring/
#   6 pip install --no-cache-dir -r requirements.txt          -> pip install --require-hashes of environment/requirements.lock
#     && mkdir -p /opt/borden_scoring && cp -a scoring/. /opt/borden_scoring/
#                                                             -> COPY judge/scoring/ to both <cwd>/scoring/ and /opt/borden_scoring/
#                                                                (v1 keeps both copies; evaluate.py reads /opt/borden_scoring)
#   (no git repo in the v1 judge image)
#   v1 eval_cmd + parser structured_json                      -> judge/run.sh + judge/emit_result.py (task.toml [judge].cmd)

# Base = bases/python310 (sforge build passes it as BASE_IMAGE).
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

COPY environment/requirements.lock /tmp/requirements.lock
RUN pip install --no-cache-dir --require-hashes -r /tmp/requirements.lock \
 && rm /tmp/requirements.lock

COPY environment/workspace/ /home/workspace/borden_inverse/
COPY judge/scoring/ /home/workspace/borden_inverse/scoring/
COPY judge/scoring/ /opt/borden_scoring/
COPY judge/run.sh judge/emit_result.py /judge/
RUN chmod 755 /judge/run.sh /judge/emit_result.py
WORKDIR /home/workspace/borden_inverse
CMD ["python3"]
