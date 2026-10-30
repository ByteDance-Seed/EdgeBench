# Copyright (c) 2026 ByteDance Ltd. and/or its affiliates
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Agent bundles: a pinned agent CLI installed on the host, injected at run time.

Task images never contain an agent. Before a run, the harness builds (once,
cached) a tarball holding a pinned Node.js plus ``npm install -g <package>@<version>``
under ``/opt/sforge-agent``, copies it into the work container, unpacks it and
links one launcher per CLI into ``/usr/local/bin``. Node itself stays off
``PATH`` so the task's own toolchain is untouched, and the sandbox needs no
network access to install anything.

Bundles are built for linux/amd64 (the platform of every task image), so the
build host must be Linux x86_64. Prebuilt bundles can be dropped into the cache
directory (``$SFORGE_CACHE_DIR/agents``, default ``~/.cache/sforge/agents``).
"""

from __future__ import annotations

import fcntl
import hashlib
import json
import logging
import os
import platform
import posixpath
import re
import shlex
import shutil
import subprocess
import tarfile
import tempfile
import urllib.request
from pathlib import Path

from sforge.harness.backend import ContainerBackend, ContainerHandle
from sforge.harness.constants import CONTAINER_DIR
from sforge.harness.tarutil import safe_extractall

PREFIX = f"{CONTAINER_DIR}/agent"
NODE_VERSION = "22.23.3"
NODE_SHA256 = "df450af89261115ef9f9e3830c3eeb2cc9213b63c720b1af623cb5dcbe2e02de"
NODE_DIST = "https://nodejs.org/dist"

_VERSION_RE = re.compile(r"[0-9A-Za-z][0-9A-Za-z.+-]*")


def cache_dir() -> Path:
    root = os.environ.get("SFORGE_CACHE_DIR") or Path.home() / ".cache" / "sforge"
    return Path(root) / "agents"


def bundle_path(package: str, version: str) -> Path:
    safe = package.lstrip("@").replace("/", "-")
    return cache_dir() / f"{safe}-{version}-node{NODE_VERSION}-linux-x64.tar.gz"


def ensure_bundle(
    package: str,
    version: str,
    *,
    node_mirror: str | None = None,
    logger: logging.Logger | None = None,
) -> Path:
    """Return the cached bundle for ``package@version``, building it if needed."""
    if not _VERSION_RE.fullmatch(version):
        raise ValueError(f"Invalid agent version {version!r}")
    out = bundle_path(package, version)
    if out.exists():
        return out
    out.parent.mkdir(parents=True, exist_ok=True)
    with open(out.with_suffix(".lock"), "w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        if not out.exists():
            _build(package, version, out, node_mirror, logger)
    return out


def inject_bundle(
    backend: ContainerBackend,
    handle: ContainerHandle,
    bundle: Path,
) -> None:
    """Unpack *bundle* into the container and link its launchers onto PATH."""
    remote = CONTAINER_DIR / "agent.tar.gz"
    backend.copy_to_container(handle, bundle, remote)
    cmd = (
        f"tar xzf {remote} -C / && rm -f {remote} && "
        f"ln -sf {PREFIX}/launchers/* /usr/local/bin/"
    )
    result = backend.exec_run(handle, ["/bin/sh", "-c", cmd])
    if result.exit_code != 0:
        raise RuntimeError(f"Failed to install agent bundle: {result.output}")


def _build(
    package: str,
    version: str,
    out: Path,
    node_mirror: str | None,
    logger: logging.Logger | None,
) -> None:
    if platform.system() != "Linux" or platform.machine() not in ("x86_64", "AMD64"):
        raise RuntimeError(
            f"Building agent bundles needs a Linux x86_64 host (got "
            f"{platform.system()} {platform.machine()}). Copy a prebuilt "
            f"{out.name} into {out.parent} instead."
        )
    if logger:
        logger.info("Building agent bundle %s@%s (node %s)", package, version, NODE_VERSION)
    with tempfile.TemporaryDirectory(prefix="sforge-bundle-") as tmp:
        root = Path(tmp) / PREFIX.lstrip("/")
        node_dir = root / "node"
        _fetch_node(node_dir, node_mirror or NODE_DIST)

        # npm reads its own npm_config_registry etc. from the environment.
        env = {**os.environ, "PATH": f"{node_dir / 'bin'}:{os.environ.get('PATH', '')}"}
        subprocess.run(
            [str(node_dir / "bin" / "npm"), "install", "-g", "--no-fund",
             "--no-audit", "--prefix", str(root), f"{package}@{version}"],
            env=env, check=True, capture_output=True, text=True,
        )
        if not _write_launchers(root, package):
            shutil.rmtree(node_dir)  # every CLI is a native binary

        partial = out.with_suffix(".partial")
        with tarfile.open(partial, "w:gz") as tar:
            tar.add(root, arcname=PREFIX.lstrip("/"))
        partial.rename(out)


def _fetch_node(dest: Path, dist: str) -> None:
    name = f"node-v{NODE_VERSION}-linux-x64.tar.xz"
    with tempfile.TemporaryDirectory() as tmp:
        archive = Path(tmp) / name
        with urllib.request.urlopen(f"{dist.rstrip('/')}/v{NODE_VERSION}/{name}") as resp:
            with open(archive, "wb") as fh:
                shutil.copyfileobj(resp, fh)
        digest = hashlib.sha256(archive.read_bytes()).hexdigest()
        if digest != NODE_SHA256:
            raise RuntimeError(f"{name}: sha256 {digest} does not match the pinned {NODE_SHA256}")
        with tarfile.open(archive) as tar:
            safe_extractall(tar, Path(tmp))
        shutil.move(str(Path(tmp) / f"node-v{NODE_VERSION}-linux-x64"), dest)


def _write_launchers(root: Path, package: str) -> bool:
    """One launcher per CLI in the package's ``bin`` map. Native binaries are
    exec'd directly; JS entry points run on the bundled node. Returns whether
    any launcher needs node."""
    pkg_dir = root / "lib" / "node_modules" / package
    bins = json.loads((pkg_dir / "package.json").read_text()).get("bin") or {}
    if isinstance(bins, str):
        bins = {package.rsplit("/", 1)[-1]: bins}
    launchers = root / "launchers"
    launchers.mkdir()
    needs_node = False
    for name, rel in bins.items():
        rel = posixpath.normpath(rel)
        target = pkg_dir / rel
        in_container = f"{PREFIX}/lib/node_modules/{package}/{rel}"
        with open(target, "rb") as fh:
            native = fh.read(4) == b"\x7fELF"
        needs_node = needs_node or not native
        exec_line = (
            f"exec {shlex.quote(in_container)} \"$@\"" if native
            else f"exec {PREFIX}/node/bin/node {shlex.quote(in_container)} \"$@\""
        )
        launcher = launchers / name
        launcher.write_text(f"#!/bin/sh\n{exec_line}\n")
        launcher.chmod(0o755)
    return needs_node
