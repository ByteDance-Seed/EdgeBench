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

from sforge.harness.constants import LOG_DIR, TASKS_DIR


@dataclass
class SForgeConfig:
    """Configuration for SForge harness. All fields injectable via SFORGE_* env vars."""

    # Network proxy
    http_proxy: str | None = None
    https_proxy: str | None = None
    no_proxy: str | None = None

    # Package mirrors
    pypi_index_url: str | None = None
    maven_mirror_url: str | None = None
    go_proxy: str | None = None
    nodejs_mirror_url: str | None = None
    npm_registry_url: str | None = None
    apt_mirror_url: str | None = None

    # Agent configuration
    agent_api_key: str | None = None
    agent_api_base_url: str | None = None
    agent_model: str | None = None
    agent_timeout: int | None = None
    agent_extra_env: dict[str, str] = field(default_factory=dict)

    # Claude Code cache optimization — suppress the random cch attribution
    # header and dynamic system prompt sections that break prompt caching on
    # third-party API proxies.  Enable via SFORGE_CLAUDE_CACHE_OPT=1.
    claude_cache_opt: bool = False

    # Judge extra environment (for LLM-based graders etc.)
    judge_extra_env: dict[str, str] = field(default_factory=dict)

    # Git credentials (for private repos in setup_cmds)
    git_user: str | None = None
    git_token: str | None = None

    # Container resource limits (work vs judge independently)
    work_cpu_limit: int | None = None       # CPUs for work containers (e.g. 4)
    work_mem_limit: str | None = None       # memory for work containers (e.g. "8g")
    judge_cpu_limit: int | None = None      # CPUs for judge containers
    judge_mem_limit: str | None = None      # memory for judge containers

    # Docker build extra hosts (DNS overrides)
    extra_hosts: dict[str, str] | None = None

    # Remote container registry
    registry: str | None = None

    # Container backend: "docker", "k8s" or "e2b"
    backend: str = "docker"

    # K8s backend settings
    k8s_namespace: str = "default"
    k8s_node_selector: dict[str, str] = field(default_factory=dict)
    k8s_image_registry: str = ""
    k8s_kubeconfig: str | None = None

    # e2b backend settings (endpoint/credentials come from the standard
    # E2B_API_KEY / E2B_API_URL / E2B_DOMAIN env vars read by the e2b SDK)
    e2b_template_map: dict[str, str] = field(default_factory=dict)
    e2b_sandbox_ttl: int | None = None
    e2b_judge_access_token: str | None = None
    # Paths
    log_dir: Path = field(default_factory=lambda: LOG_DIR)
    tasks_dir: Path = field(default_factory=lambda: TASKS_DIR)


def load_config(cli_overrides: dict | None = None) -> SForgeConfig:
    """Load config from: defaults < env vars (SFORGE_*) < CLI flags."""
    config = SForgeConfig()

    # Map of config field -> env var names to try (in priority order)
    _env_map = {
        "http_proxy": ["SFORGE_HTTP_PROXY", "HTTP_PROXY", "http_proxy"],
        "https_proxy": ["SFORGE_HTTPS_PROXY", "HTTPS_PROXY", "https_proxy"],
        "no_proxy": ["SFORGE_NO_PROXY", "NO_PROXY", "no_proxy"],
        "pypi_index_url": ["SFORGE_PYPI_INDEX_URL"],
        "maven_mirror_url": ["SFORGE_MAVEN_MIRROR_URL"],
        "go_proxy": ["SFORGE_GO_PROXY"],
        "nodejs_mirror_url": ["SFORGE_NODEJS_MIRROR_URL"],
        "npm_registry_url": ["SFORGE_NPM_REGISTRY_URL"],
        "apt_mirror_url": ["SFORGE_APT_MIRROR_URL"],
        "agent_api_key": ["SFORGE_AGENT_API_KEY"],
        "agent_api_base_url": ["SFORGE_AGENT_API_BASE_URL"],
        "agent_model": ["SFORGE_AGENT_MODEL"],
        "agent_timeout": ["SFORGE_AGENT_TIMEOUT"],
        "git_user": ["SFORGE_GIT_USER"],
        "git_token": ["SFORGE_GIT_TOKEN"],
        "registry": ["SFORGE_REGISTRY"],
        "backend": ["SFORGE_BACKEND"],
        "k8s_namespace": ["SFORGE_K8S_NAMESPACE"],
        "k8s_image_registry": ["SFORGE_K8S_IMAGE_REGISTRY"],
        "k8s_kubeconfig": ["SFORGE_K8S_KUBECONFIG"],
        "e2b_judge_access_token": ["SFORGE_JUDGE_ACCESS_TOKEN"],
        "work_cpu_limit": ["SFORGE_WORK_CPU_LIMIT"],
        "work_mem_limit": ["SFORGE_WORK_MEM_LIMIT"],
        "log_dir": ["SFORGE_LOG_DIR"],
        "tasks_dir": ["SFORGE_TASKS_DIR"],
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

    # SFORGE_CLAUDE_CACHE_OPT: truthy value enables cache optimization
    if os.environ.get("SFORGE_CLAUDE_CACHE_OPT", "").strip() not in ("", "0", "false", "no"):
        config.claude_cache_opt = True

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

    # Parse SFORGE_EXTRA_HOSTS: "host1:ip1,host2:ip2"
    extra_hosts_str = os.environ.get("SFORGE_EXTRA_HOSTS", "")
    if extra_hosts_str:
        config.extra_hosts = {}
        for item in extra_hosts_str.split(","):
            item = item.strip()
            if ":" in item:
                host, ip = item.rsplit(":", 1)
                config.extra_hosts[host.strip()] = ip.strip()

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
    e2b_ttl = os.environ.get("SFORGE_E2B_SANDBOX_TTL")
    if e2b_ttl:
        config.e2b_sandbox_ttl = int(e2b_ttl)
    # Override from CLI flags
    if cli_overrides:
        for k, v in cli_overrides.items():
            if v is not None and hasattr(config, k):
                if k in ("log_dir", "tasks_dir"):
                    v = Path(v)
                setattr(config, k, v)

    return config


def get_env_directives(config: SForgeConfig) -> str:
    """Generate Dockerfile directives for build-time proxy/mirror injection.

    Proxy vars (HTTP_PROXY, etc.) use only ARG so they are available during
    build but NOT baked into the final image.  Docker automatically exposes
    the predefined proxy ARGs to RUN commands.

    Package-mirror vars (PIP_INDEX_URL, etc.) are not Docker-predefined, so
    they need an explicit ARG+ENV pair to be visible in RUN commands.  The
    ENV is intentionally set to the *ARG reference* so that if the build-arg
    is empty the ENV is simply unset.
    """
    lines: list[str] = []

    # Proxy: Docker predefined build args — just declare ARG, Docker handles the rest.
    # These will NOT persist in the final image.
    if config.http_proxy:
        lines.append("ARG http_proxy")
        lines.append("ARG HTTP_PROXY")
    if config.https_proxy:
        lines.append("ARG https_proxy")
        lines.append("ARG HTTPS_PROXY")
    if config.no_proxy:
        lines.append("ARG no_proxy")
        lines.append("ARG NO_PROXY")

    # Package mirrors: ARG only — available during build but NOT persisted in image.
    # Docker ARGs are visible to subsequent RUN commands in the same build stage.
    if config.pypi_index_url:
        lines.append(f"ARG PIP_INDEX_URL={config.pypi_index_url}")
    if config.maven_mirror_url:
        lines.append(f"ARG MAVEN_MIRROR_URL={config.maven_mirror_url}")
    if config.go_proxy:
        lines.append(f"ARG GOPROXY={config.go_proxy}")

    return "\n".join(lines)


def get_build_args(config: SForgeConfig) -> dict[str, str]:
    """Generate Docker build args for proxy/mirror passthrough during image builds."""
    args: dict[str, str] = {}
    if config.http_proxy:
        args["HTTP_PROXY"] = config.http_proxy
        args["http_proxy"] = config.http_proxy
    if config.https_proxy:
        args["HTTPS_PROXY"] = config.https_proxy
        args["https_proxy"] = config.https_proxy
    if config.no_proxy:
        args["NO_PROXY"] = config.no_proxy
        args["no_proxy"] = config.no_proxy
    if config.pypi_index_url:
        args["PIP_INDEX_URL"] = config.pypi_index_url
    if config.maven_mirror_url:
        args["MAVEN_MIRROR_URL"] = config.maven_mirror_url
    if config.go_proxy:
        args["GOPROXY"] = config.go_proxy
    return args


def get_build_secrets(config: SForgeConfig) -> dict[str, str]:
    """Return {secret_id: value} for BuildKit --mount=type=secret."""
    secrets: dict[str, str] = {}
    if config.git_user:
        secrets["git_user"] = config.git_user
    if config.git_token:
        secrets["git_token"] = config.git_token
    return secrets


def get_container_env(config: SForgeConfig, include_judge_extra: bool = False) -> dict[str, str]:
    """Generate environment variables dict for container runtime (docker create --env)."""
    env: dict[str, str] = {}
    if config.http_proxy:
        env["http_proxy"] = config.http_proxy
        env["HTTP_PROXY"] = config.http_proxy
    if config.https_proxy:
        env["https_proxy"] = config.https_proxy
        env["HTTPS_PROXY"] = config.https_proxy
    if config.no_proxy:
        env["no_proxy"] = config.no_proxy
        env["NO_PROXY"] = config.no_proxy
    if config.agent_api_key:
        env["ANTHROPIC_API_KEY"] = config.agent_api_key
    if config.agent_api_base_url:
        env["ANTHROPIC_BASE_URL"] = config.agent_api_base_url
    if include_judge_extra and config.judge_extra_env:
        env.update(config.judge_extra_env)
    return env


def sanitize_e2b_proxy_env(
    env: dict[str, str], *, internet: bool = True,
) -> None:
    """Remove host-only proxies before sending an environment to E2B.

    Generic ``HTTP_PROXY``/``HTTPS_PROXY`` values are commonly inherited from
    the machine running SForge and may point at private hosts that a remote
    Sandbox cannot reach. Only the explicit SForge variants opt a proxy into
    E2B; isolated Work Sandboxes never receive one.
    """
    proxy_groups = (
        ("SFORGE_HTTP_PROXY", "http_proxy", "HTTP_PROXY"),
        ("SFORGE_HTTPS_PROXY", "https_proxy", "HTTPS_PROXY"),
    )
    for explicit_name, *runtime_names in proxy_groups:
        if not internet or not os.environ.get(explicit_name):
            for name in runtime_names:
                env.pop(name, None)


def get_container_resource_kwargs(
    config_cpu_limit: int | None,
    config_mem_limit: str | None,
    task_cpu_limit: int | None = None,
    task_mem_limit: str | None = None,
) -> dict:
    """Return Docker container create kwargs for CPU/memory limits.

    Priority: config (CLI/env/experiment) > task.json per-spec defaults.
    """
    kwargs: dict = {}
    cpu = config_cpu_limit if config_cpu_limit is not None else task_cpu_limit
    mem = config_mem_limit if config_mem_limit is not None else task_mem_limit
    if cpu is not None:
        kwargs["nano_cpus"] = int(cpu * 1e9)
    if mem is not None:
        kwargs["mem_limit"] = mem
    return kwargs


def create_backend_from_config(config: SForgeConfig, docker_client=None):
    """Create a ContainerBackend from config."""
    from sforge.harness.backend.factory import create_backend

    return create_backend(
        config.backend,
        docker_client=docker_client,
        k8s_namespace=config.k8s_namespace,
        k8s_node_selector=config.k8s_node_selector,
        k8s_image_registry=config.k8s_image_registry,
        k8s_kubeconfig=config.k8s_kubeconfig,
        e2b_template_map=config.e2b_template_map or None,
        e2b_sandbox_ttl=config.e2b_sandbox_ttl,
    )
