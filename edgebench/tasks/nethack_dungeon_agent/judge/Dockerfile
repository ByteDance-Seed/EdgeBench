# Judge image for nethack_dungeon_agent.
# Build context = the task directory:
#   sforge build --task nethack_dungeon_agent
#
# v1 judge.setup_cmds -> this file:
#   0-5 apt / mkdir / pip / agent.py starter       -> identical to environment/Dockerfile (shared layers)
#   6 git init && git config user.* && git add -A && git commit -m 'init'
#                                                  -> kept, v1's judge-image dates pinned (gives v1's commit 56ea0585)
#   7 heredoc > /tmp/eval_nethack.py               -> COPY judge/eval_nethack.py /judge/ (byte-identical, mode 644,
#                                                     moved out of /tmp)
#   v1 eval_cmd (python3 /tmp/eval_nethack.py) + parser score_sum
#                                                  -> judge/grade.py (task.toml [judge].cmd)

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
# Author, email, message and dates = v1's judge-image commit 56ea0585 (2026-06-09T12:47:42Z).
RUN git init -q && git config user.email 'sebench@local' && git config user.name 'sebench' \
 && git add -A \
 && GIT_AUTHOR_DATE="2026-06-09T12:47:42Z" GIT_COMMITTER_DATE="2026-06-09T12:47:42Z" git commit -q -m 'init' \
 && git log --format='%H %s' -1
COPY judge/eval_nethack.py judge/grade.py /judge/
RUN chmod 644 /judge/eval_nethack.py && chmod 755 /judge/grade.py
CMD ["python3"]
