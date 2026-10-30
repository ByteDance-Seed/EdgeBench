# rust_multicrate_reconstruction

CAS ("Coding Agent System"): a 16-crate Cargo workspace (`agent-start/`) with the function bodies
removed (`todo!()`). The agent fills them in. The judge runs `cargo test --frozen` per crate twice:
once with the public tests, then again after injecting 833 hidden test snippets (795 hidden test
names). Raw score = a weighted L0–L9 layer score, 0..100 (maximize). The rescale is the v1 one
(`linear` 0..100).

## Source

- Workspace (`agent-start/` and its README, 2,128 files) and the judge's scorer, hidden test
  sources and manifest (`judge/cas_judge/`): the task authors' v1 bundle (not public), identical by
  sha256 and mode to the published v1 images.
- `environment/vendor/claude_rs/`: a path dependency that is not on crates.io, committed (692 KB).
- The other 740 vendored crates (1.1 GB) are rebuilt at build time from crates.io by
  `build_vendor.py`, each `.crate` checked against `vendor-manifest.tsv`, reproducing v1's vendor
  layout byte for byte (including a v1 packing defect, Known issue 1).
- Rust 1.88.0 installed by `setup_toolchain.sh`, replaying v1's rustup steps with pinned versions
  and checked file by file against v1's toolchain; apt from a dated Debian snapshot. Base:
  `bases/rust`.
- `judge/run.sh`, `judge/result.py`: v1's eval command chain, with v1's inline Python copied byte
  for byte; `result.py` also writes `result.json`.
- `instruction.md`: v1's prompt, verbatim.

## Deviations from v1

1. Root only: no `agent` user and no `sudo` (SCHEMA rule 3).
2. The judge holds the bundle unpacked at `/judge/bundle/` instead of as a tarball in its working
   directory; the working directory starts empty, so the submission is extracted exactly as in v1.
3. v1's `pass_rate` moved to `metrics`; it was only a tie-breaker in v1.
4. apt lists are removed from the images (v1 left lists from a private mirror).
5. The workspace git commit is identical to v1's (same hash).

## Regression summary

Old (published v1 judge) and new judge on the same submissions, same host. Raw score / passed
tests.

| Submission | Old | New |
|---|---|---|
| empty | 1.4711 / 27 | same |
| historical 1 | 0.0 / 0 | same |
| historical 2 | 15.1292 / 178 | same |
| historical 3–5 | 12.9417, 20.0708, 23.8952 | same |
| historical 6 | 27.3713 / 430 | same |

Old and new agree exactly. Historical 2 was an infrastructure failure in v1 (invalid); neither
image reproduces it. The best historical score (27.37 of 310 submissions) sits just under the
ceiling set by Known issue 1.

## Known issues

Kept as in v1, so scores stay comparable. Fixing any of them changes scores and bumps `version`.

1. **The vendored `cc` crate is broken, capping the reachable score at about 28.44.** v1's bundle
   lost four source files of `cc`, so every crate that builds `cc` fails its tests immediately and
   scores 0. Repairing it offline means rewriting those files from scratch.
2. **Some hidden tests cannot compile.** With `cc` repaired, three injected test targets still fail
   to compile (async tests injected without their feature gate; proptest-style tests appended
   outside the `proptest!` block), so two crates (22 points) would score 0 whatever the
   implementation. This is hidden today by issue 1.
3. **No local scorer.** The workspace README says to run `bash score.sh` from the task root, but
   there is none in the work image.
4. The recorded empty-skeleton score (3.8189, from a macOS run) differs from the Linux images' 1.4711
   because of issue 1.
5. **Test-count inflation beats every real submission.** Passed tests are counted over
   `max(discovered, expected)`, so adding many trivial tests to a library module raises the score
   above the best historical submission.
6. **Hidden snippets can be dodged.** A snippet is skipped when the functions it defines already
   exist in the destination file, so an agent can avoid broken snippets or claim hidden test names.
7. **The submission can tamper with grading.** Test code runs as root next to the grader (the
   cross-task issue in `tasks/SCHEMA.md`); v1's and the new result parsing differ only in that case.
8. **The `task.toml` description is wrong.** It (from v1's task list) says "content-addressable
   storage"; the workspace calls CAS a "Coding Agent System".
