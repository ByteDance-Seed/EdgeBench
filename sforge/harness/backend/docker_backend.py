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

"""Docker backend implementation wrapping docker-py SDK."""

from __future__ import annotations

import io
import json
import logging
import os
import secrets
import signal
import sys
import tarfile
import threading
import time
import traceback
from collections.abc import Callable
from datetime import datetime, timezone
from pathlib import Path, PurePosixPath

import docker
import docker.errors
import requests
from docker.models.containers import Container

from sforge.harness.backend.base import (
    ContainerBackend,
    ContainerHandle,
    ExecResult,
    NetworkIsolationStrategy,
    StreamingExecResult,
)

HEREDOC_DELIMITER = "EOF_SFORGE_1399519320"


# A create request whose outcome we cannot know: the POST may have reached the
# daemon even though the reply never arrived.
_CREATE_OUTCOME_UNKNOWN_ERRORS = (
    requests.exceptions.ReadTimeout,
    requests.exceptions.ConnectionError,
    requests.exceptions.ChunkedEncodingError,
)

# Binds a container to the create attempt that produced it. The deterministic
# name alone cannot do this: a create whose reply was lost can land *after* a
# later cleanup has already removed the previous same-name container.
CREATE_OPERATION_LABEL = "sforge.create_operation"

# Bounded re-query of the ambiguous create. This budget bounds only the *reconcile
# query window*: every individual ``containers.get`` is capped by the time left in
# it, so a single query can never block past it. The overall create call is wider
# than this window -- it also includes the initial HTTP request wait (up to the
# client's own timeout, which happens before reconciliation starts) and the
# pending-record write (after). What the budget buys is that reconciliation
# returns within it and can adopt a container that became visible inside it; a
# daemon slow enough to land the container later is not covered, and that outcome
# is recorded as pending for out-of-band reconciliation.
_RECONCILE_QUERY_BUDGET_SEC = 30.0
_RECONCILE_QUERY_INTERVAL_SEC = 1.0

# Where an unresolved create is recorded so it can be reconciled out of band.
PENDING_CREATE_DIR_ENV = "SFORGE_PENDING_CREATE_DIR"
_DEFAULT_PENDING_CREATE_DIR = "/tmp/sforge-pending-creates"


def _record_pending_create(
    *,
    name: str,
    image: str,
    nonce: str,
    outcome: str,
    detail: str | None = None,
    cause: BaseException | None = None,
) -> None:
    """Record a create whose outcome could not be settled.

    One file per (container, create attempt): the file name carries the nonce and
    is created exclusively, so a later attempt can never overwrite an earlier
    attempt's record. A write failure is surfaced explicitly -- logged at ERROR
    and attached to the original error as a note -- never silently swallowed, and
    never allowed to replace the original failure.
    """
    try:
        root = os.environ.get(PENDING_CREATE_DIR_ENV) or _DEFAULT_PENDING_CREATE_DIR
        directory = Path(root)
        directory.mkdir(parents=True, exist_ok=True)
        payload = {
            "container_name": name,
            "image": image,
            "nonce": nonce,
            "outcome": outcome,
            "detail": detail,
            "recorded_at_utc": datetime.now(timezone.utc).isoformat(),
        }
        path = directory / f"{name}.{nonce}.json"
        with open(path, "x", encoding="utf-8") as handle:
            handle.write(json.dumps(payload, indent=2, ensure_ascii=False))
    except Exception as exc:  # noqa: BLE001 - must never mask the original failure
        logging.getLogger(__name__).error(
            "could not record pending create for %s (nonce=%s outcome=%s): %s",
            name,
            nonce,
            outcome,
            exc,
        )
        if cause is not None:
            try:
                cause.add_note(
                    f"failed to record pending create for {name} "
                    f"(nonce={nonce}, outcome={outcome}): {type(exc).__name__}: {exc}"
                )
            except AttributeError:
                pass


class ContainerCreateReconcileError(docker.errors.DockerException):
    """An ambiguous container create could not be reconciled with the daemon."""


class _QueryTimeout:
    """Sentinel: a bounded reconcile query did not finish inside its budget."""


_QUERY_TIMEOUT = _QueryTimeout()


def _container_matches_create(container, *, image: str, nonce: str) -> bool:
    attrs = getattr(container, "attrs", None) or {}
    config = attrs.get("Config") or {}
    state = (attrs.get("State") or {}).get("Status")
    labels = config.get("Labels") or {}
    return (
        labels.get(CREATE_OPERATION_LABEL) == nonce
        and config.get("Image") == image
        and state == "created"
    )


class DockerContainerHandle(ContainerHandle):
    """Wraps a docker Container object."""

    def __init__(self, container: Container) -> None:
        self._container = container

    @property
    def id(self) -> str:
        return self._container.id

    @property
    def name(self) -> str:
        return self._container.name

    @property
    def ip_address(self) -> str | None:
        try:
            self._container.reload()
            networks = self._container.attrs.get("NetworkSettings", {}).get("Networks", {})
            for net_info in networks.values():
                ip = net_info.get("IPAddress", "")
                if ip:
                    return ip
        except Exception:
            pass
        return None

    @property
    def raw(self) -> Container:
        return self._container


class DockerNetworkIsolation(NetworkIsolationStrategy):
    """Delegates to the existing NetworkIsolation class in network_isolation.py."""

    def __init__(self, isolation) -> None:
        self._isolation = isolation

    def apply(self) -> None:
        self._isolation.apply()

    def cleanup(self) -> None:
        self._isolation.cleanup()


class DockerBackend(ContainerBackend):
    """Container backend using local Docker daemon."""

    def __init__(self, client: docker.DockerClient | None = None) -> None:
        self._client = client or docker.from_env()

    @property
    def backend_name(self) -> str:
        return "docker"

    @property
    def client(self) -> docker.DockerClient:
        return self._client

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
    ) -> DockerContainerHandle:
        kwargs: dict = {}
        if cpu_limit is not None:
            kwargs["nano_cpus"] = int(cpu_limit * 1e9)
        if mem_limit is not None:
            kwargs["mem_limit"] = mem_limit
        if cap_drop:
            kwargs["cap_drop"] = cap_drop
        if extra_hosts:
            kwargs["extra_hosts"] = extra_hosts
        if user:
            kwargs["user"] = user

        operation_nonce = secrets.token_hex(16)
        try:
            container = self._client.containers.create(
                image,
                name=name,
                detach=True,
                command=command,
                environment=environment or {},
                labels={CREATE_OPERATION_LABEL: operation_nonce},
                **kwargs,
            )
        except _CREATE_OUTCOME_UNKNOWN_ERRORS as exc:
            # The POST may already have reached the daemon even though the reply
            # never arrived. Reconcile against this attempt's nonce instead of
            # creating a second container.
            container = self._reconcile_created_container(
                image=image, name=name, nonce=operation_nonce, cause=exc,
            )
        return DockerContainerHandle(container)

    def _bounded_get(self, name: str, budget: float):
        """``containers.get`` capped at ``budget`` seconds.

        Returns the container, ``None`` when the daemon reports it absent, or the
        module sentinel ``_QUERY_TIMEOUT`` when the query did not finish in time.
        The query runs on a worker thread because ``containers.get`` takes no
        timeout and the client's own timeout is shared state we must not touch.
        """
        box: dict = {}

        def worker() -> None:
            try:
                box["container"] = self._client.containers.get(name)
            except docker.errors.NotFound:
                box["container"] = None
            except BaseException as exc:  # noqa: BLE001 - re-raised by the caller
                box["error"] = exc

        thread = threading.Thread(target=worker, daemon=True)
        thread.start()
        thread.join(max(0.0, budget))
        if thread.is_alive():
            return _QUERY_TIMEOUT
        if "error" in box:
            raise box["error"]
        return box.get("container")

    def _reconcile_created_container(
        self, *, image: str, name: str, nonce: str, cause: BaseException,
    ) -> Container:
        """Decide whether an ambiguous ``create`` landed, without creating again.

        Adoption requires an exact match on this attempt's nonce, the image, and
        the ``created`` state. A same-name container left by an earlier attempt
        carries a different (or absent) nonce and is never adopted.

        Every query is capped by the time left in the budget, so the call returns
        within the budget even if a single query would block longer. An outcome
        that stays unknown is recorded as pending; ``NotFound`` proves only that
        the container was not visible at query time, never that the create did
        not happen.
        """
        deadline = time.monotonic() + _RECONCILE_QUERY_BUDGET_SEC
        while True:
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                _record_pending_create(
                    name=name, image=image, nonce=nonce, outcome="unknown",
                    detail="budget exhausted while the container was not visible",
                    cause=cause,
                )
                raise cause
            try:
                existing = self._bounded_get(name, remaining)
            except Exception:  # noqa: BLE001 - preserve the original create error
                # The reconcile query itself is unreliable: the create outcome
                # remains unknown. Never create a second container.
                _record_pending_create(
                    name=name, image=image, nonce=nonce, outcome="unknown",
                    detail="reconcile query failed",
                    cause=cause,
                )
                raise cause

            if existing is _QUERY_TIMEOUT:
                _record_pending_create(
                    name=name, image=image, nonce=nonce, outcome="unknown",
                    detail="reconcile query exceeded the remaining budget",
                    cause=cause,
                )
                raise cause

            if existing is not None:
                if _container_matches_create(existing, image=image, nonce=nonce):
                    return existing
                attrs = getattr(existing, "attrs", None) or {}
                config = attrs.get("Config") or {}
                labels = config.get("Labels") or {}
                _record_pending_create(
                    name=name, image=image, nonce=nonce, outcome="identity_conflict",
                    cause=cause,
                    detail=(
                        f"name taken by image={config.get('Image')!r} "
                        f"state={(attrs.get('State') or {}).get('Status')!r} "
                        f"nonce={labels.get(CREATE_OPERATION_LABEL)!r}"
                    ),
                )
                raise ContainerCreateReconcileError(
                    f"create_container({name!r}) returned no reply and the name is "
                    f"taken by a container that does not belong to this attempt "
                    f"(image={config.get('Image')!r} "
                    f"state={(attrs.get('State') or {}).get('Status')!r} "
                    f"nonce={labels.get(CREATE_OPERATION_LABEL)!r}); refusing to adopt it"
                ) from cause

            remaining = deadline - time.monotonic()
            if remaining <= 0:
                _record_pending_create(
                    name=name, image=image, nonce=nonce, outcome="unknown",
                    detail="budget exhausted while the container was not visible",
                    cause=cause,
                )
                raise cause
            time.sleep(min(_RECONCILE_QUERY_INTERVAL_SEC, remaining))

    def start_container(self, handle: ContainerHandle) -> None:
        self._raw(handle).start()

    def cleanup_container(
        self, handle: ContainerHandle | None, logger: logging.Logger | None = None,
    ) -> None:
        if handle is None:
            return

        container = self._raw(handle)
        old_handler = None
        try:
            old_handler = signal.signal(signal.SIGINT, signal.SIG_IGN)
        except ValueError:
            pass

        log_info = logger.info if logger else print
        log_error = logger.error if logger else print

        try:
            log_info(f"Stopping container {container.name}...")
            container.stop(timeout=15)
        except Exception as e:
            log_error(f"Failed to stop container {container.name}: {e}")
            try:
                container_info = self._client.api.inspect_container(container.id)
                pid = container_info["State"].get("Pid", 0)
                if pid > 0:
                    log_info(f"Forcefully killing container PID {pid}...")
                    os.kill(pid, signal.SIGKILL)
            except Exception as e2:
                log_error(f"Failed to kill container {container.name}: {e2}")

        try:
            log_info(f"Removing container {container.name}...")
            container.remove(force=True)
            log_info(f"Container {container.name} removed.")
        except Exception as e:
            log_error(
                f"Failed to remove container {container.name}: {e}\n"
                f"{traceback.format_exc()}"
            )

        if old_handler is not None:
            try:
                signal.signal(signal.SIGINT, old_handler)
            except ValueError:
                pass

    def container_exists(self, name: str) -> bool:
        try:
            self._client.containers.get(name)
            return True
        except docker.errors.NotFound:
            return False

    def remove_container_by_name(self, name: str) -> None:
        try:
            c = self._client.containers.get(name)
            c.remove(force=True)
        except docker.errors.NotFound:
            pass

    # --- Image ---

    def image_exists(self, image_key: str) -> bool:
        try:
            self._client.images.get(image_key)
            return True
        except docker.errors.ImageNotFound:
            return False

    # --- File transfer ---

    def copy_to_container(
        self, handle: ContainerHandle, src: Path, dst: PurePosixPath,
    ) -> None:
        container = self._raw(handle)
        if str(dst.parent) == ".":
            raise ValueError(f"Destination parent directory cannot be empty: {dst}")

        buf = io.BytesIO()
        with tarfile.open(fileobj=buf, mode="w") as tar:
            tar.add(src, arcname=dst.name)
        buf.seek(0)

        container.exec_run(f"mkdir -p {dst.parent}")
        container.put_archive(str(dst.parent), buf.read())

    def copy_from_container(
        self, handle: ContainerHandle, src: PurePosixPath,
    ) -> bytes:
        container = self._raw(handle)
        bits, _ = container.get_archive(str(src))
        return b"".join(bits)

    def write_to_container(
        self, handle: ContainerHandle, data: str, dst: PurePosixPath,
    ) -> None:
        container = self._raw(handle)
        command = f"cat <<'{HEREDOC_DELIMITER}' > {dst}\n{data}\n{HEREDOC_DELIMITER}"
        container.exec_run(command)

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
        container = self._raw(handle)
        kwargs: dict = {}
        if user:
            kwargs["user"] = user
        if workdir:
            kwargs["workdir"] = workdir
        if environment:
            kwargs["environment"] = environment
        result = container.exec_run(cmd, detach=detach, **kwargs)
        if detach:
            return ExecResult(output="", exit_code=0)
        output = result.output.decode(errors="replace") if isinstance(result.output, bytes) else (result.output or "")
        return ExecResult(output=output, exit_code=result.exit_code)

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
        result = self._exec_run_impl(
            handle, cmd, timeout,
            log_file=log_file, user=user, workdir=workdir,
            environment=environment, stream_to_stdout=stream_to_stdout,
            shutdown_event=shutdown_event, log_append=log_append,
            on_chunk=on_chunk,
        )
        return StreamingExecResult(
            output=result[0], exit_code=result[1],
            timed_out=result[2], elapsed_seconds=result[3],
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
        result = self._exec_run_impl(
            handle, cmd, timeout,
            user=user, workdir=workdir, environment=environment,
        )
        return StreamingExecResult(
            output=result[0], exit_code=result[1],
            timed_out=result[2], elapsed_seconds=result[3],
        )

    def _exec_run_impl(
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
    ) -> tuple[str, int, bool, float]:
        container = self._raw(handle)
        chunks: list[bytes] = []
        exec_id = None
        exception = None
        timed_out = False
        log_fh = None

        try:
            if log_file:
                log_file.parent.mkdir(parents=True, exist_ok=True)
                log_fh = open(log_file, "ab" if log_append else "wb")

            def run_command():
                nonlocal exec_id, exception
                try:
                    kwargs = {}
                    if user:
                        kwargs["user"] = user
                    if workdir:
                        kwargs["workdir"] = workdir
                    if environment:
                        kwargs["environment"] = environment
                    exec_id = container.client.api.exec_create(container.id, cmd, **kwargs)["Id"]
                    exec_stream = container.client.api.exec_start(exec_id, stream=True)
                    for chunk in exec_stream:
                        chunks.append(chunk)
                        if log_fh:
                            log_fh.write(chunk)
                            log_fh.flush()
                        if stream_to_stdout:
                            sys.stdout.buffer.write(chunk)
                            sys.stdout.buffer.flush()
                        if on_chunk is not None:
                            try:
                                on_chunk(chunk)
                            except Exception:
                                pass
                except Exception as e:
                    exception = e

            thread = threading.Thread(target=run_command)
            start_time = time.time()
            thread.start()

            deadline = start_time + timeout if timeout else None
            while thread.is_alive():
                remaining = (deadline - time.time()) if deadline else 1.0
                if remaining <= 0:
                    break
                thread.join(min(remaining, 1.0))
                if shutdown_event and shutdown_event.is_set():
                    break
        finally:
            if log_fh:
                log_fh.close()

        if exception:
            raise exception

        if thread.is_alive():
            if exec_id is not None:
                exec_pid = container.client.api.exec_inspect(exec_id)["Pid"]
                container.exec_run(["/bin/sh", "-c", f"kill -TERM {exec_pid}"], detach=True)
            timed_out = True
            exit_code = -1
        else:
            exit_code = container.client.api.exec_inspect(exec_id)["ExitCode"] if exec_id else -1

        end_time = time.time()
        output = b"".join(chunks).decode(errors="replace")
        return output, exit_code, timed_out, end_time - start_time

    # --- Inspection ---

    def get_container_ip(self, handle: ContainerHandle) -> str:
        container = self._raw(handle)
        container.reload()
        networks = container.attrs.get("NetworkSettings", {}).get("Networks", {})
        for net_info in networks.values():
            ip = net_info.get("IPAddress", "")
            if ip:
                return ip
        raise RuntimeError(f"Cannot determine IP for container {container.name}")

    def get_container_gateway_ip(self, handle: ContainerHandle) -> str | None:
        container = self._raw(handle)
        container.reload()
        networks = container.attrs.get("NetworkSettings", {}).get("Networks", {})
        for net_info in networks.values():
            gw = net_info.get("Gateway", "")
            if gw:
                return gw
        return None

    # --- Network isolation ---

    def create_network_isolation(
        self,
        handle: ContainerHandle,
        allowed_endpoints: list,
        logger: logging.Logger,
    ) -> NetworkIsolationStrategy:
        from sforge.harness.network_isolation import NetworkIsolation

        container = self._raw(handle)
        return DockerNetworkIsolation(NetworkIsolation(container, allowed_endpoints, logger))

    # --- Helpers ---

    @staticmethod
    def _raw(handle: ContainerHandle) -> Container:
        if isinstance(handle, DockerContainerHandle):
            return handle.raw
        raise TypeError(f"Expected DockerContainerHandle, got {type(handle).__name__}")
