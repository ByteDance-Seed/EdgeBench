# Work image for ann_vector_search_qps (agent workspace).
# Build context = the task directory:
#   sforge build --task ann_vector_search_qps
#
# v1 work.setup_cmds -> this file:
#   0 mkdir -p /home/workspace                                   -> implied by COPY below
#   1 git clone github.com/foreverpiano/ann-benchmarks <cwd>      -> sources committed under environment/workspace/
#   2 git checkout f402b2c                                        -> (= `git archive f402b2c`, upstream erikbern/ann-benchmarks commit)
#   3 pip install -r requirements.txt; pip install faiss-cpu h5py numpy scikit-learn pyyaml
#                                                                 -> pip install --require-hashes of environment/requirements.lock
#                                                                    (the exact 68 wheels v1 resolved, see NOTES.md)
#   4 curl ann-benchmarks.com/sift-128-euclidean.hdf5 -> data/    -> ADD environment/blobs/sift-128-euclidean.tar.gz (blob, see TODO below)
#   5 mkdir -p .../algorithms/custom                              -> implied
#   6 heredoc > custom/module.py                                  -> environment/workspace/.../custom/module.py (byte-identical)
#   7 heredoc > custom/config.yml                                 -> environment/workspace/.../custom/config.yml (byte-identical)
#   8 touch custom/__init__.py                                    -> environment/workspace/.../custom/__init__.py
#   9 rm -rf .git && git init && git config user.* && add && commit -m init
#                                                                 -> kept, dates pinned to v1's commit (same commit hash)
#   (template) chown -R agent:agent <cwd>; USER agent             -> dropped (root)

# Base = bases/python310 (sforge build passes it as BASE_IMAGE).
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

# Python packages: every wheel pinned by sha256 (pip --require-hashes, no resolver, no sdists).
# The lock is bind-mounted so it does not end up in the image. v1 only explicitly requested the
# packages listed below (requirements.txt + the extra pip line); pip marks every --require-hashes
# entry as REQUESTED, so the marker (and its RECORD line) is removed from the others to match v1.
RUN --mount=type=bind,source=environment/requirements.lock,target=/mnt/requirements.lock \
    set -eu; \
    pip install --no-cache-dir --disable-pip-version-check --no-deps --only-binary=:all: \
        --require-hashes -r /mnt/requirements.lock; \
    cd /usr/local/lib/python3.10/site-packages; \
    for d in *.dist-info; do \
      case "$d" in \
        PyYAML-*|ansicolors-*|datasets-*|docker-*|faiss_cpu-*|h5py-*|jinja2-*|matplotlib-*|numpy-*|\
psutil-*|pytest-*|requests-*|scikit_learn-*|pip-*|setuptools-*|wheel-*) ;; \
        *) rm -f "$d/REQUESTED"; sed -i "/^[^,]*\.dist-info\/REQUESTED,/d" "$d/RECORD" ;; \
      esac; \
    done; \
    python3 -c "import faiss, h5py, numpy, sklearn, yaml; print('faiss', faiss.__version__, 'numpy', numpy.__version__)"

COPY environment/workspace/ /home/workspace/ann-benchmarks/
# Dataset = blob environment/blobs/sift-128-euclidean.tar.gz (task.toml [[blobs]], fetched by
# sforge build, SCHEMA rule 4); ADD unpacks the single file sift-128-euclidean.hdf5 (525128288 B, mode 0644) into data/.
# Origin: the public ann-benchmarks.com dataset v1 downloaded (byte-identical, sha256 checked below).
ADD environment/blobs/sift-128-euclidean.tar.gz /home/workspace/ann-benchmarks/data/
WORKDIR /home/workspace/ann-benchmarks
RUN echo "dd6f0a6ed6b7ebb8934680f861a33ed01ff33991eaee4fd60914d854a0ca5984  data/sift-128-euclidean.hdf5" | sha256sum -c -
# v1 setup: fresh git repo with one "init" commit (agent-visible baseline for git diff).
# Author, email, message and dates = v1's commit 64802d5b (2026-06-12T12:55:44Z). data/* and
# results/* are ignored by the repo's .gitignore, as in v1.
RUN git init -q && git config user.email 'sebench@local' && git config user.name 'sebench' \
 && git add -A \
 && GIT_AUTHOR_DATE="2026-06-12T12:55:44Z" GIT_COMMITTER_DATE="2026-06-12T12:55:44Z" git commit -m 'init' -q \
 && git log --format='%H %s' -1
CMD ["python3"]
