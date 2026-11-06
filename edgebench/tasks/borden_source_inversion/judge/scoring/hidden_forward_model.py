
from __future__ import annotations

# Judge-side forward model for the Borden finite-duration rectangular-region source task.
# It intentionally mirrors generator/borden_scene.py but is self-contained inside scoring/.

import math
from typing import Dict, Iterable, Any
import numpy as np
import pandas as pd

HYDRO_DEFAULTS = {
    "porosity": 0.3,
    "hk_m_per_day": 10.0,
    "head_upstream_m": 220.0,
    "head_downstream_m": 219.0,
    "alpha_L_m": 10.0,
    "alpha_TH_m": 0.5,
    "alpha_TV_m": 0.01,
    "Dm_m2_per_day": 0.0,
    "lambda_per_day": 0.0,
    "retardation_factor": 1.0,
    "q_source_m3_per_day": 0.06764533176746916,
    "fallback_source_scale_factor": 1000.0,
}


def estimate_uniform_velocity(hk=10.0, porosity=0.3, head_upstream=220.0, head_downstream=219.0, Lx=1200.0):
    hydraulic_gradient = (head_upstream - head_downstream) / Lx
    return hk * hydraulic_gradient / porosity


def safe_float(x, default=0.0):
    try:
        v = float(x)
        if math.isfinite(v):
            return v
    except Exception:
        pass
    return default


def normalize_region_answer(source_params: Dict[str, Any], config: Dict[str, Any]) -> Dict[str, Any]:
    p = dict(source_params)
    b = config.get("source_search_bounds_for_agent", {})
    # Backward-compatible fallback: point-source submissions are treated as tiny regions.
    if "x_center" not in p and "x0" in p:
        p["x_center"] = p.get("x0")
    if "y_center" not in p and "y0" in p:
        p["y_center"] = p.get("y0")
    if "z_center" not in p and "z0" in p:
        p["z_center"] = p.get("z0")
    p.setdefault("source_type", "rectangular_region")
    p.setdefault("dimension", 3)
    p.setdefault("half_length_x", b.get("half_length_x_min", 5.0))
    p.setdefault("half_length_y", b.get("half_length_y_min", 5.0))
    p.setdefault("half_length_z", b.get("half_length_z_min", 0.5))
    p.setdefault("C0", 100.0)
    p.setdefault("t_start", b.get("t_start_min", 0.0))
    p.setdefault("duration", b.get("duration_min", 100.0))
    out = {"source_type": str(p.get("source_type", "rectangular_region")), "dimension": int(p.get("dimension", 3))}
    for k in ["x_center", "y_center", "z_center", "half_length_x", "half_length_y", "half_length_z", "C0", "t_start", "duration"]:
        out[k] = safe_float(p.get(k), 0.0)
    return out


def _fallback_point3(c0, x, y, z, t, v, porosity, al, ah, av, q_source, source_x, source_y, source_z, Dm=0.0, lamb=0.0, R=1.0, source_scale_factor=1000.0):
    x = np.asarray(x, dtype=float); y = np.asarray(y, dtype=float); z = np.asarray(z, dtype=float)
    t = np.asarray(t, dtype=float)
    t = np.maximum(t / max(R, 1e-12), 1e-6)
    DL = max(al * abs(v) + Dm, 1e-8)
    DT = max(ah * abs(v) + Dm, 1e-8)
    DV = max(av * abs(v) + Dm, 1e-8)
    dx = x - source_x - v * t
    dy = y - source_y
    dz = z - source_z
    expo = -((dx * dx) / (4 * DL * t) + (dy * dy) / (4 * DT * t) + (dz * dz) / (4 * DV * t))
    denom = (4 * math.pi * t) ** 1.5 * math.sqrt(DL * DT * DV)
    val = c0 * q_source * source_scale_factor / np.maximum(denom, 1e-30) * np.exp(expo) * np.exp(-lamb * t)
    return np.maximum(val, 0.0)


def _region_subpoints(source, config):
    disc = config.get("region_source_discretization", {})
    nx = int(disc.get("nx", 5)); ny = int(disc.get("ny", 5)); nz = int(disc.get("nz", 1))
    xs = np.linspace(source["x_center"] - source["half_length_x"], source["x_center"] + source["half_length_x"], nx)
    ys = np.linspace(source["y_center"] - source["half_length_y"], source["y_center"] + source["half_length_y"], ny)
    zs = np.linspace(source["z_center"] - source["half_length_z"], source["z_center"] + source["half_length_z"], nz)
    return [(float(x), float(y), float(z)) for x in xs for y in ys for z in zs]


def _release_offsets(duration, config):
    n_steps = int(config.get("region_source_discretization", {}).get("release_steps", 9))
    duration = max(float(duration), 1.0)
    if n_steps <= 1:
        return np.array([0.5 * duration], dtype=float)
    return np.linspace(0.0, duration, n_steps)


def _point_response(c0, x, y, z, t_arr, x0, y0, z0, hydro, config):
    porosity = float(hydro.get("porosity", HYDRO_DEFAULTS["porosity"]))
    v = float(hydro.get("velocity_m_per_day", estimate_uniform_velocity(
        hk=float(hydro.get("hk_m_per_day", HYDRO_DEFAULTS["hk_m_per_day"])),
        porosity=porosity,
        head_upstream=float(hydro.get("head_upstream_m", HYDRO_DEFAULTS["head_upstream_m"])),
        head_downstream=float(hydro.get("head_downstream_m", HYDRO_DEFAULTS["head_downstream_m"])),
        Lx=float(config.get("grid", {}).get("domain_length_x_m", 1200.0)),
    )))
    al = float(hydro.get("alpha_L_m", HYDRO_DEFAULTS["alpha_L_m"]))
    ah = float(hydro.get("alpha_TH_m", HYDRO_DEFAULTS["alpha_TH_m"]))
    av = float(hydro.get("alpha_TV_m", HYDRO_DEFAULTS["alpha_TV_m"]))
    dm = float(hydro.get("Dm_m2_per_day", HYDRO_DEFAULTS["Dm_m2_per_day"]))
    lamb = float(hydro.get("lambda_per_day", HYDRO_DEFAULTS["lambda_per_day"]))
    R = float(hydro.get("retardation_factor", HYDRO_DEFAULTS["retardation_factor"]))
    q_source = float(hydro.get("q_source_m3_per_day", HYDRO_DEFAULTS["q_source_m3_per_day"]))
    fallback_scale = float(hydro.get("fallback_source_scale_factor", HYDRO_DEFAULTS["fallback_source_scale_factor"]))
    return _fallback_point3(c0, x, y, z, t_arr, v, porosity, al, ah, av, q_source, x0, y0, z0, Dm=dm, lamb=lamb, R=R, source_scale_factor=fallback_scale)


def simulate_from_answer(answer: Dict[str, Any], wells: pd.DataFrame, hidden_times_days: Iterable[float], public_config: Dict[str, Any]) -> pd.DataFrame:
    source = normalize_region_answer(answer, public_config)
    hydro = public_config.get("hydrogeological_parameters", {})
    subpoints = _region_subpoints(source, public_config)
    release_offsets = _release_offsets(source["duration"], public_config)
    times_arr = np.asarray(list(hidden_times_days), dtype=float)
    t_start = float(source["t_start"])
    C0 = float(source["C0"])
    n_norm = max(len(subpoints) * len(release_offsets), 1)
    records = []
    for _, w in wells.iterrows():
        x = float(w["x"]); y = float(w["y"]); z = float(w["z"])
        conc_total = np.zeros_like(times_arr, dtype=float)
        for sx, sy, sz in subpoints:
            for off in release_offsets:
                tau = t_start + float(off)
                eff_t = times_arr - tau
                active = eff_t > 0.0
                if not np.any(active):
                    continue
                c = np.zeros_like(times_arr, dtype=float)
                c[active] = _point_response(C0 / n_norm, x, y, z, eff_t[active], sx, sy, sz, hydro, public_config)
                conc_total += c
        conc_total = np.nan_to_num(conc_total, nan=0.0, posinf=0.0, neginf=0.0)
        conc_total = np.maximum(conc_total, 0.0)
        for t, c in zip(times_arr, conc_total):
            records.append({
                "well_id": str(w["well_id"]),
                "x": x,
                "y": y,
                "z": z,
                "time_days": float(t),
                "time_years": float(t) / 365.0,
                "concentration_predicted_mg_L": float(c),
            })
    return pd.DataFrame.from_records(records)
