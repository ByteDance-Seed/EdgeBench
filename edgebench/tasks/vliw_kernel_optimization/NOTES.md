# vliw_kernel_optimization

Based on Anthropic's public "original performance take-home". The agent edits `solution.py`
(`KernelBuilder.build_kernel`) to emit an instruction program for a custom VLIW/SIMD machine
simulated in `problem.py` (per cycle: 12 alu, 6 valu, 2 load, 2 store, 1 flow slots; VLEN 8; one
core). The program must reproduce `reference_kernel2` (a batched walk over a random forest with
hashing) on the workload `forest_height=10, rounds=16, batch_size=256`. The judge runs `runner.py`
on 9 hidden cases (8 correctness, 1 performance, same shape, different seeds) against a frozen copy
of the simulator. Raw score = the simulated cycle count of the performance case, valid only if all
9 cases are correct (minimize). The rescale is the v1 one (`log_min`, baseline 4475.53, expert
1000). The starter scores 147734 (0 points).

## Source

- Workspace (`problem.py`, starter `solution.py`, docs and public tests) and the judge's evaluation
  directory (runner, verifier, frozen simulator, hidden cases): the task authors' repository (not
  public), identical by sha256 and mode to the published v1 images.
- `judge/eval_hidden.py` is v1's inline eval program, verbatim; `judge/run.sh` and
  `judge/write_result.py` are new and write `result.json` with v1's structured-result logic.
- `instruction.md`: v1's prompt, verbatim. Base: `bases/python` (no extra packages).

## Deviations from v1

1. Root only: no `agent` user and no `sudo` (SCHEMA rule 3).
2. **v1's parse is kept exactly.** In v1, a fixed trace line of the eval command always made the
   first result-marker strategy fail, so v1 effectively parsed the first JSON line instead. The new
   grader turns that strategy off to get the same result.
3. Invalid submissions (a wrong case, an exception, the 600 s runner timeout) are `valid=false`
   with no score, as in v1.
4. The runner's report file stays at its v1 `/tmp` path at run time so the eval program is
   unchanged. Nothing the task ships is under `/tmp`.
5. The workspace git commit is identical to v1's (same hash).

## Regression summary

Old (published v1 judge) and new judge on the same submissions, same host, interleaved, two runs
each. The score is a simulated cycle count, independent of host speed. Raw score; 0..100 in
brackets.

| Submission | Old | New |
|---|---|---|
| empty (starter), historical 2 (unchanged starter) | 147734 (0) | 147734 |
| historical 1 (exception in `build_kernel`) | invalid | invalid |
| historical 3–5 | 1626 (67.56), 1417 (76.74), 1145 (90.96) | same |
| forged marker block (Deviation 2) | 147734 | 147734 |
| forged JSON line / forged report (Known issues 1, 2) | 1.0 (100) | 1.0 (100) |

Every row matches exactly with zero spread and equals the historical v1 scores.

## Known issues

Kept as in v1, so scores stay comparable. Fixing any of them changes scores and bumps `version`.

1. **The submission can forge the result through its output.** `solution.py` runs inside the
   runner, whose output is printed before the eval program's own result, and the parser takes the
   first JSON line with a result key.
2. **The submission can forge the runner report.** The eval program reads the runner's report file
   without checking that the runner wrote it or exited normally.
3. **The simulator lives in the submission's process,** so a solution could patch the machine or
   the reference kernel. (Found by reading the code; not exercised.)
4. **The hidden cases are readable at run time** in the judge's working directory, and the case
   data could be rebuilt from the seeds; the instruction forbids hard-coding seeds, but nothing
   checks it. All cases share the public workload shape, so honest scores barely depend on the seed.
5. **The submission can tamper with grading.** Solution code runs as root next to the grader (the
   cross-task issue in `tasks/SCHEMA.md`).
6. **Instruction vs workspace docs.** The instruction is one paragraph; the score definition and
   thresholds are only in the workspace README and problem description.
7. On a runner error the runner prints `Score: 0.00` although the submission is invalid (cosmetic).
8. **Kernel build time is not scored.** A solution may search for a schedule inside `build_kernel`;
   only the 600 s runner timeout bounds it, which makes slow solutions host-dependent near the limit.
