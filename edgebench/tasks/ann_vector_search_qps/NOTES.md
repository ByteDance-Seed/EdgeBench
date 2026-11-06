# ann_vector_search_qps

The agent improves `ann_benchmarks/algorithms/custom/` (a `Custom(BaseANN)` class plus its
`config.yml`) inside a checkout of ann-benchmarks. The judge runs
`python run.py --local --algorithm custom --dataset sift-128-euclidean -k 10 --runs 1 --run-disabled`
on SIFT-1M (1M × 128 train vectors, 10K queries), reads every per-config result file, and computes
Recall@10 against the ground truth and QPS = 1 / mean(per-query time). Configs with recall ≥ 0.95
are `OK`; raw score = the highest QPS among them, 0 if none (maximize). The rescale is the v1 one
(`log_max`, baseline 3108, expert 21472).

## Source

- Workspace: the public GitHub repository `foreverpiano/ann-benchmarks` at `f402b2cc…`
  (2025-06-09, an upstream `erikbern/ann-benchmarks` commit), exported with `git archive`; the
  starter `custom/` files and `judge/eval_ann_search.py` are byte-identical to v1's inline scripts.
  Everything matches the published v1 images.
- Blob `environment/blobs/sift-128-euclidean.tar.gz` (154 MB packed; sha256 in `task.toml`): the
  public ann-benchmarks.com SIFT-1M file, byte-identical to v1's copy and to a fresh download.
- `environment/requirements.lock`: the 68 package versions v1's unpinned installs resolved to
  (faiss-cpu 1.14.2, numpy 2.2.4, h5py 3.13.0, scikit-learn 1.6.1, …), hash-pinned from PyPI; the
  installed files and metadata are identical to v1's. Base: `bases/python310`.
- `judge/grade.py`: new; it writes `result.json` with v1's scoring.
- `instruction.md`: v1's prompt, verbatim.

## Deviations from v1

1. Root only: no `agent` user and no `sudo` (SCHEMA rule 3).
2. The eval script moved from `/tmp/` to `/judge/` (content unchanged).
3. The dataset comes from a blob instead of a build-time download (same bytes, checked).
4. If the eval script crashes without a total score, v1 recorded an unrankable score; the new
   grader returns `valid=false`. A failing run is `RE`, raw 0, valid, as in v1.
5. The workspace git commits are identical to v1's (same hashes).

## Regression summary

Old (published v1 judge) and new judge on the same submissions, same shared host, interleaved,
three runs each. Raw score (best valid QPS) per run; 0..100 in brackets.

| Submission | Old | New |
|---|---|---|
| empty, historical 1 (starter config fails) | 0 | 0 |
| historical 2 | 10667 / 10156 / 10967 (61.3–65.2) | 10885 / 10392 / 10333 (62.2–64.8) |
| historical 3 | 2940 / 3330 / 3280 (0–3.6) | 2974 / 3236 / 3325 (0–3.5) |
| historical 4 | 2999 / 3339 / 3488 (0–6.0) | 3289 / 2835 / 3262 (0–2.9) |
| historical 5 | 45189 / 47299 / 47202 (100) | 46874 / 47658 / 47982 (100) |

Every mean difference is within the old judge's own spread, and per-config statuses and summaries
are identical. Historical 3 and 4 score about 3k QPS on both images versus 12.5k and 17.6k in v1,
because they use one thread per host core and collapse on a loaded 192-core host (Known issue 1).

## Known issues

Kept as in v1, so scores stay comparable. Fixing any of them changes scores and bumps `version`.

1. **The score is wall-clock QPS on whatever host runs the judge.** There is no CPU pinning or
   limit, and FAISS/OpenMP default to every visible core, so solutions that do not pin threads
   collapse under load; single-query QPS also depends on the CPU model. Historical scores are not
   reproducible across machines.
2. **The ground truth is readable during the run.** While the algorithm runs, the judge keeps the
   removed ground-truth array in a temporary file in the same container, and the static scan only
   checks a few patterns in `module.py`. A submission that reads it gets perfect recall.
3. **The submission can inject a score.** When `run.py` fails, the judge prints the end of the run
   log before its own score line, and the first `TOTAL_SCORE` wins.
4. **The static scan is narrow.** It reads only `custom/module.py`; other `.py` files and shipped
   bytecode caches are not scanned.
5. **The submission can tamper with grading.** Submitted code runs as root next to the grader (the
   cross-task issue in `tasks/SCHEMA.md`).
6. **The ground truth is in the workspace.** The dataset file the agent sees includes the neighbors;
   the instruction only forbids using them at query time.
7. **The shipped starter does not run.** Its `config.yml` uses an old format that this ann-benchmarks
   commit rejects, so the local run and the judge fail until the agent rewrites it; the brute-force
   baseline is never measured.
8. The instruction's reference numbers (3108 -> 21472 QPS) are also the rescale anchors, measured on
   unknown hardware.
