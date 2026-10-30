# college_english_exam_bank

> **This task is graded by an LLM.** The grader runs the Codex CLI as a grading agent against an
> OpenAI-Responses-compatible endpoint. The judge needs `SFORGE_JUDGE_API_KEY`,
> `SFORGE_JUDGE_API_BASE_URL` (default `https://openrouter.ai/api/v1`) and `SFORGE_JUDGE_MODEL`
> (v1 used `gpt-5.5-2026-04-24`), passed through `SFORGE_JUDGE_EXTRA_ENV`, and network access
> (`[judge] internet = true`). **Without them every submission, good or empty, is `valid=false`,
> score 0.** Scores are not deterministic: v1 scored the same archive 11.0 and 17.5.

The agent reads `task_instruction.md` (Chinese) and builds a five-paper (A to E) final-exam bank
for a first-year college English course from the attached materials: 22 files in the workspace
root (for each paper the exam and the answer key, each as Word and PDF, plus a blueprint workbook
and a cross-paper overlap self-check). The judge runs Codex with `rubrics.json` (12 rules, 100
points) and the reference materials in `scoring/`; Codex returns per-rule scores that the grader
reconciles with the rubric. Raw score = `100 * raw_total / max_total` (0..100, maximize); v1 had
no rescale.

## Source

- Workspace inputs and the judge's `scoring/` materials: the task authors' repository (not
  public), identical by sha256 to the published v1 images.
- Blob `environment/blobs/ppt_rar.tar.gz` (577 MB, sha256 in `task.toml`): the lecture-slides
  archive `附件4：PPT.rar` from the same repository, which v1 placed both at the top level and in
  `attachments/`. Download it with `sforge build` (SCHEMA rule 4).
- `judge/scoring/grade_with_codex.py`: the version shipped in the published v1 judge image (it
  reads the `SFORGE_JUDGE_*` variables), minus two private IP addresses (Deviation 3).
- Python packages: the 28 versions in the published images, hash-pinned wheels from PyPI. Codex
  CLI 0.138.0 (the version v1 got) from the npm registry tarballs, sha256-checked. apt packages
  from the Debian snapshot of v1's build day at v1's versions. Base: `bases/python`.
- `judge/run.sh`, `judge/emit_result.py`: new; they run v1's eval command and write
  `result.json` with v1's structured-result logic.
- `instruction.md`: v1's published prompt, verbatim.

## Deviations from v1

1. Root only: no `agent` user and no `sudo` (SCHEMA rule 3).
2. No pip or npm caches in the images; Codex is unpacked from verified tarballs. No behaviour
   change.
3. Two private IP addresses (v1 infrastructure) were removed from the `NO_PROXY` list the grader
   builds for Codex. Nothing else in the grader changed.
4. **Judge network and key.** The v1 judge had default networking; the harness now gives the
   judge no network and no key unless the operator provides them (see the banner).
5. If the grader crashes without printing a result, v1 recorded an unrankable score; the new
   grader returns `valid=false`. The grader's own failure results (no key, Codex failure or
   timeout, unparsable output) are `valid=false, 0`, as in v1.
6. The workspace git commit is identical to v1's (same hash).

## Regression summary

The model call cannot be re-run deterministically (Known issue 1). Two checks on the same host,
old (published v1 judge) vs new:

- **As shipped, no key:** empty submission and 5 historical submissions are `valid=false, 0` on
  both sides with the same summary.
- **Replay:** `codex` replaced by a stub that returns the grading JSON recorded in each
  historical submission's v1 log; everything else (filtering, manifests, parsing, rubric
  reconciliation, result) ran for real, two runs per side.

| Submission | v1 historical | Old | New |
|---|---|---|---|
| historical 1 (empty archive) | 0.0 | 0.0 | 0.0 |
| historical 2 | 11.0 | 11.0 | 11.0 |
| historical 3 (same archive as 2) | 17.5 | 17.5 | 17.5 |
| historical 4–6 | 21.0, 30.5, 51.5 | same | same |

All replay runs are valid, and old, new and historical summaries agree.

## Known issues

Kept as in v1, so scores stay comparable. Fixing any of them changes scores and bumps `version`.

1. **Nondeterministic LLM judge.** The score is whatever the model decides under the rubric; the
   same archive scored 11.0 and 17.5 in v1, so best-of-run rewards resubmitting. The model, the
   endpoint and the Codex version all affect the score, and the task does not pin the model.
2. **Unscorable without operator configuration** (Deviation 4).
3. **Empty submissions still call the model.** The grader's report directory also holds the
   inputs and the reference materials, so its "no files" shortcut never fires and the model is
   paid to award 0.
4. **Prompt-injection surface.** The grading agent runs as root with its sandbox and approvals
   disabled and with network access, next to the reference answers. Text inside submitted
   documents can address the grader, and the grading prompt allows it to fetch URLs cited by the
   submission.
5. **Timeouts collide.** Each Codex attempt may take up to 900 s, which equals the judge timeout,
   so a slow model call becomes a judge timeout (invalid) instead of the grader's own timeout
   result.
6. **Almost no feedback.** The grader replaces the model's feedback with short generic sentences.
7. **Missing tooling.** The task requires PDFs of the Word files, but the work image has no
   docx-to-PDF converter; the agent (which has internet) must install one or generate PDFs itself.
8. **Grader output can be spoofed or voided.** The grader prints the end of Codex's error output,
   and quotes evidence from the submission, before its own result, and the parser takes the first
   result block. Text that reaches those places can replace the score or make the result
   unrankable.
9. `pass_rate` in the grader's output (score/100) is ignored; the harness ranks by score only.
