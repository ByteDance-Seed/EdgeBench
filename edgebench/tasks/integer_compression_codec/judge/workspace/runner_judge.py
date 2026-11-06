#!/usr/bin/env python3
from __future__ import annotations

import json
import subprocess
import sys
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parent
DATA_DIR = ROOT / "data"
OUTPUT_DIR = ROOT / "outputs"
RUNNER_DIR = ROOT / ".judge-bin"
BASELINE_PATH = ROOT / "internal" / "baseline" / "baseline_results.json"
LIB_PATH = ROOT / "libintcompress.so"

DATASETS = [
    ("docids", 2.0),
    ("ts_sec", 1.5),
    ("ts_ns", 1.5),
    ("temp", 1.0),
    ("grid", 1.0),
    ("zipf", 1.0),
    ("rand", 1.0),
    ("sparse", 1.0),
]

SYMBOL_DENYLIST = {
    "dlopen", "dlsym", "dlmopen", "system", "popen",
    "fork", "vfork", "clone", "execve", "execvp", "execl",
    "ptrace", "socket", "connect", "accept", "bind", "open", "openat",
    "setuid", "setgid", "mprotect",
}


def run(cmd: list[str], timeout: int = 600, cwd: Path | None = None) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        cmd,
        cwd=str(cwd) if cwd else None,
        timeout=timeout,
        text=True,
        capture_output=True,
    )


def ensure_runners() -> None:
    RUNNER_DIR.mkdir(parents=True, exist_ok=True)
    runner_encode = RUNNER_DIR / "runner_encode"
    runner_decode = RUNNER_DIR / "runner_decode"
    if runner_encode.exists() and runner_decode.exists():
        return
    common = ["g++", "-std=c++17", "-O3", "-march=x86-64-v3", f"-I{ROOT / 'include'}"]
    enc = common + ["-o", str(runner_encode), str(ROOT / "evaluation_server" / "runner_encode.cpp"), "-ldl"]
    dec = common + ["-o", str(runner_decode), str(ROOT / "evaluation_server" / "runner_decode.cpp"), "-ldl"]
    p1 = run(enc, timeout=300, cwd=ROOT)
    if p1.returncode != 0:
        raise RuntimeError(f"failed to build runner_encode\n{p1.stdout}\n{p1.stderr}")
    p2 = run(dec, timeout=300, cwd=ROOT)
    if p2.returncode != 0:
        raise RuntimeError(f"failed to build runner_decode\n{p2.stdout}\n{p2.stderr}")


def load_baseline() -> dict[str, dict]:
    raw = json.loads(BASELINE_PATH.read_text())
    return {d["name"]: d for d in raw["per_dataset"]}


def check_symbols(lib_path: Path) -> str | None:
    defined = run(["nm", "-D", "--defined-only", str(lib_path)], timeout=30)
    if defined.returncode != 0:
        return f"nm defined failed: {defined.stderr.strip()}"
    exported = [line.split()[-1] for line in defined.stdout.splitlines() if line.strip()]
    if not any(sym.startswith("ic_") for sym in exported):
        return "no ic_* symbols exported"

    undefined = run(["nm", "-D", "-u", str(lib_path)], timeout=30)
    if undefined.returncode != 0:
        return f"nm undefined failed: {undefined.stderr.strip()}"
    for line in undefined.stdout.splitlines():
        line = line.strip()
        if not line:
            continue
        sym = line.split()[-1].split("@")[0]
        if sym in SYMBOL_DENYLIST:
            return f"denied import: {sym}"
    return None


def compute_total_score(per_dataset: list[dict], baseline: dict[str, dict]) -> float:
    total_w = sum(item["weight"] for item in per_dataset)
    total_s = 0.0
    for item in per_dataset:
        if not item.get("roundtrip_ok") or item.get("error"):
            item["score"] = 0.0
            continue
        b = baseline[item["name"]]
        bpi = item["encoded_bytes"] * 8.0 / max(item["n"], 1)
        comp_ratio = min(b["bpi"] / max(bpi, 1e-9), 8.0)
        speed_ratio = min(item["decode_gbps"] / max(b["decode_gbps"], 1e-9), 40.0)
        item["score"] = comp_ratio * speed_ratio
        total_s += item["weight"] * item["score"]
    return total_s / total_w


def run_dataset(name: str, weight: float) -> dict:
    dataset_path = DATA_DIR / f"{name}.u32"
    result = {
        "name": name,
        "weight": weight,
        "n": 0,
        "encoded_bytes": 0,
        "encode_ms": 0.0,
        "decode_ms": 0.0,
        "decode_gbps": 0.0,
        "roundtrip_ok": False,
        "score": 0.0,
        "error": None,
    }
    if not dataset_path.exists():
        result["error"] = f"missing dataset: {dataset_path}"
        return result

    runner_encode = RUNNER_DIR / "runner_encode"
    runner_decode = RUNNER_DIR / "runner_decode"
    with tempfile.TemporaryDirectory(prefix=f"ic_{name}_") as tmp:
        tmpdir = Path(tmp)
        enc_path = tmpdir / f"{name}.enc"
        enc_meta = tmpdir / f"{name}.enc.meta"
        dec_meta = tmpdir / f"{name}.json"

        p1 = run([str(runner_encode), str(dataset_path), str(LIB_PATH), str(enc_path), str(enc_meta)], timeout=300, cwd=ROOT)
        if p1.returncode != 0:
            result["error"] = f"encode failed: {(p1.stderr or p1.stdout).strip()[-500:]}"
            return result

        p2 = run([str(runner_decode), str(enc_path), str(LIB_PATH), str(dataset_path), str(dec_meta)], timeout=300, cwd=ROOT)
        if p2.returncode != 0:
            result["error"] = f"decode failed: {(p2.stderr or p2.stdout).strip()[-500:]}"
            return result

        enc = json.loads(enc_meta.read_text())
        dec = json.loads(dec_meta.read_text())
        result["n"] = enc["n"]
        result["encoded_bytes"] = enc["encoded_bytes"]
        result["encode_ms"] = enc["encode_ms"]
        result["decode_ms"] = dec["decode_ms"]
        result["decode_gbps"] = dec["decode_gbps"]
        result["roundtrip_ok"] = dec["roundtrip_ok"]
        if not result["roundtrip_ok"]:
            result["error"] = "roundtrip mismatch"
        return result


def build_submission() -> tuple[bool, str]:
    clean = run(["make", "clean"], timeout=120, cwd=ROOT)
    build = run(["make", "-j4"], timeout=600, cwd=ROOT)
    log = "\n".join([
        "== make clean ==",
        clean.stdout,
        clean.stderr,
        "== make -j4 ==",
        build.stdout,
        build.stderr,
    ])
    ok = build.returncode == 0 and LIB_PATH.exists()
    return ok, log


def main() -> int:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    baseline = load_baseline()
    try:
        ensure_runners()
        ok, compile_log = build_submission()
        if not ok:
            data = {
                "score": 0.0,
                "overall_score": 0.0,
                "num_cases": len(DATASETS),
                "status": "compile_error",
                "compile_log": compile_log[-20000:],
                "runtime_log": "",
                "per_dataset": [],
            }
        else:
            deny = check_symbols(LIB_PATH)
            if deny:
                data = {
                    "score": 0.0,
                    "overall_score": 0.0,
                    "num_cases": len(DATASETS),
                    "status": "invalid",
                    "compile_log": compile_log[-20000:],
                    "runtime_log": deny,
                    "per_dataset": [],
                    "symbol_error": deny,
                }
            else:
                per_dataset = [run_dataset(name, weight) for name, weight in DATASETS]
                total_score = compute_total_score(per_dataset, baseline)
                data = {
                    "score": float(total_score),
                    "overall_score": float(total_score),
                    "num_cases": len(DATASETS),
                    "status": "ok",
                    "compile_log": compile_log[-20000:],
                    "runtime_log": "",
                    "per_dataset": per_dataset,
                }
    except Exception as exc:  # noqa: BLE001
        data = {
            "score": 0.0,
            "overall_score": 0.0,
            "num_cases": len(DATASETS),
            "status": "error",
            "compile_log": "",
            "runtime_log": f"{type(exc).__name__}: {exc}",
            "per_dataset": [],
        }

    (OUTPUT_DIR / "result.json").write_text(json.dumps(data, indent=2))
    score = float(data.get("score", 0.0))
    summary = "score={:.6f}, datasets={}, status={}".format(
        score,
        data.get("num_cases", 0),
        data.get("status", "unknown"),
    )
    structured = {
        "valid": data.get("status") in {"ok", "invalid", "compile_error"},
        "score": score,
        "summary": summary,
        "details": [],
        "metrics": data,
    }
    print(">>>>> Start Structured Result")
    print(json.dumps(structured))
    print(">>>>> End Structured Result")
    return 0


if __name__ == "__main__":
    sys.exit(main())
