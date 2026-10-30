# Judge image for dcss_dungeon_ai.
# Build context = the task directory:
#   sforge build --task dcss_dungeon_ai
#
# v1 judge.setup_cmds -> this file:
#   0-3 apt / mkdir / my_bot.rc / my_bot_include.rc -> identical to environment/Dockerfile (shared layers)
#   4 git init && git config user.* && git add -A && git commit -m 'init'
#                                                  -> kept, v1's judge-image dates pinned (gives v1's commit e5d2b863)
#   5 heredoc > /tmp/eval_dcss.py                  -> COPY judge/eval_dcss.py /judge/ (byte-identical, mode 644,
#                                                     moved out of /tmp)
#   v1 eval_cmd (python3 /tmp/eval_dcss.py) + parser structured_json
#                                                  -> judge/grade.py (task.toml [judge].cmd)
#   The judge image has no /usr/local/bin/dcss-eval (as in v1).

# Base = bases/python310 (sforge build passes it as BASE_IMAGE).
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

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
# Author, email, message and dates = v1's judge-image commit e5d2b863 (2026-06-09T12:47:25Z).
RUN git init -q && git config user.email 'sebench@local' && git config user.name 'sebench' \
 && git add -A \
 && GIT_AUTHOR_DATE="2026-06-09T12:47:25Z" GIT_COMMITTER_DATE="2026-06-09T12:47:25Z" git commit -q -m 'init' \
 && git log --format='%H %s' -1
COPY judge/eval_dcss.py judge/grade.py /judge/
RUN chmod 644 /judge/eval_dcss.py && chmod 755 /judge/grade.py
CMD ["python3"]
