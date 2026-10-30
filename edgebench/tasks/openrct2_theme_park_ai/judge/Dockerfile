# Judge image for openrct2_theme_park_ai.
# Build context = the task directory:
#   sforge build --task openrct2_theme_park_ai
#
# v1 judge.setup_cmds -> this file:
#   1 sed debian.sources -> mirror; apt-get install libzip5 libicu76 libcurl4t64 libfreetype6
#     libsdl2-2.0-0 libpng16-16t64                          -> same packages, pinned to v1's versions,
#                                                              from the base's dated Debian snapshot
#   2 mkdir -p /home/workspace/openrct2                     -> implied
#   3 curl <internal TOS>/openrct2_release_v0.5.0_linux_trixie_x86_64.tar.gz | tar -C release;
#     chmod +x openrct2-cli                                  -> the same bytes from the public upstream release
#                                                              (sha256 20260b77... identical), checked below
#   4 curl <internal TOS>/openrct2_judge_assets_passsemantics.tar.gz | tar; mv the two eval
#     scripts to /tmp; chmod +x                               -> COPY judge/scenarios, judge/*.py; baseline
#                                                              my_plugin.js = environment/workspace/my_plugin.js
#                                                              (identical); eval scripts in /judge/ instead of /tmp
#   5 git init && git add -A && git commit -m init          -> kept, author/dates pinned (same commit hash)
#   v1 eval_cmd + parser score_sum                          -> judge/grade.py (task.toml [judge].cmd)

ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ARG DEBIAN_FRONTEND=noninteractive
# Same snapshot as bases/python310 (v1 base build 2026-06-09); every package version below
# equals the published v1 judge image. apt checks the signed InRelease and each .deb's sha256.
ARG DEBIAN_SNAPSHOT=20260609T060000Z
RUN set -eux; \
    cp /etc/apt/sources.list.d/debian.sources /root/debian.sources.orig; \
    sed -i -e "s|http://deb.debian.org/debian-security|http://snapshot.debian.org/archive/debian-security/${DEBIAN_SNAPSHOT}|" \
           -e "s|http://deb.debian.org/debian\$|http://snapshot.debian.org/archive/debian/${DEBIAN_SNAPSHOT}|" \
           /etc/apt/sources.list.d/debian.sources; \
    apt-get -o Acquire::Check-Valid-Until=false update; \
    apt-get install -y --no-install-recommends \
      libzip5=1.11.3-2 \
      libicu76=76.1-4 \
      libcurl4t64=8.14.1-2+deb13u3 \
      libfreetype6=2.13.3+dfsg-1+deb13u1 \
      libsdl2-2.0-0=2.32.4+dfsg-1 \
      libpng16-16t64=1.6.48-1+deb13u5; \
    mv /root/debian.sources.orig /etc/apt/sources.list.d/debian.sources; \
    rm -rf /var/lib/apt/lists/*

# OpenRCT2 v0.5.0, official Linux (Debian trixie) x86_64 build. v1 fetched a byte-identical
# copy of this file from an internal mirror.
ARG OPENRCT2_URL=https://github.com/OpenRCT2/OpenRCT2/releases/download/v0.5.0/OpenRCT2-v0.5.0-Linux-trixie-x86_64.tar.gz
ARG OPENRCT2_SHA256=20260b77324bd8e9cad95a8e4da2ef69d56a95e6715de0a64d824be8e57333b5
RUN set -eux; \
    mkdir -p /home/workspace/openrct2/release; \
    curl -fsSL -o /root/openrct2.tar.gz "${OPENRCT2_URL}"; \
    echo "${OPENRCT2_SHA256}  /root/openrct2.tar.gz" | sha256sum -c -; \
    tar xzf /root/openrct2.tar.gz -C /home/workspace/openrct2/release; \
    chmod +x /home/workspace/openrct2/release/OpenRCT2/openrct2-cli; \
    rm /root/openrct2.tar.gz

COPY environment/workspace/my_plugin.js /home/workspace/openrct2/my_plugin.js
COPY judge/scenarios/ /home/workspace/openrct2/scenarios/
COPY judge/eval_openrct2.py judge/openrct2_original_eval.py judge/grade.py /judge/
WORKDIR /home/workspace/openrct2
RUN set -eux; \
    chmod 755 /judge /judge/eval_openrct2.py /judge/openrct2_original_eval.py /judge/grade.py scenarios; \
    chmod 644 my_plugin.js scenarios/*.park; \
    touch -d "2026-06-08T08:57:00Z" my_plugin.js scenarios scenarios/*.park; \
    git init -q; git config user.email 'sebench@local'; git config user.name 'sebench'; git add -A; \
    GIT_AUTHOR_DATE="2026-06-10T14:16:58+00:00" GIT_COMMITTER_DATE="2026-06-10T14:16:58+00:00" git commit -m 'init' -q; \
    test "$(git rev-parse HEAD)" = 24b038d4c01bd4cf9f028a49dc66f749afbea49d
CMD ["python3"]
