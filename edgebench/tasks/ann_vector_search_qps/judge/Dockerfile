# Judge image for ann_vector_search_qps.
# Build context = the task directory:
#   sforge build --task ann_vector_search_qps
#
# v1 judge.setup_cmds -> this file:
#   0 mkdir -p /home/workspace                                   -> implied
#   1-2 git clone + checkout f402b2c                              -> COPY environment/workspace/ (minus the custom/ starter, below)
#   3 pip install ... (same two lines as work)                    -> same hashed lock as environment/Dockerfile
#   4 curl sift-128-euclidean.hdf5 -> data/                       -> ADD environment/blobs/sift-128-euclidean.tar.gz (blob)
#   5 mkdir -p custom && touch custom/__init__.py                 -> custom/ keeps only __init__.py
#   6 rm -rf .git && git init && config && add && commit -m init  -> kept, dates pinned to v1's commit (same commit hash)
#   7 heredoc > /tmp/eval_ann_search.py                           -> COPY judge/eval_ann_search.py /judge/ (byte-identical)
#   v1 eval_cmd + parser score_sum                                -> judge/grade.py (task.toml [judge].cmd)

ARG BASE_IMAGE
FROM ${BASE_IMAGE}

# Identical to environment/Dockerfile (same layer, shared build cache).
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
# Same dataset blob as environment/Dockerfile (task.toml [[blobs]], SCHEMA rule 4).
# The grader edits the hdf5 in place during a run (removes and restores
# `neighbors`), so it has to be a writable copy inside the judge container.
ADD environment/blobs/sift-128-euclidean.tar.gz /home/workspace/ann-benchmarks/data/
WORKDIR /home/workspace/ann-benchmarks
RUN echo "dd6f0a6ed6b7ebb8934680f861a33ed01ff33991eaee4fd60914d854a0ca5984  data/sift-128-euclidean.hdf5" | sha256sum -c -
# v1's judge never received the starter module.py / config.yml: custom/ holds only __init__.py.
# Then the same workspace commit as v1's judge image (b61544cd, 2026-06-12T12:55:52Z).
RUN rm ann_benchmarks/algorithms/custom/module.py ann_benchmarks/algorithms/custom/config.yml \
 && git init -q && git config user.email 'sebench@local' && git config user.name 'sebench' \
 && git add -A \
 && GIT_AUTHOR_DATE="2026-06-12T12:55:52Z" GIT_COMMITTER_DATE="2026-06-12T12:55:52Z" git commit -m 'init' -q \
 && git log --format='%H %s' -1
COPY judge/eval_ann_search.py judge/grade.py /judge/
RUN chmod 644 /judge/eval_ann_search.py && chmod 755 /judge/grade.py
CMD ["python3"]
