#!/usr/bin/env python3
"""SE-Bench structured evaluator for Loco-RL."""

from __future__ import annotations

import json
import os
import re
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parent
POLICY_PATH = ROOT / "submission" / "policy.pth"
MIN_EVAL_EPISODES = 10
EVAL_EPISODES = max(MIN_EVAL_EPISODES, int(os.environ.get("SEBENCH_LOCO_EVAL_EPISODES", str(MIN_EVAL_EPISODES))))
EVAL_TIMEOUT = int(os.environ.get("SEBENCH_LOCO_EVAL_TIMEOUT", "300"))
DEFAULT_EVAL_SEEDS = {
    "BipedalWalker-v3": [
        1009, 3251, 4933, 6427, 7109, 8863, 10939, 12491, 15149, 17389,
        19891, 22483, 25163, 28219, 31627, 34841, 37987, 41549, 45121, 48947,
    ],
    "BipedalWalkerHardcore-v3": [
        2017, 4057, 6271, 8093, 10457, 13291, 16631, 19079, 22639, 26053,
        29761, 33179, 36943, 40759, 44917, 48731, 52967, 57269, 61631, 66047,
    ],
}

PASSED = "PASSED"
FAILED = "FAILED"
ERROR = "ERROR"


def detail(name: str, status: str, message: str | None = None) -> dict:
    return {"name": name, "status": status, "message": message}


def compute_normal_score(mean_reward: float) -> float:
    return min(max(mean_reward / 300.0, 0.0), 1.0) * 100.0


def compute_hardcore_score(mean_reward: float) -> float:
    return min(max((mean_reward + 100.0) / 400.0, 0.0), 1.0) * 100.0


def compute_final_score(normal_score: float, hardcore_score: float) -> float:
    return 0.4 * normal_score + 0.6 * hardcore_score


def parse_seed_list(value: str) -> list[int]:
    seeds: list[int] = []
    for chunk in value.split(","):
        chunk = chunk.strip()
        if chunk:
            seeds.append(int(chunk))
    return seeds


def evaluation_seeds(env_id: str) -> list[int]:
    env_key = (
        "SEBENCH_LOCO_NORMAL_SEEDS"
        if env_id == "BipedalWalker-v3"
        else "SEBENCH_LOCO_HARDCORE_SEEDS"
    )
    seed_source = os.environ.get(env_key) or os.environ.get("SEBENCH_LOCO_EVAL_SEEDS")
    if seed_source:
        seeds = parse_seed_list(seed_source)
    else:
        seeds = list(DEFAULT_EVAL_SEEDS[env_id])

    if not seeds:
        raise ValueError(f"no evaluation seeds configured for {env_id}")

    while len(seeds) < EVAL_EPISODES:
        seeds.append(seeds[-1] + 9973)
    return seeds[:EVAL_EPISODES]


def evaluate_policy(env_id: str) -> dict:
    env = os.environ.copy()
    env["CUDA_VISIBLE_DEVICES"] = ""
    env["PYTHONPATH"] = str(ROOT) + os.pathsep + env.get("PYTHONPATH", "")
    seeds = evaluation_seeds(env_id)
    cmd = [
        sys.executable,
        str(ROOT / "eval" / "evaluate_policy.py"),
        "--policy",
        str(POLICY_PATH),
        "--env",
        env_id,
        "--n_episodes",
        str(EVAL_EPISODES),
        "--seeds",
        ",".join(str(seed) for seed in seeds),
    ]
    try:
        result = subprocess.run(
            cmd,
            cwd=ROOT,
            env=env,
            capture_output=True,
            text=True,
            timeout=EVAL_TIMEOUT,
        )
    except subprocess.TimeoutExpired:
        return {"env_id": env_id, "mean_reward": -200.0, "error": "evaluation_timeout"}

    output = (result.stdout or "") + (result.stderr or "")
    parsed = {"env_id": env_id, "mean_reward": -200.0, "error": None, "returncode": result.returncode}
    if result.returncode != 0:
        parsed["error"] = output[-500:]
        return parsed
    match = re.search(r"mean_reward=([-+]?\d+(?:\.\d+)?)", output)
    if not match:
        parsed["error"] = "mean_reward_not_found"
        return parsed
    parsed["mean_reward"] = float(match.group(1))
    return parsed


def strict_score(engineering_passed: int, final_score: float) -> tuple[float, dict]:
    engineering_bonus = 10.0 * engineering_passed / 4
    raw_bonus = 20.0 * (max(0.0, min(final_score, 100.0)) / 100.0)
    baseline_gain_component = 0.0
    score = min(30.0, engineering_bonus + raw_bonus + baseline_gain_component)
    return round(score, 2), {
        "engineering_bonus": round(engineering_bonus, 2),
        "raw_score_bonus": round(raw_bonus, 2),
        "baseline_gain_component": baseline_gain_component,
        "raw_loco_score": round(final_score, 2),
        "score_cap": 30.0,
        "difficulty_target": {
            "score_at_30min_lte": 15,
            "score_at_2h_lte": 30,
        },
        "formula": "engineering_bonus + 0.20 * raw_loco_score, capped at 30",
    }


def emit(result: dict) -> None:
    print(">>>>> Start Structured Result")
    print(json.dumps(result, indent=2, ensure_ascii=False))
    print(">>>>> End Structured Result")


def main() -> int:
    details = []
    dependency_ok = True
    try:
        import gymnasium  # noqa: F401
        import numpy  # noqa: F401
        import torch  # noqa: F401
        details.append(detail("engineering/dependencies_import", PASSED, "torch, numpy, gymnasium import"))
    except Exception as exc:
        dependency_ok = False
        details.append(detail("engineering/dependencies_import", ERROR, str(exc)))

    checkpoint_ok = POLICY_PATH.exists() and POLICY_PATH.is_file()
    if checkpoint_ok:
        details.append(detail(
            "engineering/checkpoint_submitted",
            PASSED,
            f"submission/policy.pth present; size_bytes={POLICY_PATH.stat().st_size}",
        ))
    else:
        details.append(detail("engineering/checkpoint_submitted", FAILED, "submission/policy.pth missing"))

    normal = {"env_id": "BipedalWalker-v3", "mean_reward": -200.0, "error": "not_evaluated"}
    hardcore = {"env_id": "BipedalWalkerHardcore-v3", "mean_reward": -200.0, "error": "not_evaluated"}
    normal_score = 0.0
    hardcore_score = 0.0
    raw_final = 0.0

    policy_loaded = False
    if dependency_ok and checkpoint_ok:
        normal = evaluate_policy("BipedalWalker-v3")
        if normal.get("returncode") == 0 or normal.get("error") is None:
            policy_loaded = True
            details.append(detail("engineering/policy_loads", PASSED, "policy loaded in evaluator subprocess"))
        else:
            details.append(detail(
                "engineering/policy_loads",
                FAILED,
                f"normal_error={normal.get('error')}",
            ))
        if policy_loaded:
            hardcore = evaluate_policy("BipedalWalkerHardcore-v3")
            if normal.get("error") is None and hardcore.get("error") is None:
                details.append(detail("engineering/policy_evaluates", PASSED, "both environments evaluated"))
            else:
                details.append(detail(
                    "engineering/policy_evaluates",
                    FAILED,
                    f"normal_error={normal.get('error')}; hardcore_error={hardcore.get('error')}",
                ))
            normal_score = compute_normal_score(float(normal.get("mean_reward", -200.0)))
            hardcore_score = compute_hardcore_score(float(hardcore.get("mean_reward", -200.0)))
            raw_final = compute_final_score(normal_score, hardcore_score)
        else:
            details.append(detail("engineering/policy_evaluates", FAILED, "policy did not load"))
    else:
        details.append(detail("engineering/policy_loads", FAILED, "checkpoint missing or dependencies failed"))
        details.append(detail("engineering/policy_evaluates", FAILED, "checkpoint missing or dependencies failed"))

    details.append(detail(
        "private_holdout/loco_rl",
        PASSED if raw_final > 0 else FAILED,
        (
            "aggregate_only; "
            f"normal_reward={normal.get('mean_reward')}; "
            f"hardcore_reward={hardcore.get('mean_reward')}; "
            f"raw_final={raw_final:.2f}"
        ),
    ))

    engineering_passed = sum(
        1 for d in details
        if d["name"].startswith("engineering/") and d["status"] == PASSED
    )
    score, scoring = strict_score(engineering_passed, raw_final)
    passed = sum(1 for d in details if d["status"] == PASSED)
    failed = sum(1 for d in details if d["status"] == FAILED)
    errors = sum(1 for d in details if d["status"] == ERROR)
    result = {
        "valid": True,
        "score": score,
        "pass_rate": passed / len(details) if details else 0.0,
        "total_tests": len(details),
        "passed": passed,
        "failed": failed,
        "errors": errors,
        "summary": (
            f"checkpoint_submission=true; strict_score={score}; "
            f"raw_loco_score={raw_final:.2f}; feedback=aggregate_only"
        ),
        "details": details,
        "metrics": {
            "checkpoint_path": str(POLICY_PATH),
            "checkpoint_present": checkpoint_ok,
            "eval_episodes": EVAL_EPISODES,
            "eval_seed_strategy": "per-environment hidden seed set average",
            "eval_seed_count_per_env": EVAL_EPISODES,
            "feedback": "aggregate_only",
            "normal": normal,
            "hardcore": hardcore,
            "normal_score": round(normal_score, 2),
            "hardcore_score": round(hardcore_score, 2),
            "raw_final_score": round(raw_final, 2),
            "scoring": scoring,
        },
    }
    emit(result)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
