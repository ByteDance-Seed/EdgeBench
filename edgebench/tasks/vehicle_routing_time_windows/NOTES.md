# vehicle_routing_time_windows

Capacitated vehicle routing with time windows (CVRPTW). The agent improves a C++17 solver (`src/`,
`include/`, `Makefile`; binary `cvrptw_solver <input> <output> <time_budget_sec>`). The judge runs
`make -j4`, then runs the solver on 56 hidden instances one after another (each gets
`min(60, remaining)` seconds under a 20-minute global deadline), checks each output with
`tools/verify`, and scores each feasible instance against a best-known-solution (BKS) table:
`s_i = max(0, 100 − 30·max(0, NV − BKS_NV) − 0.5·max(0, %gap TD))`, plus 30 per vehicle below BKS
and up to 30 for beating the BKS distance, capped at 160; 0 if infeasible. Raw score =
`100 × mean(s_i)` (maximize, 0..16000). The rescale is the v1 one (`linear` 0..10000; 100 points =
BKS on average).

## Source

- Workspace (solver sources, `Makefile`, verifier source, public example instances) and the
  judge's workspace extras, hidden instances and BKS table: the task authors' repository (not
  public), identical by sha256 to the published v1 images. The workspace `README.md` and `Makefile`
  are the outputs of v1's setup scripts, byte-identical.
- The instance READMEs (`instances/public/README.md`, and two judge-side READMEs): the English
  versions shipped in the published v1 images (the repository has Chinese versions).
- `judge/eval.py` is the body of v1's inline eval program, byte for byte; `judge/run.sh` and
  `judge/write_result.py` are new and write `result.json` with v1's structured-result logic.
- `instruction.md`: v1's prompt, verbatim. Base: `bases/python` (g++ 14.2).

## Deviations from v1

1. Root only: no `agent` user and no `sudo` (SCHEMA rule 3).
2. v1's eval program is now a file fed to `python -` from the same directory, so it behaves the same.
3. Compile failures stay `valid=false, score 0`, as in v1. If the run is killed by the judge timeout,
   v1 recorded an unrankable score; the new grader returns `valid=false`.
4. The workspace git commit is identical to v1's (same hash).

## Regression summary

Old (published v1 judge) and new judge on the same submissions, same host, interleaved, 2–6 runs
per side. Raw score; 0..100 in brackets.

| Submission | Old | New |
|---|---|---|
| empty (starter solver) | 10.33 (0.10) | 10.33 |
| historical 1 (compile error) | 0, invalid | 0, invalid |
| historical 2 | 3947.06 x3, 4071.93 | 3946.50–3947.06 |
| historical 3 | 8973.35–9023.32 | 8972.37–9023.36 |
| historical 4 | 9473.09–9473.12 | 9472.88–9473.12 |
| historical 5 | 9990.58–9991.63 | 9990.74–9990.89 |
| forged result (Known issue 1) | 16000 (100) | 16000 (100) |

Deterministic rows match exactly. The time-limited rows agree within the old judge's own spread;
the two bimodal rows are explained per instance (one instance flips between 9 and 10 vehicles;
the other fits 23 or 24 instances into the global deadline).

## Known issues

Kept as in v1, so scores stay comparable. Fixing any of them changes scores and bumps `version`.

1. **The submission can inject a score through its build output.** The judge prints the `make`
   output before its own result, and the parser takes the first result block, so a submitted
   `Makefile` that prints one wins.
2. **The verifier is built by the submission's `Makefile`,** so a submission controls the program
   that checks its own outputs. Same root cause as the cross-task issue in `tasks/SCHEMA.md`.
3. **The hidden instances are the public Solomon 100-customer benchmark, unscrambled,** with public
   BKS values, although a workspace README says the judge uses shuffled copies. An agent that knows
   the Solomon set can tune for the exact instances.
4. **Stale workspace docs.** A README describes files the setup deletes, and the `Makefile` comment
   names the wrong OS and compiler.
5. **Global deadline vs per-instance budget.** 56 × 60 s exceeds the 20-minute deadline, so a solver
   that uses its full budget scores 0 on the remaining instances.
6. **Host-dependent score.** Solvers are anytime searches stopped by wall clock (some multithreaded),
   and each instance's budget depends on the time left, so scores move with host speed and load.
   No CPU or memory limits are enforced.
7. **Judge-timeout race.** The eval program's own deadline equals the judge timeout (1200 s), so a
   solver that uses the full budget can be killed before the result is printed (unrankable).
8. Compile errors are `valid=false` (rejected rather than scored 0).
