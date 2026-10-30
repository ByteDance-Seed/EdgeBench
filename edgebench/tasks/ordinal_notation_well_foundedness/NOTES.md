# ordinal_notation_well_foundedness

Coq proof task (Coq 8.20). The agent proves well-foundedness lemmas in `task1.v` .. `task9.v`
against a fixed definition in `ChildOf.v`. The judge compiles the submitted helper files, then for
each target compiles `taskN.v` and a hidden checker `eval_taskN.v` (300 s each); a target passes
when the checker's output contains `Closed under the global context`. Raw score = sum of the
weights (1, 2, 2, 4, 4, 8, 16, 16, 32) of passed targets (0..85, maximize). The rescale is the v1
one (`linear` 0..85 -> 0..100).

## Source

- Workspace (`ChildOf.v`, `README.md`, `task1.v` .. `task9.v`), the hidden checkers
  `judge/eval_task*.v` and `judge/eval.py`: the task authors' repository (not public), identical by
  sha256 to the published v1 images.
- `judge/run.sh`, `judge/write_result.py`: new; they run `eval.py` and write `result.json` with
  v1's structured-result logic.
- `instruction.md`: v1's published prompt, verbatim. Base: `bases/coq` (`coqorg/coq:8.20`, coqc
  8.20.1).

## Deviations from v1

1. Root only: no `agent` user and no `sudo` (SCHEMA rule 3).
2. The eval script moved from `/opt/sebench/` to `/judge/eval.py` (byte-identical; it is not
   visible to the agent).
3. If `eval.py` crashes without a result, v1 recorded an unrankable score; the new grader returns
   `valid=false`.
4. The workspace git commit is identical to v1's (same hash).

## Regression summary

Old (published v1 judge) and new judge on the same submissions, same host, interleaved, two runs
each unless noted. Proof checking is deterministic. Raw score; 0..100 in brackets.

| Submission | Old | New |
|---|---|---|
| empty | 0 | 0 |
| historical 1, 2 (all targets error) | 0 | 0 |
| historical 3 | 3 (3.53) | 3 |
| historical 4, 5 | 21 (24.71) | 21 |
| historical 6 | 53 (62.35) | 53 |
| fake result block (probe) | 0 | 0 |
| spoofed pass check, one / all targets (Known issue 1) | 32 / 85 | 32 / 85 |
| `Unset Guard Checking` (probe) | 0 | 0 |

Per-target pass counts agree on every row and equal the historical v1 scores.

## Known issues

Kept as in v1, so scores stay comparable. Fixing any of them changes scores and bumps `version`.

1. **The pass check can be spoofed without a proof.** It is a substring match over the whole
   compiler output, which also contains warnings whose text the submission controls, so every
   target can pass with no proof (85/85 on both v1 and the new judge). A fix is to check the
   `Print Assumptions` result exactly (or use `coqchk`).
2. **The submission can tamper with grading.** Submitted files are compiled as root next to the
   grader, and Coq can load native plugins (the cross-task issue in `tasks/SCHEMA.md`).
3. **One broken helper zeroes the whole score.** Every submitted non-target `.v` file is compiled;
   if one never compiles, all 9 targets fail (two of six sampled v1 submissions scored 0 this way).
   The README does not warn about this, and the scratch-file exclusions are case-sensitive.
4. **Stale harness wording.** The workspace README tells the agent to run `sebench-submit`, a v1
   harness command.
