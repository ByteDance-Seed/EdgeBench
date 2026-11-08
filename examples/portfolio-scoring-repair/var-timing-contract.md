# Experimental independent VaR timing v1

This opt-in revision requires the paired ledger-v2 work and judge images.
It corrects only the **independent** VaR holding time. It does not change the
meaning of the agent's submitted risk-calibration records.

Ledger-v2 executions occur at the session close. For a NAV return from close
`t-1` to close `t`, independent VaR therefore uses the portfolio weights **after
close `t-1`**, not the weights after close `t`. Trading at close `t` cannot change
the exposure that earned that day's price return. Rows are in the complete,
chronological session order required by ledger-v2; `t-1` is the preceding
trading session, not the preceding calendar day.

All other independent VaR calculations remain unchanged: the zero-mean normal
95% formula, preceding 60 market-return observations (including the return ending
at `t-1`, excluding the one ending at `t`), covariance regularization, six-decimal
VaR rounding, and comparison against the net NAV return including costs. The
first 60 submitted weight rows still use the existing 2% fallback, as do short
history windows; these rows still enter the breach denominator when a NAV
return exists. This timing-only repair does not endorse that fallback as a
statistical calibration method or remove the existing calibration score/veto.

The score report identifies `risk_timing_contract=portfolio-var-timing-v1`.
Use new paired image digests and a new experiment registration when enabling it.
No ongoing attempt, historical curve or official result is regraded in place.
Disable by omitting `VAR_TIMING=1` in both builds and selecting the previously
qualified ledger-v2 pair for a new attempt. Public task files are identical
between feedback and blind arms; this amendment grants no evaluator access.
