# Detailed Scoring Rules

This file is the companion documentation for the evaluation script `evaluate.py`.

---

## Total Score Formula

$$Score = 0.35 \cdot M1 + 0.30 \cdot M2 + 0.30 \cdot M3 + 0.04 \cdot M4 + 0.01 \cdot M5$$

Each component score is in [0, 100]; the total is also in [0, 100].

**Weight design goals**: make the task genuinely hard —
- No baseline / 30-minute hill-climb should reach 30 points
- Score-gaming strategies stay below 6 points
- Real KT model quality (M1+M2+M3, 95% combined weight) dominates the score
- 4% left for M4 (compliance only, not dominant), 1% for M5 (anti-timeout)

### Measured Benchmark Scores (weights 35/30/30/4/1)

Actual scores from 9 typical strategies run by the evaluator on `test_scenarios.json` (100 scenarios):

| Strategy | matched | M1 | M2 | M3 | M4 | M5 | Total |
|---|---|---|---|---|---|---|---|
| Fully random | 100/100 | 0.0 | 5.1 | 0.2 | 75.8 | 100 | **5.64** |
| Constant 0.5 submission | 100/100 | 0.0 | 0.0 | 0.0 | 75.4 | 100 | **4.02** |
| Selective submission (5/20 predictions) | 100/100 | 0.0 | 0.0 | 0.0 | 75.6 | 100 | **4.02** |
| Only 3 questions in recommendation | 100/100 | 0.0 | 0.0 | 0.0 | 51.2 | 100 | **3.05** |
| Recommendations outside pool | 100/100 | 0.0 | 0.0 | 0.0 | 60.0 | 100 | **3.40** |
| Stage-1 baseline (expert, 4h) | 100/100 | 10.9 | 25.8 | 3.7 | 98.8 | 100 | **17.60** |
| Stage-2 advanced (expert, 12h) | 100/100 | 9.8 | 39.7 | 14.9 | 96.6 | 100 | **24.70** |
| **AI agent-10** (HGB + heuristics, 30 min hill-climb) | 100/100 | 32.8 | 29.0 | 5.8 | 98.4 | 100 | **26.86** |
| Oracle (cheating, knows true target_kp) | 100/100 | 0.0 | 0.0 | 49.5 | 82.0 | 100 | **19.13** |

Observations:
- **All gaming/cheating strategies stay below 6 points**
- Selective submission (only 5/20 candidate predictions): M1 0 + M2 0
- Recommendation length != 10 or outside pool: C5 fails -> M4 drops 15+ points
- 4-hour baseline **17.60**, 12-hour advanced **24.70**
- AI 30-minute HGB+ZPD heuristic hill-climb reaches **26.86** (< 30 design target)
- Professional solutions (DKT/AKT + target-KP recognizer) expected **45~55 points**
- Top-tier solutions (AKT + multi-model stacking + RL recommendation) expected **60~75 points**
- Oracle (M3-only focus) gets just 19.13 — only balanced M1+M2+M3 scores high

---

## M1 — Next-Question Answer Prediction AUC (weight **35%**)

**Script function**: `evaluate.py :: compute_m1()`

**Formula**:
```
AUC_scenario = roc_auc_score(y_true, y_pred)   # per-scenario AUC
AUC_macro    = mean(AUC_scenario)              # macro average (over all 100 official scenarios)
M1           = clip((AUC_macro - 0.65) / 0.25, 0, 1) × 100
```
- AUC <= 0.65 -> 0 points (so random baselines / weak baselines / item-only get no M1 score)
- AUC >= 0.90 -> full marks
- Impact: simple item × Laplace baseline AUC ~0.677 -> 10.9 pts; HGB improves AUC to 0.732 -> 32.8 pts; DKT expected AUC 0.75 -> 40 pts; AKT expected 0.85 -> 80 pts

**Key constraints (hardened in v3)**:
- Each test scenario has exactly **20 unique candidate questions** in `candidate_questions`.
- The Agent must provide probabilities for all 20; any missing candidate prediction is substituted with 0.5 (random) during evaluation.
- Ground truth `next_question_truth` covers only a subset of candidates (13~20 per scenario); per-scenario AUC is computed only on candidates with ground truth; if a scenario's truth is all-0/all-1 or has fewer than 2 valid predictions, per-scenario AUC=0.5.
- Missing scenario: per-scenario AUC=0.5.
- The report field `n_scenarios_fully_covered_20` records scenarios with all 20 predictions submitted.

**Edge cases**:
- Probability values are clipped to [0, 1]; out-of-range values are not treated as invalid submissions.
- Question IDs outside the candidate set are ignored.

**Positive example** (complete, correct format):
```json
"next_question_probs": {
  "Q00142": 0.83, "Q00318": 0.12, "Q00455": 0.45, ...
}
```

**Negative example** (question ID not in candidate set, will be ignored):
```json
"next_question_probs": {"Q99999": 0.7}   // Q99999 is not a candidate
```

---

## M2 — Knowledge Mastery Probability Calibration + Rank Correlation (weight **30%**)

**Script function**: `evaluate.py :: compute_m2()`

### Ground Truth Source
`knowledge_truth` in `test_ground_truth.json` (50-dim float vector) comes from:
```
knowledge_truth[k] = sigmoid(θ_true[k] at cutoff_ts)
```
where `θ_true` is the **true ability trajectory** kept by `data_generator.simulate_answering` while generating student history logs, snapshotted at each evaluation scenario's `cutoff_ts`. It corresponds one-to-one with the student's actual answering path.

### Metric Combination (tightened)
```
per_student_ECE_i      = Σ_b (|B_b|/50) × |mean(pred_in_B_b) − mean(truth_in_B_b)|   # 10 bins
per_student_Spearman_i = spearmanr(pred_i, truth_i)                                    # 50-dim rank correlation

# ECE thresholds: <=0.02 full marks, >=0.10 zero
ECE_comp      = 100 × clip((0.10 − mean(per_student_ECE)) / 0.08, 0, 1)
# Spearman threshold: >=0.6 full marks
Spearman_comp = 100 × clip(mean(per_student_Spearman) / 0.6, 0, 1)
M2            = 0.5 × ECE_comp + 0.5 × Spearman_comp
```

Threshold calibration results:
- Simple Laplace smoothing (ECE 0.136, Spearman 0.309) -> 25.8 pts (ECE out of range gets 0, Spearman gets 51)
- AI HGB + simple mastery (ECE 0.095, Spearman 0.313) -> 29.0 pts
- BKT fusion (ECE 0.068, Spearman 0.240) -> 39.7 pts
- Real BKT-EM / DKT hidden-state readout (ECE ~0.04, Spearman ~0.45) -> 60+ pts

### Why Not Global ECE
If ECE were computed once over all students and KPs flattened together, an Agent submitting a constant 0.5 would score high whenever the marginal mean of the truth is near 0.5. That defeats the task's purpose of evaluating per-student, per-KP prediction accuracy. The per-student ECE + per-student Spearman combination simultaneously penalizes:
- Constant predictions with no differentiation (Spearman -> 0)
- Poor models whose prediction range is disconnected from the truth (ECE -> high)

### Positive / Negative Examples
- **Positive**: higher 50-KP distribution for strong students, lower for weak ones, with within-KP differentiation -> both components > 0.6, M2 > 60.
- **Negative A** (constant): `[0.5]*50` -> Spearman=0; ECE may be low but only earns half via the ECE component.
- **Negative B** (random): `[random()]*50` -> high ECE, Spearman ≈ 0, M2 ≈ 15~20.

---

## M3 — Recommendation Sequence Learning Gain (weight **30%**)

**Script functions**: `evaluate.py :: compute_m3()` + `student_simulator.py`

### Post-Test Design
Each scenario's `post_test_question_ids` (10 questions) are sampled from the question pool covering **3~5 "target ZPD knowledge points"** (5 randomly chosen from KPs with mastery ∈ [0.25, 0.65]). This ensures:
- Recommendations hitting target ZPD KPs genuinely raise post-test scores
- Random recommendations dilute the signal through overly broad coverage, gain near 0
- Precise recommendation (KT + target recognition) can reach gain > 0.02

### Learning Dynamics
`StudentSimulator.simulate()` uses two coefficient sets:
- `HIST_GAIN_*` (history replay): consistent with data_generator, `correct=0.28 × (1-m)`, `wrong=0.10 × 4m(1-m)`
- `REC_GAIN_*` (recommendation simulation): `correct=0.55 × (1-m)`, `wrong=0.18 × 4m(1-m)`

The pedagogical meaning of the difference: the recommendation phase represents "guided instruction + practice," which is more efficient than ordinary self-practice. This lets the Agent's recommendation decisions produce clear post-test reward differences.

### Scoring (piecewise function)
```
agent_post   = simulator.simulate(student, history, rec_10, post_test)   # expected correct rate
random_post  = mean over 5 random 10-picks from recommendation_pool
gain         = agent_post − random_post

# Piecewise linear interpolation (replaces the old linear gain / 0.05; anchors raised)
M3_anchors = [(0.000, 0), (0.005, 4), (0.012, 15),
              (0.025, 45), (0.040, 75), (0.060, 100)]
M3 = piecewise_linear(gain, M3_anchors)
```

### Piecewise Calibration
Anchors (raised again to restrain small-gain feedback from short hill-climbs):
- gain 0.005 -> 4 pts: simple ZPD heuristic
- gain 0.012 -> 15 pts: BKT fusion + recommendation aligned with evaluator
- gain 0.025 -> 45 pts: designed target-KP recognizer
- gain 0.040 -> 75 pts: oracle level (measured oracle gain ≈ 0.030 -> 49.5 pts)

**Why tightened again**: the goal is "30-minute AI hill-climb stays under 30 points." Measured AI gain 0.0062 earned 13 pts under the old (0,0)->(0.005,10) anchors (M3 contribution 3.3); the new anchors give 5.8 pts (M3 contribution 1.7) — the key suppression lever.

### Edge Cases
- Recommendation shorter than 10: simulated at actual length.
- Recommended question outside `recommendation_pool`: still simulated (the simulator does not hard-restrict), but counted as C1/C4 risk in M4.
- Simulator RNG fixed seed=42; each random baseline is sampled 5 times and averaged to reduce variance.

---

## M4 — Recommendation Constraint Satisfaction (weight **4%**)

**Script function**: `evaluate.py :: compute_m4()`

Five constraints per scenario, 0.2 each (per-scenario max 1.0), averaged over scenarios and multiplied by 100.

### The Five Constraints

| ID | Description | Basis |
|---|---|---|
| **C1** | No questions the student answered in the past 7 days (by timestamp) | queries `answering_logs.csv` |
| **C2** | Absolute `difficulty_level` gap between adjacent questions <= 1 | checks `question_bank.csv` |
| **C3** | The 10 questions cover >= 3 **evaluator-objectively-determined** weak KPs (mastery < 0.5) | `StudentSimulator.evaluator_weak_kps()` |
| **C4** | For any KP k of a recommended question, its direct prerequisite p has **evaluator-estimated** mastery >= 0.3 | `StudentSimulator.evaluator_prereq_met()` |
| **C5** | Recommendation sequence has **length exactly 10**, no duplicate `question_id`, and all from the scenario's `recommendation_pool` | length + dedup + pool membership triple check |

### On C3/C4 Objective Determination
C3 (weak KP coverage) and C4 (prerequisite mastery) are estimated by `StudentSimulator` independently from student history — **the Agent-submitted `knowledge_state` is not read**. The Agent's `knowledge_state` field only affects M2. This prevents gaming via self-reports like `[0.49]*50` that would make every KP "weak" and every prerequisite "passed."

### Measured Per-Constraint Pass Rates

| Constraint | Random | Baseline | Advanced | Out-of-pool |
|---|---|---|---|---|
| C1 (no recent repeats) | 1.00 | 1.00 | 1.00 | 1.00 |
| C2 (difficulty gradient <= 1) | 0.05 | 1.00 | 1.00 | 1.00 |
| C3 (cover >= 3 weak KPs) | 0.51 | 0.95 | 0.90 | 0.00 |
| C4 (prerequisites passed) | 1.00 | 1.00 | 0.95 | 1.00 |
| C5 (no dup + all in pool) | 1.00 | 1.00 | 1.00 | **0.00** |

Every constraint has discriminative power. The Agent earns the key C2+C3 points only by making real decisions on difficulty planning and weak-point identification.

### Example

Suppose a scenario:
- Recommendation: [Q0100, Q0101, Q0102, Q0103, Q0104, Q0105, Q0106, Q0107, Q0108, Q0109]
- C1: ✓ (none appeared in the last 7 days of logs)
- C2: ✓ (difficulty gradient [2,2,3,3,3,3,4,4,3,3])
- C3: ✗ (covers only 2 weak KPs)
- C4: ✓ (all prerequisite KPs mastery >= 0.3)
- C5: ✓ (no duplicates)
- Per-scenario satisfaction: 4/5 = 0.8

---

## M5 — Inference Efficiency (weight **1%**, mainly anti-timeout)

**Script functions**: `evaluate.py :: compute_m5()` + `run_and_time_inference()`

```
M5 = 100                                        if t <= 200s
M5 = 100 − (t − 200) / 10                       if 200 < t < 400s
M5 = 0                                          if t >= 400s
```

**Measurement (closed-loop timing)**:
- Recommended usage `--infer_cmd "python infer.py … --output {output}"`: the evaluation script spawns the inference process via `subprocess.run`, times it with `time.time()`, and records it in `report.json` under `M5_inference_efficiency.infer_time_seconds`.
- Compat mode `--infer_time_seconds <t>`: manually pass wall-clock seconds (measured separately by the evaluator in an isolated environment).

Training time is excluded (training is completed before the Agent's delivery).

If the inference script crashes or times out (force-killed at > 600 s): the entire submission is treated as invalid, M5 = 0, and other metrics are computed from whatever output exists (if no output file was produced, M1~M4 are all 0).

**Deliverables completeness penalty**: via `--deliverables_dir <agent_root>` the following 4 required deliverables are checked:
- `train.py`, `infer.py`, `requirements.txt`, `README.md`

Each missing item deducts 5 points from M5 (max 20, floored at 0). Complete submissions lose nothing. Details are written to the top-level `deliverables_completeness` of `report.json` and `M5_inference_efficiency.deliverables_penalty`.

---

## Additional Manual Review Rules (10 total)

Even with automated scoring, these 10 manual rules identify quality defects in the Agent's answers. Violating any rule is reflected in the `quality_flags` field of the evaluation report but **does not deduct points directly** (its effect is already indirectly penalized by automated scoring). For manual review only.

| ID | Rule | Positive | Negative |
|---|---|---|---|
| R1 | JSON structure strictly follows `output_schema.json` | all fields present | missing `recommended_sequence` |
| R2 | `knowledge_state` 50 values reasonably distributed, not all identical | [0.42, 0.71, 0.33, ...] varied | [0.5]\*50 |
| R3 | `next_question_probs` must not output identical probability for all candidates | different per question | all 0.8 |
| R4 | Recommendation must not be all the same difficulty tier | difficulty [2,2,3,3,3,4,4,3,3,2] | all difficulty 3 |
| R5 | Recommendation must not have all 10 questions on one knowledge point | covers 5+ KPs | all kp_26 |
| R6 | At least one "challenge question" (difficulty >= mean + 0.5) | contains one difficulty-4 | all easy |
| R7 | At least one "consolidation question" (difficulty <= mean − 0.5) | contains one difficulty-2 | all hard |
| R8 | All 100 scenarios covered, none missing | 100 scenarios | only 80 |
| R9 | `student_id` and `scenario_id` must match the test input | exact match | shuffled or wrong |
| R10 | `recommended_sequence` all from `recommendation_pool` | all 10 in pool | references outside pool |

---

## Run Examples

### Recommended: closed-loop timing mode

```bash
cd eval_resources/
python evaluate.py \
    --infer_cmd "python ../path/to/infer.py --scenarios test_scenarios.json --model ../path/to/model.pkl --output {output}" \
    --submission /tmp/eval_submission.json \
    --ground_truth ./test_ground_truth.json \
    --scenarios ./test_scenarios.json \
    --logs ../input_data/answering_logs.csv \
    --questions ../input_data/question_bank.csv \
    --kp_graph ../input_data/knowledge_graph.csv \
    --output report.json
```

### Compat: offline submission mode

```bash
python evaluate.py \
    --submission your_submission.json \
    --ground_truth ./test_ground_truth.json \
    --scenarios ./test_scenarios.json \
    --logs ../input_data/answering_logs.csv \
    --questions ../input_data/question_bank.csv \
    --kp_graph ../input_data/knowledge_graph.csv \
    --infer_time_seconds 178.5 \
    --output report.json
```

Sample `report.json` output (advanced implementation, closed-loop timing):
```json
{
  "weights": {"M1": 0.35, "M2": 0.30, "M3": 0.30, "M4": 0.04, "M5": 0.01},
  "scenarios_total": 100,
  "scenarios_submitted": 100,
  "scenarios_matched": 100,
  "M1_next_question_auc": {
    "auc_macro": 0.675, "n_scenarios_fully_covered_20": 100, "score": 9.8
  },
  "M2_knowledge_calibration": {
    "ece_per_student_mean": 0.068, "spearman_per_student_mean": 0.240,
    "ece_component": 39.5, "spearman_component": 40.0, "score": 39.7
  },
  "M3_learning_gain": {
    "agent_mean": 0.541, "random_mean": 0.529,
    "gain": 0.0120, "scoring": "piecewise", "score": 14.9
  },
  "M4_constraint_satisfaction": {
    "per_scenario_mean": 0.966,
    "per_constraint_pass_rate": {"C1": 1.0, "C2": 1.0, "C3": 0.88, "C4": 0.95, "C5": 1.0},
    "score": 96.6
  },
  "M5_inference_efficiency": {"infer_time_seconds": 0.9, "score": 100.0},
  "total_score": 24.70
}
```

---

## References

- Corbett & Anderson (1994). *Knowledge Tracing: Modeling the Acquisition of Procedural Knowledge*.
- Piech et al. (2015). *Deep Knowledge Tracing*.
- Pardos et al. (2013). *Adapting Bayesian Knowledge Tracing to a MOOC*.
- Ghosh et al. (2020). *Context-Aware Attentive Knowledge Tracing*.
- Vygotsky L.S. *Mind in Society* — origin of ZPD theory.
