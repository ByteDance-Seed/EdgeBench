# equivalence_class_divide_and_conquer

Six progressive competitive-programming problems. The agent writes `T1.cpp` .. `T6.cpp` in the
workspace root. The judge compiles each with `g++ -std=c++17 -Ofast -pipe`, runs it on that
problem's hidden tests with the statement's time limit (wall clock, no grace) and memory limit
(+16 MB), and checks the output by token comparison (T3: a testlib checker). Problem weights are
5, 5, 10, 15, 25, 40; a fully passed problem gets its weight, otherwise
`0.5 * weight * passed / total`. Raw score = the sum (0..100, maximize). The rescale is the v1 one
(`linear` 0..100), so the 0..100 score equals the raw score.

| Problem | Tests | Time | Memory | Checker |
|---|---|---|---|---|
| T1 (5) | 5 | 0.25 s | 32 MB | tokens |
| T2 (5) | 10 | 4 s | 128 MB | tokens |
| T3 (10) | 30 | 2 s | 512 MB | testlib 0.9.45 |
| T4 (15) | 25 | 2 s | 512 MB | tokens |
| T5 (25) | 20 | 12 s | 512 MB | tokens |
| T6 (40) | 30 | 4 s | 512 MB | tokens |

## Source

- The judge (`judge/p2_judge/`: `eval.py`, `eval_common.py`, testlib, the Chinese statements that
  `eval.py` parses for limits, and the reference `std.cpp` solutions) and the empty `T*.cpp`
  files: the task authors' archives (not public), identical by sha256 and mode to the published v1
  images.
- Blob `judge/blobs/p2_tests.tar.gz` (485 MB packed, 1.1 GB of hidden tests; sha256 in
  `task.toml`): the six problems' `data/` directories from the same archive, unchanged.
- `environment/workspace/T*_*/problem.md` and `prompt.txt`: the English statements shipped in the
  published v1 work image (the archive has only Chinese versions); they state the same limits.
- `judge/grade.py`: new; it runs v1's eval command and writes `result.json` with v1's scoring.
- `instruction.md`: v1's prompt, verbatim. python3 from the base's Ubuntu snapshot at v1's
  versions. Base: `bases/cpp`.

## Deviations from v1

1. Root only: no `agent` user and no `sudo` (SCHEMA rule 3).
2. Eight packages of the shared base (ca-certificates, openssl, sed, xz-utils and a few
   libraries) are at the base's slightly newer versions. None is used by the grader; the
   toolchain (gcc/g++ 11.4.0, libc, Python 3.10.12) is identical.
3. If `eval.py` aborts without a total score, v1 recorded an unrankable score; the new grader
   returns `valid=false`. Empty submissions and compile errors score `valid=true, 0`, as in v1.
4. The workspace git commit is identical to v1's (same hash).

## Regression summary

Old (published v1 judge) and new judge on the same submissions, same shared host, interleaved,
2–3 runs per side. Raw score (= 0..100).

| Submission | Old | New |
|---|---|---|
| empty, historical 1 (all files empty) | 0 | 0 |
| reference solutions | 100 | 100 |
| historical 2–4 | 5.083333, 9.916667, 20.375 | same |
| historical 5 | 41.25 / 38.25 / 37.25 | 41.25 x3 |
| historical 6 | 83.75 | 83.75 |

Every deterministic row agrees exactly, including per-problem pass counts and summaries.
Historical 5 has a T2 solution close to the 4 s limit; its v1 score (37.25) is reproduced by the
old judge under load, and the new result lies inside the old judge's own spread. A targeted
timing comparison of that solution showed no systematic per-test difference between the images.

## Known issues

Kept as in v1, so scores stay comparable. Fixing any of them changes scores and bumps `version`.

1. **Wall-clock limits with no grace.** The time limit is measured from process start to exit
   (including start-up and reading inputs of up to 20 MB), with no CPU pinning, so solutions near
   the limit flip between accepted and timed out with host speed and load. T1's 0.25 s limit is the
   tightest.
2. **The memory limit is RSS polling.** Short spikes, and memory used by spawned processes, can
   escape it. Memory-limit failures are reported as runtime errors.
3. **Partial credit is per test, not per subtask.** The instruction says each passed subtask or
   test point earns half its score; the judge ignores the subtasks in the statements.
4. **Public problems.** The tests are the original online-judge data of public problems (the
   directory names carry the problem ids), so models may have memorized published solutions.
5. **The submission can tamper with grading.** Submitted programs run as root next to the
   grader, which holds the expected outputs and reference solutions (the cross-task issue in
   `tasks/SCHEMA.md`). (Not tested.)
6. The judge contains dead code from another suite and a stray Python 3.8 bytecode file; kept
   byte-identical.
7. A missing `T{i}.cpp` compiles the empty file from the image (compile error, 0 for that
   problem).
