# graph_node_classification

Semi-supervised node classification on the heterophilous Squirrel graph (WikipediaNetwork, 5201
nodes, 217073 edges, 2089 features, 5 classes; the 10 official Geom-GCN 60/20/20 splits). The agent
writes `solution/solution.py` (class `Solution` with `solve(input_data)`, CPU only, PyTorch
2.2.2+cpu). The judge runs `solve` once per split in 4 forked workers and per split computes
`final = 0.4 macro_F1 + 0.3 micro_F1 + 0.2 balanced_acc + 0.1 (1 - ECE) - 0.01 ln(solve seconds)
- 0.001 max(0, peak_tracemalloc_MB - 4096)`. Raw score = mean `final` over the 10 splits
(maximize). A static check rejects GPU use (`valid=false`). The rescale is the v1 one (`linear`
0..1 -> 0..100).

## Source

- Starter solution and template, and the judge's `runner.py`, `verifier.py`, `config.yaml`,
  `judge_eval.py`: the task authors' repository (not public), identical by sha256 to the
  published v1 images.
- `environment/workspace/README.md`, `solution/problem.md`: the English versions shipped in the
  published v1 images (the repository has Chinese versions).
- Blob `judge/blobs/squirrel_data.tar.gz` (5 MB packed, 626 MB unpacked; sha256 in `task.toml`): the
  `data/` directory v1 unzipped into the judge (per-split JSONL files with labels, the graph, and
  the raw Geom-GCN files), byte-identical to v1 and re-checked against its own `checksums.sha256`
  at build time.
- `environment/requirements.lock`: torch 2.2.2+cpu (public PyTorch CPU index) and its 8
  dependencies at v1's versions, hash-pinned. Base: `bases/python`.
- `judge/run.sh`, `judge/emit_result.py`: new; they run v1's eval command unchanged and write
  `result.json` with v1's structured-result logic.
- `instruction.md`: v1's prompt, verbatim.

## Deviations from v1

1. Root only: no `agent` user and no `sudo` (SCHEMA rule 3).
2. A judge timeout leaves no result (invalid); v1 recorded an unrankable score. Same ranking
   effect. The grader's own failure cases are `valid=false, 0` in both.
3. The workspace git commit is identical to v1's (same hash).

## Regression summary

Old (published v1 judge) and new judge on the same submissions, same host, run concurrently,
two runs per side. Raw score; `overall` = the accuracy part without the time term.

| Submission | Old raw | New raw | Old / new overall |
|---|---|---|---|
| starter template | 0.29244–0.29346 | 0.29249–0.29369 | 0.332624 / same |
| historical 1 | 0.57098–0.57113 | 0.57069–0.57263 | 0.608532 / same |
| historical 2 | 0.72031–0.72068 | 0.72093–0.72172 | 0.7788–0.7789 / 0.7795–0.7799 |
| historical 3 | 0.72362–0.72366 | 0.72417–0.72552 | 0.744317 / same |
| historical 4 | 0.83385–0.83429 | 0.83393–0.83587 | 0.857824 / same |
| historical 5 | timed out | timed out | — |

For submissions that train deterministically, every accuracy metric is identical on both sides
and equal to v1's historical value; raw scores differ only through the solve-time term, by no
more than the run-to-run spread. Historical 2 trains until wall-clock deadlines (Known issue 5),
so its accuracy varies slightly on both sides.

## Known issues

Kept as in v1, so scores stay comparable. Fixing any of them changes scores and bumps `version`.

1. **Test labels are reachable from `solve()`.** The runner loads the full data, test labels
   included, before forking its workers; only the copy passed to `solve` has the labels removed,
   and the audit hook blocks just a few file operations. A solution can read the true test labels
   and score 100. A fix is to drop the unsanitized data before forking.
2. **The submission can tamper with grading.** Submitted code runs as root inside the grader's
   processes and can make the parser read a forged result (the cross-task issue in
   `tasks/SCHEMA.md`).
3. **The time term rewards very fast solves.** `-0.01 ln(t)` becomes a bonus below 1 s, so the raw
   score can exceed the accuracy part and even 1.0 (clipped at 100). Raw scores also move slightly
   with host speed and load.
4. **The memory penalty is effectively inert.** Peak memory is measured with `tracemalloc`, which
   does not see PyTorch tensor allocations.
5. **Time-adaptive solutions are not reproducible across hosts.** Solutions that train until a
   wall-clock budget reach different accuracy on faster or slower hosts (one historical submission:
   0.716 in v1, 0.779 on another host).
