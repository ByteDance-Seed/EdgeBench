#!/usr/bin/env python3
"""Generic SE-Bench pytest_shim scorer runner generated from scorer_manifest.json."""
from __future__ import annotations

import csv
import io
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Any

SCORING_DIR = Path(__file__).resolve().parent
WORKSPACE = Path.cwd()
MANIFEST = SCORING_DIR / "scorer_manifest.json"
STRUCTURED_RESULT_START = ">>>>> Start Structured Result"
STRUCTURED_RESULT_END = ">>>>> End Structured Result"


def _safe_link_or_copy(src: Path, dst: Path, *, prefer_symlink: bool = True) -> None:
    if dst.exists():
        return
    if prefer_symlink:
        try:
            dst.symlink_to(src)
            return
        except Exception:
            pass
    try:
        if src.is_dir():
            shutil.copytree(src, dst, dirs_exist_ok=True)
        else:
            shutil.copy2(src, dst)
    except Exception:
        pass


def _expose_compat_files() -> None:
    # Compatibility only: manifest command remains authoritative, but legacy
    # scorers may open reference/input files by bare basename internally.
    for src in SCORING_DIR.rglob("*"):
        if not src.is_file() or src.name.startswith("."):
            continue
        rel = src.relative_to(SCORING_DIR)
        if rel.name in {"score.py", "scorer_manifest.json"}:
            continue
        if src.suffix.lower() in {".py", ".sh", ".ps1", ".cs", ".csproj", ".sln"}:
            continue
        # Use real copies for scoring data.  Some manifest commands stage the
        # same files with `cp scoring/foo workspace/foo`; if we symlink here,
        # GNU cp can fail with "are the same file" before the scorer runs.
        _safe_link_or_copy(src, WORKSPACE / src.name, prefer_symlink=False)
    input_dir = WORKSPACE / "input"
    if input_dir.is_dir():
        for src in input_dir.iterdir():
            if src.name.startswith("."):
                continue
            _safe_link_or_copy(src, WORKSPACE / src.name)


def _load_manifest() -> dict[str, Any]:
    return json.loads(MANIFEST.read_text(encoding="utf-8", errors="replace"))


def _host_path(path_text: str) -> Path:
    path_text = str(path_text)
    if path_text.startswith("/home/workspace/scoring/"):
        return SCORING_DIR / path_text[len("/home/workspace/scoring/"):]
    if path_text.startswith("scoring/"):
        return SCORING_DIR / path_text[len("scoring/"):]
    if path_text.startswith("/home/workspace/input/"):
        return WORKSPACE / "input" / path_text[len("/home/workspace/input/"):]
    if path_text.startswith("input/"):
        return WORKSPACE / "input" / path_text[len("input/"):]
    if path_text.startswith("/home/workspace/"):
        return WORKSPACE / path_text[len("/home/workspace/"):]
    return Path(path_text)


_FRAUD_THRESHOLD_PATTERNS = [
    (re.compile(r"ratio[\d.]+%?>\d+%"), "ratio too high"),
    (re.compile(r"ratio[\d.]+%?<\d+%"), "ratio insufficient"),
    (re.compile(r"unchanged\d+trading_days"), "unchanged for multiple trading days"),
    (re.compile(r"turnover[\d.]+<\d+%"), "turnover too low"),
    (re.compile(r"deviation[\d.]+\s*>\s*[\d.%]+(?:pct_points)?"), "deviation too large"),
    (re.compile(r"sharpe[\d.]+>\d+\.0"), "sharpe abnormal"),
    (re.compile(r"drawdown_abs[\d.]+%<\d+%"), "drawdown abnormal"),
    (re.compile(r"annual_return[\d.]+%>[\d.]+%and.*<\d+%"), "return-drawdown abnormal"),
    (re.compile(r"VaR_breach[\d.]+abnormal"), "VaR breach rate abnormal"),
]


def _sanitize_warning(w: str) -> str:
    for pat, replacement in _FRAUD_THRESHOLD_PATTERNS:
        if pat.search(w):
            return re.sub(pat, replacement, w)
    return w


def _build_metrics_from_report(report: dict[str, Any]) -> tuple[dict[str, Any], str]:
    metrics: dict[str, Any] = {}
    calc = report.get("calculated_metrics", {})
    scores = report.get("scores", {})
    validation = report.get("validation", {})

    metric_items = [
        ("Sharpe Ratio", calc.get("sharpe_ratio"), scores.get("sharpe"), 30),
        ("Max Drawdown", calc.get("max_drawdown"), scores.get("drawdown"), 15),
        ("Excess Return", calc.get("excess_return_annual"), scores.get("excess_return"), 20),
        ("Information Ratio", calc.get("information_ratio"), scores.get("information_ratio"), 10),
        ("Sortino Ratio", calc.get("sortino_ratio"), scores.get("sortino"), 10),
        ("Agent VaR Calibration", calc.get("agent_var_break_rate"), scores.get("agent_var"), 5),
        ("Independent VaR Calibration", calc.get("independent_var_break_rate"), scores.get("independent_var"), 5),
        ("Turnover Rate", calc.get("annual_turnover"), scores.get("turnover"), 5),
    ]

    summary_parts = []
    for name, raw_val, score_val, max_val in metric_items:
        if raw_val is not None:
            if isinstance(raw_val, float):
                if name in ("Max Drawdown",):
                    display = f"{raw_val:.2%}"
                elif name in ("Agent VaR Calibration", "Independent VaR Calibration"):
                    display = f"breach rate{raw_val:.1%}"
                elif name in ("Turnover Rate",):
                    display = f"{raw_val:.0%}"
                elif name in ("Excess Return",):
                    display = f"{raw_val:.2%}"
                elif name in ("Information Ratio", "Sortino Ratio"):
                    display = f"{raw_val:.4f}"
                else:
                    display = f"{raw_val:.4f}"
            else:
                display = str(raw_val)
            metrics[name] = f"{display} → {score_val:.1f}/{max_val}pts"
            summary_parts.append(f"{name}:{score_val:.1f}/{max_val}")

    penalty_items = [
        ("Code Detection Penalty", validation.get("code_penalty", 0)),
        ("NAV Rebuild Penalty", validation.get("nav_rebuild_penalty", 0)),
        ("NAV Internal Consistency Penalty", validation.get("nav_internal_penalty", 0)),
        ("NAV Path Anomaly Penalty", validation.get("path_penalty", 0)),
        ("Weights Completeness Penalty", validation.get("weights_penalty", 0)),
        ("Date Range Penalty", validation.get("date_range_penalty", 0)),
        ("Trade Field Penalty", validation.get("trades_field_penalty", 0)),
        ("Price Range Penalty", validation.get("price_penalty", 0)),
        ("Constraint Violation Penalty", validation.get("constraint_penalty", 0)),
        ("Anti-fraud Penalty", validation.get("anti_fraud_penalty", 0)),
        ("Short Effectiveness Penalty", validation.get("short_penalty", 0)),
    ]
    for name, val in penalty_items:
        if val:
            metrics[name] = abs(val)
            summary_parts.append(f"{name}:{abs(val)}")

    score_zero = validation.get("score_zero", False)
    if score_zero:
        metrics["Anti-fraud triggered zero"] = True
        summary_parts.append("Core return score zeroed")

    bonus = report.get("bonus", {})
    vol_score = bonus.get("volatility_event_score", 0)
    if vol_score:
        metrics["Volatility change bonus"] = f"+{vol_score}"
        summary_parts.append(f"change bonus:+{vol_score}")

    perf_score = report.get("perf_score", 0)
    metrics["Performance score"] = f"{perf_score:.1f}/100"

    base_total = report.get("base_total", 0)
    final_total = report.get("final_total", 0)
    if final_total != base_total:
        metrics["Final total score"] = f"{final_total:.1f}/100"

    warnings = report.get("warnings", [])
    sanitized = [_sanitize_warning(w) for w in warnings]
    if sanitized:
        metrics["Warning"] = sanitized

    summary = "; ".join(summary_parts) if summary_parts else f"total{final_total:.1f}"
    return metrics, summary


def _emit_structured_result(
    *,
    valid: bool,
    score: float | None,
    pass_rate: float | None,
    summary: str | None,
    details: list[dict[str, Any]] | None = None,
    metrics: dict[str, Any] | None = None,
) -> None:
    payload: dict[str, Any] = {
        "valid": valid,
        "score": score,
        "pass_rate": pass_rate,
        "summary": summary,
        "details": details or [],
        "metrics": metrics or {},
    }
    print(STRUCTURED_RESULT_START)
    print(json.dumps(payload, ensure_ascii=False))
    print(STRUCTURED_RESULT_END)


def _emit_status(status: str, reason: str, score: float | None = None,
                 metrics: dict[str, Any] | None = None, summary: str | None = None) -> None:
    payload: dict[str, Any] = {"status": status, "reason": reason, "score": score}
    if metrics is not None:
        payload["metrics"] = metrics
    if summary is not None:
        payload["summary"] = summary
    print("SCORER_STATUS_JSON " + json.dumps(payload, ensure_ascii=False))


def _emit_parseable_failure(reason: str) -> None:
    _emit_structured_result(
        valid=False,
        score=0.0,
        pass_rate=0.0,
        summary=reason,
        details=[{
            "name": "tests/score_contract.py::score_output_parseable",
            "status": "FAILED",
            "message": reason,
        }],
        metrics={},
    )
    _emit_status("infra_error", reason)
    print(f"SCORER_INFRA_ERROR {reason}")
    print(f"tests/score_contract.py::score_output_parseable FAILED  [{reason}]")
    print("===== 1 failed in 0.01s =====")
    print("TOTAL_SCORE 0")


def _emit_zero(reason: str) -> None:
    _emit_structured_result(
        valid=True,
        score=0.0,
        pass_rate=1.0,
        summary=reason,
        details=[{
            "name": "tests/score_contract.py::score_output_parseable",
            "status": "PASSED",
        }],
        metrics={},
    )
    _emit_status("ok", reason, 0.0)
    print("tests/score_contract.py::score_output_parseable PASSED")
    print("===== 1 passed in 0.01s =====")
    print("TOTAL_SCORE 0")


def _json_path(obj: Any, path: str) -> Any:
    cur = obj
    for part in path.split("."):
        if not part or part == "$":
            continue
        if isinstance(cur, dict):
            cur = cur[part]
        elif isinstance(cur, list) and part.isdigit():
            cur = cur[int(part)]
        else:
            raise KeyError(path)
    return cur


def _extract_score_from_text(text: str, score_output: dict[str, Any]) -> float | None:
    fmt = score_output.get("format")
    if fmt == "regex":
        pat = str(score_output.get("pattern") or "")
        match = re.search(pat, text, re.IGNORECASE | re.MULTILINE)
        if not match:
            return None
        return float(match.group(1))
    if fmt == "json_path":
        path = str(score_output.get("json_path") or "")
        decoder = json.JSONDecoder()
        for idx, ch in enumerate(text):
            if ch not in "[{":
                continue
            try:
                obj, _ = decoder.raw_decode(text[idx:])
            except Exception:
                continue
            try:
                return float(_json_path(obj, path))
            except Exception:
                continue
    if fmt == "csv":
        column = str(score_output.get("csv_column") or "").strip()
        if not column:
            return None
        for row in csv.DictReader(io.StringIO(text)):
            if column in row and str(row[column]).strip():
                return float(row[column])
    return None


def _extract_score(output: str, score_output: dict[str, Any]) -> float | None:
    source = str(score_output.get("source") or "stdout")
    file_path = score_output.get("file_path")
    if source in {"file", "json_file", "result_file"} or file_path:
        if not file_path:
            return None
        path = _host_path(str(file_path))
        if not path.is_file():
            return None
        text = path.read_text(encoding="utf-8", errors="replace")
        return _extract_score_from_text(text, score_output)
    return _extract_score_from_text(output, score_output)


def _normalize(raw: float, norm: dict[str, Any]) -> float:
    raw_min = float(norm.get("raw_min", 0))
    raw_max = float(norm["raw_max"])
    target_min = float(norm.get("target_min", 0))
    target_max = float(norm.get("target_max", 100))
    score = (raw - raw_min) / (raw_max - raw_min) * (target_max - target_min) + target_min
    return min(target_max, max(target_min, score))


def main() -> int:
    try:
        manifest = _load_manifest()
    except Exception as exc:
        _emit_parseable_failure(f"manifest load failed: {exc}")
        return 0

    policy = manifest.get("failure_policy") or {}
    for key, base in (
        ("required_scoring_files", "/home/workspace/scoring/"),
        ("required_input_files", "/home/workspace/input/"),
    ):
        for item in manifest.get(key) or []:
            path = _host_path(item if str(item).startswith("/home/workspace/") else base + str(item))
            if not path.exists():
                _emit_parseable_failure(f"required {key} missing: {item}")
                return 0
    missing_submission = []
    for item in manifest.get("required_submission_files") or []:
        path = _host_path(item if str(item).startswith("/home/workspace/") else "/home/workspace/" + str(item))
        if not path.exists():
            missing_submission.append(str(item))
    if missing_submission:
        if policy.get("missing_submission") == "zero_score":
            _emit_zero("missing submission files: " + ", ".join(missing_submission))
        else:
            _emit_parseable_failure("missing submission files: " + ", ".join(missing_submission))
        return 0

    command = list(manifest.get("command") or [])
    if not command:
        _emit_parseable_failure("empty manifest command")
        return 0
    _expose_compat_files()
    env = os.environ.copy()
    env["PYTHONPATH"] = str(WORKSPACE) + (os.pathsep + env.get("PYTHONPATH", "") if env.get("PYTHONPATH") else "")
    proc = subprocess.run(command, cwd=str(WORKSPACE), text=True, capture_output=True, env=env)
    output = (proc.stdout or "") + (proc.stderr or "")
    if output:
        print(output, end="" if output.endswith("\n") else "\n")
    score_output = manifest.get("score_output") or {}
    try:
        raw_score = _extract_score(output, score_output)
    except Exception as exc:
        _emit_parseable_failure(f"score extraction crashed: {exc}")
        return 0
    if raw_score is None:
        if (proc.returncode == 0 and policy.get("parse_failure") == "zero_score") or (proc.returncode != 0 and policy.get("nonzero_exit_without_score") == "zero_score"):
            _emit_zero("missing parseable score")
        else:
            _emit_parseable_failure(
                f"missing parseable score; rc={proc.returncode}"
            )
        return 0
    if proc.returncode != 0 and policy.get("nonzero_exit_with_score", "ok") != "ok":
        _emit_parseable_failure(f"scorer exited nonzero after score extraction: rc={proc.returncode}")
        return 0
    try:
        score = _normalize(float(raw_score), manifest.get("score_normalization") or {})
    except Exception as exc:
        _emit_parseable_failure(f"score normalization failed: {exc}")
        return 0

    report_metrics = None
    report_summary = None
    report_path = WORKSPACE / "score_report.json"
    if report_path.is_file():
        try:
            report_data = json.loads(report_path.read_text(encoding="utf-8", errors="replace"))
            report_metrics, report_summary = _build_metrics_from_report(report_data)
        except Exception:
            pass

    _emit_structured_result(
        valid=True,
        score=score,
        pass_rate=1.0,
        summary=report_summary or "Scoring complete",
        details=[{
            "name": "tests/score_contract.py::score_output_parseable",
            "status": "PASSED",
        }],
        metrics=report_metrics or {},
    )
    _emit_status("ok", "scored", score, metrics=report_metrics, summary=report_summary)
    print("tests/score_contract.py::score_output_parseable PASSED")
    print("===== 1 passed in 0.01s =====")
    print(f"TOTAL_SCORE {score:g}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
