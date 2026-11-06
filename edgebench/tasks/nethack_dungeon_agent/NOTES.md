# nethack_dungeon_agent

The agent writes `agent.py` exporting `get_action(obs, info, step) -> int`. The judge plays 20
NetHack games (`NetHackChallenge-v0` from `nle==1.2.0`; "10 seeds × 2 repeats"), each in its own
subprocess, at most 5000 steps and 120 s wall clock per game. A game's score is the highest
in-game score seen during the episode; games with score 0, a crash or a timeout count 0. Raw score
= the mean over the 20 games (maximize). The rescale is the v1 one (`linear` 0..1000 -> 0..100).

## Source

- No upstream repository: v1 built every task file from inline scripts in its build recipe.
- `environment/workspace/agent.py` (random-walk starter) and `judge/eval_nethack.py`:
  byte-identical to v1's inline scripts and to the published v1 images. `judge/grade.py` is new and
  writes `result.json` with v1's scoring.
- `environment/requirements.lock`: nle 1.2.0 (manylinux wheel), numpy, gymnasium and their
  dependencies, plus setuptools 69.5.1, at v1's versions, hash-pinned from PyPI; every installed file
  is byte-identical to v1's. NLE's build tools (cmake, bison, flex, ninja) from the base's Debian
  snapshot at v1's versions.
- `instruction.md`: v1's prompt, verbatim. Base: `bases/python310`.

## Deviations from v1

1. Root only: no `agent` user and no `sudo` (SCHEMA rule 3).
2. The eval script moved from `/tmp/` to `/judge/` (content unchanged).
3. setuptools is a clean 69.5.1. The published v1 images also contained leftover files of
   setuptools 79.0.1 (an artifact of how they were assembled); the image v1 actually built had only
   69.5.1. Nothing in the judge imports setuptools.
4. If the eval script crashes without a total score, v1 recorded an unrankable score; the new
   grader returns `valid=false`. An empty submission grades the judge's random-walk starter, as in v1.
5. The workspace git commits are identical to v1's (same hashes).

## Regression summary

The games cannot be seeded (Known issue 1), so scores vary run to run on both images. Old
(published v1 judge) and new judge, same host, interleaved, three runs each. Raw score: mean
(range).

| Submission | Old | New |
|---|---|---|
| empty (starter) | 0.85 (0.25–2) | 1.33 (0.7–2.55) |
| historical 1 | 0 | 0.08 (0–0.2) |
| historical 2 | 226.5 (205.3–262.3) | 248.0 (204.2–289.85) |
| historical 3 | 237.7 (191.2–296.15) | 220.0 (200.2–231) |
| historical 4 | 415.9 (317.65–585.15) | 530.0 (435.8–617.05) |
| historical 5 | 438.9 (429.4–456.3) | 486.9 (389.7–536.95) |
| historical 6 | 612.5 (410.7–855.65) | 511.3 (477.4–561.65) |

Every mean difference is smaller than the run-to-run range on one side, with mixed signs. The exact
equivalence check is separate: with seeds forced by a test script, the published and new judge
images play bit-identical games (15 of 15 trajectories), and the NLE runtime is byte-identical.

## Known issues

Kept as in v1, so scores stay comparable. Fixing any of them changes scores and bumps `version`.

1. **The games are not seeded, so the score is a random 20-game sample.** The eval's seeding call
   silently fails, so every game is a fresh random dungeon and character; the same submission moves
   by tens to hundreds of raw points between runs. The instruction's skeleton has the same no-op, so
   agents cannot reproduce a game locally either.
2. **NetHack reads the wall clock.** Moon phase, Friday the 13th and night time change Luck and some
   events, so the expected score also depends on when the judge runs.
3. **The submission can forge game results.** Each game's subprocess reports its result as a line
   on standard output and the parent takes the last one; agent code can write such a line itself
   and score 100/100 with a no-op agent.
4. **The submission can tamper with grading.** Agent code runs as root next to the grader (the
   cross-task issue in `tasks/SCHEMA.md`); issue 3 is the cheap version.
5. **The static "hack" check is a regex** over `agent.py` that zeroes the whole submission on a
   match; it is easy to evade and can fire on a harmless comment.
6. **A game scores its peak, not its final score,** so dying right after a high point costs nothing.
   The instruction only says "maximize game score".
7. **Wall-clock timeouts.** A slow agent, or a loaded host, loses whole games (120 s each, no CPU
   limit).
8. The instruction does not state the number of games, the step limit or the per-game time limit.
