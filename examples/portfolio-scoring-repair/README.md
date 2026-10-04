# Portfolio scoring contract repair candidate

This opt-in **diagnostic** repair targets the published Portfolio judge image
`seededge/edgebench.judge.portfolio_risk_calibration:08fe0a4bad80`. It does not
change SForge defaults, dataset image pins, official results, or running jobs.
The evaluator source is distributed inside the image, not this Git repository;
`repair.py` checks its exact digest and changes five audit effects, an undeclared minimum-exposure check and label-dependent position selection at build time.
No hidden data, reference solution, agent trajectory, or evaluator dump is included.

## Why

The public task promises full Sharpe credit at 4 or above and full drawdown
credit at 3% or below. The current audit overrides those scores when Sharpe
exceeds 4 or drawdown is below 2%. Better stated performance can therefore lose
core credit without evidence of false accounting.

The deliverables guide calls `trades` rebalancing records, uses execution
verbs (`buy`, `sell`, `short`, `cover`), yet describes `open_date` and `close_date`
as a holding interval. A real execution ledger can consequently be read as
zero-duration round trips. The optional `return` field is described as unused
by scoring but can also trigger a veto when supplied as zero.

These observations can warrant investigation; alone they do not prove fabricated
returns. This candidate retains diagnostic warnings but removes their automatic
core-score veto. It preserves independent NAV reconstruction, price/date/quantity
checks, other existing audit effects and scoring functions.

A separate completeness check treats gross exposure below 80% as missing data,
even when every date and all ten ETF fields are present. The published task
specifies upper position/leverage limits but no minimum investment. This repair
removes only that lower-bound condition. Missing dates, missing ETF fields,
unknown instruments and the existing upper check remain unchanged. Low investment can still lose performance or short-exposure credit;
structural completeness does not imply a good or compliant strategy.
Position and leverage limits now apply to every reported daily weight vector.
Previously only dates carrying recognized rebalance labels were checked when any
such labels existed. Identical excessive exposures could evade penalties by
renaming or omitting an event. The candidate removes that date filter and its
unused selector; it retains all existing constraint equations, penalty amounts
and caps. This is a deliberate strengthening: unlabelled days, including drifted
holdings, are audited against the published daily position limits. No unpublished
intraday tolerance or correction exemption is inferred. Original results remain
historical; this change needs a separately versioned comparison.

It is intentionally not a comprehensive validation of every remaining rule.
Trigger-specific rebalancing intervals remain unresolved: scheduled re-estimation,
additional risk rebalances and constraint corrections need an explicit common
task contract before that rule is changed. Do not treat this image as fully qualified. See the [event and constraint contract
proposal](interval-contract.md) for synthetic counterexamples, label-independent
audit requirements and the remaining acceptance cases.

## Reproduce and validate

From the repository root, with Docker available:

```sh
docker build --platform linux/amd64 \
  -f examples/portfolio-scoring-repair/Dockerfile \
  -t portfolio-judge:contract-repair-v3 examples/portfolio-scoring-repair
```

The build runs synthetic boundary tests against both original and repaired
functions in the real judge environment. They characterize rules, not complete
portfolio strategies or benchmark scores. Unknown source revisions, repeated
application, and overwriting an output fail closed. Rollback means selecting the
original image; no original tag is overwritten.

Use a copied task definition and a separately registered experiment to opt in.
Keep original and corrected scorer results separate, identify the image digest,
and do not reuse corrected scores as official leaderboard scores. This example
does not launch an agent, install credentials, or expose judge data to workers.

## Public contract clarification for upstream task sources

The work image's task instruction and `deliverables_guide.docx` should both define:

- A `trades` record represents either an actual execution or a matched closed lot;
  distinguish them explicitly (for example `record_type=execution|closed_lot`).
- An execution has its true execution timestamp and price; if the compatibility
  open/close fields are required, both use that actual timestamp and price. This
  describes one transaction, not an immediate opening and closing of a position.
- A closed lot uses its actual opening and closing dates/prices and matched
  quantity. State the matching policy and allocate partial closes consistently.
  Keep unmatched open positions separately; never invent closure dates.
- `return` is optional; absent or zero values alone do not establish fabricated
  accounting. NAV and holdings remain independently verified.

This text is a proposed schema clarification, **not installed by the scorer
Dockerfile**. Test it as a separate intervention from the scorer repair. Give
identical public examples and schema validation to feedback and blind arms;
only hidden evaluation feedback should differ. Upstream must update its owning
work/judge sources, rebuild versioned images and update dataset pins before
calling this an official task correction.

Task provenance: [EdgeBench dataset](https://huggingface.co/datasets/ByteDance-Seed/EdgeBench),
[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). This candidate is
submitted for maintainer review; the original task and scoring authors retain
attribution.
