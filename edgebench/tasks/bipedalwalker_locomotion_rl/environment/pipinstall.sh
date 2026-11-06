#!/bin/sh
# Shared by environment/Dockerfile and judge/Dockerfile (bind-mounted at build time, not in the image).
set -eu
# `python -m pip` as in v1: console-script shebangs become #!/usr/local/bin/python (v1), not python3.11.
python -m pip install --no-cache-dir --disable-pip-version-check --no-deps --only-binary=:all: \
    --require-hashes -r /mnt/lock/requirements.lock
python -m pip install --no-cache-dir --disable-pip-version-check --no-deps --no-build-isolation --no-binary=:all: \
    --require-hashes -r /mnt/lock/requirements-sdist.lock
# v1 asked for these explicitly (setup_cmds pip lines); the rest were pulled in as dependencies.
# pip marks every --require-hashes entry REQUESTED, so drop the marker (and its RECORD line) elsewhere.
cd /usr/local/lib/python3.11/site-packages
for d in *.dist-info; do
  case "$d" in
    filelock-*|fsspec-*|gymnasium-*|jinja2-*|networkx-*|numpy-*|pip-*|scipy-*|setuptools-*|swig-*|\
sympy-*|torch-*|typing_extensions-*|wheel-*) ;;
    *) rm -f "$d/REQUESTED"; sed -i "/^[^,]*\.dist-info\/REQUESTED,/d" "$d/RECORD" ;;
  esac
done
# Smoke test; no bytecode written, so site-packages stays as pip left it.
PYTHONDONTWRITEBYTECODE=1 python -c "import torch, numpy, scipy, gymnasium, Box2D; gymnasium.make('BipedalWalkerHardcore-v3').reset(seed=0); print('torch', torch.__version__, 'numpy', numpy.__version__, 'gymnasium', gymnasium.__version__)"
