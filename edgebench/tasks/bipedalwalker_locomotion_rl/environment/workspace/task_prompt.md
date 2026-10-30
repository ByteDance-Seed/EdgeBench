# Loco-RL: Locomotion Reinforcement Learning Challenge

## Overview

Your task is to train and submit a bipedal walking policy that walks as far and as fast as possible. You are given a **deliberately weak baseline** PPO implementation and must improve it to produce the strongest `submission/policy.pth` checkpoint within the allotted agent time.

**Agent time limit:** 2 hours wall-clock  
**CPU resources:** 142 cores available (Intel Xeon, no GPU)  
**Goal:** Use `submission/train.py` or your own training code to create `submission/policy.pth`; the judge evaluates the submitted checkpoint only.

---

## The Environments

### BipedalWalker-v3 (40% of score)
A 2D bipedal robot must walk forward on procedurally generated terrain with hills and gentle slopes.

- **Observation space:** 24-dimensional continuous (hull angle, angular velocity, joint angles/speeds, LIDAR readings)
- **Action space:** 4-dimensional continuous in [-1, 1] (hip and knee joint motor torques)
- **Reward:** +300 for reaching the far end; -100 for falling; small step rewards for moving forward; slight penalty for motor use
- **Episode length:** up to 1600 steps
- **Random policy score:** ~-0.3
- **Expert PPO/SAC score:** ~300

### BipedalWalkerHardcore-v3 (60% of score)
Same robot, same physics, but the terrain now contains **obstacles**: stumps, stairs, and pitfall gaps. Significantly harder.

- **Observation/action:** identical to non-hardcore (24-dim obs, 4-dim action)
- **Reward structure:** identical, but obstacles make the +300 completion reward much harder to achieve
- **Random policy score:** ~-100 (robot falls immediately)
- **Expert PPO/SAC score:** ~300 (requires much more training)

Both environments work with `gymnasium.make("BipedalWalker-v3", render_mode=None)` and are fully CPU-compatible.

---

## What You Must Do

Write or modify training code under `submission/` that:

1. **Trains a policy in the agent workspace** using any RL algorithm of your choice (PPO, SAC, TD3, DDPG, etc.)
2. **Saves the final trained policy** to `submission/policy.pth`. The simplest compatible format is:
   ```python
   torch.save({
       "state_dict": policy.state_dict(),
       "obs_dim": 24,
       "action_dim": 4,
       "hidden_dim": <your_hidden_dim>,
   }, "submission/policy.pth")
   ```
3. Optionally provides `submission/policy.py` for arbitrary architectures. The judge supports `load_policy(path)`, `build_policy(checkpoint)`, or a `Policy` class.
4. **Uses only CPU** (no CUDA)
5. Keeps large intermediate checkpoints outside `submission/`; only the final checkpoint should be submitted.

The submitted policy module should implement at least one deterministic-action path:
```python
class Policy(nn.Module):
    def __init__(self, obs_dim=24, action_dim=4, hidden_dim=64):
        ...
    def get_deterministic_action(self, obs: torch.Tensor) -> torch.Tensor:
        # Returns action in [-1, 1]
        ...
```
The judge also accepts `act(obs)` or `forward(obs)` returning a 4D action tensor in `[-1, 1]`.

---

## The Weak Baseline (What You're Improving)

The provided baseline (`baseline/train_baseline.py`) has these deliberate weaknesses:

| Issue | Baseline | Better |
|-------|----------|--------|
| Parallelism | 1 environment | 32-128 envs via multiprocessing |
| Network size | 32 hidden units | 256-512 hidden units |
| Learning rate | 1e-4 (too small) | 3e-4 |
| Discount factor | 0.90 (too low) | 0.99 |
| Steps per update | 128 | 2048+ |
| Algorithm | bare PPO | PPO with proper tuning, or SAC/TD3 |
| Obs normalization | none | running mean/std normalization |

The baseline achieves ~-50 to -20 on BipedalWalker-v3 in 200k steps. A well-tuned implementation should reach 100-300+ within 10 minutes using 32+ parallel environments.

---

## Optimization Directions

### High-impact (do these first):
1. **Parallel environments** — With 142 CPU cores, running 64 environments in parallel gives ~64x more data per wall-clock second. Use `multiprocessing.Process` + `Pipe`, or the provided `SubprocVecEnv` from `envs/locomotion_env.py`.
2. **Better hyperparameters** — `gamma=0.99`, `lr=3e-4`, `n_steps=2048`, `batch_size=256`
3. **Larger network** — At minimum 256 hidden units; add layer normalization for stability

### Medium-impact:
4. **Observation normalization** — Running mean/std normalization of observations greatly stabilizes training
5. **Reward normalization** — Divide rewards by running std for more stable value estimates
6. **Better algorithm** — SAC (off-policy) can be more sample-efficient; TD3 is also competitive

### For the hardcore environment:
7. **Curriculum learning** — Train on Walker first, then fine-tune on Hardcore
8. **Longer episodes** — The hardcore env needs the agent to navigate obstacles, requiring more exploration
9. **Higher entropy** — More exploration early in training helps find the obstacle-crossing strategy

---

## Scoring Formula

The trusted judge averages each environment over a hidden multi-seed evaluation
set with at least 10 episodes per environment. Do not tune for a single visible
seed; submissions are scored on aggregate locomotion performance.

```python
normal_score   = clip(mean_reward / 300.0, 0, 1) * 100      # BipedalWalker
hardcore_score = clip((mean_reward + 100) / 400.0, 0, 1) * 100  # BipedalWalkerHardcore
final_score    = 0.4 * normal_score + 0.6 * hardcore_score
```

The SE-Bench strict score is then calibrated as engineering checks plus
`0.20 * final_score`, capped at 30.

| Score | Interpretation |
|-------|---------------|
| 0-20 | Barely better than random |
| 20-40 | Learning to walk somewhat |
| 40-60 | Consistent forward walking |
| 60-80 | Strong on Walker, some Hardcore |
| 80-100 | Expert-level on both environments |

---

## Available Tools

```python
# Standard packages (pre-installed):
import numpy as np
import torch
import torch.nn as nn
import gymnasium as gym  # includes box2d

# Environment utilities (in this repo):
import sys; sys.path.insert(0, '/path/to/loco-rl')
from envs.locomotion_env import make_vec_env, NormalizeObsWrapper, get_env_info

# Python interpreter:
PYTHON = "python"
```

## Constraints

- **No GPU**: `CUDA_VISIBLE_DEVICES=""` is set during evaluation
- **No pre-trained weights**: Do not download or use pre-trained policies from the internet
- **No RL libraries**: Do not use stable-baselines3, RLlib, or similar — implement RL yourself
- **Must submit checkpoint**: `submission/policy.pth` is included in the submitted archive and is required for scoring.
- **Judge does not train**: trusted evaluation only loads `submission/policy.pth` and runs policy rollouts. Any training must happen before you call `sebench-submit`.
- **Must terminate local training**: training scripts should respect your remaining agent time (use `signal.SIGALRM` or time checks)

## Tips

- Do not start with a long 2-hour training run. First run quick smoke tests and short training loops; keep early iterations under 10 minutes so you can inspect failures, fix checkpoint loading, and submit frequently.
- Use the available 2-hour agent window for active improvement. Do not stop after the first loadable checkpoint; after each trusted result, continue tuning training code, training time, architecture, normalization, and curriculum until you are close to the time limit.
- A good cadence is: smoke test and first checkpoint quickly, submit within the first 30 minutes, then run longer training/tuning cycles and submit stronger checkpoints periodically. Make a final submission near the end.
- Do not idle or sleep just to consume wall-clock time; spend the time on training, evaluation, debugging, and checkpoint improvement.
- Use `time.time()` to track elapsed time and stop training gracefully before your chosen local training budget.
- Print progress periodically: `Step X: avg_reward=Y.YY` helps debugging
- Test your script with a 2-minute limit before spending a longer run.
- After `submission/policy.pth` exists, run `sebench-submit --details` to verify that the judge can load and evaluate it.
- The evaluator uses deterministic actions (mean of policy distribution), so ensure your policy's deterministic mode is good
- For BipedalWalkerHardcore, a negative mean reward is common even for decent policies — the scoring formula accounts for this (minimum -100)
