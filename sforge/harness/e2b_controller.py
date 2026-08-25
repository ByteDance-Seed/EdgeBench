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

"""Managed Judge controller for brokerless official E2B runs."""

from __future__ import annotations

import io
import json
import logging
import os
import shlex
import tarfile
import time
import uuid
from importlib.metadata import PackageNotFoundError, requires
from pathlib import Path, PurePosixPath

import requests

from sforge.harness.backend import ContainerBackend, ContainerHandle
from sforge.harness.config import SForgeConfig
from sforge.harness.constants import get_admin_secret
from sforge.harness.judge_client import JudgeConnection

logger = logging.getLogger(__name__)


def _controller_requirements() -> tuple[str, ...]:
    """Return this installed SForge version's controller dependencies."""
    try:
        declared = requires("sforge") or []
    except PackageNotFoundError:
        declared = []
    runtime = [item for item in declared if "extra ==" not in item]
    e2b = [
        item.split(";", 1)[0].strip()
        for item in declared
        if "extra == 'e2b'" in item or 'extra == "e2b"' in item
    ]
    return tuple(runtime + e2b)


class ManagedE2BController:
    """Create, expose and tear down a Judge Server in an E2B Sandbox."""

    def __init__(
        self,
        backend: ContainerBackend,
        config: SForgeConfig,
        run_id: str,
        *,
        source_root: Path | None = None,
    ) -> None:
        self.backend = backend
        self.config = config
        self.run_id = run_id
        self.source_root = source_root or Path(__file__).resolve().parents[2]
        self.handle: ContainerHandle | None = None
        self.connection: JudgeConnection | None = None
        self.host_connection: JudgeConnection | None = None

    def _environment(self) -> dict[str, str]:
        allowed = ("E2B_API_KEY", "E2B_API_URL", "E2B_DOMAIN")
        env = {key: os.environ[key] for key in allowed if os.environ.get(key)}
        env.update(
            {
                "PYTHONPATH": "/opt/sforge-controller",
                "SFORGE_TASKS_DIR": "/opt/sforge-controller/tasks",
                "SFORGE_LOG_DIR": "/tmp/sforge-controller/logs",
                "SFORGE_BACKEND": "e2b",
                "SFORGE_ADMIN_SECRET": get_admin_secret(self.config.log_dir),
                "SFORGE_E2B_SANDBOX_TTL": str(self.config.e2b_sandbox_ttl or 3600),
            }
        )
        if self.config.judge_extra_env:
            env["SFORGE_JUDGE_EXTRA_ENV"] = ",".join(
                f"{key}={value}" for key, value in self.config.judge_extra_env.items()
            )
        if self.config.e2b_template_map:
            env["SFORGE_E2B_TEMPLATE_MAP"] = ",".join(
                f"{key}={value}" for key, value in self.config.e2b_template_map.items()
            )
        return env

    def start(self, timeout: int = 120) -> JudgeConnection:
        if self.handle is not None:
            raise RuntimeError("Managed E2B controller is already running")
        env = self._environment()
        self.handle = self.backend.create_container(
            "base",
            f"sforge.controller.{self.run_id}",
            user="root",
        )
        try:
            self.backend.copy_to_container(
                self.handle,
                self.source_root / "sforge",
                PurePosixPath("/opt/sforge-controller/sforge"),
            )
            self.backend.copy_to_container(
                self.handle,
                self.config.tasks_dir,
                PurePosixPath("/opt/sforge-controller/tasks"),
            )
            requirements = _controller_requirements()
            if not requirements:
                raise RuntimeError(
                    "Could not determine managed controller dependencies from "
                    "the installed SForge package metadata"
                )
            requirement_args = " ".join(shlex.quote(item) for item in requirements)
            bootstrap = self.backend.exec_run_with_exit_code(
                self.handle,
                "python3 -m venv /tmp/sforge-controller-venv && "
                "/tmp/sforge-controller-venv/bin/python -m pip install "
                "--disable-pip-version-check --no-cache-dir --quiet "
                + requirement_args,
                timeout=300,
                user="root",
            )
            if bootstrap.exit_code != 0:
                raise RuntimeError(
                    "Failed to prepare managed E2B Judge controller: "
                    + bootstrap.output[-8000:]
                )
            command = (
                "cd /opt/sforge-controller && "
                "/tmp/sforge-controller-venv/bin/python -m sforge.cli serve "
                "--host 0.0.0.0 --port 8080 "
                "> /tmp/sforge-judge.log 2>&1"
            )
            self.backend.exec_run(
                self.handle,
                command,
                detach=True,
                user="root",
                environment=env,
            )
            endpoint = self.backend.get_service_endpoint(self.handle, 8080)
            self.connection = JudgeConnection.from_e2b_traffic_token(
                endpoint.url,
                endpoint.headers.get("e2b-traffic-access-token"),
            )
            self.host_connection = JudgeConnection(
                url="http://127.0.0.1:8080",
                request_handler=self._request_on_controller,
            )
            deadline = time.time() + timeout
            while time.time() < deadline:
                try:
                    response = self.connection.request(
                        "GET",
                        "/openapi.json",
                        timeout=5,
                    )
                    if response.status_code == 200:
                        return self.connection
                except requests.RequestException:
                    pass
                time.sleep(1)
            log = self.backend.exec_run(
                self.handle,
                "tail -200 /tmp/sforge-judge.log",
                user="root",
            )
            raise RuntimeError(
                "Managed E2B Judge controller did not become ready: "
                + log.output[-8000:]
            )
        except BaseException:
            try:
                self.close()
            except Exception:
                logger.exception(
                    "Failed to clean up managed E2B controller %s after startup error",
                    self.run_id,
                )
            raise

    def close(self) -> None:
        if self.handle is not None:
            try:
                self._export_run_logs()
            except Exception as exc:
                logger.warning(
                    "Could not export managed E2B controller logs for %s: %s",
                    self.run_id,
                    exc,
                )
            self.backend.cleanup_container(self.handle)
            self.handle = None
            self.connection = None
            self.host_connection = None

    def _request_on_controller(
        self, method: str, path: str, **kwargs,
    ) -> requests.Response:
        """Send a host-side Judge request over the E2B command channel.

        Work Sandboxes still use the secured public gateway. Host orchestration
        can avoid that extra hop by issuing the same HTTP request from inside
        the Controller Sandbox against loopback.
        """
        if self.handle is None:
            raise RuntimeError("Managed E2B Judge controller is not running")

        request_id = uuid.uuid4().hex
        prefix = f"/tmp/.sforge-host-request-{request_id}"
        spec_path = f"{prefix}.json"
        response_path = f"{prefix}.response"
        files = kwargs.pop("files", None) or {}
        timeout = kwargs.pop("timeout", 60)
        spec = {
            "method": method,
            "url": f"http://127.0.0.1:8080/{path.lstrip('/')}",
            "headers": kwargs.pop("headers", None) or {},
            "json": kwargs.pop("json", None),
            "data": kwargs.pop("data", None),
            "timeout": timeout,
            "files": {},
        }
        if kwargs:
            raise TypeError(
                "Unsupported managed Judge request arguments: "
                + ", ".join(sorted(kwargs))
            )

        raw = self.handle.raw
        uploaded_paths: list[str] = []
        try:
            for index, (field_name, file_spec) in enumerate(files.items()):
                filename, content, content_type = file_spec
                remote_path = f"{prefix}.upload-{index}"
                raw.files.write(
                    remote_path, content, user="root", request_timeout=300,
                )
                uploaded_paths.append(remote_path)
                spec["files"][field_name] = {
                    "filename": filename,
                    "path": remote_path,
                    "content_type": content_type,
                }
            raw.files.write(
                spec_path, json.dumps(spec), user="root", request_timeout=60,
            )
            command = (
                "/tmp/sforge-controller-venv/bin/python -c "
                + shlex.quote(
                    "import json,requests,sys; "
                    "s=json.load(open(sys.argv[1])); opened=[]; files={}; "
                    "[(opened.append(open(v['path'],'rb')), "
                    "files.__setitem__(k,(v['filename'],opened[-1],v['content_type']))) "
                    "for k,v in s['files'].items()]; "
                    "r=requests.request(s['method'],s['url'],headers=s['headers'],"
                    "json=s['json'],data=s['data'],files=files or None,"
                    "timeout=s['timeout']); "
                    "open(sys.argv[2],'wb').write(r.content); print(r.status_code)"
                )
                + f" {shlex.quote(spec_path)} {shlex.quote(response_path)}"
            )
            exec_timeout = (
                int(max(timeout)) if isinstance(timeout, tuple) else int(timeout)
            ) + 30
            result = self.backend.exec_run_with_exit_code(
                self.handle, command, timeout=exec_timeout, user="root",
            )
            if result.timed_out:
                raise requests.Timeout(
                    f"Managed Judge loopback request timed out: {method} {path}"
                )
            if result.exit_code != 0:
                raise requests.ConnectionError(
                    "Managed Judge loopback request failed: "
                    + result.output[-2000:]
                )
            try:
                status_code = int(result.output.strip().splitlines()[-1])
            except (ValueError, IndexError) as exc:
                raise requests.ConnectionError(
                    "Managed Judge loopback request returned no HTTP status: "
                    + result.output[-2000:]
                ) from exc
            content = raw.files.read(
                response_path, format="bytes", user="root",
                request_timeout=300,
            )
            response = requests.Response()
            response.status_code = status_code
            response._content = content
            response.url = spec["url"]
            response.encoding = "utf-8"
            return response
        finally:
            targets = [spec_path, response_path, *uploaded_paths]
            try:
                self.backend.exec_run(
                    self.handle,
                    "rm -f -- " + " ".join(map(shlex.quote, targets)),
                    user="root",
                )
            except Exception:
                logger.debug(
                    "Could not clean up managed Judge request files",
                    exc_info=True,
                )

    def _export_run_logs(self) -> None:
        """Merge Judge artifacts into the host run directory before cleanup."""
        if self.handle is None:
            return
        remote_run = f"/tmp/sforge-controller/logs/runs/{self.run_id}"
        remote_archive = "/tmp/sforge-controller-run-logs.tar.gz"
        result = self.backend.exec_run_with_exit_code(
            self.handle,
            f"test -d {shlex.quote(remote_run)} || exit 3; "
            f"tar czf {remote_archive} "
            "--exclude='submission.tar.gz' --exclude='final_archive.tar.gz' "
            f"-C {shlex.quote(remote_run)} .",
            timeout=120,
            user="root",
        )
        if result.timed_out:
            raise TimeoutError("Timed out while exporting controller logs")
        if result.exit_code == 3:
            return
        if result.exit_code != 0:
            raise RuntimeError(result.output[-4000:])
        wrapped = self.backend.copy_from_container(
            self.handle,
            PurePosixPath(remote_archive),
        )
        with tarfile.open(fileobj=io.BytesIO(wrapped)) as outer:
            files = [member for member in outer.getmembers() if member.isfile()]
            if len(files) != 1:
                raise RuntimeError(
                    f"Unexpected controller log archive wrapper: {len(files)} files"
                )
            source = outer.extractfile(files[0])
            if source is None:
                raise RuntimeError("Could not read controller log archive")
            archive = source.read()
        _merge_log_archive(
            archive,
            self.config.log_dir / "runs" / self.run_id,
        )

    def __enter__(self) -> JudgeConnection:
        return self.start()

    def __exit__(self, exc_type, exc, tb) -> None:
        self.close()


def _merge_log_archive(archive: bytes, target_dir: Path) -> None:
    """Safely merge a controller-created tar.gz into a host run tree."""
    target_root = target_dir.resolve()
    total_size = 0
    with tarfile.open(fileobj=io.BytesIO(archive), mode="r:gz") as bundle:
        for member in bundle.getmembers():
            target = (target_root / member.name).resolve()
            if target != target_root and target_root not in target.parents:
                raise ValueError(f"Unsafe controller log path: {member.name!r}")
            if member.issym() or member.islnk():
                raise ValueError(
                    f"Controller log links are not supported: {member.name!r}"
                )
            if member.isdir():
                target.mkdir(parents=True, exist_ok=True)
                continue
            if not member.isfile():
                continue
            total_size += member.size
            if member.size > 64 * 1024 * 1024 or total_size > 256 * 1024 * 1024:
                raise ValueError("Controller log archive exceeds the size limit")
            source = bundle.extractfile(member)
            if source is None:
                continue
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(source.read())
