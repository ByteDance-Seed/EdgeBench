# tryst_text_adventure

Game-mode task. The agent plays *Tryst of Fate* (G. M. Zagurski, release 205, Z-machine v5)
through the harness's game HTTP API; nothing is submitted as an archive. Each game session runs
in its own judge container with the harness's game server (FastAPI + jericho `FrotzEnv`) on
`/home/roms/tryst205.z5`. A session's score is the in-game score when the session is closed or the
game ends; the run's raw score is the best session score. jericho reports a maximum of 350; the
rescale is the v1 one (`linear` 0..350), so 0..100 = raw / 3.5.

This task is a sibling of `anchorhead_text_adventure` and `trinity_text_adventure` (same recipe,
different ROM and rescale bound).

## Source

- ROM: `jericho-game-suite/tryst205.z5` from the public GitHub repository
  `foreverpiano/z-machine-games` at commit `bfd7544a…`, fetched as a single file and
  sha256-checked. Byte-identical to the published v1 judge image.
- Python packages: the published judge image's `pip freeze` (v1 ran an unpinned
  `pip install jericho fastapi uvicorn`), hash-pinned in `judge/requirements.txt`; jericho 3.3.1 is
  built from its sdist and its `libfrotz.so` comes out byte-identical to v1's.
- The game server is part of the harness, not the task, and is unchanged from v1.
- `instruction.md`: v1's prompt, verbatim. Base: `bases/python310`.

## Deviations from v1

1. Root only: no `agent` user and no `sudo` (SCHEMA rule 3).
2. The ROM is one pinned, hash-checked download instead of a clone of the whole repository.
3. The harness now copies its game server to `/opt/sforge/game_server_app.py` (v1:
   `/tmp/game_server_app.py`); the file is the same.
4. `[judge].cmd` is a placeholder that reports `valid=false`; the harness never calls it for game
   tasks (v1 had an empty eval command).

## Regression summary

The real game-session code of the old harness (with the published v1 judge image) and of the new
harness (with this directory) was driven through the same command sequences, twice per side,
interleaved, recording score, peak, move count, end state and a hash of every observation.

| Sequences | Old | New |
|---|---|---|
| 5 scripted sessions (basic verbs, edge inputs, restart, quit) | 0 | 0 |
| score then restart / score then undo (scripted) | 0 (peak 75) / 75 | same |
| 12 historical sessions replayed (152–2509 moves) | 215, 215, 210, 195, 135, 135, 135, 125, 75, 70, 50, 15 | same |
| one full historical 7-session run | best 30 | best 30 |

Every replay is step-for-step identical on both sides, and every historical replay is also
identical to the archived v1 transcript. jericho runs the game with a fixed seed, so play is
deterministic for a given command sequence.

## Known issues

Kept as in v1, so scores stay comparable. Fixing any of them changes scores and bumps `version`.

1. **A session scores its final score, not its peak.** If the agent loses points (for example by
   restarting), the session keeps the lower value, although the prompt documents both `score` and
   `peak_score`. No v1 session ended below its peak, but it is easy to trigger.
2. **The ending or death ends the session.** The harness closes the session with the score reached
   so far. Since play is deterministic, the agent can open a new session and replay a known-good
   prefix.
3. **Session log collisions (harness).** Two sessions can share one session log directory, so a
   few logs contain more steps than their session and one result file can overwrite another on
   disk. Scoring is unaffected.
4. **Concurrent steps are logged out of order (harness).** Parallel step requests on one session
   can be recorded in a different order than they ran, so such transcripts cannot be replayed.
   Scoring is unaffected.
5. **Walkthrough knowledge.** Tryst of Fate is part of the public Jericho suite and has published
   walkthroughs; no network isolation stops a model from recalling one.
6. **Most of the prompt and the rules live in the harness.** `instruction.md` is two lines; the
   game prompt, session limits (at most 3 live sessions, idle sessions reaped after 600 s) and the
   scoring rule are harness policy, not task files.
