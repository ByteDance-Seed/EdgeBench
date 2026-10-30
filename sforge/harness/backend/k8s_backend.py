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

"""Kubernetes backend implementation using kubectl subprocess calls."""

from __future__ import annotations

import io
import json
import logging
import shlex
import signal
import subprocess
import sys
import tarfile
import threading
import time
from pathlib import Path, PurePosixPath
from typing import Callable

from sforge.harness.backend.base import (
    ContainerBackend,
    ContainerHandle,
    ExecResult,
    NetworkIsolationStrategy,
    StreamingExecResult,
)
from sforge.harness.docker_build import registry_has, remote_ref


class K8sPodHandle(ContainerHandle):
    """Handle wrapping a Kubernetes Pod."""

    def __init__(self, pod_name: str, namespace: str) -> None:
        self._pod_name = pod_name
        self._namespace = namespace
        self._pod_uid: str = ""
        self._ip: str | None = None

    @property
    def id(self) -> str:
        return self._pod_uid or self._pod_name

    @property
    def name(self) -> str:
        return self._pod_name

    @property
    def namespace(self) -> str:
        return self._namespace

    @property
    def ip_address(self) -> str | None:
        return self._ip


class K8sNetworkIsolation(NetworkIsolationStrategy):
    """Network isolation via Kubernetes NetworkPolicy."""

    def __init__(
        self,
        handle: K8sPodHandle,
        allowed_endpoints: list,
        kubectl_base: list[str],
        namespace: str,
        logger: logging.Logger,
    ) -> None:
        self._handle = handle
        self._endpoints = allowed_endpoints
        self._kubectl_base = kubectl_base
        self._namespace = namespace
        self._logger = logger
        self._policy_name = f"sforge-iso-{handle.name}"[:63].rstrip("-")
        self._applied = False

    def apply(self) -> None:
        if self._applied:
            return

        egress_rules = []
        for ep in self._endpoints:
            egress_rules.append({
                "to": [{"ipBlock": {"cidr": f"{ep.ip}/32"}}],
                "ports": [{"port": ep.port, "protocol": "TCP"}],
            })
        egress_rules.append({
            "ports": [
                {"port": 53, "protocol": "UDP"},
                {"port": 53, "protocol": "TCP"},
            ],
        })

        policy = {
            "apiVersion": "networking.k8s.io/v1",
            "kind": "NetworkPolicy",
            "metadata": {"name": self._policy_name, "namespace": self._namespace},
            "spec": {
                "podSelector": {
                    "matchLabels": {"sforge-pod": self._handle.name},
                },
                "policyTypes": ["Egress"],
                "egress": egress_rules,
            },
        }

        r = subprocess.run(
            self._kubectl_base + ["apply", "-f", "-"],
            input=json.dumps(policy).encode(),
            capture_output=True,
        )
        if r.returncode != 0:
            raise RuntimeError(
                f"Failed to apply NetworkPolicy {self._policy_name}: "
                f"{r.stderr.decode(errors='replace')}"
            )

        self._applied = True
        self._logger.info(f"K8s NetworkPolicy applied: {self._policy_name}")

    def cleanup(self) -> None:
        if not self._applied:
            return
        try:
            subprocess.run(
                self._kubectl_base + [
                    "delete", "networkpolicy", self._policy_name,
                    "--ignore-not-found",
                ],
                capture_output=True,
                timeout=30,
            )
        except Exception as exc:
            self._logger.warning(f"Failed to delete NetworkPolicy {self._policy_name}: {exc}")
        self._applied = False


class K8sBackend(ContainerBackend):
    """Container backend using Kubernetes via kubectl subprocess."""

    def __init__(
        self,
        namespace: str = "default",
        node_selector: dict[str, str] | None = None,
        image_registry: str = "",
        kubeconfig: str | None = None,
    ) -> None:
        if not image_registry:
            raise RuntimeError(
                "K8s backend requires an image registry (pods cannot use locally-built images). "
                "Set SFORGE_K8S_IMAGE_REGISTRY."
            )
        self._namespace = namespace
        self._kubeconfig = kubeconfig
        self._node_selector = node_selector or {}
        self._image_registry = image_registry.rstrip("/")
        # Build base kubectl command
        self._kubectl_base = ["kubectl", "-n", self._namespace]
        if self._kubeconfig:
            self._kubectl_base += ["--kubeconfig", self._kubeconfig]

        # Verify kubectl is reachable
        r = subprocess.run(
            self._kubectl_base + ["cluster-info"],
            capture_output=True, timeout=10,
        )
        if r.returncode != 0:
            raise RuntimeError(
                f"kubectl cluster-info failed: {r.stderr.decode(errors='replace')}"
            )

    def _kubectl(self, args: list[str], **kwargs) -> subprocess.CompletedProcess:
        return subprocess.run(self._kubectl_base + args, **kwargs)

    @property
    def backend_name(self) -> str:
        return "k8s"

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
        annotations: dict[str, str] | None = None,
        network: bool = True,
    ) -> K8sPodHandle:
        full_image = self._resolve_image(image)
        k8s_name = _sanitize_k8s_name(name)

        env_list = []
        if environment:
            for k, v in environment.items():
                env_list.append({"name": k, "value": v})

        resources = {}
        if cpu_limit is not None or mem_limit is not None:
            req = {}
            lim = {}
            if cpu_limit is not None:
                req["cpu"] = str(cpu_limit)
                lim["cpu"] = str(cpu_limit)
            if mem_limit is not None:
                mem_k8s = _parse_mem_limit(mem_limit)
                req["memory"] = mem_k8s
                lim["memory"] = mem_k8s
            resources = {"requests": req, "limits": lim}

        security_context = {}
        if cap_drop:
            security_context["capabilities"] = {"drop": cap_drop}

        container_spec = {
            "name": "work",
            "image": full_image,
            "imagePullPolicy": "Always",
            "command": ["/bin/sh", "-c", command],
        }
        if env_list:
            container_spec["env"] = env_list
        if resources:
            container_spec["resources"] = resources
        if security_context:
            container_spec["securityContext"] = security_context

        host_aliases = None
        if extra_hosts:
            hosts_by_ip: dict[str, list[str]] = {}
            for hostname, ip in extra_hosts.items():
                if ip == "host-gateway":
                    continue
                hosts_by_ip.setdefault(ip, []).append(hostname)
            if hosts_by_ip:
                host_aliases = [
                    {"ip": ip, "hostnames": hostnames}
                    for ip, hostnames in hosts_by_ip.items()
                ]

        pod_annotations = dict(annotations or {})

        pod = {
            "apiVersion": "v1",
            "kind": "Pod",
            "metadata": {
                "name": k8s_name,
                "namespace": self._namespace,
                "labels": {
                    "app": "sforge",
                    "sforge-pod": k8s_name,
                },
            },
            "spec": {
                "containers": [container_spec],
                "restartPolicy": "Never",
            },
        }
        if pod_annotations:
            pod["metadata"]["annotations"] = pod_annotations
        if self._node_selector:
            pod["spec"]["nodeSelector"] = self._node_selector
        if host_aliases:
            pod["spec"]["hostAliases"] = host_aliases

        r = self._kubectl(
            ["apply", "-f", "-"],
            input=json.dumps(pod).encode(),
            capture_output=True,
        )
        if r.returncode != 0:
            raise RuntimeError(
                f"Failed to create pod {k8s_name}: {r.stderr.decode(errors='replace')}"
            )
        return K8sPodHandle(k8s_name, self._namespace)

    def start_container(self, handle: ContainerHandle) -> None:
        h = self._handle(handle)
        deadline = time.time() + 300
        while time.time() < deadline:
            r = self._kubectl(
                ["get", "pod", h.name, "-o", "json"],
                capture_output=True,
            )
            if r.returncode != 0:
                time.sleep(2)
                continue
            pod = json.loads(r.stdout)
            phase = pod.get("status", {}).get("phase", "")
            if phase == "Running":
                h._pod_uid = pod.get("metadata", {}).get("uid", "")
                h._ip = pod.get("status", {}).get("podIP")
                return
            if phase in ("Failed", "Succeeded"):
                raise RuntimeError(f"Pod {h.name} entered terminal phase: {phase}")
            time.sleep(2)
        raise RuntimeError(f"Pod {h.name} did not become Running within 300s")

    def cleanup_container(
        self, handle: ContainerHandle | None, logger: logging.Logger | None = None,
    ) -> None:
        if handle is None:
            return

        h = self._handle(handle)
        old_handler = None
        try:
            old_handler = signal.signal(signal.SIGINT, signal.SIG_IGN)
        except ValueError:
            pass

        log_info = logger.info if logger else print
        log_error = logger.error if logger else print

        try:
            log_info(f"Deleting pod {h.name}...")
            self._kubectl(
                ["delete", "pod", h.name, "--grace-period=15", "--ignore-not-found"],
                capture_output=True,
                timeout=60,
            )
            log_info(f"Pod {h.name} deleted.")
        except Exception as e:
            log_error(f"Failed to delete pod {h.name}: {e}")

        policy_name = f"sforge-iso-{h.name}"[:63].rstrip("-")
        try:
            self._kubectl(
                ["delete", "networkpolicy", policy_name, "--ignore-not-found"],
                capture_output=True,
                timeout=30,
            )
        except Exception:
            pass

        if old_handler is not None:
            try:
                signal.signal(signal.SIGINT, old_handler)
            except ValueError:
                pass

    def container_exists(self, name: str, image_key: str | None = None) -> bool:
        k8s_name = _sanitize_k8s_name(name)
        r = self._kubectl(
            ["get", "pod", k8s_name],
            capture_output=True,
        )
        return r.returncode == 0

    def remove_container_by_name(
        self, name: str, image_key: str | None = None,
    ) -> None:
        k8s_name = _sanitize_k8s_name(name)
        self._kubectl(
            ["delete", "pod", k8s_name, "--grace-period=0", "--ignore-not-found"],
            capture_output=True,
        )

    # --- Image ---

    def image_exists(self, image_key: str) -> bool:
        return registry_has(self._resolve_image(image_key))

    # --- File transfer ---

    def copy_to_container(
        self, handle: ContainerHandle, src: Path, dst: PurePosixPath,
    ) -> None:
        h = self._handle(handle)

        self._exec_simple(h, f"mkdir -p {dst.parent}")

        buf = io.BytesIO()
        with tarfile.open(fileobj=buf, mode="w") as tar:
            tar.add(str(src), arcname=str(dst))
        buf.seek(0)
        tar_bytes = buf.read()

        proc = subprocess.Popen(
            self._kubectl_base + [
                "exec", "-i", h.name, "-c", "work", "--",
                "tar", "xf", "-", "-C", "/",
            ],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        proc.communicate(input=tar_bytes, timeout=120)

    def copy_from_container(
        self, handle: ContainerHandle, src: PurePosixPath,
    ) -> bytes:
        h = self._handle(handle)
        r = subprocess.run(
            self._kubectl_base + [
                "exec", h.name, "-c", "work", "--",
                "tar", "cf", "-", str(src),
            ],
            capture_output=True,
            timeout=120,
        )
        return r.stdout

    def write_to_container(
        self, handle: ContainerHandle, data: str, dst: PurePosixPath,
    ) -> None:
        h = self._handle(handle)
        self._exec_simple(h, f"mkdir -p {dst.parent}")

        buf = io.BytesIO()
        with tarfile.open(fileobj=buf, mode="w") as tar:
            data_bytes = data.encode("utf-8")
            info = tarfile.TarInfo(name=str(dst))
            info.size = len(data_bytes)
            tar.addfile(info, io.BytesIO(data_bytes))
        buf.seek(0)

        proc = subprocess.Popen(
            self._kubectl_base + [
                "exec", "-i", h.name, "-c", "work", "--",
                "tar", "xf", "-", "-C", "/",
            ],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        proc.communicate(input=buf.read(), timeout=120)

    # --- Exec ---

    def exec_run(
        self,
        handle: ContainerHandle,
        cmd: str | list[str],
        *,
        workdir: str | None = None,
        environment: dict[str, str] | None = None,
        detach: bool = False,
    ) -> ExecResult:
        h = self._handle(handle)
        shell_cmd = self._build_shell_cmd(cmd, workdir=workdir, environment=environment)

        if detach:
            thread = threading.Thread(
                target=self._exec_simple, args=(h, shell_cmd), daemon=True,
            )
            thread.start()
            return ExecResult(output="", exit_code=0)

        output = self._exec_simple(h, shell_cmd)
        return ExecResult(output=output, exit_code=0)

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
        output, exit_code, timed_out, elapsed = self._exec_streaming(
            handle, cmd, timeout,
            log_file=log_file, workdir=workdir,
            environment=environment, stream_to_stdout=stream_to_stdout,
            shutdown_event=shutdown_event, log_append=log_append,
            on_chunk=on_chunk,
        )
        return StreamingExecResult(
            output=output, exit_code=exit_code,
            timed_out=timed_out, elapsed_seconds=elapsed,
        )

    def exec_run_with_exit_code(
        self,
        handle: ContainerHandle,
        cmd: str | list[str],
        timeout: int | None = 60,
        *,
        workdir: str | None = None,
        environment: dict[str, str] | None = None,
    ) -> StreamingExecResult:
        output, exit_code, timed_out, elapsed = self._exec_streaming(
            handle, cmd, timeout,
            workdir=workdir, environment=environment,
        )
        return StreamingExecResult(
            output=output, exit_code=exit_code,
            timed_out=timed_out, elapsed_seconds=elapsed,
        )

    def _exec_streaming(
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
    ) -> tuple[str, int, bool, float]:
        h = self._handle(handle)
        shell_cmd = self._build_shell_cmd(cmd, workdir=workdir, environment=environment)
        exit_marker = "__SFORGE_EXIT__"
        wrapped = f'({shell_cmd}); echo "{exit_marker}$?"'

        chunks: list[bytes] = []
        proc_ref: list[subprocess.Popen] = []
        timed_out = False
        log_fh = None

        try:
            if log_file:
                log_file.parent.mkdir(parents=True, exist_ok=True)
                log_fh = open(log_file, "ab" if log_append else "wb")

            def run_command():
                try:
                    proc = subprocess.Popen(
                        self._kubectl_base + [
                            "exec", h.name, "-c", "work", "--",
                            "/bin/sh", "-c", wrapped,
                        ],
                        stdout=subprocess.PIPE,
                        stderr=subprocess.STDOUT,
                        stdin=subprocess.DEVNULL,
                    )
                    proc_ref.append(proc)
                    while True:
                        chunk = proc.stdout.read(4096)
                        if not chunk:
                            break
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
                    proc.wait()
                except Exception:
                    pass

            thread = threading.Thread(target=run_command, daemon=True)
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

        elapsed = time.time() - start_time

        if thread.is_alive():
            timed_out = True
            # Kill the kubectl exec process
            if proc_ref:
                try:
                    proc_ref[0].kill()
                except Exception:
                    pass
            # Do NOT kill processes inside the pod — the caller needs the
            # container to stay Running for post-timeout archive extraction.
            # Auto-eval is stopped by stop_event.set() in the caller.
            exit_code = -1
        else:
            exit_code = -1

        output = b"".join(chunks).decode(errors="replace")
        if exit_marker in output:
            idx = output.rfind(exit_marker)
            code_str = output[idx + len(exit_marker):].strip().split("\n")[0].strip()
            try:
                exit_code = int(code_str)
            except ValueError:
                pass
            output = output[:idx]

        return output, exit_code, timed_out, elapsed

    # --- Inspection ---

    def get_container_ip(self, handle: ContainerHandle) -> str:
        h = self._handle(handle)
        r = self._kubectl(
            ["get", "pod", h.name, "-o", "jsonpath={.status.podIP}"],
            capture_output=True,
        )
        ip = r.stdout.decode().strip()
        if not ip:
            raise RuntimeError(f"Pod {h.name} has no IP")
        h._ip = ip
        return ip

    def get_container_gateway_ip(self, handle: ContainerHandle) -> str | None:
        return None

    # --- Network isolation ---

    def create_network_isolation(
        self,
        handle: ContainerHandle,
        allowed_endpoints: list,
        logger: logging.Logger,
    ) -> NetworkIsolationStrategy:
        h = self._handle(handle)
        return K8sNetworkIsolation(
            h, allowed_endpoints, self._kubectl_base, self._namespace, logger,
        )

    # --- Internal helpers ---

    def _resolve_image(self, image: str) -> str:
        if self._image_registry and not image.startswith(self._image_registry):
            return remote_ref(self._image_registry, image)
        return image

    def _exec_simple(self, h: K8sPodHandle, cmd: str) -> str:
        r = subprocess.run(
            self._kubectl_base + [
                "exec", h.name, "-c", "work", "--",
                "/bin/sh", "-c", cmd,
            ],
            capture_output=True,
            timeout=300,
        )
        return r.stdout.decode(errors="replace") + r.stderr.decode(errors="replace")

    @staticmethod
    def _build_shell_cmd(
        cmd: str | list[str],
        *,
        workdir: str | None = None,
        environment: dict[str, str] | None = None,
    ) -> str:
        if isinstance(cmd, list):
            shell_cmd = " ".join(shlex.quote(c) for c in cmd)
        else:
            shell_cmd = cmd

        parts = []
        if environment:
            for k, v in environment.items():
                parts.append(f"export {k}={shlex.quote(v)}")
        if workdir:
            parts.append(f"cd {workdir}")
        parts.append(shell_cmd)
        return " && ".join(parts)

    @staticmethod
    def _handle(handle: ContainerHandle) -> K8sPodHandle:
        if isinstance(handle, K8sPodHandle):
            return handle
        raise TypeError(f"Expected K8sPodHandle, got {type(handle).__name__}")


def _sanitize_k8s_name(name: str) -> str:
    """Convert a Docker-style container name to a valid K8s resource name.

    For names following the 'sforge.{role}.{task_id}.{run_id}' pattern,
    truncate task_id to 15 chars if the result would exceed 63 chars.
    """
    parts = name.split(".")
    if len(parts) == 4 and parts[0] == "sforge":
        role, task_id, run_id = parts[1], parts[2], parts[3]
        task_id = task_id[:15].rstrip("-").rstrip("_")
        name = f"{role}.{task_id}.{run_id}"
    sanitized = name.lower().replace("_", "-").replace(".", "-")
    sanitized = sanitized.strip("-")[:63].rstrip("-")
    return sanitized


def _parse_mem_limit(mem: str) -> str:
    """Convert Docker-style mem limit ('8g', '512m') to K8s format ('8Gi', '512Mi')."""
    mem = mem.strip().lower()
    if mem.endswith("g"):
        return mem[:-1] + "Gi"
    if mem.endswith("m"):
        return mem[:-1] + "Mi"
    if mem.endswith("k"):
        return mem[:-1] + "Ki"
    return mem
