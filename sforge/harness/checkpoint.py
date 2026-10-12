# Copyright (c) 2026 ByteDance Ltd. and/or its affiliates
# Licensed under the Apache License, Version 2.0 (the "License").
"""Controller-owned, opt-in preservation of a settled native judge registration.

The bank is private judge state, not an agent upload endpoint. It contains no
session token. It is deliberately narrower than a worker/session checkpoint.
"""

from __future__ import annotations

import hashlib
import json
import math
import os
import re
import shutil
import stat
import tempfile
import time
import uuid
from dataclasses import asdict
from pathlib import Path
from typing import TYPE_CHECKING

from fastapi import HTTPException
from pydantic import BaseModel, ConfigDict, Field

from sforge.harness.selection import select_best

if TYPE_CHECKING:
    from sforge.harness.judge_server import JudgeState

SCHEMA = "sforge_judge_checkpoint_v1"
RESTORE_MARKER = "checkpoint-origin.json"


class CaptureRequest(BaseModel):
    model_config = ConfigDict(extra="forbid", strict=True)
    token: str
    admin_secret: str
    capture_id: str | None = Field(default=None, pattern=r"^[0-9a-f]{32}$")


class RestoreRequest(BaseModel):
    model_config = ConfigDict(extra="forbid", strict=True)
    checkpoint_id: str = Field(pattern=r"^[0-9a-f]{32}$")
    manifest_sha256: str = Field(pattern=r"^[0-9a-f]{64}$")
    run_id: str = Field(pattern=r"^[A-Za-z0-9][A-Za-z0-9_.-]{0,127}$")
    admin_secret: str


class CheckpointUnavailable(ValueError):
    """No complete, compatible native registration can be preserved."""


def _name(value: str) -> str:
    if not isinstance(value, str) or not re.fullmatch(
        r"[A-Za-z0-9][A-Za-z0-9_.-]{0,127}", value
    ):
        raise CheckpointUnavailable("Checkpoint names must be single path components")
    return value


def _encode(value: object) -> bytes:
    return json.dumps(
        value, sort_keys=True, separators=(",", ":"), allow_nan=False
    ).encode()


def _sha(raw: bytes) -> str:
    return hashlib.sha256(raw).hexdigest()


def _read(root: Path, path: Path) -> bytes:
    """Reject symlinks, non-files, replacement and writes during a read."""
    if not path.is_relative_to(root) or path.resolve(strict=True) != path:
        raise CheckpointUnavailable("Checkpoint file is outside its physical owner")
    with os.fdopen(os.open(path, os.O_RDONLY | os.O_NOFOLLOW), "rb") as f:
        before = os.fstat(f.fileno())
        if not stat.S_ISREG(before.st_mode):
            raise CheckpointUnavailable("Checkpoint component is not a regular file")
        raw = f.read()
        after = os.fstat(f.fileno())

    def signature(s):
        return s.st_dev, s.st_ino, s.st_size, s.st_mtime_ns, s.st_ctime_ns

    if (
        signature(before) != signature(after)
        or signature(after) != signature(path.stat(follow_symlinks=False))
        or path.resolve(strict=True) != path
        or len(raw) != before.st_size
    ):
        raise CheckpointUnavailable("Checkpoint file changed while being read")
    return raw


def _write(path: Path, raw: bytes) -> None:
    with os.fdopen(
        os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600), "wb"
    ) as f:
        f.write(raw)
        f.flush()
        os.fsync(f.fileno())


def _sync_directory(path: Path) -> None:
    descriptor = os.open(path, os.O_RDONLY | os.O_DIRECTORY)
    try:
        os.fsync(descriptor)
    finally:
        os.close(descriptor)


class JudgeCheckpoints:
    def __init__(self, state: JudgeState):
        self.state = state
        self.root = state.config.log_dir.resolve()
        self.bank = self.root / "checkpoints"

    def _binding(self, task_id: str) -> dict:
        task = self.state.tasks[task_id]
        if task.game_mode or self.state.backend.backend_name != "docker":
            raise CheckpointUnavailable(
                "Checkpoint v1 supports non-game Docker registrations"
            )
        import sforge

        source = hashlib.sha256()
        source_root = Path(sforge.__file__).parent
        for path in sorted(source_root.rglob("*.py")):
            source.update(path.relative_to(source_root).as_posix().encode() + b"\0")
            source.update(hashlib.sha256(path.read_bytes()).digest())
        # Image tags alone do not establish the same evaluator bytes.
        image = self.state.backend.client.images.get(task.judge_image_key)
        return {
            "native_source_sha256": source.hexdigest(),
            "task_spec_sha256": _sha(_encode(asdict(task))),
            "judge_image_key": task.judge_image_key,
            "judge_image_id": image.id,
            "backend": "docker",
            "selection": task.judge.selection,
            "score_direction": task.judge.score_direction,
        }

    def _selection(self, task_id: str, history: list[dict]) -> str:
        task = self.state.tasks[task_id]
        return select_best(history, task.judge.score_direction, task.judge.selection)[
            "best_round"
        ]

    def _packet(
        self, identifier: str, expected_sha256: str | None = None
    ) -> tuple[bytes, dict]:
        folder = self.bank / identifier
        encoded = _read(self.root, folder / "manifest.json")
        witnessed = _read(self.root, folder / "manifest.sha256").decode("ascii")
        if _sha(encoded) != witnessed or (
            expected_sha256 is not None and witnessed != expected_sha256
        ):
            raise CheckpointUnavailable("Checkpoint manifest digest differs")
        packet = json.loads(encoded)
        self._validate(packet)
        incumbent = packet["incumbent"]
        if incumbent is not None:
            archive = _read(self.root, folder / "incumbent.tar.gz")
            if (
                len(archive) != incumbent["archive_bytes"]
                or _sha(archive) != incumbent["archive_sha256"]
            ):
                raise CheckpointUnavailable("Native selected incumbent bytes differ")
        return encoded, packet

    def _validate(self, packet: dict) -> None:
        from sforge.harness.judge_server import submission_history_entry

        if packet.get("schema_version") != SCHEMA:
            raise CheckpointUnavailable("Unsupported native checkpoint schema")
        task_id = _name(packet["task_id"])
        _name(packet["source_run_id"])
        if (
            not isinstance(packet["source_registration_id"], str)
            or not re.fullmatch(r"[0-9a-f]{32}", packet["source_registration_id"])
            or type(packet["captured_at_epoch"]) not in (int, float)
            or not math.isfinite(packet["captured_at_epoch"])
            or packet["captured_at_epoch"] < 0
        ):
            raise CheckpointUnavailable("Invalid native capture provenance")
        if task_id not in self.state.tasks or packet["evaluator"] != self._binding(
            task_id
        ):
            raise CheckpointUnavailable("Checkpoint task/evaluator/source differs")
        opportunity = packet["opportunity"]
        next_round = opportunity["next_agent"]
        limit = opportunity["max_agent_submissions"]
        cooldown = opportunity["submission_cooldown"]
        remaining = opportunity["remaining_cooldown_seconds"]
        if (
            type(next_round) is not int
            or next_round < 1
            or type(opportunity["next_auto"]) is not int
            or opportunity["next_auto"] != 1
            or (
                limit is not None
                and (type(limit) is not int or limit < 0 or next_round > limit + 1)
            )
            or (cooldown is not None and (type(cooldown) is not int or cooldown < 0))
            or type(remaining) not in (float, int)
            or not 0 <= remaining <= (cooldown or 0)
        ):
            raise CheckpointUnavailable("Invalid preserved opportunity state")
        history, results = packet["history"], packet["results"]
        expected_rounds = {f"agent-{i}" for i in range(1, next_round)}
        if (
            len(history) != len(expected_rounds)
            or {e["round"] for e in history} != expected_rounds
            or len({e["submission_id"] for e in history}) != len(history)
            or set(results) != {e["submission_id"] for e in history}
        ):
            raise CheckpointUnavailable(
                "Consumed rounds and released results are not reconciled"
            )
        for entry in history:
            result = results[entry["submission_id"]]
            status = result["status"]
            if (
                status not in ("completed", "error")
                or (
                    status == "completed"
                    and (
                        not isinstance(result["report"], dict)
                        or result["error"] is not None
                    )
                )
                or (
                    status == "error"
                    and (
                        result["report"] is not None
                        or not isinstance(result["error"], str)
                    )
                )
                or entry
                != submission_history_entry(
                    entry["submission_id"],
                    task_id,
                    entry["round"],
                    result["report"],
                    result["error"],
                    status,
                )
            ):
                raise CheckpointUnavailable(
                    "Released native history and result details differ"
                )
        selected = self._selection(task_id, history)
        incumbent = packet["incumbent"]
        if (selected and (incumbent is None or incumbent["round"] != selected)) or (
            not selected and incumbent is not None
        ):
            raise CheckpointUnavailable(
                "Checkpoint incumbent differs from native selection"
            )
        resources = packet["resources"]
        if (
            set(resources) != {"judge_cpu_limit", "judge_mem_limit"}
            or (
                resources["judge_cpu_limit"] is not None
                and (
                    type(resources["judge_cpu_limit"]) is not int
                    or resources["judge_cpu_limit"] <= 0
                )
            )
            or (
                resources["judge_mem_limit"] is not None
                and not isinstance(resources["judge_mem_limit"], str)
            )
        ):
            raise CheckpointUnavailable("Invalid preserved resource profile")
        task = self.state.tasks[task_id]
        for name in ("judge_cpu_limit", "judge_mem_limit"):
            configured = getattr(self.state.config, name)
            effective = (
                configured
                if configured is not None
                else getattr(task.judge, name.removeprefix("judge_"))
            )
            # None is an unset override in native grading, so it cannot express
            # an originally unbounded limit on a now-bounded controller.
            if resources[name] is None and effective is not None:
                raise CheckpointUnavailable("Unbounded native resource profile changed")

    @staticmethod
    def _reference(identifier: str, encoded: bytes, packet: dict) -> dict:
        return {
            "checkpoint_id": identifier,
            "manifest_sha256": _sha(encoded),
            "task_id": packet["task_id"],
            "source_run_id": packet["source_run_id"],
            "opportunity": packet["opportunity"],
            "incumbent": packet["incumbent"],
        }

    def capture(self, token: str, capture_id: str | None = None) -> dict:
        state = self.state
        # Shared native registration/round/history publication lock order.
        with state._registration_lock, state._tokens_lock, state._history_lock:
            info = state.tokens.get(token)
            if info is None:
                raise CheckpointUnavailable("Unknown source registration")
            run, task_id = _name(info["run_id"]), _name(info["task_id"])
            identifier = (
                _name(capture_id) if capture_id is not None else uuid.uuid4().hex
            )
            destination = self.bank / identifier
            if destination.exists():
                encoded, packet = self._packet(identifier)
                if packet["source_registration_id"] != info["registration_id"]:
                    raise CheckpointUnavailable(
                        "Capture identity belongs to another registration"
                    )
                # A retry reads the original point, never a later source state.
                return self._reference(identifier, encoded, packet)
            if state._get_backend(run, task_id) is not state.backend:
                raise CheckpointUnavailable(
                    "Checkpoint requires the configured Docker backend"
                )
            history = state.run_history.get(state._run_key(run, task_id), [])
            results = {}
            for entry in history:
                result = state.submissions.get(entry["submission_id"])
                if (
                    result is None
                    or result["run_id"] != run
                    or result["task_id"] != task_id
                    or result["round"] != entry["round"]
                ):
                    raise CheckpointUnavailable("Released native result is unavailable")
                results[entry["submission_id"]] = {
                    key: result[key] for key in ("status", "report", "error")
                }
            observed = time.time()
            last, cooldown = info["last_agent_submit_at"], info["submission_cooldown"]
            selected = self._selection(task_id, history)
            raw = None
            incumbent = None
            if selected:
                raw = _read(
                    self.root,
                    self.root
                    / "runs"
                    / run
                    / task_id
                    / "submissions"
                    / selected
                    / "submission.tar.gz",
                )
                incumbent = {
                    "round": selected,
                    "archive_bytes": len(raw),
                    "archive_sha256": _sha(raw),
                }
            task = state.tasks[task_id]
            packet = {
                "schema_version": SCHEMA,
                "task_id": task_id,
                "source_run_id": run,
                "source_registration_id": info["registration_id"],
                "captured_at_epoch": observed,
                "evaluator": self._binding(task_id),
                "resources": {
                    "judge_cpu_limit": info["judge_cpu_limit"]
                    if info["judge_cpu_limit"] is not None
                    else (
                        state.config.judge_cpu_limit
                        if state.config.judge_cpu_limit is not None
                        else task.judge.cpu_limit
                    ),
                    "judge_mem_limit": info["judge_mem_limit"]
                    if info["judge_mem_limit"] is not None
                    else (
                        state.config.judge_mem_limit
                        if state.config.judge_mem_limit is not None
                        else task.judge.mem_limit
                    ),
                },
                "opportunity": {
                    "next_agent": info["next_agent"],
                    "next_auto": info["next_auto"],
                    "max_agent_submissions": info["max_agent_submissions"],
                    "submission_cooldown": cooldown,
                    "remaining_cooldown_seconds": max(
                        0, last + (cooldown or 0) - observed
                    )
                    if last
                    else 0,
                },
                "history": history,
                "results": results,
                "incumbent": incumbent,
            }
            self._validate(packet)
            encoded = _encode(
                packet
            )  # Freeze all references before leaving native locks.
            self.bank.mkdir(mode=0o700, parents=True, exist_ok=True)
            if (
                self.bank.resolve() != self.bank
                or stat.S_IMODE(self.bank.stat().st_mode) & 0o077
            ):
                raise CheckpointUnavailable("Checkpoint bank must be physically owned")
            temporary = Path(tempfile.mkdtemp(prefix=".capture-", dir=self.bank))
            try:
                _write(temporary / "manifest.json", encoded)
                _write(temporary / "manifest.sha256", _sha(encoded).encode("ascii"))
                if raw is not None:
                    _write(temporary / "incumbent.tar.gz", raw)
                if destination.exists():
                    raise CheckpointUnavailable("Checkpoint identifier already exists")
                _sync_directory(temporary)
                temporary.rename(destination)
                _sync_directory(self.bank)
            finally:
                if temporary.exists():
                    shutil.rmtree(temporary)
            return self._reference(identifier, encoded, packet)

    def restore(self, identifier: str, manifest_sha256: str, run_id: str) -> str:
        state = self.state
        identifier, run_id = _name(identifier), _name(run_id)
        with state._registration_lock:
            _, packet = self._packet(identifier, manifest_sha256)
            task_id = packet["task_id"]
            if run_id == packet["source_run_id"]:
                raise CheckpointUnavailable(
                    "Continuation requires a fresh run identity"
                )
            with state._tokens_lock, state._history_lock:
                if any(
                    info["run_id"] == run_id for info in state.tokens.values()
                ) or any(key.split("/", 1)[0] == run_id for key in state.run_history):
                    raise CheckpointUnavailable("Destination run already exists")
            runs = self.root / "runs"
            runs.mkdir(parents=True, exist_ok=True)
            if runs.resolve() != runs:
                raise CheckpointUnavailable("Run directory must be physically owned")
            destination = runs / run_id
            # Exclusive filesystem reservation also rejects interrupted imports
            # from another process. Never delete or overwrite someone else's run.
            destination.mkdir(mode=0o700)
            token = None
            results = {}
            try:
                prepared = state._prepare_session(
                    task_id,
                    run_id,
                    **packet["resources"],
                    max_agent_submissions=packet["opportunity"][
                        "max_agent_submissions"
                    ],
                    submission_cooldown=packet["opportunity"]["submission_cooldown"],
                )
                token = prepared[2]
                info = prepared[0]
                info["next_agent"] = packet["opportunity"]["next_agent"]
                info["next_auto"] = packet["opportunity"]["next_auto"]
                remaining = packet["opportunity"]["remaining_cooldown_seconds"]
                cooldown = info["submission_cooldown"] or 0
                # Pause duration is not elapsed research or an evaluation refill.
                info["last_agent_submit_at"] = (
                    time.time() - cooldown + remaining if remaining else 0.0
                )
                history, results = [], {}
                for entry in packet["history"]:
                    new_id = uuid.uuid4().hex[:12]
                    history.append({**entry, "submission_id": new_id})
                    results[new_id] = {
                        **packet["results"][entry["submission_id"]],
                        "task_id": task_id,
                        "run_id": run_id,
                        "round": entry["round"],
                    }
                    report = results[new_id]["report"]
                    if report is not None:
                        folder = destination / task_id / "submissions" / entry["round"]
                        folder.mkdir(parents=True)
                        _write(folder / "report.json", _encode(report))
                incumbent = packet["incumbent"]
                if incumbent is not None:
                    archive = _read(
                        self.root, self.bank / identifier / "incumbent.tar.gz"
                    )
                    if (
                        len(archive) != incumbent["archive_bytes"]
                        or _sha(archive) != incumbent["archive_sha256"]
                    ):
                        raise CheckpointUnavailable(
                            "Native selected incumbent bytes differ"
                        )
                    _write(
                        destination
                        / task_id
                        / "submissions"
                        / incumbent["round"]
                        / "submission.tar.gz",
                        archive,
                    )
                origin = {
                    "schema_version": SCHEMA,
                    "checkpoint_id": identifier,
                    "manifest_sha256": manifest_sha256,
                    "source_run_id": packet["source_run_id"],
                    "source_registration_id": packet["source_registration_id"],
                    "task_id": task_id,
                    "submission_id_map": {
                        old["submission_id"]: new["submission_id"]
                        for old, new in zip(packet["history"], history)
                    },
                }
                _write(destination / RESTORE_MARKER, _encode(origin))
                for directory in sorted(
                    (p for p in destination.rglob("*") if p.is_dir()),
                    key=lambda p: len(p.parts),
                    reverse=True,
                ):
                    _sync_directory(directory)
                _sync_directory(destination)
                _sync_directory(runs)
                # Publish new authority and all retained facts together. Native
                # counters, history and selection remain their existing owners.
                with state._tokens_lock, state._history_lock:
                    state._publish_session(info, prepared[1], token)
                    state.submissions.update(results)
                    state.run_history[state._run_key(run_id, task_id)] = history
                    state._checkpoint_runs.add(run_id)
                return token
            except BaseException:
                if token is not None:
                    with state._tokens_lock, state._history_lock:
                        state.tokens.pop(token, None)
                        state.run_history.pop(state._run_key(run_id, task_id), None)
                        for sid in results:
                            state.submissions.pop(sid, None)
                        state.run_resource_limits.pop(
                            state._run_key(run_id, task_id), None
                        )
                        state.run_backends.pop(state._run_key(run_id, task_id), None)
                        state._checkpoint_runs.discard(run_id)
                shutil.rmtree(destination)
                raise


def install_routes(app, state: JudgeState) -> None:
    """No bank creation or routes when the service opt-in is absent."""
    from docker.errors import DockerException

    bank = JudgeCheckpoints(state)

    def authorize(secret: str) -> None:
        import secrets

        if not secrets.compare_digest(
            secret.encode("utf-8"), state.admin_secret.encode("ascii")
        ):
            raise HTTPException(403, "Fresh controller admin authority is required")

    @app.post("/api/v1/checkpoint/capture")
    def capture(request: CaptureRequest) -> dict:
        authorize(request.admin_secret)
        try:
            return bank.capture(request.token, request.capture_id)
        except CheckpointUnavailable as error:
            raise HTTPException(409, str(error)) from error
        except (OSError, ValueError, KeyError, TypeError, DockerException) as error:
            raise HTTPException(
                409, "Native checkpoint source is incomplete or unavailable"
            ) from error

    @app.post("/api/v1/checkpoint/restore")
    def restore(request: RestoreRequest) -> dict:
        authorize(request.admin_secret)
        try:
            token = bank.restore(
                request.checkpoint_id, request.manifest_sha256, request.run_id
            )
            return {
                "token": token,
                "run_id": request.run_id,
                "checkpoint_id": request.checkpoint_id,
                "manifest_sha256": request.manifest_sha256,
            }
        except CheckpointUnavailable as error:
            raise HTTPException(409, str(error)) from error
        except (OSError, ValueError, KeyError, TypeError, DockerException) as error:
            raise HTTPException(
                409,
                "Native checkpoint or fresh destination is unavailable or incompatible",
            ) from error
