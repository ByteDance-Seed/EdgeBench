# Portfolio ledger v2 — experimental accounting amendment

This version includes event contract v1 and supersedes its accounting and trade
record paragraphs. Select the ledger-v2 work **and** judge images together in a
new experiment. These are experimental scores, not revised official results.
Every worker and feedback arm receives identical public instructions/validators.

## Accounting convention

Start each supplied evaluation period with **10,000,000 cash and zero shares**.
Use the input's sorted unique session dates and all ten permitted ETF codes.
Input close prices are the authoritative marks; no extra dividends, cash
interest, capital flows or financing charges are applied. Do not round balances
each day. There is no warm-up holding or terminal liquidation requirement.

All executions occur at that session's **close**. Old holdings earn the change
from the previous close; a new purchase does not earn the price movement before
its execution. `daily_weights`, shares, cash, equity and NAV are **after** that
session's executions and costs. Keep existing daily exposure limits.

- Commission: **0.0005 × absolute executed notional**, on every buy, sell, short
  and cover, with no minimum fee or netting between fills.
- Slippage: **0.0001 × absolute executed notional**, a separate cash cost. The
  execution's `price` is the input close; do not also adjust it for slippage.
- Borrow: **0.04 × prior-close short market value × elapsed calendar days / 365**.
  Debit cash at the next session before executions, including weekends/holidays.
  No first-session accrual; no liability remains after that day's cash debit.
  Covering today still pays the preceding holding interval. No post-final-session
  accrual is included. This replaces solver-specific borrow settlement policies.
- Shares are integers. `buy` adds to nonnegative holdings; `sell` reduces an
  existing long by at most its size; `short` adds to nonpositive holdings; `cover`
  reduces an existing short by at most its size. Cross zero with two ordered legs.
  Negative cash is subject to existing leverage/cash rules, not an added interest model.

Daily equity = cash + sum(shares × current close). NAV = equity / 10,000,000.
Weights = shares × current close / equity. Equity must remain positive. This is
also checked as previous equity + prior holdings' price PnL − today's commission,
slippage and borrow. All input sessions are mandatory, including no-trade days.

## Required JSON fields

Keep the original `metrics` and `risk_calibration` schema. Add:

```json
{
  "accounting_contract": "portfolio-ledger-v2",
  "initial_capital": 10000000,
  "trades": [{
    "execution_id": "unique-fill-1", "record_type": "execution",
    "date": "2025-01-02", "stock_code": "510300.XSHG",
    "direction": "buy", "qty": 100, "price": 4,
    "open_date": "2025-01-02", "close_date": "2025-01-02",
    "open_price": 4, "close_price": 4,
    "commission": 0.2, "slippage_cost": 0.04
  }],
  "daily_accounting": [{
    "date": "2025-01-02", "cash": 9999599.76, "equity": 9999999.76,
    "commission": 0.2, "slippage_cost": 0.04, "borrow_cost": 0,
    "shares": {"510300.XSHG": 100}
  }]
}
```

This is a field illustration, **not a complete valid submission**: expand shares
and `daily_weights[].weights` to all ten codes, even zeros; include matching
`daily_nav` and all dates. Each dated array must have exactly one row per session
in order. `trades` is chronological; its array order defines same-close execution
order. `execution_id` must be nonempty and unique across the run. Multiple actual
same-size fills are allowed, each with its own ID, cash movement and fees.
Do not duplicate one execution with a new ID; an extra unmatched execution fails
reconciliation. IDs alone do not prove truthful strategy execution.

`trades` contains only executions, not closed lots or aggregate order summaries.
Optional lot analytics belong in another field and never incur another cost.
Compatibility open/close fields repeat the actual execution date/price and do
not assert a round trip. All numeric values must be finite JSON numbers.

## Public validation and scoring boundary

Run on supplied public prices; it performs no submission or evaluation request:

```sh
python3 ledger_contract.py backtest_results.json etf_prices.csv
python3 event_contract.py backtest_results.json trading_dates.json
```

Pass only the public calendar/price period represented in the output. The ledger
validator checks every close, execution, fee, cash/share balance, daily cost,
equity, NAV and weight. Tolerances: 0.01 cash units, 1e-8 prices/NAV/weights, exact
shares and initial capital. Missing/duplicate dates, nonfinite values, omitted
costs and unmatched duplicated executions fail. Failure reports its first error.

The judge embeds this same validator with prices restricted to its authoritative
evaluation start/end dates, matching the period supplied to the strategy.
Restored historical or future prices are not required output sessions. The
submitted dates never determine or shorten that required calendar. An invalid or
missing ledger receives **zero total score with an accounting error**, not a
fraud verdict. Validity does not promise a positive performance score. Full-path
reconciliation replaces approximate current-weight NAV reconstruction, its
first-close normalization check and current-weight return-direction comparison.
Duplicate detection uses execution identity plus ledger evidence. Other event,
position, strategy and score rules remain those of the event-v1 candidate.
Those remaining heuristic audits are not certified by this change.

A local pass cannot validate unseen returns, certify the strategy's information
usage or establish real external fills. Hidden prices and scores are never made
available through this public validator. Roll back by selecting a previously
pinned work/judge pair for a **new** run; keep historical curves unchanged.
