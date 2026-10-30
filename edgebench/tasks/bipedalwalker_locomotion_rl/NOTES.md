# bipedalwalker_locomotion_rl

CPU-only locomotion RL. The agent trains a policy in the work container and submits
`submission/policy.pth` (optionally `submission/policy.py` for a custom architecture). The judge
does not train: it loads the checkpoint and runs 10 deterministic episodes on BipedalWalker-v3
and 10 on BipedalWalkerHardcore-v3 with fixed seeds, then computes
`strict_score = 2.5 * (engineering checks passed, 0..4) + 0.2 * raw_loco_score`, capped at 30,
where `raw_loco_score = 0.4 * clip(normal/300) * 100 + 0.6 * clip((hardcore+100)/400) * 100`.
Raw score = the strict score (maximize, 0..30). The rescale is the v1 one (`linear` 0..100, the
identity), so the best possible 0..100 score is 30.

## Source

- Workspace (README, task prompt, baseline, envs, `submission/` starter files) and the judge's
  `sebench_eval.py` and `eval/`: the task authors' asset archive (not public), identical by sha256
  to the published v1 images.
- `environment/requirements.lock`, `environment/requirements-sdist.lock`: the exact wheels and the
  one sdist (`box2d-py`) v1 installed, sha256-pinned; torch `2.3.1+cpu` comes from the public
  PyTorch CPU index. `environment/pipinstall.sh` runs v1's four `pip install` lines as one hashed
  install.
- `judge/run.sh`, `judge/emit_result.py`: new; they run v1's eval command verbatim and write
  `result.json` with v1's structured-result logic.
- `instruction.md`: v1's prompt, verbatim. Base: `bases/python`.

## Deviations from v1

1. Root only: no `agent` user and no `sudo` (SCHEMA rule 3).
2. Hash-pinned installs instead of unpinned `pip install`; the installed files are the same.
   `box2d-py` is built from its sdist as v1 did. The resulting `_Box2D` extension differs only in
   debug info and build id (v1's own two images differ the same way); with those stripped, v1's
   and the new binary are byte-identical.
3. If the evaluator crashes before printing its result, v1 recorded an unrankable score; the new
   grader returns `valid=false`.
4. The workspace git commit is identical to v1's (same hash).

## Regression summary

Old (published v1 judge) and new judge on the same submissions, same host, interleaved, two runs
each. Raw score (= 0..100).

| Submission | Old | New |
|---|---|---|
| empty | 2.5 | 2.5 |
| garbage `policy.pth` | 5.0 | 5.0 |
| historical 1 (no `policy.pth`) | 2.5 | 2.5 |
| historical 2–6 | 19.27, 20.66, 21.6, 24.41, 30.0 | same |

Every row matches exactly on every run, and also matches the historical v1 scores. Per-episode
rewards of 5 historical policies x 20 episodes are bit-identical between the old and new judge.

## Known issues

Kept as in v1, so scores stay comparable. Fixing any of them changes scores and bumps `version`.

1. **The submission can fake its rewards.** The evaluator reads the episode reward from the
   output of a subprocess that also imports the submitted `policy.py`, so the submitted code can
   print a reward of its choice and reach the maximum score with an untrained checkpoint.
2. **The submission can tamper with grading.** `policy.py` is executed and the checkpoint is
   unpickled as root in the judge container (the cross-task issue in `tasks/SCHEMA.md`).
3. **Score ceiling at 30/100.** The strict score caps at 30 and the rescale is the identity, so no
   0..100 score exceeds 30, and historical runs already reach the cap. Strong submissions are not
   distinguished.
4. **Nonzero floor.** An empty submission scores 2.5 and any unloadable `policy.pth` scores 5.0.
5. **Few, fixed episodes.** Only 10 episodes per environment on fixed seeds; the evaluator also
   reads environment variables that would change the episode count and seeds if the judge set them.
6. **Wall-clock timeouts.** Each environment's evaluation is killed after 300 s and then counts as
   reward −200, so a very slow policy can lose score depending on the host. No historical
   submission came close.
7. **Stale harness wording.** The workspace README, task prompt and `train.py` tell the agent to
   run `sebench-submit`, a v1 harness command.
8. `envs/locomotion_env.py` and `baseline/` are not used by the judge, which evaluates on stock
   gymnasium environments.
