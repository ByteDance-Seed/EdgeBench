# Cross-Border CTA Multi-Strategy Portfolio and Risk Budget Optimization

## Task Background

You are the head of the CTA strategy team at a quantitative hedge fund. The fund manages 1.5 billion RMB in assets, with an investment scope covering domestic and overseas commodity futures markets, including standardized futures contracts on exchanges such as SHFE, DCE, CZCE, INE, CME, ICE, and LME.

The fund currently operates a single trend following strategy, but it performs unstably in choppy markets. Drawdown control, cross-border exposure management, transaction cost handling, strategy correlation control, and stress scenario analysis all require systematic upgrades. Your task is to build a runnable, auditable, and iteratively optimizable CTA multi-strategy portfolio system based on the provided data and research materials.

This task does not require writing a fixed answer in one shot. Rather, it evaluates whether the Agent can continuously improve the strategy system over an extended working period. The research memos represent only internal historical research hypotheses, not standard answers. You need to validate these hypotheses, retain the effective parts, and replace or improve the ineffective parts.

## Input Files

All input files have been copied to the current working directory root; the evaluator also reads identically named copies under `/home/workspace/input/`. Do not depend on a `task_input/` subdirectory.

- `futures_price_data.xlsx`: Daily OHLCV and term structure data for domestic and overseas commodity futures.
- `futures_contract_specs.xlsx`: Contract specifications, margin requirements, transaction costs, position limits, trading calendars, etc.
- `macro_factors_data.xlsx`: Macroeconomic indicators, global market indices, and exchange rate data.
- `risk_policy_doc.docx`: Fund risk management policy and compliance constraint manual.
- `strategy_research_notes.docx`: Internal strategy research memos, intended only as initial research leads.
- `requirements.txt`: Runtime dependencies.

Using external market data or fetching supplementary data from the internet is not allowed; performing feature engineering, parameter search, walk-forward validation, and stress testing locally on the provided data is allowed.

## Task Objectives

Build a complete CTA multi-strategy portfolio system that includes at least:

1. Data preprocessing and feature engineering.
2. Five categories of strategy signals: time-series momentum, cross-sectional momentum, Carry/Basis, volatility breakout, and mean reversion/spread trading.
3. Multi-strategy portfolio construction and dynamic risk budget allocation.
4. Multi-currency, multi-market, multi-instrument backtesting engine.
5. Handling of transaction costs, exchange rates, holidays, missing data, and position limits.
6. Drawdown control, VaR, single-instrument/sector/overseas exposure and other risk constraints.
7. Performance attribution, stress testing, sensitivity analysis, and failure case diagnostics.

## Long-Horizon Optimization Requirements

This task should support multiple submissions and continuous optimization. An acceptable system is not just one that "runs" -- it should also continuously improve in the following directions:

- Reduce drawdown and tail losses while avoiding simple empty positions or ultra-low volatility disguised as risk control.
- Improve risk-adjusted returns rather than pursuing a single return metric.
- Control transaction costs and turnover, especially cost erosion from high-turnover strategies.
- Handle strategy conflicts, rising correlations, and market regime changes.
- Maintain robustness across different years, different sectors, and domestic/overseas instruments.
- Provide auditable diagnostics for failed strategies or ineffective periods.

## Required Deliverables

The submission directory must contain the following files. They can be placed in the root directory or under `outputs/`; the evaluator will prioritize reading from `outputs/`.

1. `run.py` or `main.py`: One-click execution entry point.
2. `config.json` or `config.yaml`: Main parameter configuration.
3. `signal_matrix.csv`: Daily signals for the five strategy categories.
4. `nav_history.csv`: Daily NAV and portfolio risk status.
5. `positions.csv`: Daily positions per instrument.
6. `trades.csv`: Daily trade records and transaction costs.
7. `risk_budget_allocation.csv`: Strategy risk budget and portfolio scaling records.
8. `performance_report.md` or `performance_report.xlsx`: Performance and attribution report.
9. `stress_test_report.md` or `stress_test_results.xlsx`: Stress test results.
10. `sensitivity_analysis_report.md` or `sensitivity_analysis.xlsx`: Sensitivity analysis.
11. `diagnostics.json`: Key runtime parameters, data quality checks, and exception handling notes.

## Recommended Output Schema

Recommended fields for `nav_history.csv`:

- `date`
- `nav_cny`
- `unit_nav`
- `daily_pnl_cny`
- `daily_return`
- `drawdown`
- `dd_scale`
- `gross_exposure`
- `net_exposure`
- `overseas_exposure`
- `num_positions`

Recommended wide-table fields for `signal_matrix.csv`:

- `date`
- `ticker`
- `TSMOM`
- `XSMOM`
- `CARRY`
- `BREAKOUT`
- `MEANREV`

A long-table format is also accepted: `date,ticker,strategy,signal`, but strategy names must clearly map to the above five strategy categories.

Recommended fields for `positions.csv`:

- `date`
- `ticker`
- `lots`
- `notional_cny`
- `weight`
- `price`
- `currency`
- `sector`

Recommended fields for `trades.csv`:

- `date`
- `ticker`
- `lots_change`
- `side`
- `price`
- `fx_rate`
- `notional_cny`
- `transaction_cost_cny`

## Notes

- Outputting unit NAV is allowed, but it must also be possible to reconstruct the RMB NAV; submitting both `unit_nav` and `nav_cny` is recommended.
- If random search, stochastic models, or Monte Carlo methods are used, random seeds must be fixed and recorded in `diagnostics.json`; purely deterministic systems do not need to set random seeds for the sake of formality.
- Using `pandas`, `numpy`, `scipy`, `scikit-learn`, `statsmodels`, `matplotlib`, and `openpyxl` is allowed. If other pure-CPU open-source libraries are used, their purpose and alternative approaches must be documented in the README.
- The final system must be runnable in a standard CPU environment without requiring a GPU.

## Auditability Supplementary Requirements (v4)

- Backtest results should be auditable: dates, position changes, trade records, transaction costs, and exchange rate conversions in `nav_history.csv`, `positions.csv`, and `trades.csv` should be mutually reconcilable.
- Transaction costs, contract specifications, currency, and exchange rate handling should prioritize using the input data provided with the task, and necessary fields should be retained in the output files or diagnostics files to facilitate verification.
- Mean reversion/spread trading, multi-signal synthesis, and risk budget adjustments should have their main logic documented in the code or report, and key parameters and processing rules should be recorded in `diagnostics.json` or related outputs.
