# Judge image for cta_risk_budget_optimization.
# Build context = the task directory:
#   sforge build --task cta_risk_budget_optimization
#
# v1 judge.setup_cmds -> this file:
#   0 apt-get install git git-lfs python3 python3-pip unzip curl wget ca-certificates
#                                   -> same as environment/Dockerfile (dated snapshot, pinned versions)
#   1 pip install pandas numpy openpyxl python-docx -> pip install --require-hashes of environment/requirements.lock
#   2 import check                   -> kept
#   3 git clone (sparse) of the original task repo
#   4 mkdir -p scoring input; cp grade_with_codex.py (absent in the repo, so not copied);
#     cp -r .../scoring/. /home/workspace/scoring/; cp -r .../input/. /home/workspace/input/
#                                   -> COPY judge/scoring/ and environment/workspace/ (the same 8 input files)
#   (no git repo in the v1 judge image)
#   v1 eval_cmd + parser structured_json -> judge/run.sh + judge/emit_result.py (task.toml [judge].cmd)

# Base = bases/python (sforge build passes it as BASE_IMAGE).
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ARG DEBIAN_FRONTEND=noninteractive
ARG DEBIAN_SNAPSHOT=20260617T120000Z
RUN set -eux; \
    cp /etc/apt/sources.list.d/debian.sources /etc/apt/debian.sources.orig; \
    sed -i -e "s|http://deb.debian.org/debian-security|http://snapshot.debian.org/archive/debian-security/${DEBIAN_SNAPSHOT}|" \
           -e "s|http://deb.debian.org/debian\$|http://snapshot.debian.org/archive/debian/${DEBIAN_SNAPSHOT}|" \
           /etc/apt/sources.list.d/debian.sources; \
    apt-get -o Acquire::Check-Valid-Until=false update; \
    apt-get install -y --no-install-recommends git git-lfs=3.6.1-1+deb13u1 python3 \
      python3-pip=25.1.1+dfsg-1 python3-wheel=0.46.1-2 unzip curl wget ca-certificates; \
    mv /etc/apt/debian.sources.orig /etc/apt/sources.list.d/debian.sources; \
    rm -rf /var/lib/apt/lists/*

COPY environment/requirements.lock /root/requirements.lock
RUN python3 -m pip install --no-cache-dir --break-system-packages --require-hashes -r /root/requirements.lock \
 && rm /root/requirements.lock \
 && python3 -c "import pandas, numpy, openpyxl, docx; print('base Python deps OK')"

COPY environment/workspace/ /home/workspace/input/
COPY judge/scoring/ /home/workspace/scoring/
COPY judge/run.sh judge/emit_result.py /judge/
RUN chmod 755 /judge/run.sh /judge/emit_result.py
WORKDIR /home/workspace
CMD ["python3"]
