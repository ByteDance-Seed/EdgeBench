from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path
from typing import Any

import numpy as np
import pandas as pd



def emit_score_sum_agent_feedback(detail, metrics):
    """Emit score_sum-compatible CASE lines so the Agent can see hidden/future feedback."""
    def safe_float(x, default=999.0):
        try:
            v = float(x)
            if v != v:
                return default
            return v
        except Exception:
            return default

    def fmt_metric(x):
        v = safe_float(x)
        if v == 999.0:
            return "NA"
        return f"{v:.3f}".replace(".", "p").replace("-", "m")

    def safe_token(x):
        s = str(x)
        keep = []
        for ch in s:
            if ch.isalnum() or ch in "_-":
                keep.append(ch)
            else:
                keep.append("_")
        return "".join(keep)[:80]

    try:
        detail = detail or {}
        metrics = metrics or {}

        hidden = metrics.get("hidden_well", {}) or {}
        future = metrics.get("future_public", {}) or {}

        hidden_rrmse = hidden.get("rRMSE")
        future_rrmse = future.get("rRMSE")
        hidden_log = hidden.get("log_rmse")
        future_log = future.get("log_rmse")

        cap_reason = detail.get("cap_reason", detail.get("metric_cap_reason", "none"))

        print(f"CASE feedback_hidden_well_rRMSE_{fmt_metric(hidden_rrmse)} WA score=0")
        print(f"CASE feedback_future_public_rRMSE_{fmt_metric(future_rrmse)} WA score=0")
        print(f"CASE feedback_hidden_well_log_rmse_{fmt_metric(hidden_log)} WA score=0")
        print(f"CASE feedback_future_public_log_rmse_{fmt_metric(future_log)} WA score=0")
        print(f"CASE feedback_cap_reason_{safe_token(cap_reason)} WA score=0")
        print(f"CASE feedback_transport_equation_score_{fmt_metric(detail.get('transport_equation_score', 0.0))} WA score=0")
        transport = detail.get("transport_equation_detail", {}) or {}
        terms = transport.get("recognized_terms", {}) or {}
        for name in ["time", "advection", "dispersion", "reaction", "source"]:
            status = "ok" if bool(terms.get(name)) else "missing"
            print(f"CASE feedback_ade_term_{safe_token(name)}_{status} WA score=0")
        hydro = transport.get("hydro_parameter_feedback", {}) or {}
        for name in [
            "velocity_m_per_day", "alpha_L_m", "alpha_TH_m", "alpha_TV_m",
            "porosity", "retardation_factor", "lambda_per_day",
        ]:
            item = hydro.get(name, {}) or {}
            status = safe_token(item.get("status", "missing"))
            value = fmt_metric(item.get("value", 999.0))
            expected = fmt_metric(item.get("expected", 999.0))
            print(f"CASE feedback_hydro_{safe_token(name)}_{status}_value_{value}_ref_{expected} WA score=0")
        approach_status = safe_token(transport.get("numerical_approach_status", "missing"))
        print(f"CASE feedback_transport_numerical_approach_{approach_status} WA score=0")
    except Exception as exc:
        print(f"CASE feedback_emit_error_{safe_token(repr(exc))} WA score=0")
TASK_NAME = "borden_inverse"


# ============================================================
# Basic IO
# ============================================================

def load_json(path: Path) -> dict[str, Any]:
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def save_json(obj: dict[str, Any], path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(obj, f, ensure_ascii=False, indent=2)


def safe_float(x: Any, default: float = float("nan")) -> float:
    try:
        v = float(x)
        return v if math.isfinite(v) else default
    except Exception:
        return default


# ============================================================
# Continuous metric scoring
# ============================================================


def round3(x):
    try:
        return round(float(x), 3)
    except Exception:
        return 0.0


def log_power_score(error: float, good: float, bad: float, points: float, gamma: float = 2.5) -> float:
    # Truncated logarithmic-power score for lower-is-better metrics.
    # error <= good: full points; error >= bad: zero.
    # good < error < bad: points * z**gamma on a logarithmic scale.
    try:
        error = float(error)
        good = float(good)
        bad = float(bad)
        points = float(points)
        gamma = float(gamma)
    except Exception:
        return 0.0

    if not math.isfinite(error) or not math.isfinite(good) or not math.isfinite(bad):
        return 0.0
    if good <= 0.0 or bad <= good or points <= 0.0:
        return 0.0
    if error <= good:
        return points
    if error >= bad:
        return 0.0

    z = (math.log(bad) - math.log(error)) / (math.log(bad) - math.log(good))
    z = max(0.0, min(1.0, z))
    return points * (z ** gamma)


def smooth_linear_score(error: float, good: float, bad: float, points: float, gamma: float = 1.3) -> float:
    # Wide, gentle slope for poor-to-moderate answers. This makes hidden metric
    # feedback useful before answers are accurate enough for the precision score.
    try:
        error = float(error)
        good = float(good)
        bad = float(bad)
        points = float(points)
        gamma = float(gamma)
    except Exception:
        return 0.0
    if not math.isfinite(error) or bad <= good or points <= 0.0:
        return 0.0
    if error <= good:
        return points
    if error >= bad:
        return 0.0
    z = (bad - error) / (bad - good)
    return points * (max(0.0, min(1.0, z)) ** gamma)


def metric_cap_reason(metrics: dict) -> str:
    hidden = metrics.get("hidden_well", {})
    future = metrics.get("future_public", {})

    hidden_rrmse = safe_float(hidden.get("rRMSE", float("inf")))
    future_rrmse = safe_float(future.get("rRMSE", float("inf")))
    if hidden_rrmse >= 1.60 or future_rrmse >= 1.60:
        return "cap15_public_only_or_very_poor_hidden"
    if hidden_rrmse >= 0.85 or future_rrmse >= 0.90:
        return "cap30_poor_but_improving_hidden"
    if hidden_rrmse >= 0.35 or future_rrmse >= 0.40:
        return "cap45_moderate_hidden"
    return "none"


def apply_metric_quality_caps(total_score: float, metrics: dict) -> float:
    reason = metric_cap_reason(metrics)
    total_score = float(total_score)
    if reason == "cap15_public_only_or_very_poor_hidden":
        return min(total_score, 15.0)
    if reason == "cap30_poor_but_improving_hidden":
        return min(total_score, 30.0)
    if reason == "cap45_moderate_hidden":
        return min(total_score, 45.0)
    return total_score

def clipped_linear_score(error: float, good: float, bad: float, points: float) -> float:
    """
    Lower-is-better linear score with clipping.

    error <= good: full points
    error >= bad:  zero points
    good < error < bad: linearly interpolated
    """
    try:
        error = float(error)
    except Exception:
        return 0.0

    if not math.isfinite(error):
        return 0.0
    if error <= good:
        return float(points)
    if error >= bad:
        return 0.0
    return float(points) * (bad - error) / (bad - good)


def score_metric_linear(metrics: dict[str, Any]) -> tuple[float, dict[str, float]]:
    """
    Continuous metric score with two layers:
    - coarse score: gentle slope for poor answers so agents can learn direction;
    - precision score: strict high-value reward for true hidden/future fit.
    """
    hidden = metrics.get("hidden_well", {}) or {}
    future = metrics.get("future_public", {}) or {}

    hidden_rrmse = safe_float(hidden.get("rRMSE"), float("inf"))
    future_rrmse = safe_float(future.get("rRMSE"), float("inf"))
    hidden_log = safe_float(hidden.get("log_rmse"), float("inf"))
    future_log = safe_float(future.get("log_rmse"), float("inf"))

    hidden_rrmse_coarse = smooth_linear_score(hidden_rrmse, good=0.85, bad=1.60, points=5, gamma=1.6)
    future_rrmse_coarse = smooth_linear_score(future_rrmse, good=0.90, bad=1.60, points=5, gamma=1.6)
    hidden_log_coarse = smooth_linear_score(hidden_log, good=0.035, bad=0.110, points=2, gamma=1.4)
    future_log_coarse = smooth_linear_score(future_log, good=0.040, bad=0.120, points=2, gamma=1.4)

    hidden_rrmse_precise = log_power_score(hidden_rrmse, good=0.04, bad=0.35, points=33, gamma=2.6)
    future_rrmse_precise = log_power_score(future_rrmse, good=0.05, bad=0.40, points=25, gamma=2.6)
    hidden_log_precise = log_power_score(hidden_log, good=0.010, bad=0.045, points=10, gamma=2.2)
    future_log_precise = log_power_score(future_log, good=0.012, bad=0.055, points=10, gamma=2.2)

    total = (
        hidden_rrmse_coarse + future_rrmse_coarse + hidden_log_coarse + future_log_coarse
        + hidden_rrmse_precise + future_rrmse_precise + hidden_log_precise + future_log_precise
    )
    detail = {
        "hidden_rrmse_coarse": hidden_rrmse_coarse,
        "future_rrmse_coarse": future_rrmse_coarse,
        "hidden_log_coarse": hidden_log_coarse,
        "future_log_coarse": future_log_coarse,
        "hidden_rrmse_precise": hidden_rrmse_precise,
        "future_rrmse_precise": future_rrmse_precise,
        "hidden_log_precise": hidden_log_precise,
        "future_log_precise": future_log_precise,
        "hidden_rrmse_score": hidden_rrmse_coarse + hidden_rrmse_precise,
        "future_rrmse_score": future_rrmse_coarse + future_rrmse_precise,
        "hidden_log_score": hidden_log_coarse + hidden_log_precise,
        "future_log_score": future_log_coarse + future_log_precise,
        "metric_score_linear": total,
    }
    return total, detail


def normalize_time_key(df: pd.DataFrame) -> pd.DataFrame:
    out = df.copy()
    if "time_days" not in out.columns:
        if "time" in out.columns:
            out["time_days"] = out["time"].astype(float)
        else:
            raise ValueError("time_days column not found")
    out["time_key"] = out["time_days"].astype(float).round(8)
    return out


def find_obs_concentration_column(df: pd.DataFrame) -> str:
    candidates = [
        "concentration_clean_mg_L",
        "concentration_observed_mg_L",
        "concentration_mg_L",
        "concentration",
        "obs",
        "observed",
    ]
    for c in candidates:
        if c in df.columns:
            return c
    raise ValueError(f"No observation concentration column found. Columns={list(df.columns)}")


def find_pred_concentration_column(df: pd.DataFrame) -> str:
    candidates = [
        "concentration_predicted_mg_L",
        "concentration_mg_L",
        "concentration",
        "pred",
        "predicted",
    ]
    for c in candidates:
        if c in df.columns:
            return c
    raise ValueError(f"No prediction concentration column found. Columns={list(df.columns)}")


def compute_censored_public_metrics(obs: pd.DataFrame, pred: pd.DataFrame) -> tuple[dict[str, Any], pd.DataFrame]:
    obs2 = normalize_time_key(obs)
    pred2 = normalize_time_key(pred)
    pred_col = find_pred_concentration_column(pred2)
    merged = obs2.merge(pred2, on=["well_id", "time_key"], suffixes=("_obs", "_pred"), how="inner")
    if merged.empty:
        return {
            "censored_log_rmse": float("inf"),
            "above_log_rmse": float("inf"),
            "below_excess_rate": float("inf"),
            "n": 0,
        }, merged

    pred_col_m = pred_col if pred_col in merged.columns else f"{pred_col}_pred"
    if "concentration_observed_mg_L" in merged.columns:
        obs_col = "concentration_observed_mg_L"
    elif "concentration_observed_mg_L_obs" in merged.columns:
        obs_col = "concentration_observed_mg_L_obs"
    else:
        obs_col = find_obs_concentration_column(merged)
    if "above_detection_limit" in merged.columns:
        above_col = "above_detection_limit"
    elif "above_detection_limit_obs" in merged.columns:
        above_col = "above_detection_limit_obs"
    else:
        above_col = None
    if "detection_limit_mg_L" in merged.columns:
        det = merged["detection_limit_mg_L"].to_numpy(dtype=float)
    elif "detection_limit_mg_L_obs" in merged.columns:
        det = merged["detection_limit_mg_L_obs"].to_numpy(dtype=float)
    else:
        det = np.full(len(merged), 0.005, dtype=float)

    y = np.maximum(merged[obs_col].to_numpy(dtype=float), 0.0)
    p = np.maximum(np.nan_to_num(merged[pred_col_m].to_numpy(dtype=float), nan=0.0), 0.0)
    above = merged[above_col].astype(bool).to_numpy() if above_col else y > det

    parts = []
    if np.any(above):
        parts.append(np.log1p(p[above]) - np.log1p(y[above]))
        above_log = float(np.sqrt(np.mean(parts[-1] * parts[-1])))
    else:
        above_log = 0.0
    if np.any(~above):
        excess = np.maximum(p[~above] - det[~above], 0.0)
        below = np.log1p(excess / np.maximum(det[~above], 1e-8))
        parts.append(below)
        below_excess_rate = float(np.mean(excess > 0.0))
    else:
        below_excess_rate = 0.0
    all_resid = np.concatenate(parts) if parts else np.zeros(1, dtype=float)
    return {
        "censored_log_rmse": float(np.sqrt(np.mean(all_resid * all_resid))),
        "above_log_rmse": above_log,
        "below_excess_rate": below_excess_rate,
        "n": int(len(merged)),
    }, merged


def compute_rmse_metrics(obs: pd.DataFrame, pred: pd.DataFrame) -> tuple[dict[str, Any], pd.DataFrame]:
    obs2 = normalize_time_key(obs)
    pred2 = normalize_time_key(pred)

    obs_col = find_obs_concentration_column(obs2)
    pred_col = find_pred_concentration_column(pred2)

    if "well_id" not in obs2.columns or "well_id" not in pred2.columns:
        raise ValueError("well_id column required in obs and pred")

    merged = obs2.merge(pred2, on=["well_id", "time_key"], suffixes=("_obs", "_pred"), how="inner")
    if merged.empty:
        return {
            "rmse": float("inf"),
            "rRMSE": float("inf"),
            "log_rmse": float("inf"),
            "log_rRMSE": float("inf"),
            "n": 0,
        }, merged

    obs_col_m = obs_col if obs_col in merged.columns else f"{obs_col}_obs"
    pred_col_m = pred_col if pred_col in merged.columns else f"{pred_col}_pred"

    c_obs = merged[obs_col_m].to_numpy(dtype=float)
    c_pred = merged[pred_col_m].to_numpy(dtype=float)
    c_pred = np.nan_to_num(c_pred, nan=0.0, posinf=0.0, neginf=0.0)
    c_pred = np.maximum(c_pred, 0.0)

    diff = c_pred - c_obs
    rmse = float(np.sqrt(np.mean(diff * diff)))
    rrmse = rmse / max(float(np.mean(np.abs(c_obs))), 1e-8)

    log_obs = np.log1p(np.maximum(c_obs, 0.0))
    log_pred = np.log1p(np.maximum(c_pred, 0.0))
    log_rmse = float(np.sqrt(np.mean((log_pred - log_obs) ** 2)))
    log_rrmse = log_rmse / max(float(np.mean(np.abs(log_obs))), 1e-8)

    return {
        "rmse": rmse,
        "rRMSE": rrmse,
        "log_rmse": log_rmse,
        "log_rRMSE": log_rrmse,
        "n": int(len(merged)),
    }, merged


def detect_group_column(df: pd.DataFrame) -> str | None:
    for c in ["eval_split", "eval_group", "group", "subset", "split", "category"]:
        if c in df.columns:
            return c
    return None


def compute_grouped_hidden_metrics(hidden_obs: pd.DataFrame, pred: pd.DataFrame) -> dict[str, Any]:
    metrics: dict[str, Any] = {}
    all_metrics, _ = compute_rmse_metrics(hidden_obs, pred)
    metrics["all"] = all_metrics

    group_col = detect_group_column(hidden_obs)
    if group_col is not None:
        groups = {str(g): hidden_obs[hidden_obs[group_col].astype(str) == str(g)].copy() for g in hidden_obs[group_col].dropna().unique()}
        for name, sub in groups.items():
            if len(sub) > 0:
                metrics[name] = compute_rmse_metrics(sub, pred)[0]

    # Fallback aliases if hidden data lacks explicit split labels.
    if "hidden_well" not in metrics:
        metrics["hidden_well"] = metrics.get("all", all_metrics)
    if "future_public" not in metrics:
        metrics["future_public"] = metrics.get("all", all_metrics)

    return metrics


# ============================================================
# Non-metric scoring
# ============================================================

def score_format(answer: dict[str, Any], exists: bool) -> int:
    if not exists:
        return 0

    required = [
        "source_type", "dimension", "x_center", "y_center", "z_center",
        "half_length_x", "half_length_y", "half_length_z", "C0", "t_start", "duration",
    ]
    score = 0
    if all(k in answer for k in required):
        score += 2
    try:
        if int(answer.get("dimension")) == 3 and str(answer.get("source_type", "")) == "rectangular_region":
            score += 1
    except Exception:
        pass
    return min(score, 3)


def get_bounds_dict(config: dict[str, Any]) -> dict[str, Any]:
    # Support both source_prior-style and source_search_bounds-style configs.
    for key in ["source_parameter_bounds", "source_search_bounds_for_agent", "source_bounds"]:
        if isinstance(config.get(key), dict):
            return config[key]
    return config


def range_from_bounds(bounds: dict[str, Any], name: str, fallback: tuple[float, float]) -> tuple[float, float]:
    # Supports either name_range=[lo,hi] or name_min/name_max.
    rkey = f"{name}_range"
    if isinstance(bounds.get(rkey), (list, tuple)) and len(bounds[rkey]) == 2:
        return float(bounds[rkey][0]), float(bounds[rkey][1])
    lo = bounds.get(f"{name}_min", fallback[0])
    hi = bounds.get(f"{name}_max", fallback[1])
    return float(lo), float(hi)


def score_bounds(answer: dict[str, Any], config: dict[str, Any], prior_path: Path | None = None) -> int:
    bounds = get_bounds_dict(config)
    if prior_path and prior_path.exists():
        try:
            prior = load_json(prior_path)
            if isinstance(prior, dict):
                bounds = {**bounds, **prior}
        except Exception:
            pass

    checks = [
        ("x_center", (-1e9, 1e9)),
        ("y_center", (-1e9, 1e9)),
        ("z_center", (-1e9, 1e9)),
        ("half_length_x", (0.0, 1e9)),
        ("half_length_y", (0.0, 1e9)),
        ("half_length_z", (0.0, 1e9)),
        ("C0", (0.0, 1e12)),
        ("t_start", (0.0, 1e12)),
        ("duration", (0.0, 1e12)),
    ]

    ok = True
    for name, fb in checks:
        v = safe_float(answer.get(name), float("nan"))
        lo, hi = range_from_bounds(bounds, name, fb)
        if not (math.isfinite(v) and lo <= v <= hi):
            ok = False
            break

    return 2 if ok else 0


def score_method_and_workflow(answer: dict[str, Any], submission_dir: Path) -> int:
    score = 0
    method = str(answer.get("method", "")).strip()
    if len(method) >= 20:
        score += 2
    elif method:
        score += 1

    py_files = [p for p in submission_dir.glob("*.py") if p.name != "baseline_solver.py"]
    if py_files:
        score += 2

    if (submission_dir / "report.md").exists() or (submission_dir / "results.json").exists():
        score += 1

    return min(score, 5)


def score_transport_equation(answer: dict[str, Any], config: dict[str, Any]) -> tuple[float, dict[str, Any]]:
    """
    Reward an explicit ADE solute transport construction, but keep it small.
    This is learning feedback for agents; predictive hidden/future metrics still
    control the final caps.
    """
    model = answer.get("transport_model", {})
    if not isinstance(model, dict):
        return 0.0, {"reason": "transport_model_missing_or_not_object"}

    hydro = config.get("hydrogeological_parameters", {}) or {}
    score = 0.0
    detail: dict[str, Any] = {}

    equation_text = " ".join([
        str(model.get("equation_type", "")),
        str(model.get("governing_equation", "")),
        str(model.get("numerical_approach", "")),
    ]).lower()
    terms = {
        "time": ("dc/dt" in equation_text) or ("time" in equation_text),
        "advection": ("advection" in equation_text) or ("v dot grad" in equation_text) or ("velocity" in equation_text),
        "dispersion": ("dispersion" in equation_text) or ("div(d grad" in equation_text) or ("alpha_l" in equation_text),
        "reaction": ("lambda" in equation_text) or ("decay" in equation_text) or ("reaction" in equation_text),
        "source": "source" in equation_text,
    }
    term_count = sum(bool(v) for v in terms.values())
    score += min(3.0, 0.6 * term_count)
    detail["recognized_terms"] = terms

    numeric_checks = [
        ("velocity_m_per_day", hydro.get("velocity_m_per_day")),
        ("alpha_L_m", hydro.get("alpha_L_m")),
        ("alpha_TH_m", hydro.get("alpha_TH_m")),
        ("alpha_TV_m", hydro.get("alpha_TV_m")),
        ("porosity", hydro.get("porosity")),
        ("retardation_factor", hydro.get("retardation_factor")),
        ("lambda_per_day", hydro.get("lambda_per_day")),
    ]
    matched = 0
    hydro_feedback: dict[str, Any] = {}
    for name, expected in numeric_checks:
        got = safe_float(model.get(name), float("nan"))
        exp = safe_float(expected, float("nan"))
        hydro_feedback[name] = {
            "value": got if math.isfinite(got) else None,
            "expected": exp if math.isfinite(exp) else None,
            "status": "missing_or_nonfinite",
        }
        if math.isfinite(got) and math.isfinite(exp):
            tol = max(abs(exp) * 0.25, 1e-8)
            if abs(got - exp) <= tol:
                matched += 1
                hydro_feedback[name]["status"] = "near_public_reference"
            else:
                hydro_feedback[name]["status"] = "far_from_public_reference"
            hydro_feedback[name]["relative_error"] = abs(got - exp) / max(abs(exp), 1e-8)
    score += min(3.0, 3.0 * matched / max(len(numeric_checks), 1))
    detail["matched_public_hydro_parameters"] = matched
    detail["hydro_parameter_feedback"] = hydro_feedback

    approach = str(model.get("numerical_approach", "")).lower()
    detail["numerical_approach_status"] = "missing_or_too_short"
    if len(approach) >= 30:
        score += 1.0
        detail["numerical_approach_status"] = "described"
    if any(k in approach for k in ["optimi", "least", "differential", "anneal", "grid", "multi-start", "multistart"]):
        score += 1.0
        detail["numerical_approach_status"] = "describes_optimization"
    detail["transport_equation_score_raw"] = score
    return min(score, 8.0), detail


def score_public_sanity(answer: dict[str, Any], case_dir: Path, config: dict[str, Any], scoring_dir: Path) -> tuple[int, dict[str, Any]]:
    """
    Public observations are noisy and censored. This sanity score rewards
    plausible public predictions without letting public-only fitting dominate.
    """
    public_obs_path = case_dir / "public_monitoring_data.csv"
    public_wells_path = case_dir / "public_wells.csv"
    if not public_obs_path.exists() or not public_wells_path.exists():
        return 0, {}

    try:
        sys.path.insert(0, str(scoring_dir))
        from hidden_forward_model import simulate_from_answer  # type: ignore

        public_obs = pd.read_csv(public_obs_path)
        public_wells = pd.read_csv(public_wells_path)
        times = sorted(public_obs["time_days"].astype(float).unique())
        pred = simulate_from_answer(answer, public_wells, np.asarray(times, dtype=float), config)
        m, _ = compute_censored_public_metrics(public_obs, pred)
        score = clipped_linear_score(m.get("censored_log_rmse", float("inf")), good=0.035, bad=0.55, points=10)
        return float(score), m
    except Exception:
        return 0, {}


def score_region_physics(answer: dict[str, Any], metrics: dict[str, Any]) -> int:
    """
    Region/physics score, total 15 points, gated by hidden/future predictive quality.
    If hidden/future fit is weak, plausible-looking parameters should not add many points.
    """
    hidden_rrmse = safe_float(metrics.get("hidden_well", {}).get("rRMSE"), float("inf"))
    future_rrmse = safe_float(metrics.get("future_public", {}).get("rRMSE"), float("inf"))

    if hidden_rrmse >= 0.85 or future_rrmse >= 0.90:
        return 0

    vals = {
        "half_length_x": safe_float(answer.get("half_length_x")),
        "half_length_y": safe_float(answer.get("half_length_y")),
        "half_length_z": safe_float(answer.get("half_length_z")),
        "C0": safe_float(answer.get("C0")),
        "duration": safe_float(answer.get("duration")),
        "t_start": safe_float(answer.get("t_start")),
    }
    score = 0
    if vals["half_length_x"] > 0: score += 3
    if vals["half_length_y"] > 0: score += 3
    if vals["half_length_z"] > 0: score += 2
    if vals["C0"] > 0: score += 3
    if vals["duration"] > 0: score += 2
    if vals["t_start"] >= 0: score += 2
    return min(score, 15)


def inspect_forbidden_access(submission_dir: Path) -> list[str]:
    warnings: list[str] = []
    forbidden = [
        "hidden_monitoring_data", "hidden_wells", "hidden_true_region_source",
        "hidden_forward_model", "hidden_eval_config", "/opt/borden_scoring",
        "private_generation_record_not_for_agent", "scoring/", "MODFLOW", "MT3DMS", "flopy.run_model",
    ]
    for p in submission_dir.rglob("*.py"):
        rel = p.relative_to(submission_dir).as_posix()
        if rel.startswith("scoring/"):
            continue
        try:
            text = p.read_text(encoding="utf-8", errors="ignore")
        except Exception:
            continue
        for kw in forbidden:
            if kw in text:
                warnings.append(f"Forbidden/suspicious keyword `{kw}` in {rel}")
    return warnings


# ============================================================
# Main evaluation
# ============================================================

def evaluate(submission_dir: Path, case_dir: Path, scoring_dir: Path, output: Path) -> dict[str, Any]:
    answer_path = submission_dir / "answer.json"
    config_path = case_dir / "public_problem_config.json"
    prior_path = case_dir / "public_source_prior.json"

    detail: dict[str, Any] = {
        "total_score": 0,
        "raw_total_before_cap": 0,
        "format_score": 0,
        "bounds_score": 0,
        "public_sanity_score": 0,
        "method_workflow_score": 0,
        "transport_equation_score": 0,
        "transport_equation_detail": {},
        "metric_score_linear": 0,
        "region_physics_score": 0,
        "metric_score_detail": {},
        "metrics": {},
        "public_metrics": {},
        "warnings": [],
        "errors": [],
    }

    if not answer_path.exists():
        detail["errors"].append("answer.json not found")
        save_json(detail, output)
        print(f"CASE {TASK_NAME} WA score=0")
        print("TOTAL_SCORE 0")
        return detail

    try:
        answer = load_json(answer_path)
    except Exception as exc:
        detail["errors"].append(f"Failed to load answer.json: {exc}")
        save_json(detail, output)
        print(f"CASE {TASK_NAME} WA score=0")
        print("TOTAL_SCORE 0")
        return detail

    try:
        config = load_json(config_path)
    except Exception:
        config = {}

    answer_summary = {
        "source_type": answer.get("source_type"),
        "x_center": answer.get("x_center"),
        "y_center": answer.get("y_center"),
        "z_center": answer.get("z_center"),
        "half_length_x": answer.get("half_length_x"),
        "half_length_y": answer.get("half_length_y"),
        "half_length_z": answer.get("half_length_z"),
        "C0": answer.get("C0"),
        "t_start": answer.get("t_start"),
        "duration": answer.get("duration"),
        "transport_model": answer.get("transport_model"),
    }

    detail["format_score"] = score_format(answer, True)
    detail["bounds_score"] = score_bounds(answer, config, prior_path)
    detail["method_workflow_score"] = score_method_and_workflow(answer, submission_dir)
    transport_score, transport_detail = score_transport_equation(answer, config)
    detail["transport_equation_score"] = transport_score
    detail["transport_equation_detail"] = transport_detail
    detail["warnings"].extend(inspect_forbidden_access(submission_dir))

    # Public sanity score is small and intentionally non-dominant.
    public_sanity_score, public_metrics = score_public_sanity(answer, case_dir, config, scoring_dir)
    detail["public_sanity_score"] = public_sanity_score
    detail["public_metrics"] = public_metrics

    try:
        sys.path.insert(0, str(scoring_dir))
        from hidden_forward_model import simulate_from_answer  # type: ignore

        hidden_wells = pd.read_csv(scoring_dir / "hidden_wells.csv")
        public_wells_path = case_dir / "public_wells.csv"
        if public_wells_path.exists():
            public_wells = pd.read_csv(public_wells_path)
            pred_wells = pd.concat([hidden_wells, public_wells], ignore_index=True)
            pred_wells = pred_wells.drop_duplicates(subset=["well_id"], keep="first")
        else:
            pred_wells = hidden_wells
        hidden_obs = pd.read_csv(scoring_dir / "hidden_monitoring_data.csv")
        times = sorted(hidden_obs["time_days"].astype(float).unique())
        pred = simulate_from_answer(answer, pred_wells, np.asarray(times, dtype=float), config)
        metrics = compute_grouped_hidden_metrics(hidden_obs, pred)
        detail["metrics"] = metrics

        metric_score, metric_score_detail = score_metric_linear(metrics)
        detail["metric_score_linear"] = metric_score
        detail["metric_score_detail"] = metric_score_detail
        detail["region_physics_score"] = score_region_physics(answer, metrics)

    except Exception as exc:
        detail["errors"].append(f"Hidden metric scoring failed: {exc}")
        detail["metrics"] = {}

    # Keep shallow/public-only answers from receiving large easy points.
    detail["format_score"] = min(float(detail["format_score"]), 1.0)
    detail["bounds_score"] = min(float(detail["bounds_score"]), 1.0)
    detail["public_sanity_score"] = min(float(detail["public_sanity_score"]), 2.0)
    detail["method_workflow_score"] = min(float(detail["method_workflow_score"]), 1.0)
    detail["transport_equation_score"] = min(float(detail["transport_equation_score"]), 2.0)

    metrics_for_caps = detail.get("metrics", {}) or {}
    hidden_rrmse = safe_float(metrics_for_caps.get("hidden_well", {}).get("rRMSE"), float("inf"))
    future_rrmse = safe_float(metrics_for_caps.get("future_public", {}).get("rRMSE"), float("inf"))
    detail["region_physics_score_before_gate"] = round3(detail["region_physics_score"])
    if hidden_rrmse >= 0.35 or future_rrmse >= 0.40:
        detail["region_physics_score"] = 0.0
        detail["region_physics_gate"] = "blocked_by_hidden_or_future_rrmse"
    else:
        detail["region_physics_score"] = min(float(detail["region_physics_score"]), 10.0)
        detail["region_physics_gate"] = "passed_capped_at_10"

    raw_total = (
        detail["format_score"]
        + detail["bounds_score"]
        + detail["public_sanity_score"]
        + detail["method_workflow_score"]
        + detail["transport_equation_score"]
        + detail["metric_score_linear"]
        + detail["region_physics_score"]
    )
    detail["raw_total_before_cap"] = float(raw_total)
    detail["cap_reason"] = metric_cap_reason(metrics_for_caps)
    total_score = apply_metric_quality_caps(raw_total, metrics_for_caps)
    detail["total_score"] = round3(total_score)

    save_json(detail, output)

    print("ANSWER_SUMMARY", json.dumps(answer_summary, ensure_ascii=False))
    print(f"CASE {TASK_NAME} OK score={detail['total_score']}")
    print(f"CASE borden_inverse OK score={float(detail['total_score']):.3f}")
    print(f"RAW_TOTAL_SCORE {float(locals().get('raw_total', detail.get('raw_total', detail.get('raw_total_before_cap', detail.get('total_score', 0.0))))):.3f}")
    print(f"TOTAL_SCORE {float(detail['total_score']):.3f}")
    emit_score_sum_agent_feedback(detail, metrics)
    print("SCORE_BREAKDOWN", json.dumps({
        "raw_total_before_cap": detail["raw_total_before_cap"],
        "cap_reason": detail["cap_reason"],
        "format_score": detail["format_score"],
        "bounds_score": detail["bounds_score"],
        "public_sanity_score": detail["public_sanity_score"],
        "method_workflow_score": detail["method_workflow_score"],
        "transport_equation_score": detail["transport_equation_score"],
        "transport_equation_detail": detail["transport_equation_detail"],
        "metric_score_linear": detail["metric_score_linear"],
        "region_physics_score": detail["region_physics_score"],
        "metric_score_detail": detail["metric_score_detail"],
    }, ensure_ascii=False))
    print("METRICS", json.dumps(detail.get("metrics", {}), ensure_ascii=False))

    # ---- SE-Bench structured_json feedback block ----
    try:
        _detail = locals().get("detail", locals().get("score_detail", {}))
        _metrics = locals().get("metrics", {})
        _answer_summary = locals().get("answer_summary", locals().get("summary", {}))

        def _safe_float(x, default=999.0):
            try:
                v = float(x)
                if v != v:
                    return default
                return v
            except Exception:
                return default

        _hidden = _metrics.get("hidden_well", {}) or {}
        _future = _metrics.get("future_public", {}) or {}

        _hidden_rrmse = _safe_float(_hidden.get("rRMSE"))
        _future_rrmse = _safe_float(_future.get("rRMSE"))
        _hidden_log = _safe_float(_hidden.get("log_rmse"))
        _future_log = _safe_float(_future.get("log_rmse"))

        _total_score = _safe_float(
            _detail.get("total_score", locals().get("total_score", locals().get("score", 0.0))),
            default=0.0,
        )
        _raw_total = _safe_float(
            _detail.get("raw_total_before_cap", _detail.get("raw_total_score", _total_score)),
            default=_total_score,
        )

        _cap_reason = _detail.get("cap_reason", _detail.get("metric_cap_reason", "none"))

        _metric_detail = _detail.get("metric_score_detail", {}) or {}

        structured_result = {
            "valid": True,
            "score": float(_total_score),
            "pass_rate": 1.0,
            "summary": (
                f"TOTAL_SCORE={_total_score:.3f}; "
                f"RAW_TOTAL_SCORE={_raw_total:.3f}; "
                f"cap_reason={_cap_reason}; "
                f"hidden_well_rRMSE={_hidden_rrmse}; "
                f"future_public_rRMSE={_future_rrmse}; "
                f"hidden_well_log_rmse={_hidden_log}; "
                f"future_public_log_rmse={_future_log}"
            ),
            "metrics": {
                "total_score": float(_total_score),
                "raw_total_score": float(_raw_total),
                "cap_reason": _cap_reason,
                "hidden_well_rRMSE": _hidden_rrmse,
                "future_public_rRMSE": _future_rrmse,
                "hidden_well_log_rmse": _hidden_log,
                "future_public_log_rmse": _future_log,
                "format_score": _detail.get("format_score"),
                "bounds_score": _detail.get("bounds_score"),
                "public_sanity_score": _detail.get("public_sanity_score"),
                "method_workflow_score": _detail.get("method_workflow_score"),
                "transport_equation_score": _detail.get("transport_equation_score"),
                "transport_equation_detail": _detail.get("transport_equation_detail"),
                "region_physics_score": _detail.get("region_physics_score"),
                "hidden_rrmse_score": _metric_detail.get("hidden_rrmse_score"),
                "future_rrmse_score": _metric_detail.get("future_rrmse_score"),
                "hidden_log_score": _metric_detail.get("hidden_log_score"),
                "future_log_score": _metric_detail.get("future_log_score"),
                "score_breakdown": _detail,
                "answer_summary": _answer_summary,
            },
            "details": [
                {
                    "name": "format_validity",
                    "status": "PASSED" if _safe_float(_detail.get("format_score", 0), 0) > 0 else "FAILED",
                    "score": _detail.get("format_score", 0),
                    "weight": 2,
                    "message": "answer.json schema and required fields check",
                },
                {
                    "name": "hidden_well_prediction",
                    "status": "PASSED" if _hidden_rrmse < 0.25 else "FAILED",
                    "score": _metric_detail.get("hidden_rrmse_score", 0),
                    "weight": 45,
                    "message": f"hidden_well rRMSE={_hidden_rrmse}",
                },
                {
                    "name": "future_time_extrapolation",
                    "status": "PASSED" if _future_rrmse < 0.35 else "FAILED",
                    "score": _metric_detail.get("future_rrmse_score", 0),
                    "weight": 30,
                    "message": f"future_public rRMSE={_future_rrmse}",
                },
                {
                    "name": "quality_cap",
                    "status": "PASSED" if str(_cap_reason) == "none" else "FAILED",
                    "score": float(_total_score),
                    "weight": 100,
                    "message": f"cap_reason={_cap_reason}",
                },
            ],
        }

        print(">>>>> Start Structured Result")
        print(json.dumps(structured_result, ensure_ascii=False))
        print(">>>>> End Structured Result")
    except Exception as _structured_exc:
        print("STRUCTURED_RESULT_ERROR", repr(_structured_exc))
    # ---- End SE-Bench structured_json feedback block ----
    if detail["warnings"]:
        print("WARNINGS", json.dumps(detail["warnings"], ensure_ascii=False))
    if detail["errors"]:
        print("ERRORS", json.dumps(detail["errors"], ensure_ascii=False))

    return detail


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--submission_dir", required=True)
    parser.add_argument("--case_dir", required=True)
    parser.add_argument("--scoring_dir", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    evaluate(
        submission_dir=Path(args.submission_dir),
        case_dir=Path(args.case_dir),
        scoring_dir=Path(args.scoring_dir),
        output=Path(args.output),
    )


if __name__ == "__main__":
    main()
