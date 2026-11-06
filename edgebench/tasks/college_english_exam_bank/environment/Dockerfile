# Work image for college_english_exam_bank (agent workspace).
# Build context = the task directory:
#   sforge build --task college_english_exam_bank
#
# v1 work.setup_cmds -> this file:
#   0 apt-get install git python3 python3-pip unzip p7zip-full  -> same packages, exact v1 versions, Debian snapshot
#                                                                 of the v1 build day (2026-06-09)
#   1 python3 -m pip install beautifulsoup4 lxml markdown numpy openpyxl pandas pdfplumber Pillow pypdf
#     python-docx python-pptx requests xlrd                     -> pip install --require-hashes of environment/requirements.lock
#                                                                 (the 28 exact versions of the published image)
#   2 git clone (sparse) of the original task repo -> /tmp/assets
#   3 cp -r /tmp/assets/college_english_exam_bank/input/. /home/workspace/ && rm -rf /tmp/assets
#                                                              -> environment/workspace/ (all files sha256-identical to the
#                                                                 published image) + the blob environment/blobs/ppt_rar.tar.gz
#                                                                 for the one 577 MB file, which v1 has twice (top level and
#                                                                 attachments/)
#   4 rm -rf .git && git init && git config user.* && git add -A && git commit -m init
#                                                              -> same, v1's commit date pinned (gives v1's commit 3ea90c35)
#   (template) chown -R agent:agent <cwd>; USER agent          -> dropped (root)

# Base = bases/python (sforge build passes it as BASE_IMAGE).
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ARG DEBIAN_FRONTEND=noninteractive
# apt from the Debian snapshot of the v1 build day (the v1 install ran 2026-06-09 12:48 UTC);
# apt checks the GPG-signed InRelease and each .deb's sha256. The stock sources file is restored.
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
      p7zip-full=16.02+transitional.1; \
    mv /tmp/debian.sources.orig /etc/apt/sources.list.d/debian.sources; \
    rm -rf /var/lib/apt/lists/*

# Python deps from public PyPI, every wheel checked by sha256. The lock is bind-mounted so it does
# not end up in the image. pip marks every --require-hashes entry as REQUESTED; the marker (and its
# RECORD line) is removed from the packages v1 did not name on its pip command line.
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
    done; \
    python3 -B -c "import docx, pptx, openpyxl, pandas, pdfplumber, pypdf, PIL, bs4, lxml, xlrd, markdown; print('ok')"

# Workspace = v1 input/ of the original task repo. The 577 MB `附件4：PPT.rar` is the blob
# environment/blobs/ppt_rar.tar.gz (task.toml [[blobs]], see NOTES.md); v1 has it twice.
COPY environment/workspace/ /home/workspace/
ADD environment/blobs/ppt_rar.tar.gz /home/workspace/
ADD environment/blobs/ppt_rar.tar.gz /home/workspace/attachments/
WORKDIR /home/workspace
RUN echo "d6dd4f3046c7bc5c1801ba5bf173f4bf8fc60ad7adc593cc2f21a209ea949826  附件4：PPT.rar" > /tmp/ppt.sha \
 && sha256sum -c /tmp/ppt.sha && (cd attachments && sha256sum -c /tmp/ppt.sha) && rm /tmp/ppt.sha
# v1 setup: fresh git repo with one "init" commit (agent-visible baseline for git diff).
# Author/email/message/date = v1's commit 3ea90c35 (2026-06-09T12:48:28Z).
RUN git init -q && git config user.email 'sebench@local' && git config user.name 'sebench' \
 && git add -A \
 && GIT_AUTHOR_DATE="2026-06-09T12:48:28Z" GIT_COMMITTER_DATE="2026-06-09T12:48:28Z" git commit -q -m 'init' \
 && git log --format='%H %an <%ae> %ad' -1
CMD ["python3"]
