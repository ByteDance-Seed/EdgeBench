# Judge image for k12_math_recommendation.
# Build context = the task directory:
#   sforge build --task k12_math_recommendation
#
# v1 judge.setup_cmds -> this file:
#   0 apt-get install git-lfs python3 python3-pip unzip curl wget ca-certificates
#                                   -> same as environment/Dockerfile (git-lfs, python3-pip, python3-wheel pinned)
#   1 python3 -m pip install -q ... -> pip install --require-hashes of environment/requirements.lock
#   2 curl judge.tar.gz (internal object storage) + sha256 check + untar to /tmp/assets
#   3 mkdir -p <cwd>/scoring <cwd>/input; cp -r .../scoring/. <cwd>/scoring/; cp -r .../input/. <cwd>/input/
#                                   -> COPY judge/scoring/ (published image's English scorer, see NOTES.md) and
#                                      COPY environment/workspace/ to <cwd>/input/ (v1's judge input/ is
#                                      byte-identical to the agent workspace, attachments/ copy included)
#   (no git repo in the v1 judge image)
#   v1 eval_cmd `cd /home/workspace && python3 scoring/score.py` + parser structured_json
#                                   -> judge/run.sh + judge/emit_result.py (task.toml [judge].cmd)

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
RUN python3 -m pip install --no-cache-dir -q --require-hashes -r /root/requirements.lock \
 && rm /root/requirements.lock

COPY environment/workspace/ /home/workspace/input/
COPY environment/workspace/input_data/ /home/workspace/input/attachments/input_data/
COPY environment/workspace/environment_setup.md environment/workspace/requirements.txt /home/workspace/input/attachments/
COPY judge/scoring/ /home/workspace/scoring/
COPY judge/run.sh judge/emit_result.py /judge/
RUN chmod 755 /home/workspace/scoring/score.py /judge/run.sh /judge/emit_result.py
WORKDIR /home/workspace
CMD ["python3"]
