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

"""Build, pull and push task images with the docker CLI.

Every image is built from a Dockerfile in the task (or base) directory and
tagged with the content hash computed by :class:`TaskSpec`, so an existing
tag is always up to date. Proxies are passed as Docker's predefined build
args, which are not recorded in the image.
"""

from __future__ import annotations

import hashlib
import json
import logging
import os
import re
import shutil
import subprocess
import urllib.error
import urllib.parse
import urllib.request
import sys
import threading
from pathlib import Path

from sforge.harness.config import SForgeConfig
from sforge.harness.constants import UTF8
from sforge.harness.task_spec import TaskSpec

_locks: dict[str, threading.Lock] = {}
_locks_guard = threading.Lock()


class BuildImageError(Exception):
    def __init__(self, image_name: str, message: str, log_file: Path | None = None):
        super().__init__(message)
        self.image_name = image_name
        self.log_path = log_file

    def __str__(self):
        return (
            f"Error building image {self.image_name}: {super().__str__()}\n"
            f"Check ({self.log_path}) for more information."
        )


def setup_logger(
    name: str, log_file: Path, mode: str = "w", verbose: bool = False
) -> logging.Logger:
    """Create a file logger (plus stdout when *verbose*)."""
    log_file.parent.mkdir(parents=True, exist_ok=True)
    logger = logging.getLogger(f"sforge.{name}.{log_file.name}")
    handler = logging.FileHandler(log_file, mode=mode, encoding=UTF8)
    handler.setFormatter(logging.Formatter("%(asctime)s - %(levelname)s - %(message)s"))
    logger.addHandler(handler)
    if verbose:
        console = logging.StreamHandler(sys.stdout)
        console.setFormatter(logging.Formatter("%(message)s"))
        logger.addHandler(console)
    logger.setLevel(logging.INFO)
    logger.propagate = False
    setattr(logger, "log_file", log_file)
    return logger


def close_logger(logger: logging.Logger) -> None:
    for handler in logger.handlers:
        handler.close()
        logger.removeHandler(handler)


def image_exists(key: str) -> bool:
    return subprocess.run(
        ["docker", "image", "inspect", key], capture_output=True,
    ).returncode == 0


def _lock(key: str) -> threading.Lock:
    with _locks_guard:
        return _locks.setdefault(key, threading.Lock())


def _build(
    key: str,
    dockerfile: Path,
    context: Path,
    spec: TaskSpec,
    config: SForgeConfig,
    *,
    force: bool,
    verbose: bool,
) -> str:
    with _lock(key):
        if not force and image_exists(key):
            return key
        if context == spec.task_dir:
            ensure_blobs(spec)
        log_file = config.log_dir / "build_images" / f"{key.replace(':', '_')}.log"
        log_file.parent.mkdir(parents=True, exist_ok=True)
        cmd = ["docker", "build", "--platform", spec.platform,
               "-f", str(dockerfile), "-t", key]
        if spec.base_image_key and context != spec.base_dir:
            cmd += ["--build-arg", f"BASE_IMAGE={spec.base_image_key}"]
        for arg, value in (("http_proxy", config.http_proxy), ("https_proxy", config.https_proxy),
                           ("no_proxy", config.no_proxy)):
            if value:
                cmd += ["--build-arg", f"{arg}={value}", "--build-arg", f"{arg.upper()}={value}"]
        cmd.append(str(context))
        with open(log_file, "w") as log:
            log.write(" ".join(cmd) + "\n")
            log.flush()
            proc = subprocess.run(
                cmd, stdout=None if verbose else log, stderr=subprocess.STDOUT if not verbose else None,
            )
        if proc.returncode != 0:
            raise BuildImageError(key, f"docker build exited {proc.returncode}", log_file)
        return key


def _sha256(path: Path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def ensure_blobs(spec: TaskSpec) -> None:
    """Make every blob in task.toml present with the right sha256, downloading
    missing ones from ``$SFORGE_BLOB_URL/<sha256>`` (default: the benchmark's ``blob_url``)."""
    base_url = os.environ.get("SFORGE_BLOB_URL") or spec.benchmark.blob_url
    for blob in spec.blobs:
        dest = spec.task_dir / blob.path
        if dest.exists() and _sha256(dest) == blob.sha256:
            continue
        dest.parent.mkdir(parents=True, exist_ok=True)
        part = dest.with_name(dest.name + ".part")
        if not base_url:
            raise BuildImageError(spec.task_id, f"blob {blob.path} is missing; set blob_url in benchmark.toml or SFORGE_BLOB_URL")
        url = f"{base_url.rstrip('/')}/{blob.sha256}"
        try:
            with urllib.request.urlopen(url) as resp, open(part, "wb") as fh:
                shutil.copyfileobj(resp, fh)
        except OSError as e:
            part.unlink(missing_ok=True)
            raise BuildImageError(spec.task_id, f"blob {blob.path}: cannot download {url}: {e}") from e
        digest = _sha256(part)
        if digest != blob.sha256:
            part.unlink()
            raise BuildImageError(spec.task_id, f"blob {blob.path}: downloaded sha256 {digest} != {blob.sha256}")
        part.replace(dest)


def build_base_image(spec: TaskSpec, config: SForgeConfig, *, force: bool = False,
                     verbose: bool = False) -> str | None:
    if not spec.base:
        return None
    return _build(spec.base_image_key, spec.base_dir / "Dockerfile", spec.base_dir,
                  spec, config, force=force, verbose=verbose)


def build_work_image(spec: TaskSpec, config: SForgeConfig, *, force: bool = False,
                     verbose: bool = False) -> str:
    build_base_image(spec, config, verbose=verbose)
    return _build(spec.work_image_key, spec.task_dir / "environment" / "Dockerfile",
                  spec.task_dir, spec, config, force=force, verbose=verbose)


def build_judge_image(spec: TaskSpec, config: SForgeConfig, *, force: bool = False,
                      verbose: bool = False) -> str:
    build_base_image(spec, config, verbose=verbose)
    return _build(spec.judge_image_key, spec.task_dir / "judge" / "Dockerfile",
                  spec.task_dir, spec, config, force=force, verbose=verbose)


def build_all_images(spec: TaskSpec, config: SForgeConfig, *, force: bool = False,
                     force_base: bool = False, verbose: bool = False):
    base = build_base_image(spec, config, force=force_base, verbose=verbose)
    work = build_work_image(spec, config, force=force, verbose=verbose)
    judge = build_judge_image(spec, config, force=force, verbose=verbose)
    return base, work, judge


def _keys(spec: TaskSpec) -> list[str]:
    return [spec.work_image_key, spec.judge_image_key]


def remote_ref(registry: str, key: str) -> str:
    """Where image *key* lives under the *registry* prefix, one repository per
    image: ``bench.base.cpp:0123abcd`` -> ``<registry>/bench.base.cpp:0123abcd``."""
    return f"{registry.rstrip('/')}/{key}"


_MANIFEST_TYPES = ", ".join((
    "application/vnd.docker.distribution.manifest.v2+json",
    "application/vnd.docker.distribution.manifest.list.v2+json",
    "application/vnd.oci.image.index.v1+json",
    "application/vnd.oci.image.manifest.v1+json",
))


def registry_has(ref: str) -> bool:
    """Whether the registry has image *ref* (``host/name:tag``), checked with a
    HEAD request, which Docker Hub does not count against its pull rate limit.
    Tries https, then plain http (e.g. a local test registry)."""
    host, _, name_tag = ref.partition("/")
    if "." not in host and ":" not in host and host != "localhost":
        host, name_tag = "docker.io", ref
    if host == "docker.io":
        host = "registry-1.docker.io"
    name, _, tag = name_tag.rpartition(":")
    if not name:
        return False
    for scheme in ("https", "http"):
        try:
            return _manifest_exists(f"{scheme}://{host}/v2/{name}/manifests/{tag}")
        except (OSError, ValueError):
            continue
    return False


def _manifest_exists(url: str) -> bool:
    """HEAD a registry manifest, with an anonymous bearer token when the registry
    asks for one (Docker Hub does even for public images). Raises OSError when
    the registry cannot be reached."""
    headers = {"Accept": _MANIFEST_TYPES}
    for _ in range(2):
        try:
            with urllib.request.urlopen(urllib.request.Request(url, method="HEAD", headers=headers), timeout=10):
                return True
        except urllib.error.HTTPError as e:
            challenge = e.headers.get("WWW-Authenticate", "")
            if e.code != 401 or not challenge.startswith("Bearer ") or "Authorization" in headers:
                return False
            params = dict(re.findall(r'(\w+)="([^"]*)"', challenge))
            realm = params.pop("realm", "")
            with urllib.request.urlopen(f"{realm}?{urllib.parse.urlencode(params)}", timeout=10) as resp:
                body = json.load(resp)
            headers["Authorization"] = f"Bearer {body.get('token') or body.get('access_token')}"
    return False


def pull_all_images(spec: TaskSpec, registry: str) -> dict[str, bool]:
    """Pull work + judge from ``registry`` and tag them with their local keys."""
    ok: dict[str, bool] = {}
    for key in _keys(spec):
        remote = remote_ref(registry, key)
        with _lock(key):
            ok[key] = image_exists(key) or (
                subprocess.run(["docker", "pull", remote]).returncode == 0
                and subprocess.run(["docker", "tag", remote, key]).returncode == 0
            )
    return ok


def push_all_images(spec: TaskSpec, registry: str) -> dict[str, bool]:
    """Push base (if any) + work + judge to ``registry``."""
    ok: dict[str, bool] = {}
    keys = ([spec.base_image_key] if spec.base else []) + _keys(spec)
    for key in keys:
        remote = remote_ref(registry, key)
        with _lock(f"push:{remote}"):
            ok[key] = (
                subprocess.run(["docker", "tag", key, remote]).returncode == 0
                and subprocess.run(["docker", "push", remote]).returncode == 0
            )
    return ok
