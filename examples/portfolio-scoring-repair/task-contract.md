# Portfolio event contract v1 — experimental task amendment

This explicitly versioned task variant supplements `task_instruction.md` and
`deliverables_guide.docx`. Where the older guide conflates a model update, a
rebalance and a holding interval, this amendment takes precedence. It changes
the task contract; its scores are not official EdgeBench scores. All worker arms
in a comparison must receive this same document and public validator.

## Model events and independent clocks

`risk_calibration.rebalance_history` records model events, not every execution.
Each entry contains `date` (`YYYY-MM-DD`) and one of these `trigger` values:

- `initial`: initialize the model at the first trading session of the evaluation
  period. Exactly one initial event is required. No extra warm-up data is supplied.
- `scheduled`: complete the required model re-estimation at session offsets 20,
  40, 60, and so on from initialization. A scheduled update need not execute a
  transaction when the optimizer retains its current holdings. Record it anyway.
- `risk_scale_change`: an additional risk-driven rebalance. Consecutive additional
  events must be at least five elapsed trading sessions apart. There is no maximum
  gap in this clock. A scheduled update does not reset or postpone it. The existing
  requirement to implement risk-driven behavior remains; a label alone does not
  establish that the strategy detected a risk change.

The calendar is the sorted, unique trading dates in the input price data within
that run's period. Elapsed sessions are the difference in calendar indices, not
an inclusive count and not civil days. An incomplete final 20-session block
requires no extra scheduled event. Initialization at offset 0 and scheduled
updates at 20/40 are compatible with a risk event at 18; risk events at 18/22
violate the minimum even though a scheduled update lies between them.

A scheduled and risk event may share a date if both operations actually occurred.
Duplicate `(date, trigger)` entries, off-calendar dates, unsupported labels and
missing or misplaced model updates are invalid. Execution-only corrections
belong in `trades`, not as invented model-event labels. They do not reset either
model clock, excuse a missing scheduled update, or waive any position constraint.
No correction exemption is inferred from a free-text reason.

## Execution records and holdings

A transaction and a closed holding lot are different records. Use
`record_type="execution"` for an actual buy/sell/short/cover execution and retain
the existing required stock, direction, quantity and price fields. If compatibility
fields `open_date`, `close_date`, `open_price`, `close_price` are required, use the
actual execution date and price in both pairs. This describes one execution, not
an immediate opening and closing of the position. A zero or absent optional
`return` field does not by itself indicate false accounting.

Use `record_type="closed_lot"` only for an actual matched closed quantity, with
its real opening/closing dates and prices. Describe the matching method and
allocate partial closes consistently. Do not invent closure dates for open lots.
Do not duplicate one transaction as both an execution and another chargeable
trade record. The strategy's cash, commissions, borrow costs, holdings and NAV
must remain mutually consistent; the existing independent accounting checks remain.

Report `daily_weights` at each session's close after that session's execution and
mark-to-market. Include all ten ETF fields, even zeros. Every reported vector is
subject to the published position, shorting and leverage caps, regardless of event
labels. Uninvested cash is not a missing ETF field and there is no minimum gross
investment. This variant grants no unreported intraday tolerance or label-based
constraint-repair exemption. Performance, shorting effectiveness and calibration
requirements still apply.

## Public validation available to every arm

`event_contract.py` reads only the event records and calendar you supply. It does
not invoke the judge or access hidden risk events, hidden prices, scores or a
background evaluator. Prepare `trading_dates.json` as a JSON array of the public
backtest period's sorted unique session dates, then run:

```sh
python3 event_contract.py backtest_results.json trading_dates.json
```

Exit 0 means that the supplied event schedule satisfies this public contract;
exit 1 reports event errors. This does not validate strategy quality, truthful
execution, risk-trigger thresholds, all output fields or accounting. The judge
uses the same event validator: each detected event-contract error contributes two
points to the existing interval deduction, within the existing overall deduction
rules. Existing missing-history and missing-risk-behavior deductions remain.
A valid synthetic schedule needs no trades or market returns; do not fabricate
events merely to pass validation.
