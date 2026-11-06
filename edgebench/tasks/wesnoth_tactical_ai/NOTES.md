# wesnoth_tactical_ai

The agent writes a Lua/WML AI (`my_custom_ai.cfg` plus optional `*.lua`) for The Battle for
Wesnoth 1.18. The judge statically scans the submitted files for forbidden APIs, installs the AI
as an add-on (each `.lua` gets a sandbox header), and plays 60 headless games: 3 maps x 10 seeds
x 2 repeats against the default RCA AI, at most 50 turns and 180 s per game.
Raw score = `round(80 * win_rate + 20 * avg_efficiency)` (integer 0..100, maximize), where
efficiency = `min(1, baseline_turns / turns)` averaged over wins. The rescale is the v1 one
(`linear` 0..100), so the 0..100 score equals the raw score.

## Source

- No upstream repository: v1 built everything from Debian packages and two inline scripts in its
  build recipe.
- `environment/workspace/my_custom_ai.cfg` and `judge/eval_wesnoth.py`: byte-identical to v1's
  inline scripts and to the published v1 images. `judge/grade.py` is new and writes `result.json`
  with v1's scoring logic.
- `instruction.md`: v1's prompt, verbatim.
- Wesnoth `1:1.18.5-1` (`wesnoth-1.18`, `wesnoth-1.18-data`) from the Debian snapshot of
  2026-06-05, the day v1 installed it. Every file under `/usr` and every package version matches
  the published v1 images. Base: `bases/python310`.

## Deviations from v1

1. Root only: no `agent` user and no `sudo` (SCHEMA rule 3). In the work image `HOME` moves from
   `/home/agent` to `/root`, so an agent testing locally installs its add-on under
   `/root/.config/wesnoth-1.18/data/add-ons/my_ai/`. The v1 judge already ran as root, so grading
   is unchanged.
2. The eval script moved from `/tmp/eval_wesnoth.py` to `/judge/eval_wesnoth.py` (content unchanged).
3. If the grader prints no total score (only when the eval script crashes), v1 recorded an
   unrankable score; the new grader returns `valid=false`. Empty submissions, the starter config
   and detected hacks score `valid=true, 0`, as in v1.
4. The workspace git repository is identical to v1's (same commits and hashes); only the index
   stat cache differs.

## Regression summary

Old (published v1 judge) and new judge on the same submissions, same host, interleaved. Raw score
(= 0..100). Game outcomes are random (Known issue 1), so scoring submissions ran 8 times per side.

| Submission | Old runs: range (mean) | New runs: range (mean) |
|---|---|---|
| empty, starter config, static hack | 0 | 0 |
| historical 1 | 57–85 (73.2) | 60–77 (69.2) |
| historical 2 | 67–78 (72.4) | 70–84 (75.1) |
| historical 3 | 62–80 (70.2) | 69–83 (75.6) |
| historical 4 | 70–79 (75.5) | 66–85 (77.2) |
| historical 5 | 64–80 (72.0) | 69–77 (73.4) |

Deterministic rows match exactly, including the summaries. For the scoring AIs the per-run
standard deviation is 3–8 points on both images; per-submission mean differences (−4.0 to +5.4)
are within about two standard errors, and the pooled means over 40 runs per side are 72.7 (old)
and 74.1 (new). Together with identical files and packages, this is agreement within v1's own
noise.

## Known issues

Kept as in v1, so scores stay comparable. Fixing any of them changes scores and bumps `version`.

1. **Games are not reproducible, so the score is noisy.** The same map and seed do not replay the
   same game, and the two repeats of a pair often disagree. A ~70-point AI has a run-to-run
   standard deviation of about 4–6 points (spread up to 23 points over 4 runs); one historical
   submission scored 88 once in v1 but 64–80 in 16 re-runs. The source of the randomness was not
   identified.
2. **The forbidden-API scan and the sandbox cover only top-level `.lua` files.** Lua code written
   inline in `my_custom_ai.cfg` is neither scanned for those APIs nor sandboxed. (Found by reading
   the code; not exercised.)
3. **The scan is a plain text match.** A comment or string that merely mentions a forbidden name
   (including in unused draft `.cfg`/`.lua` files left in the directory) zeroes the score. In the
   other direction, the instruction promises that obfuscated access is detected, but only a few
   routes are blocked at run time.
4. **Only top-level files are installed.** Lua files in subdirectories are not copied into the
   add-on, so an AI that uses them fails to load and loses every game.
5. **Wall-clock limits.** The 60 games run sequentially under a 900 s judge timeout. An AI that
   averages more than about 15 s per game makes the whole judge time out (unrankable instead of
   scored); the margin depends on host speed and load.
6. **Early wins zero the submission.** Any win before turn 3 is treated as a hack. Such wins are
   implausible on these maps, so this is mainly a note.
7. **The submission can tamper with grading.** Submitted code runs as root next to the grader
   (the cross-task issue in `tasks/SCHEMA.md`), and issue 2 leaves inline Lua unsandboxed.
8. `task.toml` says `language = "Python"` (from v1's task list); the agent actually writes Lua and
   WML.
