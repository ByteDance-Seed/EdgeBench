# Work image for dcss_dungeon_ai (agent workspace).
# Build context = the task directory:
#   sforge build --task dcss_dungeon_ai
#
# v1 work.setup_cmds -> this file:
#   0 apt-get install --no-install-recommends crawl screen
#                                                  -> same packages, pinned versions, dated Debian snapshot
#   1 mkdir -p /home/dcss_agent /opt/tiger/game/DCSS/morgue
#                                                  -> kept (RUN mkdir)
#   2 heredoc > my_bot.rc; 3 heredoc > my_bot_include.rc
#                                                  -> environment/workspace/ (byte-identical, mode 644)
#   4 git init && git config user.* && git add -A && git commit -m 'init'
#                                                  -> kept, v1's author and dates pinned (gives v1's commit 550df753)
#   5 heredoc > /usr/local/bin/dcss-eval && chmod +x
#                                                  -> environment/dcss-eval (byte-identical, mode 755)
#   (template) chown -R agent:agent <cwd>; USER agent -> dropped (root)

# Base = bases/python310 (sforge build passes it as BASE_IMAGE).
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

# Same Debian snapshot as bases/python310 (the v1 task layer was built 2026-06-09 12:47 UTC and
# installed exactly these versions). apt checks the GPG-signed InRelease and every .deb's sha256.
# The stock sources file is restored afterwards.
ARG DEBIAN_FRONTEND=noninteractive
ARG DEBIAN_SNAPSHOT=20260609T060000Z
RUN set -eux; \
    cp /etc/apt/sources.list.d/debian.sources /tmp/debian.sources.orig; \
    sed -i -e "s|http://deb.debian.org/debian-security|http://snapshot.debian.org/archive/debian-security/${DEBIAN_SNAPSHOT}|" \
           -e "s|http://deb.debian.org/debian\$|http://snapshot.debian.org/archive/debian/${DEBIAN_SNAPSHOT}|" \
           /etc/apt/sources.list.d/debian.sources; \
    apt-get -o Acquire::Check-Valid-Until=false update; \
    apt-get install -y --no-install-recommends \
      crawl=2:0.28.0-1.1 crawl-common=2:0.28.0-1.1 liblua5.1-0=5.1.5-11 screen=4.9.1-3; \
    mv /tmp/debian.sources.orig /etc/apt/sources.list.d/debian.sources; \
    rm -rf /var/lib/apt/lists/*; \
    mkdir -p /home/dcss_agent /opt/tiger/game/DCSS/morgue

COPY environment/workspace/ /home/dcss_agent/
RUN chmod 755 /home/dcss_agent && chmod 644 /home/dcss_agent/my_bot.rc /home/dcss_agent/my_bot_include.rc
WORKDIR /home/dcss_agent
# Author, email, message and dates = v1's work-image commit 550df753 (2026-06-09T12:47:24Z).
RUN git init -q && git config user.email 'sebench@local' && git config user.name 'sebench' \
 && git add -A \
 && GIT_AUTHOR_DATE="2026-06-09T12:47:24Z" GIT_COMMITTER_DATE="2026-06-09T12:47:24Z" git commit -q -m 'init' \
 && git log --format='%H %s' -1
COPY environment/dcss-eval /usr/local/bin/dcss-eval
RUN chmod 755 /usr/local/bin/dcss-eval
CMD ["python3"]
