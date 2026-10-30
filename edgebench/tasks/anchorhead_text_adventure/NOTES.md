# anchorhead_text_adventure

Game-mode task. The agent plays *Anchorhead* (Michael S. Gentry, 1998, Z-machine v8) through the
harness's game HTTP API; nothing is submitted as an archive and there is no grader. Each new game
session runs in its own judge container with the harness's game server (FastAPI + jericho
`FrotzEnv`) on `/home/roms/anchor.z8`. A session's score is the in-game score when the session is
closed, evicted, reaped or ends; the run's raw score is the best session score. Anchorhead's
maximum is 100 and the rescale is the v1 one (`linear` 0..100), so the 0..100 score equals the raw
score.

## Source

- ROM: `jericho-game-suite/anchor.z8` from the public GitHub repository
  `foreverpiano/z-machine-games` at commit `bfd7544a…`, fetched as a single file and
  sha256-checked. Byte-identical to the published v1 judge image.
- Python packages: the published judge image's `pip freeze` (v1 ran an unpinned
  `pip install jericho fastapi uvicorn`), hash-pinned in `judge/requirements.txt`; jericho 3.3.1 is
  built from its sdist and its `libfrotz.so` comes out byte-identical to v1's.
- The game server and the game prompt are part of the harness, not the task; the server file is
  unchanged from v1.
- `instruction.md`: v1's prompt, verbatim. Base: `bases/python310`.

## Deviations from v1

1. Root only: no `agent` user and no `sudo` (SCHEMA rule 3). The game server already ran as root
   in v1.
2. The ROM is one pinned, hash-checked download instead of a clone of the whole repository.
3. The harness now copies its game server to `/opt/sforge/game_server_app.py` (v1:
   `/tmp/game_server_app.py`); the file is the same.
4. `[judge].cmd` is a placeholder that reports `valid=false`; the harness never calls it for game
   tasks (v1 had an empty eval command).

## Regression summary

The real game-session code of the old harness (with the published v1 judge image) and of the new
harness (with this directory) was driven through the same command sequences, twice per side,
interleaved, comparing every step's action, score, peak, move count, end state and observation.

| Sequences | Old | New |
|---|---|---|
| 5 scripted sessions (basic verbs, edge inputs, restart, quit) | 0 | 0 |
| 8 historical sessions replayed (170–2502 steps) | 66, 42, 32, 27, 26, 23, 20, 0 | same |
| one full historical 3-session run | best 16 | best 16 |
| historical session + `restart` (Known issue 1) | 0 (peak 23) | 0 (peak 23) |

Every step is identical on both sides and in the archived v1 transcripts. jericho runs Anchorhead
with a fixed seed, so play is deterministic for a given command sequence.

## Known issues

Kept as in v1, so scores stay comparable. Fixing any of them changes scores and bumps `version`.

1. **A session scores its final score, not its peak.** The published description says "scored by
   peak in-game score" and the prompt documents both `score` and `peak_score`, but a session counts
   with the score at the moment it closes; restarting after scoring archives 0. Anchorhead never
   lowers the score otherwise (no v1 session ended below its peak).
2. **Session log collisions (harness).** A race in session numbering lets two sessions share one
   log directory, so their step logs interleave and one result file overwrites the other on disk.
   Scoring is unaffected (it uses the in-memory history).
3. **Walkthrough knowledge.** Anchorhead has public walkthroughs; no network isolation stops a
   model from recalling one.
4. **Most of the prompt and the rules live in the harness.** `instruction.md` is two lines; the API
   description, tips and scoring rules come from the harness, so changing it changes this task.
5. **Harness session policy.** Each session is a new container (3–17 s to start and stop), at most
   3 sessions are live per run (a fourth evicts and scores the oldest), and idle sessions are
   reaped after 600 s.
