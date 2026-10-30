#!/bin/sh
# v1 work/judge setup step: `apt-get install -y --no-install-recommends python3 python3-numpy`.
# Shared by environment/Dockerfile and judge/Dockerfile. Versions are pinned to the
# ones recorded in the published v1 images (dpkg status); they come from the base's
# dated Ubuntu snapshot (sources.list set by bases/cpp), and apt checks the signed
# InRelease and every .deb's sha256. numpy matters: tools/gen_data.py output depends on it.
set -eux
apt-get update
apt-get install -y --no-install-recommends \
  python3=3.10.6-1~22.04.1 \
  python3-minimal=3.10.6-1~22.04.1 \
  libpython3-stdlib=3.10.6-1~22.04.1 \
  python3.10=3.10.12-1~22.04.15 \
  python3.10-minimal=3.10.12-1~22.04.15 \
  libpython3.10-minimal=3.10.12-1~22.04.15 \
  libpython3.10-stdlib=3.10.12-1~22.04.15 \
  python3-numpy=1:1.21.5-1ubuntu22.04.1 \
  python3-pkg-resources=59.6.0-1.2ubuntu0.22.04.3 \
  libblas3=3.10.0-2ubuntu1 \
  liblapack3=3.10.0-2ubuntu1 \
  libgfortran5=12.3.0-1ubuntu1~22.04.3 \
  libmpdec3=2.5.1-2build2 \
  libreadline8=8.1.2-1 \
  readline-common=8.1.2-1 \
  libsqlite3-0=3.37.2-2ubuntu0.5 \
  media-types=7.0.0
rm -rf /var/lib/apt/lists/*
python3 -c 'import numpy; assert numpy.__version__ == "1.21.5", numpy.__version__'
