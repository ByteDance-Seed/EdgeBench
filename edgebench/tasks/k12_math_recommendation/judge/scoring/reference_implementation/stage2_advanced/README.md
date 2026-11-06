# Stage 2 — Advanced Implementation

This folder is Stage 2 of the task authors' "reference implementation": an advanced version representing roughly **4~8 hours of incremental work** on top of the Stage-1 baseline. It is **still not an optimal solution**; it demonstrates the first batch of feasible optimizations along M2/M3/M4 and serves as a reference for score progression.

## Improvements over the Baseline

### 1. Fused knowledge_state estimation
- **BKT-style theta fit**: with an entry-test-score-derived theta prior and slight forgetting decay on unpracticed KPs
- **Equal-weight fusion with Laplace**: `mastery = 0.5 × sigmoid(theta_BKT) + 0.5 × Laplace`
- **Division of labor**: BKT provides calibration (low ECE); Laplace provides ranking signal (high Spearman)

### 2. M1 prediction weighted by question discrimination
- Keep the `item × mastery` structure with dynamic weights by question discrimination:
  - `w_item = clip(0.25 + 0.3 × discrimination, 0.3, 0.7)`
  - High-discrimination questions trust item_avg_correct more; low-discrimination ones trust student mastery more

### 3. Recommendation strategy aligned with evaluator judgment
- **Additionally fit a "zero-prior BKT theta"** whose output exactly matches the evaluator's `StudentSimulator.evaluator_mastery_estimate`
- Use this objective estimate to determine weak KPs (for M4 C3) and prerequisite mastery (for M4 C4) during recommendation
- Candidate questions must hit both weak KPs **and** ZPD KPs

## How to Run

```bash
python train.py --data_dir ../../input_data/ --model_out ./models/advanced.pkl
python infer.py \
    --scenarios ../../eval_resources/test_scenarios.json \
    --model ./models/advanced.pkl \
    --output submission_test.json
```

## Measured Scores (change vs baseline)

| Metric | Baseline | Advanced | Δ |
|---|---|---|---|
| M1 | 44.3 (AUC 0.677) | 43.6 (AUC 0.675) | -0.7 |
| M2 | 38.3 (ECE 0.130, Sp 0.297) | **48.3** (ECE 0.069, Sp 0.243) | **+10.0** |
| M3 | 9.2 (gain 0.0046) | **23.9** (gain 0.0120) | **+14.7** |
| M4 | 98.8 | 96.6 | -2.2 |
| M5 | 100.0 (1.0 s) | 100.0 (0.9 s) | 0 |
| **Total** | **45.29** | **50.40** | **+5.11** |

See `evaluation_report.json` for the detailed report.

## Next Improvement Directions

The **marginal gains** of this advanced version are mainly limited by:

1. **M1 barely moves**: the item × mastery linear combination is near its ceiling. Raising AUC from 0.691 to 0.75+ requires sequence models:
   - DKT: ~40 minutes for 30 epochs of CPU training, expected AUC 0.75
   - AKT: another 30 epochs ~60 minutes, expected AUC 0.80+

2. **M2 Spearman actually declines** (0.319 -> 0.260): BKT calibrates well but its per-kp ranking signal is weaker than Laplace's. Real BKT-EM parameter fitting could bring Spearman back to 0.4+.

3. **M3 gain 0.014 is still 2.7× short of oracle 0.037**: an explicit "post-test target-KP predictor" is needed — features like the concentration of recent wrong KPs and recovery curves of consecutively missed KPs could predict which 5 KPs are most likely post-test targets.

4. **M4 C4 pass rate 93%**: the strict prerequisite check occasionally kills good questions — a "soft prerequisite weight" could replace hard filtering.

Reference roadmap: total score can rise from 50.40 toward 60~75.
