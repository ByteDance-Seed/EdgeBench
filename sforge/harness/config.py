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

from __future__ import annotations

import os
from dataclasses import dataclass, field, fields
from pathlib import Path

from sforge.harness.constants import DEFAULT_BENCHMARK_DIR, LOG_DIR
from sforge.harness.task_spec import Benchmark, load_benchmark


@dataclass
class SForgeConfig:
    """Configuration for SForge harness. All fields injectable via SFORGE_* env vars."""

    # Network proxy
    http_proxy: str | None = None
    https_proxy: str | None = None
    no_proxy: str | None = None

    # Mirrors used on the host when building agent bundles
    nodejs_mirror_url: str | None = None

    # Agent configuration
    agent_api_key: str | None = None
    agent_api_base_url: str | None = None
    agent_model: str | None = None
    # Reasoning effort, canonical vocabulary "low"/"medium"/"high"/"max";
    # each agent translates to its native mechanism (env var, CLI flag or
    # config option) and maps aliases (e.g. max -> xhigh).  None means the
    # agent's own default — existing runs were recorded under that behavior,
    # so never default this to an explicit level.
    agent_effort: str | None = None
    agent_timeout: int | None = None
    agent_extra_env: dict[str, str] = field(default_factory=dict)

    # Judge extra environment (for LLM-based graders etc.)
    judge_extra_env: dict[str, str] = field(default_factory=dict)

    # Container resource limits (work vs judge independently)
    work_cpu_limit: int | None = None       # CPUs for work containers (e.g. 4)
    work_mem_limit: str | None = None       # memory for work containers (e.g. "8g")
    judge_cpu_limit: int | None = None      # CPUs for judge containers
    judge_mem_limit: str | None = None      # memory for judge containers

    # Registry prefix for pre-built images (sforge pull/push); default: the benchmark's
    registry: str | None = None

    # Container backend: "docker", "k8s" or "e2b"
    backend: str = "docker"

    # K8s backend settings
    k8s_namespace: str = "default"
    k8s_node_selector: dict[str, str] = field(default_factory=dict)
    k8s_image_registry: str | None = None   # default: the pull registry
    k8s_kubeconfig: str | None = None

    # e2b backend settings (endpoint/credentials come from the standard
    # E2B_API_KEY / E2B_API_URL / E2B_DOMAIN env vars read by the e2b SDK)
    e2b_template_map: dict[str, str] = field(default_factory=dict)
    e2b_template_namespace: str | None = None
    # Paths
    log_dir: Path = field(default_factory=lambda: LOG_DIR)
    # The benchmark directory (benchmark.toml, tasks/, bases/)
    benchmark_dir: Path = DEFAULT_BENCHMARK_DIR

    @property
    def benchmark(self) -> Benchmark:
        return load_benchmark(self.benchmark_dir)

    @property
    def image_registry(self) -> str | None:
        return self.registry or self.benchmark.registry

    @property
    def pod_image_registry(self) -> str | None:
        return self.k8s_image_registry or self.image_registry


def load_config(cli_overrides: dict | None = None) -> SForgeConfig:
    """Load config from: defaults < env vars (SFORGE_*) < CLI flags."""
    config = SForgeConfig()

    # Map of config field -> env var names to try (in priority order)
    _env_map = {
        "http_proxy": ["SFORGE_HTTP_PROXY", "HTTP_PROXY", "http_proxy"],
        "https_proxy": ["SFORGE_HTTPS_PROXY", "HTTPS_PROXY", "https_proxy"],
        "no_proxy": ["SFORGE_NO_PROXY", "NO_PROXY", "no_proxy"],
        "nodejs_mirror_url": ["SFORGE_NODEJS_MIRROR_URL"],
        "agent_api_key": ["SFORGE_AGENT_API_KEY"],
        "agent_api_base_url": ["SFORGE_AGENT_API_BASE_URL"],
        "registry": ["SFORGE_REGISTRY"],
        "k8s_namespace": ["SFORGE_K8S_NAMESPACE"],
        "k8s_image_registry": ["SFORGE_K8S_IMAGE_REGISTRY"],
        "k8s_kubeconfig": ["SFORGE_K8S_KUBECONFIG"],
        "e2b_template_namespace": ["SFORGE_E2B_TEMPLATE_NAMESPACE"],
        "log_dir": ["SFORGE_LOG_DIR"],
        "benchmark_dir": ["SFORGE_BENCHMARK"],
    }

    for field_name, env_keys in _env_map.items():
        for env_key in env_keys:
            val = os.environ.get(env_key)
            if val is not None:
                f = next(f for f in fields(config) if f.name == field_name)
                if f.type in ("Path", "Path | None"):
                    setattr(config, field_name, Path(val))
                elif f.type in ("int", "int | None"):
                    setattr(config, field_name, int(val))
                else:
                    setattr(config, field_name, val)
                break

    # Parse SFORGE_AGENT_EXTRA_ENV: "KEY1=VAL1,KEY2=VAL2"
    extra_env_str = os.environ.get("SFORGE_AGENT_EXTRA_ENV", "")
    if extra_env_str:
        for item in extra_env_str.split(","):
            item = item.strip()
            if "=" in item:
                k, v = item.split("=", 1)
                config.agent_extra_env[k.strip()] = v.strip()

    # Parse SFORGE_JUDGE_EXTRA_ENV: "KEY1=VAL1,KEY2=VAL2"
    judge_env_str = os.environ.get("SFORGE_JUDGE_EXTRA_ENV", "")
    if judge_env_str:
        for item in judge_env_str.split(","):
            item = item.strip()
            if "=" in item:
                k, v = item.split("=", 1)
                config.judge_extra_env[k.strip()] = v.strip()

    # Parse SFORGE_K8S_NODE_SELECTOR: "key1=val1,key2=val2"
    k8s_ns_str = os.environ.get("SFORGE_K8S_NODE_SELECTOR", "")
    if k8s_ns_str:
        for item in k8s_ns_str.split(","):
            item = item.strip()
            if "=" in item:
                k, v = item.split("=", 1)
                config.k8s_node_selector[k.strip()] = v.strip()

    # SFORGE_E2B_TEMPLATE_MAP: "image_key=template,..." or a JSON file path
    if os.environ.get("SFORGE_E2B_TEMPLATE_MAP"):
        from sforge.harness.backend.e2b_backend import template_map_from_env
        config.e2b_template_map = template_map_from_env()
    # Override from CLI flags
    if cli_overrides:
        for k, v in cli_overrides.items():
            if v is not None and hasattr(config, k):
                if k in ("log_dir", "benchmark_dir"):
                    v = Path(v)
                setattr(config, k, v)

    return config


def sanitize_e2b_proxy_env(env: dict[str, str]) -> None:
    """Remove host-only proxies before sending an environment to E2B.

    Generic ``HTTP_PROXY``/``HTTPS_PROXY`` values are commonly inherited from
    the machine running SForge and may point at private hosts that a remote
    Sandbox cannot reach. Only the explicit SForge variants opt a proxy into
    E2B.
    """
    proxy_groups = (
        ("SFORGE_HTTP_PROXY", "http_proxy", "HTTP_PROXY"),
        ("SFORGE_HTTPS_PROXY", "https_proxy", "HTTPS_PROXY"),
    )
    for explicit_name, *runtime_names in proxy_groups:
        if not os.environ.get(explicit_name):
            for name in runtime_names:
                env.pop(name, None)


def resource_env(cpu_limit: int | None, mem_limit: str | None) -> dict[str, str]:
    """Tell code in a container what it was given: under a CPU quota, nproc
    and os.cpu_count() still report the host's cores."""
    env = {}
    if cpu_limit is not None:
        env["SFORGE_CPUS"] = str(cpu_limit)
    if mem_limit is not None:
        env["SFORGE_MEMORY"] = str(mem_limit)
    return env


def create_backend_from_config(config: SForgeConfig, docker_client=None):
    """Create a ContainerBackend from config."""
    from sforge.harness.backend.factory import create_backend

    return create_backend(
        config.backend,
        docker_client=docker_client,
        k8s_namespace=config.k8s_namespace,
        k8s_node_selector=config.k8s_node_selector,
        k8s_image_registry=config.pod_image_registry if config.backend == "k8s" else None,
        k8s_kubeconfig=config.k8s_kubeconfig,
        e2b_template_map=config.e2b_template_map or None,
        e2b_template_namespace=config.e2b_template_namespace,
    )
