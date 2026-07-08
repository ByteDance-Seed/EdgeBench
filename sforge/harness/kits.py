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

"""Build work/judge images from self-contained build kits.

A kit directory reproduces a released task image as: base image (built locally
from BENCHMARK.yaml) + kit. Kits are exported from released images by
benchmark maintainers; consumers only need this module via
`python -m sforge build --task <id> --kits-dir <root>`. A kit contains:

    Dockerfile        FROM <deterministic base tag> [+ RUN rm] + ADD context.tar
    context.tar       merged filesystem diff above the base, headers preserved
    MANIFEST.sha256   per-file sha256 + mode + uid:gid + size
    kit.json          provenance, final image name, base-file deletions

Kits for a task live at <kits_root>/<task_id>/{work,judge}/.
"""

from __future__ import annotations

import concurrent.futures
import hashlib
import json
import logging
import re
import tarfile
import tempfile
from pathlib import Path

import docker

from sforge.harness.config import SForgeConfig
from sforge.harness.docker_build import BuildImageError, _image_exists, build_base_image
from sforge.harness.task_spec import TaskSpec

logger = logging.getLogger(__name__)

_MANIFEST_RE = re.compile(r"^(\S+)  (0o\d+) (\d+):(\d+) +(\d+)  /(.*)$")



class KitError(Exception):
    pass


def kit_dir_for(kits_root: Path, task_id: str, kind: str) -> Path:
    return Path(kits_root) / task_id / kind


def _load_kit_meta(kit_dir: Path) -> dict:
    kit_json = kit_dir / "kit.json"
    if not kit_json.is_file():
        raise KitError(f"not a kit directory (missing kit.json): {kit_dir}")
    return json.loads(kit_json.read_text())


def build_image_from_kit(
    image_name: str,
    kit_dir: Path,
    client: docker.DockerClient,
    force_rebuild: bool = False,
    verbose: bool = False,
) -> str:
    """docker-build a kit directory and tag it as image_name."""
    if not force_rebuild and _image_exists(client, image_name):
        return image_name

    kit = _load_kit_meta(kit_dir)
    from_tag = kit.get("from_tag")
    if from_tag and not _image_exists(client, from_tag):
        raise KitError(
            f"base image '{from_tag}' not found locally. "
            f"Build the task with --kits-dir (the base is built automatically "
            f"from BENCHMARK.yaml first)."
        )
    if kit.get("final_name") and kit["final_name"] != image_name:
        logger.warning(
            "kit %s declares final_name=%s but task expects %s; tagging as the latter",
            kit_dir, kit["final_name"], image_name,
        )

    if verbose:
        print(f"[kit] docker build {kit_dir} -> {image_name}")
    try:
        client.images.build(
            path=str(kit_dir), tag=image_name, rm=True, nocache=force_rebuild,
        )
    except docker.errors.BuildError as e:
        raise BuildImageError(image_name, f"kit build failed: {e}", logger) from e
    return image_name


def verify_image_against_kit(
    image_name: str,
    kit_dir: Path,
    client: docker.DockerClient,
    verbose: bool = False,
) -> list[str]:
    """Check every MANIFEST entry (content sha256 + mode + uid:gid) and every
    recorded deletion against the built image's filesystem. Returns a list of
    problem descriptions (empty = OK)."""
    kit = _load_kit_meta(kit_dir)
    deletions = kit.get("deletions", [])

    entries = []
    for line in (kit_dir / "MANIFEST.sha256").read_text().splitlines():
        m = _MANIFEST_RE.match(line)
        if not m:
            raise KitError(f"unparseable manifest line in {kit_dir}: {line}")
        entries.append(m.groups())  # digest, mode, uid, gid, size, path

    container = client.containers.create(image_name)
    try:
        with tempfile.TemporaryFile() as export:
            for chunk in container.export():
                export.write(chunk)
            export.seek(0)

            seen: dict[str, tuple] = {}
            with tarfile.open(fileobj=export) as t:
                for mem in t:
                    p = mem.name.strip("/").removeprefix("./")
                    if mem.isreg():
                        h = hashlib.sha256()
                        f = t.extractfile(mem)
                        for chunk in iter(lambda: f.read(1 << 20), b""):
                            h.update(chunk)
                        seen[p] = ("file", h.hexdigest(), mem.mode, mem.uid, mem.gid)
                    elif mem.issym():
                        seen[p] = ("symlink", mem.linkname, mem.mode, mem.uid, mem.gid)
                    elif mem.isdir():
                        seen[p] = ("dir", None, mem.mode, mem.uid, mem.gid)
                    elif mem.islnk():
                        seen[p] = ("hardlink", mem.linkname.strip("/"), mem.mode, mem.uid, mem.gid)
    finally:
        container.remove(force=True)

    problems: list[str] = []
    manifest_paths = set()
    for digest, mode_s, uid_s, gid_s, _size, path in entries:
        path = path.rstrip("/")
        manifest_paths.add(path)
        got = seen.get(path)
        mode, uid, gid = int(mode_s, 8), int(uid_s), int(gid_s)
        if got is None:
            problems.append(f"MISSING /{path}")
            continue
        kind, gdigest, gmode, guid, ggid = got
        want_kind = ("dir" if digest == "dir"
                     else "symlink" if digest.startswith("symlink->")
                     else "hardlink" if digest.startswith("hardlink->")
                     else "file")
        ok = (
            (want_kind == "dir" and kind == "dir")
            or (want_kind == "symlink" and kind == "symlink"
                and gdigest == digest[len("symlink->"):])
            or (want_kind == "hardlink" and kind in ("hardlink", "file"))
            or (want_kind == "file" and kind == "file" and gdigest == digest)
        )
        if not ok:
            problems.append(f"CONTENT /{path} want {digest[:32]} got {kind}:{str(gdigest)[:32]}")
        if (gmode, guid, ggid) != (mode, uid, gid):
            problems.append(
                f"META /{path} want {oct(mode)} {uid}:{gid} got {oct(gmode)} {guid}:{ggid}"
            )
    for d in deletions:
        if d in seen and d not in manifest_paths:
            problems.append(f"UNDELETED /{d}")

    if verbose:
        print(f"[kit] verify {image_name}: {len(entries)} entries, "
              f"{len(deletions)} deletions, {len(problems)} problem(s)")
    return problems


def build_task_images_from_kits(
    task_spec: TaskSpec,
    kits_root: Path,
    config: SForgeConfig,
    client: docker.DockerClient,
    force_rebuild: bool = False,
    force_rebuild_base: bool = False,
    verify: bool = False,
    verbose: bool = False,
) -> tuple[str, str, str]:
    """Build base (from BENCHMARK.yaml) + work + judge (from kits) for a task.

    Returns (base, work, judge) image tags. Raises KitError/BuildImageError on
    failure, including verification mismatches when verify=True.
    """
    base = build_base_image(
        task_spec, config, client, force_rebuild=force_rebuild_base, verbose=verbose,
    )

    jobs = [
        (task_spec.work_image_key, kit_dir_for(kits_root, task_spec.task_id, "work")),
        (task_spec.judge_image_key, kit_dir_for(kits_root, task_spec.task_id, "judge")),
    ]
    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as ex:
        futs = [
            ex.submit(build_image_from_kit, name, kd, client,
                      force_rebuild=force_rebuild, verbose=verbose)
            for name, kd in jobs
        ]
        work, judge = (f.result() for f in futs)

    if verify:
        for name, kd in jobs:
            problems = verify_image_against_kit(name, kd, client, verbose=verbose)
            if problems:
                detail = "\n  ".join(problems[:20])
                raise KitError(
                    f"{name} failed kit verification ({len(problems)} problem(s)):\n  {detail}"
                )

    return base, work, judge
