# Engineering Iteration Log

This file records the task authors' real process of building a solution system for this task from scratch. **Scores marked "measured" in the tables below are real, reproducible runs of the evaluation script; those marked "expected" are roadmap projections inferred from the measured stages.**

---

## Stage Benchmarks and Scores

| Stage | Benchmark Effort | Total | Status |
|---|---|---|---|
| Stage 1: baseline implementation | ~4 hours | **45.29** | ✅ measured (`stage1_baseline/`) |
| Stage 2: BKT fusion + recommendation alignment | ~8~12 hours | **50.40** | ✅ measured (`stage2_advanced/`) |
| Stage 3: DKT/AKT sequence models | ~36 hours | expected 60~68 | ⏳ roadmap |
| Stage 4: RL recommendation + cold start + multi-model fusion | ~72 hours | expected 68~75 | ⏳ roadmap |

> Measured score sources: `stage1_baseline/evaluation_report.json` and `stage2_advanced/evaluation_report.json`, obtained by actually running `eval_resources/evaluate.py` on the 100 official test scenarios.

---

## Stage 1 (0~4 hours) — Baseline Implementation **measured 45.29**

### Design

| Module | Method |
|---|---|
| Knowledge state estimation | Aggregate historical correct rate per (student, kp), Laplace smoothing `(correct+1)/(total+2)` |
| Next-question prediction | `0.5 × item_avg_correct + 0.5 × mastery_center` |
| Recommendation strategy | ZPD set heuristic (mastery ∈ [0.25, 0.65]) + prerequisite check + difficulty-gradient greedy |
| Data split | Bisect student history at scenario cutoff_ts, **strictly no future answers** |

### Measured Components

| Metric | Score | Raw Value |
|---|---|---|
| M1 (AUC) | 44.3 | AUC=0.677 |
| M2 (ECE + Spearman) | 38.3 | ECE=0.130, Spearman=0.297 |
| M3 (learning gain) | 9.2 | gain=+0.0046 |
| M4 (constraint satisfaction) | 98.8 | C1~C5 pass rate: {1.00, 1.00, 0.94, 1.00, 1.00} |
| M5 (inference efficiency) | 100.0 | 1.0 s (closed-loop timing) |
| **Total** | **45.29** | |

### Key Findings
- **Data split must be strict**: the initial version used a pre-aggregated `student × kp` mastery table (which included subsequent answers), inflating AUC to 0.866. After strict splitting it dropped back to 0.690 — more realistic.
- **Laplace-smoothed per-kp correct rate is already a strong signal**: it captures both overall student ability and kp-specific performance.
- **High M4 C3/C4 pass rates**: Laplace estimates correlate strongly with the evaluator's objective estimates.

---

## Stage 2 (4~12 hours) — BKT Fusion + Evaluator Alignment **measured 50.40**

### Three Improvements over Stage 1

**1. Fused knowledge_state estimation**
- On top of Laplace, add a BKT-style theta fit with an "entry-test-score-derived prior" and "slight forgetting decay on unpracticed KPs"
- Equal-weight average: `mastery = 0.5 × sigmoid(theta_BKT) + 0.5 × Laplace`
- BKT calibrates well (low ECE); Laplace has strong ranking signal (high Spearman)

**2. M1 prediction weighted by question discrimination**
- Keep the item × mastery structure with dynamic weighting by question discrimination:
  - High-discrimination questions -> trust item_avg_correct more
  - Low-discrimination questions -> trust student mastery more

**3. Recommendation strategy aligned with evaluator judgment**
- Additionally fit a "zero-prior BKT theta" whose output matches the evaluator's `StudentSimulator.evaluator_mastery_estimate`
- Use it to determine weak KPs (protecting M4 C3) and prerequisite mastery (protecting M4 C4) during recommendation
- Recommendation candidates = questions hitting both weak KPs and ZPD KPs

### Measured Components (change vs Stage 1)

| Metric | Score | Raw Value | Δ |
|---|---|---|---|
| M1 | 43.6 | AUC=0.675 | -0.7 |
| M2 | 48.3 | ECE=0.069, Spearman=0.243 | **+10.0** |
| M3 | 23.9 | gain=+0.0120 | **+14.7** |
| M4 | 96.6 | C1~C5: {1.00, 1.00, 0.88, 0.95, 1.00} | -2.2 |
| M5 | 100.0 | 0.9 s (closed-loop timing) | 0 |
| **Total** | **50.40** | | **+5.11** |

### Key Findings
- **The M2 gain comes mainly from BKT calibration**: ECE dropped from 0.139 to 0.069. Spearman actually declined (0.319→0.260) since BKT's ranking signal is weaker than Laplace's, but the fused M2 is better overall.
- **The M3 gain comes mainly from recommendation alignment**: using the same mastery estimation as the evaluator greatly raises the hit rate on "evaluator-determined weak KPs," doubling learning gain from 0.006 to 0.014.
- **M4 dips slightly**: strict prerequisite checks occasionally kill genuinely beneficial questions; C4 dropped from 100% to 93%.
- **M1 barely moves**: the item × mastery combination is near the ceiling for simple methods; breaking AUC 0.70 requires sequence models.

---

## Stage 3 (expected 12~36 hours) — Deep Sequence Models **expected 60~68**

**Not yet measured.** Roadmap based on experience with similar problems:

1. **DKT (Deep Knowledge Tracing, single-layer GRU + kp embedding)**
   - ~40 minutes for 30 epochs of CPU training
   - Expected M1 AUC 0.690 -> 0.75~0.78, M1 score +15
2. **BKT-EM parameter fitting** (independent p_learn/p_slip/p_guess/p_init per kp)
   - Expected M2 Spearman 0.26 -> 0.40~0.45, M2 +8~10
3. **Target-KP recognizer**: use student history features (recent error concentration, consecutive-miss KPs) to predict which 5 KPs are most likely post-test targets
   - Expected M3 gain 0.014 -> 0.022~0.028, M3 +10~15

**Total expected gain 8~15 points -> 60~68**.

---

## Stage 4 (expected 36~72 hours) — Multi-Model Fusion + Optimization **expected 68~75**

**Not yet measured.** Roadmap:

1. **AKT (Attentive Knowledge Tracing)**: self-attention replacing GRU, M1 AUC -> 0.82~0.85
2. **Multi-model stacking**: DKT + AKT + BKT + Laplace with xgboost as meta-learner
3. **RL recommendation strategy**: train a PPO policy on the evaluator's simulator, directly maximizing gain
4. **Cold-start modeling**: KNN prior for students with < 20 interactions
5. **Inference acceleration**: feature caching, batch inference

**Total expected further gain 5~8 points -> 68~75**.

---

## Score Range Summary (reference)

- **Any gaming/cheating strategy**: < 21 points
  - Fully random 19.8, selective submission of 5/20 candidates 20.0, recommendation length != 10 (short or long) 16.4~16.8, recommendations outside pool 17.6
- **Baseline implementation (measured)**: **45.29**
- **Advanced implementation (measured)**: **50.40**
- **Professional solutions (expected)**: 60~75
- **Theoretical ceiling** (simultaneously M1 AUC 0.90 + perfect M2 calibration + M3 hitting all target KPs + full M4): ~90

---

## Reproduction

```bash
# Training (once each for baseline / advanced)
cd reference_implementation/stage1_baseline/
python train.py --data_dir ../../input_data/ --model_out ./models/baseline.pkl
cd ../stage2_advanced/
python train.py --data_dir ../../input_data/ --model_out ./models/advanced.pkl

# Evaluation (closed-loop timing mode; evaluate.py spawns and times infer itself)
cd ../../eval_resources/
python evaluate.py \
    --infer_cmd "python ../reference_implementation/stage2_advanced/infer.py \
                 --scenarios test_scenarios.json \
                 --model ../reference_implementation/stage2_advanced/models/advanced.pkl \
                 --output {output}" \
    --submission /tmp/_eval_sub.json \
    --ground_truth test_ground_truth.json \
    --scenarios test_scenarios.json \
    --logs ../input_data/answering_logs.csv \
    --questions ../input_data/question_bank.csv \
    --kp_graph ../input_data/knowledge_graph.csv \
    --output report.json
```
