# openttd_transport_ai

The agent writes an OpenTTD NoAI script in Squirrel (`my_ai/info.nut`, `my_ai/main.nut`, optional
extra `.nut` files). The judge plays 5 headless OpenTTD 13.4 games (OpenGFX 7.1, map seeds 0–4, 20
game years each, the AI is the only company) through the OpenTTDLab Python package, reads the
company value from the monthly autosaves (the last quarterly value per seed) and averages it over
the seeds. Raw score = that mean (maximize). The rescale is the v1 one (`log_max`, baseline 1e5,
expert 1e9).

## Source

- Starter AI, the HTML docs and the extracted NoAI API docs, and the judge's two eval scripts: the
  task authors' repository (not public), identical by sha256 to the published v1 images.
  `eval_openttd.py` has one line changed (the path of the second script, moved out of `/tmp`).
- OpenTTD 13.4 and OpenGFX 7.1: the public OpenTTD CDN release archives, sha256-checked (the values
  in the CDN's release manifests); `environment/openttdlab-cache/` holds the two manifests.
- Python packages: the 16 versions in the published images (OpenTTDLab 0.0.75, httpx 0.28.1, …),
  hash-pinned. `environment/patch_openttdlab.py` is v1's patch that lets OpenTTDLab run offline
  from its cache.
- `judge/grade.py`: new; it writes `result.json` with v1's scoring.
- `instruction.md`: v1's prompt, verbatim. Base: `bases/python310`.

## Deviations from v1

1. Root only: no `agent` user and no `sudo` (SCHEMA rule 3).
2. The eval scripts moved from `/tmp` to `/judge/`.
3. **Built to v1's final recipe.** The latest v1 images in the public registry predate a v1 fix
   that patched OpenTTDLab and pre-filled its cache; without it the judge needed the OpenTTD CDN at
   grading time and the instruction's local test failed offline. This migration includes the fix,
   so both images work offline. Scoring is unaffected (the manifests only locate and verify the
   archives).
4. The workspace git commits are identical to v1's (same hashes).

## Regression summary

Old (published v1 judge, with network) and new judge (offline) on the same submissions, same host,
two interleaved streams, two runs each. Raw score; 0..100 in brackets.

| Submission | Old | New |
|---|---|---|
| empty (starter AI) | 0 | 0 |
| historical 1 | 79477 (0.00) | 79477 |
| historical 2–6 | 330069 (12.97), 4183978 (40.54), 15189566 (54.54), 25225913 (60.05), 40867412 (65.28) | same |

Zero spread and exact agreement on every run: games are deterministic for a given AI (AIs run on
an opcode budget per tick, not wall clock). Five of six historical v1 scores reproduce exactly;
historical 1 crashed in v1 (Known issue 3) and completes on both images here.

## Known issues

Kept as in v1, so scores stay comparable. Fixing any of them changes scores and bumps `version`.

1. **The goal API does not exist.** The instruction says to maximize
   `AICompany.GetCompanyValue(...)` and the starter calls it, but API 13 only has
   `GetQuarterlyCompanyValue` (which the shipped docs list). The starter AI dies on its first line,
   so the starter and the empty submission score 0.
2. **Wrong docs path.** The instruction points to `docs/noai_api_docs/`; the docs are in
   `docs/openttd_reference_docs/noai_api_docs/`.
3. **Infrastructure failures score 0, not invalid.** Any crash of the evaluation (including the
   game worker pool dying under memory pressure) and its own timeout become a valid 0 instead of a
   retry.
4. **The score is the last quarterly value, not the end-of-game value.** Final cash and loan are
   ignored, which rewards converting everything into assets just before the last quarter.
5. **The internal timeout equals the judge timeout** (3600 s), so a slow AI may be killed by the
   harness (invalid) before the evaluator can report 0.
6. The submission runs in OpenTTD's script VM, which has no file or process access, so the
   cross-task root issue mostly does not apply. `my_ai/` may contain any files.
7. `task.toml` says `language = "Python"` (from v1's task list); the agent writes Squirrel.
