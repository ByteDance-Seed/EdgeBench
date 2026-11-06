#!/usr/bin/env python3
import argparse
import contextlib
import importlib
import io
import json
import math
import os
import random
import re
import subprocess
import sys

import gymnasium as gym
import nle
import numpy as np

WORK_DIR = "/home/nethack_agent"
N_SEEDS = int(os.environ.get("NETHACK_N_SEEDS", os.environ.get("NETHACK_N_GAMES", "10")))
REPEATS_PER_SEED = int(os.environ.get("NETHACK_REPEATS_PER_SEED", "2"))
MAX_STEPS = int(os.environ.get("NETHACK_MAX_STEPS", "5000"))
GAME_TIMEOUT = int(os.environ.get("NETHACK_GAME_TIMEOUT", "120"))
SCORE_SANITY_LIMIT = 100000
EVAL_SEED_BASE = int(os.environ.get("NETHACK_EVAL_SEED_BASE", "1729"))
RESULT_PREFIX = "SEBENCH_NETHACK_RESULT "

HACK_PATTERNS = [
    (r'FINAL_SCORE\s*=\s*["\']?\d{4,}', 'hardcoded FINAL_SCORE with large number'),
    (r'print\s*\(\s*f?["\'].*FINAL_SCORE.*\d{4,}', 'printing hardcoded FINAL_SCORE'),
    (r'TOTAL_SCORE\s+\d', 'attempting to spoof judge score output'),
    (r'CASES_(?:OK|TOTAL)\s+\d', 'attempting to spoof judge case output'),
    (r'SEBENCH_OFFICIAL', 'attempting to spoof official value prefix'),
    (r'open\s*\(\s*["\']\s*/tmp/eval', 'attempting to read/modify eval script'),
]


def static_check(code_path):
    try:
        with open(code_path) as f:
            code = f.read()
    except Exception:
        return True, []
    violations = []
    for pattern, desc in HACK_PATTERNS:
        if re.search(pattern, code):
            violations.append(desc)
    return len(violations) == 0, violations


def seed_process(seed):
    seed_value = EVAL_SEED_BASE + int(seed)
    random.seed(seed_value)
    np.random.seed(seed_value % (2**32 - 1))
    os.environ["PYTHONHASHSEED"] = str(seed_value)


def get_score_from_obs(obs):
    try:
        blstats = obs.get("blstats")
        if blstats is not None and len(blstats) > 9:
            score = float(blstats[9])
            if not math.isfinite(score) or score < 0:
                return 0
            return int(score)
    except Exception:
        pass
    return 0


def reset_env(env, seed):
    try:
        env.seed(seed)
    except Exception:
        pass
    reset_result = env.reset()
    if isinstance(reset_result, tuple):
        return reset_result[0], reset_result[1] if len(reset_result) > 1 else {}
    return reset_result, {}


def run_game_child(seed):
    seed_process(seed)
    try:
        if WORK_DIR not in sys.path:
            sys.path.insert(0, WORK_DIR)
        if "agent" in sys.modules:
            del sys.modules["agent"]
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            agent_mod = importlib.import_module("agent")
        get_action_fn = getattr(agent_mod, "get_action", None)
        if get_action_fn is None:
            return {"seed": seed, "status": "RE", "score": 0}
    except Exception:
        return {"seed": seed, "status": "RE", "score": 0}

    env = None
    try:
        env = gym.make("NetHackChallenge-v0")
        obs, info = reset_env(env, seed)
    except Exception:
        try:
            if env is not None:
                env.close()
        except Exception:
            pass
        return {"seed": seed, "status": "RE", "score": 0}

    best_score = 0
    consecutive_errors = 0
    for step in range(MAX_STEPS):
        try:
            with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
                action = get_action_fn(obs, info, step)
            if not isinstance(action, int):
                action = int(action)
        except Exception:
            consecutive_errors += 1
            if consecutive_errors > 100:
                break
            action = 18

        try:
            result = env.step(action)
            consecutive_errors = 0
        except Exception:
            break

        if len(result) == 5:
            obs, reward, terminated, truncated, info = result
            done = terminated or truncated
        else:
            obs, reward, done, info = result
        best_score = max(best_score, get_score_from_obs(obs))
        if done:
            break

    try:
        env.close()
    except Exception:
        pass

    if not math.isfinite(best_score) or best_score < 0 or best_score > SCORE_SANITY_LIMIT:
        return {"seed": seed, "status": "WA", "score": 0}
    if best_score <= 0:
        return {"seed": seed, "status": "WA", "score": 0}
    return {"seed": seed, "status": "OK", "score": int(best_score)}


def run_seed_subprocess(seed):
    cmd = [sys.executable, __file__, "--run-seed", str(seed)]
    try:
        r = subprocess.run(cmd, cwd=WORK_DIR, capture_output=True, text=True, timeout=GAME_TIMEOUT)
    except subprocess.TimeoutExpired:
        return seed, "TLE", 0
    if r.returncode != 0:
        return seed, "RE", 0
    result = None
    for line in (r.stdout + "\n" + r.stderr).splitlines():
        if line.startswith(RESULT_PREFIX):
            try:
                result = json.loads(line[len(RESULT_PREFIX):])
            except Exception:
                result = None
    if not result:
        return seed, "RE", 0
    status = result.get("status", "RE")
    try:
        score = float(result.get("score", 0))
    except Exception:
        score = 0
    if not math.isfinite(score) or score < 0 or score > SCORE_SANITY_LIMIT:
        return seed, "WA", 0
    score = int(score)
    if score <= 0 and status == "OK":
        status = "WA"
    if status not in ("OK", "WA", "RE", "TLE", "CE"):
        status = "RE"
    return seed, status, score


def main():
    agent_path = os.path.join(WORK_DIR, "agent.py")
    clean, violations = static_check(agent_path)
    total_cases = N_SEEDS * REPEATS_PER_SEED
    if not clean:
        for case_id in range(total_cases):
            print(f"HACK_DETECTED static_check {', '.join(violations)}", flush=True)
            print(f"CASE {case_id:04d} WA score=0", flush=True)
        print("TOTAL_SCORE 0.000000", flush=True)
        print("CASES_OK 0", flush=True)
        print(f"CASES_TOTAL {total_cases}", flush=True)
        return

    results = []
    for seed in range(N_SEEDS):
        for repeat in range(REPEATS_PER_SEED):
            _, status, score = run_seed_subprocess(seed)
            results.append((seed, repeat, status, score))

    ok = 0
    scores = []
    for case_id, (seed, repeat, status, sc) in enumerate(results):
        if not math.isfinite(sc) or sc < 0 or sc > SCORE_SANITY_LIMIT:
            status, sc = "WA", 0
        if sc <= 0 and status == "OK":
            status = "WA"
        if status == "OK":
            ok += 1
        scores.append(float(sc))
        print(f"CASE {case_id:04d} {status} score={int(sc)}", flush=True)

    mean_score = sum(scores) / len(scores) if scores else 0.0
    if not math.isfinite(mean_score) or mean_score < 0 or mean_score > SCORE_SANITY_LIMIT:
        mean_score = 0.0
    print(f"TOTAL_SCORE {mean_score:.6f}", flush=True)
    print(f"CASES_OK {ok}", flush=True)
    print(f"CASES_TOTAL {total_cases}", flush=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--run-seed", type=int, default=None)
    args = parser.parse_args()
    if args.run_seed is not None:
        result = run_game_child(args.run_seed)
        print(RESULT_PREFIX + json.dumps(result, sort_keys=True), flush=True)
    else:
        main()
