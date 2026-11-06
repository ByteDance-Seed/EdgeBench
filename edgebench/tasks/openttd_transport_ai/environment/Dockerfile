# Work image for openttd_transport_ai (agent workspace).
# Build context = the task directory:
#   sforge build --task openttd_transport_ai
#
# v1 work.setup_cmds -> this file:
#   0 mkdir -p <cwd> <cwd>/my_ai <cwd>/docs                 -> implied by COPY below
#   1 pip install --no-cache-dir openttdlab httpx           -> pip install --require-hashes environment/requirements.lock
#                                                              (the 16 versions pip freeze shows in the published images)
#   2 git clone --sparse .../ALE_problem.git @13fe6ba        -> sources committed under environment/workspace/
#   3 cp OpenTTD/my_ai/{info,main}.nut <cwd>/my_ai/          -> environment/workspace/my_ai/ (byte-identical)
#   4 cp squirrel_reference.html noai_tutorial.html noai_api_docs.zip <cwd>/docs/
#   5 unzip noai_api_docs.zip in docs/ && rm it              -> environment/workspace/docs/ = the two html files plus
#                                                              the zip's extracted tree docs/openttd_reference_docs/
#   6 git init && git config user.* && add && commit -m init -> kept, author/dates pinned to v1's commit
#   7 python3 -c '<patch openttdlab get_yaml>'               -> environment/patch_openttdlab.py (same code)
#   8 run_experiments(... days=30) once, which downloads OpenTTD 13.4 + OpenGFX 7.1 and the two
#     manifests into ~/.cache/OpenTTDLab/0.0.75/            -> archives fetched below from the public OpenTTD CDN
#                                                              (sha256-checked), manifests committed in
#                                                              environment/openttdlab-cache/; the 30-day run is kept
#                                                              as a smoke test
#   9 cp -a /root/.cache/OpenTTDLab /home/agent/.cache/; chown agent
#                                                            -> dropped: the agent is root, the cache is /root/.cache
#   (template) chown -R agent:agent <cwd>; USER agent        -> dropped (root)

# Base = bases/python310 (sforge build passes it as BASE_IMAGE).
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

# Python deps from public PyPI, every wheel checked by sha256 (pip --require-hashes).
COPY environment/requirements.lock environment/patch_openttdlab.py /root/openttd-setup/
RUN pip install --no-cache-dir --require-hashes -r /root/openttd-setup/requirements.lock \
 && python3 /root/openttd-setup/patch_openttdlab.py \
 && rm -rf /root/openttd-setup

# OpenTTDLab cache (user_cache_dir('OpenTTDLab', '0.0.75') = /root/.cache/OpenTTDLab/0.0.75):
# the release archives OpenTTDLab would download, pinned by the sha256 in the OpenTTD CDN manifests,
# plus those manifests (read by the patched get_yaml when there is no network).
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

COPY environment/workspace/ /home/workspace/openttd_ai/
WORKDIR /home/workspace/openttd_ai
# v1 setup: fresh git repo with one "init" commit (agent-visible baseline for git diff).
# Author/email/message/date = v1's commit 1ae28db0 (2026-06-06T13:55:44Z).
RUN git init -q && git config user.email 'sebench@local' && git config user.name 'sebench' \
 && git add -A \
 && GIT_AUTHOR_DATE="2026-06-06T13:55:44Z" GIT_COMMITTER_DATE="2026-06-06T13:55:44Z" git commit -q -m 'init' \
 && git log --format='%H %an <%ae> %ad' -1

# v1 step 8 as a smoke test: one 30-day game with the starter AI. The patched get_yaml may refresh
# the manifests from the CDN when the build has network, so the cache is re-verified afterwards.
RUN python3 -c "from openttdlab import run_experiments, local_folder; import os; list(run_experiments(openttd_version='13.4', opengfx_version='7.1', experiments=[{'seed': 0, 'ais': (local_folder('/home/workspace/openttd_ai/my_ai', ai_name='MyAI'),), 'days': 30}]))" \
 && cd /root/.cache/OpenTTDLab/0.0.75 && sha256sum -c /root/openttdlab-cache.sha256 && rm /root/openttdlab-cache.sha256 \
 && git -C /home/workspace/openttd_ai status --porcelain | (! grep .)
CMD ["python3"]
