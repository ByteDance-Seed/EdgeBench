#!/usr/bin/env python3
"""SE-Bench wrapper for the original 80-point CTA evaluator."""

from __future__ import annotations

import json
import subprocess
from pathlib import Path


WORKSPACE = Path("/home/workspace")
SCORING_DIR = WORKSPACE / "scoring"
SUBMISSION_DIR = WORKSPACE
DATA_DIR = WORKSPACE / "input"
RESULTS_JSON = SUBMISSION_DIR / "eval_results.json"

METRIC_SPECS = [
    (
        "M1_backtest_verification",
        "backtest_verification",
        10.0,
        "Auditability of the NAV, positions, trades, costs, and FX chain",
    ),
    (
        "M2_performance_metrics",
        "performance_metrics",
        25.0,
        "Quality of performance metrics, contingent on underlying backtest credibility",
    ),
    (
        "M3_risk_constraints",
        "risk_constraints",
        20.0,
        "Drawdown, volatility, exposure, and cross-border risk-control constraints",
    ),
    (
        "M4_signal_generation",
        "signal_generation",
        15.0,
        "Multi-strategy signals, mean-reversion evidence, and conflict handling",
    ),
    (
        "M5_code_compliance",
        "code_compliance",
        10.0,
        "Compliance of randomness, dependencies, cost/FX-rate sources, and runtime",
    ),
]

GUIDANCE = [
    "Prioritize improving the lowest-scoring dimension; do not chase higher returns alone.",
    "Performance and risk-control quality depend on the credibility of the underlying backtest chain.",
    "If the signal-generation dimension is weak, strengthen verifiable multi-strategy signal outputs and conflict handling.",
]


def _run_agent_entry() -> None:
    for name in ("run.py", "main.py"):
        path = SUBMISSION_DIR / name
        if not path.is_file():
            continue
        print(f"[run_eval] Running submitted entrypoint: {name}", flush=True)
        try:
            proc = subprocess.run(
                ["python3", str(path)],
                cwd=str(SUBMISSION_DIR),
                text=True,
                capture_output=True,
                timeout=300,
            )
            if proc.stdout:
                print(proc.stdout[-4000:], flush=True)
            if proc.returncode != 0:
                print(f"[run_eval] Entrypoint exited {proc.returncode}", flush=True)
                if proc.stderr:
                    print(proc.stderr[-4000:], flush=True)
        except subprocess.TimeoutExpired:
            print("[run_eval] Entrypoint timed out after 300s; continuing to evaluator.", flush=True)
        return


def _load_score() -> tuple[float, str, dict | None]:
    if not RESULTS_JSON.is_file():
        return 0.0, "eval_results.json was not produced", None
    try:
        data = json.loads(RESULTS_JSON.read_text(encoding="utf-8", errors="replace"))
    except Exception as exc:
        return 0.0, f"failed to read eval_results.json: {exc}", None
    scores = data.get("scores") or {}
    raw_score = float(scores.get("grand_total", scores.get("auto_total", 0.0)) or 0.0)
    max_score = float(data.get("total_max_score", 80) or 80)
    normalized = raw_score / max_score * 100.0 if max_score > 0 else 0.0
    return max(0.0, min(100.0, normalized)), f"raw_score={raw_score:g}/{max_score:g}", data


def _build_metrics(results: dict | None) -> dict:
    scores = (results or {}).get("scores") or {}
    metrics = {}
    for name, key, max_score, description in METRIC_SPECS:
        raw_score = float(scores.get(key, 0.0) or 0.0)
        metrics[name] = {
            "score": round(raw_score / max_score * 100.0, 3) if max_score else 0.0,
            "raw_score": raw_score,
            "max_score": max_score,
            "description": description,
        }
    return metrics


def _emit_structured_result(valid: bool, score: float, results: dict | None = None) -> None:
    metrics = _build_metrics(results)
    payload = {
        "valid": bool(valid),
        "total_tests": 1,
        "passed": 1 if valid else 0,
        "failed": 0 if valid else 1,
        "errors": 0,
        "pass_rate": 1.0 if valid else 0.0,
        "score": float(f"{score:.6f}"),
        "score_scale": "0-100",
        "metrics": metrics,
        "guidance": GUIDANCE,
        "summary": "The structured scoring feedback only contains coarse-grained dimension scores and general improvement directions; it does not include hidden thresholds, reference answers, or itemized deduction details.",
        "details": {},
    }
    payload_text = json.dumps(payload, ensure_ascii=False, separators=(",", ":"))
    # The harness structured_json parser expects either a bare JSON line or a
    # marker block. Keep the legacy prefixed line for backward-compatible logs.
    print(">>>>> Start Structured Result")
    print(payload_text)
    print(">>>>> End Structured Result")
    print("STRUCTURED_RESULT_JSON " + payload_text)


def main() -> int:
    _run_agent_entry()

    eval_script = SCORING_DIR / "eval_script.py"
    cmd = [
        "python3",
        str(eval_script),
        "--submission_dir",
        str(SUBMISSION_DIR),
        "--data_dir",
        str(DATA_DIR),
        "--standard_answer_dir",
        str(SCORING_DIR),
        "--run_agent_code",
        "--timeout",
        "300",
    ]
    print("[run_eval] Running evaluator:", " ".join(cmd), flush=True)
    try:
        proc = subprocess.run(
            cmd,
            cwd=str(WORKSPACE),
            text=True,
            capture_output=True,
            timeout=600,
        )
    except subprocess.TimeoutExpired:
        print("TOTAL_SCORE 0")
        print("FEEDBACK: evaluator timed out after 600s")
        _emit_structured_result(False, 0.0)
        return 0
    except Exception as exc:
        print("TOTAL_SCORE 0")
        print(f"FEEDBACK: evaluator launch failed: {exc}")
        _emit_structured_result(False, 0.0)
        return 0

    if proc.stdout:
        print(proc.stdout[-8000:], flush=True)
    if proc.stderr:
        print(proc.stderr[-8000:], flush=True)

    score, feedback, results = _load_score()
    if proc.returncode != 0:
        feedback = f"evaluator exited {proc.returncode}; {feedback}"
    print(f"TOTAL_SCORE {score:.6f}")
    print(f"FEEDBACK: {feedback}")
    _emit_structured_result(proc.returncode == 0 and results is not None, score, results)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
