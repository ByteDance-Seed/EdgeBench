# CTA judge execution and result repair

The published CTA judge runs the submitted entrypoint in its wrapper and then
runs it again in the evaluator. Each task invocation allows 300 seconds, while
the outer evaluation script allows 600 seconds. A slow submission can therefore
use almost the entire grading window before scoring finishes.

This recipe pins the published base image and verifies the exact wrapper and
evaluator hashes before patching. It follows the adjacent task-repair examples;
no hidden evaluator, input data, reference solution or submission is copied into
the repository.

The evaluator becomes the sole owner of task execution. Its code, scoring
formula, compliance checks and 300-second task limit remain unchanged. The
wrapper gives the evaluator 540 seconds, leaving headroom for cleanup and result
formatting within the 600-second outer evaluation-script limit. Container
creation and archive delivery are outside that execution timeout.

The evaluator runs in its own process group. The wrapper cleans that group on
completion and timeout, captures output in temporary files and retains the last
8,000 bytes of each stream for diagnostics. A process that deliberately creates
a separate session still depends on judge-container isolation and cleanup.

Before execution, the wrapper removes any stale result. Missing or malformed
results, non-finite scores, evaluator launch errors, nonzero exits and timeouts
produce an invalid structured result with an explicit error reason. A genuine
finite zero remains valid. The numeric zero on an invalid result is a compatibility
field, not a successful zero-score result. Consumers must honor `valid`.
Total and dimension scores are checked after normalization as well as before it:
finite inputs can still overflow, and clipping an infinite total must not turn
it into a valid score of 100 or 0. Existing clipping of finite totals is preserved.

From the repository root:

```sh
docker build --network=none --pull=false \
  -t edgebench.judge.cta_risk_budget_optimization:chain-repair-v1 \
  examples/cta-scoring-repair
```

The build verifies revision/reapplication guards and runs synthetic regressions
against the actual patched wrapper, including a non-idempotent task entrypoint,
valid zero, stale/missing/malformed results, timeout cleanup and background
descendants. Synthetic fixtures do not replace qualification of the real
evaluator. `parser_contract.py` additionally passes real wrapper output through
the parser from a caller-selected SForge checkout; record that checkout's exact
revision and ensure imports resolve there when qualifying a release.

For new evaluations, copy the task manifest and change only `judge.image_tag`
to `chain-repair-v1`. Record the recipe revision, resulting image ID/digest and
copied task manifest. Keep the local image name above: SForge resolves the
unprefixed `edgebench.judge.<task_id>:<tag>` name. Dataset changes, image
publication and experiment adoption are separate rollout operations. Preserve
the old image and never replace the judge of a running experiment.

For historical analysis, write rescoring results to a separate directory and
retain original reports, archives, timestamps and failure classifications. Apply
the same repair and resource settings across compared arms. Rescoring can recover
artifact scores; it cannot restore feedback a solver missed. An affected active
feedback run may need a fresh matched attempt after qualification. A failure in
hidden background scoring alone does not automatically require new solving, and
a judge timeout does not establish an Agent runtime failure.
