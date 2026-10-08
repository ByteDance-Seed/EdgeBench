# Portfolio event and constraint contract proposal

Status: the default diagnostic image still preserves original interval semantics.
An explicit `EVENT_CONTRACT=1` build now implements separate model/risk clocks
and a public calendar anchor through `event_contract.py`; it must be paired with
`Work.Dockerfile` and its [task amendment](task-contract.md). This is a versioned
experimental task, not an official correction or reinterpretation of old scores.
The v3 daily-weight audit remains label-independent. Constraint-repair exemptions
and automatic verification of risk-trigger thresholds are not implemented.

## Demonstrated inconsistencies

The public task requires risk-model re-estimation every 20 trading sessions and
at least five sessions between additional risk-triggered rebalances. Its output
guide describes `scheduled` and `risk_scale_change` events. Re-estimation,
execution and restoring a violated position limit are different operations.

Synthetic probes against the original published judge
produce the following results. Indices below refer to a synthetic trading calendar;
no submission, market data or strategy trajectory is needed.

| Input | Current observation | Required distinction |
| --- | --- | --- |
| Initial event at 0; scheduled events at 20 and 40; risk event at 18 | Two interval penalty points for 18→20 | An additional risk action does not postpone scheduled re-estimation |
| Risk events at 10 and 14, with scheduled events at 20 and 40 | No interval penalty | Four elapsed sessions are fewer than the stated five |
| Risk events at 10 and 15, with scheduled events at 20 and 40 | No interval penalty | Five elapsed sessions meet the lower bound |
| Initial event at 0; only risk events at 10, 20, 30 and 40 | No interval penalty | Risk actions alone do not prove scheduled model re-estimation |
| Complete weight records: all zero at 0, all ten assets at 25% each at 18; event labels `initial` at 0, `scheduled` at 18, `risk_scale_change` at 40 | Five leverage penalty points, plus other position penalties | Gross exposure is 2.5, above the published 2.0 cap |
| Same weights/dates, changing only the event at 18 to `constraint_repair` or an unknown label | Zero leverage and total constraint penalty | An event label must not select whether exposure is audited |

The last pair demonstrates a label-dependent audit gap, repaired in v3; it is not evidence that
an agent intentionally exploited the grader. Simply excluding correction events
from interval checks would be an incomplete fix and could conceal this gap.

## Contract basis and remaining extensions

1. Use the sorted, unique trading calendar supplied to the task. Elapsed sessions
   are `index(end) - index(start)`, excluding the starting session. Invalid dates,
   duplicate event records and conflicting labels receive explicit schema errors.
2. Anchor scheduled re-estimation to the first evaluation session: initialization
   at index 0, then updates at 20, 40, and so on while those indices exist. A
   re-estimation may leave weights unchanged. Record its completion independently
   of whether it generated a transaction; do not infer model updates from turnover.
   Publish this anchor and the no-warm-up policy in both task and output guide.
3. Keep a separate clock for additional `risk_scale_change` rebalances. Consecutive
   additional events must be at least five elapsed sessions apart. Scheduled model
   updates neither reset nor postpone this clock. Do not impose a maximum gap
   between risk events when the declared threshold has not triggered.
4. Document the risk threshold and its observable inputs. Absence of a risk event
   is a violation only if evidence shows that its declared trigger occurred;
   manufacturing a risk event is not a substitute for verifying calibration.
5. Define whether each reported weight vector is before or after the day's
   execution and returns. Audit position, shorting and leverage limits from those
   vectors and execution evidence, independently of the event label. Missing or
   unrecognized labels cannot grant an exemption. If drift tolerance or temporary
   intraday breaches are permitted, publish their bound and repair deadline.
6. A constraint correction is an execution restoring a demonstrated breach, not a
   model re-estimation. In event v1 it belongs only in the execution ledger and
   receives no exemption; the following is a possible future extension. Record the affected limit and pre/post exposure. Verify
   that evidence before allowing an interval exemption; relabeling a discretionary
   risk trade is insufficient. The current daily output may lack pre-trade facts,
   so an exemption must not be inferred solely from `trigger` or free-text reason.
7. Retain accounting, price/date/quantity checks and strategy-quality metrics.
   Define the event contract first, then choose and publish penalty magnitudes.
   Do not tune penalties to make a particular strategy's score positive.

These are explicitly versioned owning-task semantics, not a silent reinterpretation of old
results. The task amendment identifies the installed subset; exemption extensions remain proposed. Existing records that cannot establish an exemption remain unqualified
for the new contract; their original scores are retained as historical evidence.

## Decisive acceptance

Implement the same public schema in the work image, output guide and judge, with
valid/invalid examples accessible in both feedback settings. A public validator
may report formatting and contract errors; it must not reveal hidden returns,
risk events, evaluator data or score signals to a blind worker.

The revised judge must pass all pairs above, plus missing scheduled updates,
legitimate updates without trades, same-session operations, a partial final
20-session block, holidays, invalid/duplicate dates, omitted event history,
unrecognized labels, and relabeling without valid repair evidence. Hold weights
and prices fixed in label-mutation tests: position/leverage findings must stay
identical. A genuine four-session risk gap must still fail after benign scheduled
or correction events are inserted between its endpoints.

Keep this change in a separately versioned task/judge pair, use identical public
instructions for all arms, restart comparisons on that common contract and keep
old curves separate. A passing synthetic probe alone does not qualify long-run
worker behavior or establish a feedback-ablation effect.
