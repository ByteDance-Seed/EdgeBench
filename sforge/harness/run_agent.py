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

"""Agent execution with iterative evaluation via judge server.

The agent runs in a work container with:
- sforge-submit script for on-demand evaluation
- Stop hook to prevent premature exit (unconditional block)
- Auto-eval runs on the host side (invisible to agent)

Architecture:
    Host: sforge serve (judge HTTP server, started separately)
          + auto-eval thread (extracts code from container, submits to judge)
    Container: Agent + sforge-submit (curl-based)
    Communication: HTTP (container → host judge server)
"""

from __future__ import annotations

import io
import json
import shlex
import shutil
import signal
import tarfile as _tarfile
import threading
import time
import traceback
import uuid
from dataclasses import dataclass
from pathlib import Path, PurePosixPath
from urllib.parse import urlparse

import requests

from sforge.harness.agent import Agent
from sforge.harness.backend import ContainerBackend, ContainerHandle
from sforge.harness.config import SForgeConfig, resource_env, sanitize_e2b_proxy_env
from sforge.harness.constants import CONTAINER_DIR, get_admin_secret
from sforge.harness.docker_build import (
    close_logger,
    setup_logger,
)
from sforge.harness.llm_gateway import PLACEHOLDER_KEY as GATEWAY_PLACEHOLDER_KEY
from sforge.harness.llm_gateway import ROUTE_PREFIX as GATEWAY_ROUTE
from sforge.harness.network_isolation import is_ip_address, resolve_hostname
from sforge.harness.evolve_scripts import (
    generate_evolve_prompt,
    generate_game_prompt,
    generate_submit_script,
)
from sforge.harness.tarutil import safe_extractall
from sforge.harness.task_spec import TaskSpec

# How often native agent session files are mirrored into the run log dir.
SESSION_SYNC_INTERVAL = 60


@dataclass
class RunResult:
    """Result of running an agent on a task."""

    archive: bytes = b""
    best_score_0_100: float | None = None
    best_score: float | None = None
    best_round: str = ""
    total_rounds: int = 0
    agent_submissions: int = 0
    auto_submissions: int = 0
    agent_output: str = ""
    timed_out: bool = False
    runtime_seconds: float = 0.0
    resume_count: int = 0
    usage: dict | None = None  # LLM gateway totals (tokens, requests, by model)

    def to_dict(self) -> dict:
        d = {
            "best_score_0_100": self.best_score_0_100,
            "best_round": self.best_round,
            "total_rounds": self.total_rounds,
            "agent_submissions": self.agent_submissions,
            "auto_submissions": self.auto_submissions,
            "timed_out": self.timed_out,
            "runtime_seconds": self.runtime_seconds,
            "archive_size_bytes": len(self.archive),
            "resume_count": self.resume_count,
        }
        if self.best_score is not None:
            d["best_score"] = self.best_score
        if self.usage is not None:
            d["usage"] = self.usage
        return d


# ---------------------------------------------------------------------------
# Environment and command helpers
# ---------------------------------------------------------------------------


def _build_agent_env(
    agent: Agent,
    model: str | None = None,
) -> dict[str, str]:
    """Build environment variables dict for an agent container."""
    config = agent._config
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
        env[agent.api_key_env] = config.agent_api_key

    if config.agent_api_base_url and agent.api_base_env:
        env[agent.api_base_env] = config.agent_api_base_url

    effective_model = model or config.agent_model or agent.default_model
    if effective_model and agent.model_env:
        env[agent.model_env] = effective_model

    env.update(config.agent_extra_env)

    agent.augment_env(env, model)

    return env


# ---------------------------------------------------------------------------
# Container setup helpers
# ---------------------------------------------------------------------------


def _install_tools(
    backend: ContainerBackend,
    handle: ContainerHandle,
    task_spec: TaskSpec,
    agent: Agent,
    log_dir: Path,
    logger,
    disable_stop_hook: bool = False,
) -> None:
    """Install sforge-submit and agent stop hooks."""

    # 1. Install sforge-submit script
    submit_script = generate_submit_script(
        task_spec.cwd, task_spec.submit_paths, task_spec.submit_exclude,
    )
    local_submit = log_dir / "_sforge-submit.sh"
    local_submit.write_text(submit_script)
    backend.copy_to_container(
        handle, local_submit, PurePosixPath("/usr/local/bin/sforge-submit")
    )
    backend.exec_run(handle, "chmod a+x /usr/local/bin/sforge-submit")
    logger.info("Installed sforge-submit script")

    # 2. Install agent-specific stop hook (unless disabled)
    if not disable_stop_hook:
        agent.install_stop_hook(backend, handle, log_dir, logger)
    else:
        logger.info("Stop hook disabled by flag")


def _extract_archive_from_container(
    backend: ContainerBackend,
    handle: ContainerHandle,
    task_spec: TaskSpec,
    *,
    shutdown_event: threading.Event | None = None,
) -> bytes:
    """Extract the current submission archive from a running work container."""
    remote_archive = CONTAINER_DIR / f"submission-{uuid.uuid4().hex}.tar.gz"
    path_checks = "\n".join(
        "if [[ -e {path} || -L {path} ]]; then "
        "submit_paths+=({path}); fi".format(path=shlex.quote(path))
        for path in task_spec.submit_paths
    )
    excludes = " ".join(
        shlex.quote(f"--exclude={pattern}")
        for pattern in task_spec.submit_exclude
    )
    tar_cmd = f"""
cd -- {shlex.quote(task_spec.cwd)} || exit $?
submit_paths=()
{path_checks}
if (( ${{#submit_paths[@]}} )); then
    tar czf {shlex.quote(str(remote_archive))} --exclude=.git {excludes} -- "${{submit_paths[@]}}"
else
    tar czf {shlex.quote(str(remote_archive))} --files-from /dev/null
fi
"""
    return _tar_out_of_container(
        backend, handle, tar_cmd, remote_archive, "submission archive",
        shutdown_event=shutdown_event,
    )


def _tar_out_of_container(
    backend: ContainerBackend,
    handle: ContainerHandle,
    tar_cmd: str,
    remote: PurePosixPath,
    what: str,
    *,
    shutdown_event: threading.Event | None = None,
) -> bytes:
    """Run *tar_cmd* (which writes *remote*) in the container, copy the file
    out and return its bytes. The remote file is removed afterwards."""
    try:
        result = backend.exec_run_with_exit_code(
            handle, ["/bin/bash", "-c", tar_cmd], timeout=300,
        )
        if result.timed_out:
            raise RuntimeError(f"Timed out while creating the {what}")
        if result.exit_code != 0:
            raise RuntimeError(f"Could not create the {what}: " + result.output[-4000:])
        if backend.backend_name == "e2b":
            raw = backend.copy_from_container(
                handle, remote, shutdown_event=shutdown_event,
            )
        else:
            raw = backend.copy_from_container(handle, remote)
    finally:
        try:
            backend.exec_run(handle, ["rm", "-f", str(remote)])
        except Exception:
            pass
    with _tarfile.open(fileobj=io.BytesIO(raw)) as outer:
        members = [member for member in outer.getmembers() if member.isfile()]
        if len(members) != 1:
            raise RuntimeError(
                f"Unexpected {what} wrapper: expected 1 file, got {len(members)}"
            )
        source = outer.extractfile(members[0])
        if source is None:
            raise RuntimeError(f"Could not read the {what} wrapper")
        return source.read()


def _sync_agent_sessions(
    backend: ContainerBackend,
    handle: ContainerHandle,
    agent: Agent,
    log_dir: Path,
    shutdown_event: threading.Event | None = None,
) -> None:
    """Mirror the agent's native session files into ``log_dir/sessions``
    (container paths kept, e.g. ``sessions/root/.claude/projects/...``).

    These JSONL transcripts are the source of truth for trajectories and
    token usage; ``agent_output.txt`` (stdout) is only a log.
    """
    if not agent.session_dirs:
        return
    rel = " ".join(shlex.quote(d.lstrip("/")) for d in agent.session_dirs)
    probe = f'cd / && for d in {rel}; do [ -e "$d" ] && exit 0; done; exit 1'
    if backend.exec_run(handle, ["/bin/sh", "-c", probe]).exit_code != 0:
        return  # agent has not written a session yet
    remote = CONTAINER_DIR / f"sessions-{uuid.uuid4().hex}.tar.gz"
    tar_cmd = (
        f"cd / && tar czf {remote} --ignore-failed-read "
        f"$(ls -d {rel} 2>/dev/null) 2>/dev/null; test -f {remote}"
    )
    data = _tar_out_of_container(
        backend, handle, tar_cmd, remote, "session archive",
        shutdown_event=shutdown_event,
    )
    dest = log_dir / "sessions"
    staging = log_dir / ".sessions.partial"
    shutil.rmtree(staging, ignore_errors=True)
    staging.mkdir()
    with _tarfile.open(fileobj=io.BytesIO(data)) as tar:
        safe_extractall(tar, staging)
    old = log_dir / ".sessions.old"
    shutil.rmtree(old, ignore_errors=True)
    if dest.exists():
        dest.rename(old)
    staging.rename(dest)
    shutil.rmtree(old, ignore_errors=True)


def _session_sync_loop(
    backend: ContainerBackend,
    handle: ContainerHandle,
    agent: Agent,
    log_dir: Path,
    stop_event: threading.Event,
    logger,
) -> None:
    while not stop_event.wait(SESSION_SYNC_INTERVAL):
        try:
            _sync_agent_sessions(backend, handle, agent, log_dir, stop_event)
        except Exception as e:
            logger.warning("Session sync failed: %s", e)


def _route_through_gateway(
    env: dict[str, str],
    agent: Agent,
    upstream: str | None,
    api_key: str | None,
    gateway: str,
) -> None:
    """Point the agent at the LLM gateway: every occurrence of the upstream
    URL becomes the gateway URL and the real key becomes a placeholder the
    gateway swaps back, so the key never enters the sandbox."""
    for name, value in list(env.items()):
        if api_key and api_key in value:
            value = value.replace(api_key, GATEWAY_PLACEHOLDER_KEY)
        if upstream and upstream.rstrip("/") in value:
            value = value.replace(upstream.rstrip("/"), gateway)
        env[name] = value
    if agent.api_base_env:
        env[agent.api_base_env] = gateway


def _auto_eval_loop(
    backend: ContainerBackend,
    handle: ContainerHandle,
    task_spec: TaskSpec,
    host_judge_url: str,
    session_token: str,
    eval_interval: int,
    stop_event: threading.Event,
    logger,
    log_dir: Path,
    admin_secret: str,
) -> None:
    """Host-side auto-eval: periodically extract code and submit to judge.

    Runs as a daemon thread. Fire-and-forget — does not poll for results.
    Writes tick entries to auto_eval_ticks.log for post-mortem inspection.
    """
    ticks_log = log_dir / "auto_eval_ticks.log"
    while True:
        stop_event.wait(eval_interval)
        if stop_event.is_set():
            break
        try:
            archive = _extract_archive_from_container(
                backend, handle, task_spec, shutdown_event=stop_event,
            )
            if stop_event.is_set():
                break
            resp = requests.post(
                f"{host_judge_url}/api/v1/submit",
                data={
                    "token": session_token,
                    "kind": "auto",
                    "admin_secret": admin_secret,
                },
                files={"archive": ("archive.tar.gz", archive, "application/gzip")},
                timeout=120,
            )
            resp.raise_for_status()
            data = resp.json()
            ts = time.strftime("%Y-%m-%dT%H:%M:%S")
            with open(ticks_log, "a") as f:
                f.write(f"[{ts}] submitted {len(archive)} bytes -> {data.get('submission_id', '?')} round={data.get('round_id', '?')}\n")
        except Exception as e:
            ts = time.strftime("%Y-%m-%dT%H:%M:%S")
            try:
                with open(ticks_log, "a") as f:
                    f.write(f"[{ts}] error: {e}\n")
            except Exception:
                pass
            logger.debug("Auto-eval tick failed: %s", e)


# ---------------------------------------------------------------------------
# Main entry point
# ---------------------------------------------------------------------------


def run_agent(
    task_spec: TaskSpec,
    agent: Agent,
    config: SForgeConfig,
    backend: ContainerBackend,
    run_id: str,
    model: str | None = None,
    timeout: int | None = None,
    judge_url: str = "http://host.docker.internal:8080",
    host_judge_url: str | None = None,
    eval_interval: int = 300,
    disable_stop_hook: bool = False,
    disable_auto_eval: bool = False,
    disable_auto_resume: bool = False,
    internet: bool = True,
    verbose: bool = False,
    shutdown_event: threading.Event | None = None,
    max_submissions: int | None = None,
    submission_cooldown: int | None = None,
) -> RunResult:
    """Run an agent on a task with iterative evaluation.

    ``judge_url`` is how containers reach the judge server; ``host_judge_url``
    is how this process does (derived from ``judge_url`` when not given).

    1. Build work + judge images
    2. Create work container (with judge URL in env)
    3. Install agent + tools (submit script, stop hook, auto-eval daemon)
    4. Run agent (high max-turns for iterative work)
    5. Read final state, extract archive
    """
    effective_timeout = timeout or config.agent_timeout or agent.timeout

    log_dir = config.log_dir / "runs" / run_id / task_spec.task_id
    log_dir.mkdir(parents=True, exist_ok=True)
    logger = setup_logger(
        f"agent.{task_spec.task_id}.{run_id}",
        log_dir / "run_agent.log",
        verbose=verbose,
    )

    # judge_url is for container use; derive a host-local URL for registration/polling
    parsed_judge = urlparse(judge_url)
    if host_judge_url:
        pass
    elif parsed_judge.hostname == "host.docker.internal":
        host_judge_url = judge_url.replace("host.docker.internal", "127.0.0.1")
    elif backend.backend_name == "k8s":
        # judge_url points to VPC IP (for pods); host talks to judge server locally
        host_judge_url = f"http://127.0.0.1:{parsed_judge.port or 8080}"
    else:
        host_judge_url = judge_url

    handle = None
    net_isolation = None
    auto_eval_stop = None
    session_stop = threading.Event()
    admin_secret = ""

    try:
        admin_secret = get_admin_secret(config.log_dir)
        # 0. Clean up stale iptables chains from previous runs that were killed
        if backend.backend_name == "docker":
            from sforge.harness.network_isolation import cleanup_stale_chains
            cleanup_stale_chains(logger)

        # 1. Check images exist (must run `sforge build` first)
        for image_key in (task_spec.work_image_key, task_spec.judge_image_key):
            if not backend.image_exists(image_key):
                if backend.backend_name == "e2b":
                    raise RuntimeError(
                        f"E2B Template for {image_key!r} was not found. Build it from "
                        "the task's pre-built image and set SFORGE_E2B_TEMPLATE_NAMESPACE "
                        "or SFORGE_E2B_TEMPLATE_MAP (see the E2B backend docs)."
                    )
                raise RuntimeError(
                    f"Image '{image_key}' not found. Run `sforge pull --task {task_spec.task_id}` to fetch from registry, or `sforge build --task {task_spec.task_id}` to build locally."
                )
        logger.info("Images ready")

        # 1b. Register session with judge server
        upstream_api_url = config.agent_api_base_url or agent.default_api_base_url
        reg_body: dict = {
            "task_id": task_spec.task_id, "run_id": run_id, "admin_secret": admin_secret,
            "llm_base_url": upstream_api_url, "llm_api_key": config.agent_api_key,
        }
        if config.judge_cpu_limit is not None:
            reg_body["judge_cpu_limit"] = config.judge_cpu_limit
        if config.judge_mem_limit is not None:
            reg_body["judge_mem_limit"] = config.judge_mem_limit
        if max_submissions is not None:
            reg_body["max_agent_submissions"] = max_submissions
        if submission_cooldown is not None:
            reg_body["submission_cooldown"] = submission_cooldown
        if backend.backend_name == "k8s":
            reg_body["backend"] = backend.backend_name
            reg_body["k8s_image_registry"] = config.k8s_image_registry
            reg_body["k8s_namespace"] = config.k8s_namespace
            if config.k8s_node_selector:
                reg_body["k8s_node_selector"] = config.k8s_node_selector
            if config.k8s_kubeconfig:
                reg_body["k8s_kubeconfig"] = config.k8s_kubeconfig
        elif backend.backend_name == "e2b":
            reg_body["backend"] = "e2b"
            reg_body["e2b_template_map"] = config.e2b_template_map
            reg_body["e2b_template_namespace"] = config.e2b_template_namespace
        for _reg_attempt in range(1, 6):
            try:
                reg_resp = requests.post(
                    f"{host_judge_url}/api/v1/register",
                    json=reg_body,
                    timeout=10,
                )
                reg_resp.raise_for_status()
                break
            except (requests.ConnectionError, requests.Timeout, requests.HTTPError) as exc:
                if _reg_attempt == 5:
                    raise
                wait = 2 * _reg_attempt
                logger.warning("Register attempt %d/5 failed (%s), retrying in %ds...", _reg_attempt, exc, wait)
                time.sleep(wait)
        session_token = reg_resp.json()["token"]
        logger.info("Registered session with judge server")
        # The agent reaches the model through the judge server's LLM gateway.
        api_url = f"{judge_url.rstrip('/')}{GATEWAY_ROUTE}/{session_token}"

        # 2. Create container
        container_name = f"sforge.run.{task_spec.task_id}.{run_id}"

        backend.remove_container_by_name(container_name, task_spec.work_image_key)

        env = _build_agent_env(agent, model)
        _route_through_gateway(env, agent, upstream_api_url, config.agent_api_key, api_url)
        if not internet:
            # Isolated sandboxes only talk to the judge (which forwards model
            # traffic itself), so host proxies have no business in there.
            for name in ("http_proxy", "HTTP_PROXY", "https_proxy", "HTTPS_PROXY"):
                env.pop(name, None)
        elif backend.backend_name == "e2b":
            sanitize_e2b_proxy_env(env)
        env["SFORGE_JUDGE_URL"] = judge_url
        env["SFORGE_TOKEN"] = session_token

        if task_spec.game_mode:
            game_api_base = (
                judge_url.rstrip("/")
                + f"/api/v1/game/{run_id}/{task_spec.task_id}"
            )
            env["GAME_SERVER_URL"] = game_api_base

        # Ensure judge server URL bypasses proxy
        judge_host = urlparse(judge_url).hostname or ""
        for key in ("NO_PROXY", "no_proxy"):
            existing = env.get(key, "")
            if judge_host and judge_host not in existing:
                env[key] = f"{existing},{judge_host}" if existing else judge_host

        # Network isolation: preflight + extra_hosts pre-resolve
        container_extra_hosts = {"host.docker.internal": "host-gateway"}
        container_cap_drop: list[str] = []

        if not internet and backend.backend_name == "docker":
            # Docker-only preflight: isolation runs as host iptables rules.
            from sforge.harness.network_isolation import (
                check_iptables_permission,
            )

            if not check_iptables_permission():
                raise RuntimeError(
                    "Network isolation requires sudo iptables access. "
                    "Ensure passwordless sudo is configured for iptables."
                )

        # Pin the API host for every task, not just isolated ones: sandbox DNS
        # may resolve it to an unreachable address, and a host-side /etc/hosts
        # override (e.g. a tunnel endpoint) can only reach the sandbox this way.
        api_host = urlparse(api_url).hostname or ""
        if (
            not backend.uses_hostname_egress
            and api_host
            and api_host != "host.docker.internal"
            and not is_ip_address(api_host)
        ):
            try:
                resolved_ips = resolve_hostname(api_host, logger)
            except RuntimeError:
                if not internet:
                    raise
                resolved_ips = []
                logger.warning(f"Could not pre-resolve {api_host}; sandbox DNS will be used")
            if resolved_ips:
                container_extra_hosts[api_host] = resolved_ips[0]

        if not internet:
            container_cap_drop = ["NET_RAW"]
            logger.info("Network isolation enabled: preflight passed")

        cpu = config.work_cpu_limit if config.work_cpu_limit is not None else task_spec.work.cpu_limit
        mem = config.work_mem_limit if config.work_mem_limit is not None else task_spec.work.mem_limit
        env.update(resource_env(cpu, mem))

        handle = backend.create_container(
            task_spec.work_image_key,
            container_name,
            environment=env,
            extra_hosts=container_extra_hosts,
            cap_drop=container_cap_drop or None,
            cpu_limit=cpu,
            mem_limit=mem,
        )
        backend.start_container(handle)
        logger.info(f"Container started: {container_name} (judge_url={judge_url})")

        # Some provider DNS returns poisoned answers for public domains (see
        # Backend.public_dns); internet-enabled tasks then use public
        # resolvers. Isolated tasks keep provider DNS (their whitelist pins
        # hostnames via /etc/hosts).
        public_dns = backend.public_dns
        if internet and public_dns:
            resolv = "".join(f"nameserver {ns}\n" for ns in public_dns)
            # Public resolvers return AAAA records but sandboxes may have no
            # IPv6 route; prefer IPv4 so v6-first clients don't burn timeouts.
            fix = (
                f"printf %s {shlex.quote(resolv)} > /etc/resolv.conf && "
                "echo 'precedence ::ffff:0:0/96 100' >> /etc/gai.conf"
            )
            backend.exec_run(handle, ["/bin/bash", "-c", fix])
            logger.info(f"Sandbox DNS switched to public resolvers: {', '.join(public_dns)}")

        # 3. Install agent runtime
        agent.install(backend, handle, logger)

        # 4. Install tools.
        #    Game-mode tasks skip sforge-submit (scoring is built into the
        #    game HTTP API and there is no archive to submit), but still need
        #    the stop hook — otherwise the agent exits naturally as soon as
        #    the model decides it's "done", losing the full timeout budget.
        effective_eval_interval = 0 if disable_auto_eval else eval_interval
        auto_eval_stop = None
        if not task_spec.game_mode:
            _install_tools(
                backend,
                handle,
                task_spec,
                agent,
                log_dir,
                logger,
                disable_stop_hook=disable_stop_hook,
            )

            # Start host-side auto-eval thread (if enabled)
            if effective_eval_interval > 0:
                auto_eval_stop = threading.Event()
                auto_eval_thread = threading.Thread(
                    target=_auto_eval_loop,
                    args=(
                        backend, handle, task_spec, host_judge_url,
                        session_token, effective_eval_interval,
                        auto_eval_stop, logger, log_dir,
                        admin_secret,
                    ),
                    daemon=True,
                )
                auto_eval_thread.start()
                logger.info(f"Host-side auto-eval started (interval={effective_eval_interval}s)")
        elif not disable_stop_hook:
            agent.install_stop_hook(backend, handle, log_dir, logger)

        # 4b. Apply network isolation (after install + tools, before agent)
        if not internet:
            from sforge.harness.network_isolation import (
                build_allowed_endpoints,
            )

            gateway_ip = backend.get_container_gateway_ip(handle) or ""
            if not gateway_ip and backend.backend_name == "docker":
                raise RuntimeError(
                    "Cannot determine gateway IP for network isolation"
                )

            endpoints = build_allowed_endpoints(
                judge_url, api_url, gateway_ip, logger,
                resolve_hostnames=not backend.uses_hostname_egress,
            )
            net_isolation = backend.create_network_isolation(handle, endpoints, logger)
            net_isolation.apply()

        # 5. Write prompt
        if task_spec.game_mode:
            prompt = generate_game_prompt(task_spec.work.instruction, internet=internet)
        else:
            prompt = generate_evolve_prompt(
                task_spec.work.instruction,
                submit_paths=task_spec.submit_paths,
                internet=internet,
                max_submissions=max_submissions,
                submission_cooldown=submission_cooldown,
            )
        prompt_path = f"{CONTAINER_DIR}/prompt.md"
        local_prompt = log_dir / "agent_prompt.md"
        local_prompt.write_text(prompt)
        backend.copy_to_container(handle, local_prompt, PurePosixPath(prompt_path))
        backend.exec_run(handle, f"chmod a+r {prompt_path}")
        logger.info(f"Prompt written ({len(prompt)} bytes)")

        # 6. Run agent (with auto-resume on abnormal exit)
        can_resume = not disable_auto_resume and agent.resume_cmd is not None
        remaining_timeout = effective_timeout
        resume_count = 0
        total_runtime = 0.0
        agent_timed_out = False
        all_output_parts: list[str] = []
        agent_live_log = log_dir / "agent_output.txt"
        MIN_RUNTIME_FOR_RESUME = 1
        MAX_RESUMES = 100

        threading.Thread(
            target=_session_sync_loop,
            args=(backend, handle, agent, log_dir, session_stop, logger),
            daemon=True,
        ).start()

        started_at = time.time()
        from datetime import datetime
        started_at_iso = datetime.fromtimestamp(started_at).strftime("%Y-%m-%dT%H:%M:%S")
        (log_dir / "started_at").write_text(f"{started_at_iso}\n{started_at}\n")

        on_chunk_cb = None

        while remaining_timeout > 0:
            is_resume = resume_count > 0
            run_cmd = agent.format_run_cmd(
                prompt_path, model=model,
                internet=internet, resume=is_resume,
            )
            if is_resume:
                logger.info(
                    f"Resuming agent (attempt {resume_count}/{MAX_RESUMES}, "
                    f"{remaining_timeout:.0f}s left): {run_cmd[:200]}..."
                )
            else:
                logger.info(f"Running agent: {run_cmd[:200]}... (timeout={remaining_timeout:.0f}s)")

            seg_result = backend.exec_run_with_timeout(
                handle,
                ["/bin/bash", "-c", run_cmd],
                timeout=int(remaining_timeout),
                log_file=agent_live_log,
                workdir=task_spec.cwd,
                environment=env,
                stream_to_stdout=verbose,
                shutdown_event=shutdown_event,
                log_append=is_resume,
                on_chunk=on_chunk_cb,
            )
            all_output_parts.append(seg_result.output)
            total_runtime += seg_result.elapsed_seconds

            if seg_result.timed_out:
                agent_timed_out = True
                break

            if not can_resume:
                break
            if seg_result.elapsed_seconds < MIN_RUNTIME_FOR_RESUME:
                logger.warning(
                    f"Agent exited after only {seg_result.elapsed_seconds:.1f}s "
                    f"(< {MIN_RUNTIME_FOR_RESUME}s), not resuming (likely systematic failure)"
                )
                break
            if resume_count >= MAX_RESUMES:
                logger.warning(f"Max resume attempts ({MAX_RESUMES}) reached")
                break

            remaining_timeout -= seg_result.elapsed_seconds
            resume_count += 1
            logger.info(f"Agent exited after {seg_result.elapsed_seconds:.1f}s, will resume")

        agent_output = "\n".join(all_output_parts)
        runtime = total_runtime
        logger.info(
            f"Agent finished: runtime={runtime:.1f}s, timed_out={agent_timed_out}, "
            f"resumes={resume_count}"
        )

        # 7. Stop background threads before extracting final state
        if auto_eval_stop is not None:
            auto_eval_stop.set()
            logger.info("Auto-eval thread stopped")
        session_stop.set()
        try:
            _sync_agent_sessions(backend, handle, agent, log_dir)
        except Exception as e:
            logger.warning(f"Final session sync failed: {e}")

        # 8. Extract final archive (tar of submit_paths)
        try:
            final_archive = _extract_archive_from_container(
                backend, handle, task_spec,
            )
            (log_dir / "final_archive.tar.gz").write_bytes(final_archive)
            logger.info(f"Final archive: {len(final_archive)} bytes")
        except Exception as e:
            logger.warning(f"Failed to extract final archive (container may have stopped): {e}")
            final_archive = b""

        # 8. Collect results
        if task_spec.game_mode:
            try:
                requests.post(
                    f"{host_judge_url}/api/v1/game/{run_id}/{task_spec.task_id}/close-all",
                    timeout=30,
                )
            except Exception:
                logger.warning("Failed to close active game sessions")

            try:
                history_resp = requests.get(
                    f"{host_judge_url}/api/v1/history?token={session_token}",
                    timeout=10,
                )
                history_resp.raise_for_status()
                history = history_resp.json()
            except Exception:
                logger.warning("Failed to fetch run history from judge server")
                history = {"run_id": run_id, "best_score": None, "entries": []}

            (log_dir / "game_history.json").write_text(
                json.dumps(history, indent=2, ensure_ascii=False)
            )

            game_entries = [
                e for e in history.get("entries", []) if e.get("type") == "game"
            ]
            best_score_raw = history.get("best_score")
            best_score = (
                float(best_score_raw) if best_score_raw is not None else None
            )
            best_score_0_100 = history.get("best_score_0_100")
            best_round = history.get("best_round", "")
            total_rounds = len(game_entries)

            result = RunResult(
                archive=final_archive,
                best_score_0_100=best_score_0_100,
                best_score=best_score,
                best_round=best_round,
                total_rounds=total_rounds,
                agent_submissions=total_rounds,
                auto_submissions=0,
                agent_output=agent_output,
                timed_out=agent_timed_out,
                runtime_seconds=runtime,
                resume_count=resume_count,
            )
            logger.info(
                f"Done (game): best_score={best_score} ({best_round}), "
                f"sessions={total_rounds}, resumes={resume_count}, runtime={runtime:.1f}s"
            )
        else:
            # Stop work container processes
            try:
                backend.exec_run(handle, "kill 1 2>/dev/null || true")
                logger.info("Work container processes stopped")
            except Exception:
                pass

            # Drain pending judge evaluations before querying final results
            drain_deadline = time.time() + 900
            while time.time() < drain_deadline:
                try:
                    h = requests.get(
                        f"{host_judge_url}/api/v1/history",
                        params={"token": session_token, "admin_secret": admin_secret},
                        timeout=10,
                    ).json()
                    pending = [e for e in h.get("entries", []) if e.get("status") in ("running", "queued")]
                    if not pending:
                        break
                    logger.info(f"Draining {len(pending)} pending judge evals...")
                except Exception:
                    break
                time.sleep(15)
            else:
                logger.warning("Drain timed out after 15 min; some reports may be missing.")

            # Query Judge Server for authoritative results (with admin_secret to get full history)
            try:
                history_resp = requests.get(
                    f"{host_judge_url}/api/v1/history",
                    params={"token": session_token, "admin_secret": admin_secret},
                    timeout=10,
                )
                history_resp.raise_for_status()
                history = history_resp.json()
            except Exception:
                logger.warning("Failed to fetch run history from judge server")
                history = {
                    "run_id": run_id, "best_score": None,
                    "best_round": "",
                    "agent_submissions": 0, "auto_submissions": 0,
                    "entries": [],
                }

            (log_dir / "run_history.json").write_text(
                json.dumps(history, indent=2, ensure_ascii=False)
            )

            best_score_0_100 = history.get("best_score_0_100")
            best_score_raw = history.get("best_score")
            best_score = (
                float(best_score_raw) if best_score_raw is not None else None
            )
            best_round = history.get("best_round", "")
            agent_subs = history.get("agent_submissions", 0)
            auto_subs = history.get("auto_submissions", 0)
            total_rounds = agent_subs + auto_subs

            result = RunResult(
                archive=final_archive,
                best_score_0_100=best_score_0_100,
                best_score=best_score,
                best_round=best_round,
                total_rounds=total_rounds,
                agent_submissions=agent_subs,
                auto_submissions=auto_subs,
                agent_output=agent_output,
                timed_out=agent_timed_out,
                runtime_seconds=runtime,
                resume_count=resume_count,
            )

            logger.info(
                f"Done: best={result.best_score_0_100} "
                f"(round {result.best_round!r}), "
                f"agent_subs={agent_subs}, auto_subs={auto_subs}, "
                f"resumes={resume_count}, runtime={runtime:.1f}s"
            )
        try:
            usage_resp = requests.get(
                f"{host_judge_url}/api/v1/usage",
                params={"token": session_token, "admin_secret": admin_secret},
                timeout=30,
            )
            usage_resp.raise_for_status()
            result.usage = usage_resp.json()
            logger.info(f"LLM usage: {json.dumps({k: v for k, v in result.usage.items() if k != 'by_model'})}")
        except Exception as e:
            logger.warning(f"Could not fetch LLM usage: {e}")
        return result

    except KeyboardInterrupt:
        logger.info("Run interrupted by user (Ctrl+C)")

        # Stop auto-eval thread
        if auto_eval_stop is not None:
            auto_eval_stop.set()
        session_stop.set()

        # Try to extract archive from the container before it's destroyed
        interrupted_archive = b""
        try:
            if handle is not None:
                try:
                    _sync_agent_sessions(backend, handle, agent, log_dir)
                except Exception:
                    pass
                interrupted_archive = _extract_archive_from_container(
                    backend, handle, task_spec,
                )
                (log_dir / "final_archive.tar.gz").write_bytes(interrupted_archive)
                logger.info(f"Final archive (interrupted): {len(interrupted_archive)} bytes")
        except Exception:
            pass

        # Query judge server for results accumulated before interruption (full history)
        try:
            history_resp = requests.get(
                f"{host_judge_url}/api/v1/history",
                params={"token": session_token, "admin_secret": admin_secret},
                timeout=10,
            )
            history_resp.raise_for_status()
            history = history_resp.json()
        except Exception:
            history = {
                "run_id": run_id, "best_score": None,
                "best_round": "",
                "agent_submissions": 0, "auto_submissions": 0,
                "entries": [],
            }

        (log_dir / "run_history.json").write_text(
            json.dumps(history, indent=2, ensure_ascii=False)
        )

        best_score_0_100 = history.get("best_score_0_100")
        best_score_raw = history.get("best_score")
        best_score = float(best_score_raw) if best_score_raw is not None else None
        best_round = history.get("best_round", "")
        agent_subs = history.get("agent_submissions", 0)
        auto_subs = history.get("auto_submissions", 0)
        total_rounds = agent_subs + auto_subs

        logger.info(
            f"Interrupted results: best={best_score_0_100} "
            f"(round {best_round!r}), "
            f"agent_subs={agent_subs}, auto_subs={auto_subs}"
        )

        return RunResult(
            archive=interrupted_archive,
            best_score_0_100=best_score_0_100,
            best_score=best_score,
            best_round=best_round,
            total_rounds=total_rounds,
            agent_submissions=agent_subs,
            auto_submissions=auto_subs,
            agent_output="Stopped by user (Ctrl+C)",
            timed_out=False,
            resume_count=resume_count,
        )
    except Exception as e:
        logger.error(f"Error: {e}\n{traceback.format_exc()}")
        if backend.backend_name == "e2b":
            # E2B transport or lifecycle failures must remain visible to the
            # caller instead of being reported as a successful zero score.
            raise

        # Preserve the pre-E2B Docker/Kubernetes behavior.
        try:
            history_resp = requests.get(
                f"{host_judge_url}/api/v1/history?token={session_token}",
                timeout=10,
            )
            history_resp.raise_for_status()
            history = history_resp.json()
            best_score_0_100 = history.get("best_score_0_100")
            best_score_raw = history.get("best_score")
            best_score = float(best_score_raw) if best_score_raw is not None else None
            best_round = history.get("best_round", "")
            agent_subs = history.get("agent_submissions", 0)
            auto_subs = history.get("auto_submissions", 0)
        except Exception:
            best_score_0_100 = None
            best_score = None
            best_round = ""
            agent_subs = 0
            auto_subs = 0

        return RunResult(
            best_score_0_100=best_score_0_100,
            best_score=best_score,
            best_round=best_round,
            total_rounds=agent_subs + auto_subs,
            agent_submissions=agent_subs,
            auto_submissions=auto_subs,
            agent_output=str(e),
            timed_out=False,
            resume_count=locals().get("resume_count", 0),
        )
    finally:
        session_stop.set()
        if auto_eval_stop is not None:
            auto_eval_stop.set()
        if net_isolation is not None:
            try:
                net_isolation.cleanup()
            except Exception as exc:
                if logger:
                    logger.warning(f"Failed to cleanup network isolation: {exc}")
        if threading.current_thread() is threading.main_thread():
            prev_handler = signal.signal(signal.SIGINT, signal.SIG_IGN)
            print("\nStopping container, please wait... (Ctrl+C disabled during cleanup)")
            backend.cleanup_container(handle, logger)
            signal.signal(signal.SIGINT, prev_handler)
        else:
            backend.cleanup_container(handle, logger)
        close_logger(logger)
