#!/bin/sh
# Shared by environment/Dockerfile and judge/Dockerfile (bind-mounted at build time, not in the image).
# v1 setup step: python -m pip install --no-cache-dir --index-url https://download.pytorch.org/whl/cpu torch==2.2.2+cpu
set -eu
# `python -m pip` as in v1: console-script shebangs become #!/usr/local/bin/python (v1 bytes).
python -m pip install --no-cache-dir --disable-pip-version-check --no-deps --only-binary=:all: \
    --require-hashes -r /mnt/lock/requirements.lock
# v1 asked only for torch; the rest were pulled in as dependencies. pip marks every
# --require-hashes entry REQUESTED, so drop that marker (and its RECORD line) for the others.
cd /usr/local/lib/python3.11/site-packages
for d in filelock-*.dist-info fsspec-*.dist-info jinja2-*.dist-info markupsafe-*.dist-info \
         mpmath-*.dist-info networkx-*.dist-info sympy-*.dist-info typing_extensions-*.dist-info; do
  rm -f "$d/REQUESTED"; sed -i "/^[^,]*\.dist-info\/REQUESTED,/d" "$d/RECORD"
done
# -B: do not leave stdlib .pyc files from this check behind (v1 has none).
python -B -c "import torch; print('torch', torch.__version__, torch.get_num_threads())"
