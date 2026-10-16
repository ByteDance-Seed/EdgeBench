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

"""Judge HTTP REST API server (FastAPI)."""

from __future__ import annotations

import fcntl
import json
import logging
import os
import queue
import secrets
import threading
import time
import uuid
from collections.abc import Callable
from dataclasses import dataclass, field, replace
from enum import Enum
from pathlib import Path, PurePosixPath
from typing import Any

import requests
from docker.utils import parse_bytes
from fastapi import FastAPI, File, Form, HTTPException, Query, UploadFile
from pydantic import BaseModel

from sforge import __version__
from sforge.harness.backend import ContainerBackend
from sforge.harness.benchmark import load_benchmark
from sforge.harness.config import (
    SForgeConfig,
    create_backend_from_config,
    get_container_env,
    load_config,
    sanitize_e2b_proxy_env,
)
from sforge.harness.constants import get_admin_secret
from sforge.harness.docker_build import BuildImageError, build_judge_image
from sforge.harness.run_evaluation import judge_submission
from sforge.harness.selection import select_best
from sforge.harness.task_spec import TaskSpec, load_all_tasks

logger = logging.getLogger("sforge.judge_server")

GAME_SERVER_APP_PATH = Path(__file__).parent / "game_server_app.py"


class SubmissionBudgetExceeded(Exception):
    pass


class SubmissionCooldownActive(Exception):
    pass


# --- Models ---


class SubmissionStatus(str, Enum):
    QUEUED = "queued"
    RUNNING = "running"
    COMPLETED = "completed"
    ERROR = "error"


class ResultResponse(BaseModel):
    submission_id: str
    status: SubmissionStatus
    report: dict | None = None
    error: str | None = None


class GameNewRequest(BaseModel):
    pass


class GameStepRequest(BaseModel):
    action: str


class GameNewResponse(BaseModel):
    session_id: str
    observation: str
    score: int
    peak_score: int
    max_score: int
    done: bool
    moves: int


class GameStepResponse(BaseModel):
    session_id: str
    observation: str
    score: int
    peak_score: int
    max_score: int
    done: bool
    moves: int


class GameStatusResponse(BaseModel):
    session_id: str
    score: int
    peak_score: int
    max_score: int
    done: bool
    moves: int


class GameCloseResponse(BaseModel):
    session_id: str
    final_score: int
    peak_score: int
    max_score: int
    moves: int


class RegisterRequest(BaseModel):
    task_id: str
    run_id: str
    admin_secret: str = ""
    judge_cpu_limit: int | None = None
    judge_mem_limit: str | None = None
    backend: str | None = None
    k8s_image_registry: str | None = None
    k8s_namespace: str | None = None
    k8s_node_selector: dict[str, str] | None = None
    k8s_kubeconfig: str | None = None
    max_agent_submissions: int | None = None
    submission_cooldown: int | None = None
    e2b_template_map: dict[str, str] | None = None
    e2b_template_namespace: str | None = None
    e2b_sandbox_ttl: int | None = None


class RegisterResponse(BaseModel):
    token: str


class SubmitResponse(BaseModel):
    submission_id: str
    round_id: str
    status: SubmissionStatus
    remaining_submissions: int | None = None


# --- Game session state ---

GAME_SESSION_IDLE_TIMEOUT = 600  # 10 minutes
GAME_SESSION_MAX = 200
GAME_SESSION_PER_RUN_MAX = 3
GAME_REAPER_INTERVAL = 60
GAME_CONTAINER_READY_TIMEOUT = 30
GAME_CONTAINER_READY_POLL = 0.5
GAME_CONTAINER_PORT = 8000
GAME_GATEWAY_ATTEMPTS = 3
GAME_GATEWAY_BACKOFF = 1.0


@dataclass
class GameSessionState:
    session_id: str
    run_id: str
    task_id: str
    game_num: int
    container: object  # ContainerHandle
    container_url: str
    headers: dict = field(default_factory=dict)
    max_score: int = 0
    peak_score: int = 0
    current_score: int = 0
    moves: int = 0
    done: bool = False
    steps: list = field(default_factory=list)
    created_at: float = field(default_factory=time.time)
    last_active: float = field(default_factory=time.time)


#: Default cap on concurrently executing judge containers. A long-running judge
#: (e.g. a search-heavy benchmark) otherwise overlaps with every auto snapshot.
JUDGE_MAX_CONCURRENCY = 4
#: Default cap on accepted-but-not-yet-running submissions. Only `auto` production
#: is rejected at this bound; `agent`/final submissions are always accepted so the
#: final grading can never be starved by auto snapshots.
JUDGE_MAX_BACKLOG = 8


#: Host-wide slot file. Every launcher process on this machine contends for the
#: same file, so the total number of concurrently running judges is bounded once
#: instead of once per process.
JUDGE_HOST_SLOT_FILE = os.environ.get(
    "SFORGE_JUDGE_HOST_SLOT_FILE", "/tmp/sforge-judge-host-slots.json")
JUDGE_HOST_MEMORY_FILE = os.environ.get(
    "SFORGE_JUDGE_HOST_MEMORY_FILE", "/tmp/sforge-judge-host-memory.json")
JUDGE_HOST_OWNER_FILE = os.environ.get(
    "SFORGE_JUDGE_HOST_OWNER_FILE", "/tmp/sforge-judge-host-owners.json")
#: Default host-wide total. Chosen so several launchers share one machine budget.
JUDGE_HOST_CAPACITY = 8
#: A launcher can disappear after another server has already completed its one-time
#: startup reconciliation.  Capacity waiters periodically retry backend-confirmed
#: cleanup so an orphan cannot stall every later judge indefinitely.
JUDGE_CAPACITY_RECONCILE_INTERVAL = 5.0


class HostJudgeCapacity:
    """Cross-process judge slot budget backed by an flock-guarded file.

    A per-process pool multiplies with the number of launcher processes; this is the
    bound that actually limits the host. The first writer fixes the capacity.
    A dead launcher does not prove its judge containers stopped, so slots remain
    reserved until explicit release or backend-confirmed cleanup.
    """

    def __init__(
        self, capacity: int, path: str | None = None, owner_path: str | None = None,
    ) -> None:
        self.capacity = max(1, int(capacity))
        self.path = Path(path or os.environ.get("SFORGE_JUDGE_HOST_SLOT_FILE", JUDGE_HOST_SLOT_FILE))
        self._lock_path = self.path.with_suffix(self.path.suffix + ".lock")
        if owner_path is not None:
            self._owner_path = Path(owner_path)
        elif path is not None:
            self._owner_path = self.path.with_suffix(self.path.suffix + ".owners")
        else:
            self._owner_path = Path(
                os.environ.get("SFORGE_JUDGE_HOST_OWNER_FILE", JUDGE_HOST_OWNER_FILE)
            )

    def _read(self) -> dict:
        try:
            state = json.loads(self.path.read_text())
        except FileNotFoundError:
            return {"version": 1, "capacity": self.capacity, "holders": {}}
        except (OSError, ValueError) as exc:
            raise RuntimeError("Cannot read judge host capacity state") from exc
        if (not isinstance(state, dict) or state.get("version") != 1
                or type(state.get("capacity")) is not int or state["capacity"] < 1
                or not isinstance(state.get("holders"), dict)
                or any(
                    not isinstance(k, str)
                    or not (
                        isinstance(v, (int, float))
                        or (
                            isinstance(v, dict)
                            and isinstance(v.get("acquired_at"), (int, float))
                            and (v.get("owner_id") is None or isinstance(v.get("owner_id"), str))
                            and type(v.get("units", 1)) is int
                            and v.get("units", 1) >= 1
                        )
                    )
                    for k, v in state["holders"].items()
                )):
            raise RuntimeError("Invalid judge host capacity state; explicit recovery required")
        return state

    def _write(self, state: dict) -> None:
        tmp = self.path.with_suffix(self.path.suffix + ".tmp")
        tmp.write_text(json.dumps(state))
        tmp.replace(self.path)

    def _read_owners(self) -> dict[str, str]:
        try:
            state = json.loads(self._owner_path.read_text())
        except FileNotFoundError:
            return {}
        except (OSError, ValueError) as exc:
            raise RuntimeError("Cannot read judge host owner state") from exc
        owners = state.get("owners") if isinstance(state, dict) else None
        if (
            not isinstance(state, dict)
            or state.get("version") != 1
            or not isinstance(owners, dict)
            or any(not isinstance(k, str) or not isinstance(v, str) for k, v in owners.items())
        ):
            raise RuntimeError("Invalid judge host owner state; explicit recovery required")
        return owners

    def _write_owners(self, owners: dict[str, str]) -> None:
        tmp = self._owner_path.with_suffix(self._owner_path.suffix + ".tmp")
        tmp.write_text(json.dumps({"version": 1, "owners": owners}))
        tmp.replace(self._owner_path)

    @staticmethod
    def _holder_units(holder: float | dict) -> int:
        return holder.get("units", 1) if isinstance(holder, dict) else 1

    def try_acquire(
        self, token: str, owner_id: str | None = None, *, units: int = 1,
    ) -> bool:
        if type(units) is not int or units < 1:
            raise ValueError("Judge host capacity units must be a positive integer")
        self._lock_path.parent.mkdir(parents=True, exist_ok=True)
        with open(self._lock_path, "a+") as lock:
            fcntl.flock(lock, fcntl.LOCK_EX)
            try:
                state = self._read()
                if state["capacity"] != self.capacity:
                    raise RuntimeError("Judge host capacity configuration mismatch")
                holders = state["holders"]
                owners = self._read_owners()
                current = holders.get(token)
                if current is not None:
                    current_owner = (
                        current.get("owner_id") if isinstance(current, dict)
                        else owners.get(token)
                    )
                    if self._holder_units(current) != units or current_owner != owner_id:
                        raise RuntimeError("Judge host capacity holder identity mismatch")
                used = sum(self._holder_units(holder) for holder in holders.values())
                if current is not None or used + units <= state["capacity"]:
                    holders[token] = (
                        {"acquired_at": time.time(), "owner_id": owner_id, "units": units}
                        if units != 1 else time.time()
                    )
                    if owner_id is not None:
                        owners[token] = owner_id
                    else:
                        owners.pop(token, None)
                    self._write(state)
                    self._write_owners(owners)
                    return True
                return False
            finally:
                fcntl.flock(lock, fcntl.LOCK_UN)

    def release(self, token: str) -> None:
        self._lock_path.parent.mkdir(parents=True, exist_ok=True)
        with open(self._lock_path, "a+") as lock:
            fcntl.flock(lock, fcntl.LOCK_EX)
            try:
                state = self._read()
                owners = self._read_owners()
                state["holders"].pop(token, None)
                owners.pop(token, None)
                self._write(state)
                self._write_owners(owners)
            finally:
                fcntl.flock(lock, fcntl.LOCK_UN)

    @staticmethod
    def _owner_is_alive(token: str) -> bool:
        owner, separator, _ = token.partition(":")
        if not separator:
            return True
        try:
            pid = int(owner)
        except ValueError:
            return True
        if pid < 1:
            return True
        try:
            os.kill(pid, 0)
        except ProcessLookupError:
            return False
        except PermissionError:
            return True
        return True

    def reconcile_stale_holders(
        self, cleanup: Callable[[str, str | None], bool],
    ) -> list[str]:
        """Release dead owners only after their backend resources are gone."""
        self._lock_path.parent.mkdir(parents=True, exist_ok=True)
        with open(self._lock_path, "a+") as lock:
            fcntl.flock(lock, fcntl.LOCK_EX)
            try:
                state = self._read()
                if state["capacity"] != self.capacity:
                    raise RuntimeError("Judge host capacity configuration mismatch")
                snapshot = dict(state["holders"])
                owner_snapshot = self._read_owners()
            finally:
                fcntl.flock(lock, fcntl.LOCK_UN)

        reconciled = []
        for token, holder in sorted(snapshot.items()):
            if self._owner_is_alive(token):
                continue
            owner_id = (
                holder.get("owner_id") if isinstance(holder, dict)
                else owner_snapshot.get(token)
            )
            try:
                cleaned = cleanup(token, owner_id)
            except Exception:
                logger.exception("Could not clean stale judge slot %s", token)
                continue
            if not cleaned:
                continue
            with open(self._lock_path, "a+") as lock:
                fcntl.flock(lock, fcntl.LOCK_EX)
                try:
                    state = self._read()
                    if state["holders"].get(token) != holder:
                        continue
                    owners = self._read_owners()
                    state["holders"].pop(token)
                    owners.pop(token, None)
                    self._write(state)
                    self._write_owners(owners)
                    reconciled.append(token)
                finally:
                    fcntl.flock(lock, fcntl.LOCK_UN)
        return reconciled


# --- Server state ---


class JudgeState:
    def __init__(
        self, config: SForgeConfig, *,
        backend_factory: Callable[[SForgeConfig], ContainerBackend] | None = None,
    ):
        self.config = config
        self.admin_secret = get_admin_secret(config.log_dir)
        self.tasks: dict[str, TaskSpec] = {}
        self.submissions: dict[str, dict] = {}  # submission_id -> {status, report, ...}
        self.game_sessions: dict[str, GameSessionState] = {}
        self.run_history: dict[str, list[dict]] = {}  # run_id -> [entries]
        self.tokens: dict[str, dict] = {}  # token -> {task_id, run_id, next_agent, next_auto, judge_cpu_limit, judge_mem_limit}
        self.run_resource_limits: dict[str, dict] = {}  # run/task -> limits
        self.run_backends: dict[str, ContainerBackend] = {}  # run/task -> backend
        # Bounded judge execution: accepted submissions are never dropped, but at
        # most `judge_max_concurrency` run at once. `auto` production is additionally
        # rejected *before* a round is consumed when the backlog is already full, so
        # a long judge cannot turn the host into an unbounded fan-out.
        self.judge_max_concurrency = max(1, int(getattr(config, "judge_max_concurrency", 0) or JUDGE_MAX_CONCURRENCY))
        self.host_capacity = HostJudgeCapacity(
            int(getattr(config, "judge_host_capacity", 0) or JUDGE_HOST_CAPACITY))
        memory_capacity = getattr(config, "judge_host_memory_capacity", None)
        if memory_capacity:
            try:
                memory_capacity_bytes = parse_bytes(memory_capacity)
            except Exception as exc:
                raise ValueError(
                    "SFORGE_JUDGE_HOST_MEMORY_CAPACITY must be a positive memory size"
                ) from exc
            if memory_capacity_bytes < 1:
                raise ValueError(
                    "SFORGE_JUDGE_HOST_MEMORY_CAPACITY must be a positive memory size"
                )
            self.host_memory_capacity = HostJudgeCapacity(
                memory_capacity_bytes,
                os.environ.get("SFORGE_JUDGE_HOST_MEMORY_FILE", JUDGE_HOST_MEMORY_FILE),
            )
        else:
            self.host_memory_capacity = None
        self.judge_max_backlog = max(self.judge_max_concurrency,
                                     int(getattr(config, "judge_max_backlog", 0) or JUDGE_MAX_BACKLOG))
        self._judge_queue: queue.Queue[str | None] = queue.Queue()
        self._judge_pending: dict[str, tuple] = {}
        self._judge_pending_lock = threading.Lock()
        self._judge_workers: list[threading.Thread] = []
        self._judge_workers_lock = threading.Lock()
        self._capacity_reconcile_lock = threading.Lock()
        self._capacity_reconciled_at = 0.0
        self._submission_lock = threading.RLock()
        self._judge_queue_drained = threading.Event()
        self._game_lock = threading.Lock()
        self._history_lock = threading.Lock()
        self._tokens_lock = threading.Lock()
        self._custom_backend_factory = backend_factory
        self._backend_factory = (
            create_backend_from_config if backend_factory is None else backend_factory
        )
        self.backend = self._make_backend(config)
        self._reconcile_stale_capacity_holders(self.backend, force=True)

        self._reaper_stop = threading.Event()
        self._reaper_thread = threading.Thread(
            target=self._reaper_loop, daemon=True
        )
        self._reaper_thread.start()

    def _make_backend(self, config: SForgeConfig) -> ContainerBackend:
        backend = self._backend_factory(config)
        if backend is None:
            raise TypeError("backend factory must return a backend")
        return backend

    def _reconcile_stale_capacity_holders(
        self, backend: ContainerBackend, *, force: bool = False,
    ) -> int:
        """Reclaim dead-launcher capacity after backend resource cleanup.

        This is safe to call from every capacity waiter.  A process-local lock and
        monotonic interval bound backend queries, while ``HostJudgeCapacity`` keeps
        the cross-process compare-and-remove atomic.
        """
        reconcile = getattr(backend, "reconcile_judge_capacity_holder", None)
        if not callable(reconcile):
            return 0
        if not self._capacity_reconcile_lock.acquire(blocking=False):
            return 0
        try:
            now = time.monotonic()
            if (
                not force
                and now - self._capacity_reconciled_at
                < JUDGE_CAPACITY_RECONCILE_INTERVAL
            ):
                return 0
            # Record the attempt before invoking the backend so concurrent waiters
            # do not fan out if cleanup is slow or raises.
            self._capacity_reconciled_at = now
            count = 0
            for capacity in (self.host_capacity, self.host_memory_capacity):
                if capacity is None:
                    continue
                reconciled = capacity.reconcile_stale_holders(reconcile)
                count += len(reconciled)
                if reconciled:
                    logger.info(
                        "Reconciled %d stale judge capacity holders", len(reconciled)
                    )
            return count
        finally:
            self._capacity_reconcile_lock.release()

    def _reaper_loop(self) -> None:
        while not self._reaper_stop.is_set():
            self._reaper_stop.wait(GAME_REAPER_INTERVAL)
            self._cleanup_idle_sessions()

    def _cleanup_idle_sessions(self) -> None:
        now = time.time()
        expired: list[str] = []
        with self._game_lock:
            for sid, sess in self.game_sessions.items():
                if now - sess.last_active > GAME_SESSION_IDLE_TIMEOUT:
                    expired.append(sid)
        for sid in expired:
            self._destroy_game_session(sid)

    def _destroy_game_session(self, session_id: str) -> None:
        with self._game_lock:
            sess = self.game_sessions.pop(session_id, None)
        if sess is None:
            return
        try:
            backend = self._get_backend(sess.run_id, sess.task_id)
            backend.cleanup_container(sess.container, logger)
        except Exception:
            logger.exception("Error cleaning up game container for session %s", session_id)
            with self._game_lock:
                self.game_sessions.setdefault(session_id, sess)
            return
        self._archive_game_session(sess)

    def _game_log_dir(self, sess: GameSessionState) -> Path:
        return (
            self.config.log_dir / "runs" / sess.run_id
            / sess.task_id / "submissions" / f"game-{sess.game_num}"
        )

    def _archive_game_session(self, sess: GameSessionState) -> None:
        entry = {
            "type": "game",
            "round": f"game-{sess.game_num}",
            "session_id": sess.session_id,
            "task_id": sess.task_id,
            "max_score": sess.max_score,
            "peak_score": sess.peak_score,
            "final_score": sess.current_score,
            "score": sess.current_score,
            "moves": sess.moves,
            "steps": sess.steps,
        }
        if sess.max_score and sess.max_score > 0:
            entry["pass_rate"] = sess.current_score / sess.max_score
        else:
            entry["pass_rate"] = 0.0
        with self._history_lock:
            history_key = f"{sess.run_id}/{sess.task_id}"
            self.run_history.setdefault(history_key, []).append(entry)

        log_dir = self._game_log_dir(sess)
        log_dir.mkdir(parents=True, exist_ok=True)
        (log_dir / "game_result.json").write_text(json.dumps(entry, indent=2, ensure_ascii=False))

    def _flush_game_step(self, sess: GameSessionState) -> None:
        log_dir = self._game_log_dir(sess)
        log_dir.mkdir(parents=True, exist_ok=True)
        step = sess.steps[-1]
        with open(log_dir / "steps.jsonl", "a") as f:
            f.write(json.dumps(step, ensure_ascii=False) + "\n")

    # --- Token-based session registration ---

    def register_session(self, task_id: str, run_id: str,
                         judge_cpu_limit: int | None = None,
                         judge_mem_limit: str | None = None,
                         backend: str | None = None,
                         k8s_image_registry: str | None = None,
                         k8s_namespace: str | None = None,
                         k8s_node_selector: dict[str, str] | None = None,
                         k8s_kubeconfig: str | None = None,
                         max_agent_submissions: int | None = None,
                         submission_cooldown: int | None = None,
                         e2b_template_map: dict[str, str] | None = None,
                         e2b_template_namespace: str | None = None,
                         e2b_sandbox_ttl: int | None = None) -> str:
        if task_id not in self.tasks:
            raise ValueError(f"Unknown task: {task_id}")
        token = secrets.token_hex(16)
        with self._tokens_lock:
            run_key = self._run_key(run_id, task_id)
            effective_e2b_template_map = (
                self.config.e2b_template_map
                if not e2b_template_map
                else e2b_template_map
            )
            effective_e2b_template_namespace = (
                self.config.e2b_template_namespace
                if not e2b_template_namespace
                else e2b_template_namespace
            )
            effective_e2b_sandbox_ttl = (
                self.config.e2b_sandbox_ttl
                if e2b_sandbox_ttl is None
                else e2b_sandbox_ttl
            )
            e2b_config_changed = backend == "e2b" and (
                effective_e2b_template_map != self.config.e2b_template_map
                or effective_e2b_template_namespace
                != self.config.e2b_template_namespace
                or effective_e2b_sandbox_ttl != self.config.e2b_sandbox_ttl
            )
            run_backend = None
            if self._custom_backend_factory is not None or (backend and (
                backend != self.backend.backend_name or e2b_config_changed
            )):
                effective_config = replace(
                    self.config,
                    backend=backend or self.config.backend,
                    k8s_namespace=k8s_namespace or self.config.k8s_namespace,
                    k8s_node_selector=k8s_node_selector or self.config.k8s_node_selector,
                    k8s_image_registry=k8s_image_registry or self.config.k8s_image_registry,
                    k8s_kubeconfig=k8s_kubeconfig or self.config.k8s_kubeconfig,
                    e2b_template_map=effective_e2b_template_map,
                    e2b_template_namespace=effective_e2b_template_namespace,
                    e2b_sandbox_ttl=effective_e2b_sandbox_ttl,
                    judge_cpu_limit=(self.config.judge_cpu_limit
                                     if judge_cpu_limit is None else judge_cpu_limit),
                    judge_mem_limit=(self.config.judge_mem_limit
                                     if judge_mem_limit is None else judge_mem_limit),
                )
                # A supplied factory owns all registrations, including unchanged
                # backend names. It may enforce template/resource policy. Failure
                # must not publish a token or replace a prior run's configuration.
                run_backend = self._make_backend(effective_config)
            if run_backend is not None:
                self.run_backends[run_key] = run_backend
            self.tokens[token] = {
                "task_id": task_id,
                "run_id": run_id,
                "next_agent": 1,
                "next_auto": 1,
                "judge_cpu_limit": judge_cpu_limit,
                "judge_mem_limit": judge_mem_limit,
                "max_agent_submissions": max_agent_submissions,
                "submission_cooldown": submission_cooldown,
                "last_agent_submit_at": 0.0,
            }
            self.run_resource_limits[run_key] = {
                "judge_cpu_limit": judge_cpu_limit,
                "judge_mem_limit": judge_mem_limit,
            }
        return token

    @staticmethod
    def _run_key(run_id: str, task_id: str) -> str:
        return f"{run_id}/{task_id}"

    def _get_backend(
        self, run_id: str | None = None, task_id: str | None = None,
    ) -> ContainerBackend:
        if run_id and task_id:
            backend = self.run_backends.get(self._run_key(run_id, task_id))
            if backend is not None:
                return backend
        return self.backend

    def resolve_token(self, token: str) -> dict:
        with self._tokens_lock:
            info = self.tokens.get(token)
        if info is None:
            raise KeyError("Invalid token")
        return dict(info)

    def consume_round(self, token: str, kind: str = "agent") -> tuple[str, str, str, int | None, str | None, int | None]:
        """Allocate the next round ID for a token. Returns (task_id, run_id, round_id, cpu, mem, remaining).

        For agent submissions, enforces max_agent_submissions and submission_cooldown.
        Raises SubmissionBudgetExceeded or SubmissionCooldownActive on violation.
        Auto submissions are never limited.
        """
        with self._tokens_lock:
            info = self.tokens.get(token)
            if info is None:
                raise KeyError("Invalid token")

            if kind == "agent":
                max_subs = info.get("max_agent_submissions")
                cooldown = info.get("submission_cooldown")
                next_n = info.get("next_agent", 1)

                if max_subs is not None and next_n > max_subs:
                    raise SubmissionBudgetExceeded(
                        f"Submission budget exhausted ({max_subs}/{max_subs} used)"
                    )
                if cooldown is not None:
                    elapsed = time.time() - info.get("last_agent_submit_at", 0.0)
                    if elapsed < cooldown and info.get("last_agent_submit_at", 0.0) > 0:
                        remaining_wait = int(cooldown - elapsed) + 1
                        raise SubmissionCooldownActive(
                            f"Submission cooldown active — wait {remaining_wait}s before next submission. "
                            f"Continue working on improvements and submit again later."
                        )

                info["last_agent_submit_at"] = time.time()

            counter_key = f"next_{kind}"
            n = info.get(counter_key, 1)
            round_id = f"{kind}-{n}"
            info[counter_key] = n + 1

            remaining = None
            if kind == "agent":
                max_subs = info.get("max_agent_submissions")
                if max_subs is not None:
                    remaining = max_subs - n

        return info["task_id"], info["run_id"], round_id, info.get("judge_cpu_limit"), info.get("judge_mem_limit"), remaining

    def _record_submission(self, run_id: str, submission_id: str, task_id: str, round_id: str | None, report_dict: dict | None, error: str | None, status: str = "completed") -> None:
        entry: dict[str, Any] = {
            "type": "submission",
            "status": status,
            "submission_id": submission_id,
            "task_id": task_id,
            "round": round_id,
        }
        if report_dict:
            entry["pass_rate"] = report_dict.get("pass_rate", 0.0)
            entry["score"] = report_dict.get("score")
            entry["passed"] = report_dict.get("passed", 0)
            entry["failed"] = report_dict.get("failed", 0)
            entry["total_tests"] = report_dict.get("total_tests", 0)
            entry["valid"] = report_dict.get("valid", True)
            entry["summary"] = report_dict.get("summary")
            if status == "completed":
                # Missing fields in older reports are unknown, not success/zero.
                for key in ("timed_out", "runtime_seconds"):
                    if key in report_dict:
                        entry[key] = report_dict[key]
        if error:
            entry["error"] = error
        history_key = f"{run_id}/{task_id}"
        with self._history_lock:
            entries = self.run_history.setdefault(history_key, [])
            for i, e in enumerate(entries):
                if e.get("submission_id") == submission_id:
                    entries[i] = entry
                    return
            entries.append(entry)

    def get_run_history(self, run_id: str, task_id: str | None = None) -> dict:
        history_key = f"{run_id}/{task_id}" if task_id else run_id
        with self._history_lock:
            entries = list(self.run_history.get(history_key, []))

        # Resolve selection policy from task spec
        resolved_tid = task_id
        if not resolved_tid:
            for e in entries:
                if e.get("task_id"):
                    resolved_tid = e["task_id"]
                    break
        task_spec = self.tasks.get(resolved_tid) if resolved_tid else None
        policy = task_spec.judge.selection if task_spec else "pass_rate_first"
        direction = task_spec.judge.score_direction if task_spec else "maximize"

        best = select_best(entries, direction, policy)

        sub_entries = [e for e in entries if e.get("type") == "submission"]
        return {
            "run_id": run_id,
            "best_score": best["best_score"],
            "best_pass_rate": best["best_pass_rate"],
            "best_round": best["best_round"],
            "agent_submissions": sum(1 for e in sub_entries if (e.get("round") or "").startswith("agent-")),
            "auto_submissions": sum(1 for e in sub_entries if (e.get("round") or "").startswith("auto-")),
            "entries": entries,
        }

    def load_tasks(self) -> None:
        benchmark = load_benchmark(self.config.tasks_dir)
        task_list = load_all_tasks(self.config.tasks_dir, benchmark)
        self.tasks = {t.task_id: t for t in task_list}

    def auto_capacity_available(self) -> bool:
        """Whether an `auto` submission may be accepted right now.

        The HTTP layer asks this *before* `consume_round`, so a capacity refusal
        never burns an agent round or a cooldown window.
        """
        # Backlog = accepted but not yet terminal (queued + running). Counting only
        # the not-yet-started queue would report capacity while judges are actually
        # still executing, which is exactly the overlap we are bounding.
        with self._submission_lock:
            in_flight = sum(
                1 for sub in self.submissions.values()
                if sub.get("status") in (SubmissionStatus.QUEUED, SubmissionStatus.RUNNING)
            )
        return in_flight < self.judge_max_backlog

    def _ensure_judge_workers(self) -> None:
        with self._judge_workers_lock:
            while len(self._judge_workers) < self.judge_max_concurrency:
                thread = threading.Thread(target=self._judge_worker_loop,
                                          name=f"sforge-judge-{len(self._judge_workers)}", daemon=True)
                thread.start()
                self._judge_workers.append(thread)

    def _judge_memory_requirement(
        self, task_id: str, requested_limit: str | None,
    ) -> int:
        assert self.host_memory_capacity is not None
        task_limit = getattr(self.tasks[task_id].judge, "mem_limit", None)
        memory_limit = requested_limit or self.config.judge_mem_limit or task_limit
        if memory_limit is None:
            return self.host_memory_capacity.capacity
        try:
            required = parse_bytes(memory_limit)
        except Exception as exc:
            raise RuntimeError(f"Invalid judge memory limit: {memory_limit!r}") from exc
        if required < 1:
            raise RuntimeError("Judge memory limit must be positive")
        if required > self.host_memory_capacity.capacity:
            raise RuntimeError(
                "Judge memory requirement exceeds host memory capacity"
            )
        return required

    def _judge_worker_loop(self) -> None:
        while True:
            submission_id = self._judge_queue.get()
            if submission_id is None:
                self._judge_queue.task_done()
                return
            slot_acquired = False
            memory_acquired = False
            token = f"{os.getpid()}:{submission_id}"
            try:
                with self._judge_pending_lock:
                    payload = self._judge_pending.pop(submission_id, None)
                if payload is None:
                    continue
                task_id, _, run_id, _, _, judge_mem_limit = payload
                backend = self._get_backend(run_id, task_id)
                owner_identity = getattr(backend, "judge_capacity_owner_id", None)
                owner_id = owner_identity() if callable(owner_identity) else None
                memory_units = (
                    self._judge_memory_requirement(task_id, judge_mem_limit)
                    if self.host_memory_capacity is not None else None
                )
                while True:
                    if self._judge_queue_drained.is_set():
                        raise RuntimeError("Judge capacity wait cancelled before grading")
                    slot_acquired = self.host_capacity.try_acquire(token, owner_id)
                    if not slot_acquired:
                        self._reconcile_stale_capacity_holders(backend)
                        time.sleep(0.2)
                        continue
                    if self.host_memory_capacity is None:
                        break
                    memory_acquired = self.host_memory_capacity.try_acquire(
                        token, owner_id, units=memory_units
                    )
                    if memory_acquired:
                        break
                    self.host_capacity.release(token)
                    slot_acquired = False
                    self._reconcile_stale_capacity_holders(backend)
                    time.sleep(0.2)
                self._grade_worker(submission_id, *payload)
            except Exception as exc:
                self._transition_submission(submission_id, SubmissionStatus.ERROR, error=str(exc))
            finally:
                if memory_acquired:
                    try:
                        assert self.host_memory_capacity is not None
                        self.host_memory_capacity.release(token)
                    except Exception:
                        logger.exception("Could not release judge memory %s", token)
                if slot_acquired:
                    try:
                        self.host_capacity.release(token)
                    except Exception:
                        # Preserve the actual grading outcome; a failed release
                        # retains capacity and must not kill the worker pool.
                        logger.exception("Could not release judge slot %s", token)
                self._judge_queue.task_done()

    def _transition_submission(self, submission_id: str, status: SubmissionStatus,
                               report: dict | None = None, error: str | None = None) -> None:
        with self._submission_lock:
            sub = self.submissions[submission_id]
            sub.update(status=status, report=report, error=error)
            self._record_submission(sub["run_id"] or submission_id, submission_id,
                                    sub["task_id"], sub["round"], report, error,
                                    status=status.value)

    def submit(self, task_id: str, archive: bytes, run_id: str | None = None, round: str | None = None,
               judge_cpu_limit: int | None = None, judge_mem_limit: str | None = None) -> str:
        """Submit and grade asynchronously. Returns submission_id for polling."""
        if task_id not in self.tasks:
            raise ValueError(f"Unknown task: {task_id}")

        submission_id = uuid.uuid4().hex[:12]
        log_run_id = run_id or submission_id
        self._ensure_judge_workers()
        with self._submission_lock:
            self.submissions[submission_id] = {
                "status": SubmissionStatus.QUEUED,
                "task_id": task_id,
                "run_id": run_id,
                "round": round,
                "report": None,
                "error": None,
            }
            self._record_submission(log_run_id, submission_id, task_id, round, None, None, status="queued")
        with self._judge_pending_lock:
            self._judge_pending[submission_id] = (
                task_id, archive, run_id, round, judge_cpu_limit, judge_mem_limit)
        self._judge_queue.put(submission_id)
        return submission_id

    def _grade_worker(self, submission_id: str, task_id: str, archive: bytes,
                      run_id: str | None = None, round: int | None = None,
                      judge_cpu_limit: int | None = None, judge_mem_limit: str | None = None) -> None:
        self._transition_submission(submission_id, SubmissionStatus.RUNNING)
        try:
            task_spec = self.tasks[task_id]
            log_run_id = run_id or submission_id
            sub_num = str(round) if round is not None else "1"
            sub_log_dir = (
                self.config.log_dir / "runs" / log_run_id
                / task_id / "submissions" / sub_num
            )
            overrides: dict = {}
            if judge_cpu_limit is not None:
                overrides["judge_cpu_limit"] = judge_cpu_limit
            if judge_mem_limit is not None:
                overrides["judge_mem_limit"] = judge_mem_limit
            config = replace(self.config, **overrides) if overrides else self.config
            report = judge_submission(
                task_spec=task_spec,
                archive=archive,
                config=config,
                backend=self._get_backend(run_id, task_id),
                submission_id=submission_id,
                log_dir=sub_log_dir,
            )
            report_dict = report.to_dict()
            report_dict.pop("score_0_100", None)
            self._transition_submission(submission_id, SubmissionStatus.COMPLETED, report=report_dict)
        except Exception as e:
            self._transition_submission(submission_id, SubmissionStatus.ERROR, error=str(e))

    def get_result(self, submission_id: str) -> dict | None:
        with self._submission_lock:
            result = self.submissions.get(submission_id)
            return dict(result) if result is not None else None

    # --- Game session management ---

    def create_game_session(self, run_id: str, task_id: str) -> tuple[GameSessionState, dict]:
        """Start a game container and create a new game session.

        Returns (session_state, response_from_container).
        """
        task_spec = self.tasks.get(task_id)
        if task_spec is None:
            raise ValueError(f"Unknown task: {task_id}")
        if not task_spec.game_mode:
            raise ValueError(f"Task {task_id} is not a game task")
        if not task_spec.judge.game_server_cmd:
            raise ValueError(f"Task {task_id} has no game_server_cmd")

        with self._game_lock:
            if len(self.game_sessions) >= GAME_SESSION_MAX:
                raise RuntimeError(f"Too many active game sessions ({GAME_SESSION_MAX})")

        # Evict oldest sessions for this run+task if at per-task cap
        with self._game_lock:
            task_sessions = sorted(
                [s for s in self.game_sessions.values() if s.run_id == run_id and s.task_id == task_id],
                key=lambda s: s.game_num,
            )
            to_evict = task_sessions[:len(task_sessions) - GAME_SESSION_PER_RUN_MAX + 1] if len(task_sessions) >= GAME_SESSION_PER_RUN_MAX else []
        for sess in to_evict:
            logger.info("Evicting oldest game session %s for %s/%s", sess.session_id, run_id, task_id)
            self._destroy_game_session(sess.session_id)

        backend = self._get_backend(run_id, task_id)

        if backend.backend_name == "docker":
            from sforge.harness.backend.docker_backend import DockerBackend
            assert isinstance(backend, DockerBackend)
            build_judge_image(task_spec, self.config, backend.client, force_rebuild=False)

        session_id = uuid.uuid4().hex[:12]
        container_name = f"sforge.game.{task_id}.{session_id}"
        port = GAME_CONTAINER_PORT
        env = get_container_env(self.config, include_judge_extra=True)
        game_headers = {}
        if backend.backend_name == "e2b":
            sanitize_e2b_proxy_env(env)
            # E2B exposes the service through a public gateway. Protect the
            # in-sandbox app as well as the outer Judge route.
            game_token = uuid.uuid4().hex
            env["SFORGE_GAME_TOKEN"] = game_token
            game_headers["X-SForge-Game-Token"] = game_token

        rl = self.run_resource_limits.get(self._run_key(run_id, task_id), {})
        cpu = rl.get("judge_cpu_limit")
        mem = rl.get("judge_mem_limit")
        # fall back to task defaults
        if cpu is None:
            cpu = task_spec.judge.cpu_limit
        if mem is None:
            mem = task_spec.judge.mem_limit
        handle = None
        committed = False
        try:
            handle = backend.create_container(
                task_spec.judge_image_key,
                container_name,
                environment=env,
                cpu_limit=cpu,
                mem_limit=mem,
            )
            backend.start_container(handle)
            logger.info(
                "Game container started: %s (%s)", container_name, handle.id[:12],
            )

            backend.copy_to_container(
                handle, GAME_SERVER_APP_PATH,
                PurePosixPath("/tmp/game_server_app.py"),
            )
            backend.exec_run(
                handle, f"/bin/bash -c '{task_spec.judge.game_server_cmd} &'",
                detach=True,
            )

            endpoint = backend.get_service_endpoint(handle, port)
            container_url = endpoint.url
            game_headers = {**endpoint.headers, **game_headers}

            deadline = time.time() + GAME_CONTAINER_READY_TIMEOUT
            while time.time() < deadline:
                try:
                    resp = requests.get(
                        f"{container_url}/health", headers=game_headers, timeout=5,
                    )
                    if resp.status_code == 200:
                        break
                except requests.RequestException:
                    pass
                time.sleep(GAME_CONTAINER_READY_POLL)
            else:
                raise RuntimeError("Game container did not become ready in time")

            gateway_attempts = (
                GAME_GATEWAY_ATTEMPTS if backend.backend_name == "e2b" else 1
            )
            for attempt in range(1, gateway_attempts + 1):
                try:
                    resp = requests.post(
                        f"{container_url}/new", json={}, headers=game_headers,
                        timeout=10,
                    )
                    resp.raise_for_status()
                    data = resp.json()
                    break
                except (requests.RequestException, ValueError) as exc:
                    if attempt == gateway_attempts:
                        raise RuntimeError(
                            "Game gateway failed while creating a session after "
                            f"{gateway_attempts} attempts: {exc}"
                        ) from exc
                    time.sleep(GAME_GATEWAY_BACKOFF * attempt)

            with self._history_lock:
                history_key = f"{run_id}/{task_id}"
                archived = sum(
                    1 for e in self.run_history.get(history_key, [])
                    if e.get("type") == "game"
                )
            with self._game_lock:
                active = sum(
                    1 for s in self.game_sessions.values() if s.run_id == run_id
                )
            game_num = archived + active + 1

            sess = GameSessionState(
                session_id=session_id,
                run_id=run_id,
                task_id=task_id,
                game_num=game_num,
                container=handle,
                container_url=container_url,
                headers=game_headers,
                max_score=data.get("max_score", 0),
                peak_score=data.get("peak_score", 0),
                current_score=data.get("score", 0),
                moves=data.get("moves", 0),
                done=data.get("done", False),
            )
            with self._game_lock:
                self.game_sessions[session_id] = sess
            committed = True
            return sess, data
        except Exception as original_error:
            if handle is not None and not committed:
                try:
                    backend.cleanup_container(handle, logger)
                except Exception as cleanup_error:
                    raise RuntimeError(
                        "Game container initialization failed and cleanup also "
                        f"failed: {cleanup_error}"
                    ) from original_error
            raise

    def game_step(self, session_id: str, action: str) -> dict:
        with self._game_lock:
            sess = self.game_sessions.get(session_id)
        if sess is None:
            raise KeyError(f"Game session not found: {session_id}")

        resp = requests.post(
            f"{sess.container_url}/step",
            json={"action": action},
            headers=sess.headers,
            timeout=10,
        )
        resp.raise_for_status()
        data = resp.json()

        sess.current_score = data.get("score", sess.current_score)
        sess.max_score = data.get("max_score", sess.max_score)
        sess.peak_score = data.get("peak_score", sess.peak_score)
        sess.moves = data.get("moves", sess.moves)
        sess.done = data.get("done", sess.done)
        sess.last_active = time.time()
        sess.steps.append({
            "move": sess.moves,
            "action": action,
            "observation": data.get("observation", ""),
            "score": data.get("score", 0),
            "peak_score": data.get("peak_score", 0),
            "max_score": data.get("max_score", 0),
            "done": data.get("done", False),
        })

        self._flush_game_step(sess)

        if sess.done:
            threading.Thread(
                target=self._auto_close_session,
                args=(session_id,),
                daemon=True,
            ).start()

        return data

    def _auto_close_session(self, session_id: str) -> None:
        with self._game_lock:
            sess = self.game_sessions.pop(session_id, None)
        if sess is None:
            return
        backend = self._get_backend(sess.run_id, sess.task_id)
        if backend.backend_name != "e2b":
            self._archive_game_session(sess)
            try:
                backend.cleanup_container(sess.container, logger)
            except Exception:
                logger.exception(
                    "Error auto-closing game session %s", session_id,
                )
            return
        try:
            backend.cleanup_container(sess.container, logger)
        except Exception:
            logger.exception("Error auto-closing game session %s", session_id)
            with self._game_lock:
                self.game_sessions.setdefault(session_id, sess)
            return
        self._archive_game_session(sess)
        logger.info("Auto-closed done game session %s (max_score=%d)", session_id, sess.max_score)

    def game_status(self, session_id: str) -> dict:
        with self._game_lock:
            sess = self.game_sessions.get(session_id)
        if sess is None:
            raise KeyError(f"Game session not found: {session_id}")

        resp = requests.get(f"{sess.container_url}/status", headers=sess.headers, timeout=5)
        resp.raise_for_status()
        data = resp.json()

        sess.current_score = data.get("score", sess.current_score)
        sess.max_score = data.get("max_score", sess.max_score)
        sess.peak_score = data.get("peak_score", sess.peak_score)
        sess.moves = data.get("moves", sess.moves)
        sess.done = data.get("done", sess.done)
        sess.last_active = time.time()

        return data

    def close_game_session(self, session_id: str) -> dict:
        with self._game_lock:
            sess = self.game_sessions.pop(session_id, None)
        if sess is None:
            raise KeyError(f"Game session not found: {session_id}")

        try:
            resp = requests.post(f"{sess.container_url}/close", headers=sess.headers, timeout=10)
            resp.raise_for_status()
            data = resp.json()
        except Exception:
            data = {
                "final_score": sess.current_score,
                "peak_score": sess.peak_score,
                "max_score": sess.max_score,
                "moves": sess.moves,
            }
        backend = self._get_backend(sess.run_id, sess.task_id)
        if backend.backend_name != "e2b":
            self._archive_game_session(sess)
            try:
                backend.cleanup_container(sess.container, logger)
            except Exception:
                logger.exception(
                    "Error cleaning up game container for session %s",
                    session_id,
                )
            return data
        try:
            backend.cleanup_container(sess.container, logger)
        except Exception:
            with self._game_lock:
                self.game_sessions.setdefault(session_id, sess)
            raise
        self._archive_game_session(sess)

        return data

    def close_all_game_sessions(self, run_id: str, task_id: str) -> int:
        with self._game_lock:
            sessions = [
                (sid, sess) for sid, sess in self.game_sessions.items()
                if sess.run_id == run_id and sess.task_id == task_id
            ]
        backend = self._get_backend(run_id, task_id)
        if backend.backend_name == "e2b":
            with self._game_lock:
                for sid, _ in sessions:
                    self.game_sessions.pop(sid, None)
            failures = []
            for sid, sess in sessions:
                try:
                    backend.cleanup_container(sess.container, logger)
                except Exception as exc:
                    logger.exception(
                        "Error cleaning up game container for session %s", sid,
                    )
                    failures.append((sid, exc))
                    with self._game_lock:
                        self.game_sessions.setdefault(sid, sess)
                    continue
                self._archive_game_session(sess)
            if failures:
                detail = ", ".join(f"{sid}: {exc}" for sid, exc in failures)
                raise RuntimeError(f"Failed to clean up game containers: {detail}")
            return len(sessions)

        # Preserve the existing non-blocking Docker/K8s cleanup behavior.
        containers_to_cleanup = []
        for sid, sess in sessions:
            with self._game_lock:
                self.game_sessions.pop(sid, None)
            self._archive_game_session(sess)
            containers_to_cleanup.append((sid, sess.container))

        def _bg_cleanup():
            for sid, container in containers_to_cleanup:
                try:
                    backend.cleanup_container(container, logger)
                except Exception:
                    logger.exception("Error cleaning up game container for session %s", sid)
        threading.Thread(target=_bg_cleanup, daemon=True).start()
        return len(sessions)



# --- FastAPI app factory ---


def create_app(
    config: SForgeConfig | None = None, *,
    backend_factory: Callable[[SForgeConfig], ContainerBackend] | None = None,
) -> FastAPI:
    """Create one judge with an optional app-local backend construction policy.

    The factory receives the effective configuration at startup and registration.
    It must either return a backend or raise; no fallback bypasses its policy.
    Container execution, grading and result selection remain the native paths.
    """
    if config is None:
        config = load_config()

    app = FastAPI(title="SForge Judge", version=__version__)
    state = JudgeState(config, backend_factory=backend_factory)
    state.load_tasks()

    @app.get("/api/v1/result/{submission_id}")
    def get_result(submission_id: str) -> ResultResponse:
        """Get result of an async submission."""
        result = state.get_result(submission_id)
        if result is None:
            raise HTTPException(status_code=404, detail="Submission not found")
        return ResultResponse(
            submission_id=submission_id,
            status=result["status"],
            report=result["report"],
            error=result["error"],
        )

    @app.post("/api/v1/register")
    def register(req: RegisterRequest) -> RegisterResponse:
        """Register a session and get a token for submissions."""
        if req.admin_secret != state.admin_secret:
            raise HTTPException(status_code=403, detail="Invalid admin secret")
        try:
            token = state.register_session(
                req.task_id, req.run_id,
                judge_cpu_limit=req.judge_cpu_limit,
                judge_mem_limit=req.judge_mem_limit,
                backend=req.backend,
                k8s_image_registry=req.k8s_image_registry,
                k8s_namespace=req.k8s_namespace,
                k8s_node_selector=req.k8s_node_selector,
                k8s_kubeconfig=req.k8s_kubeconfig,
                max_agent_submissions=req.max_agent_submissions,
                submission_cooldown=req.submission_cooldown,
                e2b_template_map=req.e2b_template_map,
                e2b_template_namespace=req.e2b_template_namespace,
                e2b_sandbox_ttl=req.e2b_sandbox_ttl,
            )
            return RegisterResponse(token=token)
        except ValueError as e:
            raise HTTPException(status_code=404, detail=str(e))

    @app.post("/api/v1/submit")
    def submit(
        token: str = Form(...),
        archive: UploadFile = File(...),
        kind: str = Form("agent"),
        admin_secret: str = Form(""),
    ) -> SubmitResponse:
        """Submit an archive using a session token.

        The server resolves task_id, run_id, and assigns a round_id.
        kind=auto requires a valid admin_secret (host-side only).
        """
        if kind not in ("agent", "auto"):
            raise HTTPException(status_code=400, detail="kind must be 'agent' or 'auto'")
        if kind == "auto" and admin_secret != state.admin_secret:
            raise HTTPException(status_code=403, detail="admin_secret required for auto submissions")
        archive_data = archive.file.read()
        with state._submission_lock:
            # Capacity is checked *before* a round is allocated: an auto snapshot that
            # cannot be accepted must not burn an agent round or open a cooldown.
            # `agent` submissions are never refused here, so final grading cannot be
            # starved by auto production.
            if kind == "auto" and not state.auto_capacity_available():
                raise HTTPException(status_code=429,
                                    detail="judge backlog is full; auto submission deferred")
            try:
                task_id, run_id, round_id, judge_cpu_limit, judge_mem_limit, remaining = state.consume_round(token, kind)
            except KeyError:
                raise HTTPException(status_code=401, detail="Invalid token")
            except SubmissionBudgetExceeded as e:
                raise HTTPException(status_code=429, detail=str(e))
            except SubmissionCooldownActive as e:
                raise HTTPException(status_code=429, detail=str(e))
            try:
                submission_id = state.submit(task_id, archive_data, run_id, round_id,
                                             judge_cpu_limit=judge_cpu_limit,
                                             judge_mem_limit=judge_mem_limit)
                return SubmitResponse(
                    submission_id=submission_id,
                    round_id=round_id,
                    status=SubmissionStatus.QUEUED,
                    remaining_submissions=remaining,
                )
            except ValueError as e:
                raise HTTPException(status_code=404, detail=str(e))

    @app.get("/api/v1/history")
    def history(token: str = Query(...), admin_secret: str = Query("")) -> dict:
        """Get run history using a session token.

        Without admin_secret: returns only agent submissions (agent-visible view).
        With valid admin_secret: returns all entries including auto-eval (host-side view).
        """
        try:
            info = state.resolve_token(token)
        except KeyError:
            raise HTTPException(status_code=401, detail="Invalid token")
        full = state.get_run_history(info["run_id"], info["task_id"])
        if admin_secret == state.admin_secret:
            return full
        # Filter to agent-only view: hide auto-eval entries
        agent_entries = [
            e for e in full.get("entries", [])
            if not (e.get("round") or "").startswith("auto-")
        ]
        resolved_tid = info["task_id"]
        task_spec = state.tasks.get(resolved_tid) if resolved_tid else None
        policy = task_spec.judge.selection if task_spec else "pass_rate_first"
        direction = task_spec.judge.score_direction if task_spec else "maximize"
        best = select_best(agent_entries, direction, policy)
        return {
            "run_id": info["run_id"],
            "best_score": best["best_score"],
            "best_pass_rate": best["best_pass_rate"],
            "best_round": best["best_round"],
            "agent_submissions": sum(1 for e in agent_entries if e.get("type") == "submission"),
            "auto_submissions": 0,
            "entries": agent_entries,
        }

    # --- Game session routes ---

    @app.post("/api/v1/game/{run_id}/{task_id}/new")
    def game_new(run_id: str, task_id: str, req: GameNewRequest) -> GameNewResponse:
        """Start a new game session in a dedicated container."""
        try:
            sess, data = state.create_game_session(run_id, task_id)
        except ValueError as e:
            raise HTTPException(404, str(e))
        except (RuntimeError, BuildImageError) as e:
            raise HTTPException(503, str(e))
        return GameNewResponse(
            session_id=sess.session_id,
            observation=data.get("observation", ""),
            score=data.get("score", 0),
            peak_score=data.get("peak_score", 0),
            max_score=data.get("max_score", 0),
            done=data.get("done", False),
            moves=data.get("moves", 0),
        )

    @app.post("/api/v1/game/{run_id}/{task_id}/{session_id}/step")
    def game_step(run_id: str, task_id: str, session_id: str, req: GameStepRequest) -> GameStepResponse:
        try:
            data = state.game_step(session_id, req.action)
        except KeyError:
            raise HTTPException(404, f"Game session not found: {session_id}")
        except requests.HTTPError as e:
            raise HTTPException(400, str(e))
        return GameStepResponse(
            session_id=session_id,
            observation=data.get("observation", ""),
            score=data.get("score", 0),
            peak_score=data.get("peak_score", 0),
            max_score=data.get("max_score", 0),
            done=data.get("done", False),
            moves=data.get("moves", 0),
        )

    @app.get("/api/v1/game/{run_id}/{task_id}/{session_id}/status")
    def game_status(run_id: str, task_id: str, session_id: str) -> GameStatusResponse:
        try:
            data = state.game_status(session_id)
        except KeyError:
            raise HTTPException(404, f"Game session not found: {session_id}")
        return GameStatusResponse(
            session_id=session_id,
            score=data.get("score", 0),
            peak_score=data.get("peak_score", 0),
            max_score=data.get("max_score", 0),
            done=data.get("done", False),
            moves=data.get("moves", 0),
        )

    @app.post("/api/v1/game/{run_id}/{task_id}/{session_id}/close")
    def game_close(run_id: str, task_id: str, session_id: str) -> GameCloseResponse:
        try:
            data = state.close_game_session(session_id)
        except KeyError:
            raise HTTPException(404, f"Game session not found: {session_id}")
        return GameCloseResponse(
            session_id=session_id,
            final_score=data.get("final_score", 0),
            peak_score=data.get("peak_score", 0),
            max_score=data.get("max_score", 0),
            moves=data.get("moves", 0),
        )

    @app.post("/api/v1/game/{run_id}/{task_id}/close-all")
    def game_close_all(run_id: str, task_id: str) -> dict:
        count = state.close_all_game_sessions(run_id, task_id)
        return {"closed": count}

    return app
