#!/usr/bin/env python3
"""Hidden evaluator for the Jagua Nesting Optimizer task.

The evaluator compares a submitted jagua-rs/lbf implementation against a
frozen reference checkout on deterministic hidden strip-packing instances.
It also validates the emitted solution JSON independently in Python so that a
submission cannot win by printing impossible strip widths.
"""

from __future__ import annotations

import argparse
import json
import math
import os
import shutil
import subprocess
import sys
import tempfile
import time
from dataclasses import dataclass
from pathlib import Path


EPS = 1e-5
BUILD_ENV = {**os.environ, "RUSTC_BOOTSTRAP": "1"}

HIDDEN_CASE_FILES = (
    "blaz1.json",
    "jakobs2.json",
    "mao.json",
    "marques.json",
    "shapes1.json",
    "shirts.json",
    "swim.json",
    "swim_cr.json",
    "trousers.json",
    "gardeyn0.json",
    "gardeyn1.json",
    "gardeyn2.json",
    "gardeyn3.json",
    "gardeyn4.json",
    "gardeyn5.json",
    "gardeyn6.json",
    "gardeyn7.json",
)


@dataclass
class CaseResult:
    name: str
    status: str
    score: float
    reason: str
    ref_width: float | None = None
    cand_width: float | None = None
    cand_runtime: float | None = None


def rotate_translate(poly: list[list[float]], rotation_deg: float, translation: list[float]) -> list[tuple[float, float]]:
    angle = math.radians(rotation_deg)
    ca = math.cos(angle)
    sa = math.sin(angle)
    tx, ty = translation
    out: list[tuple[float, float]] = []
    for x, y in poly:
        out.append((x * ca - y * sa + tx, x * sa + y * ca + ty))
    return out


def polygon_area(poly: list[tuple[float, float]]) -> float:
    area = 0.0
    pts = poly[:-1] if poly and poly[0] == poly[-1] else poly
    for (x1, y1), (x2, y2) in zip(pts, pts[1:] + pts[:1]):
        area += x1 * y2 - x2 * y1
    return area / 2.0


def orient(a: tuple[float, float], b: tuple[float, float], c: tuple[float, float]) -> float:
    return (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])


def on_segment(a: tuple[float, float], b: tuple[float, float], p: tuple[float, float]) -> bool:
    return (
        min(a[0], b[0]) - EPS <= p[0] <= max(a[0], b[0]) + EPS
        and min(a[1], b[1]) - EPS <= p[1] <= max(a[1], b[1]) + EPS
        and abs(orient(a, b, p)) <= EPS
    )


def segments_cross(a: tuple[float, float], b: tuple[float, float], c: tuple[float, float], d: tuple[float, float]) -> bool:
    o1 = orient(a, b, c)
    o2 = orient(a, b, d)
    o3 = orient(c, d, a)
    o4 = orient(c, d, b)
    if o1 * o2 < -EPS and o3 * o4 < -EPS:
        return True
    # Boundary touching is allowed in strip packing, so collinear endpoint
    # contacts do not count as overlap.
    if abs(o1) <= EPS and on_segment(a, b, c):
        return False
    if abs(o2) <= EPS and on_segment(a, b, d):
        return False
    if abs(o3) <= EPS and on_segment(c, d, a):
        return False
    if abs(o4) <= EPS and on_segment(c, d, b):
        return False
    return False


def point_in_polygon(p: tuple[float, float], poly: list[tuple[float, float]]) -> bool:
    x, y = p
    inside = False
    pts = poly[:-1] if poly and poly[0] == poly[-1] else poly
    n = len(pts)
    for i in range(n):
        x1, y1 = pts[i]
        x2, y2 = pts[(i + 1) % n]
        if on_segment((x1, y1), (x2, y2), p):
            return False
        if (y1 > y) != (y2 > y):
            x_int = (x2 - x1) * (y - y1) / (y2 - y1 + 1e-30) + x1
            if x < x_int:
                inside = not inside
    return inside


def polygons_overlap(a: list[tuple[float, float]], b: list[tuple[float, float]]) -> bool:
    aa = a[:-1] if a and a[0] == a[-1] else a
    bb = b[:-1] if b and b[0] == b[-1] else b
    for i in range(len(aa)):
        for j in range(len(bb)):
            if segments_cross(aa[i], aa[(i + 1) % len(aa)], bb[j], bb[(j + 1) % len(bb)]):
                return True
    if any(point_in_polygon(p, bb) for p in aa):
        return True
    if any(point_in_polygon(p, aa) for p in bb):
        return True
    return False


def polygon_bbox(poly: list[tuple[float, float]]) -> tuple[float, float, float, float]:
    pts = poly[:-1] if poly and poly[0] == poly[-1] else poly
    xs = [p[0] for p in pts]
    ys = [p[1] for p in pts]
    return min(xs), min(ys), max(xs), max(ys)


def bboxes_may_overlap(
    a: tuple[float, float, float, float],
    b: tuple[float, float, float, float],
) -> bool:
    return not (
        a[2] < b[0] - EPS
        or b[2] < a[0] - EPS
        or a[3] < b[1] - EPS
        or b[3] < a[1] - EPS
    )


def normalize_shape(shape: dict) -> list[list[float]]:
    if shape["type"] == "simple_polygon":
        data = shape["data"]
        return [[float(x), float(y)] for x, y in data]
    if shape["type"] == "rectangle":
        d = shape["data"]
        x = float(d["x_min"])
        y = float(d["y_min"])
        w = float(d["width"])
        h = float(d["height"])
        return [[x, y], [x + w, y], [x + w, y + h], [x, y + h], [x, y]]
    raise ValueError(f"unsupported shape type: {shape['type']}")


def validate_solution(instance_path: Path, solution_path: Path) -> tuple[bool, str, float]:
    inst = json.loads(instance_path.read_text())
    sol = json.loads(solution_path.read_text())
    solution = sol.get("solution")
    if not isinstance(solution, dict):
        return False, "missing_solution", 0.0
    layout = solution.get("layout", {})
    placed = layout.get("placed_items")
    if not isinstance(placed, list):
        return False, "missing_placed_items", 0.0

    items = {int(item["id"]): item for item in inst["items"]}
    item_polys = {item_id: normalize_shape(item["shape"]) for item_id, item in items.items()}
    demand = {int(item["id"]): int(item["demand"]) for item in inst["items"]}
    counts = {k: 0 for k in demand}
    height = float(inst["strip_height"])
    polygons: list[list[tuple[float, float]]] = []
    bboxes: list[tuple[float, float, float, float]] = []
    max_x = 0.0

    for idx, placed_item in enumerate(placed):
        item_id = int(placed_item["item_id"])
        if item_id not in items:
            return False, f"unknown_item_{item_id}", 0.0
        counts[item_id] += 1
        trans = placed_item.get("transformation", {})
        rot = float(trans.get("rotation", 0.0))
        tr = trans.get("translation", [0.0, 0.0])
        poly = rotate_translate(item_polys[item_id], rot, [float(tr[0]), float(tr[1])])
        if abs(polygon_area(poly)) <= EPS:
            return False, f"zero_area_{idx}", 0.0
        for x, y in poly:
            if x < -1e-4 or y < -1e-4 or y > height + 1e-4:
                return False, f"out_of_strip_{idx}", 0.0
            max_x = max(max_x, x)
        polygons.append(poly)
        bboxes.append(polygon_bbox(poly))

    if counts != demand:
        return False, f"demand_mismatch_{counts}_expected_{demand}", 0.0

    for i in range(len(polygons)):
        for j in range(i + 1, len(polygons)):
            if not bboxes_may_overlap(bboxes[i], bboxes[j]):
                continue
            if polygons_overlap(polygons[i], polygons[j]):
                return False, f"overlap_{i}_{j}", 0.0

    reported = float(solution.get("strip_width", max_x))
    width = max(max_x, reported)
    return True, "valid", width


def load_case_paths(reference: Path, args: argparse.Namespace) -> list[Path]:
    case_names = [name.strip() for name in args.case_list.split(",") if name.strip()]
    if args.cases:
        case_names = case_names[: args.cases]
    paths = [reference / "assets" / name for name in case_names]
    missing = [str(path) for path in paths if not path.exists()]
    if missing:
        raise FileNotFoundError("missing benchmark assets: " + ", ".join(missing))
    return paths


def write_config(path: Path, seed: int, n_samples: int) -> None:
    cfg = {
        "cde_config": {
            "quadtree_depth": 5,
            "cd_threshold": 16,
            "item_surrogate_config": {
                "n_pole_limits": [[100, 0.0], [20, 0.75], [10, 0.90]],
                "n_ff_poles": 2,
                "n_ff_piers": 0,
            },
        },
        "poly_simpl_tolerance": 0.0005,
        "narrow_concavity_cutoff": [0.01, 0.01],
        "min_item_separation": None,
        "prng_seed": seed,
        "n_samples": n_samples,
        "ls_frac": 0.25,
        "svg_draw_options": {},
    }
    path.write_text(json.dumps(cfg), encoding="utf-8")


def run_lbf(root: Path, instance: Path, config: Path, out_dir: Path, timeout: int) -> tuple[bool, str, Path, float]:
    if out_dir.exists():
        shutil.rmtree(out_dir)
    out_dir.mkdir(parents=True)
    cmd = [
        "cargo",
        "run",
        "--release",
        "--bin",
        "lbf",
        "--",
        "-i",
        str(instance),
        "-p",
        "spp",
        "-c",
        str(config),
        "-s",
        str(out_dir),
        "-l",
        "warn",
    ]
    start = time.time()
    try:
        proc = subprocess.run(
            cmd,
            cwd=root,
            env=BUILD_ENV,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            timeout=timeout,
            check=False,
        )
    except FileNotFoundError as exc:
        return False, f"missing_executable:{exc.filename}", out_dir / f"sol_{instance.stem}.json", 0.0
    except subprocess.TimeoutExpired:
        return False, "timeout", out_dir / f"sol_{instance.stem}.json", timeout
    runtime = time.time() - start
    if proc.returncode != 0:
        snippet = proc.stdout[-500:].replace("\n", " ")
        return False, f"runtime_error:{snippet}", out_dir / f"sol_{instance.stem}.json", runtime
    sol_path = out_dir / f"sol_{instance.stem}.json"
    if not sol_path.exists():
        return False, "missing_solution_file", sol_path, runtime
    return True, "ok", sol_path, runtime


def build_project(root: Path, timeout: int, refresh_sources: bool = False) -> tuple[bool, str]:
    if refresh_sources:
        touch_proc = subprocess.run(
            ["find", "lbf/src", "jagua-rs/src", "-type", "f", "-exec", "touch", "{}", "+"],
            cwd=root,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            check=False,
        )
        if touch_proc.returncode != 0:
            return False, "source_touch_failed:" + touch_proc.stdout[-500:].replace("\n", " ")
    try:
        proc = subprocess.run(
            ["cargo", "build", "--release", "--bin", "lbf"],
            cwd=root,
            env=BUILD_ENV,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            timeout=timeout,
            check=False,
        )
    except FileNotFoundError as exc:
        return False, f"missing_executable:{exc.filename}"
    except subprocess.TimeoutExpired:
        return False, "build_timeout"
    if proc.returncode != 0:
        return False, "build_failed:" + proc.stdout[-800:].replace("\n", " ")
    return True, "ok"


def improvement_score(improvement: float, case_points: float, args: argparse.Namespace) -> float:
    """Nonlinear quality score.

    The previous linear formula gave substantial credit to shallow heuristics
    that shaved a few percent from many easy cases. The deadband and squared
    progress curve keep small gains visible in logs but make them worth little.
    """
    if improvement <= args.min_improvement:
        return 0.0
    span = max(args.target_improvement - args.min_improvement, EPS)
    progress = min(1.0, (improvement - args.min_improvement) / span)
    return case_points * (progress**args.quality_exponent)


def runtime_multiplier(cand_runtime: float, ref_runtime: float, args: argparse.Namespace) -> float:
    """Penalize broad multi-start strategies that only buy quality with time.

    This task should reward smarter placement/search logic, not simply trying
    many item orders until the per-case timeout is nearly exhausted.
    """
    soft_time = max(args.min_soft_time, args.time_limit * args.soft_time_frac)
    multiplier = 1.0
    if cand_runtime > soft_time:
        multiplier *= (soft_time / max(cand_runtime, EPS)) ** args.runtime_exponent

    runtime_floor = max(ref_runtime, args.min_reference_runtime, EPS)
    slowdown = cand_runtime / runtime_floor
    if slowdown > args.max_slowdown:
        multiplier *= (args.max_slowdown / slowdown) ** args.runtime_exponent

    return max(0.0, min(1.0, multiplier))


def evaluate_case(instance_src: Path, candidate: Path, reference: Path, work: Path, idx: int, args: argparse.Namespace, case_points: float) -> CaseResult:
    case_name = instance_src.stem
    inst_path = work / f"{case_name}.json"
    shutil.copy2(instance_src, inst_path)
    cfg_path = work / f"{case_name}_config.json"
    write_config(cfg_path, seed=10_000 + idx * 17, n_samples=args.samples)

    ref_ok, ref_reason, ref_sol, ref_runtime = run_lbf(reference, inst_path, cfg_path, work / f"ref_{case_name}", args.time_limit)
    if not ref_ok:
        return CaseResult(case_name, "RE", 0.0, f"reference_failed:{ref_reason}")
    ref_valid, ref_v_reason, ref_width = validate_solution(inst_path, ref_sol)
    if not ref_valid:
        return CaseResult(case_name, "RE", 0.0, f"reference_invalid:{ref_v_reason}")

    cand_ok, cand_reason, cand_sol, cand_runtime = run_lbf(candidate, inst_path, cfg_path, work / f"cand_{case_name}", args.time_limit)
    if not cand_ok:
        status = "TLE" if cand_reason == "timeout" else "RE"
        return CaseResult(case_name, status, 0.0, cand_reason, ref_width=ref_width, cand_runtime=cand_runtime)
    cand_valid, cand_v_reason, cand_width = validate_solution(inst_path, cand_sol)
    if not cand_valid:
        return CaseResult(case_name, "WA", 0.0, cand_v_reason, ref_width=ref_width, cand_runtime=cand_runtime)

    improvement = max(0.0, (ref_width - cand_width) / max(ref_width, EPS))
    raw = improvement_score(improvement, case_points, args)
    rt_mult = runtime_multiplier(cand_runtime, ref_runtime, args)
    score = raw * rt_mult
    status = "OK" if score > 1e-9 else "WA"
    reason = (
        f"ref={ref_width:.4f},cand={cand_width:.4f},impr={improvement:.4%},"
        f"raw={raw:.4f},rt={rt_mult:.3f},time={cand_runtime:.2f}s,ref_time={ref_runtime:.2f}s"
    )
    return CaseResult(case_name, status, score, reason, ref_width, cand_width, cand_runtime)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--candidate", default=os.getcwd())
    parser.add_argument("--reference", default="/home/workspace/jagua-rs-ref")
    parser.add_argument("--cases", type=int, default=16)
    parser.add_argument("--case-list", default=",".join(HIDDEN_CASE_FILES))
    parser.add_argument("--samples", type=int, default=900)
    parser.add_argument("--time-limit", type=int, default=20)
    parser.add_argument("--build-timeout", type=int, default=180)
    parser.add_argument("--case-points", type=float, default=0.0)
    parser.add_argument("--min-improvement", type=float, default=0.025)
    parser.add_argument("--target-improvement", type=float, default=0.18)
    parser.add_argument("--quality-exponent", type=float, default=2.0)
    parser.add_argument("--soft-time-frac", type=float, default=0.40)
    parser.add_argument("--min-soft-time", type=float, default=2.0)
    parser.add_argument("--max-slowdown", type=float, default=5.0)
    parser.add_argument("--min-reference-runtime", type=float, default=0.15)
    parser.add_argument("--runtime-exponent", type=float, default=1.25)
    args = parser.parse_args()

    candidate = Path(args.candidate).resolve()
    reference = Path(args.reference).resolve()

    cand_build, cand_msg = build_project(candidate, args.build_timeout, refresh_sources=True)
    if not cand_build:
        print(f"CASE build CE score=0 reason={cand_msg}")
        print("TOTAL_SCORE 0.000000")
        return 0

    ref_build, ref_msg = build_project(reference, args.build_timeout)
    if not ref_build:
        print(f"CASE reference CE score=0 reason={ref_msg}")
        print("TOTAL_SCORE 0.000000")
        return 0

    try:
        case_paths = load_case_paths(reference, args)
    except FileNotFoundError as exc:
        print(f"CASE assets CE score=0 reason={exc}")
        print("TOTAL_SCORE 0.000000")
        return 0

    case_points = args.case_points if args.case_points > 0 else 100.0 / max(len(case_paths), 1)
    total = 0.0
    with tempfile.TemporaryDirectory(prefix="jagua_eval_") as td:
        work = Path(td)
        for idx, case_path in enumerate(case_paths):
            res = evaluate_case(case_path, candidate, reference, work, idx, args, case_points)
            total += res.score
            print(f"CASE {idx:04d} {res.status} score={res.score:.6f} reason={res.reason}")
            sys.stdout.flush()

    print(f"TOTAL_SCORE {total:.6f}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

