# jagua_nesting_optimization

The workspace is the public Rust project `jagua-rs` (2D irregular cutting and packing collision
detection) with its `lbf` left-bottom-fill reference optimizer. The agent improves `lbf` for strip
packing. The judge builds the submitted tree and a frozen copy of the original code, runs both
with `cargo run --release --bin lbf` on 16 hidden instances (fixed seeds, 900 samples, 20 s per
run), validates the candidate's solution JSON, and sums a nonlinear improvement score times a
runtime factor: 6.25 points per case. Raw score = the sum (0..100, maximize). v1 had no rescale.

## Source

- `environment/jagua-rs/`: the public upstream `github.com/JeroenGar/jagua-rs` at `43e81373…`
  (2026-05-20) plus a generated `Cargo.lock`, minus the hidden instances, as in v1's work bundle.
- `judge/hidden/` (29 hidden instance files and the unfiltered test list) and
  `judge/jagua_task_scorer/{evaluate.py,score.sh}`: v1's judge bundle and inline scripts,
  byte-identical to the published v1 judge image.
- `environment/SEBENCH_TASK.md`: the English version shipped in the published v1 work image (v1's
  build recipe had a Chinese version).
- Rust 1.88.0 installed by a pinned recipe shared with `rust_multicrate_reconstruction`; crates
  come from crates.io, verified against `Cargo.lock`. Base: `bases/rust`.
- `judge/run.sh` (v1's eval command verbatim) and `judge/result.py` (new; writes `result.json`
  with v1's scoring).
- `instruction.md`: v1's prompt, verbatim.

## Deviations from v1

1. Root only: no `agent` user and no `sudo` (SCHEMA rule 3).
2. v1 configured a third-party crates mirror; it is dropped (crates come from crates.io, same
   files).
3. **The judge is offline.** A submission that adds a crate not in `Cargo.lock` could fetch it in
   v1 but fails to build (score 0) here. No sampled historical submission does that.
4. A build-time test listing that v1 left in `/tmp` moved to `/judge/`; nothing reads it.
5. If no total score is printed, v1 recorded an unrankable score; the new grader returns
   `valid=false`. Compile errors score `valid=true, 0`, as in v1.
6. The workspace git commit is identical to v1's (same hash).

## Regression summary

Old (published v1 judge) and new judge run concurrently on the same submission, same shared host,
four rounds. Raw score per round.

| Submission | Old | New |
|---|---|---|
| empty (reference code) | 0 | 0 |
| historical 1 | 19.31 / 19.95 / 20.32 / 19.75 | 19.36 / 20.06 / 18.90 / 19.30 |
| historical 2 | 7.15 / 5.21 / 5.35 / 7.22 | 7.21 / 5.34 / 5.35 / 7.40 |
| historical 3 | 26.96 / 23.75 / 23.89 / 26.96 | 26.96 / 23.75 / 24.52 / 26.96 |
| historical 4 | 38.01 / 36.53 / 36.86 / 38.16 | 38.03 / 38.38 / 38.19 / 38.28 |
| historical 5 | 43.71 / 38.76 / 44.20 / 42.84 | 44.18 / 42.12 / 44.96 / 43.18 |

The reference widths are identical in every case of every run on both sides. Old and new agree
within 0.5 in the low-load rounds; the larger gaps under load come from the runtime factor and
from wall-clock-budgeted searches, and are no bigger than the old judge's own spread. One
historical compile error in v1 is not reproduced by either image (the submission builds fine).

## Known issues

Kept as in v1, so scores stay comparable. Fixing any of them changes scores and bumps `version`.

1. **Stacked copies pass validation.** The overlap check does not flag two copies of an item
   placed at the same position, so collapsing copies of each item type yields "valid" layouts that
   are much narrower than any honest solution. The hidden instances have many copies per item type.
2. **Allowed orientations are not checked.** Any rotation angle is accepted.
3. **Host-dependent score.** Most reference runs finish under the 0.15 s floor, so a candidate that
   takes more than about 0.75 s per instance is penalized; typical improved solvers get a runtime
   factor of 0.6–0.9, which moves with host speed and load. Solvers with wall-clock budgets also
   change their layouts between runs.
4. **The submission can tamper with grading.** A `build.rs` runs as root during the candidate
   build, before the reference is built and scored (the cross-task issue in `tasks/SCHEMA.md`).
5. Only 16 of the 17 hidden cases run; some hidden instance files are never used.
6. Files the agent deleted are still present in the judge (the submission is extracted over the
   full tree), and the judge always uses its own `Cargo.lock`.
7. A valid but non-improving case is reported as `WA`, the same status as an invalid one.
8. The task text says "bin packing" and "strip packing" interchangeably; it is strip packing.
