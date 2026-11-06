# git_rewrite_in_zig

From the public FrontierSWE task `git-to-zig`. The agent writes a Zig reimplementation of git
v2.47.0 in `/home/workspace/zig-port` (`zig build` -> `zig-out/bin/git`). The judge runs grep-based
anti-cheat checks, does a clean `zig build`, runs an strace smoke test and deletes the system git,
then builds git's own C test helpers and runs git's whole test suite (`t[0-9]*.sh`, with
`GIT_TEST_INSTALLED` pointing at the agent's binary) in parallel. Raw score = passed TAP tests /
29075, rounded to 6 decimals (maximize). The rescale is the v1 one (`linear` 0..1 -> 0..100).

## Source

- `environment/zig-port/` (the scaffold), the workspace `instruction.md`, and the judge's
  `tests/test.sh` and `compute_reward.py`: the task authors' copy of the FrontierSWE task (not
  public), identical by sha256 to the published v1 images. `judge/tests/pytest_shim.sh` comes from
  v1's build recipe, byte-identical.
- git source and test suite: the public release `git-2.47.0.tar.xz` from kernel.org
  (sha256-checked), with the same 14 paths removed as in v1 and `judge/test-lib.sh.patch` applied to
  the test suite (the only content change; it lets the tests run against an installed binary). Every
  file matches v1's trees.
- Zig 0.14.0 from ziglang.org, sha256-checked. Task apt packages from the base's Ubuntu snapshot at
  v1's versions. Base: `bases/cpp`.
- `judge/run.sh` (v1's eval command verbatim) and `judge/result.py` (new; writes `result.json` with
  v1's scoring).
- `instruction.md`: v1's prompt, verbatim.

## Deviations from v1

1. Root only: no `agent` user and no `sudo` (SCHEMA rule 3).
2. The test-suite tarball is rebuilt reproducibly: same members, modes and contents as v1's, but
   different archive bytes (v1's was packed with macOS tar metadata).
3. Seven packages of the shared base (ca-certificates, openssl CLI, sed and a few libraries) are one
   patch release newer; the regression shows no effect.
4. If no total score is printed (only if the shim crashes), v1 recorded an unrankable score; the new
   grader returns `valid=false`.
5. v1's test files stay at `/opt/tests/`, where `test.sh` expects them.
6. The workspace git commit is identical to v1's (same hash).

## Regression summary

Old (published v1 judge) and new judge on the same submissions, same host, interleaved, 2–4 runs
per side. Raw score; 0..100 = 100 × raw.

| Submission | Old | New |
|---|---|---|
| empty (scaffold) | 0.000069 | 0.000069 |
| historical 1 | 0 | 0 |
| historical 2 | 0.229132–0.229338 | 0.228719–0.229338 |
| historical 3–5 | 0.260224, 0.269923, 0.299983 | same |

Five of six submissions give the same score on every run of both images. Historical 2's variation
comes entirely from one flaky test script and takes the same set of values on both images. Two
historical submissions score one test more than in v1 on both images, a host difference.

## Known issues

Kept as in v1, so scores stay comparable. Fixing any of them changes scores and bumps `version`.

1. **Two different prompts.** Besides `instruction.md`, the workspace has the FrontierSWE
   instruction, which describes a timer daemon and image paths that do not exist here.
2. **Host-dependent score.** The test suite runs with `nproc`-way parallelism, each script under a
   120 s timeout, with no CPU limit; on a busy or small host slow scripts can lose their remaining
   tests.
3. **Flaky test.** One test script passes a varying number of tests between runs for some
   submissions.
4. **The empty scaffold scores above 0** (2 tests pass with a stub binary).
5. **The score is not capped at 1.** The denominator is a fixed constant from FrontierSWE, and the
   numerator counts every passing test line.
6. **The anti-cheat is heuristic** (text greps and a short strace check); wrapping the real git is
   mostly prevented by deleting it before the tests. Not tested adversarially.
7. **The submission can tamper with grading.** The agent's binary runs as root during the test
   suite (the cross-task issue in `tasks/SCHEMA.md`). (Not tested.)
8. The eval command's final `cat` of a log file always fails because `test.sh` deletes it (log noise
   only).
9. `task.toml` says `language = "C++"`; the submission language is Zig.
