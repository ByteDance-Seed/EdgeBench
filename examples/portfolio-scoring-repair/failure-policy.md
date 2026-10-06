# Portfolio failure-policy v1 (opt-in)

The published Portfolio wrapper can emit `valid=true`, score `0`, and a passed
parseability test when the scoring command crashes or produces no parseable
score. Its manifest maps both `parse_failure` and
`nonzero_exit_without_score` to `zero_score`. Such a result does not establish
that the strategy earned zero; it also must not qualify as a successful result
for caching merely because `valid` is true.

This independent build-time repair changes those two policies to `infra_error`.
The existing wrapper then emits `valid=false`, a failed parseability test and
`SCORER_STATUS_JSON.status=infra_error`. Its legacy `TOTAL_SCORE 0` sentinel
remains: consumers must respect structured validity rather than charting that
sentinel as an observed score. No original reports are rewritten.

Explicit numeric zero, documented strategy-run failure and strategy timeout
scores remain valid zeros. Missing-submission behavior, scoring equations,
normalization and other manifest fields remain unchanged. This does not detect
incorrect but parseable scores, determine why a command failed, or make arbitrary
submitted strategies deterministic. It does not authorize result sharing.

## Build and validate

```sh
docker build --platform linux/amd64 \
  -f examples/portfolio-scoring-repair/failure-policy.Dockerfile \
  -t portfolio-judge:failure-policy-v1 examples/portfolio-scoring-repair
```

The build checks exact wrapper and manifest SHA-256 revisions before applying
anything, exercises original and repaired policy through the real image wrapper
with synthetic child processes, and refuses unknown revisions. No hidden data,
reference solution or copied evaluator source is distributed here. Tests cover
crashes, empty/unparseable output, genuine zero, documented strategy failure and
timeout, normal score, repeated repair, unknown source and overwrite protection.

To combine with a separately qualified local Portfolio judge variant, pass
`--build-arg BASE_IMAGE=<immutable-judge-reference>` and give the result a new tag.
The wrapper and manifest guards must still match; the variant's own validation
remains necessary. Record the resulting image digest in a copied task definition
and register a **new** experiment. Do not hot-update a running attempt, reuse its
historical scores under the new policy, or treat this diagnostic variant as an
official leaderboard change. Roll back by selecting the prior exact judge image
for a new attempt. SForge defaults, official task definitions and work images
are untouched; activating this image grants no access to hidden feedback.

This example only builds a candidate judge image. It does not start solver jobs
or submit benchmark solutions. This policy change is independent of event,
ledger, VaR timing and return-basis repairs.
