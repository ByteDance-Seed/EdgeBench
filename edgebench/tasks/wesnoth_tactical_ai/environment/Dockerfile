# Work image for wesnoth_tactical_ai (agent workspace).
# Build context = the task directory:
#   sforge build --task wesnoth_tactical_ai
#
# v1 work.setup_cmds -> this file:
#   0 apt-get install wesnoth-1.18 wesnoth-1.18-data   -> same packages, pinned versions, dated Debian snapshot
#   1 ln -sf /usr/games/wesnoth-1.18 /usr/local/bin/wesnoth -> kept
#   2 sed ... ca_recruit_rushers.lua (comment out math.randomseed(os.time())) -> kept
#   3 mkdir -p /home/wesnoth_agent                    -> implied by COPY below
#   4 heredoc > my_custom_ai.cfg (baseline)           -> environment/workspace/my_custom_ai.cfg (byte-identical)
#   5 git init && git config user.* && git add -A && git commit -m 'init'
#                                                     -> kept, v1's work-image dates pinned (gives v1's commit b9c859cc)
#   (template) chown -R agent:agent <cwd>; USER agent -> dropped (root)

# Base = bases/python310 (sforge build passes it as BASE_IMAGE).
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

# v1 installed Wesnoth on 2026-06-05 14:11 UTC (published image /var/log/apt/history.log), so apt
# uses the Debian snapshot just before that. apt checks the GPG-signed InRelease and every .deb's
# sha256. The stock sources file is restored afterwards.
ARG DEBIAN_FRONTEND=noninteractive
ARG DEBIAN_SNAPSHOT=20260605T120000Z
RUN set -eux; \
    cp /etc/apt/sources.list.d/debian.sources /tmp/debian.sources.orig; \
    sed -i -e "s|http://deb.debian.org/debian-security|http://snapshot.debian.org/archive/debian-security/${DEBIAN_SNAPSHOT}|" \
           -e "s|http://deb.debian.org/debian\$|http://snapshot.debian.org/archive/debian/${DEBIAN_SNAPSHOT}|" \
           /etc/apt/sources.list.d/debian.sources; \
    apt-get -o Acquire::Check-Valid-Until=false update; \
    apt-get install -y --no-install-recommends \
      wesnoth-1.18=1:1.18.5-1 wesnoth-1.18-data=1:1.18.5-1; \
    mv /tmp/debian.sources.orig /etc/apt/sources.list.d/debian.sources; \
    rm -rf /var/lib/apt/lists/*
RUN ln -sf /usr/games/wesnoth-1.18 /usr/local/bin/wesnoth \
 && sed -i 's/math.randomseed(os.time())/--math.randomseed(os.time())/g' \
      /usr/share/games/wesnoth/1.18/data/ai/lua/ca_recruit_rushers.lua

COPY environment/workspace/ /home/wesnoth_agent/
WORKDIR /home/wesnoth_agent
# Author, email, message and dates = v1's work-image commit b9c859cc (2026-06-05T14:11:16Z).
RUN git init -q && git config user.email 'sebench@local' && git config user.name 'sebench' \
 && git add -A \
 && GIT_AUTHOR_DATE="2026-06-05T14:11:16Z" GIT_COMMITTER_DATE="2026-06-05T14:11:16Z" git commit -q -m 'init' \
 && git log --format='%H %s' -1
CMD ["python3"]
