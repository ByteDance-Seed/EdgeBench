# openrct2_theme_park_ai

The agent writes one ES5 OpenRCT2 plugin, `my_plugin.js`. The judge statically scans it with an
anti-cheat regex list, then runs OpenRCT2 v0.5.0 headless on three scenarios (large, medium,
small), each for at most 120 s wall clock. A judge-owned monitor plugin builds one "seed" ride and
logs company value, rides, staff and so on. Each scenario's score is `final companyValue /
baseline`, multiplied by an operation multiplier (open rides 0.6, staff 0.4), capped at 1.10 when
the plugin never opens a ride of its own, reduced for more than 10 action errors, and capped at
2.0. Raw score = `round(mean(norm) * 10000)` (maximize, 0..20000 in practice). The rescale is the
v1 one (`linear` 0..40000).

## Source

- Workspace (`my_plugin.js` no-op baseline, `openrct2.d.ts`, samples) and the judge assets (three
  `.park` scenarios, `eval_openrct2.py`, `openrct2_original_eval.py`): the task authors' asset
  archives (not public), identical by sha256 to the published v1 images. `eval_openrct2.py` has one
  line changed (the path of the second script, moved out of `/tmp`).
- OpenRCT2 v0.5.0: the official upstream release asset
  `OpenRCT2-v0.5.0-Linux-trixie-x86_64.tar.gz`, sha256-checked; it is the same file v1 used.
- Runtime libraries: the six Debian packages v1 installed, from the snapshot the base uses, at
  v1's versions.
- `judge/grade.py`: new; it runs v1's eval command and writes `result.json` with v1's scoring.
- `instruction.md`: v1's prompt, verbatim. Base: `bases/python310`.

## Deviations from v1

1. Root only: no `agent` user and no `sudo` (SCHEMA rule 3).
2. The eval scripts moved from `/tmp` to `/judge/`.
3. If the wrapper crashes without a total score, v1 recorded an unrankable score; the new grader
   returns `valid=false`. The empty submission and anti-cheat rejections score `valid=true, 0`,
   as in v1.
4. **The judge is offline.** v1's judge had default networking, and OpenRCT2 makes an update
   check at startup; whether the network is present slightly shifts the game timeline (see
   Regression summary).
5. The workspace git commits are identical to v1's (same hashes).

## Regression summary

Old (published v1 judge, with network as in v1) and new judge (offline) on the same submissions,
same host, interleaved, two runs each. Raw score; 0..100 in brackets.

| Submission | Old | New |
|---|---|---|
| empty, historical 1 | 0 | 0 |
| historical 2–4 | 6967, 11000, 13413 | same |
| historical 5 | 17994 (44.99) | 18018 (45.05) |
| historical 6 | 20000 (50.00) | 20000 |
| forged score (Known issue 1) | 40000 (100) | 40000 (100) |

Summaries are identical. The one difference (historical 5, one scenario) comes from the network
mode, not the image: run by hand on the same host, old and new images give the same score with
the same network mode (bridge: 18017, as in v1's historical run; no network: 18041).

## Known issues

Kept as in v1, so scores stay comparable. Fixing any of them changes scores and bumps `version`.

1. **The submission can inject a score.** The wrapper prints a sample of the plugin's own log
   before the real score line, and the first `TOTAL_SCORE` anywhere in the output wins, so a plugin
   that only logs a score line gets that score (up to 100/100) and passes the anti-cheat scan.
2. **The simulation is much shorter than the instruction says.** The instruction says about 4 game
   years; every scenario is cut at the 120 s wall-clock cap, about 72 game days. Scores reward the
   first two to three game months.
3. **Host- and environment-dependent scores.** Because runs are cut by wall-clock time, results
   move with host load and with whether the judge has network access. On one host with the same
   settings, repeated runs were identical.
4. **Value ratio above 1 without growth.** The baselines are well below the scenarios' starting
   company values, so a plugin whose company value falls can still score ratios of 1.6–2.2, and
   many runs sit at a cap. The baselines are not the no-op plugin's values, as the instruction
   implies.
5. **Static anti-cheat only.** The rules are enforced by regexes over the plugin source; bypasses
   were not tested.
6. **The submission runs next to the grader.** The plugin runs as root inside OpenRCT2 in the judge
   container (the cross-task issue in `tasks/SCHEMA.md`); issue 1 is the cheap version of that.
7. The per-scenario pass/fail labels are informational; ranking uses only the raw score.
