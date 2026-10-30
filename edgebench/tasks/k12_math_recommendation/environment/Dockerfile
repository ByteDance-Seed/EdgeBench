# Work image for k12_math_recommendation (agent workspace).
# Build context = the task directory:
#   sforge build --task k12_math_recommendation
#
# v1 work.setup_cmds -> this file:
#   0 apt-get update && apt-get install -y --no-install-recommends git git-lfs python3 python3-pip
#       unzip curl wget ca-certificates
#                                   -> same command against the base's dated Debian snapshot; the packages
#                                      the base lacks are pinned to the versions in the published image
#                                      (git-lfs, python3-pip, python3-wheel)
#   1 python3 -m pip install -q numpy pandas scikit-learn scipy lightgbm joblib pyyaml tqdm (ranges)
#                                   -> pip install --require-hashes of environment/requirements.lock
#                                      (the 13 exact versions the published image has, public PyPI wheels)
#   2 curl work.tar.gz (internal object storage) + sha256 check + untar to /tmp/assets
#   3 cp -r /tmp/assets/k12_math_recommendation/input/. /home/workspace/; rm -rf /tmp/assets
#                                   -> environment/workspace/ (the published image's English workspace, see
#                                      NOTES.md); attachments/ is a byte-identical second copy, made below
#   4 rm -rf .git && git init && git config user.* && git add -A && git commit -m init
#                                   -> same, with v1's commit date pinned (gives v1's commit 0d841cf9)
#   (template) chown -R agent:agent /home/workspace; USER agent  -> dropped (root)

# Base = bases/python (sforge build passes it as BASE_IMAGE).
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ARG DEBIAN_FRONTEND=noninteractive
# Same Debian snapshot as bases/python (apt checks the signed InRelease and every .deb sha256).
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

# Workspace = v1 input/ (24 files). attachments/ holds the same bytes a second time, as in v1.
COPY environment/workspace/ /home/workspace/
COPY environment/workspace/input_data/ /home/workspace/attachments/input_data/
COPY environment/workspace/environment_setup.md environment/workspace/requirements.txt /home/workspace/attachments/
WORKDIR /home/workspace
# v1 setup: fresh git repo with one "init" commit on master. Author/email/message/date =
# v1's commit 0d841cf9 (1782991121 = 2026-07-02T11:18:41Z).
RUN git init -q && git symbolic-ref HEAD refs/heads/master \
 && git config user.email 'sebench@local' && git config user.name 'sebench' \
 && git add -A \
 && GIT_AUTHOR_DATE="1782991121 +0000" GIT_COMMITTER_DATE="1782991121 +0000" git commit -q -m init \
 && git log --format='%H %an <%ae> %ad' -1
CMD ["python3"]
