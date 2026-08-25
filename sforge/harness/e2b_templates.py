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

"""Deterministic E2B Template supply chain for SForge task images."""

from __future__ import annotations

import hashlib
import io
import json
import re
import shlex
import stat
import tarfile
import time
from dataclasses import asdict, dataclass, replace
from pathlib import Path

import docker.errors
import requests

from sforge.harness.task_spec import TaskSpec

# schema_version stays 4: the manifest gains a snapshot_roots field, but that
# field is excluded from the fingerprint, and schema_version itself is part of
# every existing fingerprint. Keeping it at 4 lets clean tasks and tasks whose
# image /tmp is empty reuse their current E2B builds; only tasks that actually
# ship files under /tmp get a new fingerprint and rebuild.
MANIFEST_SCHEMA_VERSION = 4
PORTABLE_IMAGE_RECIPE_VERSION = 2
WORK_FILESYSTEM_RECIPE_VERSION = 2
DEFAULT_WORK_MEMORY_MB = 4096
DEFAULT_JUDGE_MEMORY_MB = 8192

# The official task images predate E2B and ship evaluator helpers under /tmp: a
# wrapper the command names plus other files that wrapper reads at runtime.
# Docker and Kubernetes boot from the image, so those files are simply present;
# E2B resets /tmp on every Sandbox, so any helper the command does not name on
# its own line silently disappears. SForge therefore snapshots the image's
# initial /tmp and restores it on Sandbox start, restoring parity with the other
# backends. This is a backend-compatibility shim: it never rewrites the official
# images, the evaluators, or any scoring behavior.
_TMP_SNAPSHOT_ROOT = "/tmp"
_TMP_SNAPSHOT_PERSISTENT = "/opt/sforge/runtime/tmp"
TMP_SNAPSHOT_RECIPE_VERSION = 1
# A /tmp path named anywhere in the role's command decides *whether* to attempt
# a snapshot; the snapshot itself always captures the whole image /tmp, so
# helpers the command reaches only indirectly come along too. Capturing all of
# /tmp (rather than the named paths) is what makes this robust, and keying the
# decision on a /tmp reference preserves the no-pull fast path for the many
# tasks — including multi-gigabyte ones — that never touch /tmp.
_TMP_PATH = re.compile(r"(?<![A-Za-z0-9_.-])/tmp(?:/|\b)")
# game_server_app.py is injected by the harness after Sandbox creation, so it is
# never part of the image and must not be captured from a stale image copy.
_SNAPSHOT_EXCLUDE_NAMES = frozenset({"game_server_app.py"})
# Snapshots stay tiny in practice (image /tmp holds a handful of helper files).
# These ceilings only guard against a pathological image and fail the build
# loudly rather than silently truncating.
MAX_SNAPSHOT_ENTRIES = 4096
MAX_SNAPSHOT_BYTES = 256 * 1024 * 1024


class AptSourceError(RuntimeError):
    """The source image uses an APT source unavailable to E2B builds."""


def _is_missing_image_error(exc: Exception) -> bool:
    if isinstance(exc, (docker.errors.ImageNotFound, docker.errors.NotFound)):
        return True
    # Some Registry implementations surface a missing manifest through the
    # Docker Engine distribution endpoint as HTTP 500 instead of 404. Only
    # accept its explicit not-found wording; other server errors remain fatal.
    message = str(exc).lower()
    return "artifact " in message and " not found" in message


def _manifest_fingerprint(data: dict, role: str) -> str:
    fingerprint_data = dict(data)
    if role == "work":
        fingerprint_data["filesystem_recipe_version"] = WORK_FILESYSTEM_RECIPE_VERSION
    # snapshot_roots records the build-time intent to snapshot /tmp; it is not
    # part of the built template's content, so it never enters the fingerprint.
    # Only a non-empty captured payload (runtime_artifacts) changes what the
    # template ships, so the snapshot recipe version is folded in only then.
    # This keeps clean tasks byte-identical to the pre-snapshot fingerprint and
    # avoids rebuilding every template.
    fingerprint_data.pop("snapshot_roots", None)
    if fingerprint_data.get("runtime_artifacts"):
        fingerprint_data["tmp_snapshot_recipe_version"] = TMP_SNAPSHOT_RECIPE_VERSION
    return hashlib.sha256(
        json.dumps(fingerprint_data, sort_keys=True).encode()
    ).hexdigest()


def template_name(image_key: str) -> str:
    repo, _, _ = image_key.partition(":")
    return repo.lower().replace(".", "-").replace("_", "-")


def template_tag(image_key: str) -> str:
    _, sep, tag = image_key.rpartition(":")
    if not sep or not tag:
        raise ValueError(f"Image key has no immutable tag: {image_key!r}")
    return tag


def parse_memory_mb(value: str | None, default: int = 4096) -> int:
    if value is None:
        return default
    raw = str(value).strip().lower()
    match = re.fullmatch(r"(\d+)([kmgt]i?b?|)", raw)
    if not match:
        raise ValueError(f"Unsupported memory value: {value!r}")
    amount = int(match.group(1))
    if amount <= 0:
        raise ValueError("Memory must be greater than zero")
    unit = match.group(2)
    if unit in ("", "m", "mb", "mib"):
        return amount
    if unit in ("k", "kb", "kib"):
        return max(1, amount // 1024)
    if unit in ("g", "gb", "gib"):
        return amount * 1024
    if unit in ("t", "tb", "tib"):
        return amount * 1024 * 1024
    raise ValueError(f"Unsupported memory unit: {unit!r}")


@dataclass(frozen=True)
class RuntimeArtifact:
    source: str
    persistent: str
    digest: str = ""


@dataclass(frozen=True)
class TemplateManifest:
    schema_version: int
    task_id: str
    role: str
    source_image: str
    source_image_digest: str
    image_key: str
    name: str
    tag: str
    user: str
    workdir: str
    cpu_count: int
    memory_mb: int
    environment: tuple[tuple[str, str], ...]
    runtime_artifacts: tuple[RuntimeArtifact, ...]
    snapshot_roots: tuple[str, ...]
    fingerprint: str

    @property
    def reference(self) -> str:
        return f"{self.name}:{self.tag}"

    def to_dict(self) -> dict:
        return asdict(self)


def _command_references_tmp(task_spec: TaskSpec, role: str) -> bool:
    """Whether the role's command touches /tmp, so its image /tmp is snapshotted.

    This only decides *whether* to snapshot. The snapshot itself always captures
    the entire image /tmp, so evaluator helpers the command reaches only
    indirectly (a wrapper that reads a sibling file) are preserved too. Keying
    the decision on a /tmp reference keeps the no-pull fast path for the many
    tasks — including multi-gigabyte ones — whose commands never touch /tmp.
    """
    if role == "work":
        command = task_spec.work.agent_query or ""
    else:
        command = " ".join(
            filter(
                None,
                (
                    task_spec.judge.eval_cmd,
                    task_spec.judge.game_server_cmd,
                ),
            )
        )
    return bool(_TMP_PATH.search(command))


def make_template_manifest(
    task_spec: TaskSpec,
    role: str,
    source_registry: str,
    *,
    cpu_count: int | None = None,
    memory_mb: int | None = None,
) -> TemplateManifest:
    if role not in ("work", "judge"):
        raise ValueError("Template role must be 'work' or 'judge'")
    image_key = (
        task_spec.work_image_key if role == "work" else task_spec.judge_image_key
    )
    spec = task_spec.work if role == "work" else task_spec.judge
    snapshot_roots = (
        (_TMP_SNAPSHOT_ROOT,)
        if _command_references_tmp(task_spec, role)
        else ()
    )
    resolved_cpu = cpu_count if cpu_count is not None else spec.cpu_limit or 4
    resolved_memory = (
        memory_mb
        if memory_mb is not None
        else parse_memory_mb(
            spec.mem_limit,
            default=(
                DEFAULT_WORK_MEMORY_MB
                if role == "work"
                else DEFAULT_JUDGE_MEMORY_MB
            ),
        )
    )
    if resolved_cpu <= 0:
        raise ValueError("Template CPU count must be greater than zero")
    if resolved_memory <= 0:
        raise ValueError("Template memory must be greater than zero")
    core = {
        "schema_version": MANIFEST_SCHEMA_VERSION,
        "task_id": task_spec.task_id,
        "role": role,
        "source_image": f"{source_registry.rstrip('/')}/{image_key}",
        "source_image_digest": "",
        "image_key": image_key,
        "name": template_name(image_key),
        "tag": template_tag(image_key),
        "user": "agent" if role == "work" else "root",
        "workdir": task_spec.cwd,
        "cpu_count": resolved_cpu,
        "memory_mb": resolved_memory,
        "environment": [],
        "runtime_artifacts": [],
        "snapshot_roots": list(snapshot_roots),
    }
    fingerprint = _manifest_fingerprint(core, role)
    return TemplateManifest(
        **{
            **core,
            "runtime_artifacts": (),
            "snapshot_roots": snapshot_roots,
        },
        fingerprint=fingerprint,
    )


def _restore_command(manifest: TemplateManifest) -> str | None:
    if not manifest.runtime_artifacts:
        return None
    commands = []
    for item in manifest.runtime_artifacts:
        parent = str(Path(item.source).parent)
        # Merge each captured entry back into place without touching the
        # directory root: /tmp keeps its E2B-provisioned runtime files and its
        # sticky bit. `cp -aT` treats the destination as the entry itself, so a
        # directory that already exists is overwritten in place rather than
        # nested under itself, making restore idempotent across restarts. The
        # && chain means any failed copy aborts start-up, so a broken restore
        # surfaces as a Sandbox that never becomes ready instead of an evaluator
        # silently missing a helper.
        commands.append(
            f"mkdir -p {shlex.quote(parent)} && "
            f"cp -aT {shlex.quote(item.persistent)} {shlex.quote(item.source)}"
        )
    return " && ".join(commands) + " && sleep infinity"


def _replace_runtime_artifacts(
    manifest: TemplateManifest,
    artifacts: tuple[RuntimeArtifact, ...],
) -> TemplateManifest:
    provisional = replace(manifest, runtime_artifacts=artifacts, fingerprint="")
    data = asdict(provisional)
    data.pop("fingerprint")
    fingerprint = _manifest_fingerprint(data, manifest.role)
    return replace(provisional, fingerprint=fingerprint)


def _replace_image_metadata(
    manifest: TemplateManifest,
    source_image: str,
    environment: tuple[tuple[str, str], ...],
) -> TemplateManifest:
    provisional = replace(
        manifest,
        source_image=source_image,
        source_image_digest=source_image.split("@", 1)[1],
        environment=environment,
        fingerprint="",
    )
    data = asdict(provisional)
    data.pop("fingerprint")
    return replace(
        provisional, fingerprint=_manifest_fingerprint(data, manifest.role),
    )


def _image_environment(image) -> tuple[tuple[str, str], ...]:
    values = {}
    for entry in (image.attrs.get("Config") or {}).get("Env") or []:
        key, separator, value = entry.partition("=")
        normalized = key.lower()
        sensitive = any(
            marker in normalized
            for marker in (
                "api_key", "access_key", "auth", "credential",
                "password", "passwd", "private_key", "secret", "token",
            )
        )
        host_specific = normalized in {
            "http_proxy", "https_proxy", "no_proxy",
        }
        if (
            separator
            and re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", key)
            and not sensitive
            and not host_specific
        ):
            values[key] = value
    return tuple(sorted(values.items()))


_MANIFEST_ACCEPT = ", ".join((
    "application/vnd.oci.image.index.v1+json",
    "application/vnd.oci.image.manifest.v1+json",
    "application/vnd.docker.distribution.manifest.list.v2+json",
    "application/vnd.docker.distribution.manifest.v2+json",
))


def _registry_location(image_ref: str) -> tuple[str, str, str]:
    name, separator, identifier = image_ref.partition("@")
    if not separator:
        name, separator, identifier = image_ref.rpartition(":")
        if not separator or "/" in identifier:
            name, identifier = image_ref, "latest"
    parts = name.split("/")
    if len(parts) > 1 and ("." in parts[0] or ":" in parts[0] or parts[0] == "localhost"):
        registry, repository = parts[0], "/".join(parts[1:])
    else:
        registry = "registry-1.docker.io"
        repository = name if "/" in name else f"library/{name}"
    return registry, repository, identifier


def _registry_image_environment(
    image_ref: str,
    *,
    attempts: int = 3,
    username: str | None = None,
    password: str | None = None,
) -> tuple[tuple[str, str], ...]:
    """Read OCI Config.Env without downloading image layers."""
    if bool(username) != bool(password):
        raise ValueError("Both registry username and password are required")
    registry, repository, identifier = _registry_location(image_ref)
    base_url = f"https://{registry}/v2/{repository}"
    headers = {"Accept": _MANIFEST_ACCEPT}
    auth = (username, password) if username and password else None

    def request(path: str):
        response = requests.get(
            base_url + path, headers=headers, auth=auth, timeout=30,
        )
        if response.status_code != 401:
            response.raise_for_status()
            return response
        scheme, _, parameters = response.headers.get("WWW-Authenticate", "").partition(" ")
        if scheme.lower() != "bearer":
            response.raise_for_status()
        challenge = requests.utils.parse_dict_header(parameters)
        token_response = requests.get(
            challenge["realm"],
            params={
                key: challenge[key]
                for key in ("service", "scope")
                if key in challenge
            },
            auth=auth, timeout=30,
        )
        token_response.raise_for_status()
        token_data = token_response.json()
        token = token_data.get("token") or token_data.get("access_token")
        if not token:
            raise RuntimeError(f"Registry token response for {image_ref!r} had no token")
        headers["Authorization"] = f"Bearer {token}"
        response = requests.get(base_url + path, headers=headers, timeout=30)
        response.raise_for_status()
        return response

    error = None
    for attempt in range(1, max(1, attempts) + 1):
        try:
            manifest = request(f"/manifests/{identifier}").json()
            if "manifests" in manifest:
                descriptor = next(
                    (
                        item for item in manifest["manifests"]
                        if (item.get("platform") or {}).get("os") == "linux"
                        and (item.get("platform") or {}).get("architecture") == "amd64"
                    ),
                    None,
                )
                if descriptor is None:
                    raise RuntimeError(
                        f"Image {image_ref!r} has no linux/amd64 manifest"
                    )
                manifest = request(
                    f"/manifests/{descriptor['digest']}"
                ).json()
            config = manifest.get("config") or {}
            digest = config.get("digest")
            if not isinstance(digest, str) or not digest.startswith("sha256:"):
                raise RuntimeError(
                    f"Image {image_ref!r} has no valid OCI config digest"
                )
            raw = request(f"/blobs/{digest}").content
            if hashlib.sha256(raw).hexdigest() != digest.removeprefix("sha256:"):
                raise RuntimeError(f"OCI config digest mismatch for {image_ref!r}")
            config_data = json.loads(raw)
            image = type("RegistryImage", (), {
                "attrs": {"Config": config_data.get("config") or {}},
            })()
            return _image_environment(image)
        except Exception as exc:
            error = exc
            if attempt < max(1, attempts):
                time.sleep(min(2 ** (attempt - 1), 8))
    raise RuntimeError(
        f"Failed to read OCI config for {image_ref!r} after {attempts} "
        f"attempts: {error}"
    ) from error


def _environment_profile_command(
    environment: tuple[tuple[str, str], ...],
) -> str | None:
    if not environment:
        return None
    content = "".join(
        f"export {key}={shlex.quote(value)}\n" for key, value in environment
    )
    return (
        "mkdir -p /etc/profile.d && printf %s "
        f"{shlex.quote(content)} > /etc/profile.d/sforge-image-env.sh && "
        "chmod 0644 /etc/profile.d/sforge-image-env.sh"
    )


def _runtime_artifact_digest(path: Path) -> str:
    """Hash content plus filesystem semantics preserved by cp -a."""
    digest = hashlib.sha256()
    members = [path]
    if path.is_dir():
        members.extend(sorted(path.rglob("*")))
    for member in members:
        relative = "." if member == path else str(member.relative_to(path))
        kind = "dir" if member.is_dir() else "file"
        mode = stat.S_IMODE(member.stat().st_mode)
        digest.update(f"{relative}\0{kind}\0{mode:o}\0".encode())
        if member.is_file():
            digest.update(member.read_bytes())
        digest.update(b"\0")
    return digest.hexdigest()


def _capture_tmp_snapshot(
    container,
    context_dir: Path,
) -> tuple[tuple[RuntimeArtifact, ...], dict[str, str]]:
    """Snapshot the image's initial /tmp into staged per-entry artifacts.

    The whole directory is captured (not just command-named paths) so evaluator
    helpers reached indirectly survive. Each top-level entry becomes its own
    artifact so the Sandbox restore merges them back into /tmp without recreating
    or clobbering the directory root. Anything unusual — a path escape, a symlink
    or special file, or a payload past the ceilings — fails the build loudly
    rather than being silently dropped.
    """
    try:
        stream, _ = container.get_archive(_TMP_SNAPSHOT_ROOT)
        archive = b"".join(stream)
    except docker.errors.NotFound:
        return (), {}

    staging = context_dir / "tmp-snapshot"
    staging.mkdir(parents=True, exist_ok=True)
    staging_root = staging.resolve()
    with tarfile.open(fileobj=io.BytesIO(archive)) as bundle:
        members = bundle.getmembers()
        if not members:
            return (), {}
        prefix = members[0].name.split("/", 1)[0]
        entry_count = 0
        total_bytes = 0
        keep = []
        for member in members:
            relative = member.name[len(prefix):].lstrip("/")
            if not relative:
                # The /tmp directory itself: E2B provides it, so never recreate
                # or re-permission the root; only its contents are restored.
                continue
            top = relative.split("/", 1)[0]
            if top in _SNAPSHOT_EXCLUDE_NAMES:
                continue
            target = (staging / member.name).resolve()
            if staging_root not in target.parents and target != staging_root:
                raise ValueError(
                    f"Unsafe /tmp snapshot path: {member.name!r}"
                )
            if member.issym() or member.islnk():
                raise ValueError(
                    "/tmp snapshot symlinks are not supported: "
                    f"{member.name!r}"
                )
            if not (member.isfile() or member.isdir()):
                raise ValueError(
                    "/tmp snapshot special files are not supported: "
                    f"{member.name!r}"
                )
            entry_count += 1
            if member.isfile():
                total_bytes += member.size
            if entry_count > MAX_SNAPSHOT_ENTRIES:
                raise ValueError(
                    f"/tmp snapshot exceeds {MAX_SNAPSHOT_ENTRIES} entries"
                )
            if total_bytes > MAX_SNAPSHOT_BYTES:
                raise ValueError(
                    f"/tmp snapshot exceeds {MAX_SNAPSHOT_BYTES} bytes"
                )
            keep.append(member)
        if not keep:
            return (), {}
        # Preserve the image's exact modes so the restored /tmp matches what
        # Docker and Kubernetes see. The loop above already rejected symlinks,
        # hardlinks, special files, and path escapes, so "fully_trusted" adds no
        # new exposure here; it also extracts without the Python 3.14
        # extraction-filter deprecation. Extraction runs as the unprivileged
        # build user, so setuid/setgid bits cannot escalate on the host.
        bundle.extractall(staging, members=keep, filter="fully_trusted")

    source_root = staging / prefix
    artifacts = []
    sources = {}
    for entry in sorted(source_root.iterdir()):
        name = entry.name
        source = f"{_TMP_SNAPSHOT_ROOT}/{name}"
        artifacts.append(
            RuntimeArtifact(
                source=source,
                persistent=f"{_TMP_SNAPSHOT_PERSISTENT}/{name}",
                digest=_runtime_artifact_digest(entry),
            )
        )
        sources[source] = str(entry.relative_to(context_dir))
    return tuple(artifacts), sources


def stage_runtime_artifacts(
    manifest: TemplateManifest,
    docker_client,
    context_dir: Path,
    *,
    pull_attempts: int = 3,
    portable_registry: str | None = None,
    source_registry_username: str | None = None,
    source_registry_password: str | None = None,
    portable_registry_username: str | None = None,
    portable_registry_password: str | None = None,
    force_portable: bool = False,
) -> tuple[TemplateManifest, dict[str, str], bool]:
    """Resolve the immutable source image and snapshot its initial /tmp.

    Tasks whose command never touches /tmp keep the no-pull fast path: only the
    registry digest and OCI environment are resolved, with no image download.
    """
    if not manifest.snapshot_roots and not force_portable:
        try:
            image = docker_client.images.get(manifest.source_image)
        except Exception as exc:
            if not _is_missing_image_error(exc):
                raise
            immutable_image = _resolve_registry_digest(
                docker_client,
                manifest.source_image,
                attempts=pull_attempts,
                username=source_registry_username,
                password=source_registry_password,
            )
            environment = _registry_image_environment(
                immutable_image, attempts=pull_attempts,
                username=source_registry_username,
                password=source_registry_password,
            )
            resolved = _replace_image_metadata(
                manifest, immutable_image, environment,
            )
            return _replace_runtime_artifacts(resolved, ()), {}, False

    image = _get_or_pull_image(
        docker_client,
        manifest.source_image,
        attempts=pull_attempts,
        username=source_registry_username,
        password=source_registry_password,
    )
    immutable_source = _matching_repo_digest(image, manifest.source_image)
    used_portable_image = force_portable
    if used_portable_image:
        if not portable_registry:
            raise AptSourceError(
                f"Source image {manifest.source_image!r} requires APT source "
                "normalization. Pass --portable-registry to publish a portable "
                "derivative before building the E2B Template."
            )
        portable_ref = _portable_image_ref(
            portable_registry,
            manifest.image_key,
            immutable_source.split("@", 1)[1],
        )
        immutable_image = _optional_registry_digest(
            docker_client,
            portable_ref,
            attempts=pull_attempts,
            username=portable_registry_username,
            password=portable_registry_password,
        )
        if immutable_image is None:
            image, immutable_image = _build_and_push_portable_image(
                docker_client,
                image,
                manifest.source_image,
                portable_ref,
                context_dir,
                username=portable_registry_username,
                password=portable_registry_password,
            )
        else:
            # The Registry manifest is authoritative. A tag may still exist in
            # the local Docker cache after its remote manifest was deleted, so
            # never derive an E2B source digest from the local tag alone.
            image = _get_or_pull_image(
                docker_client,
                immutable_image,
                attempts=pull_attempts,
                username=portable_registry_username,
                password=portable_registry_password,
            )
    else:
        immutable_image = immutable_source
    manifest = _replace_image_metadata(
        manifest, immutable_image, _image_environment(image),
    )
    if not manifest.snapshot_roots:
        return _replace_runtime_artifacts(manifest, ()), {}, used_portable_image

    container = docker_client.containers.create(manifest.source_image)
    try:
        artifacts, sources = _capture_tmp_snapshot(container, context_dir)
    finally:
        container.remove(force=True)
    return (
        _replace_runtime_artifacts(manifest, artifacts),
        sources,
        used_portable_image,
    )


def _registry_auth(
    username: str | None,
    password: str | None,
) -> dict[str, dict[str, str]]:
    if not username and not password:
        return {}
    if not username or not password:
        raise ValueError("Both registry username and password are required")
    return {"auth_config": {"username": username, "password": password}}


def _get_or_pull_image(
    docker_client,
    image_ref: str,
    *,
    attempts: int = 3,
    username: str | None = None,
    password: str | None = None,
):
    """Resolve an image locally, retrying transient registry failures."""
    try:
        return docker_client.images.get(image_ref)
    except Exception as exc:
        if not _is_missing_image_error(exc):
            raise

    attempts = max(1, attempts)
    auth = _registry_auth(username, password)
    error = None
    for attempt in range(1, attempts + 1):
        try:
            return docker_client.images.pull(image_ref, **auth)
        except Exception as exc:
            error = exc
            # A failed pull can still leave a complete image in the daemon.
            try:
                return docker_client.images.get(image_ref)
            except Exception as lookup_exc:
                if not _is_missing_image_error(lookup_exc):
                    raise
            if attempt < attempts:
                time.sleep(min(2 ** (attempt - 1), 8))
    raise RuntimeError(
        f"Failed to pull source image {image_ref!r} after {attempts} attempts: {error}"
    ) from error


def _resolve_registry_digest(
    docker_client,
    image_ref: str,
    *,
    attempts: int = 3,
    username: str | None = None,
    password: str | None = None,
) -> str:
    """Resolve an immutable registry digest without downloading layers."""
    attempts = max(1, attempts)
    auth = _registry_auth(username, password)
    error = None
    for attempt in range(1, attempts + 1):
        try:
            data = docker_client.images.get_registry_data(image_ref, **auth)
            digest = data.id
            if not digest.startswith("sha256:"):
                raise ValueError(
                    f"Registry returned an invalid digest for {image_ref!r}: {digest!r}"
                )
            repository, separator, _ = image_ref.rpartition(":")
            if not separator:
                repository = image_ref
            return f"{repository}@{digest}"
        except Exception as exc:
            error = exc
            if attempt < attempts:
                time.sleep(min(2 ** (attempt - 1), 8))
    raise RuntimeError(
        f"Failed to resolve source image {image_ref!r} after {attempts} "
        f"attempts: {error}"
    ) from error


def _optional_registry_digest(
    docker_client,
    image_ref: str,
    *,
    attempts: int = 3,
    username: str | None = None,
    password: str | None = None,
) -> str | None:
    """Resolve a remote image digest, returning None only for NotFound.

    A local Docker tag is not proof that the corresponding remote manifest
    still exists. Authentication and transport failures remain hard errors so
    they cannot silently trigger a rebuild or overwrite an inaccessible tag.
    """
    attempts = max(1, attempts)
    auth = _registry_auth(username, password)
    for attempt in range(1, attempts + 1):
        try:
            data = docker_client.images.get_registry_data(image_ref, **auth)
            digest = data.id
            if not digest.startswith("sha256:"):
                raise ValueError(
                    f"Registry returned an invalid digest for {image_ref!r}: "
                    f"{digest!r}"
                )
            repository, separator, _ = image_ref.rpartition(":")
            if not separator:
                repository = image_ref
            return f"{repository}@{digest}"
        except Exception as exc:
            if _is_missing_image_error(exc):
                return None
            if attempt == attempts:
                raise RuntimeError(
                    f"Failed to inspect portable image {image_ref!r} after "
                    f"{attempts} attempts: {exc}"
                ) from exc
            time.sleep(min(2 ** (attempt - 1), 8))
    return None


def _portable_image_ref(
    portable_registry: str,
    image_key: str,
    source_digest: str,
) -> str:
    repo, sep, tag = image_key.rpartition(":")
    if not sep:
        raise ValueError(f"Image key has no immutable tag: {image_key!r}")
    digest_suffix = source_digest.removeprefix("sha256:")[:12]
    if not digest_suffix:
        raise ValueError("Source image digest is required for a portable image")
    return (
        f"{portable_registry.rstrip('/')}/{repo}:"
        f"{tag}-{digest_suffix}-e2b-v{PORTABLE_IMAGE_RECIPE_VERSION}"
    )


def _matching_repo_digest(image, image_ref: str) -> str:
    repo_digests = image.attrs.get("RepoDigests") or []
    source_repo, separator, _ = image_ref.rpartition(":")
    if not separator:
        source_repo = image_ref
    matching = [
        item
        for item in repo_digests
        if "@" in item and item.split("@", 1)[0] == source_repo
    ]
    if not matching:
        raise ValueError(
            f"Source image {image_ref!r} has no matching registry digest "
            f"(available: {repo_digests}); push it to that registry before "
            "building an E2B Template"
        )
    return matching[0]


def _portable_apt_sources_command() -> str:
    """Return a distro-aware command that restores public APT sources."""
    debian_components = "main"
    ubuntu_components = "main universe"
    debian_sources = " ".join(
        (
            f'"deb http://deb.debian.org/debian $codename {debian_components}"',
            f'"deb http://deb.debian.org/debian $codename-updates {debian_components}"',
            f'"deb http://security.debian.org/debian-security '
            f'$codename-security {debian_components}"',
        )
    )
    ubuntu_sources = " ".join(
        (
            f'"deb http://archive.ubuntu.com/ubuntu $codename {ubuntu_components}"',
            f'"deb http://archive.ubuntu.com/ubuntu $codename-updates '
            f'{ubuntu_components}"',
            f'"deb http://security.ubuntu.com/ubuntu $codename-security '
            f'{ubuntu_components}"',
        )
    )
    return (
        "set -eu; . /etc/os-release; "
        "codename=${VERSION_CODENAME:-${UBUNTU_CODENAME:-}}; "
        'test -n "$codename"; '
        "rm -f /etc/apt/sources.list; "
        "rm -rf /etc/apt/sources.list.d; "
        "mkdir -p /etc/apt/sources.list.d; "
        'case "$ID" in '
        f"debian) printf '%s\\n' {debian_sources} "
        "> /etc/apt/sources.list ;; "
        f"ubuntu) printf '%s\\n' {ubuntu_sources} "
        "> /etc/apt/sources.list ;; "
        '*) echo "Unsupported APT distribution: $ID" >&2; exit 1 ;; '
        "esac"
    )


def _build_and_push_portable_image(
    docker_client,
    source_image,
    source_ref: str,
    portable_ref: str,
    context_dir: Path,
    *,
    username: str | None = None,
    password: str | None = None,
) -> tuple[object, str]:
    """Publish a source-equivalent image with public APT sources.

    E2B provisions its own packages before user Template instructions run, so
    source-list repair must already be present in the imported image.
    """
    immutable_source = _matching_repo_digest(source_image, source_ref)
    config = source_image.attrs.get("Config") or {}
    original_user = config.get("User") or ""
    original_workdir = config.get("WorkingDir") or "/"
    dockerfile = [
        f"FROM {immutable_source}",
        "USER root",
        "RUN " + _portable_apt_sources_command(),
    ]
    if original_user:
        dockerfile.append(f"USER {original_user}")
    dockerfile.append(f"WORKDIR {original_workdir}")
    dockerfile_path = context_dir / "Portable.Dockerfile"
    dockerfile_path.write_text("\n".join(dockerfile) + "\n")

    image, logs = docker_client.images.build(
        path=str(context_dir),
        dockerfile=dockerfile_path.name,
        tag=portable_ref,
        rm=True,
        forcerm=True,
    )
    for item in logs:
        if item.get("error") or item.get("errorDetail"):
            raise RuntimeError(
                f"Failed to build portable source image {portable_ref!r}: "
                f"{item.get('error') or item['errorDetail'].get('message')}"
            )

    repository, tag = portable_ref.rsplit(":", 1)
    pushed_digest = None
    push_kwargs = {
        "tag": tag,
        "stream": True,
        "decode": True,
        **_registry_auth(username, password),
    }
    for item in docker_client.images.push(repository, **push_kwargs):
        if item.get("error") or item.get("errorDetail"):
            raise RuntimeError(
                f"Failed to push portable source image {portable_ref!r}: "
                f"{item.get('error') or item['errorDetail'].get('message')}"
            )
        pushed_digest = (item.get("aux") or {}).get("Digest") or pushed_digest
    image.reload()
    immutable_portable = (
        f"{repository}@{pushed_digest}"
        if pushed_digest
        else _matching_repo_digest(image, portable_ref)
    )
    return image, immutable_portable


def build_template_definition(
    manifest: TemplateManifest,
    template_cls,
    *,
    registry_username: str | None = None,
    registry_password: str | None = None,
    context_dir: Path | None = None,
    runtime_sources: dict[str, str] | None = None,
):
    template = (
        template_cls(file_context_path=context_dir) if context_dir else template_cls()
    )
    auth = {}
    if registry_username or registry_password:
        if not registry_username or not registry_password:
            raise ValueError("Both registry username and password are required")
        auth = {
            "username": registry_username,
            "password": registry_password,
        }
    builder = template.from_image(manifest.source_image, **auth)
    environment = dict(manifest.environment)
    if environment:
        builder = builder.set_envs(environment)
        builder = builder.run_cmd(
            _environment_profile_command(manifest.environment), user="root",
        )
    runtime_sources = runtime_sources or {}
    for item in manifest.runtime_artifacts:
        source = runtime_sources.get(item.source)
        if source is None:
            raise ValueError(
                f"Runtime artifact {item.source!r} was not staged from the image"
            )
        builder = builder.copy(
            source,
            item.persistent,
            user="root",
            force_upload=True,
        )
    if manifest.runtime_artifacts:
        # The copies above land root-owned, but the Sandbox start command runs
        # as manifest.user (agent for work). A non-root user cannot `cp -a` a
        # root-owned directory back into /tmp (preserving times/ownership is
        # denied), so hand the staged tree to the run user. Modes are preserved,
        # so the restored files keep the image's permissions; only ownership
        # normalizes to the run identity, which is exactly who reads them.
        builder = builder.run_cmd(
            f"chown -R {shlex.quote(manifest.user)}:{shlex.quote(manifest.user)} "
            f"{shlex.quote(_TMP_SNAPSHOT_PERSISTENT)}",
            user="root",
        )
    if manifest.role == "work":
        # Match the Docker work-image contract. Imported images can preserve
        # root-owned subdirectories even when their default user is `agent`.
        builder = builder.run_cmd(
            f"chown -R agent:agent {shlex.quote(manifest.workdir)} && "
            f"chmod -R u+rwX {shlex.quote(manifest.workdir)}",
            user="root",
        )
    builder = builder.set_user(manifest.user).set_workdir(manifest.workdir)
    restore = _restore_command(manifest)
    if restore:
        ready = " && ".join(
            f"test -e {shlex.quote(item.source)}" for item in manifest.runtime_artifacts
        )
        builder = builder.set_start_cmd(restore, ready)
    return builder


def _matching_build_id(
    template_cls, name: str, tag: str, fingerprint_tag: str
) -> str | None:
    """Return the build shared by the image and manifest aliases."""
    try:
        if not template_cls.exists(f"{name}:{tag}"):
            return None
        if not template_cls.exists(f"{name}:{fingerprint_tag}"):
            return None
        tags = template_cls.get_tags(name)
    except Exception as exc:
        raise RuntimeError(
            f"Could not inspect E2B Template aliases for {name!r}: {exc}"
        ) from exc
    builds = {item.tag: item.build_id for item in tags}
    image_build = builds.get(tag)
    manifest_build = builds.get(fingerprint_tag)
    if not image_build or image_build != manifest_build:
        return None
    return image_build


def _is_retryable_build_error(exc: Exception) -> bool:
    text = " ".join(
        str(item).lower()
        for item in (exc, getattr(exc, "__cause__", None))
        if item is not None
    )
    deterministic = (
        "provisioning output",
        "could not resolve",
        "no installation candidate",
    )
    if any(marker in text for marker in deterministic):
        return False
    transient = (
        "timeout",
        "timed out",
        "connection",
        "eof",
        "tls",
        "temporarily unavailable",
        "internal error",
        "502",
        "503",
        "504",
    )
    return any(marker in text for marker in transient)


def _is_apt_source_error(message: str) -> bool:
    """Recognize E2B provisioning failures caused by unreachable APT repos."""
    lowered = message.lower()
    return "provisioning output" in lowered and any(
        marker in lowered
        for marker in (
            "apt",
            "could not resolve",
            "temporary failure resolving",
            "no installation candidate",
        )
    )


def _build_failure_message(status) -> str:
    reason = getattr(status, "reason", None)
    parts = []
    message = getattr(reason, "message", None)
    if message:
        parts.append(message)
    for entry in getattr(reason, "log_entries", None) or []:
        text = getattr(entry, "message", None)
        if text:
            parts.append(text)
    parts.extend(str(item) for item in (getattr(status, "logs", None) or []))
    return "\n".join(parts)[-12000:] or "Build failed"


def build_e2b_template(
    manifest: TemplateManifest,
    *,
    template_cls=None,
    attempts: int = 3,
    build_timeout: int = 600,
    force: bool = False,
    on_build_logs=None,
    registry_username: str | None = None,
    registry_password: str | None = None,
    context_dir: Path | None = None,
    runtime_sources: dict[str, str] | None = None,
):
    """Build idempotently, reconciling ambiguous API failures by tag."""
    if attempts <= 0:
        raise ValueError("Template build attempts must be greater than zero")
    if build_timeout <= 0:
        raise ValueError("Template build timeout must be greater than zero")
    if template_cls is None:
        from e2b import Template as template_cls
    fingerprint_tag = f"sforge-{manifest.fingerprint[:12]}"
    previous_ready_build = _matching_build_id(
        template_cls,
        manifest.name,
        manifest.tag,
        fingerprint_tag,
    )
    if previous_ready_build and not force:
        return {"status": "existing", "build_id": previous_ready_build}
    definition = build_template_definition(
        manifest,
        template_cls,
        registry_username=registry_username,
        registry_password=registry_password,
        context_dir=context_dir,
        runtime_sources=runtime_sources,
    )
    error = None
    used_attempts = 0
    for attempt in range(1, attempts + 1):
        used_attempts = attempt
        try:
            info = template_cls.build_in_background(
                definition,
                manifest.name,
                tags=[manifest.tag, fingerprint_tag],
                cpu_count=manifest.cpu_count,
                memory_mb=manifest.memory_mb,
                skip_cache=force,
                on_build_logs=on_build_logs,
            )
        except Exception as exc:
            if _is_apt_source_error(str(exc)):
                raise AptSourceError(str(exc)) from exc
            error = exc
            accepted = _matching_build_id(
                template_cls,
                manifest.name,
                manifest.tag,
                fingerprint_tag,
            )
            if accepted and accepted != previous_ready_build:
                return {"status": "reconciled", "build_id": accepted}
            if attempt < attempts and _is_retryable_build_error(exc):
                time.sleep(min(2 ** (attempt - 1), 8))
                continue
            break

        deadline = time.monotonic() + build_timeout
        logs_offset = 0
        last_status_error = None
        while time.monotonic() < deadline:
            try:
                status = template_cls.get_build_status(
                    info,
                    logs_offset=logs_offset,
                )
                last_status_error = None
            except Exception as exc:
                last_status_error = exc
                if not _is_retryable_build_error(exc):
                    raise RuntimeError(
                        f"Could not inspect E2B template build "
                        f"{info.template_id}/{info.build_id}: {exc}"
                    ) from exc
                time.sleep(1)
                continue
            logs_offset += len(status.log_entries)
            if on_build_logs is not None:
                for entry in status.log_entries:
                    on_build_logs(entry)
            state = getattr(status.status, "value", status.status)
            if state == "ready":
                return {
                    "status": "built",
                    "template_id": info.template_id,
                    "build_id": info.build_id,
                }
            if state == "error":
                message = _build_failure_message(status)
                if _is_apt_source_error(message):
                    raise AptSourceError(message)
                error = RuntimeError(message)
                accepted = _matching_build_id(
                    template_cls, manifest.name, manifest.tag, fingerprint_tag,
                )
                if accepted and accepted != previous_ready_build:
                    return {"status": "reconciled", "build_id": accepted}
                if attempt < attempts and _is_retryable_build_error(error):
                    time.sleep(min(2 ** (attempt - 1), 8))
                    break
                raise error
            time.sleep(1)
        else:
            accepted = _matching_build_id(
                template_cls,
                manifest.name,
                manifest.tag,
                fingerprint_tag,
            )
            if accepted == info.build_id:
                return {"status": "reconciled", "build_id": accepted}
            detail = (
                f": last status error: {last_status_error}"
                if last_status_error else ""
            )
            raise TimeoutError(
                f"E2B template build timed out after {build_timeout}s "
                f"(template_id={info.template_id}, build_id={info.build_id}); "
                f"the E2B SDK has no per-build cancellation API{detail}"
            )
    raise RuntimeError(
        f"Failed to build E2B template {manifest.reference!r} after "
        f"{used_attempts} attempts: {error}"
    ) from error


def write_template_manifest(
    manifest: TemplateManifest,
    result: dict,
    output_dir: Path,
) -> Path:
    output_dir.mkdir(parents=True, exist_ok=True)
    path = output_dir / f"{manifest.role}.json"
    path.write_text(
        json.dumps(
            {**manifest.to_dict(), "result": result},
            indent=2,
            ensure_ascii=False,
        )
    )
    return path
