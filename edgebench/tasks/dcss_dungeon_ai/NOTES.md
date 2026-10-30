# dcss_dungeon_ai

Dungeon Crawl Stone Soup 0.28 (Debian `crawl` console build). The agent writes a Lua bot as two rc
files, `my_bot.rc` and `my_bot_include.rc`, in `/home/dcss_agent`. The judge plays 5 fixed hidden
seeds in parallel, each as a Minotaur Berserker with a mace inside a GNU `screen` session, with a
900 s wall-clock budget per game; at the deadline it force-abandons the game so crawl writes a
morgue. A game's score is DCSS's own score from its morgue, 0 if no morgue appears or the morgue
mentions wizard or explore mode. Raw score = mean over the 5 games, rounded to 0.1 (maximize). The
rescale is the v1 one (`log1p_max`, baseline 400, upper 50000).

## Source

- No upstream repository: v1 built every task file from inline scripts in its build recipe.
- `environment/workspace/{my_bot.rc,my_bot_include.rc}` (the baseline bot),
  `environment/dcss-eval` (the agent-side local evaluator, seeds 1..100) and `judge/eval_dcss.py`:
  byte-identical to v1's inline scripts and to the published v1 images. `judge/grade.py` is new and
  writes `result.json` with v1's structured-result logic.
- `crawl` 0.28.0, `crawl-common`, `liblua5.1-0` and `screen` from the Debian snapshot the base
  uses, at v1's versions; all their files are identical to v1's.
- `instruction.md`: v1's prompt, verbatim. Base: `bases/python310`.

## Deviations from v1

1. Root only: no `agent` user and no `sudo` (SCHEMA rule 3). `HOME` moves from `/home/agent` to
   `/root`, so the local evaluator keeps its scratch in `/root/.dcss-eval`.
2. The eval script moved from `/tmp/` to `/judge/` (content unchanged).
3. `valid` keeps v1's rule that all 5 games need an accepted morgue. If no score is printed at all,
   v1 recorded an unrankable score; the new grader returns `valid=false`.
4. The workspace git commits are identical to v1's (same hashes).

## Regression summary

Old (published v1 judge) and new judge on the same submissions, started together on the same
shared host. Raw score; 0..100 in brackets.

| Submission | Old | New |
|---|---|---|
| empty (baseline bot), 10–11 runs | 12.6–40.0 (mean 0.91) | 12.2–40.0 (mean 1.04) |
| historical 1 | 0.0 | 0.0 |
| historical 2 | 81.4 (3.83) | 81.4 |
| historical 3 | 1170.6 (28.28) | 1170.6 |
| historical 4, 4–5 runs | 2400.8–3408.8 (mean 44.05) | 1556.0–5211.2 (mean 44.04) |

Deterministic bots match exactly per game, old = new = v1. The nondeterministic ones (the baseline
and historical 4) have the same set of per-game outcomes on both sides, overlapping ranges, and
0..100 means that differ by 0.13 and 0.01. All runs were valid.

## Known issues

Kept as in v1, so scores stay comparable. Fixing any of them changes scores and bumps `version`.

1. **Nondeterministic games.** Each game has a 900 s wall-clock budget, and a background thread
   types dismiss keys into the session every 1.5 s regardless of the game state, so identical bots
   on identical seeds can diverge (v1 scored two byte-identical submissions 1170.6 and 200.0; one
   bot ranges from 1556 to 5211 on the same host). Bots that die early are often reproducible. The
   instruction's claim that repeated submissions are broadly comparable holds only for some bots.
2. **No CPU or memory limits.** Five games run in parallel, so the turn rate, and the score of bots
   that survive the full 900 s, depends on host speed and load.
3. **One failed game invalidates the submission** instead of counting as 0.
4. **The hidden seeds are in the judge script,** now public with the task directory; the work
   image does not contain them.
5. **An empty submission is not 0**: the judge image contains the baseline bot, which plays instead.
6. **The ban check is a plain text match on the whole morgue,** so any bot message containing
   `WIZARD` zeroes that game (it can only lower a score).
7. The bot runs inside crawl as root, but crawl's client Lua has no file API, so the cross-task
   tampering route was not found to apply.
8. **Harness-specific wording.** The instruction and judge summary mention `sforge-submit`,
   `sebench-submit`, "Pass rate" and "Passed" from the v1 harness UI; `task.toml` says
   `language = "Python"` although the agent writes Lua.
9. The judge prepends an unused `MAX_TURNS` variable to the rc file; the instruction correctly says
   there is no turn limit.
