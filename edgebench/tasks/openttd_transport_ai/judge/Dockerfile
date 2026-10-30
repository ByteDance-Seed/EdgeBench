# Judge image for openttd_transport_ai.
# Build context = the task directory:
#   sforge build --task openttd_transport_ai
#
# v1 judge.setup_cmds -> this file:
#   0 mkdir -p <cwd> <cwd>/my_ai                             -> implied by COPY
#   1 pip install --no-cache-dir openttdlab httpx           -> pip install --require-hashes environment/requirements.lock
#   2 git clone --sparse .../ALE_problem.git @13fe6ba        -> sources committed in the task dir
#   3 cp OpenTTD/my_ai/{info,main}.nut <cwd>/my_ai/          -> COPY environment/workspace/my_ai/ (same bytes)
#   4 git init && git config user.* && add && commit -m init -> kept, author/dates pinned to v1's commit
#   5 cp OpenTTD/eval_script.py /tmp/openttd_original_eval.py
#     cp OpenTTD/eval/eval_openttd.py /tmp/eval_openttd.py   -> /judge/openttd_original_eval.py (byte-identical) and
#                                                              /judge/eval_openttd.py (EVAL_SCRIPT path changed to
#                                                              /judge/openttd_original_eval.py, nothing else)
#   6 python3 -c '<patch openttdlab get_yaml>'               -> environment/patch_openttdlab.py (same code)
#   7 run_experiments(... days=30) once (fills ~/.cache/OpenTTDLab/0.0.75/)
#                                                            -> archives fetched from the public OpenTTD CDN (sha256-checked),
#                                                              manifests from environment/openttdlab-cache/; run kept as smoke test
#   v1 eval_cmd + parser score_sum                           -> judge/grade.py (task.toml [judge].cmd)

# Base = bases/python310 (sforge build passes it as BASE_IMAGE).
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

COPY environment/requirements.lock environment/patch_openttdlab.py /root/openttd-setup/
RUN pip install --no-cache-dir --require-hashes -r /root/openttd-setup/requirements.lock \
 && python3 /root/openttd-setup/patch_openttdlab.py \
 && rm -rf /root/openttd-setup

ARG OPENTTD_CDN=https://cdn.openttd.org
COPY environment/openttdlab-cache/ /root/.cache/OpenTTDLab/0.0.75/
RUN set -eux; cd /root/.cache/OpenTTDLab/0.0.75; \
    curl -fsSL -o openttd-13.4-linux-generic-amd64.tar.xz ${OPENTTD_CDN}/openttd-releases/13.4/openttd-13.4-linux-generic-amd64.tar.xz; \
    curl -fsSL -o opengfx-7.1-all.zip ${OPENTTD_CDN}/opengfx-releases/7.1/opengfx-7.1-all.zip; \
    printf '%s\n' \
      '943b7be04130ea790323f70bf5476ccf17692a6e89790748e90aa590b7db4370  openttd-13.4-linux-generic-amd64.tar.xz' \
      '928fcf34efd0719a3560cbab6821d71ce686b6315e8825360fba87a7a94d7846  opengfx-7.1-all.zip' \
      'c630df9377bf2c2c6bc1a5f1d0c1c052bb9f93345c7d3941b1ec40b6f2febe03  manifest-0070f64da951fb43.yaml' \
      'd90dec662496fb51a67790bd7f75dbd3bf9d54d5a374a9c7f76b589ee83bee23  manifest-b3873804ff4a9ff6.yaml' \
      > /root/openttdlab-cache.sha256; \
    sha256sum -c /root/openttdlab-cache.sha256

COPY environment/workspace/my_ai/ /home/workspace/openttd_ai/my_ai/
WORKDIR /home/workspace/openttd_ai
# Author/email/message/date = v1's judge-image commit ff06e929 (2026-06-06T13:55:43Z).
RUN git init -q && git config user.email 'sebench@local' && git config user.name 'sebench' \
 && git add -A \
 && GIT_AUTHOR_DATE="2026-06-06T13:55:43Z" GIT_COMMITTER_DATE="2026-06-06T13:55:43Z" git commit -q -m 'init' \
 && git log --format='%H %an <%ae> %ad' -1

COPY judge/openttd_original_eval.py judge/eval_openttd.py judge/grade.py /judge/
RUN chmod 644 /judge/openttd_original_eval.py && chmod 755 /judge/eval_openttd.py /judge/grade.py

RUN python3 -c "from openttdlab import run_experiments, local_folder; import os; list(run_experiments(openttd_version='13.4', opengfx_version='7.1', experiments=[{'seed': 0, 'ais': (local_folder('/home/workspace/openttd_ai/my_ai', ai_name='MyAI'),), 'days': 30}]))" \
 && cd /root/.cache/OpenTTDLab/0.0.75 && sha256sum -c /root/openttdlab-cache.sha256 && rm /root/openttdlab-cache.sha256 \
 && git -C /home/workspace/openttd_ai status --porcelain | (! grep .)
CMD ["python3"]
