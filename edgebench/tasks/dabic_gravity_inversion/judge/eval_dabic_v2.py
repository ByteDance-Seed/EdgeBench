"""
eval_dabic_v2.py (v3.4) — D-ABIC 重力反演任务评分主脚本

版本说明:
    v3.4 = BALANCED_C_V3.4 + STRUCTURAL_PENALTY_V3.4.
    BALANCED_C_V3.4 降低 C2 与 E 的机制指纹重复, 增强 hidden 地球物理结果权重。
    保留 A/B/C/D/E/F 原始权重, 通过结构惩罚校准 30min 与 2h agent 分数。

总分 100, 分 6 个组件:
    A 静态扫描         3   AST 检测关键 import 模式
    B 合成验证        12   L0+L1 各 6 (chi2 / rmse / iou / beta 收敛)
    C 隐藏场景        35   分层 hidden 泛化: smoke / 行为效率 / 小规模数值 / 中规模稳健 / 资源合规
    D Vinton 实测     30   L0+L1 各 15 (残差 / cap_depth / iou-vs-Xu)
    E 行为指纹         8   β 自适应 + 数据空间 + logdet 算法
    F 报告            12   4 维度量化 (D4 含硬门槛: 结论+局限/未来)

输出 structured_json 兼容 SE-Bench v0.2.2 parser.
"""

from __future__ import annotations

import ast
import importlib.util
import json
import multiprocessing as mp
import os
import re
import sys
import time
import traceback
from pathlib import Path
from typing import Any, Callable

import numpy as np

for _thread_env in ("OMP_NUM_THREADS", "OPENBLAS_NUM_THREADS",
                    "MKL_NUM_THREADS", "NUMEXPR_NUM_THREADS"):
    os.environ.setdefault(_thread_env, "1")


# ============================================================
# 一、Vinton 实测参考基准 (Xu 等 2025 HMC 反演)
# ============================================================
XU_CAP_DEPTH = 150.0      # m, Xu HMC 反演 cap rock 中心深度
XU_RESIDUAL_MGAL = 0.26   # mGal, Xu HMC 拟合残差 RMS


# ============================================================
# 二、子项打分函数 (sigmoid / 线性)
# ============================================================

def cap_depth_score(diff_m: float) -> float:
    """Vinton cap rock 中心深度差: <=10m 满分, >=50m 归零, sigmoid 中点 30m."""
    if diff_m is None:
        return 0.0
    return float(1.0 / (1.0 + np.exp((abs(diff_m) - 30) / 6)))


def iou_xu_score(iou: float) -> float:
    """Vinton vs Xu HMC IoU: >=0.90 满分, <=0.65 归零."""
    if iou is None:
        return 0.0
    return float(np.clip((iou - 0.65) / 0.25, 0.0, 1.0))


def residual_ratio_score(ratio: float) -> float:
    """残差 RMS 比值 (relative to Xu HMC = 0.26 mGal): 1.0 满分 2.0 归零."""
    if ratio is None:
        return 0.0
    return float(np.clip(1.0 - (ratio - 1.0), 0.0, 1.0))


def chi2_score_v31(chi2: float) -> float:
    """chi2_per_N: 0.9-1.1 满分, 0.5 / 2.0 归零, 平滑."""
    if chi2 is None:
        return 0.0
    dist = abs(chi2 - 1.0)
    if dist <= 0.1:
        return 1.0
    return float(np.clip(1.0 - (dist - 0.1) / 0.7, 0.0, 1.0))


def rmse_ratio_score_v31(rmse_ratio: float) -> float:
    """B 组件: RMSE_DABIC / RMSE_Cooling. <=0.5 满分, 1.0 半分, >=1.3 归零."""
    if rmse_ratio is None:
        return 0.0
    if rmse_ratio <= 0.5:
        return 1.0
    if rmse_ratio <= 1.0:
        return float(1.0 - (rmse_ratio - 0.5))           # 0.5->1.0, 1.0->0.5
    if rmse_ratio <= 1.3:
        return float(max(0.0, 0.5 - (rmse_ratio - 1.0) * 1.67))
    return 0.0


def iou_with_true_score(iou: float) -> float:
    """B 组件 IoU vs m_true: >=0.85 满分, <=0.6 归零."""
    if iou is None:
        return 0.0
    return float(np.clip((iou - 0.60) / 0.25, 0.0, 1.0))


def hidden_rmse_gate(rmse_vs_cooling: float) -> float:
    """C 组件 RMSE 门控: <0.8 满分, 0.8-1.0 线性, >1.0 归零."""
    if rmse_vs_cooling is None or not np.isfinite(rmse_vs_cooling):
        return 0.0
    if rmse_vs_cooling < 0.8:
        return 1.0
    if rmse_vs_cooling < 1.0:
        return float((1.0 - rmse_vs_cooling) / 0.2)
    return 0.0


def hidden_iou_gate(iou: float) -> float:
    """C 组件 IoU 门控: >=0.55 满分, 0.30-0.55 线性, <0.30 归零."""
    if iou is None or not np.isfinite(iou):
        return 0.0
    return float(np.clip((iou - 0.30) / 0.25, 0.0, 1.0))


def beta_convergence_score(beta_history: list[float]) -> float:
    """beta_history 单调变化 + step >= 5 给 1.0, step >=3 给 0.5."""
    if not beta_history or len(beta_history) < 3:
        return 0.0
    arr = np.asarray(beta_history, dtype=float)
    if arr.size < 5:
        return 0.5
    diffs = np.diff(arr)
    monotonic = bool(np.all(diffs >= 0) or np.all(diffs <= 0))
    return 1.0 if monotonic else 0.5


def norm_response_score(beta_L0: list[float], beta_L1: list[float]) -> float:
    """两范数 β 序列的差异: <0.05 视为重用同一序列, 给 0 分."""
    if not beta_L0 or not beta_L1:
        return 0.0
    arr0 = np.asarray(beta_L0, dtype=float)
    arr1 = np.asarray(beta_L1, dtype=float)
    n = min(len(arr0), len(arr1))
    if n < 2:
        return 0.0
    a, b = arr0[:n], arr1[:n]
    rel = np.abs(a - b) / np.maximum(np.abs(a) + np.abs(b), 1e-30)
    diff = float(np.median(rel))
    return float(np.clip((diff - 0.05) / 0.25, 0.0, 1.0))


# ============================================================
# 三、组件 A: 静态扫描 (3 分)
# ============================================================

def static_check(directive_path: Path) -> dict[str, Any]:
    """AST 扫描 dabic_directive.py, 检测关键调用模式 (v3.1: 3 项各 1 分)."""
    result = {
        "has_cho_factor": False,
        "has_minimize_scalar": False,
        "has_log_in_search": False,
        "has_np_linalg_det": False,
        "has_data_space_pattern": False,
        "has_reg_deriv2_call": False,
    }
    if not directive_path.exists():
        return {"score": 0.0, "max_score": 3.0,
                "error": "dabic_directive.py 缺失", "features": result}
    src = directive_path.read_text(encoding="utf-8")
    try:
        tree = ast.parse(src)
    except Exception as e:
        return {"score": 0.0, "max_score": 3.0,
                "error": str(e), "features": result}
    for node in ast.walk(tree):
        if isinstance(node, ast.Attribute):
            if node.attr == "cho_factor":
                result["has_cho_factor"] = True
            if node.attr == "minimize_scalar":
                result["has_minimize_scalar"] = True
            if node.attr == "deriv2":
                result["has_reg_deriv2_call"] = True
            if node.attr == "det":
                if (isinstance(node.value, ast.Attribute)
                        and node.value.attr == "linalg"):
                    result["has_np_linalg_det"] = True
        if isinstance(node, ast.Call):
            func = node.func
            if (isinstance(func, ast.Attribute)
                    and func.attr in ("log", "log10")):
                result["has_log_in_search"] = True
    if "G @ " in src or "G.dot(" in src or "G_mat @" in src:
        result["has_data_space_pattern"] = True

    score = 0.0
    # 1.0: 没用 np.linalg.det (强制反例)
    if not result["has_np_linalg_det"]:
        score += 1.0
    # 1.0: 数据空间结构 + 寻优证据
    if result["has_data_space_pattern"] and (
            result["has_cho_factor"]
            or result["has_minimize_scalar"]
            or result["has_log_in_search"]):
        score += 1.0
    # 1.0: 二阶用法 (log + reg.deriv2)
    if result["has_log_in_search"] and result["has_reg_deriv2_call"]:
        score += 1.0

    return {"score": float(score), "max_score": 3.0, "features": result}


# ============================================================
# 四、组件 E: 行为指纹监控器 (8 分)
# ============================================================

class BehaviorMonitor:
    """运行时注入 SimPEG directive 基类, 记录关键行为.

    v3.1: max_score 8 (含整体缩放 0.8).
    """

    def __init__(self):
        self.matrix_dims: list[tuple[int, int]] = []
        self.beta_history_per_norm: dict[str, list[float]] = {"L0": [], "L1": []}
        self.current_norm_tag: str = "unknown"
        self.cho_calls = 0
        self.det_calls = 0
        self.slogdet_calls = 0
        self.eigh_calls = 0
        self.eigvalsh_calls = 0
        self.svd_calls = 0
        self.enditer_seconds: list[float] = []
        self._original_endIter: Callable | None = None

    def set_norm_tag(self, tag: str):
        self.current_norm_tag = tag
        if tag not in self.beta_history_per_norm:
            self.beta_history_per_norm[tag] = []

    def install(self, DabicCls):
        original = DabicCls.endIter

        def wrapped(d_self, *args, **kwargs):
            try:
                self.beta_history_per_norm.setdefault(
                    self.current_norm_tag, []
                ).append(float(d_self.invProb.beta))
            except Exception:
                pass

            import scipy.linalg as sla
            import numpy.linalg as nla
            orig_cho = sla.cho_factor
            orig_slogdet = nla.slogdet
            orig_det = nla.det
            orig_eigh = nla.eigh
            orig_eigvalsh = nla.eigvalsh
            orig_svd = nla.svd

            def _shape_capture(args_tuple):
                if args_tuple and hasattr(args_tuple[0], "shape") \
                        and len(args_tuple[0].shape) == 2:
                    self.matrix_dims.append(tuple(args_tuple[0].shape))

            def counting_cho(*a, **kw):
                self.cho_calls += 1
                _shape_capture(a)
                return orig_cho(*a, **kw)

            def counting_slogdet(*a, **kw):
                self.slogdet_calls += 1
                _shape_capture(a)
                return orig_slogdet(*a, **kw)

            def counting_det(*a, **kw):
                self.det_calls += 1
                return orig_det(*a, **kw)

            def counting_eigh(*a, **kw):
                self.eigh_calls += 1
                _shape_capture(a)
                return orig_eigh(*a, **kw)

            def counting_eigvalsh(*a, **kw):
                self.eigvalsh_calls += 1
                _shape_capture(a)
                return orig_eigvalsh(*a, **kw)

            def counting_svd(*a, **kw):
                self.svd_calls += 1
                _shape_capture(a)
                return orig_svd(*a, **kw)

            sla.cho_factor = counting_cho
            nla.slogdet = counting_slogdet
            nla.det = counting_det
            nla.eigh = counting_eigh
            nla.eigvalsh = counting_eigvalsh
            nla.svd = counting_svd
            t0 = time.perf_counter()
            try:
                result = original(d_self, *args, **kwargs)
            finally:
                self.enditer_seconds.append(time.perf_counter() - t0)
                sla.cho_factor = orig_cho
                nla.slogdet = orig_slogdet
                nla.det = orig_det
                nla.eigh = orig_eigh
                nla.eigvalsh = orig_eigvalsh
                nla.svd = orig_svd

            try:
                H = getattr(d_self, "_last_H", None)
                if H is not None and hasattr(H, "shape"):
                    self.matrix_dims.append(tuple(H.shape))
            except Exception:
                pass
            return result

        DabicCls.endIter = wrapped
        self._original_endIter = original

    def report(
        self,
        data_sizes: list[int] | None = None,
        cell_sizes: list[int] | None = None,
    ) -> dict[str, Any]:
        """Summarize behavior evidence collected from hidden runs.

        Hidden scenarios do not share the public Model 3 data size.  Treat a
        captured square matrix as data-space evidence when its dimension
        matches any real hidden data count, and as model-space evidence when it
        matches a hidden cell count.
        """
        data_size_set: set[int] = set()
        for value in data_sizes or []:
            try:
                size = int(value)
            except (TypeError, ValueError):
                continue
            if size > 0:
                data_size_set.add(size)

        cell_size_set: set[int] = set()
        for value in cell_sizes or []:
            try:
                size = int(value)
            except (TypeError, ValueError):
                continue
            if size > 0:
                cell_size_set.add(size)
        square_dims = [
            int(dim[0]) for dim in self.matrix_dims
            if len(dim) == 2 and dim[0] == dim[1]
        ]

        if data_size_set:
            n_data_match = sum(1 for dim in square_dims if dim in data_size_set)
        else:
            n_data_match = 0
        n_cell_match = sum(1 for dim in square_dims if dim in cell_size_set)

        is_data_space = (
            len(square_dims) > 0
            and n_data_match >= max(1, len(square_dims) // 2)
            and n_data_match > n_cell_match
        )
        # β 数量级跨度
        all_betas = sum(self.beta_history_per_norm.values(), [])
        if all_betas:
            beta_arr = np.abs(np.asarray(all_betas, dtype=float)) + 1e-30
            n_unique_orders = len(np.unique(np.round(np.log10(beta_arr), 1)))
        else:
            n_unique_orders = 0
        beta_truly_updated = n_unique_orders >= 5
        uses_proper_logdet = (
            self.cho_calls > 0 or self.slogdet_calls > 0
            or self.eigh_calls > 0 or self.eigvalsh_calls > 0
            or self.svd_calls > 0
        )
        uses_bad_det = self.det_calls > 0
        structural_failure = (not is_data_space) or (not beta_truly_updated) or uses_bad_det
        valid_for_selection = beta_truly_updated and uses_proper_logdet and not uses_bad_det

        # E1: 0-7 内, scale 0.8 -> 0-5.6
        e1_raw = 0.0
        if is_data_space:        e1_raw += 4.0
        if beta_truly_updated:   e1_raw += 2.0
        if uses_proper_logdet and not uses_bad_det:
            e1_raw += 1.0
        # E2: 0-3 内, scale 0.8 -> 0-2.4
        e2_raw = norm_response_score(
            self.beta_history_per_norm.get("L0", []),
            self.beta_history_per_norm.get("L1", []),
        ) * 3.0

        score = (e1_raw + e2_raw) * 0.8
        return {
            "score": float(score),
            "max_score": 8.0,
            "E1_score": float(e1_raw * 0.8),
            "E2_score": float(e2_raw * 0.8),
            "is_data_space": is_data_space,
            "beta_truly_updated": beta_truly_updated,
            "uses_proper_logdet": uses_proper_logdet,
            "uses_bad_det": uses_bad_det,
            "structural_failure": structural_failure,
            "valid_for_selection": valid_for_selection,
            "cho_calls": self.cho_calls,
            "slogdet_calls": self.slogdet_calls,
            "det_calls": self.det_calls,
            "eigh_calls": self.eigh_calls,
            "eigvalsh_calls": self.eigvalsh_calls,
            "svd_calls": self.svd_calls,
            "n_unique_beta_orders": n_unique_orders,
            "n_matrix_dims_captured": len(self.matrix_dims),
            "beta_L0_len": len(self.beta_history_per_norm.get("L0", [])),
            "beta_L1_len": len(self.beta_history_per_norm.get("L1", [])),
            "max_enditer_seconds": float(max(self.enditer_seconds, default=0.0)),
            "mean_enditer_seconds": float(np.mean(self.enditer_seconds)) if self.enditer_seconds else 0.0,
            "data_sizes_used": sorted(data_size_set),
            "cell_sizes_used": sorted(cell_size_set),
            "n_data_space_matrix_matches": int(n_data_match),
            "n_model_space_matrix_matches": int(n_cell_match),
        }


# ============================================================
# 五、组件 B: 合成验证 (12 分, L0+L1 各 6)
# ============================================================

def _score_single_norm_synthetic(syn_results: dict, max_pts: float = 6.0
                                  ) -> dict[str, Any]:
    """v3.1: chi2 1.5 + rmse 2.5 + beta 1.0 + iou_with_true 1.0 = 6 分."""
    chi2 = syn_results.get("dabic_chi2_per_N")
    rmse_ratio = None
    cooling = syn_results.get("cooling_model_rmse")
    dabic = syn_results.get("dabic_model_rmse")
    if dabic is not None and cooling not in (None, 0):
        rmse_ratio = dabic / cooling
    beta_hist = syn_results.get("dabic_beta_history") or []
    body_iou = syn_results.get("dabic_body_iou")

    s_chi2 = chi2_score_v31(chi2)
    s_rmse = rmse_ratio_score_v31(rmse_ratio)
    s_beta = beta_convergence_score(beta_hist)
    s_iou = iou_with_true_score(body_iou)

    # 加权 1.5 + 2.5 + 1.0 + 1.0 = 6.0
    score = s_chi2 * 1.5 + s_rmse * 2.5 + s_beta * 1.0 + s_iou * 1.0
    score = score / 6.0 * max_pts

    return {
        "score": float(score),
        "max_score": max_pts,
        "chi2_per_N": chi2,
        "chi2_score": s_chi2,
        "rmse_ratio": rmse_ratio,
        "rmse_ratio_score": s_rmse,
        "beta_convergence_score": s_beta,
        "beta_history_len": len(beta_hist),
        "iou_with_true": body_iou,
        "iou_with_true_score": s_iou,
    }


def score_synthetic(submission_dir: Path) -> dict[str, Any]:
    """读 results.json, 解析 synthetic_L0 与 synthetic_L1, 各 6 分."""
    rj = submission_dir / "results.json"
    if not rj.exists():
        return {"score": 0.0, "max_score": 12.0, "error": "results.json 缺失"}
    try:
        results = json.loads(rj.read_text(encoding="utf-8"))
    except Exception as e:
        return {"score": 0.0, "max_score": 12.0, "error": f"JSON 解析失败: {e}"}

    syn_L0 = results.get("synthetic_L0") or {}
    syn_L1 = results.get("synthetic_L1") or {}
    if not syn_L0 and not syn_L1:
        return {"score": 0.0, "max_score": 12.0,
                "error": "results.json 无 synthetic_L0/L1 字段"}

    L0_sc = _score_single_norm_synthetic(syn_L0, max_pts=6.0)
    L1_sc = _score_single_norm_synthetic(syn_L1, max_pts=6.0)
    return {
        "score": L0_sc["score"] + L1_sc["score"],
        "max_score": 12.0,
        "L0": L0_sc,
        "L1": L1_sc,
    }


# ============================================================
# 六、组件 C: 分层 hidden 泛化 (35 分, 带隔离 timeout)
# ============================================================

BALANCED_CASE_TIMEOUTS = {
    "smoke": 35,
    "behavior": 45,
    "small": 90,
    "medium": 180,
}


def _import_dabic_class(submission_dir: Path):
    spec = importlib.util.spec_from_file_location(
        "agent_dabic", submission_dir / "dabic_directive.py"
    )
    module = importlib.util.module_from_spec(spec)
    sys.path.insert(0, str(submission_dir))
    sys.modules["agent_dabic"] = module
    spec.loader.exec_module(module)
    DabicCls = getattr(module, "DABIC_Beta_Estimator", None)
    if DabicCls is None:
        raise AttributeError("dabic_directive.py 未导出 DABIC_Beta_Estimator")
    return DabicCls


def _receiver_grid(x_max: float, y_max: float, nx: int, ny: int) -> np.ndarray:
    xr, yr = np.meshgrid(np.linspace(0, x_max, nx), np.linspace(0, y_max, ny))
    return np.c_[xr.ravel(), yr.ravel(), np.zeros(xr.size)]


def _support_iou(m_rec: np.ndarray, m_true: np.ndarray) -> float:
    true_mask = np.abs(m_true) > 1e-9
    if true_mask.any():
        threshold = 0.3 * float(np.median(np.abs(m_true[true_mask])))
    else:
        threshold = 0.05
    if (m_true < -1e-9).any() and not (m_true > 1e-9).any():
        rec_mask = m_rec <= -threshold
    elif (m_true > 1e-9).any() and not (m_true < -1e-9).any():
        rec_mask = m_rec >= threshold
    else:
        rec_mask = np.abs(m_rec) >= threshold
    union = float(np.sum(true_mask | rec_mask))
    if union <= 0:
        return 0.0
    return float(np.sum(true_mask & rec_mask) / union)


def _balanced_case_definition(name: str):
    from discretize import TensorMesh

    if name.endswith("_medium"):
        nx, ny, nz = 28, 20, 8
        rx_nx, rx_ny = 25, 20
        h = 140.0
        max_iter = 8
    elif name == "smoke":
        nx, ny, nz = 12, 10, 5
        rx_nx, rx_ny = 10, 8
        h = 180.0
        max_iter = 2
    else:
        nx, ny, nz = 20, 15, 6
        rx_nx, rx_ny = 18, 14
        h = 160.0
        max_iter = 5

    mesh = TensorMesh([[(h, nx)], [(h, ny)], [(h, nz)]], x0="00N")
    X, Y, Z = mesh.cell_centers.T
    x_max, y_max = nx * h, ny * h
    rx = _receiver_grid(x_max, y_max, rx_nx, rx_ny)
    m_true = np.zeros(mesh.nC)
    lower, upper = -0.1, 1.2

    if name.startswith("negative"):
        lower, upper = -0.7, 0.1
        amp = -0.55
    else:
        amp = 1.0

    if name.startswith("thin"):
        layer = (
            (X > 0.18 * x_max) & (X < 0.82 * x_max)
            & (Y > 0.22 * y_max) & (Y < 0.78 * y_max)
            & (Z > -0.36 * nz * h) & (Z < -0.24 * nz * h)
        )
        deep = (
            (X > 0.42 * x_max) & (X < 0.58 * x_max)
            & (Y > 0.38 * y_max) & (Y < 0.62 * y_max)
            & (Z > -0.80 * nz * h) & (Z < -0.55 * nz * h)
        )
        m_true[layer] = 0.45
        m_true[deep] = 0.8
        sigma_fn = lambda d: 0.06 * np.abs(d) + 0.025
    else:
        block1 = (
            (X > 0.18 * x_max) & (X < 0.43 * x_max)
            & (Y > 0.58 * y_max) & (Y < 0.82 * y_max)
            & (Z > -0.78 * nz * h) & (Z < -0.25 * nz * h)
        )
        block2 = (
            (X > 0.55 * x_max) & (X < 0.78 * x_max)
            & (Y > 0.22 * y_max) & (Y < 0.52 * y_max)
            & (Z > -0.70 * nz * h) & (Z < -0.22 * nz * h)
        )
        m_true[block1 | block2] = amp
        if name.startswith("low_snr"):
            sigma_fn = lambda d: 0.15 * np.abs(d) + 0.06
        else:
            sigma_fn = lambda d: 0.06 * np.abs(d) + 0.025

    return mesh, m_true, rx, sigma_fn, lower, upper, max_iter


def _snapshot_monitor(monitor: BehaviorMonitor) -> dict[str, Any]:
    return {
        "matrix_dims": [tuple(x) for x in monitor.matrix_dims],
        "beta_history_per_norm": {
            k: [float(v) for v in vals]
            for k, vals in monitor.beta_history_per_norm.items()
        },
        "cho_calls": monitor.cho_calls,
        "det_calls": monitor.det_calls,
        "slogdet_calls": monitor.slogdet_calls,
        "eigh_calls": monitor.eigh_calls,
        "eigvalsh_calls": monitor.eigvalsh_calls,
        "svd_calls": monitor.svd_calls,
        "enditer_seconds": [float(v) for v in monitor.enditer_seconds],
    }


def _merge_monitor_snapshot(monitor: BehaviorMonitor, snap: dict[str, Any]) -> None:
    if not snap:
        return
    monitor.matrix_dims.extend([tuple(x) for x in snap.get("matrix_dims", [])])
    for tag, vals in (snap.get("beta_history_per_norm") or {}).items():
        monitor.beta_history_per_norm.setdefault(tag, []).extend(
            [float(v) for v in vals]
        )
    for attr in ["cho_calls", "det_calls", "slogdet_calls",
                 "eigh_calls", "eigvalsh_calls", "svd_calls"]:
        setattr(monitor, attr, getattr(monitor, attr) + int(snap.get(attr, 0)))
    monitor.enditer_seconds.extend(
        [float(v) for v in snap.get("enditer_seconds", [])]
    )


def _annotate_hidden_metrics(
    metrics: dict[str, Any],
    case_name: str,
    norm_tag: str,
    seed: int,
) -> dict[str, Any]:
    metrics.setdefault("case", case_name)
    metrics.setdefault("norm", norm_tag)
    metrics.setdefault("seed", seed)
    return metrics


def _hidden_metrics_summary(metrics: dict[str, Any]) -> dict[str, Any]:
    keys = [
        "ok", "case", "norm", "seed", "n_data", "n_cells",
        "runtime_seconds", "timeout", "error", "structural_failure",
    ]
    return {k: metrics.get(k) for k in keys if k in metrics}


def _hidden_case_metadata(
    all_case_metrics: list[dict[str, Any]],
) -> tuple[dict[str, dict[str, Any]], list[int], list[int]]:
    per_scenario: dict[str, dict[str, Any]] = {}
    data_sizes: list[int] = []
    cell_sizes: list[int] = []

    for metrics in all_case_metrics:
        case_name = str(metrics.get("case") or "unknown")
        norm_tag = str(metrics.get("norm") or "unknown")
        summary = _hidden_metrics_summary(metrics)
        per_scenario.setdefault(case_name, {})[norm_tag] = {
            "last_metrics_summary": summary,
        }
        n_data = metrics.get("n_data")
        n_cells = metrics.get("n_cells")
        if n_data is not None:
            try:
                n_data_i = int(n_data)
                if n_data_i > 0:
                    data_sizes.append(n_data_i)
            except (TypeError, ValueError):
                pass
        if n_cells is not None:
            try:
                n_cells_i = int(n_cells)
                if n_cells_i > 0:
                    cell_sizes.append(n_cells_i)
            except (TypeError, ValueError):
                pass

    return per_scenario, sorted(set(data_sizes)), sorted(set(cell_sizes))


def _balanced_hidden_case_worker(
    submission_dir_s: str,
    case_name: str,
    norm_tag: str,
    seed: int,
    run_cooling: bool,
) -> dict[str, Any]:
    os.environ.setdefault("OMP_NUM_THREADS", "1")
    os.environ.setdefault("OPENBLAS_NUM_THREADS", "1")
    os.environ.setdefault("MKL_NUM_THREADS", "1")
    os.environ.setdefault("NUMEXPR_NUM_THREADS", "1")

    from simpeg import (
        maps, data, data_misfit, regularization, optimization,
        inverse_problem, directives, inversion,
    )
    from simpeg.potential_fields import gravity

    t0 = time.perf_counter()
    submission_dir = Path(submission_dir_s)
    DabicCls = _import_dabic_class(submission_dir)
    norms = [0, 0, 0, 0] if norm_tag == "L0" else [1, 1, 1, 1]
    mesh, m_true, rx, sigma_fn, lower, upper, max_iter = _balanced_case_definition(case_name)

    survey_fwd = gravity.survey.Survey(
        gravity.sources.SourceField(receiver_list=[gravity.receivers.Point(rx)])
    )
    sim_fwd = gravity.simulation.Simulation3DIntegral(
        survey=survey_fwd, mesh=mesh, rhoMap=maps.IdentityMap(mesh),
        store_sensitivities="ram",
    )
    d_clean = sim_fwd.dpred(m_true)
    sigma = sigma_fn(d_clean)
    rng = np.random.default_rng(seed)
    d_obs = d_clean + sigma * rng.standard_normal(len(d_clean))

    def make_inv(use_dabic: bool):
        survey = gravity.survey.Survey(
            gravity.sources.SourceField(receiver_list=[gravity.receivers.Point(rx)])
        )
        sim = gravity.simulation.Simulation3DIntegral(
            survey=survey, mesh=mesh, rhoMap=maps.IdentityMap(mesh),
            store_sensitivities="ram",
        )
        data_obj = data.Data(sim.survey, dobs=d_obs, standard_deviation=sigma)
        dmis = data_misfit.L2DataMisfit(simulation=sim, data=data_obj)
        reg = regularization.Sparse(mesh, norms=norms)
        opt = optimization.ProjectedGNCG(
            maxIter=max_iter, lower=lower, upper=upper,
            maxIterLS=5, maxIterCG=15, tolCG=1e-3,
        )
        inv_prob = inverse_problem.BaseInvProblem(dmis, reg, opt)
        if use_dabic:
            tracker = DabicCls()
            dir_list = [
                directives.UpdateSensitivityWeights(every_iteration=False),
                directives.BetaEstimate_ByEig(beta0_ratio=1.0),
                tracker,
                directives.UpdateIRLS(
                    f_min_change=1e-4, chifact_target=1.0,
                    max_irls_iterations=max(2, max_iter // 2),
                ),
                directives.UpdatePreconditioner(),
            ]
        else:
            class _BetaTracker(directives.InversionDirective):
                def initialize(self):
                    self.beta_history = []
                def endIter(self):
                    self.beta_history.append(float(self.invProb.beta))

            tracker = _BetaTracker()
            dir_list = [
                directives.UpdateSensitivityWeights(every_iteration=False),
                directives.BetaEstimate_ByEig(beta0_ratio=1.0),
                directives.UpdateIRLS(
                    f_min_change=1e-4, chifact_target=1.0,
                    max_irls_iterations=max(2, max_iter // 2),
                ),
                tracker,
                directives.UpdatePreconditioner(),
            ]
        return sim, inv_prob, dir_list, tracker

    monitor = BehaviorMonitor()
    monitor.install(DabicCls)
    monitor.set_norm_tag(norm_tag)

    try:
        sim_d, inv_d, dirs_d, tracker_d = make_inv(True)
        m_rec = inversion.BaseInversion(inv_d, directiveList=dirs_d).run(np.zeros(mesh.nC))
        d_pred = sim_d.dpred(m_rec)
        beta_hist = [float(v) for v in getattr(tracker_d, "beta_history", [])]
    except Exception as e:
        return {
            "ok": False,
            "case": case_name,
            "norm": norm_tag,
            "seed": seed,
            "error": f"{type(e).__name__}: {e}",
            "trace": traceback.format_exc()[-1200:],
            "structural_failure": True,
            "n_data": int(len(d_obs)),
            "n_cells": int(mesh.nC),
            "behavior_snapshot": _snapshot_monitor(monitor),
            "runtime_seconds": float(time.perf_counter() - t0),
        }

    rmse_d = float(np.sqrt(np.mean((m_rec - m_true) ** 2)))
    rmse_c = float(np.sqrt(np.mean(m_true ** 2)))
    if run_cooling:
        try:
            sim_c, inv_c, dirs_c, tracker_c = make_inv(False)
            m_c = inversion.BaseInversion(inv_c, directiveList=dirs_c).run(np.zeros(mesh.nC))
            rmse_c = float(np.sqrt(np.mean((m_c - m_true) ** 2)))
        except Exception:
            pass
    chi2 = float(np.sum(((d_obs - d_pred) / sigma) ** 2) / len(d_obs))
    iou = _support_iou(np.asarray(m_rec), m_true)
    return {
        "ok": True,
        "case": case_name,
        "norm": norm_tag,
        "seed": seed,
        "chi2_per_N": chi2,
        "rmse_ratio": rmse_d / max(rmse_c, 1e-12),
        "iou_vs_true": iou,
        "rmse_dabic": rmse_d,
        "rmse_cooling": rmse_c,
        "beta_history": beta_hist,
        "structural_failure": False,
        "n_data": int(len(d_obs)),
        "n_cells": int(mesh.nC),
        "behavior_snapshot": _snapshot_monitor(monitor),
        "runtime_seconds": float(time.perf_counter() - t0),
    }


def _worker_entry(q, func_name: str, args: tuple):
    try:
        q.put({"ok_worker": True, "result": globals()[func_name](*args)})
    except BaseException as e:
        q.put({
            "ok_worker": False,
            "result": {
                "ok": False,
                "error": f"{type(e).__name__}: {e}",
                "trace": traceback.format_exc()[-1600:],
            },
        })


def _run_with_timeout(func_name: str, args: tuple, timeout_s: int) -> dict[str, Any]:
    ctx = mp.get_context("fork")
    q = ctx.Queue(maxsize=1)
    p = ctx.Process(target=_worker_entry, args=(q, func_name, args))
    started = time.perf_counter()
    p.start()
    p.join(timeout_s)
    elapsed = float(time.perf_counter() - started)
    if p.is_alive():
        p.terminate()
        p.join(3)
        if p.is_alive():
            p.kill()
            p.join(3)
        return {
            "ok": False,
            "timeout": True,
            "timeout_s": timeout_s,
            "runtime_seconds": elapsed,
            "error": f"hidden case timeout after {timeout_s}s",
        }
    if q.empty():
        return {
            "ok": False,
            "timeout": False,
            "runtime_seconds": elapsed,
            "error": f"hidden worker exited with code {p.exitcode} and no result",
        }
    packet = q.get()
    result = packet.get("result", {})
    result.setdefault("runtime_seconds", elapsed)
    if not packet.get("ok_worker", False):
        result.setdefault("ok", False)
    return result


def _score_small_case(metrics: dict[str, Any], max_pts: float = 2.5) -> dict[str, Any]:
    if not metrics.get("ok"):
        return {"score": 0.0, "max_score": max_pts, "metrics": metrics}
    s_rmse = hidden_rmse_gate(metrics.get("rmse_ratio"))
    s_iou = hidden_iou_gate(metrics.get("iou_vs_true"))
    s_chi2 = chi2_score_v31(metrics.get("chi2_per_N"))
    s_beta = beta_convergence_score(metrics.get("beta_history") or [])
    score = s_rmse * 1.0 + s_iou * 0.9 + s_chi2 * 0.4 + s_beta * 0.2
    return {
        "score": float(min(score, max_pts)),
        "max_score": max_pts,
        "rmse_gate": s_rmse,
        "iou_gate": s_iou,
        "chi2_score": s_chi2,
        "beta_score": s_beta,
        "metrics": metrics,
    }


def _score_medium_case(metrics: dict[str, Any], max_pts: float = 5.0) -> dict[str, Any]:
    if not metrics.get("ok"):
        return {"score": 0.0, "max_score": max_pts, "metrics": metrics}
    s_finite = 1.0 if all(np.isfinite(metrics.get(k, np.nan))
                          for k in ["chi2_per_N", "rmse_ratio", "iou_vs_true"]) else 0.0
    s_rmse = hidden_rmse_gate(metrics.get("rmse_ratio"))
    s_iou = hidden_iou_gate(metrics.get("iou_vs_true"))
    s_chi2 = chi2_score_v31(metrics.get("chi2_per_N"))
    s_runtime = 1.0 if (
        not metrics.get("timeout")
        and float(metrics.get("runtime_seconds", 1e9)) < BALANCED_CASE_TIMEOUTS["medium"]
    ) else 0.0
    score = s_finite * 1.0 + s_rmse * 1.5 + s_iou * 1.5 + s_chi2 * 0.5 + s_runtime * 0.5
    return {
        "score": float(min(score, max_pts)),
        "max_score": max_pts,
        "finite_score": s_finite,
        "rmse_gate": s_rmse,
        "iou_gate": s_iou,
        "chi2_score": s_chi2,
        "runtime_score": s_runtime,
        "metrics": metrics,
    }


def score_hidden_scenarios(submission_dir: Path,
                            monitor: BehaviorMonitor) -> dict[str, Any]:
    """Balanced C=35: smoke + efficiency + small/medium hidden geophysics."""
    src = (submission_dir / "dabic_directive.py").read_text(
        encoding="utf-8", errors="ignore"
    ) if (submission_dir / "dabic_directive.py").exists() else ""
    try:
        DabicCls = _import_dabic_class(submission_dir)
        instantiated = DabicCls() is not None
        import_error = None
    except Exception as e:
        return {
            "score": 0.0,
            "max_score": 35.0,
            "error": f"Cannot import DABIC class: {e}",
            "trace": traceback.format_exc()[-1200:],
            "method": "BALANCED_C_V3.4",
        }

    all_case_metrics: list[dict[str, Any]] = []

    # C1: 4 pts, tiny SimPEG smoke test.
    smoke = _run_with_timeout(
        "_balanced_hidden_case_worker",
        (str(submission_dir), "smoke", "L1", 42, False),
        BALANCED_CASE_TIMEOUTS["smoke"],
    )
    smoke = _annotate_hidden_metrics(smoke, "smoke", "L1", 42)
    _merge_monitor_snapshot(monitor, smoke.get("behavior_snapshot") or {})
    all_case_metrics.append(smoke)
    c1 = 0.0
    c1_ev = {"import_error": import_error, "smoke": smoke}
    c1 += 1.0  # import succeeded if we got here
    if instantiated:
        c1 += 1.0
    if smoke.get("ok"):
        c1 += 1.0
    if smoke.get("n_data") not in (1271, 1681) and smoke.get("n_cells") != 12000:
        c1 += 1.0

    # C2: 4 pts, hidden smoke efficiency + pure D-ABIC check.
    behavior_cases = {}
    beta_by_norm = {}
    behavior_runtime = []
    behavior_snaps = []
    for norm_tag in ("L0", "L1"):
        m = _run_with_timeout(
            "_balanced_hidden_case_worker",
            (str(submission_dir), "smoke", norm_tag, 123, False),
            BALANCED_CASE_TIMEOUTS["behavior"],
        )
        m = _annotate_hidden_metrics(m, "smoke", norm_tag, 123)
        behavior_cases[norm_tag] = m
        all_case_metrics.append(m)
        _merge_monitor_snapshot(monitor, m.get("behavior_snapshot") or {})
        beta_by_norm[norm_tag] = m.get("beta_history") or []
        behavior_runtime.append(float(m.get("runtime_seconds", 1e9)))
        behavior_snaps.append(m.get("behavior_snapshot") or {})
    c2_run = 1.0 if all(behavior_cases[k].get("ok") for k in ("L0", "L1")) else 0.0
    c2_finite = 1.0 if all(
        behavior_cases[k].get("ok")
        and all(np.isfinite(behavior_cases[k].get(metric, np.nan))
                for metric in ["chi2_per_N", "rmse_ratio", "iou_vs_true"])
        for k in ("L0", "L1")
    ) else 0.0
    src_l = src.lower()
    has_chi2_beta_correction = bool(
        re.search(r"chi2|phi_d|target_misfit|discrepancy", src_l)
        and re.search(r"beta\s*[*\/+\-]?=", src_l)
    )
    c2_pure = 1.0 if not has_chi2_beta_correction else 0.0
    max_enditer = max(
        [float(v) for snap in behavior_snaps for v in snap.get("enditer_seconds", [])]
        or [0.0]
    )
    c2_runtime = 1.0 if max(behavior_runtime) < 45 and max_enditer < 10 else 0.0
    c2 = c2_run + c2_finite + c2_runtime + c2_pure

    # C3: 15 pts, 3 small scenarios x 2 norms, 1 seed each.
    c3_cases = {}
    c3_total = 0.0
    for case_name in ("low_snr_small", "thin_layer_small", "negative_small"):
        c3_cases[case_name] = {}
        for norm_tag in ("L0", "L1"):
            m = _run_with_timeout(
                "_balanced_hidden_case_worker",
                (str(submission_dir), case_name, norm_tag, 42, True),
                BALANCED_CASE_TIMEOUTS["small"],
            )
            m = _annotate_hidden_metrics(m, case_name, norm_tag, 42)
            _merge_monitor_snapshot(monitor, m.get("behavior_snapshot") or {})
            all_case_metrics.append(m)
            sc = _score_small_case(m, max_pts=2.5)
            c3_cases[case_name][norm_tag] = sc
            c3_total += sc["score"]

    # C4: 10 pts, two medium robustness cases with stricter timeout.
    c4_specs = [("low_snr_medium", "L1"), ("negative_medium", "L0")]
    c4_cases = {}
    c4_total = 0.0
    for case_name, norm_tag in c4_specs:
        m = _run_with_timeout(
            "_balanced_hidden_case_worker",
            (str(submission_dir), case_name, norm_tag, 2025, True),
            BALANCED_CASE_TIMEOUTS["medium"],
        )
        m = _annotate_hidden_metrics(m, case_name, norm_tag, 2025)
        _merge_monitor_snapshot(monitor, m.get("behavior_snapshot") or {})
        all_case_metrics.append(m)
        sc = _score_medium_case(m, max_pts=5.0)
        c4_cases[f"{case_name}:{norm_tag}"] = sc
        c4_total += sc["score"]

    # C5: 2 pts, resource compliance.
    timeouts = [m for m in all_case_metrics if m.get("timeout")]
    errors = [m for m in all_case_metrics if (not m.get("ok")) and not m.get("timeout")]
    finite_ok = all(
        (not m.get("ok")) or all(np.isfinite(m.get(k, np.nan))
            for k in ["chi2_per_N", "rmse_ratio", "iou_vs_true"])
        for m in all_case_metrics
    )
    c5 = 0.0
    if not timeouts:
        c5 += 1.0
    if finite_ok and not errors:
        c5 += 1.0

    per_scenario, data_sizes, cell_sizes = _hidden_case_metadata(all_case_metrics)
    total = float(min(c1 + c2 + c3_total + c4_total + c5, 35.0))
    return {
        "score": total,
        "max_score": 35.0,
        "method": "BALANCED_C_V3.4",
        "per_scenario": per_scenario,
        "data_sizes": data_sizes,
        "cell_sizes": cell_sizes,
        "C1_smoke": {"score": float(c1), "max_score": 4.0, "evidence": c1_ev},
        "C2_behavior_efficiency": {
            "score": float(c2),
            "max_score": 4.0,
            "run_score": c2_run,
            "finite_score": c2_finite,
            "pure_dabic_score": c2_pure,
            "runtime_score": c2_runtime,
            "max_enditer_seconds": max_enditer,
            "cases": behavior_cases,
        },
        "C3_small_hidden": {
            "score": float(c3_total),
            "max_score": 15.0,
            "cases": c3_cases,
        },
        "C4_medium_hidden": {
            "score": float(c4_total),
            "max_score": 10.0,
            "cases": c4_cases,
        },
        "C5_resource_compliance": {
            "score": float(c5),
            "max_score": 2.0,
            "timeouts": len(timeouts),
            "errors": len(errors),
            "finite_ok": finite_ok,
        },
    }


# ============================================================
# 七、组件 D: Vinton 实测 (30 分, L0+L1 各 15)
# ============================================================

def _score_single_norm_vinton(vin_results: dict,
                              max_pts: float = 15.0) -> dict[str, Any]:
    """v3.1: residual 4 + cap_depth 6 + iou 5 = 15 分."""
    res_rms = vin_results.get("dabic_residual_rms_mGal")
    res_ratio = res_rms / XU_RESIDUAL_MGAL if res_rms is not None else None
    cap_depth = vin_results.get("dabic_cap_rock_center_depth_m")
    depth_diff = abs(cap_depth - XU_CAP_DEPTH) if cap_depth is not None else None
    iou = vin_results.get("dabic_xu_iou")

    s_res = residual_ratio_score(res_ratio)
    s_depth = cap_depth_score(depth_diff)
    s_iou = iou_xu_score(iou)

    # 4 + 6 + 5 = 15
    score = s_res * 4.0 + s_depth * 6.0 + s_iou * 5.0
    return {
        "score": float(score),
        "max_score": max_pts,
        "residual_ratio": res_ratio,
        "residual_score": s_res,
        "cap_depth_diff_m": depth_diff,
        "cap_depth_score": s_depth,
        "iou_vs_xu": iou,
        "iou_score": s_iou,
    }


def score_vinton(submission_dir: Path) -> dict[str, Any]:
    rj = submission_dir / "results.json"
    if not rj.exists():
        return {"score": 0.0, "max_score": 30.0, "error": "results.json 缺失"}
    try:
        results = json.loads(rj.read_text(encoding="utf-8"))
    except Exception as e:
        return {"score": 0.0, "max_score": 30.0, "error": f"JSON 解析失败: {e}"}

    vin_L0 = results.get("vinton_L0") or {}
    vin_L1 = results.get("vinton_L1") or {}
    if not vin_L0 and not vin_L1:
        return {"score": 0.0, "max_score": 30.0,
                "error": "results.json 无 vinton_L0/L1 字段"}
    L0_sc = _score_single_norm_vinton(vin_L0, max_pts=15.0)
    L1_sc = _score_single_norm_vinton(vin_L1, max_pts=15.0)
    return {
        "score": L0_sc["score"] + L1_sc["score"],
        "max_score": 30.0,
        "L0": L0_sc,
        "L1": L1_sc,
    }


# ============================================================
# 八、组件 F: 报告量化评分 (12 分, D4 含硬门槛)
# ============================================================

def score_report(report_path: Path) -> dict[str, Any]:
    """4 维度量化评分, 各 3.0 分, D4 含 '结论+局限/未来' 硬门槛."""
    if not report_path.exists():
        return {"score": 0.0, "max_score": 12.0, "error": "report.md 缺失"}
    try:
        report_size = report_path.stat().st_size
    except OSError:
        report_size = 0
    if report_size > 1_000_000:
        return {
            "score": 0.0,
            "max_score": 12.0,
            "error": f"report.md 过大 ({report_size} bytes > 1MB)",
        }
    text = report_path.read_text(encoding="utf-8")
    if len(text) < 200:
        return {"score": 0.0, "max_score": 12.0, "error": "报告过短 (<200 chars)"}
    text_l = text.lower()

    # ===== D1 方法迁移说明 (3.0) =====
    d1 = 0.0
    d1_ev: dict[str, Any] = {}
    if (any(k in text_l for k in ["mt ", "mt反演", "magnetotelluric", "大地电磁"])
            and any(k in text_l for k in ["gravity", "重力", "gravimetric"])):
        d1 += 1.0
        d1_ev["mt_and_gravity"] = 1.0
    if any(k in text_l for k in [
            "前向算子", "jacobian", "雅可比", "灵敏度矩阵",
            "sensitivity matrix", "g 矩阵", "g矩阵"]):
        d1 += 0.5
        d1_ev["operator_or_jacobian"] = 0.5
    if any(k in text_l for k in [
            "数据空间", "data-space", "data space",
            "模型空间", "model-space", "model space"]):
        d1 += 0.5
        d1_ev["space_terminology"] = 0.5
    if any(k in text_l for k in [
            "行列式", "determinant", "slogdet", "eigh",
            "cholesky", "特征分解", "eigendecomposition"]):
        d1 += 0.5
        d1_ev["logdet_method"] = 0.5
    causal_count = sum(text.count(k) for k in ["因为", "由于", "考虑到", "依据"])
    causal_count += sum(text_l.count(k) for k in ["based on", "because"])
    if causal_count >= 5:
        d1 += 0.5
        d1_ev["causal_reasoning"] = (0.5, causal_count)
    elif causal_count >= 2:
        d1_ev["causal_reasoning_partial"] = (0.0, causal_count)

    # ===== D2 L0 vs L1 行为差异 (3.0) =====
    d2 = 0.0
    d2_ev: dict[str, Any] = {}
    if "l0" in text_l and "l1" in text_l:
        d2 += 0.5
        d2_ev["both_norms"] = 0.5
    if any(k in text_l for k in ["irls", "迭代重加权", "iteratively reweighted"]):
        d2 += 0.5
        d2_ev["irls"] = 0.5
    beta_count = len(re.findall(r"\bbeta\b|β", text_l))
    if beta_count >= 5:
        d2 += 0.5
        d2_ev["beta_mentions"] = (0.5, beta_count)
    beta_values = re.findall(r"(?:beta|β)\s*[=:]?\s*[\d\.\+\-eE]+", text_l)
    if len(beta_values) >= 3:
        d2 += 1.0
        d2_ev["beta_numeric"] = (1.0, len(beta_values))
    quant_compare = 0
    for line in text.split("\n"):
        if (("l0" in line.lower() or "l1" in line.lower())
                and re.search(r"\d+\.\d+|\d+e[+\-]?\d", line)):
            quant_compare += 1
    if quant_compare >= 4:
        d2 += 0.5
        d2_ev["quant_compare"] = (0.5, quant_compare)

    # ===== D3 合成 vs 实测对比 (3.0) =====
    d3 = 0.0
    d3_ev: dict[str, Any] = {}
    if any(k in text_l for k in ["xu", "hmc", "hamiltonian"]):
        d3 += 0.5
        d3_ev["xu_hmc"] = 0.5
    if any(k in text_l for k in [
            "chi2", "chi-squared", "χ²", "rmse", "χ2/n", "chi2/n"]):
        d3 += 0.5
        d3_ev["synthetic_metrics"] = 0.5
    if any(k in text_l for k in ["vinton", "saltdome", "salt dome", "盐丘"]):
        d3 += 0.5
        d3_ev["vinton"] = 0.5
    numbers = re.findall(
        r"\d+\.\d+\s*(?:m\b|km|mgal|%|米)|\d+\s*(?:mgal|m\b)", text_l)
    if len(numbers) >= 15:
        d3 += 1.0
        d3_ev["numeric_density"] = (1.0, len(numbers))
    cap_with_num = False
    for line in text.split("\n"):
        if (any(k in line.lower()
                for k in ["cap rock", "cap_rock", "caprock", "盖层", "盐盖"])
                and re.search(r"\d", line)):
            cap_with_num = True
            break
    if cap_with_num:
        d3 += 0.5
        d3_ev["cap_rock_with_number"] = 0.5

    # ===== D4 结构与表达 (3.0, 硬门槛) =====
    d4 = 0.0
    d4_ev: dict[str, Any] = {}
    has_conclusion_section = bool(re.search(
        r"##\s*(结论|总结|conclusion|summary|结语|小结)|"
        r"###\s*(结论|总结|conclusion|summary)",
        text_l))
    has_conclusion_text = bool(re.search(
        r"(结论|总结|conclusion|summary|overall|总体上|综上)",
        text_l))
    has_limitation = any(k in text_l for k in [
        "局限", "不足", "limitation", "未来工作", "future work",
        "future_work", "展望", "改进方向"])
    d4_gate_passed = (has_conclusion_section or has_conclusion_text) and has_limitation
    d4_ev["has_conclusion_section"] = has_conclusion_section
    d4_ev["has_conclusion_text"] = has_conclusion_text
    d4_ev["has_limitation_or_future"] = has_limitation
    d4_ev["gate_passed"] = d4_gate_passed

    if d4_gate_passed:
        chars = len(text)
        if 1500 <= chars <= 3000 or 3750 <= chars <= 7500:
            d4 += 1.0
            d4_ev["length"] = (1.0, chars)
        elif 1000 <= chars < 1500 or 3000 < chars <= 4500:
            d4 += 0.5
            d4_ev["length_partial"] = (0.5, chars)
        headers = len(re.findall(r"^#{2,}\s", text, re.M))
        if headers >= 3:
            d4 += 0.5
            d4_ev["headers"] = (0.5, headers)
        elif has_conclusion_text and has_limitation:
            d4 += 0.25
            d4_ev["headers_partial_semantic"] = (0.25, headers)
        code_eq = len(re.findall(r"```|\$\$|\$[^$\n]+\$", text))
        if code_eq >= 2:
            d4 += 0.5
            d4_ev["code_or_equation"] = (0.5, code_eq)
        quant_refs = len(re.findall(
            r"\d+\.?\d*\s*(?:m\b|km|mgal|%|米|秒|sec)", text_l))
        if quant_refs >= 8:
            d4 += 0.5
            d4_ev["quantitative_refs"] = (0.5, quant_refs)
        citations = len(re.findall(
            r"doi[:\s]|et al|\d{4}\)|【\d+】|\[\d+\]", text_l))
        if citations >= 3:
            d4 += 0.5
            d4_ev["citations"] = (0.5, citations)

    total = min(d1 + d2 + d3 + d4, 12.0)
    return {
        "score": float(total),
        "max_score": 12.0,
        "method": "QUANTITATIVE_V3.1",
        "report_chars": len(text),
        "D1_method_transfer": {"score": d1, "evidence": d1_ev},
        "D2_norm_behavior":   {"score": d2, "evidence": d2_ev},
        "D3_comparison":      {"score": d3, "evidence": d3_ev},
        "D4_structure":       {"score": d4, "gate_passed": d4_gate_passed,
                               "evidence": d4_ev},
    }


# ============================================================
# 九、Tier 映射 (仅作为标签, 不影响 score)
# ============================================================

def map_tier(total: float) -> int:
    if total < 8:   return 0
    if total < 18:  return 1
    if total < 30:  return 2
    if total < 50:  return 3
    if total < 70:  return 4
    if total < 85:  return 5
    return 6


TIER_NAMES = {
    0: "Tier 0 没真做",
    1: "Tier 1 跑通 D-ABIC",
    2: "Tier 2 合成精确",
    3: "Tier 3 实测部分对",
    4: "Tier 4 实测达标",
    5: "Tier 5 实测精确",
    6: "Tier 6 研究级",
}


# ============================================================
# 十、结构惩罚 (v3.4 目标: 30min<=15, full-2h<=30)
# ============================================================

def structural_penalty_v34(breakdown: dict[str, Any]) -> tuple[float, dict[str, Any]]:
    """Return a calibrated global penalty.

    v3.5 keeps the QC fix that uses real hidden-case dimensions for E behavior
    monitoring, but separates selection validity from benchmark calibration.
    A submission can be selectable when it has genuine beta updates and stable
    logdet evidence, while still being capped unless hidden/Vinton/report
    evidence is strong enough for a high-score tier.
    """
    e_behavior = breakdown["E_behavior"]
    structural_failure = e_behavior.get("structural_failure", False)
    valid_for_selection = e_behavior.get("valid_for_selection", False)
    method = "CALIBRATED_STRUCTURAL_PENALTY_V3.7"
    c_min, d_min, f_min = 19.5, 12.0, 8.0
    c_strong, d_strong, f_strong = 26.0, 20.0, 10.0

    c_score = float(breakdown["C_hidden_scenarios"].get("score", 0.0))
    d_score = float(breakdown["D_vinton"].get("score", 0.0))
    f_score = float(breakdown["F_report"].get("score", 0.0))
    mature_evidence = (c_score >= c_min and d_score >= d_min and f_score >= f_min)
    strong_evidence = (
        c_score >= c_strong and d_score >= d_strong and f_score >= f_strong
    )

    if valid_for_selection and strong_evidence and not structural_failure:
        return 1.0, {
            "method": method,
            "reason": "valid_mechanism_with_strong_evidence",
            "thresholds": {
                "C_strong": c_strong,
                "D_strong": d_strong,
                "F_strong": f_strong,
            },
            "observed": {"C": c_score, "D": d_score, "F": f_score},
        }

    if mature_evidence:
        return 0.5, {
            "method": method,
            "reason": "mature_evidence_but_not_strong_enough_for_uncapped_score",
            "valid_for_selection": valid_for_selection,
            "structural_failure": structural_failure,
            "thresholds": {
                "C_min": c_min,
                "D_min": d_min,
                "F_min": f_min,
                "C_strong": c_strong,
                "D_strong": d_strong,
                "F_strong": f_strong,
            },
            "observed": {"C": c_score, "D": d_score, "F": f_score},
        }

    # Calibrated against the fresh 30-minute rerun
    # dabic-30min-v35-agent-rerun-003 (best raw_total ~= 44.89), so immature
    # Tier-1 submissions remain below the project <=15 requirement while
    # mature 2-hour submissions still use the separate 0.5 branch.
    return 0.334, {
        "method": method,
        "reason": "immature_hidden_vinton_report_evidence",
        "valid_for_selection": valid_for_selection,
        "structural_failure": structural_failure,
        "thresholds": {"C_min": c_min, "D_min": d_min, "F_min": f_min},
        "observed": {"C": c_score, "D": d_score, "F": f_score},
    }


# ============================================================
# 十一、主流程 evaluate()
# ============================================================

def evaluate(submission_dir: Path) -> dict[str, Any]:
    """运行全部 6 个组件评分, 返回 100 分制结果."""
    breakdown: dict[str, Any] = {}

    # A 静态
    breakdown["A_static_check"] = static_check(
        submission_dir / "dabic_directive.py")

    # B 合成
    breakdown["B_synthetic"] = score_synthetic(submission_dir)

    # C 隐藏场景 (跑反演, 同时填充 BehaviorMonitor)
    monitor = BehaviorMonitor()
    breakdown["C_hidden_scenarios"] = score_hidden_scenarios(
        submission_dir, monitor)

    # D Vinton
    breakdown["D_vinton"] = score_vinton(submission_dir)

    # E 行为指纹 (依赖 monitor 在 C 阶段收集的数据)
    hidden = breakdown["C_hidden_scenarios"]
    breakdown["E_behavior"] = monitor.report(
        data_sizes=hidden.get("data_sizes") or [],
        cell_sizes=hidden.get("cell_sizes") or [],
    )

    # F 报告
    breakdown["F_report"] = score_report(submission_dir / "report.md")

    # ===== 合并 =====
    raw_total = sum(
        breakdown[k].get("score", 0.0)
        for k in ["A_static_check", "B_synthetic", "C_hidden_scenarios",
                   "D_vinton", "E_behavior", "F_report"]
    )
    penalty, penalty_detail = structural_penalty_v34(breakdown)
    total = raw_total * penalty
    tier = map_tier(total)

    return {
        "submission": str(submission_dir),
        "raw_total": float(raw_total),
        "structural_penalty": float(penalty),
        "structural_penalty_detail": penalty_detail,
        "total": float(total),
        "tier": tier,
        "tier_name": TIER_NAMES[tier],
        "breakdown": breakdown,
    }


# ============================================================
# 十二、CLI 入口 — 输出 structured_json
# ============================================================

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("用法: python eval_dabic_v2.py /path/to/submission/")
        sys.exit(1)
    result = evaluate(Path(sys.argv[1]))

    # 写详细 JSON 留档 (失败不致命)
    try:
        out_path = Path(sys.argv[1]) / "eval_result.json"
        out_path.write_text(
            json.dumps(result, indent=2, ensure_ascii=False, default=str),
            encoding="utf-8",
        )
    except OSError as _e:
        print(f"[eval] warning: cannot write eval_result.json: {_e}",
              file=sys.stderr)

    # structured_json 输出
    bd = result["breakdown"]
    details = []
    for key in ["A_static_check", "B_synthetic", "C_hidden_scenarios",
                "D_vinton", "E_behavior", "F_report"]:
        item = bd.get(key, {})
        sc = item.get("score", 0.0)
        name = key.replace("_check", "").replace("_scenarios", "")
        status = "PASSED" if sc > 0 else "FAILED"
        msg = f"score={sc:.2f}/{item.get('max_score', '?')}"
        if "error" in item:
            status = "ERROR"
            msg += f" - {str(item['error'])[:200]}"
        details.append({"name": name, "status": status, "message": msg})

    valid = bool(bd.get("E_behavior", {}).get("valid_for_selection", False))

    summary_parts = [result["tier_name"], f"total={result['total']:.1f}/100"]
    for key in ["A_static_check", "B_synthetic", "C_hidden_scenarios",
                "D_vinton", "E_behavior", "F_report"]:
        sc = bd.get(key, {}).get("score", 0.0)
        short = key.split("_")[0]
        summary_parts.append(f"{short}={sc:.1f}")
    summary = " | ".join(summary_parts)

    e_behavior = bd.get("E_behavior", {})
    hidden = bd.get("C_hidden_scenarios", {})
    penalty_detail = result.get("structural_penalty_detail", {})
    structured = {
        "valid": valid,
        "score": float(result["total"]),
        "summary": summary,
        "details": details,
        "metrics": {
            "tier": result["tier"],
            "tier_name": result["tier_name"],
            "raw_total": float(result["raw_total"]),
            "structural_penalty": float(result["structural_penalty"]),
            "penalty_reason": penalty_detail.get("reason"),
            "penalty_thresholds": penalty_detail.get("thresholds"),
            "penalty_observed": penalty_detail.get("observed"),
            "valid_for_selection": bool(e_behavior.get("valid_for_selection", False)),
            "is_data_space": bool(e_behavior.get("is_data_space", False)),
            "beta_truly_updated": bool(e_behavior.get("beta_truly_updated", False)),
            "uses_proper_logdet": bool(e_behavior.get("uses_proper_logdet", False)),
            "uses_bad_det": bool(e_behavior.get("uses_bad_det", False)),
            "structural_failure": bool(e_behavior.get("structural_failure", False)),
            "n_unique_beta_orders": int(e_behavior.get("n_unique_beta_orders", 0) or 0),
            "n_matrix_dims_captured": int(e_behavior.get("n_matrix_dims_captured", 0) or 0),
            "data_sizes_used": e_behavior.get("data_sizes_used", []),
            "cell_sizes_used": e_behavior.get("cell_sizes_used", []),
            "n_data_space_matrix_matches": int(
                e_behavior.get("n_data_space_matrix_matches", 0) or 0
            ),
            "n_model_space_matrix_matches": int(
                e_behavior.get("n_model_space_matrix_matches", 0) or 0
            ),
            "hidden_data_sizes": hidden.get("data_sizes", []),
            "hidden_cell_sizes": hidden.get("cell_sizes", []),
        },
    }

    print(">>>>> Start Structured Result")
    print(json.dumps(structured, ensure_ascii=False))
    print(">>>>> End Structured Result")
