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
The default image retains original interval semantics. The opt-in event-v1 pair
below changes them only alongside an explicit public task amendment and validator.
It is a new experimental task variant, not certification of every scoring policy.
See the [event contract basis](interval-contract.md) for the counterexamples and
remaining risk-trigger/correction evidence boundaries.

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

## Optional paired event-contract revision

The published task says to re-estimate every 20 sessions and keep five sessions
between additional risk events, but the judge applies an inclusive 5–25-day clock
to every adjacent event. The optional pair installs an explicit initialization
anchor, separate scheduled/risk clocks, missing-update checks and elapsed-session
arithmetic. It rejects unsupported model-event labels; execution-only records
belong in `trades`. It grants no constraint-repair exemption. This changes task
semantics and must never be silently applied to historical results.

```sh
docker build --platform linux/amd64 --build-arg EVENT_CONTRACT=1 \
  -f examples/portfolio-scoring-repair/Dockerfile \
  -t portfolio-judge:event-contract-v1 examples/portfolio-scoring-repair
docker build --platform linux/amd64 \
  -f examples/portfolio-scoring-repair/Work.Dockerfile \
  -t portfolio-work:event-contract-v1 examples/portfolio-scoring-repair
```

Select **both** images in a copied task definition and record their exact digests.
The work image adds [the canonical amendment](task-contract.md), links it from
`task_instruction.md` with explicit precedence over ambiguous legacy guide fields,
and installs `event_contract.py`. The judge embeds that same validator at build
time. Both feedback settings receive exactly the same public files. The validator
uses only supplied event records and calendar; it has no judge client, hidden-data
path or scoring function. Its success does not certify truthful model updates,
strategy quality, accounting or complete output-schema compliance.

The amendment also disambiguates executions from closed lots, defines daily weight
timing and describes the existing diagnostic score repairs. It does not add a
second transaction ledger or change independent NAV reconstruction. Upstream still
owns consolidation into the original DOCX/work/judge sources and official pins.
Disable this revision by selecting the original work image and either the original
judge or the separately identified default diagnostic candidate; start a new run.
Never mix task variants in one comparison or splice their curves.

Validation covers the real judge function, embedded/public validator identity,
valid and invalid calendars/events, independent clocks, holidays, duplicates,
missing updates, a partial final period and absence of transactions. An isolated
work-image CLI check exercises success/error output without judge files or network.
No long-run model adoption or scientific benefit is established by these checks.

Task provenance: [EdgeBench dataset](https://huggingface.co/datasets/ByteDance-Seed/EdgeBench),
[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). This candidate is
submitted for maintainer review; the original task and scoring authors retain
attribution.

## Optional paired ledger v2

The [ledger-v2 amendment](ledger-contract.md) makes close execution, starting
capital and costs explicit, then checks the full daily cash/share/equity path.
It supersedes approximate current-weight NAV reconstruction and signature-only
duplicate detection. Missing costs, duplicated executions and altered intermediate
NAV fail even if the final NAV matches. Separate same-size fills remain valid
when their identities, inventory, cash and costs reconcile. Invalid accounting
receives zero with an accounting diagnostic, not a fraud verdict.

This is an opt-in experimental task revision, including event v1, not a silent
change to either default image or historical scores. Costs are fixed at 5 bps
commission and 1 bp slippage per execution, with 4% ACT/365 prior-close short
borrow paid daily. These are explicit new task conventions, not assumptions
retroactively imposed on older outputs. Remaining strategy/scoring heuristics
are outside this accounting repair.

```sh
docker build --platform linux/amd64 --build-arg EVENT_CONTRACT=1 \
  --build-arg LEDGER_CONTRACT=1 \
  -f examples/portfolio-scoring-repair/Dockerfile \
  -t portfolio-judge:ledger-v2 examples/portfolio-scoring-repair
docker build --platform linux/amd64 --build-arg LEDGER_CONTRACT=1 \
  -f examples/portfolio-scoring-repair/Work.Dockerfile \
  -t portfolio-work:ledger-v2 examples/portfolio-scoring-repair
```

Use both image digests in a copied task definition. The same public validator is
installed in the work image and embedded in the judge, without judge clients,
hidden input data or score access. Synthetic tests cover close timing, weekend
borrow, legitimate matching-size fills, 24 accounting/schema mutations and
actual judge-entry rejection before performance calculation. A local pass does
not certify hidden-period strategy performance or causal use of market inputs.
Revert by selecting a previously qualified paired task for a new attempt.
