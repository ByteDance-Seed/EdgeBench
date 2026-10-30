# Judge image for college_english_exam_bank.
# Build context = the task directory:
#   sforge build --task college_english_exam_bank
#
# THE GRADER CALLS AN LLM (Codex CLI agent, see judge/run.sh and NOTES.md): it needs an API key,
# base URL and model passed in by the operator (SFORGE_JUDGE_EXTRA_ENV) and network access.
#
# v1 judge.setup_cmds -> this file:
#   0 apt-get install git python3 python3-pip unzip p7zip-full curl nodejs npm
#                                                              -> same packages, exact v1 versions, Debian snapshot
#                                                                 of the v1 build day (2026-06-09)
#   1 npm install -g @openai/codex (unpinned; v1 got 0.138.0) -> the two npm tarballs of @openai/codex 0.138.0
#                                                                 (main + linux-x64 binary package), sha256-checked,
#                                                                 unpacked into the same tree `npm install -g` makes
#   2 python3 -m pip install ...                               -> pip install --require-hashes of environment/requirements.lock
#   3 git clone (sparse) of the original task repo -> /tmp/assets
#   4 mkdir scoring input; cp -r .../scoring/. scoring/; cp -r .../input/. input/; rm -rf /tmp/assets
#                                                              -> COPY judge/scoring/ and environment/workspace/ (+ the blob)
#   (published image, later layer 2026-06-30) scoring/grade_with_codex.py replaced by a version
#     reading SFORGE_JUDGE_* env vars                          -> judge/scoring/grade_with_codex.py is that version
#                                                                 (two internal IPs removed from its NO_PROXY list)
#   v1 eval_cmd + parser structured_json                      -> judge/run.sh + judge/emit_result.py (task.toml [judge].cmd)

# Base = bases/python (sforge build passes it as BASE_IMAGE).
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ARG DEBIAN_FRONTEND=noninteractive
ARG DEBIAN_SNAPSHOT=20260609T120000Z
RUN set -eux; \
    cp /etc/apt/sources.list.d/debian.sources /tmp/debian.sources.orig; \
    sed -i -e "s|http://deb.debian.org/debian-security|http://snapshot.debian.org/archive/debian-security/${DEBIAN_SNAPSHOT}|" \
           -e "s|http://deb.debian.org/debian\$|http://snapshot.debian.org/archive/debian/${DEBIAN_SNAPSHOT}|" \
           /etc/apt/sources.list.d/debian.sources; \
    apt-get -o Acquire::Check-Valid-Until=false update -qq; \
    apt-get install -y --no-install-recommends -qq \
      git=1:2.47.3-0+deb13u1 \
      python3=3.13.5-1 \
      python3-pip=25.1.1+dfsg-1 \
      unzip=6.0-29 \
      p7zip-full=16.02+transitional.1 \
      curl=8.14.1-2+deb13u3 \
      nodejs=20.19.2+dfsg-1+deb13u2 \
      npm=9.2.0~ds1-3; \
    mv /tmp/debian.sources.orig /etc/apt/sources.list.d/debian.sources; \
    rm -rf /var/lib/apt/lists/*

# Codex CLI 0.138.0 from the public npm registry (the version v1's unpinned install resolved).
# sha256 of the registry tarballs; their sha512 equals the registry's `dist.integrity`.
RUN set -eux; \
    d=$(mktemp -d); cd "$d"; \
    curl -fsSLO https://registry.npmjs.org/@openai/codex/-/codex-0.138.0.tgz; \
    curl -fsSLO https://registry.npmjs.org/@openai/codex/-/codex-0.138.0-linux-x64.tgz; \
    printf '%s  %s\n' \
      aef3a3d77b038470120651b35c911053f0033ccbd1427eeff0d5fcf270b7009a codex-0.138.0.tgz \
      9343155a32cffeccc020687361d92d334ab53703e8a1046db3f0502ed47aaa4c codex-0.138.0-linux-x64.tgz \
      | sha256sum -c -; \
    m=/usr/local/lib/node_modules/@openai/codex; \
    mkdir -p "$m/node_modules/@openai/codex-linux-x64"; \
    tar -xzf codex-0.138.0.tgz --strip-components=1 --no-same-owner -C "$m"; \
    tar -xzf codex-0.138.0-linux-x64.tgz --strip-components=1 --no-same-owner -C "$m/node_modules/@openai/codex-linux-x64"; \
    ln -s ../lib/node_modules/@openai/codex/bin/codex.js /usr/local/bin/codex; \
    cd /; rm -rf "$d"; \
    codex --version; \
    rm -rf /root/.codex   # created by the version check; v1 has no /root/.codex

RUN --mount=type=bind,source=environment/requirements.lock,target=/mnt/requirements.lock \
    set -eu; \
    python3 -m pip install -q --no-cache-dir --disable-pip-version-check --no-deps --only-binary=:all: \
        --require-hashes -r /mnt/requirements.lock; \
    cd /usr/local/lib/python3.11/site-packages; \
    for d in *.dist-info; do \
      case "$d" in \
        beautifulsoup4-*|lxml-*|markdown-*|numpy-*|openpyxl-*|pandas-*|pdfplumber-*|pillow-*|pypdf-*|\
python_docx-*|python_pptx-*|requests-*|xlrd-*|pip-*|setuptools-*|wheel-*) ;; \
        *) rm -f "$d/REQUESTED"; sed -i "/^[^,]*\.dist-info\/REQUESTED,/d" "$d/RECORD" ;; \
      esac; \
    done

# input/ = the agent's workspace files (v1 copied the same repo input/ dir), incl. the blob twice.
COPY environment/workspace/ /home/workspace/input/
ADD environment/blobs/ppt_rar.tar.gz /home/workspace/input/
ADD environment/blobs/ppt_rar.tar.gz /home/workspace/input/attachments/
# scoring/ = rubrics, reference answers and the Codex grader (the grader's own files, hidden from the agent).
COPY judge/scoring/ /home/workspace/scoring/
COPY judge/run.sh judge/emit_result.py /judge/
RUN chmod 755 /judge/run.sh /judge/emit_result.py
WORKDIR /home/workspace
CMD ["python3"]
