# Work image for cta_risk_budget_optimization (agent workspace).
# Build context = the task directory:
#   sforge build --task cta_risk_budget_optimization
#
# v1 work.setup_cmds -> this file:
#   0 apt-get update && apt-get install -y --no-install-recommends git git-lfs python3 python3-pip
#       unzip curl wget ca-certificates
#                                   -> same command against the base's dated Debian snapshot; the packages
#                                      the base lacks are pinned to the versions found in the published
#                                      image (git-lfs, python3-pip, python3-wheel)
#   1 pip install --break-system-packages -i <internal PyPI> pandas numpy openpyxl python-docx
#                                   -> pip install --require-hashes of environment/requirements.lock
#                                      (the 9 exact versions the published image has, public PyPI wheels)
#   2 python3 -c "import pandas, numpy, openpyxl, docx"  -> kept
#   3 git clone (sparse) of the original task repo; 4 cp -r .../input/. /home/workspace/
#                                   -> environment/workspace/ (8 files, sha256-identical to the published image)
#   5 rm -rf .git && git init && git config user.* && git add -A && git commit -m 'init'
#                                   -> same, with v1's commit date pinned (gives v1's commit 55e75164)
#   (template) chown -R agent:agent <cwd>; USER agent    -> dropped (root)

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
RUN python3 -m pip install --no-cache-dir --break-system-packages --require-hashes -r /root/requirements.lock \
 && rm /root/requirements.lock \
 && python3 -c "import pandas, numpy, openpyxl, docx; print('base Python deps OK')"

COPY environment/workspace/ /home/workspace/
WORKDIR /home/workspace
# v1 setup: fresh git repo with one "init" commit. Author/email/message/date = v1's
# commit 55e75164 (1782991425 = 2026-07-02T11:23:45Z).
RUN git init -q && git config user.email 'sebench@local' && git config user.name 'sebench' \
 && git add -A \
 && GIT_AUTHOR_DATE="1782991425 +0000" GIT_COMMITTER_DATE="1782991425 +0000" git commit -q -m 'init' \
 && git log --format='%H %an <%ae> %ad' -1
CMD ["python3"]
