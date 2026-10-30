# Stage 1 — Baseline Implementation

This folder is Stage 1 of the task authors' "reference implementation": a runnable baseline representing about **4 hours of work**. It is **not an optimal solution**; it serves as a **score calibration reference** for both Agents and reviewers.

## Design

| Module | Method | Complexity |
|---|---|---|
| Knowledge state estimation | (student, kp) aggregated correct rate + Laplace smoothing | O(N) aggregation, no training |
| Next-question prediction | `item_avg_correct × 0.5 + mastery_center × 0.5` | one-line linear combination |
| Recommendation strategy | ZPD set heuristic + prerequisite check + difficulty-gradient greedy | O(\|pool\|·log) |
| Data split | bisect at cutoff_ts, strictly no future answers | single bisect |

**Deliberately avoided challenges** (left for the Agent to tackle):
- Sequence models such as DKT/SAKT (require PyTorch training)
- Calibration optimization (Platt scaling / Isotonic)
- RL-based recommendation sequence optimization
- Multi-model fusion

## How to Run

```bash
# Training (~3 seconds)
python train.py --data_dir ../../input_data/ --model_out ./models/baseline.pkl

# Inference (~20 seconds for 100 scenarios)
python infer.py \
    --scenarios ../../eval_resources/test_scenarios.json \
    --model ./models/baseline.pkl \
    --output submission_test.json
```

## Measured Scores

Evaluated on `test_scenarios.json` (100 scenarios):

| Metric | Score | Raw Value |
|---|---|---|
| M1 | 44.3 | AUC=0.677 (100/100 with full 20-question predictions) |
| M2 | 38.3 | ECE=0.130, Spearman=0.297 |
| M3 | 9.2 | gain=+0.0046 |
| M4 | 98.8 | C1~C5: {1.00, 1.00, 0.94, 1.00, 1.00} |
| M5 | 100.0 | 1.0 s (closed-loop timing) |
| **Total** | **45.29** | |

See `evaluation_report.json` for the detailed report.

## Why 45.29 and Not 60+

1. **M1 AUC only 0.677**: the naive item × Laplace linear combination is near its ceiling. Breaking AUC 0.75 requires sequence models (DKT/AKT).
2. **M2 Spearman 0.297, ECE 0.130**: Laplace ranks sparse KPs decently but calibrates poorly. BKT or Bayesian estimation would clearly improve ECE.
3. **M3 gain 0.005**: the ZPD set heuristic can only aim fuzzily, far from the oracle's gain ≈ 0.037. A "target-KP recognizer" is needed.
4. **M4 already at 98.8**: baseline Laplace estimation aligns well with the evaluator's objective judgment; C3 pass rate 94%, little room left.

Main improvement directions for the Agent (cross-reference Stage 2 at `../stage2_advanced/`):
- BKT + entry-score prior + Laplace fusion -> M2 +10 (weighted +2.0)
- Recommendation aligned with the evaluator's estimation -> M3 +15 (weighted +3.7)
- DKT sequence modeling -> M1 +15 (weighted +5.3)

Measured total range: 45.29 -> 50.40 (advanced) -> expected 60~75 (deep methods).
