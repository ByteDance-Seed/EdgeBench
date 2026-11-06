# Judge image for portfolio_risk_calibration.
# Build context = the task directory:
#   sforge build --task portfolio_risk_calibration
#
# v1 judge.setup_cmds -> this file:
#   0 apt-get install git python3 python3-pip unzip curl wget ca-certificates
#                                   -> same as environment/Dockerfile (dated snapshot, pinned versions)
#   1 python3 -m pip install ...    -> pip install --require-hashes of environment/requirements.lock
#   2 git clone (sparse) of the original task repo
#   3 mkdir -p scoring input; cp -r .../scoring/. /home/workspace/scoring/; cp -r .../input/. /home/workspace/input/
#                                   -> COPY judge/scoring/ (12 files) and environment/workspace/ (the same 16
#                                      input files as the work image); both as in the published judge image,
#                                      which carries English translations / renames of repo files (NOTES.md)
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
    apt-get install -y --no-install-recommends git python3 \
      python3-pip=25.1.1+dfsg-1 python3-wheel=0.46.1-2 unzip curl wget ca-certificates; \
    mv /etc/apt/debian.sources.orig /etc/apt/sources.list.d/debian.sources; \
    rm -rf /var/lib/apt/lists/*

COPY environment/requirements.lock /root/requirements.lock
RUN python3 -m pip install -q --no-cache-dir --require-hashes -r /root/requirements.lock \
 && rm /root/requirements.lock

COPY environment/workspace/ /home/workspace/input/
COPY judge/scoring/ /home/workspace/scoring/
COPY judge/run.sh judge/emit_result.py /judge/
RUN chmod 755 /judge/run.sh /judge/emit_result.py
WORKDIR /home/workspace
CMD ["python3"]
