## Title

Dynamic Portfolio Optimization and Risk-Adaptive Allocation

## Task Requirements

You are a portfolio manager at a quantitative hedge fund, responsible for managing a multi-asset macro allocation fund. You need to build a dynamic portfolio optimization system that can adapt to changes in market states.

Background: Traditional Markowitz mean-variance optimization relies on historical covariance matrices and cannot adjust in time during structural market breaks (such as volatility clustering, correlation breakdowns). Your task is to build a risk-calibration-driven portfolio optimizer that allows the portfolio to dynamically shrink risk exposure under different market states, while controlling excessive turnover through transaction cost management.

Task objective: Based on the provided daily historical data for 10 cross-asset ETFs (covering equity, bond, commodity, and money market), along with macro state indicators (VIX, yield curve), build a complete dynamic portfolio optimization system.

The system must include:
1. Risk calibration module: Dynamically estimate the covariance matrix (including tail risk modeling) and output a risk scaling factor (scale in [0.6, 2.0]). A VaR estimation method (parametric or historical simulation) must be implemented, with the ability to adjust parameters online based on backtest results of VaR breach rates. This module serves as the upstream input for portfolio optimization, determining the maximum risk budget allowed under current market conditions.
2. Portfolio optimization module: Receives the adjusted covariance matrix from the risk calibration module and solves for optimal weights on each rebalancing date. The optimization objective is to maximize the Sharpe ratio or risk-adjusted returns, with constraints including single-asset caps, asset class concentration limits, total leverage ratio, etc.
3. Execution cost-aware layer: Adds a turnover penalty term to the optimization objective so that the optimizer only rebalances when expected excess returns significantly exceed transaction costs (including slippage impact).
4. Dynamic rebalancing mechanism: Automatically adjusts rebalancing frequency based on changes in the risk scaling factor and market state. During crisis states, temporarily increased rebalancing frequency is allowed; during calm periods, frequency is reduced to save costs.

## Optimization Objectives (in priority order)

1. Sharpe ratio (most important): Target an annualized Sharpe ratio of 3.0 or above during the backtest period; 4.0 and above earns full marks; below 1.2 will severely impact the score. Calculation: annualized return / annualized volatility (risk-free rate = 0), daily return annualization factor sqrt(252).
2. Maximum drawdown control: Target maximum drawdown no greater than 4%; 3% or below earns full marks; exceeding 8% will severely impact the score. Calculation: max(1 - current NAV / historical peak NAV).
3. Excess return capability: Target annualized excess return of 8% or above; 12% or above earns full marks; the strategy must outperform the multi-asset benchmark (60% equity + 30% bond + 10% commodity). Negative annualized excess return will result in a score deduction.
4. Information ratio: Target 1.0 or above; 2.5 or above earns full marks; below 0.5 scores very low. Information ratio = annualized excess return / tracking error.
5. Sortino ratio: Target 2.0 or above; 4.0 or above earns full marks; below 0.5 scores very low. Sortino ratio = annualized excess return / downside deviation.
6. Risk model calibration accuracy: VaR breach rate should be close to 5%. Agent-reported VaR breach rate should be controlled near 4%-6%; independent VaR breach rate should be controlled near 3%-7%.
7. Turnover control: Target annualized one-way turnover between 80%-120%. Annualized one-way turnover = sum(|delta_w_i|) / 2 * (252 / backtest_days), where delta_w_i is the change in position weights between adjacent trading days.
8. Short selling strategy: Daily average short exposure must reach 10% or above, and the correlation coefficient between short exposure and market returns must be below -0.1. Insufficient short selling or ineffective hedging will result in score deductions.

Benchmark composition:
- Equity portion (60%): 5 equity ETFs equally weighted (510300, 159935, 159915, 513660, 513500).
- Bond portion (30%): 2 bond ETFs equally weighted (511010, 511220).
- Commodity portion (10%): 2 commodity ETFs equally weighted (518880, 510410).
- Excess return = strategy annualized return - benchmark annualized return.

## Provided Data and Materials

1. etf_prices.csv: Daily price data for 10 cross-asset ETFs (including training period 2019-01-01 to 2023-12-31 and validation period 2024-01-01 to 2024-12-31).
   - Fields include: date (trading date), stock_code (ETF code), open (open price), high (high price), low (low price), close (close price), volume (trading volume).
   - ETFs covered: CSI 300 ETF (510300), CSI 500 ETF (159935), ChiNext ETF (159915), Hang Seng ETF (513660), S&P 500 ETF (513500), Government Bond ETF (511010), Municipal Bond ETF (511220), Gold ETF (518880), Resources ETF Bosera (510410), Money Market ETF (159001).
2. etf_info.csv: ETF basic information, fields include: stock_code (ETF code), stock_name (ETF name), asset_class (asset classification, values: Equity, Bond, Commodity, Money Market).
3. train_period.txt: Training period start and end dates, format: 2019-01-01,2023-12-31. The Agent performs model parameter estimation, covariance matrix estimation, and risk model calibration during this phase.
4. valid_period.txt: Validation period start and end dates, format: 2024-01-01,2024-12-31. The Agent performs parameter tuning and strategy selection during this phase, with iterative refinement allowed.
5. macro_indicators.csv: Daily macro state indicator data, fields include: date, VIX, US10Y, Term_Spread, Credit_Spread.

Macro indicator descriptions:
- VIX: Global risk sentiment proxy index. When global risk sentiment deteriorates, A-shares typically also face pressure.
- US10Y: Global cost-of-capital benchmark. U.S. interest rate changes affect A-share valuations through northbound capital flows and exchange rate channels.
- Term_Spread (10Y-2Y): U.S. Treasury term spread, a leading indicator of the global economic cycle. Yield curve inversion typically signals rising recession risk, corresponding to reduced risk asset exposure.
- Credit_Spread (AAA corporate bond - Treasury): U.S. credit environment proxy. Widening credit spreads reflect rising risk aversion, which can help determine defensive/offensive allocation switching.
- The Agent needs to independently judge the extent to which these global indicators are applicable to A-share multi-asset allocation decisions, and how to map them into risk scaling factor adjustment signals. The strategy should primarily use ETF price data to drive the risk scaling factor, with macro indicators as supplementary reference.

## Constraints

- Trading instruments are limited to the 10 provided ETFs.
- Round-trip transaction cost of 0.05% (0.05% deducted on both buy and sell sides, 0.1% round-trip total). On buy, 0.05% is deducted from available capital; on sell, 0.05% is deducted from proceeds.
- Short selling must be implemented; short positions must exist continuously during the evaluation period (at least 10% of trading days must have position records with negative weights). Securities lending cost is uniformly set at 4% annualized (simplified). Lending interest = short amount * 0.04 * holding days / 365, deducted from returns upon closing.
- Short selling is limited to equity and commodity ETFs only: CSI 300 ETF, CSI 500 ETF, ChiNext ETF, Hang Seng ETF, S&P 500 ETF, Gold ETF, Resources ETF Bosera; bond and money market ETFs cannot be shorted.
- Initial capital of 10 million; single-asset maximum position cannot exceed 25% of total capital. Equity and bond asset class total positions cannot each exceed 60%, commodity asset class total position cannot exceed 15%, and money market ETF position cannot exceed 5%. Single-asset short weight cannot exceed -25%.
- Total leverage ratio (sum of absolute long and short exposures / net assets) cannot exceed 2.0.
- Risk model parameters (covariance matrix, VaR breach rate) must be re-estimated on a rolling basis every 20 trading days. If the risk scaling factor changes significantly, an additional rebalancing is triggered, with a minimum interval of 5 trading days between additional rebalances.
- The output risk calibration records should include rebalance_history, and use trigger="risk_scale_change" when the risk scaling factor triggers an additional rebalance; otherwise it will be considered as not having implemented risk-driven rebalancing.
- Using future data is prohibited; no network requests are allowed during strategy execution.
- Backtest full-cycle (1-year validation period) runtime must not exceed 5 minutes.
- Training/validation period data and evaluation period data are physically isolated in different directories; strategy code must not read data across directories.

## Final Deliverables

- portfolio_optimizer.py: Directly runnable strategy code that outputs backtest_results.json (containing daily NAV, daily position weights, trade records, performance metrics, risk scaling factor series, VaR breach records, rebalancing records, etc.).
- requirements.txt: Lists all dependency libraries.
- backtest_results.json: Generated by running the strategy code, containing complete backtest results needed for scoring.

Note: The weights object in daily position weights must include weights for all 10 ETFs; ETFs with zero weight must also be explicitly listed.

## Special Notes

1. The hidden test data contains at least one volatility regime change event. If the system's risk calibration module can correctly detect such events and cause the risk scaling factor to increase by an absolute value of >= 0.3 within 5 trading days after the event (i.e., scale_after - scale_before >= 0.3), and the portfolio's maximum drawdown is reduced by >= 5 percentage points compared to the uncontrolled baseline, an additional bonus (+10 points) will be awarded in scoring. The detection mechanism must be a general method (e.g., volatility breakout threshold) rather than hard-coded for specific dates.
2. Training data covers the 2019 slow bull market, 2020 pandemic shock, 2022 bear market, and 2023 choppy market, requiring the strategy to perform robustly across all market states.
3. During evaluation, the strategy code will run in an independent evaluation directory that contains only the input files needed for evaluation, with no access to training/validation period data. The scoring script executes in an independent directory to ensure fairness of out-of-sample scoring.
4. The application of macro indicators is completely open: the Agent may choose to use some or all indicators, may design linear/nonlinear mapping functions, and may also abandon certain indicators if found ineffective during backtesting. Strategies that do not use macro indicators can still participate in scoring, but strategies that reasonably incorporate macro information are expected to perform more robustly during extreme market conditions. The strategy should primarily use ETF price data to drive the risk scaling factor, with macro indicators as supplementary reference.
5. The evaluation period data runs from January 1, 2025 to December 31, 2025, approximately 242 trading days, with no additional warm-up window. The strategy must handle insufficient data windows on its own (e.g., equal-weight holding for the first 20 trading days, using simple methods for initial covariance estimation, etc.). The evaluation script does not penalize strategy degradation caused by insufficient data.
6. The evaluation directory provides only: etf_prices_test.csv, etf_info.csv, test_period.txt (and optionally macro_indicators_test.csv). Files such as etf_prices.csv and valid_period.txt from the training/validation period will not be provided.
7. The strategy code must read test_period.txt to obtain the evaluation period start and end dates (2025-01-01 to 2025-12-31); the output daily_nav and daily_weights must contain data for all trading days within the evaluation period.
8. In evaluation mode, the strategy code should not fall back to using training/validation period files. If required test files do not exist, the code should raise an explicit error. It is recommended that the strategy code switch modes via command-line arguments (--backtest) or automatic file existence detection to avoid depending on non-existent files.
9. Data authenticity requirement: All output data must genuinely reflect strategy execution results and must not be fabricated or tampered with. The evaluation system will perform multi-dimensional authenticity checks on output data (including NAV double verification, price range validation, trade record verification, etc.). Data anomalies or falsification will directly affect the final score; severe cases will result in performance scores being zeroed out.

## Task Input Description

The following input files are provided with the task, all located in the `attachments/` directory:

| File | Format | Description |
| --- | --- | --- |
| `attachments/etf_prices.csv` | `.csv`, `utf-8-sig` | Daily price data for 10 ETFs covering the training period (2019-01-01 to 2023-12-31) and validation period (2024-01-01 to 2024-12-31). |
| `attachments/macro_indicators.csv` | `.csv`, `utf-8-sig` | Daily macro state indicator data (2019-01-01 to 2024-12-31). |
| `attachments/etf_info.csv` | `.csv`, `utf-8-sig` | Basic information for 10 ETFs. |
| `attachments/train_period.txt` | `.txt`, `utf-8` | Training period start and end dates, format: `2019-01-01,2023-12-31`. |
| `attachments/valid_period.txt` | `.txt`, `utf-8` | Validation period start and end dates, format: `2024-01-01,2024-12-31`. |

Reference document: `attachments/deliverables_guide.docx`.

## Deliverable Requirements

- portfolio_optimizer.py | Python source file
- requirements.txt | plain text
- backtest_results.json | JSON
