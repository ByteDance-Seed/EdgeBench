from __future__ import annotations

import importlib.util
import json
import math
import multiprocessing
import os
import sys
import time
import traceback
import tracemalloc
from concurrent.futures import ProcessPoolExecutor, as_completed
from typing import Any, Dict, List, Tuple

from verifier import evaluate


_AUDIT_ENFORCED = False
_WORKER_CONTEXT: Dict[str, Any] = {}


def _load_module_from_path(module_name: str, module_path: str) -> Any:
    spec = importlib.util.spec_from_file_location(module_name, module_path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Unable to load module spec: {module_path}")

    module = importlib.util.module_from_spec(spec)
    module_dir = os.path.dirname(os.path.abspath(module_path))
    added_to_path = False
    if module_dir not in sys.path:
        sys.path.insert(0, module_dir)
        added_to_path = True

    try:
        spec.loader.exec_module(module)
    except Exception as exc:
        tb = traceback.format_exc()
        raise RuntimeError(f"Failed to import {module_path}: {exc}\n{tb}") from exc
    finally:
        if added_to_path:
            try:
                sys.path.remove(module_dir)
            except ValueError:
                pass
    return module


def _import_solution_module(base_dir: str) -> tuple[Any, str]:
    module_path, source_label = _resolve_solution_candidate(base_dir)
    module = _load_module_from_path("solution_submission", module_path)
    if not hasattr(module, "Solution"):
        raise RuntimeError(f"{source_label} does not define class Solution.")
    return module, source_label


def _solution_candidates(base_dir: str) -> List[Tuple[str, str]]:
    env_solution_path = os.getenv("SEB_SOLUTION_PATH")
    candidates: List[Tuple[str, str]] = []
    if env_solution_path:
        candidates.append((os.path.abspath(env_solution_path), env_solution_path))
    solution_dir = os.path.join(base_dir, "solution")
    candidates.extend(
        [
            (os.path.join(solution_dir, "solution.py"), "solution/solution.py"),
            (os.path.join(base_dir, "solution.py"), "solution.py"),
            (os.path.join(solution_dir, "solution_template.py"), "solution/solution_template.py"),
            (os.path.join(base_dir, "solution_template.py"), "solution_template.py"),
        ]
    )
    return candidates


def _resolve_solution_candidate(base_dir: str) -> Tuple[str, str]:
    candidates = _solution_candidates(base_dir)

    seen: set[str] = set()
    for module_path, source_label in candidates:
        abs_path = os.path.abspath(module_path)
        if abs_path in seen or not os.path.exists(abs_path):
            continue
        seen.add(abs_path)
        return abs_path, source_label

    raise RuntimeError("No valid solution module found.")


def _parse_simple_yaml(path: str) -> Dict[str, Any]:
    root: Dict[str, Any] = {}
    stack: List[Tuple[int, Dict[str, Any]]] = [(-1, root)]

    with open(path, "r", encoding="utf-8") as f:
        for raw in f:
            line = raw.rstrip("\n")
            if not line.strip() or line.lstrip().startswith("#"):
                continue

            indent = len(line) - len(line.lstrip(" "))
            text = line.strip()
            if ":" not in text:
                continue

            key, val = text.split(":", 1)
            key = key.strip()
            val = val.strip()

            while stack and indent <= stack[-1][0]:
                stack.pop()
            parent = stack[-1][1]

            if val == "":
                parent[key] = {}
                stack.append((indent, parent[key]))
            else:
                if val.startswith('"') and val.endswith('"') and len(val) >= 2:
                    parsed: Any = val[1:-1]
                elif val.lower() in {"true", "false"}:
                    parsed = val.lower() == "true"
                else:
                    try:
                        if "." in val:
                            parsed = float(val)
                        else:
                            parsed = int(val)
                    except Exception:
                        parsed = val
                parent[key] = parsed

    return root


def _load_jsonl(path: str) -> List[Dict[str, Any]]:
    rows: List[Dict[str, Any]] = []
    with open(path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                rows.append(json.loads(line))
            except json.JSONDecodeError:
                continue
    return rows


def _load_graph_edges(path: str) -> List[List[int]]:
    edges: List[List[int]] = []
    with open(path, "r", encoding="utf-8") as f:
        header = f.readline().strip()
        if header != "source,target":
            raise ValueError(f"Unexpected graph.csv header: {header}")
        for line in f:
            line = line.strip()
            if not line:
                continue
            src, dst = line.split(",", 1)
            edges.append([int(src), int(dst)])
    return edges


def _load_meta(path: str) -> Dict[str, Any]:
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def _resolve_split_paths(cfg: Dict[str, Any], split_id: int) -> Tuple[str, str, str]:
    dp = cfg.get("data_path", {})
    pattern = dp.get("split_pattern", {})
    train_rel = str(pattern.get("train", "data/squirrel/train_split_{split_id:02d}.jsonl")).format(split_id=split_id)
    valid_rel = str(pattern.get("valid", "data/squirrel/valid_split_{split_id:02d}.jsonl")).format(split_id=split_id)
    test_rel = str(pattern.get("test", "data/squirrel/test_split_{split_id:02d}.jsonl")).format(split_id=split_id)
    return train_rel, valid_rel, test_rel


def _slice_ids(rows: List[Dict[str, Any]], ratio: float) -> List[int]:
    ids = [int(r["node_id"]) for r in rows if "node_id" in r]
    if ratio >= 1.0:
        return ids
    n = max(1, int(len(ids) * ratio)) if ids else 0
    return ids[:n]


def _build_input_data(
    cfg: Dict[str, Any],
    split_id: int,
    nodes_rows: List[Dict[str, Any]],
    graph_edges: List[List[int]],
    meta: Dict[str, Any],
    quick_test: bool,
) -> Tuple[Dict[str, Any], Dict[str, int]]:
    base_dir = os.path.dirname(os.path.abspath(__file__))
    train_rel, valid_rel, test_rel = _resolve_split_paths(cfg, split_id)
    train_rows = _load_jsonl(os.path.join(base_dir, train_rel))
    valid_rows = _load_jsonl(os.path.join(base_dir, valid_rel))
    test_rows = _load_jsonl(os.path.join(base_dir, test_rel))

    q_ratio = float(cfg.get("quick_test_ratio", 0.2)) if quick_test else 1.0
    train_ids = _slice_ids(train_rows, q_ratio)
    valid_ids = _slice_ids(valid_rows, q_ratio)
    test_ids = _slice_ids(test_rows, q_ratio)
    test_id_set = set(test_ids)

    nodes_rows_sanitized: List[Dict[str, Any]] = []
    for row in nodes_rows:
        out = dict(row)
        try:
            nid = int(out.get("node_id"))
        except Exception:
            nid = None
        if nid in test_id_set and "label" in out:
            out["label"] = None
        nodes_rows_sanitized.append(out)

    gt: Dict[str, int] = {}
    for r in test_rows:
        if "node_id" not in r or "label" not in r or r["label"] is None:
            continue
        nid = int(r["node_id"])
        if nid in test_id_set:
            gt[str(nid)] = int(r["label"])

    input_data = {
        "graph": {
            "edges": graph_edges,
            "num_nodes": int(meta.get("num_nodes", len(nodes_rows))),
            "num_edges": int(meta.get("num_edges", len(graph_edges))),
            "is_directed": False,
        },
        "nodes": nodes_rows_sanitized,
        "train_nodes": train_ids,
        "valid_nodes": valid_ids,
        "test_nodes": test_ids,
        "split_id": split_id,
        "dataset_meta": {
            "dataset_name": meta.get("dataset_name", "Squirrel"),
            "num_classes": int(meta.get("num_classes", 5)),
            "feature_dim": int(meta.get("feature_dim", 0)),
            "geom_gcn_preprocess": bool(meta.get("geom_gcn_preprocess", True)),
        },
    }
    return input_data, gt


def _register_audit_hook(data_dir_abs: str) -> None:
    deny_tokens = [
        os.path.normpath(data_dir_abs).lower(),
        "data/",
        "nodes_all.jsonl",
        "graph.csv",
        "train_split_",
        "valid_split_",
        "test_split_",
        "meta.json",
    ]

    def audit(event: str, args: Tuple[Any, ...]) -> None:
        if not _AUDIT_ENFORCED:
            return
        if event not in {"open", "os.open"}:
            return
        if not args:
            return
        try:
            p = str(args[0]).lower()
        except Exception:
            return
        for t in deny_tokens:
            if t and t in p:
                raise PermissionError("Solution cannot access evaluation data files directly.")

    sys.addaudithook(audit)


def _resource_penalty(cfg: Dict[str, Any], peak_memory_mb: float) -> float:
    penalties = cfg.get("penalties", {})
    spec = penalties.get("resource_penalty_spec", {})
    if not isinstance(spec, dict):
        return 0.0
    if spec.get("type") != "peak_memory_linear":
        return 0.0
    coef = float(spec.get("coef", 0.0))
    baseline = float(spec.get("baseline_mb", 0.0))
    excess = max(0.0, peak_memory_mb - baseline)
    return coef * excess


def _overall_score(cfg: Dict[str, Any], metrics: Dict[str, float]) -> float:
    scoring = cfg.get("scoring", {})
    weights = scoring.get("weights", {})
    w_macro = float(weights.get("macro_f1", 0.4))
    w_micro = float(weights.get("micro_f1", 0.3))
    w_bal = float(weights.get("balanced_accuracy", 0.2))
    w_om_ece = float(weights.get("one_minus_ece", 0.1))
    return (
        w_macro * float(metrics.get("macro_f1", 0.0))
        + w_micro * float(metrics.get("micro_f1", 0.0))
        + w_bal * float(metrics.get("balanced_accuracy", 0.0))
        + w_om_ece * float(metrics.get("one_minus_ece", 0.0))
    )


def _aggregate_metric(items: List[Dict[str, Any]], key: str) -> float:
    if not items:
        return 0.0
    return float(sum(float(item.get(key, 0.0)) for item in items) / float(len(items)))


def _parse_int_env(name: str, default: int) -> int:
    raw = os.getenv(name)
    if raw is None or not raw.strip():
        return default
    try:
        return int(raw)
    except ValueError:
        return default


def _cap_worker_threads() -> None:
    # Split-level parallelism is the intended concurrency. Cap BLAS/Torch
    # internal pools to avoid oversubscribing the judge CPU quota.
    for name in ("OMP_NUM_THREADS", "MKL_NUM_THREADS", "OPENBLAS_NUM_THREADS", "NUMEXPR_NUM_THREADS"):
        os.environ.setdefault(name, "1")
    try:
        import torch  # type: ignore

        torch.set_num_threads(int(os.environ.get("TORCH_NUM_THREADS", "1")))
        if hasattr(torch, "set_num_interop_threads"):
            torch.set_num_interop_threads(int(os.environ.get("TORCH_NUM_INTEROP_THREADS", "1")))
    except Exception:
        pass


def _init_split_worker(context: Dict[str, Any] | None = None) -> None:
    global _WORKER_CONTEXT
    if context is not None:
        _WORKER_CONTEXT = context
    _cap_worker_threads()
    _register_audit_hook(_WORKER_CONTEXT["data_dir_abs"])


def _evaluate_one_split(split_id: int) -> Dict[str, Any]:
    context = _WORKER_CONTEXT
    cfg = context["cfg"]
    nodes_rows = context["nodes_rows"]
    graph_edges = context["graph_edges"]
    meta = context["meta"]
    quick_test = bool(context["quick_test"])
    base_dir = context["base_dir"]

    sol_mod, _ = _import_solution_module(base_dir)
    solver_cls = getattr(sol_mod, "Solution")

    input_data, ground_truth = _build_input_data(cfg, split_id, nodes_rows, graph_edges, meta, quick_test)
    solver = solver_cls()

    global _AUDIT_ENFORCED
    tracemalloc.start()
    start = time.perf_counter()
    _AUDIT_ENFORCED = True
    try:
        result = solver.solve(input_data)
    finally:
        _AUDIT_ENFORCED = False
    total_solution_time_sec = time.perf_counter() - start
    current, peak = tracemalloc.get_traced_memory()
    tracemalloc.stop()
    _ = current

    peak_memory_mb = float(peak) / (1024.0 * 1024.0)
    predictions = result.get("predictions", {}) if isinstance(result, dict) else {}
    confidences = result.get("confidences", {}) if isinstance(result, dict) else {}

    metrics = evaluate(predictions=predictions, ground_truth=ground_truth, confidences=confidences)
    overall_score = _overall_score(cfg, metrics)
    time_penalty_coef = float(cfg.get("penalties", {}).get("time_penalty_coef", 0.01))
    time_penalty = time_penalty_coef * math.log(max(1e-6, total_solution_time_sec))
    resource_penalty = _resource_penalty(cfg, peak_memory_mb)
    final_score = overall_score - time_penalty - resource_penalty

    return {
        "split_id": split_id,
        "metrics": {
            **metrics,
            "overall_score": overall_score,
            "final_score": final_score,
        },
        "runtime": {
            "total_solution_time_sec": total_solution_time_sec,
            "peak_memory_mb": peak_memory_mb,
            "time_penalty": time_penalty,
            "resource_penalty": resource_penalty,
        },
        "counts": {
            "num_test_nodes": len(ground_truth),
            "num_predictions": len(predictions) if isinstance(predictions, dict) else 0,
        },
    }


def _run_split_evaluations(
    split_ids: List[int],
    context: Dict[str, Any],
    max_workers: int,
) -> List[Dict[str, Any]]:
    global _WORKER_CONTEXT
    max_workers = max(1, min(max_workers, len(split_ids)))
    if max_workers == 1:
        _WORKER_CONTEXT = context
        _init_split_worker()
        return [_evaluate_one_split(split_id) for split_id in split_ids]

    try:
        mp_context = multiprocessing.get_context("fork")
        _WORKER_CONTEXT = context
        initializer = _init_split_worker
        initargs: Tuple[Any, ...] = ()
    except ValueError:
        mp_context = None
        initializer = _init_split_worker
        initargs = (context,)

    split_results: List[Dict[str, Any]] = []
    with ProcessPoolExecutor(
        max_workers=max_workers,
        mp_context=mp_context,
        initializer=initializer,
        initargs=initargs,
    ) as executor:
        futures = {executor.submit(_evaluate_one_split, split_id): split_id for split_id in split_ids}
        for future in as_completed(futures):
            split_results.append(future.result())

    split_results.sort(key=lambda item: int(item["split_id"]))
    return split_results


def _resolve_result_path(base_dir: str) -> str:
    override_path = os.getenv("SEB_RESULT_JSON")
    if override_path:
        return os.path.abspath(override_path)
    return os.path.join(base_dir, "outputs", "result.json")


def main() -> None:
    base_dir = os.path.dirname(os.path.abspath(__file__))
    cfg_path = os.path.join(base_dir, "config.yaml")
    cfg = _parse_simple_yaml(cfg_path)
    quick_test = str(os.getenv("QUICK_TEST", "")).lower() in {"1", "true", "yes", "on"}

    dp = cfg.get("data_path", {})
    nodes_path = os.path.join(base_dir, dp.get("nodes", "data/squirrel/nodes_all.jsonl"))
    graph_path = os.path.join(base_dir, dp.get("graph", "data/squirrel/graph.csv"))
    meta_path = os.path.join(base_dir, dp.get("meta", "data/squirrel/meta.json"))

    nodes_rows = _load_jsonl(nodes_path)
    graph_edges = _load_graph_edges(graph_path)
    meta = _load_meta(meta_path)

    data_dir_abs = os.path.join(base_dir, "data")

    _, solution_source = _resolve_solution_candidate(base_dir)

    total_available_splits = int(meta.get("num_splits", cfg.get("full_eval_num_splits", 10)))
    if quick_test:
        num_splits = min(total_available_splits, int(cfg.get("quick_test_max_splits", 2)))
    else:
        num_splits = min(total_available_splits, int(cfg.get("full_eval_num_splits", total_available_splits)))

    default_workers = int(cfg.get("parallel_eval_workers", 4))
    parallel_workers = _parse_int_env("SEB_PARALLEL_WORKERS", default_workers)
    eval_context = {
        "base_dir": base_dir,
        "cfg": cfg,
        "nodes_rows": nodes_rows,
        "graph_edges": graph_edges,
        "meta": meta,
        "quick_test": quick_test,
        "data_dir_abs": data_dir_abs,
    }
    split_results = _run_split_evaluations(list(range(num_splits)), eval_context, parallel_workers)

    aggregate_metrics = {
        "macro_f1": _aggregate_metric([r["metrics"] for r in split_results], "macro_f1"),
        "micro_f1": _aggregate_metric([r["metrics"] for r in split_results], "micro_f1"),
        "balanced_accuracy": _aggregate_metric([r["metrics"] for r in split_results], "balanced_accuracy"),
        "one_minus_ece": _aggregate_metric([r["metrics"] for r in split_results], "one_minus_ece"),
        "ece": _aggregate_metric([r["metrics"] for r in split_results], "ece"),
        "overall_score": _aggregate_metric([r["metrics"] for r in split_results], "overall_score"),
        "final_score": _aggregate_metric([r["metrics"] for r in split_results], "final_score"),
    }
    aggregate_runtime = {
        "avg_total_solution_time_sec": _aggregate_metric([r["runtime"] for r in split_results], "total_solution_time_sec"),
        "avg_peak_memory_mb": _aggregate_metric([r["runtime"] for r in split_results], "peak_memory_mb"),
        "avg_time_penalty": _aggregate_metric([r["runtime"] for r in split_results], "time_penalty"),
        "avg_resource_penalty": _aggregate_metric([r["runtime"] for r in split_results], "resource_penalty"),
        "max_peak_memory_mb": max((float(r["runtime"].get("peak_memory_mb", 0.0)) for r in split_results), default=0.0),
        "parallel_eval_workers": min(max(1, parallel_workers), num_splits),
    }

    out_path = _resolve_result_path(base_dir)
    os.makedirs(os.path.dirname(out_path), exist_ok=True)

    payload = {
        "task_name": cfg.get("task_name", "gnc_heterophily_squirrel_01"),
        "input_mode": cfg.get("input_mode", "batch"),
        "quick_test": quick_test,
        "solution_source": solution_source,
        "dataset": {
            "name": meta.get("dataset_name", "Squirrel"),
            "num_nodes": int(meta.get("num_nodes", len(nodes_rows))),
            "num_edges": int(meta.get("num_edges", len(graph_edges))),
            "feature_dim": int(meta.get("feature_dim", 0)),
            "num_classes": int(meta.get("num_classes", 0)),
            "num_splits_evaluated": num_splits,
        },
        "metrics": aggregate_metrics,
        "runtime": aggregate_runtime,
        "split_results": split_results,
    }

    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=2)

    print(f"Score: {aggregate_metrics['final_score']}")


if __name__ == "__main__":
    main()

