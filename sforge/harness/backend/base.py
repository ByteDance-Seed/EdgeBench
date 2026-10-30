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

"""Abstract base classes for container backends."""

from __future__ import annotations

import abc
import logging
import threading
from dataclasses import dataclass, field
from pathlib import Path, PurePosixPath
from typing import Callable


@dataclass
class ExecResult:
    """Result of a simple (non-streaming) command execution."""

    output: str = ""
    exit_code: int = 0


@dataclass
class StreamingExecResult:
    """Result of a streaming command execution with timeout support."""

    output: str = ""
    exit_code: int = 0
    timed_out: bool = False
    elapsed_seconds: float = 0.0


@dataclass(frozen=True)
class ServiceEndpoint:
    """A routable service URL and provider gateway credentials."""

    url: str
    headers: dict[str, str] = field(default_factory=dict)


class ContainerHandle(abc.ABC):
    """Opaque handle to a running container or pod."""

    @property
    @abc.abstractmethod
    def id(self) -> str:
        ...

    @property
    @abc.abstractmethod
    def name(self) -> str:
        ...

    @property
    @abc.abstractmethod
    def ip_address(self) -> str | None:
        ...


class ContainerBackend(abc.ABC):
    """Abstract interface for container orchestration."""

    @property
    @abc.abstractmethod
    def backend_name(self) -> str:
        ...

    @property
    def uses_hostname_egress(self) -> bool:
        """True when the provider enforces egress rules by hostname and its
        sandboxes resolve DNS themselves (official e2b). Otherwise the harness
        resolves the judge/API hosts and pins them into /etc/hosts."""
        return False

    @property
    def public_dns(self) -> tuple[str, ...]:
        """Resolvers that internet-enabled sandboxes should use instead of the
        provider's own DNS (empty = keep the provider's)."""
        return ()

    # --- Lifecycle ---

    @abc.abstractmethod
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
        annotations: dict[str, str] | None = None,
        network: bool = True,
    ) -> ContainerHandle:
        """``network=False`` is honoured at creation where the backend can
        (docker); elsewhere the caller isolates the started container with
        ``create_network_isolation(handle, [])``."""
        ...

    @abc.abstractmethod
    def start_container(self, handle: ContainerHandle) -> None:
        ...

    @abc.abstractmethod
    def cleanup_container(
        self, handle: ContainerHandle | None, logger: logging.Logger | None = None,
    ) -> None:
        ...

    @abc.abstractmethod
    def container_exists(self, name: str, image_key: str | None = None) -> bool:
        """``image_key`` is an optional lookup hint for backends that cannot
        enumerate containers globally (veFaaS scopes listing per function)."""
        ...

    @abc.abstractmethod
    def remove_container_by_name(
        self, name: str, image_key: str | None = None,
    ) -> None:
        """``image_key`` as in :meth:`container_exists`."""
        ...

    # --- Image ---

    @abc.abstractmethod
    def image_exists(self, image_key: str) -> bool:
        ...

    # --- File transfer ---

    @abc.abstractmethod
    def copy_to_container(
        self, handle: ContainerHandle, src: Path, dst: PurePosixPath,
    ) -> None:
        ...

    @abc.abstractmethod
    def copy_from_container(
        self, handle: ContainerHandle, src: PurePosixPath,
    ) -> bytes:
        ...

    @abc.abstractmethod
    def write_to_container(
        self, handle: ContainerHandle, data: str, dst: PurePosixPath,
    ) -> None:
        ...

    # --- Exec ---

    @abc.abstractmethod
    def exec_run(
        self,
        handle: ContainerHandle,
        cmd: str | list[str],
        *,
        workdir: str | None = None,
        environment: dict[str, str] | None = None,
        detach: bool = False,
    ) -> ExecResult:
        ...

    @abc.abstractmethod
    def exec_run_with_timeout(
        self,
        handle: ContainerHandle,
        cmd: str | list[str],
        timeout: int | None = 60,
        *,
        log_file: Path | None = None,
        workdir: str | None = None,
        environment: dict[str, str] | None = None,
        stream_to_stdout: bool = False,
        shutdown_event: threading.Event | None = None,
        log_append: bool = False,
        on_chunk: Callable[[bytes], None] | None = None,
    ) -> StreamingExecResult:
        ...

    @abc.abstractmethod
    def exec_run_with_exit_code(
        self,
        handle: ContainerHandle,
        cmd: str | list[str],
        timeout: int | None = 60,
        *,
        workdir: str | None = None,
        environment: dict[str, str] | None = None,
    ) -> StreamingExecResult:
        ...

    # --- Inspection ---

    @abc.abstractmethod
    def get_container_ip(self, handle: ContainerHandle) -> str:
        ...

    def get_service_endpoint(
        self, handle: ContainerHandle, port: int,
    ) -> ServiceEndpoint:
        """Return the URL plus headers needed to cross the provider gateway."""
        return ServiceEndpoint(
            url=f"http://{self.get_container_ip(handle)}:{port}",
        )

    @abc.abstractmethod
    def get_container_gateway_ip(self, handle: ContainerHandle) -> str | None:
        ...

    # --- Network isolation ---

    @abc.abstractmethod
    def create_network_isolation(
        self,
        handle: ContainerHandle,
        allowed_endpoints: list,
        logger: logging.Logger,
    ) -> NetworkIsolationStrategy:
        ...


class NetworkIsolationStrategy(abc.ABC):
    """Abstract network isolation that can be applied and cleaned up."""

    @abc.abstractmethod
    def apply(self) -> None:
        ...

    @abc.abstractmethod
    def cleanup(self) -> None:
        ...
