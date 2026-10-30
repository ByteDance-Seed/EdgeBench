# Result Analysis Reference

This section uses "runnable baselines + iteration process records" to demonstrate that the task comes from a real engineering scenario, has sufficient discrimination and depth, and that the scoring system has been empirically validated.

### Deliverables

I. Two runnable reference implementations (~12 hours of benchmark effort total)

Stage-1 baseline (~4 hours), located at reference_implementation/stage1_baseline/:

- train.py: training script (Laplace-smoothed student × kp mastery aggregation + question bank index), runs in ~3 seconds

- infer.py: inference script (strict history split at cutoff + ZPD heuristics + constraint checks), ~20 seconds for 100 scenarios

- models/baseline.pkl: trained model (~30 MB)

- submission_test.json: actual submission on test_scenarios

- evaluation_report.json: measured evaluation report, total score 45.29

- README.md: design rationale and score breakdown

  Stage-2 advanced (incremental ~4~8 hours), located at reference_implementation/stage2_advanced/:

- train.py / infer.py: BKT-style fitting + entry-score prior + forgetting decay on unpracticed KPs + recommendation strategy aligned with evaluator judgment

- models/advanced.pkl: trained model (~14 MB)

- submission_test.json / evaluation_report.json: measured total score 50.40 (+5.11 vs baseline)

- README.md: three changes relative to baseline with per-component gains

  II. Engineering iteration records
  Located at reference_implementation/iteration_log.md, containing:

- Stage 1 (0~4 h): baseline construction, measured total 45.29

- Stage 2 (4~12 h): BKT fusion + recommendation aligned with evaluator judgment, measured total 50.40

- Stage 3 (12~36 h): DKT/AKT sequence models + target-KP recognizer, expected 60~68

- Stage 4 (36~72 h+): RL recommendation strategy + cold start + multi-model fusion, expected 68~75

- Each stage includes measured/expected breakdowns of component metrics

  III. Scoring system validation
  The "measured benchmark scores" table in eval_resources/scoring_rubric.md shows actual scores of 7 typical strategies (13~53 points), demonstrating that the scoring scheme:

1. Suppresses all gaming/cheating strategies below 21 points, including "partial submission (missing scenarios)" and "recommendations outside pool";
2. Gives the 4-hour baseline 45.29 and the 12-hour advanced version 50.40;
3. Expects 65~75 points for professional solutions (leaving room for continued improvement).
