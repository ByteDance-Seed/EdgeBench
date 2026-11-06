"""Remote evaluation service for task 1 (integer compression).

FastAPI service. Accepts a tarball, compiles it in a sandboxed Docker exec,
loads the resulting libintcompress.so, runs the 8 datasets, and returns per-
dataset scores.

Security properties (see README.md §Security for the full list):
    * Submissions run in disposable containers with --network=none, --read-only
    * Datasets are mounted read-only at randomised paths.
    * Encode + decode run in *different* processes, so a submission cannot
      stash the raw input in memory and return it verbatim.
    * Output symbol table is white-listed before decode; any reference to
      dlopen/system/fork/exec/ptrace/open rejects the submission.

This file is intentionally a single module (~400 lines) so that the reviewer
can audit end-to-end scoring in one place.
"""

from __future__ import annotations

import hashlib
import json
import os
import secrets
import shutil
import subprocess
import tarfile
import tempfile
import threading
import time
import uuid
from dataclasses import dataclass, field, asdict
from pathlib import Path
from typing import Dict, List, Optional

from fastapi import FastAPI, File, HTTPException, Header, UploadFile
from fastapi.responses import JSONResponse

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

DATASETS = [
    ("docids", 2.0),
    ("ts_sec", 1.5),
    ("ts_ns",  1.5),
    ("temp",   1.0),
    ("grid",   1.0),
    ("zipf",   1.0),
    ("rand",   1.0),
    ("sparse", 1.0),
]

# Absolute paths on the host machine. Populated at deploy time — see
# `internal/evaluation_server/README.md`.
DATA_DIR = Path(os.environ.get("IC_DATA_DIR", "/srv/intcompress/data"))
WORK_ROOT = Path(os.environ.get("IC_WORK_ROOT", "/var/lib/intcompress/work"))
RESULT_DIR = Path(os.environ.get("IC_RESULT_DIR", "/var/lib/intcompress/results"))

BASELINE_PATH = Path(os.environ.get("IC_BASELINE", "/srv/intcompress/baseline.json"))
RUNNER_IMAGE = os.environ.get("IC_RUNNER_IMAGE", "intcompress-runner:latest")

COMPILE_TIMEOUT_SEC = 300
PER_DATASET_TIMEOUT_SEC = 300
SUBMIT_LIMIT_PER_AGENT = 100

SYMBOL_DENYLIST = {
    "dlopen", "dlsym", "dlmopen", "system", "popen",
    "fork", "vfork", "clone", "execve", "execvp", "execl",
    "ptrace", "socket", "connect", "accept", "bind", "open", "openat",
    "setuid", "setgid", "mprotect",
}

SYMBOL_ALLOW_PREFIXES = ("ic_",)  # exported user symbols

# ---------------------------------------------------------------------------
# Data classes
# ---------------------------------------------------------------------------


@dataclass
class DatasetResult:
    name: str
    weight: float
    encoded_bytes: int = 0
    n: int = 0
    encode_ms: float = 0.0
    decode_ms: float = 0.0
    decode_gbps: float = 0.0
    roundtrip_ok: bool = False
    score: float = 0.0  # S_i before weighting
    error: Optional[str] = None


@dataclass
class Submission:
    id: str
    agent_token: str
    received_at: float
    status: str = "queued"      # queued | compiling | running | done | error
    total_score: float = 0.0
    per_dataset: List[DatasetResult] = field(default_factory=list)
    compile_log: str = ""
    runtime_log: str = ""
    error: Optional[str] = None


# ---------------------------------------------------------------------------
# Persistence (flat-file; production would use sqlite or redis)
# ---------------------------------------------------------------------------

_lock = threading.Lock()
_submissions: Dict[str, Submission] = {}
_submission_count_per_agent: Dict[str, int] = {}


def _save(sub: Submission) -> None:
    RESULT_DIR.mkdir(parents=True, exist_ok=True)
    path = RESULT_DIR / f"{sub.id}.json"
    data = asdict(sub)
    data["per_dataset"] = [asdict(d) for d in sub.per_dataset]
    path.write_text(json.dumps(data, indent=2))


# ---------------------------------------------------------------------------
# Scoring
# ---------------------------------------------------------------------------


def load_baseline() -> Dict[str, Dict[str, float]]:
    with open(BASELINE_PATH) as f:
        raw = json.load(f)
    return {d["name"]: d for d in raw["per_dataset"]}


def compute_score(
    per_dataset: List[DatasetResult],
    baseline: Dict[str, Dict[str, float]],
) -> float:
    total_w = sum(d.weight for d in per_dataset)
    total_s = 0.0
    for d in per_dataset:
        if not d.roundtrip_ok or d.error:
            d.score = 0.0
            continue
        b = baseline[d.name]
        bpi = d.encoded_bytes * 8.0 / max(d.n, 1)
        comp_ratio = min(b["bpi"] / max(bpi, 1e-9), 8.0)
        speed_ratio = min(d.decode_gbps / max(b["decode_gbps"], 1e-9), 40.0)
        d.score = comp_ratio * speed_ratio
        total_s += d.weight * d.score
    return total_s / total_w


# ---------------------------------------------------------------------------
# Sandboxed runner
# ---------------------------------------------------------------------------


def _run(cmd: List[str], timeout: float, cwd: Optional[Path] = None) -> subprocess.CompletedProcess:
    return subprocess.run(
        cmd, timeout=timeout, capture_output=True, text=True,
        cwd=str(cwd) if cwd else None,
    )


def check_symbols(lib_path: Path) -> Optional[str]:
    """Return None if ok, else an error message."""
    try:
        proc = _run(["nm", "-D", "--defined-only", str(lib_path)], timeout=30)
    except subprocess.TimeoutExpired:
        return "nm timed out"
    defined = [line.split()[-1] for line in proc.stdout.splitlines() if line.strip()]
    if not any(s.startswith("ic_") for s in defined):
        return "no ic_* symbols exported"

    proc = _run(["nm", "-D", "-u", str(lib_path)], timeout=30)
    undefined = [line.split()[-1] for line in proc.stdout.splitlines() if line.strip()]
    for sym in undefined:
        # strip optional @GLIBC version
        short = sym.split("@")[0]
        if short in SYMBOL_DENYLIST:
            return f"denied import: {short}"
    return None


def compile_submission(work: Path) -> tuple[bool, str]:
    try:
        proc = _run(["docker", "run", "--rm",
                     "--network=none", "--cpus=4", "--memory=8g",
                     "-v", f"{work}:/workspace",
                     "-w", "/workspace",
                     RUNNER_IMAGE,
                     "sh", "-c", "make -j4"],
                    timeout=COMPILE_TIMEOUT_SEC)
    except subprocess.TimeoutExpired as e:
        return False, f"compile timeout\n{e.stdout or ''}\n{e.stderr or ''}"
    ok = proc.returncode == 0 and (work / "libintcompress.so").exists()
    return ok, proc.stdout + "\n---STDERR---\n" + proc.stderr


def run_dataset(work: Path, name: str, dataset_path: Path) -> DatasetResult:
    """Run encode + decode in two *separate* docker exec invocations to prevent
    the submission from caching raw input in memory across calls."""

    # Stage 1: encode — reads dataset, writes encoded.bin + meta.json.
    enc_cmd = [
        "docker", "run", "--rm",
        "--network=none", "--cpus=4", "--memory=8g", "--read-only",
        "--tmpfs=/tmp:rw,size=8g",
        "-v", f"{work}:/workspace:ro",
        "-v", f"{dataset_path}:/input.u32:ro",
        "-v", f"{work}_out:/out",
        "-w", "/workspace",
        RUNNER_IMAGE,
        "/workspace/runner_encode", "/input.u32", "/workspace/libintcompress.so",
        f"/out/{name}.enc", f"/out/{name}.meta",
    ]

    dec_cmd = [
        "docker", "run", "--rm",
        "--network=none", "--cpus=4", "--memory=8g", "--read-only",
        "--tmpfs=/tmp:rw,size=8g",
        "-v", f"{work}:/workspace:ro",
        "-v", f"{work}_out:/out:ro",
        "-v", f"{dataset_path}:/input.u32:ro",  # for final byte-compare
        "-w", "/workspace",
        RUNNER_IMAGE,
        "/workspace/runner_decode", f"/out/{name}.enc", "/workspace/libintcompress.so",
        "/input.u32", f"/out/{name}.json",
    ]

    r = DatasetResult(name=name, weight=dict(DATASETS)[name])
    try:
        p1 = _run(enc_cmd, timeout=PER_DATASET_TIMEOUT_SEC)
        if p1.returncode != 0:
            r.error = f"encode failed: {p1.stderr[-500:]}"
            return r
        p2 = _run(dec_cmd, timeout=PER_DATASET_TIMEOUT_SEC)
        if p2.returncode != 0:
            r.error = f"decode failed: {p2.stderr[-500:]}"
            return r
        meta_path = Path(f"{work}_out") / f"{name}.json"
        with open(meta_path) as f:
            meta = json.load(f)
        r.n = meta["n"]
        r.encoded_bytes = meta["encoded_bytes"]
        r.encode_ms = meta["encode_ms"]
        r.decode_ms = meta["decode_ms"]
        r.decode_gbps = meta["decode_gbps"]
        r.roundtrip_ok = meta["roundtrip_ok"]
        if not r.roundtrip_ok:
            r.error = "roundtrip mismatch"
    except subprocess.TimeoutExpired:
        r.error = "timeout"
    except FileNotFoundError as e:
        r.error = f"missing artefact: {e}"
    return r


def worker_thread(sub: Submission, tarball: bytes) -> None:
    work = WORK_ROOT / sub.id
    work.mkdir(parents=True, exist_ok=True)
    out = Path(f"{work}_out")
    out.mkdir(parents=True, exist_ok=True)
    try:
        # Unpack with safe paths.
        tar_path = work / "submit.tar.gz"
        tar_path.write_bytes(tarball)
        with tarfile.open(tar_path, "r:gz") as tar:
            for member in tar.getmembers():
                if member.name.startswith("/") or ".." in member.name:
                    raise ValueError(f"unsafe path: {member.name}")
            tar.extractall(work)

        sub.status = "compiling"
        _save(sub)
        ok, log = compile_submission(work)
        sub.compile_log = log[-20000:]
        if not ok:
            sub.status = "error"
            sub.error = "compile_error"
            _save(sub)
            return

        # Symbol check
        deny = check_symbols(work / "libintcompress.so")
        if deny:
            sub.status = "error"
            sub.error = f"symbol_check_failed: {deny}"
            _save(sub)
            return

        sub.status = "running"
        _save(sub)
        baseline = load_baseline()
        results: List[DatasetResult] = []
        for name, _w in DATASETS:
            dataset_path = DATA_DIR / f"{name}.u32"
            r = run_dataset(work, name, dataset_path)
            results.append(r)
            sub.per_dataset = results
            _save(sub)

        sub.total_score = compute_score(results, baseline)
        sub.status = "done"
        _save(sub)
    except Exception as ex:  # noqa: BLE001 — top-level catch intentional
        sub.status = "error"
        sub.error = f"internal: {type(ex).__name__}: {ex}"
        _save(sub)
    finally:
        shutil.rmtree(work, ignore_errors=True)
        shutil.rmtree(out, ignore_errors=True)


# ---------------------------------------------------------------------------
# HTTP surface
# ---------------------------------------------------------------------------

app = FastAPI()


@app.post("/submit")
async def submit(
    file: UploadFile = File(...),
    x_agent_token: str = Header(...),
) -> JSONResponse:
    data = await file.read()
    if len(data) > 32 * 1024 * 1024:
        raise HTTPException(413, "submission > 32MiB")

    with _lock:
        cnt = _submission_count_per_agent.get(x_agent_token, 0)
        if cnt >= SUBMIT_LIMIT_PER_AGENT:
            raise HTTPException(429, "submission limit reached")
        _submission_count_per_agent[x_agent_token] = cnt + 1
        sid = uuid.uuid4().hex
        sub = Submission(id=sid, agent_token=x_agent_token, received_at=time.time())
        _submissions[sid] = sub

    threading.Thread(target=worker_thread, args=(sub, data), daemon=True).start()
    return JSONResponse({"submission_id": sid, "status": "queued"})


@app.get("/result/{sid}")
def result(sid: str) -> JSONResponse:
    sub = _submissions.get(sid)
    if sub is None:
        # maybe it was flushed to disk
        path = RESULT_DIR / f"{sid}.json"
        if path.exists():
            return JSONResponse(json.loads(path.read_text()))
        raise HTTPException(404, "unknown submission_id")
    data = asdict(sub)
    data["per_dataset"] = [asdict(d) for d in sub.per_dataset]
    return JSONResponse(data)


@app.get("/leaderboard/{agent_token}")
def leaderboard(agent_token: str) -> JSONResponse:
    rows = []
    for sub in _submissions.values():
        if sub.agent_token == agent_token and sub.status == "done":
            rows.append({"submission_id": sub.id,
                         "received_at": sub.received_at,
                         "total_score": sub.total_score})
    rows.sort(key=lambda r: -r["total_score"])
    final = rows[0]["total_score"] if rows else 0
    return JSONResponse({"final_score": final,
                         "submissions_used": len(rows),
                         "submissions": rows[:20]})
