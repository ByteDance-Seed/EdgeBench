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
from sforge.harness.config import SForgeConfig, sanitize_e2b_proxy_env
from sforge.harness.constants import get_admin_secret
from sforge.harness.docker_build import (
    close_logger,
    setup_logger,
)
from sforge.harness.evolve_scripts import (
    generate_evolve_prompt,
    generate_game_prompt,
    generate_submit_script,
)
from sforge.harness.task_spec import TaskSpec


@dataclass
class RunResult:
    """Result of running an agent on a task."""

    archive: bytes = b""
    best_pass_rate: float = 0.0
    best_score: float | None = None
    best_round: str = ""
    total_rounds: int = 0
    agent_submissions: int = 0
    auto_submissions: int = 0
    agent_output: str = ""
    timed_out: bool = False
    runtime_seconds: float = 0.0
    resume_count: int = 0

    def to_dict(self) -> dict:
        d = {
            "best_pass_rate": self.best_pass_rate,
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

    if config.nodejs_mirror_url:
        env["SFORGE_NODEJS_MIRROR_URL"] = config.nodejs_mirror_url
    if config.npm_registry_url:
        env["npm_config_registry"] = config.npm_registry_url

    env.update(config.agent_extra_env)

    agent.augment_env(env, model)

    return env


def _e2b_install_env(env: dict[str, str], agent: Agent) -> dict[str, str]:
    """Keep only non-secret values required while installing the agent."""
    allowed = {
        "http_proxy", "HTTP_PROXY", "https_proxy", "HTTPS_PROXY",
        "no_proxy", "NO_PROXY", "SFORGE_NODEJS_MIRROR_URL",
        "npm_config_registry",
    }
    if agent.api_base_env:
        allowed.add(agent.api_base_env)
    if agent.model_env:
        allowed.add(agent.model_env)
    return {key: value for key, value in env.items() if key in allowed}


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
    submit_script = generate_submit_script()
    local_submit = log_dir / "_sforge-submit.sh"
    local_submit.write_text(submit_script)
    backend.copy_to_container(
        handle, local_submit, PurePosixPath("/usr/local/bin/sforge-submit")
    )
    backend.exec_run(handle, "chmod a+x /usr/local/bin/sforge-submit", user="root")
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
    remote_archive = PurePosixPath(
        f"/tmp/.sforge-submission-{uuid.uuid4().hex}.tar.gz"
    )
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
    result = backend.exec_run_with_exit_code(
        handle, ["/bin/bash", "-c", tar_cmd], timeout=300,
        user="agent",
    )
    if result.timed_out:
        raise RuntimeError("Timed out while creating the submission archive")
    if result.exit_code != 0:
        raise RuntimeError(
            "Could not create the submission archive: " + result.output[-4000:]
        )
    try:
        if backend.backend_name == "e2b":
            raw = backend.copy_from_container(
                handle, remote_archive, shutdown_event=shutdown_event,
            )
        else:
            raw = backend.copy_from_container(handle, remote_archive)
    finally:
        try:
            backend.exec_run(
                handle, ["rm", "-f", str(remote_archive)], user="root",
            )
        except Exception:
            pass
    with _tarfile.open(fileobj=io.BytesIO(raw)) as outer:
        members = [member for member in outer.getmembers() if member.isfile()]
        if len(members) != 1:
            raise RuntimeError(
                f"Unexpected archive wrapper: expected 1 file, got {len(members)}"
            )
        source = outer.extractfile(members[0])
        if source is None:
            raise RuntimeError("Could not read the submission archive wrapper")
        archive = source.read()
    return archive


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

    Requires a running judge server (started via `sforge serve`).

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
    if parsed_judge.hostname == "host.docker.internal":
        host_judge_url = judge_url.replace("host.docker.internal", "127.0.0.1")
    elif backend.backend_name == "k8s":
        # judge_url points to VPC IP (for pods); host talks to judge server locally
        host_judge_url = f"http://127.0.0.1:{parsed_judge.port or 8080}"
    else:
        host_judge_url = judge_url

    handle = None
    net_isolation = None
    install_parts: list[str] = []
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
                        f"E2B Template for {image_key!r} was not found. Make sure "
                        "the task uses a published image version with an official "
                        "Template, or point SFORGE_E2B_TEMPLATE_MAP at a "
                        "self-built Template."
                    )
                raise RuntimeError(
                    f"Image '{image_key}' not found. Run `sforge pull --task {task_spec.task_id}` to fetch from registry, or `sforge build --task {task_spec.task_id}` to build locally."
                )
        logger.info("Images ready")

        # 1b. Register session with judge server
        reg_body: dict = {"task_id": task_spec.task_id, "run_id": run_id, "admin_secret": admin_secret}
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
            reg_body["e2b_sandbox_ttl"] = config.e2b_sandbox_ttl
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

        # 2. Create container
        container_name = f"sforge.run.{task_spec.task_id}.{run_id}"

        backend.remove_container_by_name(container_name)

        env = _build_agent_env(agent, model)
        if backend.backend_name == "e2b":
            sanitize_e2b_proxy_env(env, internet=internet)
        env["SFORGE_JUDGE_URL"] = judge_url
        env["SFORGE_TOKEN"] = session_token
        env["SFORGE_PATCH_DIR"] = task_spec.cwd
        env["SFORGE_SUBMIT_PATHS"] = " ".join(task_spec.submit_paths)
        env["SFORGE_SUBMIT_EXCLUDE_FLAGS"] = " ".join(
            f"--exclude={e}" for e in task_spec.submit_exclude
        )

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
            # Docker-only preflight: isolation runs as host iptables rules, so
            # it needs sudo and conflicts with host proxy env leaking into the
            # container. Remote backends (k8s, e2b) isolate inside the cluster/
            # provider and are unaffected by either.
            from sforge.harness.network_isolation import (
                check_iptables_permission,
            )

            if config.http_proxy or config.https_proxy:
                raise RuntimeError(
                    "Network isolation (internet=false) is not compatible with "
                    "direct proxy configuration. Start a local API proxy first:\n"
                    "  python -m sforge proxy --target <YOUR_API_URL>\n"
                    "Then set SFORGE_AGENT_API_BASE_URL="
                    "http://host.docker.internal:9090 "
                    "and unset HTTP_PROXY/HTTPS_PROXY before running."
                )
            if not check_iptables_permission():
                raise RuntimeError(
                    "Network isolation requires sudo iptables access. "
                    "Ensure passwordless sudo is configured for iptables."
                )

        if not internet:
            from sforge.harness.network_isolation import (
                is_ip_address,
                resolve_hostname,
            )

            api_url = config.agent_api_base_url or agent.default_api_base_url
            if api_url:
                api_host = urlparse(api_url).hostname or ""
                if (
                    backend.backend_name != "e2b"
                    and api_host
                    and api_host != "host.docker.internal"
                    and not is_ip_address(api_host)
                ):
                    resolved_ips = resolve_hostname(api_host, logger)
                    if resolved_ips:
                        container_extra_hosts[api_host] = resolved_ips[0]

            container_cap_drop = ["NET_RAW"]
            logger.info("Network isolation enabled: preflight passed")

        cpu = config.work_cpu_limit if config.work_cpu_limit is not None else task_spec.work.cpu_limit
        mem = config.work_mem_limit if config.work_mem_limit is not None else task_spec.work.mem_limit

        handle = backend.create_container(
            task_spec.work_image_key,
            container_name,
            environment=(
                _e2b_install_env(env, agent)
                if backend.backend_name == "e2b" else env
            ),
            extra_hosts=container_extra_hosts,
            cap_drop=container_cap_drop or None,
            cpu_limit=cpu,
            mem_limit=mem,
            # e2b execs default to the SDK's "user" account, not the image USER
            user="agent",
        )
        backend.start_container(handle)
        logger.info(f"Container started: {container_name} (judge_url={judge_url})")

        # 3. Install agent runtime
        for i, cmd in enumerate(agent.install_cmds):
            logger.info(
                f"Install step {i + 1}/{len(agent.install_cmds)}: {cmd}"
            )
            result = backend.exec_run_with_exit_code(
                handle, f"/bin/bash -c {shlex.quote(cmd)}", timeout=600
            )
            install_parts.append(result.output)
            if result.timed_out:
                raise RuntimeError(f"Install command timed out: {cmd}")
            if result.exit_code != 0:
                raise RuntimeError(
                    f"Install command failed (exit {result.exit_code}): {cmd}\n{result.output}"
                )
            logger.info(f"Install step {i + 1} done ({result.elapsed_seconds:.1f}s)")

        (log_dir / "install_output.txt").write_text("\n".join(install_parts))
        logger.info("Agent installation complete")

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

            effective_api_url = config.agent_api_base_url or agent.default_api_base_url
            endpoints = build_allowed_endpoints(
                judge_url, effective_api_url, gateway_ip, logger,
                resolve_hostnames=backend.backend_name != "e2b",
            )
            net_isolation = backend.create_network_isolation(handle, endpoints, logger)
            net_isolation.apply()

        # 5. Write prompt
        if task_spec.game_mode:
            prompt = generate_game_prompt(task_spec.work.agent_query, internet=internet)
        else:
            prompt = generate_evolve_prompt(
                task_spec.work.agent_query,
                submit_paths=task_spec.submit_paths,
                internet=internet,
                max_submissions=max_submissions,
                submission_cooldown=submission_cooldown,
            )
        prompt_path = "/tmp/agent_prompt.md"
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

        # 7. Stop auto-eval thread before extracting final archive
        if auto_eval_stop is not None:
            auto_eval_stop.set()
            logger.info("Auto-eval thread stopped")

        # 8. Extract final archive (tar of submit_paths)
        try:
            final_archive = _extract_archive_from_container(
                backend, handle, task_spec, shutdown_event=shutdown_event,
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
            best_pass_rate_raw = history.get("best_pass_rate", 0.0)
            best_pass_rate = float(best_pass_rate_raw) if best_pass_rate_raw else 0.0
            best_round = history.get("best_round", "")
            total_rounds = len(game_entries)

            result = RunResult(
                archive=final_archive,
                best_pass_rate=best_pass_rate,
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
            # Save debug artifacts from container (non-authoritative, best-effort)
            try:
                state_result = backend.exec_run_with_timeout(
                    handle,
                    [
                        "/bin/bash",
                        "-c",
                        "cat /tmp/sforge_state.json 2>/dev/null || echo '{}'",
                    ],
                    timeout=10,
                )
                state = json.loads(state_result.output.strip())
                (log_dir / "evolve_state.json").write_text(
                    json.dumps(state, indent=2, ensure_ascii=False)
                )
            except Exception:
                logger.warning("Failed to read state file from container")

            # Stop work container processes
            try:
                backend.exec_run(handle, "kill 1 2>/dev/null || true", user="root")
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
                    "best_pass_rate": 0.0, "best_round": "",
                    "agent_submissions": 0, "auto_submissions": 0,
                    "entries": [],
                }

            (log_dir / "run_history.json").write_text(
                json.dumps(history, indent=2, ensure_ascii=False)
            )

            best_pass_rate = history.get("best_pass_rate", 0.0)
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
                best_pass_rate=best_pass_rate,
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
                f"Done: best={result.best_pass_rate:.2%} "
                f"(round {result.best_round!r}), "
                f"agent_subs={agent_subs}, auto_subs={auto_subs}, "
                f"resumes={resume_count}, runtime={runtime:.1f}s"
            )
        return result

    except KeyboardInterrupt:
        logger.info("Run interrupted by user (Ctrl+C)")

        # Stop auto-eval thread
        if auto_eval_stop is not None:
            auto_eval_stop.set()

        # Try to extract archive from the container before it's destroyed
        interrupted_archive = b""
        try:
            if handle is not None:
                interrupted_archive = _extract_archive_from_container(
                    backend, handle, task_spec, shutdown_event=shutdown_event,
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
                "best_pass_rate": 0.0, "best_round": "",
                "agent_submissions": 0, "auto_submissions": 0,
                "entries": [],
            }

        (log_dir / "run_history.json").write_text(
            json.dumps(history, indent=2, ensure_ascii=False)
        )

        best_pass_rate = history.get("best_pass_rate", 0.0)
        best_score_raw = history.get("best_score")
        best_score = float(best_score_raw) if best_score_raw is not None else None
        best_round = history.get("best_round", "")
        agent_subs = history.get("agent_submissions", 0)
        auto_subs = history.get("auto_submissions", 0)
        total_rounds = agent_subs + auto_subs

        logger.info(
            f"Interrupted results: best={best_pass_rate:.2%} "
            f"(round {best_round!r}), "
            f"agent_subs={agent_subs}, auto_subs={auto_subs}"
        )

        return RunResult(
            archive=interrupted_archive,
            best_pass_rate=best_pass_rate,
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
            best_pass_rate = history.get("best_pass_rate", 0.0)
            best_score_raw = history.get("best_score")
            best_score = float(best_score_raw) if best_score_raw is not None else None
            best_round = history.get("best_round", "")
            agent_subs = history.get("agent_submissions", 0)
            auto_subs = history.get("auto_submissions", 0)
        except Exception:
            best_pass_rate = 0.0
            best_score = None
            best_round = ""
            agent_subs = 0
            auto_subs = 0

        return RunResult(
            best_pass_rate=best_pass_rate,
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
