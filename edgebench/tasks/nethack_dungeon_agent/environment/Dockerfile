# Work image for nethack_dungeon_agent (agent workspace).
# Build context = the task directory:
#   sforge build --task nethack_dungeon_agent
#
# v1 work.setup_cmds -> this file:
#   0 apt-get install cmake bison flex libbz2-dev ninja-build build-essential
#                                                  -> same packages, pinned versions, dated Debian snapshot
#   1 mkdir -p /home/nethack_agent                 -> implied by COPY below
#   2 pip install 'setuptools<70' wheel            -> environment/requirements.lock (setuptools 69.5.1)
#   3 pip install 'nle==1.2.0'                     -> environment/requirements.lock (nle + deps, sha256-pinned)
#   4 heredoc > agent.py (starter); 5 chmod +x     -> environment/workspace/agent.py (byte-identical, mode 755)
#   6 git init && git config user.* && git add -A && git commit -m 'init'
#                                                  -> kept, v1's author and dates pinned (gives v1's commit 8d7ac0ae)
#   (template) chown -R agent:agent <cwd>; USER agent -> dropped (root)

# Base = bases/python310 (sforge build passes it as BASE_IMAGE).
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

# Build tools from v1 setup_cmds[0] (NLE's source-build deps; nle itself installs from a wheel).
# Same Debian snapshot as bases/python310 (v1 task layer built 2026-06-09 12:47 UTC); apt checks
# the GPG-signed InRelease and every .deb's sha256. libbz2-dev and build-essential are already
# in the base. The stock sources file is restored afterwards.
ARG DEBIAN_FRONTEND=noninteractive
ARG DEBIAN_SNAPSHOT=20260609T060000Z
RUN set -eux; \
    cp /etc/apt/sources.list.d/debian.sources /tmp/debian.sources.orig; \
    sed -i -e "s|http://deb.debian.org/debian-security|http://snapshot.debian.org/archive/debian-security/${DEBIAN_SNAPSHOT}|" \
           -e "s|http://deb.debian.org/debian\$|http://snapshot.debian.org/archive/debian/${DEBIAN_SNAPSHOT}|" \
           /etc/apt/sources.list.d/debian.sources; \
    apt-get -o Acquire::Check-Valid-Until=false update; \
    apt-get install -y --no-install-recommends \
      cmake=3.31.6-2 bison=2:3.8.2+dfsg-1+b2 flex=2.6.4-8.2+b4 ninja-build=1.12.1-1 \
      libbz2-dev build-essential; \
    mv /tmp/debian.sources.orig /etc/apt/sources.list.d/debian.sources; \
    rm -rf /var/lib/apt/lists/*

COPY environment/requirements.lock /tmp/requirements.lock
RUN pip install --no-cache-dir --require-hashes -r /tmp/requirements.lock \
 && rm /tmp/requirements.lock

COPY environment/workspace/ /home/nethack_agent/
RUN chmod 755 /home/nethack_agent/agent.py
WORKDIR /home/nethack_agent
# v1 setup: fresh git repo with one "init" commit (agent-visible baseline for git diff).
# Author, email, message and dates = v1's work-image commit 8d7ac0ae (2026-06-09T12:47:41Z).
RUN git init -q && git config user.email 'sebench@local' && git config user.name 'sebench' \
 && git add -A \
 && GIT_AUTHOR_DATE="2026-06-09T12:47:41Z" GIT_COMMITTER_DATE="2026-06-09T12:47:41Z" git commit -q -m 'init' \
 && git log --format='%H %s' -1
CMD ["python3"]
