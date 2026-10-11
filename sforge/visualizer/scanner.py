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

"""Scan a runs directory into Run/Submission models.

Layout expected:
    <runs_dir>/<run_id>/<task_id>/
        final_result.json           (optional – missing means run was aborted)
        evolve_state.json           (optional)
        submissions/<n>/report.json (optional; n is integer)

The scanner is cheap: each request does a shallow directory walk and only
opens the top-level JSONs. Per-submission `test_details` is loaded lazily
by `load_submission()` / `load_submission_tests()`.
"""

from __future__ import annotations

import datetime as _dt
import json
import math
import os
import re
import subprocess
import time
from dataclasses import replace
from pathlib import Path
from typing import Optional

from sforge.visualizer.models import Run, Submission, TestResult


# ── Experiment grouping ──────────────────────────────────────────────────────
# A single experiment is typically launched across several machines, producing
# run_ids that share a stem but differ only in a trailing -<machine>-<timestamp>
# (e.g. glm51-n35-160-152-20260528172933 .. -156-...). For avg@N / ELO compares
# we want to merge those sibling runs into one group, while keeping distinct
# experiments (different date / env prefix) separate.
_RUN_PREFIX_RE = re.compile(r"-\d+-\d{14}$")  # trailing -<machine>-<14-digit ts>
_RUN_TS_RE = re.compile(r"-\d{14}$")          # trailing -<14-digit ts> only


def run_group_key(run_id: str) -> str:
    """Group key for a run_id: strip a trailing -<machine>-<timestamp> so that
    sibling runs of the same experiment across machines collapse into one group
    (e.g. glm51-n35-160-152-2026... -> glm51-n35-160). run_ids without that
    suffix (e.g. 0530-glm51-new-env) are returned unchanged."""
    stripped = _RUN_PREFIX_RE.sub("", run_id)
    if stripped != run_id:
        return stripped
    return _RUN_TS_RE.sub("", run_id)


# ── Docker container status cache ────────────────────────────────────────────
# Probing per-task container status via `docker inspect` was the dominant
# request cost (≈7s on 297 calls). One `docker ps -a` listing satisfies all
# probes; cache it for a few seconds since container state changes slowly.
_DOCKER_CACHE_TTL = 5.0  # seconds
_docker_cache: dict[str, str] = {}
_docker_cache_ts: float = 0.0
_infra_error_cache: dict[Path, tuple[int, int, bool]] = {}


def _docker_status_map() -> dict[str, str]:
    """Return {container_name: status} for all `sforge.*` containers.

    Cached for `_DOCKER_CACHE_TTL` seconds. Returns empty dict if Docker is
    unavailable, which causes downstream code to fall back to mtime-based
    abort detection.
    """
    global _docker_cache, _docker_cache_ts
    now = time.time()
    if now - _docker_cache_ts < _DOCKER_CACHE_TTL:
        return _docker_cache
    fresh: dict[str, str] = {}
    try:
        r = subprocess.run(
            ["docker", "ps", "-a", "--format", "{{.Names}}\t{{.State}}",
             "--filter", "name=sforge."],
            capture_output=True, text=True, timeout=3,
        )
        if r.returncode == 0:
            for line in r.stdout.splitlines():
                if "\t" in line:
                    name, state = line.split("\t", 1)
                    fresh[name.strip()] = state.strip()
    except (subprocess.TimeoutExpired, FileNotFoundError, OSError):
        pass
    _docker_cache = fresh
    _docker_cache_ts = now
    return _docker_cache


def _safe_load_json(path: Path) -> Optional[dict]:
    try:
        return json.loads(path.read_text())
    except (OSError, json.JSONDecodeError):
        return None


def _finite_or_none(value) -> Optional[float]:
    """Coerce to float, returning None for missing/NaN/inf values.

    Rescaled scores are written as JSON `null` (missing) or, for degenerate
    rescale params, `NaN` — neither should surface as a real data point.
    """
    if value is None:
        return None
    try:
        v = float(value)
    except (TypeError, ValueError):
        return None
    return v if math.isfinite(v) else None


def _detect_infra_error(task_dir: Path) -> bool:
    """True when run_agent.log contains a Python-logging ERROR-level line.

    Marks infrastructure failures (disk exhaustion, docker timeouts, crashes,
    and any future error logged at ERROR level) without hardcoding causes.
    Matches " - ERROR - " specifically so normal WARNING lines (e.g. game
    tasks' "404 Client Error" for a missing final archive) are not flagged.
    """
    log = task_dir / "run_agent.log"
    if not log.exists():
        return False
    try:
        st = log.stat()
    except OSError:
        return False
    key = (st.st_mtime_ns, st.st_size)
    cached = _infra_error_cache.get(log)
    if cached and cached[:2] == key:
        return cached[2]
    try:
        with log.open("r", errors="replace") as fh:
            has_error = any(" - ERROR - " in line for line in fh)
    except OSError:
        has_error = False
    _infra_error_cache[log] = (key[0], key[1], has_error)
    return has_error


def _task_created_at(task_dir: Path) -> float:
    started_at_path = task_dir / "started_at"
    if started_at_path.is_file():
        try:
            lines = started_at_path.read_text().strip().splitlines()
            return float(lines[-1])
        except (OSError, ValueError, IndexError):
            pass

    log_path = task_dir / "run_agent.log"
    try:
        with log_path.open("r", errors="replace") as fh:
            for line in fh:
                try:
                    return _dt.datetime.strptime(line[:19], "%Y-%m-%d %H:%M:%S").timestamp()
                except ValueError:
                    continue
    except OSError:
        pass

    try:
        return task_dir.stat().st_mtime
    except OSError:
        return 0.0


def _task_mtime(task_dir: Path) -> float:
    try:
        return task_dir.stat().st_mtime
    except OSError:
        return 0.0


# ── Directory-layout detection ───────────────────────────────────────────────
# Runs may be stored flat (2-level: <runs_dir>/<run_id>/<task>/) or grouped by
# machine (3-level: <runs_dir>/<ip>/<run_id>/<task>/). We detect per-entry which
# layout applies by looking for task-dir markers one level down.
_TASK_DIR_MARKERS = ("final_result.json", "run_agent.log", "started_at", "evolve_state.json")


def _is_task_dir(d: Path) -> bool:
    """True if `d` looks like a task directory (a leaf holding a run's output)."""
    try:
        if (d / "submissions").is_dir():
            return True
        return any((d / m).exists() for m in _TASK_DIR_MARKERS)
    except OSError:
        return False


def _parse_round_label(name: str) -> tuple[str, int]:
    """Decode a submissions/<name> folder into (kind, seq).

    Schemes:
        "3"           → ("agent", 3)   legacy numeric folders (pre-auto-eval)
        "agent-3"     → ("agent", 3)
        "auto-7"      → ("auto", 7)
        "game-2"      → ("game", 2)
        anything else → ("unknown", 0)
    """
    if name.isdigit():
        return "agent", int(name)
    if "-" in name:
        prefix, _, num = name.partition("-")
        if prefix in ("agent", "auto", "game") and num.isdigit():
            return prefix, int(num)
    return "unknown", 0


def _scan_submissions_shallow(task_dir: Path) -> list[Submission]:
    """List submissions with summary info only (no test_details)."""
    submissions: list[Submission] = []
    sub_root = task_dir / "submissions"
    if not sub_root.is_dir():
        return submissions

    for entry in sorted(sub_root.iterdir(), key=lambda p: (p.stat().st_mtime, p.name)):
        if not entry.is_dir():
            continue
        kind, seq = _parse_round_label(entry.name)
        if kind == "unknown":
            continue
        if kind == "game":
            game_result_path = entry / "game_result.json"
            steps_path = entry / "steps.jsonl"
            data = _safe_load_json(game_result_path) or {}

            # In-flight sessions only have steps.jsonl — derive live state
            # from the last step record.
            if not data and steps_path.is_file():
                try:
                    with steps_path.open("rb") as fh:
                        last_line = b""
                        for line in fh:
                            if line.strip():
                                last_line = line
                    if last_line:
                        last = json.loads(last_line.decode())
                        data = {
                            "score": last.get("score", 0),
                            "final_score": last.get("score", 0),
                            "peak_score": last.get("peak_score", 0),
                            "max_score": last.get("max_score", 0),
                            "moves": last.get("move", 0),
                        }
                except (OSError, json.JSONDecodeError):
                    pass

            try:
                if game_result_path.is_file():
                    mtime = game_result_path.stat().st_mtime
                elif steps_path.is_file():
                    mtime = steps_path.stat().st_mtime
                else:
                    mtime = entry.stat().st_mtime
            except OSError:
                mtime = 0.0
            max_score = float(data.get("max_score", 0) or 0)
            final_score = float(data.get("final_score", data.get("score", 0)) or 0)
            peak_score = float(data.get("peak_score", final_score) or 0)
            pass_rate = (final_score / max_score) if max_score > 0 else 0.0
            submissions.append(
                Submission(
                    round_label=entry.name,
                    seq=seq,
                    kind=kind,
                    path=entry,
                    submitted_at=mtime,
                    submission_id=data.get("session_id", ""),
                    total_tests=0,
                    passed=0,
                    failed=0,
                    errors=0,
                    pass_rate=pass_rate,
                    score=final_score,
                    max_score=max_score if max_score > 0 else None,
                    peak_score=peak_score if peak_score > 0 else None,
                    timed_out=False,
                    runtime_seconds=float(data.get("moves", 0) or 0),
                )
            )
            continue
        report_path = entry / "report.json"
        data = _safe_load_json(report_path)
        # A queued/running directory is not a scored zero. Likewise, an
        # explicitly invalid evaluation must not become a curve observation.
        if not data or data.get("valid") is False:
            continue
        ts = data.get("submitted_at")
        if ts is not None:
            try:
                mtime = float(ts)
            except (TypeError, ValueError):
                mtime = 0.0
        else:
            try:
                mtime = report_path.stat().st_mtime if report_path.is_file() else entry.stat().st_mtime
            except OSError:
                mtime = 0.0
        submissions.append(
            Submission(
                round_label=entry.name,
                seq=seq,
                kind=kind,
                path=entry,
                submitted_at=mtime,
                submission_id=data.get("submission_id", ""),
                total_tests=int(data.get("total_tests", 0) or 0),
                passed=int(data.get("passed", 0) or 0),
                failed=int(data.get("failed", 0) or 0),
                errors=int(data.get("errors", 0) or 0),
                pass_rate=float(data.get("pass_rate", 0.0) or 0.0),
                score=data.get("score"),
                score_0_100=_finite_or_none(data.get("score_0_100")),
                timed_out=bool(data.get("timed_out", False)),
                runtime_seconds=float(data.get("runtime_seconds", 0.0) or 0.0),
            )
        )
    # Game sessions are ordered by seq (start order — game_num is assigned
    # monotonically at /new), not by mtime which reflects close time.
    def _sort_key(s: Submission) -> tuple:
        primary = float(s.seq) if s.kind == "game" else s.submitted_at
        return (primary, s.seq)
    submissions.sort(key=_sort_key)
    return submissions


def _peek_model(task_dir: Path) -> str:
    """Extract model from agent_output.txt when final_result.json has none.

    Supports formats:
    - Claude Code JSONL: an init event line with {"type":"system","model":"..."}
    - SForge supervisor wrapper: Command: claude ... --model <model>
    - Codex plain text: header block contains `model: ...`
    """
    log_path = task_dir / "agent_output.txt"
    if not log_path.is_file():
        return ""
    try:
        with log_path.open("r", errors="replace") as fh:
            head = fh.read(4096)
    except OSError:
        return ""
    for line in head.splitlines():
        stripped = line.strip()
        if stripped.startswith("{"):
            try:
                init = json.loads(stripped)
                if init.get("type") == "system" and init.get("model"):
                    return init["model"]
            except (json.JSONDecodeError, KeyError):
                pass
    if "OpenAI Codex" in head:
        for line in head.splitlines():
            stripped = line.strip()
            if stripped.startswith("model:"):
                return stripped.split(":", 1)[1].strip()
    return ""


def _peek_agent(task_dir: Path) -> str:
    """Infer the agent name from run_agent.log when final_result.json is absent."""
    log_path = task_dir / "run_agent.log"
    if not log_path.is_file():
        return ""
    try:
        with log_path.open("r", errors="replace") as fh:
            head = fh.read(4096)
    except OSError:
        return ""
    if "Running agent: claude " in head or "Running agent: claude\n" in head:
        return "claude-code"
    if "Running agent: codex " in head or "Running agent: codex\n" in head:
        return "codex"
    if "Running agent: opencode " in head or "Running agent: opencode\n" in head:
        return "opencode"
    if "Running agent: aider " in head or "Running agent: aider\n" in head:
        return "aider"
    # New harness format: "Agent supervisor attempt N: claude -p ..."
    for line in head.splitlines():
        if "Agent supervisor attempt" not in line:
            continue
        after_colon = line.split(":", 4)[-1].strip()
        if after_colon.startswith("claude ") or after_colon.startswith("claude\n"):
            return "claude-code"
        if after_colon.startswith("codex ") or after_colon.startswith("codex\n"):
            return "codex"
        if after_colon.startswith("opencode ") or after_colon.startswith("opencode\n"):
            return "opencode"
        if after_colon.startswith("aider ") or after_colon.startswith("aider\n"):
            return "aider"
    return ""


def _select_best_submission(
    submissions: list[Submission],
    score_direction: str,
) -> Optional[Submission]:
    """Pick the best submission respecting score_direction."""
    has_score = any(s.score is not None for s in submissions)
    if not submissions:
        return None
    if has_score:
        sentinel = float('-inf') if score_direction != "minimize" else float('inf')
        if score_direction == "minimize":
            return min(submissions, key=lambda s: s.score if s.score is not None else sentinel)
        return max(submissions, key=lambda s: s.score if s.score is not None else sentinel)
    return max(submissions, key=lambda s: s.pass_rate)


def _build_run(
    run_id: str,
    task_dir: Path,
    task_meta: dict[str, dict] | None = None,
    ip: str = "",
    *,
    include_submissions: bool = True,
) -> Run:
    task = task_dir.name
    meta = (task_meta or {}).get(task, {})
    score_direction = meta.get("score_direction", "maximize")
    is_score_task = meta.get("is_score_task", False)

    final = _safe_load_json(task_dir / "final_result.json")
    final_best_score = final.get("best_score") if final else None
    needs_summary = (
        include_submissions
        or final is None
        or (is_score_task and final_best_score in (None, "null"))
    )
    state = (_safe_load_json(task_dir / "evolve_state.json") or {}) if needs_summary else {}

    created_at = _task_created_at(task_dir) if needs_summary else _task_mtime(task_dir)

    submissions = _scan_submissions_shallow(task_dir) if needs_summary else []

    # If evolve_state.json carries per-submission kind (new harness), override
    # the kind derived from folder names. Matches by round label.
    state_subs = state.get("submissions") or []
    if state_subs:
        state_map = {str(s.get("round", "")): s for s in state_subs}
        for sub in submissions:
            entry = state_map.get(sub.round_label)
            if entry:
                k = str(entry.get("kind", ""))
                if k in ("agent", "auto"):
                    sub.kind = k
                ts = entry.get("at")
                if ts:
                    sub.submitted_at = float(ts)

    submissions.sort(key=lambda s: (s.submitted_at, s.seq))

    # Rescaled 0-100 is always higher-is-better (each rescale kind maps the
    # best raw score to 100), so the best rescaled score is simply the max
    # across submissions — regardless of the raw task's score_direction.
    _rescaled = [s.score_0_100 for s in submissions if s.score_0_100 is not None]
    best_score_0_100 = max(_rescaled) if _rescaled else None

    if final is None:
        # Infer is_score_task from submission data when task_meta is absent
        if not is_score_task and any(s.score is not None for s in submissions):
            is_score_task = True

        best = _select_best_submission(submissions, score_direction) if is_score_task else (
            max(submissions, key=lambda s: s.pass_rate) if submissions else None
        )

        ABORT_THRESHOLD_SEC = int(os.environ.get("SFORGE_VIZ_ABORT_THRESHOLD", "7200"))

        # Look up container status via the cached `docker ps -a` map instead
        # of running 3 `docker inspect` subprocess calls per task.
        status_map = _docker_status_map()
        container_probe = "unknown"
        saw_no_such = False
        for prefix in ("sforge.run", "sforge.evolve"):
            cname = f"{prefix}.{task}.{run_id}"
            if cname in status_map:
                container_probe = status_map[cname]
                break
            # If `docker ps` succeeded but the container isn't there, it's
            # equivalent to the old "no such object" stderr.
            saw_no_such = True
        if container_probe == "unknown" and saw_no_such and status_map:
            container_probe = "missing"

        # Skip the expensive rglob — use the task_dir's own mtime plus the
        # most-recent submission as an "any activity" signal. This is a
        # ~30x speedup on large submission directories.
        last_activity = created_at
        try:
            t = task_dir.stat().st_mtime
            if t > last_activity:
                last_activity = t
        except OSError:
            pass
        if submissions:
            sub_t = max((s.submitted_at for s in submissions), default=0.0)
            if sub_t > last_activity:
                last_activity = sub_t

        if container_probe == "running":
            is_aborted = False
        elif container_probe in ("missing", "exited", "dead", "created", "paused", "removing", "restarting"):
            is_aborted = True
        elif not (task_dir / "run_agent.log").exists():
            is_aborted = True
        else:
            is_aborted = (time.time() - last_activity) > ABORT_THRESHOLD_SEC

        if is_aborted:
            live_runtime = max(last_activity - created_at, 0.0)
        else:
            live_runtime = max(time.time() - created_at, 0.0)

        return Run(
            run_id=run_id,
            task=task,
            path=task_dir,
            agent=_peek_agent(task_dir),
            model=_peek_model(task_dir),
            ip=ip,
            best_pass_rate=best.pass_rate if best else 0.0,
            best_score=best.score if best else None,
            best_score_0_100=best_score_0_100,
            best_round=best.round_label if best else "",
            total_rounds=len(submissions),
            runtime_seconds=live_runtime,
            score_direction=score_direction,
            is_score_task=is_score_task,
            has_final=False,
            aborted=is_aborted,
            infra_error=_detect_infra_error(task_dir),
            created_at=created_at,
            submissions=submissions if include_submissions else [],
        )

    best_score_raw = final_best_score
    if best_score_raw in (None, "null"):
        best_score_raw = state.get("best_score")
    best_score = float(best_score_raw) if best_score_raw not in (None, "null") else None
    best_round = str(final.get("best_round", "") or "")

    # Infer is_score_task from data when task_meta is absent
    if not is_score_task and best_score is not None:
        is_score_task = True

    # If score task but best_score/best_round missing, recompute from submissions
    if is_score_task and submissions:
        scored = [s for s in submissions if s.score is not None]
        if scored:
            if score_direction == "minimize":
                best_sub = min(scored, key=lambda s: s.score)
            else:
                best_sub = max(scored, key=lambda s: s.score)
            if best_score is None:
                best_score = best_sub.score
            if not best_round:
                best_round = best_sub.round_label

    # In summary scans submissions aren't loaded, so the rescaled best is still
    # unknown. Read just the best round's report.json (one small file) so the
    # runs list / homepage can show the rescaled Best without a full submissions
    # walk. Only for score tasks — pass-rate tasks never carry a rescale.
    if best_score_0_100 is None and is_score_task and best_round:
        rep = _safe_load_json(task_dir / "submissions" / best_round / "report.json")
        if rep is not None:
            best_score_0_100 = _finite_or_none(rep.get("score_0_100"))

    return Run(
        run_id=run_id,
        task=task,
        path=task_dir,
        agent=final.get("agent", ""),
        model=final.get("model") or (_peek_model(task_dir) if include_submissions else "") or "",
        ip=ip,
        best_pass_rate=float(final.get("best_pass_rate", 0.0) or 0.0),
        best_score=best_score,
        best_score_0_100=best_score_0_100,
        best_round=best_round,
        total_rounds=int(final.get("total_rounds", len(submissions)) or len(submissions)),
        timed_out=bool(final.get("timed_out", False)),
        runtime_seconds=float(final.get("runtime_seconds", 0.0) or 0.0),
        archive_size_bytes=int(final.get("archive_size_bytes", 0) or 0),
        score_direction=score_direction,
        is_score_task=is_score_task,
        has_final=True,
        infra_error=_detect_infra_error(task_dir) if include_submissions else False,
        created_at=created_at,
        submissions=submissions if include_submissions else [],
    )


class RunsIndex:
    """On-demand scanner of a runs root directory.

    Keeps the API stateless: each accessor re-scans from disk. Good enough for
    a dev-time visualizer where write activity is low.

    list_runs() is cached for _LIST_RUNS_TTL seconds to avoid redundant
    directory walks on rapid page loads.
    """

    _LIST_RUNS_TTL = 10.0  # seconds

    def __init__(self, runs_dir: Path, task_meta: dict[str, dict] | None = None):
        self.runs_dir = runs_dir
        self.task_meta = task_meta or {}
        self._list_runs_cache: list[Run] | None = None
        self._list_runs_ts: float = 0.0
        self._list_run_summaries_cache: list[Run] | None = None
        self._list_run_summaries_ts: float = 0.0
        self._run_path_index: dict[str, Path] | None = None
        self._run_path_index_ts: float = 0.0

    def _iter_task_dirs(self):
        """Yield (run_id, task_dir, ip) auto-detecting flat vs machine-grouped.

        - Flat 2-level: <runs_dir>/<run_id>/<task>/   → ip="".
        - 3-level:      <runs_dir>/<ip>/<run_id>/<task>/.

        Per-entry detection: a direct child of runs_dir is a *run dir* if any of
        its own child dirs looks like a task dir; otherwise it is treated as a
        machine/grouping dir whose children are run dirs.
        """
        if not self.runs_dir.is_dir():
            return
        for entry in sorted(self.runs_dir.iterdir()):
            if not entry.is_dir():
                continue
            child_dirs = [c for c in sorted(entry.iterdir()) if c.is_dir()]
            if any(_is_task_dir(c) for c in child_dirs):
                # 2-level: entry is a run dir, its child dirs are tasks.
                for task_dir in child_dirs:
                    if _is_task_dir(task_dir):
                        yield entry.name, task_dir, ""
            else:
                # 3-level: entry is a machine/ip dir; its children are run dirs.
                for run_dir in child_dirs:
                    for task_dir in sorted(run_dir.iterdir()):
                        if task_dir.is_dir() and _is_task_dir(task_dir):
                            yield run_dir.name, task_dir, entry.name

    def list_runs(self, *, include_submissions: bool = True) -> list[Run]:
        now = time.time()
        if include_submissions:
            if self._list_runs_cache is not None and now - self._list_runs_ts < self._LIST_RUNS_TTL:
                return self._list_runs_cache
        elif self._list_run_summaries_cache is not None and now - self._list_run_summaries_ts < self._LIST_RUNS_TTL:
            return self._list_run_summaries_cache
        result = [
            _build_run(
                run_id,
                task_dir,
                self.task_meta,
                ip=ip,
                include_submissions=include_submissions,
            )
            for run_id, task_dir, ip in self._iter_task_dirs()
        ]
        if include_submissions:
            self._list_runs_cache = result
            self._list_runs_ts = time.time()
        else:
            self._list_run_summaries_cache = result
            self._list_run_summaries_ts = time.time()
        return result

    def _run_dir_index(self) -> dict[str, Path]:
        """Map each run_id (run-dir name) to its actual path, across layouts.

        run-dir names are globally unique (they embed the machine id), so a flat
        run_id → path lookup works for both 2- and 3-level trees.
        """
        now = time.time()
        if self._run_path_index is not None and now - self._run_path_index_ts < self._LIST_RUNS_TTL:
            return self._run_path_index
        idx: dict[str, Path] = {}
        if self.runs_dir.is_dir():
            for entry in sorted(self.runs_dir.iterdir()):
                if not entry.is_dir():
                    continue
                child_dirs = [c for c in entry.iterdir() if c.is_dir()]
                if any(_is_task_dir(c) for c in child_dirs):
                    idx[entry.name] = entry                  # 2-level run dir
                else:
                    for run_dir in child_dirs:               # 3-level: <ip>/<run_dir>
                        idx[run_dir.name] = run_dir
        self._run_path_index, self._run_path_index_ts = idx, now
        return idx

    def run_dir_path(self, run_id: str) -> Optional[Path]:
        return self._run_dir_index().get(run_id)

    def get_run(self, run_id: str, task: str) -> Optional[Run]:
        run_dir = self.run_dir_path(run_id)
        if run_dir is None:
            return None
        task_dir = run_dir / task
        if not task_dir.is_dir():
            return None
        ip = run_dir.parent.name if run_dir.parent != self.runs_dir else ""
        return _build_run(run_id, task_dir, self.task_meta, ip=ip)

    def list_run_tasks(self, run_id: str, *, include_submissions: bool = True) -> list[Run]:
        run_dir = self.run_dir_path(run_id)
        if run_dir is None:
            return []
        ip = run_dir.parent.name if run_dir.parent != self.runs_dir else ""
        return [
            _build_run(
                run_id,
                task_dir,
                self.task_meta,
                ip=ip,
                include_submissions=include_submissions,
            )
            for task_dir in sorted(run_dir.iterdir())
            if task_dir.is_dir() and _is_task_dir(task_dir)
        ]

    def load_submission(self, run_id: str, task: str, round_label: str) -> Optional[Submission]:
        run = self.get_run(run_id, task)
        if run is None:
            return None
        for sub in run.submissions:
            if sub.round_label == round_label:
                tests = self.load_submission_tests(sub.path)
                return replace(sub, tests=tests)
        return None

    @staticmethod
    def load_submission_tests(submission_path: Path) -> list[TestResult]:
        data = _safe_load_json(submission_path / "report.json") or {}
        out: list[TestResult] = []
        details = data.get("test_details")
        if not details:
            details = data.get("details") or []
        for t in details:
            if isinstance(t, dict):
                out.append(TestResult(name=str(t.get("name", "")), status=str(t.get("status", ""))))
        return out
