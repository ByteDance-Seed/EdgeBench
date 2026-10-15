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
import logging
import os
import signal
import tarfile
import threading
import traceback
from collections.abc import Callable
from pathlib import Path, PurePosixPath

import docker
import docker.errors
from docker.models.containers import Container

from sforge.harness.backend.base import (
    ContainerBackend,
    ContainerHandle,
    ExecResult,
    NetworkIsolationStrategy,
    StreamingExecResult,
)

HEREDOC_DELIMITER = "EOF_SFORGE_1399519320"


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
        self._judge_capacity_owner_id: str | None = None

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

        container = self._client.containers.create(
            image,
            name=name,
            detach=True,
            command=command,
            environment=environment or {},
            **kwargs,
        )
        return DockerContainerHandle(container)

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

    def judge_capacity_owner_id(self) -> str | None:
        if self._judge_capacity_owner_id is None:
            engine_id = self._client.info().get("ID")
            if not engine_id:
                return None
            self._judge_capacity_owner_id = f"docker:{engine_id}"
        return self._judge_capacity_owner_id

    def reconcile_judge_capacity_holder(
        self, token: str, owner_id: str | None,
    ) -> bool:
        current_owner_id = self.judge_capacity_owner_id()
        if owner_id is not None and owner_id != current_owner_id:
            return False
        _, separator, submission_id = token.partition(":")
        if not separator or not submission_id:
            return False
        suffix = f".{submission_id}"
        candidates = self._client.containers.list(
            all=True, filters={"name": submission_id}
        )
        owned = [
            container for container in candidates
            if ".judge." in container.name and container.name.endswith(suffix)
        ]
        if owner_id is None and not owned:
            return False
        for container in owned:
            self.cleanup_container(
                DockerContainerHandle(container), logging.getLogger(__name__)
            )
        remaining = self._client.containers.list(
            all=True, filters={"name": submission_id}
        )
        return not any(
            ".judge." in container.name and container.name.endswith(suffix)
            for container in remaining
        )

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
        native_codes: list[int] = []
        result = self._exec_run_impl(
            handle, cmd, timeout,
            log_file=log_file, user=user, workdir=workdir,
            environment=environment, stream_to_stdout=stream_to_stdout,
            shutdown_event=shutdown_event, log_append=log_append,
            on_chunk=on_chunk,
            on_terminal=native_codes.append,
        )
        return StreamingExecResult(
            output=result[0], exit_code=result[1],
            timed_out=result[2], elapsed_seconds=result[3],
            terminal_observed=bool(native_codes),
            native_exit_code=native_codes[-1] if native_codes else None,
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
        on_terminal: Callable[[int], None] | None = None,
    ) -> tuple[str, int, bool, float]:
        from sforge.harness.docker_utils import _exec_run

        return _exec_run(
            self._raw(handle), cmd, timeout,
            log_file=log_file, user=user, workdir=workdir,
            environment=environment, stream_to_stdout=stream_to_stdout,
            shutdown_event=shutdown_event, log_append=log_append,
            on_chunk=on_chunk,
            on_terminal=on_terminal,
        )

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
