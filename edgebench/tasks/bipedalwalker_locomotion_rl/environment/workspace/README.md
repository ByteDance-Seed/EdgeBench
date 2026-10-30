# Loco-RL: Locomotion RL Agent Benchmark

An AI agent benchmark measuring the ability to write efficient reinforcement learning training code. Agents receive a deliberately weak PPO baseline and must improve it to achieve the highest possible episode reward within a time limit.

## Origin

Directly inspired by the **"Quadruped RL (highest score; no hparams)"** evaluation in Anthropic's Claude Mythos System Card (Table 2.3.3.A):

| Model | Score (highest) | Notes |
|-------|----------------|-------|
| Claude Opus 4.5 | 19.48 | |
| Claude Opus 4.6 | 20.96 | |
| Claude Mythos Preview | 30.87 | |

Threshold: **>12 ≈ 4 hours of human engineering work**. This benchmark uses **BipedalWalker-v3 + BipedalWalkerHardcore-v3** (Box2D, no MuJoCo required) to preserve the same engineering challenges: continuous control, sparse reward signals, and CPU multi-core parallelization as the primary throughput lever.

---

## Task Overview

The agent receives:
- **`baseline/train_baseline.py`** — a weak PPO implementation with 6 deliberate deficiencies
- **`envs/locomotion_env.py`** — environment utilities (vectorized env creation, obs normalization)
- **`task_prompt.md`** — full task description
- A **2-hour wall-clock time limit** (configurable; shortened for quick tests)

The agent must train a bipedal locomotion policy in the work container and save the final checkpoint to `submission/policy.pth`. The SE-Bench judge does not run training; it only loads the submitted checkpoint and evaluates the policy on each environment.

---

## Environments

### BipedalWalker-v3 (weight: 40% of final score)

A 2D bipedal robot walking on procedurally generated terrain with gentle slopes.

| Property | Value |
|----------|-------|
| Observation | 24-dim continuous (hull angle/velocity, joint angles × 4, angular velocities × 4, contact forces × 2, LIDAR × 10) |
| Action | 4-dim continuous ∈ [−1, 1] (hip and knee joint torques for both legs) |
| Reward per step | Small positive reward for forward velocity; small penalty for motor use |
| Fall penalty | −100 (episode terminates) |
| Completion bonus | +300 (reaching the far end) |
| Max episode length | 1600 steps |
| Random policy | ≈ −0.3 to +50 (usually falls) |
| Expert PPO/SAC | ≈ 300 |

### BipedalWalkerHardcore-v3 (weight: 60% of final score)

Identical robot, identical physics, but terrain includes **stumps, stairs, and pitfall gaps**. Substantially harder.

| Property | Value |
|----------|-------|
| Observation / Action | Same as non-hardcore |
| Random policy | ≈ −100 (falls immediately) |
| Expert policy | ≈ 300 (requires much more training and/or curriculum) |

Hardcore carries 60% weight because it is the harder discriminator. A policy that has only learned basic walking on flat terrain will still fall immediately when encountering obstacles.

---

## The Baseline and Its Weaknesses

`baseline/train_baseline.py` implements a minimal PPO with 6 deliberate deficiencies:

| Deficiency | Baseline value | Better value | Impact |
|------------|----------------|--------------|--------|
| Parallel envs | **1** (single env) | 32–128 | 142 CPU cores go unused |
| Network size | **hidden = 32** | 256–512 | Too small to represent complex gaits |
| Learning rate | **1e-4** | 3e-4 | Slow convergence |
| Discount factor | **0.90** | 0.99 | Undervalues long-term rewards |
| Steps per update | **128** | 2048+ | High gradient variance |
| Obs normalization | **none** | RunningMeanStd | Critical for BipedalWalker convergence |

**Why obs normalization matters so much**: BipedalWalker's 24 observation dimensions have very different scales (some near 0, some near ±5). Without normalization, the neural network receives inconsistent input magnitudes and has extreme difficulty learning. Empirically: without obs normalization, PPO stalls at reward ≈ −92 even after hours; with obs normalization, reward starts improving within 8 minutes.

**Why parallelization matters**: With a single environment, even the best PPO implementation can only collect ~5,000 env-steps/second. With 32–64 parallel environments using `AsyncVectorEnv`, throughput rises to ~9,000–15,000 steps/second. In a 2-hour window:
- 1 env → ~36M steps → may not learn to walk reliably
- 64 envs → ~108M steps → comfortably learns Walker, begins Hardcore

---

## Scoring

The trusted judge evaluates each submitted policy over a hidden multi-seed
episode set, with at least 10 episodes per environment. Reported rewards are
aggregate means; the exact seed list is not part of the agent-facing task.

```
normal_score    = clip(mean_reward_walker / 300, 0, 1) × 100
hardcore_score  = clip((mean_reward_hardcore + 100) / 400, 0, 1) × 100
final_score     = 0.4 × normal_score + 0.6 × hardcore_score
```

The SE-Bench strict score is:

```
strict_score = engineering_bonus + 0.20 * final_score
strict_score = min(strict_score, 30)
```

With all engineering checks passing, a raw locomotion score of 100 reaches the
30-point cap.


**Reference points for BipedalWalker:**

| mean_reward | normal_score | Interpretation |
|------------|--------------|----------------|
| −100 | 0 | Falls immediately |
| −50 | 0 | Falls after a few steps |
| 0 | 0 | Stays upright but doesn't move forward |
| 100 | 33 | Short bursts of walking |
| 200 | 67 | Consistent walking |
| 300 | 100 | Completes the course |

**Reference points for BipedalWalkerHardcore:**

| mean_reward | hardcore_score | Interpretation |
|------------|----------------|----------------|
| −100 | 0 | Falls immediately |
| −58 | 10.5 | Survives longer, still falls |
| 0 | 25 | Navigates flat sections |
| 100 | 50 | Handles some obstacles |
| 200 | 75 | Handles most obstacles |
| 300 | 100 | Completes the hardcore course |

**Overall performance tiers:**

| Final score | Technical path |
|-------------|---------------|
| 0–5 | Weak implementation (baseline-like; ~1.4 for baseline itself) |
| 5–20 | Obs normalization + better hyperparams, no parallelism |
| 20–50 | Parallelized PPO (32–64 envs), Walker learning |
| 50–80 | SAC/TD3 or well-tuned PPO, Walker reliably high, Hardcore improving |
| 80–100 | Curriculum learning, Walker ≥ 280, Hardcore ≥ 200 |

---

## Difficulty Analysis: What Each Range Requires

### 0–5 points: Baseline-level
Using the baseline as-is or with minor fixes scores ≈ 1.4/100. Walker gets −68 and Hardcore −91 after 200K steps (27 seconds of wall clock).

### 5–20 points: Fix the obvious problems
- Increase `hidden_dim` to 256+
- Fix `lr=3e-4`, `gamma=0.99`
- Add observation normalization (`RunningMeanStd`)

Without parallelization, 2 hours gives ~14M steps (1 env at 2000 steps/sec including network overhead). Walker reaches 0–50; Hardcore still negative.

### 20–50 points: Parallelize
Use `gym.vector.AsyncVectorEnv` or `SubprocVecEnv` with 32–64 workers. This is the primary engineering challenge — the agent must correctly implement parallel rollout collection, synchronize environments, and scale PPO's batch size accordingly. Walker reaches 100–200 in 2 hours.

### 50–80 points: Algorithm + curriculum
- Switch to **SAC** or **TD3** (off-policy; 2–3× more sample-efficient than PPO for continuous control)
- After Walker reaches ≥200, transfer to Hardcore fine-tuning
- Add reward shaping for obstacle avoidance

### 80–100 points: Expert-level
- Walker ≥ 280, Hardcore ≥ 200
- Requires careful curriculum design, possibly adversarial training or shaped rewards for specific obstacle types
- Likely needs the full 2-hour budget used effectively across both environments

---

## Evaluation Protocol

1. The submitted archive is overlaid onto the judge workspace.
2. The judge requires `submission/policy.pth`; it does not run `submission/train.py`.
3. The policy is loaded with `CUDA_VISIBLE_DEVICES=""` (CPU only).
4. The policy is evaluated on BipedalWalker-v3 over a hidden multi-seed episode set.
5. The same policy is evaluated on BipedalWalkerHardcore-v3 over a separate hidden multi-seed episode set.
6. Scores are computed from mean episode rewards.

For the default checkpoint format, the fallback `Policy` class reconstructs a two-layer MLP from `state_dict`, `obs_dim`, `action_dim`, and `hidden_dim`. For other architectures, submit `submission/policy.py` defining one of:

```python
def load_policy(path) -> torch.nn.Module: ...
def build_policy(checkpoint) -> torch.nn.Module: ...
class Policy(torch.nn.Module): ...
```

The returned module should implement `get_deterministic_action(obs)`, `act(obs)`, or `forward(obs)`, returning actions clamped or clampable to [−1, 1].

---

## Checkpoint Format

```python
torch.save({
    "state_dict": policy.state_dict(),
    "obs_dim":    24,
    "action_dim": 4,
    "hidden_dim": <your_hidden_dim>,   # used by evaluator to reconstruct network
}, "submission/policy.pth")
```

The evaluator automatically infers `hidden_dim` from the checkpoint's weight shapes if the key is absent, so partial compatibility is supported. Use `submission/policy.py` when you need a deeper MLP, residual network, observation-normalization wrapper, TorchScript-style wrapper, or other custom architecture.

---

## Measured Results

### Agent quick test (5-minute training)

| Iteration | Key design choices | Walker reward | Hardcore reward | Final score |
|-----------|--------------------|---------------|-----------------|-------------|
| 1 | 64 envs, hidden=256, curriculum at 250s | −68.4 | −91.3 | 1.3/100 |

The score is low because 5 minutes of training is insufficient and the curriculum (switching to Hardcore at 250 s) fires before Walker is learned. The infrastructure is correct.

### Reference implementation (20-minute training)

Reference training scripts and checkpoints are not included in the agent
workspace; implement your own `submission/train.py`.

| Time elapsed | Walker reward | Hardcore reward | Final score |
|-------------|---------------|-----------------|-------------|
| 0 (baseline) | −91 | −91 | 1.4/100 |
| 8 min | −71 | — | — |
| 17 min | −46 | — | — |
| 20 min | **−46.4** | **−58.0** | **6.3/100** |

Without obs normalization (pure SyncVectorEnv, no obs norm): reward stalls at −92 after hours of training — obs normalization is the critical missing ingredient.

---

## File Structure

```
loco-rl/
├── README.md                    # This file
├── PLAN.md                      # Full benchmark design document
├── task_prompt.md               # Agent-facing task description
├── baseline/
│   ├── __init__.py
│   └── train_baseline.py        # Weak PPO (single env, hidden=32, lr=1e-4)
├── envs/
│   └── locomotion_env.py        # make_env, AsyncVecEnv helper, NormalizeObsWrapper
├── eval/
│   └── evaluate_policy.py       # Trusted judge-side policy evaluation
├── submission/
│   ├── train.py                 # Agent-side training entrypoint
│   ├── policy.py                # Optional/custom policy loader
│   └── policy.pth               # Final trained checkpoint submitted to judge
└── task_prompt.md
```

## Quick Start

```bash
cd /home/workspace/loco-rl
PYTHON=python

# Run a short local training smoke test before longer runs
$PYTHON submission/train.py

# After training creates submission/policy.pth, ask the trusted judge to load it
sebench-submit --details
```

## Hardware Environment

- **CPU**: Intel Xeon, 142 physical cores — parallelization is the primary throughput lever
- **GPU**: none (set `CUDA_VISIBLE_DEVICES=""` during evaluation)
- **Python**: system `python`
- **Available packages**: `numpy`, `torch`, `gymnasium[box2d]`, `scipy`
