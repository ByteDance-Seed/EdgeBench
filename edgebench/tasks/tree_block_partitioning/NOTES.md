# tree_block_partitioning

Six progressive competitive-programming problems (C++). The agent writes `T1.cpp` .. `T6.cpp` in
`/home/workspace/p1`. The judge compiles each with `g++ -std=c++17 -Ofast -pipe` (problems 2–6 are
linked with a hidden interaction library), runs it on that problem's hidden cases under the
statement's time and memory limits, and scores problem *i* (weights 5, 5, 10, 15, 25, 40) as its
weight if every case passes, else `weight × 0.5 × passed / total`. Raw score = the sum, 0..100
(maximize). The rescale is the v1 one (`linear` 0..100). Four problems carry public online-judge
ids (P5611, P7881, P7723, P11691); two are original.

## Source

- Workspace stubs, samples and visible interaction libraries, and the judge (`judge/p1_judge/`:
  `eval.py`, `eval_common.py`, statements, reference solutions): the task authors' archives (not
  public), identical by sha256 and mode to the published v1 images.
- Blob `judge/blobs/p1_data.tar.gz` (186 MB packed, 415 MB unpacked; sha256 in `task.toml`): the six
  problems' `data/` directories (inputs, answers, hidden checker and interaction library), unchanged.
- `environment/workspace/*/problem.md` and `prompt.txt`: the English statements shipped in the
  published v1 work image (the archives have only Chinese versions); the limits are the same.
- python3 from the base's Ubuntu snapshot at v1's versions. Base: `bases/cpp`.
- `judge/run.sh` (v1's eval command verbatim) and `judge/grade.py` (new; writes `result.json` with
  v1's scoring).
- `instruction.md`: v1's prompt, verbatim.

## Deviations from v1

1. Root only: no `agent` user and no `sudo` (SCHEMA rule 3).
2. Eight packages of the shared base (ca-certificates, openssl, sed, xz-utils and a few libraries)
   are at the base's slightly newer versions; none is used by compiling, running or judging.
3. If `eval.py` crashes without a total score, or the judge times out, v1 recorded an unrankable
   score; the new grader returns `valid=false`. Empty submissions and compile errors score
   `valid=true, 0`, as in v1.
4. A stray Python 3.8 bytecode file in v1's judge is not shipped.
5. The workspace git commit is identical to v1's (same hash).

## Regression summary

Old (published v1 judge) and new judge on the same submissions, same shared host, interleaved,
2–3 runs per side. Raw score (= 0..100).

| Submission | Old | New |
|---|---|---|
| empty, historical 1 (six empty files) | 0 | 0 |
| reference solutions | 100 | 100 |
| forged score / answer lookup (Known issues 1, 2) | 100 / 5 | 100 / 5 |
| historical 2 | 14.87–14.92 | 14.92 |
| historical 3 | 23.60–23.99 | 23.76–23.99 |
| historical 4 | 26.20–28.31 | 28.00–28.48 |
| historical 5 | 38.94–45.88 | 39.47–45.88 |
| historical 6 | 53.17–59.75 | 52.86–59.75 |

Deterministic rows match exactly, including the 7200-unit details. The timing-sensitive rows differ
only through timeout flips, which follow host load; at low load both sides reproduce the historical
scores and agree with each other.

## Known issues

Kept as in v1, so scores stay comparable. Fixing any of them changes scores and bumps `version`.

1. **The submission can inject a score through its error output.** For a failing case the judge
   prints the program's last stderr line before the real score line, and the first `TOTAL_SCORE`
   anywhere wins, so a program that prints a score line gets that score with no case passed.
2. **Hidden answers are readable by the submission.** Submitted programs run as root in the judge
   next to the expected outputs (the cross-task issue in `tasks/SCHEMA.md`).
3. **Wall-clock limits with no grace.** Each case runs under the statement limit exactly, measured
   around a polling loop that includes process start-up, so solutions near the limit flip with host
   load.
4. **The memory limit is approximate** (RSS polling; spikes and child processes escape it), and a
   solution may use every host core.
5. **T6's hidden header differs from the visible one.** A conforming solution is unaffected, but one
   that touches the header's fields compiles locally and fails to compile in the judge.
6. **Partial-credit wording.** The instruction mentions subtasks; the judge has only cases.
7. A missing `Tk.cpp` compiles the empty stub from the judge image (compile error, 0 for that
   problem).
8. The task name and description describe the six data-structure problems only loosely.
9. The workspace `prompt.txt` and `instruction.md` are two English translations of the same prompt.
