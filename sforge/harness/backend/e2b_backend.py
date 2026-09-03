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

"""E2B backend: runs work/judge containers on official E2B.

Targets native E2B semantics (https://e2b.dev):

- endpoint/credentials via the standard e2b env vars
  (``E2B_API_KEY``, ``E2B_API_URL`` / ``E2B_DOMAIN``);
- public Template namespace via ``SFORGE_E2B_TEMPLATE_NAMESPACE`` and optional
  image-key overrides via ``SFORGE_E2B_TEMPLATE_MAP``
  (see :meth:`E2BBackend.resolve_template`).

Semantics notes vs the docker backend:

- Commands run through the sandbox's envd daemon via ``/bin/bash -l -c``,
  so string commands get full shell interpretation (docker exec splits
  them into argv without a shell). All harness call sites are compatible.
- ``copy_from_container`` preserves the docker contract of returning a
  tar archive containing the file.
- stdout/stderr arrive as separate streams; chunks are interleaved in
  arrival order, which is close to but not guaranteed identical to the
  container's write order.
- cpu/mem limits and cap_drop are template-level concepts in e2b and are
  ignored at container creation (logged once).
"""

from __future__ import annotations

import io
import json
import logging
import os
import re
import shlex
import tarfile
import threading
import time
import uuid
from collections.abc import Callable
from pathlib import Path, PurePosixPath

from sforge.harness.backend.base import (
    ContainerBackend,
    ContainerHandle,
    ExecResult,
    NetworkIsolationStrategy,
    ServiceEndpoint,
    StreamingExecResult,
)

logger = logging.getLogger(__name__)

# Sandbox lifetime lease. The renewal thread extends every live sandbox back
# to the full TTL at TTL/3 intervals, so a crashed harness leaks a sandbox for
# at most one TTL.
DEFAULT_SANDBOX_TTL = 3600

# Upper bound for the blocking, non-streaming exec_run path. The interface
# carries no per-call timeout there and every caller only runs short
# housekeeping commands (chmod, mkdir, tar list/extract, chown, kill), so a
# generous ceiling turns a hung remote stream into a failure instead of a
# forever-block. The streaming exec paths manage their own deadlines and the
# detached path stays unbounded on purpose so background servers keep running.
DEFAULT_EXEC_TIMEOUT = 600

# Files API calls are idempotent at the paths used by the harness. Uploads use
# a bounded request deadline; downloads stream so progress can continue for
# large archives while the SDK still aborts an idle stream. Retry transient
# transport failures, but surface deterministic provider errors immediately.
FILE_TRANSFER_ATTEMPTS = 3
FILE_TRANSFER_REQUEST_TIMEOUT = 300
SANDBOX_CREATE_ATTEMPTS = 3
SANDBOX_CLEANUP_ATTEMPTS = 3
SANDBOX_LIFECYCLE_REQUEST_TIMEOUT = 10
SANDBOX_CLEANUP_GRACE_PERIOD = 60

_METADATA_NAME_KEY = "sforge_name"
_E2B_NAME_PATTERN = re.compile(r"[a-z0-9_-]{1,128}")


class E2BSandboxHandle(ContainerHandle):
    """Wraps an e2b Sandbox object."""

    def __init__(
        self,
        sandbox,
        name: str,
        default_user: str | None = None,
    ) -> None:
        self._sandbox = sandbox
        self._name = name
        self.default_user = default_user
        self._lease_lock = threading.Lock()
        self._closing = False

    @property
    def id(self) -> str:
        return self._sandbox.sandbox_id

    @property
    def name(self) -> str:
        return self._name

    @property
    def ip_address(self) -> str | None:
        return None

    @property
    def raw(self):
        return self._sandbox


class E2BNetworkIsolation(NetworkIsolationStrategy):
    """Egress whitelist via the e2b network API.

    Translates the harness's ``AllowedEndpoint`` list into
    ``update_network(allow_out=<hosts>, deny_out=[0.0.0.0/0])`` on the running
    sandbox. Allow rules take precedence over deny in e2b, which gives exactly
    the whitelist-plus-default-drop semantics supported by the official API.
    Port granularity is not supported by e2b selectors: allowing an endpoint
    allows all ports on that host.
    """

    def __init__(self, sandbox, allowed_endpoints: list, log: logging.Logger) -> None:
        self._sandbox = sandbox
        self._endpoints = allowed_endpoints
        self._logger = log

    def apply(self) -> None:
        hosts: list[str] = []
        for ep in self._endpoints:
            host = getattr(ep, "hostname", None) or getattr(ep, "ip", None)
            if host and host not in hosts:
                hosts.append(host)
        try:
            self._sandbox.update_network(
                {"allow_out": hosts, "deny_out": ["0.0.0.0/0"]}
            )
        except Exception as exc:
            raise RuntimeError(
                "e2b network isolation failed: the provider rejected "
                f"update_network ({exc}). Run with --enable-internet to skip "
                "isolation, or use an internet-enabled template."
            ) from exc
        self._logger.info(
            "e2b network isolation applied: allow=%s deny=all (host-level, "
            "ports are not filtered)",
            hosts,
        )

    def cleanup(self) -> None:
        # E2B Sandboxes are never reused. Keep the deny rules in place until
        # deletion so a transient kill failure cannot leave an unrestricted
        # workload alive for the remainder of its TTL.
        return None


class E2BBackend(ContainerBackend):
    """Container backend for the official E2B Sandbox API."""

    def __init__(
        self,
        template_map: dict[str, str] | None = None,
        sandbox_ttl: int | None = None,
        *,
        template_namespace: str | None = None,
        sandbox_cls=None,
        template_cls=None,
    ) -> None:
        if sandbox_cls is None:
            try:
                from e2b import Sandbox as sandbox_cls
            except ImportError as exc:
                raise RuntimeError(
                    "The e2b backend requires the 'e2b' package. "
                    "Install with: uv sync --extra e2b (or pip install e2b)"
                ) from exc
        self._sandbox_cls = sandbox_cls
        if template_cls is None:
            try:
                from e2b import Template as template_cls
            except ImportError:
                template_cls = None
        self._template_cls = template_cls
        self._template_map = (
            dict(template_map) if template_map else template_map_from_env()
        )
        self._template_namespace = (
            template_namespace
            if template_namespace is not None
            else os.environ.get("SFORGE_E2B_TEMPLATE_NAMESPACE", "")
        ).strip() or None
        if (
            self._template_namespace is not None
            and not _E2B_NAME_PATTERN.fullmatch(self._template_namespace)
        ):
            raise ValueError(
                "E2B Template namespace must contain only lowercase letters, "
                "numbers, dashes, and underscores, and be at most 128 characters"
            )
        self._sandbox_ttl = (
            int(os.environ.get("SFORGE_E2B_SANDBOX_TTL", DEFAULT_SANDBOX_TTL))
            if sandbox_ttl is None
            else sandbox_ttl
        )
        if self._sandbox_ttl <= 0:
            raise ValueError("E2B Sandbox TTL must be greater than zero")
        self._handles: dict[str, E2BSandboxHandle] = {}
        self._handles_lock = threading.Lock()
        self._renewal_thread: threading.Thread | None = None
        self._renewal_wakeup = threading.Event()
        self._warned_limits = False

    @property
    def backend_name(self) -> str:
        return "e2b"

    # --- Template resolution ---

    def resolve_template(self, image_key: str) -> str:
        """Map an image key to an e2b template reference.

        Explicit entries in ``SFORGE_E2B_TEMPLATE_MAP`` win (matched with and
        without the image tag); otherwise the repo part is normalized to the
        template-name charset, the image tag carries over as the Template tag,
        and ``SFORGE_E2B_TEMPLATE_NAMESPACE`` is prepended when configured
        (``edgebench.work.foo_bar:abc123`` ->
        ``edgebench/edgebench-work-foo-bar:abc123``).
        """
        if image_key in self._template_map:
            return self._template_map[image_key]
        repo, sep, tag = image_key.partition(":")
        if repo in self._template_map:
            return self._template_map[repo] + sep + tag
        return e2b_template_reference(image_key, self._template_namespace)

    # --- Lifecycle ---

    def create_container(
        self,
        image: str,
        name: str,
        *,
        command: str = "tail -f /dev/null",
        environment: dict[str, str] | None = None,
        extra_hosts: dict[str, str] | None = None,
        cap_drop: list[str] | None = None,
        cpu_limit: int | None = None,
        mem_limit: str | None = None,
        user: str | None = None,
        annotations: dict[str, str] | None = None,
    ) -> E2BSandboxHandle:
        if (cpu_limit or mem_limit or cap_drop) and not self._warned_limits:
            self._warned_limits = True
            logger.warning(
                "e2b backend: cpu/mem limits and cap_drop are fixed at "
                "template build time; per-container values are ignored"
            )

        template = self.resolve_template(image)
        envs = {k: str(v) for k, v in (environment or {}).items() if v is not None}
        metadata = {str(key): str(value) for key, value in (annotations or {}).items()}
        metadata[_METADATA_NAME_KEY] = name
        create_kwargs = {
            "template": template,
            "envs": envs,
            "metadata": metadata,
            "timeout": self._sandbox_ttl,
            "secure": True,
            "network": {"allow_public_traffic": False},
            "lifecycle": {"on_timeout": "kill"},
        }
        sandbox = self._create_sandbox(name, create_kwargs)
        handle = E2BSandboxHandle(sandbox, name, default_user=user)
        with self._handles_lock:
            self._handles[handle.id] = handle
            self._ensure_renewal_thread()
        try:
            # host.docker.internal has no meaning outside the docker backend and
            # would shadow real DNS if written into /etc/hosts.
            hosts = {
                h: ip
                for h, ip in (extra_hosts or {}).items()
                if h != "host.docker.internal" and ip != "host-gateway"
            }
            if hosts:
                lines = "".join(f"{ip} {h}\\n" for h, ip in hosts.items())
                sandbox.commands.run(
                    f"printf %s {shlex.quote(lines)} >> /etc/hosts",
                    user="root",
                    timeout=30,
                )

            if command and command != "tail -f /dev/null":
                sandbox.commands.run(
                    command,
                    background=True,
                    user=user,
                    timeout=0,
                    envs=envs or None,
                )
        except BaseException:
            try:
                self.cleanup_container(handle, logger)
            except Exception:
                logger.exception(
                    "Failed to clean up E2B Sandbox %s after initialization error",
                    handle.id,
                )
            raise
        return handle

    def _create_sandbox(self, name: str, create_kwargs: dict):
        """Create a Sandbox, reconciling an ambiguous API timeout by name.

        A create request may reach E2B even when the client times out before
        receiving its response. The unique SForge name in metadata lets us
        reconnect to that Sandbox instead of leaking it and creating another.
        """
        error = None
        for attempt in range(1, SANDBOX_CREATE_ATTEMPTS + 1):
            try:
                return self._sandbox_cls.create(**create_kwargs)
            except Exception as exc:
                error = exc
                if not _is_retryable_transport_error(exc):
                    raise
                try:
                    matches = list(self._iter_sandboxes_by_name(name))
                except RuntimeError as lookup_exc:
                    logger.warning(
                        "Could not reconcile timed-out E2B Sandbox creation "
                        "for %s (attempt %d/%d): %s",
                        name, attempt, SANDBOX_CREATE_ATTEMPTS, lookup_exc,
                    )
                else:
                    if matches:
                        sandbox_id = matches[0].sandbox_id
                        logger.warning(
                            "E2B Sandbox creation response was lost; "
                            "reconnecting to %s (%s)", name, sandbox_id,
                        )
                        return self._sandbox_cls.connect(
                            sandbox_id, timeout=self._sandbox_ttl,
                        )
                if attempt < SANDBOX_CREATE_ATTEMPTS:
                    logger.warning(
                        "E2B Sandbox creation failed for %s "
                        "(attempt %d/%d): %s",
                        name, attempt, SANDBOX_CREATE_ATTEMPTS, exc,
                    )
                    time.sleep(attempt)
        raise RuntimeError(
            f"Failed to create E2B Sandbox {name!r} after "
            f"{SANDBOX_CREATE_ATTEMPTS} attempts: {error}"
        ) from error

    def start_container(self, handle: ContainerHandle) -> None:
        self._raw(handle)
        # E2B Sandboxes are running as soon as create() returns.

    def cleanup_container(
        self,
        handle: ContainerHandle | None,
        logger_: logging.Logger | None = None,
    ) -> None:
        if handle is None:
            return
        log = logger_ or logger
        sandbox = self._raw(handle)
        # Cleanup is a terminal lease transition, independent of the runtime
        # TTL selected by the user. Remove the handle from lease renewal first,
        # then shorten its provider-side deadline before attempting deletion.
        # If E2B temporarily rejects kill(), on_timeout=kill still reclaims the
        # Sandbox within the cleanup grace period.
        with self._handles_lock:
            self._handles.pop(handle.id, None)
            self._renewal_wakeup.set()
        cleanup_deadline_armed = False
        cleanup_timeout = min(
            self._sandbox_ttl, SANDBOX_CLEANUP_GRACE_PERIOD,
        )
        with handle._lease_lock:
            handle._closing = True
            for attempt in range(1, SANDBOX_CLEANUP_ATTEMPTS + 1):
                try:
                    sandbox.set_timeout(
                        cleanup_timeout,
                        request_timeout=SANDBOX_LIFECYCLE_REQUEST_TIMEOUT,
                    )
                    cleanup_deadline_armed = True
                    break
                except Exception as exc:
                    if attempt == SANDBOX_CLEANUP_ATTEMPTS:
                        log.warning(
                            "Could not shorten sandbox %s cleanup deadline "
                            "after %d attempts: %s",
                            handle.id, attempt, exc,
                        )
                    else:
                        time.sleep(attempt)
        log.info(f"Killing sandbox {handle.name} ({handle.id})...")
        for attempt in range(1, SANDBOX_CLEANUP_ATTEMPTS + 1):
            try:
                killed = sandbox.kill(
                    request_timeout=SANDBOX_LIFECYCLE_REQUEST_TIMEOUT,
                )
                if killed:
                    log.info(f"Sandbox {handle.name} killed.")
                else:
                    log.info(f"Sandbox {handle.name} was already gone.")
                return
            except Exception as exc:
                if attempt == SANDBOX_CLEANUP_ATTEMPTS:
                    if cleanup_deadline_armed:
                        log.warning(
                            "Failed to kill sandbox %s after %d attempts; "
                            "E2B will reclaim it within %ds: %s",
                            handle.id, attempt,
                            cleanup_timeout, exc,
                        )
                    else:
                        message = (
                            "Failed to arm cleanup deadline and kill sandbox "
                            "%s after %d attempts; original TTL remains the "
                            "only safeguard: %s"
                        ) % (handle.id, attempt, exc)
                        log.error(message)
                        raise RuntimeError(message) from exc
                    return
                time.sleep(attempt)

    def container_exists(self, name: str) -> bool:
        return any(True for _ in self._iter_sandboxes_by_name(name))

    def remove_container_by_name(self, name: str) -> None:
        for info in self._iter_sandboxes_by_name(name):
            for attempt in range(1, 4):
                try:
                    self._sandbox_cls.kill(info.sandbox_id)
                    with self._handles_lock:
                        self._handles.pop(info.sandbox_id, None)
                        self._renewal_wakeup.set()
                    break
                except Exception as exc:
                    if attempt == 3:
                        raise RuntimeError(
                            f"Failed to remove stale E2B Sandbox "
                            f"{info.sandbox_id}: {exc}"
                        ) from exc
                    time.sleep(attempt)

    def _iter_sandboxes_by_name(self, name: str):
        from e2b import SandboxQuery  # local: keeps module import-light

        query = SandboxQuery(metadata={_METADATA_NAME_KEY: name})
        try:
            paginator = self._sandbox_cls.list(query=query)
            while paginator.has_next:
                for info in paginator.next_items():
                    if (info.metadata or {}).get(_METADATA_NAME_KEY) == name:
                        yield info
        except Exception as exc:
            raise RuntimeError(
                f"Could not list E2B Sandboxes named {name!r}: {exc}"
            ) from exc

    # --- Image ---

    def image_exists(self, image_key: str) -> bool:
        if self._template_cls is None:
            return False
        template = self.resolve_template(image_key)
        if _is_namespaced_template_reference(template):
            logger.debug(
                "E2B cannot preflight public Template %r across namespaces; "
                "deferring validation to Sandbox.create()",
                template,
            )
            return True
        try:
            # Check the complete name:tag alias. Sandbox.create remains the
            # authoritative launchability check performed later in the flow.
            return bool(self._template_cls.exists(template))
        except Exception as exc:
            raise RuntimeError(
                f"Could not verify E2B template {template!r}: {exc}"
            ) from exc

    # --- File transfer ---

    def copy_to_container(
        self,
        handle: ContainerHandle,
        src: Path,
        dst: PurePosixPath,
    ) -> None:
        if str(dst.parent) == ".":
            raise ValueError(f"Destination parent directory cannot be empty: {dst}")
        sandbox = self._raw(handle)
        # Harness file transfers include privileged destinations such as
        # /usr/local/bin and /etc. Match the effective daemon-level behavior
        # of Docker's put_archive by writing as root; callers set ownership
        # explicitly when a user-owned destination requires it.
        run_user = "root"
        sandbox.commands.run(
            f"mkdir -p {shlex.quote(str(dst.parent))}",
            user=run_user,
            timeout=60,
        )

        if src.is_dir():
            buf = io.BytesIO()
            with tarfile.open(fileobj=buf, mode="w") as tar:
                tar.add(src, arcname=dst.name)
            tmp = f"/tmp/.sforge-copy-{uuid.uuid4().hex}.tar"
            self._retry_file_transfer(
                f"upload {src}",
                lambda: sandbox.files.write(
                    tmp, buf.getvalue(), user=run_user,
                    request_timeout=FILE_TRANSFER_REQUEST_TIMEOUT,
                ),
            )
            sandbox.commands.run(
                f"tar xf {tmp} -C {shlex.quote(str(dst.parent))}; "
                f"status=$?; rm -f {tmp}; exit $status",
                user=run_user,
                timeout=300,
            )
        else:
            data = src.read_bytes()
            self._retry_file_transfer(
                f"upload {src}",
                lambda: sandbox.files.write(
                    str(dst), data, user=run_user,
                    request_timeout=FILE_TRANSFER_REQUEST_TIMEOUT,
                ),
            )

    def copy_from_container(
        self,
        handle: ContainerHandle,
        src: PurePosixPath,
        *,
        shutdown_event: threading.Event | None = None,
    ) -> bytes:
        sandbox = self._raw(handle)
        archive = f"/tmp/.sforge-download-{uuid.uuid4().hex}.tar"
        command = (
            f"tar cf {shlex.quote(archive)} "
            f"-C {shlex.quote(str(src.parent))} {shlex.quote(src.name)}"
        )
        try:
            result = sandbox.commands.run(command, user="root", timeout=300)
            if result.exit_code != 0:
                raise RuntimeError(
                    f"Failed to archive {src}: {result.stderr or result.stdout}"
                )
            def download() -> bytes:
                if shutdown_event is not None and shutdown_event.is_set():
                    raise InterruptedError(f"Download of {src} was cancelled")
                reader = sandbox.files.read(
                    archive, format="stream", user="root",
                )
                try:
                    chunks = []
                    for chunk in reader:
                        if (
                            shutdown_event is not None
                            and shutdown_event.is_set()
                        ):
                            raise InterruptedError(
                                f"Download of {src} was cancelled"
                            )
                        chunks.append(chunk)
                    return b"".join(chunks)
                finally:
                    close = getattr(reader, "close", None)
                    if close is not None:
                        close()

            return self._retry_file_transfer(f"download {src}", download)
        finally:
            try:
                sandbox.files.remove(archive, user="root")
            except Exception:
                logger.debug(
                    "Could not remove E2B download archive %s",
                    archive,
                    exc_info=True,
                )

    def write_to_container(
        self,
        handle: ContainerHandle,
        data: str,
        dst: PurePosixPath,
    ) -> None:
        sandbox = self._raw(handle)
        self._retry_file_transfer(
            f"write {dst}",
            lambda: sandbox.files.write(
                str(dst), data, user="root",
                request_timeout=FILE_TRANSFER_REQUEST_TIMEOUT,
            ),
        )

    # --- Exec ---

    def exec_run(
        self,
        handle: ContainerHandle,
        cmd: str | list[str],
        *,
        user: str | None = None,
        workdir: str | None = None,
        environment: dict[str, str] | None = None,
        detach: bool = False,
    ) -> ExecResult:
        sandbox = self._raw(handle)
        run_user = user or self._default_user(handle)
        cmd_str = _as_shell(cmd)
        envs = environment or None

        if detach:
            sandbox.commands.run(
                cmd_str,
                background=True,
                user=run_user,
                cwd=workdir,
                envs=envs,
                timeout=0,
            )
            return ExecResult(output="", exit_code=0)

        chunks: list[str] = []
        try:
            result = sandbox.commands.run(
                cmd_str,
                user=run_user,
                cwd=workdir,
                envs=envs,
                timeout=DEFAULT_EXEC_TIMEOUT,
                on_stdout=chunks.append,
                on_stderr=chunks.append,
            )
            exit_code = result.exit_code
        except Exception as exc:
            exit_code = _exit_code_of(exc)
            if exit_code is None:
                raise
        return ExecResult(output="".join(chunks), exit_code=exit_code)

    def exec_run_with_timeout(
        self,
        handle: ContainerHandle,
        cmd: str | list[str],
        timeout: int | None = 60,
        *,
        log_file: Path | None = None,
        user: str | None = None,
        workdir: str | None = None,
        environment: dict[str, str] | None = None,
        stream_to_stdout: bool = False,
        shutdown_event: threading.Event | None = None,
        log_append: bool = False,
        on_chunk: Callable[[bytes], None] | None = None,
    ) -> StreamingExecResult:
        output, exit_code, timed_out, elapsed = self._exec_stream(
            handle,
            cmd,
            timeout,
            log_file=log_file,
            user=user,
            workdir=workdir,
            environment=environment,
            stream_to_stdout=stream_to_stdout,
            shutdown_event=shutdown_event,
            log_append=log_append,
            on_chunk=on_chunk,
        )
        return StreamingExecResult(
            output=output,
            exit_code=exit_code,
            timed_out=timed_out,
            elapsed_seconds=elapsed,
        )

    def exec_run_with_exit_code(
        self,
        handle: ContainerHandle,
        cmd: str | list[str],
        timeout: int | None = 60,
        *,
        user: str | None = None,
        workdir: str | None = None,
        environment: dict[str, str] | None = None,
    ) -> StreamingExecResult:
        output, exit_code, timed_out, elapsed = self._exec_stream(
            handle,
            cmd,
            timeout,
            user=user,
            workdir=workdir,
            environment=environment,
        )
        return StreamingExecResult(
            output=output,
            exit_code=exit_code,
            timed_out=timed_out,
            elapsed_seconds=elapsed,
        )

    def _exec_stream(
        self,
        handle: ContainerHandle,
        cmd: str | list[str],
        timeout: int | None,
        *,
        log_file: Path | None = None,
        user: str | None = None,
        workdir: str | None = None,
        environment: dict[str, str] | None = None,
        stream_to_stdout: bool = False,
        shutdown_event: threading.Event | None = None,
        log_append: bool = False,
        on_chunk: Callable[[bytes], None] | None = None,
    ) -> tuple[str, int, bool, float]:
        import sys

        sandbox = self._raw(handle)
        run_user = user or self._default_user(handle)
        chunks: list[str] = []
        exit_code: int | None = None
        exception: Exception | None = None
        timed_out = False
        log_fh = None

        try:
            if log_file:
                log_file.parent.mkdir(parents=True, exist_ok=True)
                log_fh = open(log_file, "ab" if log_append else "wb")

            def emit(text: str) -> None:
                chunks.append(text)
                raw = text.encode(errors="replace")
                if log_fh:
                    log_fh.write(raw)
                    log_fh.flush()
                if stream_to_stdout:
                    sys.stdout.buffer.write(raw)
                    sys.stdout.buffer.flush()
                if on_chunk is not None:
                    try:
                        on_chunk(raw)
                    except Exception:
                        logger.debug(
                            "E2B output callback failed", exc_info=True,
                        )

            # The wait stream can be interrupted by request timeouts or
            # ordinary network failures while agent runs last hours. The
            # command therefore runs in the background — it survives a dropped
            # stream — and its exit code is persisted in the sandbox so it is
            # recoverable even if the process finishes while we are detached.
            rc_file = f"/tmp/.sforge-rc-{uuid.uuid4().hex}"
            wrapped = (
                f"{{ {_as_shell(cmd)}\n}}; __ec=$?; echo $__ec > {rc_file}; exit $__ec"
            )
            proc = sandbox.commands.run(
                wrapped,
                background=True,
                user=run_user,
                cwd=workdir,
                envs=environment or None,
                timeout=0,
            )

            def read_rc_file() -> int | None:
                try:
                    result = sandbox.commands.run(
                        f"cat {rc_file}",
                        user="root",
                        timeout=30,
                    )
                    return int(result.stdout.strip())
                except Exception:
                    return None

            def wait_command() -> None:
                nonlocal exit_code, exception
                attach = proc
                reconnects = 0
                while True:
                    try:
                        result = attach.wait(on_stdout=emit, on_stderr=emit)
                        exit_code = result.exit_code
                        return
                    except Exception as exc:
                        code = _exit_code_of(exc)
                        if code is not None:
                            exit_code = code
                            return
                        # Stream dropped, not a command failure. Reattach to
                        # the still-running process; output produced while
                        # detached is lost, the exit code is not.
                        last_exc = exc
                    for attempt in range(5):
                        if shutdown_event and shutdown_event.is_set():
                            exception = last_exc
                            return
                        try:
                            attach = sandbox.commands.connect(proc.pid, timeout=0)
                            break
                        except Exception:
                            code = read_rc_file()
                            if code is not None:
                                # Command finished while we were detached.
                                exit_code = code
                                return
                            time.sleep(min(2**attempt, 15))
                    else:
                        exception = last_exc
                        return
                    reconnects += 1
                    logger.info(
                        "e2b exec stream dropped, reattached to pid %s (reconnect #%d)",
                        proc.pid,
                        reconnects,
                    )

            start_time = time.time()
            thread = threading.Thread(target=wait_command, daemon=True)
            thread.start()

            deadline = start_time + timeout if timeout else None
            while thread.is_alive():
                remaining = (deadline - time.time()) if deadline else 1.0
                if remaining <= 0:
                    break
                thread.join(min(remaining, 1.0))
                if shutdown_event and shutdown_event.is_set():
                    break

            if thread.is_alive():
                timed_out = True
                try:
                    killed = sandbox.commands.kill(proc.pid)
                    if killed is False:
                        raise RuntimeError(
                            f"E2B command {proc.pid} was not found while timing out"
                        )
                except Exception as exc:
                    raise RuntimeError(
                        f"Failed to stop timed-out E2B command {proc.pid}: {exc}"
                    ) from exc
                thread.join(10)
                if thread.is_alive():
                    raise RuntimeError(
                        f"Timed-out E2B command {proc.pid} did not terminate"
                    )
                # The late thread result (e.g. 137 from the kill) must not
                # shadow the docker-contract exit code for timeouts.
                exit_code = -1
                exception = None
        finally:
            if log_fh:
                log_fh.close()
            if "rc_file" in locals():
                try:
                    sandbox.files.remove(rc_file, user="root")
                except Exception:
                    logger.debug(
                        "Could not remove E2B command status file %s",
                        rc_file,
                        exc_info=True,
                    )

        if exception:
            raise exception

        elapsed = time.time() - start_time
        return (
            "".join(chunks),
            exit_code if exit_code is not None else -1,
            timed_out,
            elapsed,
        )

    # --- Inspection ---

    def get_container_ip(self, handle: ContainerHandle) -> str:
        raise NotImplementedError(
            "e2b sandboxes have no routable IP; use get_service_endpoint() to "
            "reach in-sandbox services through the e2b gateway"
        )

    def get_service_endpoint(
        self,
        handle: ContainerHandle,
        port: int,
    ) -> ServiceEndpoint:
        sandbox = self._raw(handle)
        token = getattr(sandbox, "traffic_access_token", None)
        if not token:
            raise RuntimeError(
                "E2B did not return a traffic access token for the secured service"
            )
        return ServiceEndpoint(
            url=f"https://{sandbox.get_host(port)}",
            headers={"e2b-traffic-access-token": token},
        )

    def get_container_gateway_ip(self, handle: ContainerHandle) -> str | None:
        return None

    # --- Network isolation ---

    def create_network_isolation(
        self,
        handle: ContainerHandle,
        allowed_endpoints: list,
        logger_: logging.Logger,
    ) -> NetworkIsolationStrategy:
        return E2BNetworkIsolation(self._raw(handle), allowed_endpoints, logger_)

    # --- Lease renewal ---

    def _ensure_renewal_thread(self) -> None:
        """Start one renewal worker while holding ``_handles_lock``."""
        if self._renewal_thread is not None and self._renewal_thread.is_alive():
            return
        self._renewal_wakeup.clear()
        self._renewal_thread = threading.Thread(
            target=self._renewal_loop,
            daemon=True,
            name="e2b-lease-renewal",
        )
        self._renewal_thread.start()

    def _renewal_loop(self) -> None:
        interval = max(self._sandbox_ttl // 3, 1)
        while True:
            woke_early = self._renewal_wakeup.wait(interval)
            with self._handles_lock:
                handles = list(self._handles.values())
                if not handles:
                    self._renewal_thread = None
                    return
                if woke_early:
                    self._renewal_wakeup.clear()
            if woke_early:
                continue
            for handle in handles:
                self._renew_handle(handle)

    def _renew_handle(self, handle: E2BSandboxHandle) -> None:
        with handle._lease_lock:
            if handle._closing:
                return
            try:
                handle.raw.set_timeout(
                    self._sandbox_ttl,
                    request_timeout=SANDBOX_LIFECYCLE_REQUEST_TIMEOUT,
                )
            except Exception as exc:
                logger.warning(
                    f"Lease renewal failed for sandbox {handle.id}: {exc}"
                )

    # --- Helpers ---

    @staticmethod
    def _default_user(handle: ContainerHandle) -> str | None:
        return getattr(handle, "default_user", None)

    @staticmethod
    def _raw(handle: ContainerHandle):
        if isinstance(handle, E2BSandboxHandle):
            return handle.raw
        raise TypeError(f"Expected E2BSandboxHandle, got {type(handle).__name__}")

    @staticmethod
    def _retry_file_transfer(description: str, operation):
        for attempt in range(1, FILE_TRANSFER_ATTEMPTS + 1):
            try:
                return operation()
            except Exception as exc:
                if (
                    attempt == FILE_TRANSFER_ATTEMPTS
                    or not _is_retryable_transport_error(exc)
                ):
                    raise
                logger.warning(
                    "E2B file transfer failed while attempting to %s "
                    "(attempt %d/%d): %s",
                    description, attempt, FILE_TRANSFER_ATTEMPTS, exc,
                )
                time.sleep(attempt)
        raise AssertionError("unreachable")


def _as_shell(cmd: str | list[str]) -> str:
    return shlex.join(cmd) if isinstance(cmd, list) else cmd


def e2b_template_reference(image_key: str, namespace: str | None = None) -> str:
    repo, separator, tag = image_key.partition(":")
    name = repo.lower().replace(".", "-").replace("_", "-")
    if not _E2B_NAME_PATTERN.fullmatch(name):
        raise ValueError(
            f"E2B Template name derived from {image_key!r} is invalid: {name!r}"
        )
    if namespace:
        if not _E2B_NAME_PATTERN.fullmatch(namespace):
            raise ValueError(
                "E2B Template namespace must contain only lowercase letters, "
                "numbers, dashes, and underscores, and be at most 128 characters"
            )
        name = f"{namespace}/{name}"
    return name + separator + tag


def _is_namespaced_template_reference(template: str) -> bool:
    name, _, _tag = template.partition(":")
    parts = name.split("/")
    return len(parts) == 2 and all(_E2B_NAME_PATTERN.fullmatch(part) for part in parts)


def _exit_code_of(exc: Exception) -> int | None:
    """Exit code carried by a CommandExitException, duck-typed so fakes and
    provider variants work."""
    code = getattr(exc, "exit_code", None)
    return code if isinstance(code, int) else None


def _is_retryable_transport_error(exc: Exception) -> bool:
    """Recognize transport failures without retrying provider rejections."""
    current: BaseException | None = exc
    while current is not None:
        if type(current).__name__ in {
            "ConnectError",
            "ConnectTimeout",
            "ReadError",
            "ReadTimeout",
            "RemoteProtocolError",
            "TimeoutException",
            "WriteError",
            "WriteTimeout",
        }:
            return True
        current = current.__cause__ or current.__context__
    message = str(exc).lower()
    return any(
        marker in message
        for marker in (
            "connection reset",
            "operation timed out",
            "request timed out",
            "temporarily unavailable",
        )
    )


def template_map_from_env() -> dict[str, str]:
    """Parse SFORGE_E2B_TEMPLATE_MAP: inline ``key=value,key=value`` pairs or
    a path to a JSON object file."""
    raw = os.environ.get("SFORGE_E2B_TEMPLATE_MAP", "").strip()
    if not raw:
        return {}
    if raw.endswith(".json"):
        try:
            return {
                str(k): str(v) for k, v in json.loads(Path(raw).read_text()).items()
            }
        except (OSError, json.JSONDecodeError) as exc:
            raise ValueError(
                f"Cannot load SFORGE_E2B_TEMPLATE_MAP file {raw!r}: {exc}"
            ) from exc
    result: dict[str, str] = {}
    for item in raw.split(","):
        item = item.strip()
        if not item:
            continue
        if "=" not in item:
            raise ValueError(
                f"Malformed SFORGE_E2B_TEMPLATE_MAP entry {item!r} (expected key=value)"
            )
        k, v = item.split("=", 1)
        result[k.strip()] = v.strip()
    return result
