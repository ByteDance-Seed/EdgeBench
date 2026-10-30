# Judge image for wesnoth_tactical_ai.
# Build context = the task directory:
#   sforge build --task wesnoth_tactical_ai
#
# v1 judge.setup_cmds -> this file:
#   0-4 apt / ln / sed / mkdir / my_custom_ai.cfg  -> identical to environment/Dockerfile (shared layers)
#   5 git init && git config user.* && git add -A && git commit -m 'init'
#                                                  -> kept, v1's judge-image dates pinned (gives v1's commit c6736ae6)
#   6 heredoc > /tmp/eval_wesnoth.py               -> COPY judge/eval_wesnoth.py /judge/ (byte-identical, mode 644,
#                                                     moved out of /tmp)
#   v1 eval_cmd (python3 /tmp/eval_wesnoth.py) + parser score_sum
#                                                  -> judge/grade.py (task.toml [judge].cmd)

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
# Author, email, message and dates = v1's judge-image commit c6736ae6 (2026-06-05T14:11:21Z).
RUN git init -q && git config user.email 'sebench@local' && git config user.name 'sebench' \
 && git add -A \
 && GIT_AUTHOR_DATE="2026-06-05T14:11:21Z" GIT_COMMITTER_DATE="2026-06-05T14:11:21Z" git commit -q -m 'init' \
 && git log --format='%H %s' -1
COPY judge/eval_wesnoth.py judge/grade.py /judge/
RUN chmod 644 /judge/eval_wesnoth.py && chmod 755 /judge/grade.py
CMD ["python3"]
