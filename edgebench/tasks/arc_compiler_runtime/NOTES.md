# arc_compiler_runtime

The agent implements the JavaScript modules of a compiler and runtime for "Arc", a small language
described by `CHEATSHEET.md`, `TASK.md`, `problem.md`, `spec/` and `docs/` (lexer, parser, type
checker, interpreter, JS code generator, stdlib, toolchain helpers) under `compiler/src/`. Only
`compiler/src/` is submitted. The judge copies the workspace (with the submission extracted over
the starter files) into a temporary directory, adds 21 hidden TypeScript test suites (448 cases)
and runs each with `tsx` under `timeout 90`. Raw score = `100 × WEIGHTED_PASSED / WEIGHTED_TOTAL`
(per-suite weights 2–8, weighted total 2970; maximize). The rescale is the v1 one (`linear`
0..100), so the 0..100 score equals the raw score.

## Source

- Workspace (`agent-start/`, 156 files, and `problem.md`) and the judge's `score_hidden.sh`: the
  task authors' repository (not public), identical by sha256 to the published v1 images.
- Public smoke tests (`tests/public-smoke/`) and the 21 hidden suites: taken from the published v1
  images (the authors' test archive was not used directly), identical by sha256.
- `node_modules/` comes from `npm ci` with the committed `package-lock.json` (every entry from the
  npm registry with an integrity hash), as in v1. Node.js 20.19.2 and npm 9.2.0 from a dated Debian
  snapshot; all 361 packages that step adds are checked against v1's versions. Base: `bases/python`.
- `judge/eval_hidden.py` is v1's inline eval program, verbatim; `judge/run.sh` and
  `judge/write_result.py` are new and write `result.json` with v1's structured-result logic.
- `instruction.md`: v1's prompt, verbatim.

## Deviations from v1

1. Root only: no `agent` user and no `sudo` (SCHEMA rule 3).
2. **v1's parse is kept exactly.** In v1, a fixed trace line of the eval command always made the
   first result-marker strategy fail, so v1 effectively parsed the first JSON line instead. The new
   grader turns that strategy off to get the same result.
3. If the eval program itself crashes (for example its 1400 s timeout), v1 recorded an unrankable
   score; the new grader returns `valid=false`. Infrastructure failures inside the scorer are
   `valid=false, 0` on both.
4. The workspace git commit is identical to v1's (same hash), which also proves the installed
   `node_modules/` tree is identical (v1 committed it).

## Regression summary

Old (published v1 judge) and new judge on the same submissions, same host, interleaved, two runs
each. The grader is deterministic. Raw score (= 0..100).

| Submission | Old | New |
|---|---|---|
| empty (starter files) | 35.59 | 35.59 |
| historical 1 | 0.00 | 0.00 |
| historical 2–5 | 51.21, 53.50, 53.74, 79.80 | same |
| forged result (Known issue 2) | 100 | 100 |

Every row matches exactly, including raw and weighted counts, and equals the historical v1 scores.

## Known issues

Kept as in v1, so scores stay comparable. Fixing any of them changes scores and bumps `version`.

1. **The starter is not a stub; an empty submission scores 35.59.** `compiler/src/runtime.js` is a
   working regex-based implementation that passes all public smoke tests, although `TASK.md` says
   the starter scores 0. Submitting nothing beats some historical submissions.
2. **The submission can forge its result.** The scorer echoes a failing suite's output before the
   eval program's own result, and the parser takes the first result block, so submitted code that
   prints one and exits wins.
3. **The submission can read the hidden tests.** The hidden suites are copied next to the
   submission and run in the same process, so the expected values are readable at run time.
4. **Starter files cannot be deleted.** The archive is extracted over the starter `compiler/src/`,
   so a starter module the submission leaves out stays in place.
5. **The submission can tamper with grading.** Submitted code runs as root next to the grader (the
   cross-task issue in `tasks/SCHEMA.md`).
6. **Metadata.** `task.toml` says `language = "Python"` and the description mentions a "TypeScript
   compiler pipeline"; the deliverable is JavaScript modules on Node 20.
7. One timeout or runner crash in any of the 21 suites makes the whole submission invalid rather
   than 0 for that suite.
