from __future__ import annotations

import ast
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

PASSED = "PASSED"
FAILED = "FAILED"
ERROR = "ERROR"
STRUCTURED_START = ">>>>> Start Structured Result"
STRUCTURED_END = ">>>>> End Structured Result"


def _safe_float(value, default: float = 0.0) -> float:
    try:
        if value is None:
            return default
        return float(value)
    except (TypeError, ValueError):
        return default


def _safe_int(value, default: int = 0) -> int:
    try:
        if value is None:
            return default
        return int(value)
    except (TypeError, ValueError):
        return default


def _clip_message(message: str | None, limit: int = 500) -> str:
    if not message:
        return ""
    text = " ".join(str(message).split())
    return text[:limit]


def _qualified_name(node: ast.AST) -> str | None:
    if isinstance(node, ast.Name):
        return node.id
    if isinstance(node, ast.Attribute):
        base = _qualified_name(node.value)
        return f"{base}.{node.attr}" if base else node.attr
    return None


def _has_gpu_string(node: ast.AST) -> bool:
    for child in ast.walk(node):
        if isinstance(child, ast.Constant) and isinstance(child.value, str):
            value = child.value.lower()
            if any(token in value for token in ("cuda", "mps", "xpu", "rocm", "hip")):
                return True
    return False


def _forbidden_import(name: str) -> bool:
    banned_prefixes = ("cupy", "pycuda", "triton", "jax", "tensorflow")
    if name == "numba.cuda" or name.startswith("numba.cuda."):
        return True
    return any(name == prefix or name.startswith(prefix + ".") for prefix in banned_prefixes)


def _detect_gpu_policy_violation(solution_path: Path) -> str | None:
    try:
        source = solution_path.read_text(encoding="utf-8")
        tree = ast.parse(source, filename=str(solution_path))
    except SyntaxError:
        return None
    except OSError as exc:
        return f"unable to inspect submitted solution for GPU policy: {exc}"

    gpu_device_names: set[str] = set()
    for node in ast.walk(tree):
        if isinstance(node, ast.Assign) and _has_gpu_string(node.value):
            for target in node.targets:
                if isinstance(target, ast.Name):
                    gpu_device_names.add(target.id)
        elif isinstance(node, ast.AnnAssign) and isinstance(node.target, ast.Name) and _has_gpu_string(node.value):
            gpu_device_names.add(node.target.id)

    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            for alias in node.names:
                if _forbidden_import(alias.name):
                    return f"GPU-related package import is forbidden: {alias.name}"
        elif isinstance(node, ast.ImportFrom):
            module = node.module or ""
            names = [f"{module}.{alias.name}" if module else alias.name for alias in node.names]
            if _forbidden_import(module) or any(_forbidden_import(name) for name in names):
                return f"GPU-related package import is forbidden: {module}"
        elif isinstance(node, ast.Attribute):
            qname = _qualified_name(node)
            if qname and (
                ".cuda" in qname
                or qname in {"torch.xpu", "torch.mps", "torch.backends.mps"}
                or qname.endswith(".is_cuda")
            ):
                return f"GPU API usage is forbidden: {qname}"
        elif isinstance(node, ast.Call):
            qname = _qualified_name(node.func)
            if qname and (
                ".cuda" in qname
                or qname in {"torch.set_default_device", "torch.cuda", "torch.xpu", "torch.backends.mps"}
            ):
                return f"GPU API call is forbidden: {qname}"
            if qname and (qname == "torch.device" or qname.endswith(".to")):
                if any(
                    _has_gpu_string(arg)
                    or (isinstance(arg, ast.Name) and arg.id in gpu_device_names)
                    for arg in node.args
                ):
                    return f"GPU device target is forbidden in call: {qname}"
            for keyword in node.keywords:
                if keyword.arg == "device" and (
                    _has_gpu_string(keyword.value)
                    or (isinstance(keyword.value, ast.Name) and keyword.value.id in gpu_device_names)
                ):
                    return f"GPU device target is forbidden in call: {qname or 'unknown'}"
    return None


def _detail(name: str, status: str, message: str, score: float) -> dict:
    return {
        "name": name,
        "status": status,
        "message": _clip_message(message),
        "score": score,
        "weight": 1.0,
    }


def _emit_structured(result: dict) -> None:
    print(STRUCTURED_START)
    print(json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True))
    print(STRUCTURED_END)


def _failure_result(error_note: str | None) -> dict:
    details = [
        _detail("result_payload", ERROR, error_note or "runner.py did not produce a valid result payload", 0.0),
        _detail("full_eval", FAILED, "no result payload", 0.0),
        _detail("prediction_coverage", FAILED, "no result payload", 0.0),
        _detail("solution_score", FAILED, "score unavailable", 0.0),
    ]
    return {
        "valid": False,
        "score": 0.0,
        "pass_rate": 0.0,
        "summary": _clip_message(f"runner failed before producing a valid result payload: {error_note or 'unknown error'}"),
        "details": details,
        "metrics": {},
    }


def _gpu_violation_result(message: str) -> dict:
    return {
        "valid": False,
        "score": 0.0,
        "pass_rate": 0.0,
        "summary": _clip_message(f"hardware policy violation: {message}"),
        "details": [
            _detail("hardware_policy", FAILED, message, 0.0),
            _detail("solution_score", FAILED, "score unavailable", 0.0),
        ],
        "metrics": {},
    }


def _prediction_coverage_ok(payload: dict) -> tuple[bool, str]:
    split_results = payload.get("split_results", [])
    if not isinstance(split_results, list) or not split_results:
        return False, "missing split_results"

    bad_splits: list[str] = []
    for item in split_results:
        counts = item.get("counts", {}) if isinstance(item, dict) else {}
        split_id = counts.get("split_id", item.get("split_id", "?") if isinstance(item, dict) else "?")
        expected = _safe_int(counts.get("num_test_nodes"), -1)
        actual = _safe_int(counts.get("num_predictions"), -2)
        if expected < 0 or actual != expected:
            bad_splits.append(f"split={split_id} predictions={actual} expected={expected}")

    if bad_splits:
        return False, "; ".join(bad_splits[:3])
    return True, f"{len(split_results)} splits fully covered"


def main() -> int:
    base_dir = Path(__file__).resolve().parent
    runner_path = base_dir / "runner.py"
    solution_path = base_dir / "solution" / "solution.py"

    gpu_violation = _detect_gpu_policy_violation(solution_path)
    if gpu_violation is not None:
        _emit_structured(_gpu_violation_result(gpu_violation))
        return 0

    fd, result_path = tempfile.mkstemp(prefix="seb045_eval_", suffix=".json")
    os.close(fd)
    env = os.environ.copy()
    env["SEB_SOLUTION_PATH"] = str(solution_path)
    env["SEB_RESULT_JSON"] = result_path
    env["CUDA_VISIBLE_DEVICES"] = ""
    env["NVIDIA_VISIBLE_DEVICES"] = "none"
    env.pop("QUICK_TEST", None)

    payload = None
    error_note = None
    try:
        completed = subprocess.run(
            [sys.executable, str(runner_path)],
            cwd=base_dir,
            env=env,
            capture_output=True,
            text=True,
            check=False,
        )
        if completed.returncode == 0 and Path(result_path).exists():
            payload = json.loads(Path(result_path).read_text(encoding="utf-8"))
        else:
            tail = (completed.stderr or completed.stdout or "").strip().splitlines()[-5:]
            error_note = " | ".join(tail)[:400] if tail else f"returncode={completed.returncode}"
    except Exception as exc:
        error_note = str(exc)
    finally:
        try:
            os.remove(result_path)
        except OSError:
            pass

    if payload is None:
        _emit_structured(_failure_result(error_note))
        return 0

    dataset = payload.get("dataset", {}) if isinstance(payload, dict) else {}
    runtime = payload.get("runtime", {}) if isinstance(payload, dict) else {}
    metrics = payload.get("metrics", {}) if isinstance(payload, dict) else {}

    num_splits = _safe_int(dataset.get("num_splits_evaluated"))
    quick_test = bool(payload.get("quick_test", True))
    full_eval = (not quick_test) and num_splits == 10
    coverage_ok, coverage_message = _prediction_coverage_ok(payload)

    final_score = _safe_float(metrics.get("final_score"))
    overall_score = _safe_float(metrics.get("overall_score"))
    macro_f1 = _safe_float(metrics.get("macro_f1"))
    micro_f1 = _safe_float(metrics.get("micro_f1"))
    balanced_accuracy = _safe_float(metrics.get("balanced_accuracy"))
    one_minus_ece = _safe_float(metrics.get("one_minus_ece"))
    ece = _safe_float(metrics.get("ece"))
    total_time = _safe_float(runtime.get("avg_total_solution_time_sec"))
    solution_score_ok = "final_score" in metrics

    details = [
        _detail("result_payload", PASSED, "runner.py produced a valid result payload", 1.0),
        _detail(
            "full_eval",
            PASSED if full_eval else FAILED,
            f"quick_test={quick_test} num_splits_evaluated={num_splits}",
            1.0 if full_eval else 0.0,
        ),
        _detail(
            "prediction_coverage",
            PASSED if coverage_ok else FAILED,
            coverage_message,
            1.0 if coverage_ok else 0.0,
        ),
        _detail(
            "solution_score",
            PASSED if solution_score_ok else FAILED,
            f"final_score={final_score:.6f}" if solution_score_ok else "final_score unavailable",
            1.0 if solution_score_ok else 0.0,
        ),
    ]

    passed_checks = sum(1 for item in details if item["status"] == PASSED)
    valid = passed_checks == len(details)
    structured_metrics = {
        "final_score": final_score,
        "overall_score": overall_score,
        "macro_f1": macro_f1,
        "micro_f1": micro_f1,
        "balanced_accuracy": balanced_accuracy,
        "one_minus_ece": one_minus_ece,
        "ece": ece,
        "avg_total_solution_time_sec": total_time,
        "avg_peak_memory_mb": _safe_float(runtime.get("avg_peak_memory_mb")),
        "max_peak_memory_mb": _safe_float(runtime.get("max_peak_memory_mb")),
        "avg_time_penalty": _safe_float(runtime.get("avg_time_penalty")),
        "avg_resource_penalty": _safe_float(runtime.get("avg_resource_penalty")),
        "num_splits_evaluated": num_splits,
        "quick_test": quick_test,
    }

    result = {
        "valid": valid,
        "score": final_score,
        "pass_rate": passed_checks / len(details),
        "summary": (
            f"valid={str(valid).lower()} final_score={final_score:.6f} "
            f"overall_score={overall_score:.6f} macro_f1={macro_f1:.6f} "
            f"micro_f1={micro_f1:.6f} balanced_accuracy={balanced_accuracy:.6f} "
            f"one_minus_ece={one_minus_ece:.6f} avg_time={total_time:.3f}s "
            f"checks={passed_checks}/{len(details)}"
        ),
        "details": details,
        "metrics": structured_metrics,
    }
    _emit_structured(result)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
