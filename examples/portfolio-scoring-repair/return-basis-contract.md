# Portfolio return basis v1 — experimental metric amendment

This independent opt-in requires ledger v2 and matching work/judge images.
It changes performance measurement, not score weights, thresholds or audit vetoes.
Do not regrade or splice historical results. Both feedback arms receive this text.

The evaluation calendar has N reported trading-session closes. Initial portfolio
NAV is exactly 1 before the first session. Define r[0] = NAV[0] − 1 and, for later
sessions, r[t] = NAV[t] / NAV[t−1] − 1. There are N observations, including the
first session's execution costs; normalizing away that first close is invalid.
A first-session loss counts toward drawdown from initial NAV 1. Subsequent peaks
are the maximum of initial NAV and all closes observed so far.

The existing cost-free, daily rebalanced 60/30/10 benchmark starts at NAV 1 at the
first supplied close. Its first-session return is zero; subsequent returns use
its existing construction. This amendment does not invent a pre-period holding
or charge benchmark execution costs. The entire authoritative calendar is used
for both paths, with their explicit initial NAVs of 1.

Annual strategy return = final strategy NAV^(252/N) − 1.
Annual benchmark return = final benchmark NAV^(252/N) − 1.
Annual excess return is the **difference of these annual returns**, not an
annualization of the difference in cumulative returns.

Sharpe uses all N session returns: mean × 252 divided by sample standard deviation
× sqrt(252). Information ratio uses the annual excess return above divided by the
sample standard deviation of same-session strategy-minus-benchmark returns ×
sqrt(252). Existing zero-volatility handling remains zero. Drawdown is negative.
The existing adjacent-close weight-change turnover definition and half-year
minimum annualization denominator are retained, using N sessions consistently.
Opening allocation is not added to that turnover numerator.

The legacy Sortino denominator remains the sample standard deviation of negative
active daily returns, with its existing zero/insufficient-downside handling.
Its observations now include the first session and its numerator uses the annual
excess definition above. This is **not** a repair of the separate downside-moment
ambiguity. VaR calculations, warm-up and calibration denominators are also
unchanged; their timing opt-in is independent. These limitations must not be
represented as qualification of the entire scoring design.

Activate with `RETURN_BASIS=1` on both ledger-v2 builds, record new image digests
and use a newly registered task. Omit it on both builds to restore the prior
metric implementation. The normal score report identifies
`return_basis_contract: portfolio-return-basis-v1`; invalid ledger early exits
retain the accounting error report. This file grants no evaluator/data access.
