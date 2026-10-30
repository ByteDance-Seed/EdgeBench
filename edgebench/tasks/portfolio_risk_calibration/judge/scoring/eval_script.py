#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
eval_script.py - Dynamic Portfolio Optimization Strategy Auto-Scoring Script (final)
================================================================

Features:
    0. Static code analysis (future data patterns + network requests + bypass methods + hidden file access)
    1. File mapping (compatible with platform prefix numbering)
    2. Data preparation (truncate to eval period -> run strategy -> restore)
    3. Validate output data date range (eval period 2025-01-01 to 2025-12-31)
    4. NAV dual verification (independent rebuild with trade costs and short costs + internal consistency)
    5. NAV path reasonableness check (single-day change within +/-15%)
    6. Weight completeness check (date coverage, 10 ETFs complete, unknown assets, weight sum)
    7. Weights-NAV direction consistency cross-validation
    8. Independent calculation of all performance metrics (eval period data only)
    9. Dual VaR verification (Agent-reported VaR breach rate + independent VaR breach rate)
   10. Full verification: open/close prices within actual daily price range
   11. Volatility change detection bonus independent verification
   12. Full core constraint check (by rebalancing day): position, leverage, short limits, asset class, cash,
       rolling revaluation, risk scaling factor change, VaR change, short exposure, short hedge effectiveness
   13. Anti-fraud check: performance plausibility, trade authenticity, strategy implementation authenticity

Score weights (total 100 + bonus 10 = 110):
    Sharpe Ratio 30 | Max Drawdown 15 | Excess Return 20 | Information Ratio 10 | Sortino Ratio 10
    Agent VaR 5 | Independent VaR 5 | Turnover Rate 5

Benchmark composition (60% equity + 30% bond + 10% commodity):
    Equity (60%): 5 equity ETFs equal-weight (510300, 159935, 159915, 513660, 513500)
    Bond (30%): 2 bond ETFs equal-weight (511010, 511220)
    Commodity (10%): 2 commodity ETFs equal-weight (518880, 510410)

Excess ReturnScoring rules:
    - Full marks: annualized excess>=12% gets full 20 pts
    - pass line: annualizedexcess≥0% gets 0pts
    - penalty line: annualizedexcess negative willpenalty, max deduct 10pts

Information RatioScoring rules:
    - Pass line: 0.5 (below gets 0 pts)
    - Full marks: 2.5 (above gets 10 pts)

Sortino RatioScoring rules:
    - Pass line: 0.5 (below gets 0 pts)
    - Full marks: 4.0 (above gets 10 pts)

Sharpe RatioScoring rules:
    - Pass line: 1.2 (below gets 0 pts)
    - Full marks: 4.0 (above gets 30 pts)

Max DrawdownScoring rules:
    - Full marks: 3% (below gets 15 pts)
    - Zero line: 8% (above gets 0 pts)

Independent VaRScoring rules:
    - targetbreachrate: 5%
    - tolerance: ±2 percentage points(3%~7% withinlinearscore)

penalty items: 
    - codedetectionviolation: each items deduct 2pts, max deduct 6pts
    - NAVdualverificationfailed: independentrebuildfailed deduct 10pts, internalself-consistentfailed deduct 10pts
    - NAVpathabnormal: single-daychangeexceeds±15%, each  deduct 2pts, max deduct 8pts
    - positionweightnot complete: bynot completedateproportiontieredpenalty(-1 to -10pts)
    - tradeinstrumentviolation: containsnon-permittedinstrument, each  deduct 5pts, max deduct 15pts
    - date rangeabnormal: outputdatacontainstest period outsidedate, each class deduct 1pts, max deduct 6pts
    - price range verificationabnormal: exceedssame-day[low,high], each trades deduct 3pts, max10pts
    - tradesfieldmissing: basicfieldmissingeach trades deduct 3pts, extendedfieldmissingeach trades deduct 2pts, max10pts/8pts
    - position classconstraint(singleasset, class, cash, shortweight): settotalpenaltylimit30pts
    - leverage classconstraint: settotalpenaltylimit20pts
    - Short Effectiveness Penalty: exposureinsufficientlinearpenalty(max-6pts), hedgeinvalid deduct 4pts
    - strategyimplementnot complete: not short, scaling factorconstant, VaRvalue is constant, risk_scale_change not triggered etc

Anti-fraud check (triggersCore return score zeroedor deduction):
    - performancemetricreasonable: sharpe>4.0, drawdown<2%, annualizedreturn>50% and drawdown<5%, VaRbreachrate<1% or >15%
    - Trade record authenticity: price fraud, time fraud, same-day open/close,returnall 0, lots fraud, NAV inconsistency
    - strategy implementation authenticity: nevershort, shorttradeday<10%, scaling factorconstant, VaRconstant, weightequal-weight, leverage ratio30 days unchanged
    - reportvalueseverelyre-not consistent: sharpedeviation>0.2, drawdowndeviation>2 percentage points, Turnover Ratedeviation>50% etc
    - operation special items: hiddenfileread, NAVconsecutive5 days unchanged, tradeduplicaterecords

usemethod: python eval_script.py
"""

import json
import os
import re
import sys
import shutil
import subprocess
import time
from collections import defaultdict
from datetime import datetime
from typing import Dict, List, Tuple, Optional

import pandas as pd
import numpy as np
from scipy import stats
import glob


# ==================== allglobalconfigparams ====================

# ---------- datatimebetweenrange ----------
TEST_START = '2025-01-01'              # eval period start
TEST_END = '2025-12-31'                # eval period end

# ---------- verificationthreshold ----------
METRIC_TOLERANCE = 0.05                # metric cross-validation tolerance (5%)
NAV_REBUILD_THRESHOLD = 0.05           # NAV independent rebuild tolerance (5%)
NAV_INTERNAL_THRESHOLD = 0.02          # NAV internal consistency tolerance (2%)
NAV_PATH_MAX_CHANGE = 0.15             # max single-day NAV change (15%)

# ---------- runlimit ----------
MAX_EXECUTION_TIME = 300               # max execution time (seconds)

# ---------- strategyparams(with task specstrictconsistent)----------
INITIAL_CAPITAL = 10_000_000           # initial capital 10M
MAX_SINGLE_POSITION = 0.25             # max single asset position 25%
MAX_ASSET_CLASS_POSITION = {
    'equity': 0.60,
    'bond': 0.60,
    'commodity': 0.15,                      # commodity class limit 15% (reduced from 60%)
    'cash': 0.05
}
MAX_SHORT_WEIGHT = -0.25               # single asset short weight floor -25%
MAX_LEVERAGE = 2.0                     # max total leverage
COMMISSION = 0.0005                    # one-waycommission 0.05%
SHORT_INTEREST = 0.04                  # annualizedshort interest cost 4%

# ---------- short limit ----------
SHORTABLE_ETFS = [
    '510300.XSHG', '159935.XSHE', '159915.XSHE',
    '513660.XSHG', '513500.XSHG',
    '518880.XSHG', '510410.XSHG'
]

# ---------- asset classmapping ----------
ASSET_CLASS_MAP = {
    '510300.XSHG': 'equity', '159935.XSHE': 'equity', '159915.XSHE': 'equity',
    '513660.XSHG': 'equity', '513500.XSHG': 'equity',
    '511010.XSHG': 'bond', '511220.XSHG': 'bond',
    '518880.XSHG': 'commodity', '510410.XSHG': 'commodity',
    '159001.XSHE': 'cash'
}

# ---------- allETFcolumntable(fixed order)----------
ALL_ETFS = [
    '510300.XSHG', '159935.XSHE', '159915.XSHE',
    '513660.XSHG', '513500.XSHG',
    '511010.XSHG', '511220.XSHG',
    '518880.XSHG', '510410.XSHG',
    '159001.XSHE'
]
N_ASSETS = len(ALL_ETFS)

# ==================== benchmark config(60/30/10)====================
# benchmarkcomposition: 
#   - Equity (60%): 5 equity ETFs equal-weight
#   - Bond (30%): 2 bond ETFs equal-weight
#   - Commodity (10%): 2 commodity ETFs equal-weight
# ================================================================
STOCK_BENCHMARK_ETFS = [
    '510300.XSHG', '159935.XSHE', '159915.XSHE',
    '513660.XSHG', '513500.XSHG'
]
BOND_BENCHMARK_ETFS = ['511010.XSHG', '511220.XSHG']
COMMODITY_BENCHMARK_ETFS = ['518880.XSHG', '510410.XSHG']

# benchmarkweightconfig(new: 60%equity / 30%bond / 10%commodity)
BENCHMARK_STOCK_WEIGHT = 0.60          # equityweight 60%
BENCHMARK_BOND_WEIGHT = 0.30           # bondweight 30%
BENCHMARK_COMMODITY_WEIGHT = 0.10      # commodityweight 10%

# ---------- performancescoringparams(new)----------
# Sharpe Ratio: pass1.2, full marks4.0
SHARPE_PASS_THRESHOLD = 1.2
SHARPE_FULL_SCORE_THRESHOLD = 4.0      # from 3.5increased to4.0
# Excess Return: full marks12%
EXCESS_FULL_SCORE_THRESHOLD = 0.12     # from 8%increased to12%
EXCESS_MAX_PENALTY = -10.0
# Information Ratio: pass0.5, full marks2.5
IR_PASS_THRESHOLD = 0.5                # from 0.3increased to0.5
IR_FULL_SCORE_THRESHOLD = 2.5          # from 1.0increased to2.5
# Sortino Ratio: full marks4.0
SORTINO_FULL_SCORE_THRESHOLD = 4.0     # from 2.5increased to4.0
SORTINO_PASS_THRESHOLD = 0.5
# Max Drawdown: full marks3%, zeroed8%
MAX_DD_FULL_SCORE = 0.03               # 3%
MAX_DD_ZERO_SCORE = 0.08               # 8%

# ---------- VaRscoringparams ----------
# Agentself-reportedVaR: tolerance±1%
AGENT_VAR_TOLERANCE = 0.01
# Independent VaR: tolerance±2%(from ±1%relaxed)
INDEPENDENT_VAR_TOLERANCE = 0.02

# ---------- Turnover Ratescoringrange ----------
TURNOVER_IDEAL_LOW = 0.80
TURNOVER_IDEAL_HIGH = 1.20
TURNOVER_ACCEPTABLE_LOW = 0.60
TURNOVER_ACCEPTABLE_HIGH = 1.40

# ---------- rollingrevaluationintervalthreshold(tradeday)----------
REBALANCE_MIN_DAYS = 5
REBALANCE_MAX_DAYS = 25

# ---------- volatility change detectionparams ----------
# bonusthreshold: absolutechange≥0.3(from relativechange30%changed absolutechange0.3)
VOLATILITY_EVENT_ABSOLUTE_CHANGE = 0.3
VOLATILITY_EVENT_DD_IMPROVEMENT = 0.05  # drawdownimprovement≥5 percentage points

# ---------- shortdetectionthreshold ----------
MIN_SHORT_TRADING_DAYS_PCT = 0.10      # minshortpositiontradedayproportion 10%

# ---------- shortexposurelinearpenaltyparams ----------
SHORT_EXPOSURE_TARGET = 0.10           # targetexposure 10%
SHORT_EXPOSURE_MAX_PENALTY = 6.0       # maxpenalty 6pts
SHORT_EXPOSURE_STEP = 0.05             # penaltystep(from 10% to 5%)

# ---------- need hidden scoringanswerfile ----------
SENSITIVE_FILE = 'true_risk_events.json'
HIDDEN_FILE = '.true_risk_events_hidden'


# ============================================================================
# 0. File mapping (compatible with platform prefix numbering)
# ============================================================================

def map_platform_files():
    """
    willevaluationplatformwithsequencenumber beforefix file mapping scoringscriptcanuse unifiednamename.
    strategy codeinternalusehardcoded rawfilenameread, noneedmodify.
    """
    file_patterns = {
        '*etf_prices_test.csv': 'etf_prices_test.csv',
        '*etf_info.csv': 'etf_info.csv',
        '*macro_indicators_test.csv': 'macro_indicators_test.csv',
        '*test_period.txt': 'test_period.txt',
        '*true_risk_events.json': '.risk_events_for_eval.json',
    }

    for pattern, target in file_patterns.items():
        if os.path.exists(target):
            continue
        matches = glob.glob(pattern)
        if matches:
            src = matches[0]
            if src != target:
                shutil.copy2(src, target)
                print(f"  file mapping: {src} → {target}")


# ============================================================================
# 1. strategy codestaticdetection(enhancedversion)
# ============================================================================

def audit_strategy_code(filepath='portfolio_optimizer.py'):
    """
    staticcheckstrategy codewhethercontainsnot futuredatausepattern and networkrequest.
    
    Returns: (whetherpass, warningcolumntable, violation itemscount)
    """
    if not os.path.exists(filepath):
        matches = glob.glob('*portfolio_optimizer.py')
        if matches:
            filepath = matches[0]
        else:
            return False, [f"strategy codefile {filepath} does not exist"], 1

    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            code = f.read()
    except FileNotFoundError:
        return False, [f"strategy codefile {filepath} does not exist"], 1

    warnings_list = []
    lines = code.split('\n')
    hardcoded = []
    shift_future = []
    network_violations = []
    hidden_file_attempts = []

    for i, line in enumerate(lines, 1):
        stripped = line.strip()

        # skipcomments and default value definitions
        if stripped.startswith('#'):
            continue
        if re.match(r'^DEFAULT_.*=\s*', stripped):
            continue
        if re.match(r'^[A-Z_]+_START\s*=\s*', stripped):
            continue
        if re.match(r'^[A-Z_]+_END\s*=\s*', stripped):
            continue

        # check1: test periodend datehardcoded
        if re.findall(r'2025-1[2-9]-\d{2}', stripped):
            hardcoded.append(f"line {i} rows: {stripped[:80]}")

        # check2: not futuredatareference
        if 'shift(-1)' in stripped or 'shift(-2)' in stripped:
            shift_future.append(f"line {i} rows: {stripped[:80]}")

        # check3: networkrequest
        network_patterns = [
            r'import\s+requests', r'import\s+urllib', r'import\s+socket',
            r'from\s+requests', r'from\s+urllib', r'urllib\.request',
            r'requests\.(get|post)', r'socket\.(connect|socket)'
        ]
        for pat in network_patterns:
            if re.search(pat, stripped):
                network_violations.append(f"line {i} rows: {stripped[:80]}")
                break

        # check3enhanced: __import__ dynamicimport
        if '__import__' in stripped and ('request' in stripped.lower() or 'url' in stripped.lower()):
            network_violations.append(f"line {i} rows: __import__dynamicimportsuspectednetworklib ({stripped[:80]})")

        # check3enhanced: exec/eval dynamicexec rows
        if ('exec(' in stripped or 'eval(' in stripped) and ('import' in stripped.lower() or 'request' in stripped.lower()):
            network_violations.append(f"line {i} rows: exec/evaldynamicexec rowssuspectedimport ({stripped[:80]})")

        # check3enhanced: subprocess callnetworkcommand
        if 'subprocess' in stripped and ('curl' in stripped.lower() or 'wget' in stripped.lower()):
            network_violations.append(f"line {i} rows: subprocesscallnetworkcommand ({stripped[:80]})")

        # check3enhanced: socket directconnection
        if 'socket' in stripped and ('connect' in stripped or 'AF_INET' in stripped):
            network_violations.append(f"line {i} rows: socketdirectnetworkconnection ({stripped[:80]})")

        # check4: attemptreadhidden risk eventfile
        if '.true_risk_events' in stripped or '.risk_events' in stripped:
            hidden_file_attempts.append(f"line {i} rows: attemptreadhiddenfile ({stripped[:80]})")

    if hardcoded:
        warnings_list.append(f"test periodend datehardcoded ({len(hardcoded)} occurrences)")
    if shift_future:
        warnings_list.append(f"shift(-1)/shift(-2) not futuredatareference ({len(shift_future)} occurrences)")
    if network_violations:
        warnings_list.append(f"networkrequestrelatedcode ({len(network_violations)} occurrences)")
    if hidden_file_attempts:
        warnings_list.append(f"attemptreadhiddenscoringfile ({len(hidden_file_attempts)} occurrences)")

    violation_count = sum([1 for x in [hardcoded, shift_future, network_violations, hidden_file_attempts] if x])

    return len(warnings_list) == 0, warnings_list, violation_count


# ============================================================================
# 2. dataprepareandstrategyrun
# ============================================================================

def prepare_agent_data():
    """ strategy codepreparecontaining onlyeval perioddata file."""
    CUTOFF = TEST_START

    for f in ['etf_prices_test.csv', 'macro_indicators_test.csv']:
        if os.path.exists(f):
            shutil.copy2(f, f + '.full_backup')
            df = pd.read_csv(f, encoding='utf-8-sig')
            df['date'] = pd.to_datetime(df['date'])
            df_cut = df[(df['date'] >= CUTOFF) & (df['date'] <= TEST_END)]
            df_cut.to_csv(f, index=False, encoding='utf-8-sig')


def restore_full_data():
    """restorecompletedatafile(scoringscriptsubsequentverificationuse)."""
    for f in ['etf_prices_test.csv', 'macro_indicators_test.csv']:
        backup = f + '.full_backup'
        if os.path.exists(backup):
            shutil.move(backup, f)


def run_strategy_and_generate_output():
    """
    callstrategy codegenerateresultfile.
    
    Returns: (successflagflag, elapsedtimeseccount, info)
    """
    for f in ['backtest_results.json']:
        if os.path.exists(f):
            os.remove(f)

    agent_scripts = glob.glob('*portfolio_optimizer.py')
    if not agent_scripts:
        return False, 0, "cannot find strategy file (*portfolio_optimizer.py)"
    agent_script = agent_scripts[0]

    # temporarily move true_risk_events.json
    risk_file_hidden = False
    if os.path.exists(SENSITIVE_FILE):
        os.rename(SENSITIVE_FILE, HIDDEN_FILE)
        risk_file_hidden = True

    start_time = time.time()

    try:
        result = subprocess.run(
            [sys.executable, agent_script, '--backtest'],
            capture_output=True, text=True, timeout=MAX_EXECUTION_TIME,
            encoding='utf-8', errors='replace',
            env={**os.environ, 'PYTHONIOENCODING': 'utf-8'}
        )
        execution_time = time.time() - start_time

        if result.returncode != 0:
            return False, execution_time, f"strategyrunfailed (returncode={result.returncode})"

        if not os.path.exists('backtest_results.json'):
            return False, execution_time, "strategy run did not generate backtest_results.json"

        return True, execution_time, "strategyrunsuccess"

    except subprocess.TimeoutExpired:
        return False, MAX_EXECUTION_TIME, "strategyrunexceedtime"
    except Exception as e:
        return False, 0, f"runabnormal: {e}"
    finally:
        if risk_file_hidden:
            if os.path.exists(HIDDEN_FILE):
                os.rename(HIDDEN_FILE, SENSITIVE_FILE)


# ============================================================================
# 3. dataloadfunction
# ============================================================================

def load_prices(filepath='etf_prices_test.csv'):
    """loadETF price data(restore after completedata)."""
    df = pd.read_csv(filepath, encoding='utf-8-sig')
    df['date'] = pd.to_datetime(df['date'])
    return df


def get_price_range(prices_df, etf_code, trade_date):
    """getspecifiedETFatspecifieddate pricerange(low, high)."""
    trade_date = pd.to_datetime(trade_date)
    row = prices_df[(prices_df['stock_code'] == etf_code) & (prices_df['date'] == trade_date)]
    if len(row) == 0:
        return None, None
    return float(row.iloc[0]['low']), float(row.iloc[0]['high'])


def get_trading_days_between(dates_series, start_date, end_date):
    """computetwo datebetween tradedaycount."""
    return len([d for d in dates_series if start_date <= d <= end_date])


def load_risk_events(filepath='.risk_events_for_eval.json'):
    """loadvolatilityratesuddenchangeeventconfig."""
    for f in [filepath, 'true_risk_events.json']:
        if os.path.exists(f):
            try:
                with open(f, 'r', encoding='utf-8') as fh:
                    return json.load(fh), None
            except json.JSONDecodeError as e:
                return None, f"risk eventfile JSON formaterror: {e}"
    return None, "risk eventfilenot exists"


def calculate_benchmark_nav(prices_df, start_date, end_date):
    """
    compute60/30/10equitybondcommoditybenchmarkNAV(dailyrebalance, nocost)
    
    benchmarkcomposition(adjustfull 60/30/10): 
    - Equity (60%): 5 equity ETFs equal-weight
    - Bond (30%): 2 bond ETFs equal-weight
    - Commodity (10%): 2 commodity ETFs equal-weight
    
    Args:
        prices_df: prices DataFrame
        start_date: start date
        end_date: end date
    
    Returns:
        benchmark_nav: benchmark NAV Series
    """
    pivot = prices_df.pivot(index='date', columns='stock_code', values='close')
    pivot = pivot.loc[start_date:end_date]
    
    # equityportion(60%)
    stock_pivot = pivot[STOCK_BENCHMARK_ETFS]
    stock_ret = stock_pivot.pct_change().mean(axis=1)
    
    # bondportion(30%)
    bond_pivot = pivot[BOND_BENCHMARK_ETFS]
    bond_ret = bond_pivot.pct_change().mean(axis=1)
    
    # commodityportion(10%)
    commodity_pivot = pivot[COMMODITY_BENCHMARK_ETFS]
    commodity_ret = commodity_pivot.pct_change().mean(axis=1)
    
    # benchmarkreturn(useadjustfull after weight: 60/30/10)
    benchmark_ret = (BENCHMARK_STOCK_WEIGHT * stock_ret + 
                     BENCHMARK_BOND_WEIGHT * bond_ret + 
                     BENCHMARK_COMMODITY_WEIGHT * commodity_ret)
    
    # benchmarkNAV
    benchmark_nav = (1 + benchmark_ret).cumprod()
    benchmark_nav = benchmark_nav.fillna(1.0)
    
    return benchmark_nav


# ============================================================================
# 4. date rangecheck
# ============================================================================

def validate_date_range(data, field_name, date_field='date'):
    """checkdata in datewhetherateval periodrange within."""
    violations = []
    for i, item in enumerate(data):
        d = item.get(date_field, '')
        if d and (d < TEST_START or d > TEST_END):
            violations.append(f"{field_name}[{i}].{date_field}: {d}")
    return violations


# ============================================================================
# 5. NAVdualverification(includingcost deduct )
# ============================================================================

def rebuild_nav_from_weights_and_prices(daily_weights, prices_df):
    """
    from positionweight and pricedataindependentrebuild deduct fee after NAVcurve.
    
    computeformula: 
        gross return = sum(weight_i × same-daychangemagnitude_i)
        commission = (buyamount + sellamount) × one-waycommission rate / net asset
        short interest cost = sum(|shortweight_i|) × annualizedshort interest rate / 365
        net return = gross return - commission - short interest cost
    
    Args:
        daily_weights: daily weights list
        prices_df: prices DataFrame
    
    Returns:
        (nav_df, error_msg): rebuildNAVDataFrame and error message
    """
    if not daily_weights:
        return None, "daily_weights is empty"

    # constructpricepivot table
    pivot = prices_df.pivot(index='date', columns='stock_code', values='close')
    for etf in ALL_ETFS:
        if etf not in pivot.columns:
            pivot[etf] = np.nan
    pivot = pivot[ALL_ETFS].ffill()
    returns = pivot.pct_change()

    # constructweightDataFrame
    weight_records = []
    for dw in daily_weights:
        date_str = dw['date']
        w = dw.get('weights', {})
        row = {'date': pd.to_datetime(date_str)}
        for etf in ALL_ETFS:
            row[etf] = float(w.get(etf, 0))
        weight_records.append(row)

    weights_df = pd.DataFrame(weight_records).set_index('date')
    common_dates = returns.index.intersection(weights_df.index)

    if len(common_dates) < 2:
        return None, f"weightandpricedata commontradedayinsufficient(only{len(common_dates)} days)"

    # dailyrebuildNAV
    nav = 1.0
    nav_series = []
    prev_weights = weights_df.iloc[0].values.copy()

    for date in common_dates:
        cur_weights = weights_df.loc[date].values
        ret_vec = returns.loc[date].values

        # computegross return
        valid = ~np.isnan(ret_vec) & ~np.isnan(cur_weights)
        gross_ret = float(np.dot(cur_weights[valid], ret_vec[valid])) if valid.sum() > 0 else 0.0

        # computecommission
        buy_amount = sum(max(w - pw, 0) for w, pw in zip(cur_weights, prev_weights)) * nav
        sell_amount = sum(max(pw - w, 0) for w, pw in zip(cur_weights, prev_weights)) * nav
        commission_cost = (buy_amount + sell_amount) * COMMISSION / nav if nav > 0 else 0.0

        # computeshort interest cost
        short_cost = 0.0
        for w in cur_weights:
            if w < 0:
                short_cost += abs(w) * SHORT_INTEREST / 365

        # net return
        net_ret = gross_ret - commission_cost - short_cost
        nav *= (1 + net_ret)
        nav_series.append({'date': date, 'nav': float(nav)})
        prev_weights = cur_weights.copy()

    return pd.DataFrame(nav_series), None


def verify_nav_rebuild(daily_nav, daily_weights, prices_df, threshold=NAV_REBUILD_THRESHOLD):
    """NAVindependentrebuildverification."""
    if not daily_nav or not daily_weights:
        return False, "daily_nav  or  daily_weights is empty", None

    rebuilt_df, err = rebuild_nav_from_weights_and_prices(daily_weights, prices_df)
    if rebuilt_df is None:
        return False, f"unable tofrom weight and pricerebuildNAV: {err}", None

    agent_nav_df = pd.DataFrame(daily_nav)
    agent_nav_df['date'] = pd.to_datetime(agent_nav_df['date'])
    agent_nav_df = agent_nav_df.set_index('date')

    agent_final = float(agent_nav_df['nav'].iloc[-1])
    rebuilt_final = float(rebuilt_df['nav'].iloc[-1])
    diff = abs(agent_final - rebuilt_final)

    if diff > threshold:
        return False, f"NAVandweight/pricenot consistent: self-reported {agent_final:.4f} vs independentrebuild {rebuilt_final:.4f} (diff {diff:.4f})", rebuilt_df
    return True, f"NAVandweight/priceconsistent: {agent_final:.4f} vs rebuild {rebuilt_final:.4f}", rebuilt_df


def verify_nav_internal_consistency(daily_nav, threshold=NAV_INTERNAL_THRESHOLD):
    """NAVinternalself-consistentverification."""
    if not daily_nav:
        return False, "daily_nav is empty"

    nav_df = pd.DataFrame(daily_nav)
    nav_df['date'] = pd.to_datetime(nav_df['date'])
    nav_df['nav'] = nav_df['nav'].astype(float)
    nav_df = nav_df.sort_values('date').reset_index(drop=True)
    nav_df['daily_ret'] = nav_df['nav'].pct_change()
    valid_rets = nav_df['daily_ret'].dropna()

    if len(valid_rets) == 0:
        return False, "unable tofrom daily_nav computedayreturnrate"

    rebuilt = 1.0
    for r in valid_rets:
        rebuilt *= (1 + r)

    reported = float(nav_df['nav'].iloc[-1])
    diff = abs(reported - rebuilt)

    if diff > threshold:
        return False, f"NAVinternalnot consistent: self-reported {reported:.6f} vs dayreturnraterebuild {rebuilt:.6f} (diff {diff:.4f})"
    return True, f"NAVinternalconsistent: {reported:.6f} vs rebuild {rebuilt:.6f}"


def verify_nav_path_consistency(daily_nav, max_daily_change=NAV_PATH_MAX_CHANGE):
    """NAVpath reasonableness check."""
    if not daily_nav:
        return True, []

    nav_df = pd.DataFrame(daily_nav)
    nav_df['date'] = pd.to_datetime(nav_df['date'])
    nav_df['nav'] = nav_df['nav'].astype(float)
    nav_df = nav_df.sort_values('date').reset_index(drop=True)
    nav_df['daily_ret'] = nav_df['nav'].pct_change()

    warnings = []
    for _, row in nav_df.iterrows():
        ret = row['daily_ret']
        if pd.notna(ret) and abs(ret) > max_daily_change:
            warnings.append(
                f"{row['date'].strftime('%Y-%m-%d')}: dayreturnrate {ret:.4f} exceeds±{max_daily_change:.0%}"
            )

    return len(warnings) == 0, warnings


# ============================================================================
# 6. positionweightcompleteverification
# ============================================================================

def validate_daily_weights_completeness(daily_weights, daily_nav):
    """
    verification daily_weights  complete.
    
    check items: 
        1. whethercontainsnot knowninstrument
        2. datecoveragewhethercomplete
        3. dailywhethercontainsall10 ETF
        4. daily weightsabsolute value of  and whetheratreasonablerange(0.8-2.2)
    
    Returns: (warningcount, warningcolumntable, not completedatecount)
    """
    warns = []
    incomplete_count = 0

    # checknot knowninstrument
    unknown_etfs = set()
    for dw in daily_weights:
        weights = dw.get('weights', {})
        for etf in weights:
            if etf not in ALL_ETFS:
                unknown_etfs.add(etf)

    if unknown_etfs:
        warns.append(f"daily_weights contains {len(unknown_etfs)}  non-permittedinstrument: {unknown_etfs}")
        return len(warns), warns, incomplete_count

    # checkdatecoverage
    nav_dates = set(d['date'] for d in daily_nav)
    weight_dates = set(d['date'] for d in daily_weights)
    missing = nav_dates - weight_dates
    extra = weight_dates - nav_dates

    if missing:
        warns.append(f"daily_weights missing {len(missing)}  trading days")
    if extra:
        warns.append(f"daily_weights extra {len(extra)}  trading days")

    # checkETFcomplete and weight sum
    for dw in daily_weights:
        date_str = dw['date']
        weights = dw.get('weights', {})
        missing_etfs = [etf for etf in ALL_ETFS if etf not in weights]
        if missing_etfs:
            incomplete_count += 1
            continue
        total_abs = sum(abs(w) for w in weights.values())
        if total_abs < 0.8 or total_abs > 2.2:
            incomplete_count += 1
            continue

    if incomplete_count > 0:
        warns.append(f"daily_weights not complete: {incomplete_count}  date")

    return len(warns), warns, incomplete_count


def calculate_weights_penalty(incomplete_count, total_days):
    """
    computeWeights Completeness Penalty(tieredpenalty)
    based ondatanot completedateproportionptstierpenalty
    """
    if total_days == 0 or incomplete_count == 0:
        return 0
    
    ratio = incomplete_count / total_days
    
    if ratio < 0.05:
        return -1
    elif ratio < 0.10:
        return -2
    elif ratio < 0.20:
        return -4
    elif ratio < 0.30:
        return -6
    elif ratio < 0.50:
        return -8
    else:
        return -10


def cross_validate_weights_vs_nav(daily_weights, daily_nav, prices_df):
    """crossverificationweightandNAVchange directionconsistent."""
    if not daily_weights or not daily_nav:
        return 0, []

    pivot = prices_df.pivot(index='date', columns='stock_code', values='close')
    for etf in ALL_ETFS:
        if etf not in pivot.columns:
            pivot[etf] = np.nan
    pivot = pivot[ALL_ETFS].ffill()
    daily_rets = pivot.pct_change()

    nav_df = pd.DataFrame(daily_nav)
    nav_df['date'] = pd.to_datetime(nav_df['date'])
    nav_df['nav'] = nav_df['nav'].astype(float)
    nav_df = nav_df.sort_values('date')
    nav_df['nav_ret'] = nav_df['nav'].pct_change()
    nav_df = nav_df.set_index('date')

    weight_dict = {}
    for dw in daily_weights:
        date = pd.to_datetime(dw['date'])
        w = dw.get('weights', {})
        vec = np.array([float(w.get(etf, 0)) for etf in ALL_ETFS])
        weight_dict[date] = vec

    warns = []
    mismatch_count = 0

    for date in nav_df.index:
        if date not in weight_dict or date not in daily_rets.index:
            continue
        w_vec = weight_dict[date]
        ret_vec = daily_rets.loc[date].values
        valid = ~np.isnan(ret_vec)
        if valid.sum() > 0:
            theoretical_ret = np.dot(w_vec[valid], ret_vec[valid])
        else:
            continue
        actual_ret = nav_df.loc[date, 'nav_ret']
        if pd.isna(actual_ret):
            continue
        if abs(theoretical_ret) > 0.001 and abs(actual_ret) > 0.001:
            if theoretical_ret * actual_ret < 0:
                mismatch_count += 1
                if mismatch_count <= 5:
                    warns.append(
                        f"{date.strftime('%Y-%m-%d')}: weightestimatereturnrate {theoretical_ret:.4f} "
                        f"andNAVreturnrate {actual_ret:.4f} directionmutualopposite"
                    )

    return mismatch_count, warns


# ============================================================================
# 7. traderecordsfieldcomplete
# ============================================================================

def validate_trades_integrity(trades):
    """checktraderecordsfieldcomplete."""
    basic_fields = ['open_date', 'close_date', 'stock_code', 'direction']
    extra_fields = ['open_price', 'close_price', 'qty']

    basic_invalid = 0
    extra_invalid = 0

    for t in trades:
        if any(f not in t or t[f] is None for f in basic_fields):
            basic_invalid += 1
            continue
        if any(f not in t or t[f] is None for f in extra_fields):
            extra_invalid += 1

    return basic_invalid, extra_invalid


# ============================================================================
# 8. performancemetricrecalculated(useformaleval perioddata)
# ============================================================================

def calculate_metrics_from_data(daily_nav, daily_weights, benchmark_nav):
    """
    from daily_nav, daily_weights  and benchmarkNAVre-newcomputeallperformancemetric.
    
    return metricincludes: 
    - Sharpe Ratio, Max Drawdown, annualizedreturn, annualizedvolatilityrate
    - Excess Return(annualized), Information Ratio, Sortino Ratio
    - Turnover Rate(annualizedone-way)
    
    Args:
        daily_nav: dailyNAVcolumntable
        daily_weights: daily weights list
        benchmark_nav: benchmark NAV Series
    
    Returns:
        (metrics_dict, error_msg): metricfielddict and error message
    """
    if not daily_nav:
        return None, "daily_nav is empty"

    try:
        #  daily_nav convert DataFrame, dateset asindex
        df = pd.DataFrame(daily_nav)
        df['date'] = pd.to_datetime(df['date'])
        df['nav'] = df['nav'].astype(float)
        df = df.sort_values('date')
        df = df.set_index('date')

        # useformaleval perioddata
        df_test = df[df.index >= TEST_START].copy()
        if len(df_test) < 2:
            return None, "formaleval periodvalidtradedayinsufficient"

        s = df_test['nav']
        r = s.pct_change().dropna()

        if len(r) < 2:
            return None, f"validtradedayinsufficient(only {len(r)}  days)"

        n_days = len(r)

        # Sharpe Ratio
        ann_ret = r.mean() * 252
        ann_vol = r.std() * np.sqrt(252)
        sharpe = ann_ret / ann_vol if ann_vol > 0 else 0.0

        # Max Drawdown
        cummax = s.cummax()
        max_dd = float(((s - cummax) / cummax).min())

        # totalreturnrate and annualizedreturnrate
        total_return = float(s.iloc[-1] - 1.0)
        annual_return = (1 + total_return) ** (252 / n_days) - 1 if n_days > 0 else 0.0

        # Turnover Rate
        annual_turnover = 0.0
        if daily_weights and len(daily_weights) >= 2:
            weight_df = pd.DataFrame([
                {**{'date': dw['date']}, **dw.get('weights', {})}
                for dw in daily_weights
            ]).set_index('date').sort_index()

            turnover_sum = 0.0
            prev_w = None
            for date in weight_df.index:
                curr_w = weight_df.loc[date].values
                if prev_w is not None:
                    turnover_sum += np.sum(np.abs(curr_w - prev_w))
                prev_w = curr_w.copy()

            years = max(n_days / 252, 0.5)
            annual_turnover = turnover_sum / 2.0 / years

        # Excess Return, Information Ratio, Sortino Ratio(basedatbenchmark)
        excess_annual = 0.0
        information_ratio = 0.0
        sortino_ratio = 0.0
        benchmark_annual_return = 0.0

        if benchmark_nav is not None and len(benchmark_nav) > 0:
            #  aligndate
            common_idx = s.index.intersection(benchmark_nav.index)
            
            if len(common_idx) >= 2:
                agent_aligned = s[common_idx]
                bench_aligned = benchmark_nav[common_idx]

                # benchmarkannualizedreturn
                bench_total = bench_aligned.iloc[-1] / bench_aligned.iloc[0] - 1
                benchmark_annual_return = (1 + bench_total) ** (252 / len(common_idx)) - 1

                # Excess Return(annualized)
                agent_total = agent_aligned.iloc[-1] / agent_aligned.iloc[0] - 1
                excess_total = agent_total - bench_total
                excess_annual = (1 + excess_total) ** (252 / len(common_idx)) - 1

                # dayExcess Return
                agent_daily_ret = agent_aligned.pct_change().dropna()
                bench_daily_ret = bench_aligned.pct_change().dropna()
                common_dates = agent_daily_ret.index.intersection(bench_daily_ret.index)
                excess_daily = agent_daily_ret[common_dates] - bench_daily_ret[common_dates]

                if len(excess_daily) > 0:
                    # Information Ratio
                    tracking_error = excess_daily.std() * np.sqrt(252)
                    if tracking_error > 1e-9:
                        information_ratio = excess_annual / tracking_error

                    # Sortino Ratio(lower rowsdeviation)
                    downside_returns = excess_daily[excess_daily < 0]
                    if len(downside_returns) > 0:
                        downside_deviation = downside_returns.std() * np.sqrt(252)
                        if downside_deviation > 1e-9:
                            sortino_ratio = excess_annual / downside_deviation

        return {
            'sharpe_ratio': round(sharpe, 4),
            'max_drawdown': round(max_dd, 4),
            'annual_turnover': round(annual_turnover, 4),
            'total_return': round(total_return, 4),
            'annual_return': round(annual_return, 4),
            'benchmark_annual_return': round(benchmark_annual_return, 4),
            'trading_days': n_days,
            'excess_return_annual': round(excess_annual, 4),
            'information_ratio': round(information_ratio, 4),
            'sortino_ratio': round(sortino_ratio, 4),
        }, None

    except Exception as e:
        return None, f"metriccomputeabnormal: {e}"


# ============================================================================
# 9. performancescoringfunction(full marks100pts)
# ============================================================================

def score_sharpe(sharpe_ratio: float) -> float:
    """
    Sharpe Ratioscoring(full marks30pts)
    Pass line: 1.2 (below gets 0 pts)
    Full marks: 4.0 (above gets 30 pts)
    formulaptsdenominator: 4.0 - 1.2 = 2.8
    """
    if sharpe_ratio <= SHARPE_PASS_THRESHOLD:
        return 0.0
    elif sharpe_ratio >= SHARPE_FULL_SCORE_THRESHOLD:
        return 30.0
    else:
        return 30.0 * (sharpe_ratio - SHARPE_PASS_THRESHOLD) / (SHARPE_FULL_SCORE_THRESHOLD - SHARPE_PASS_THRESHOLD)


def score_drawdown(max_drawdown: float) -> float:
    """
    Max Drawdownscoring(full marks15pts)
    Full marks: 3% (below gets 15 pts)
    Zero line: 8% (above gets 0 pts)
    """
    dd = abs(max_drawdown)
    if dd <= MAX_DD_FULL_SCORE:
        return 15.0
    elif dd >= MAX_DD_ZERO_SCORE:
        return 0.0
    else:
        return 15.0 * (MAX_DD_ZERO_SCORE - dd) / (MAX_DD_ZERO_SCORE - MAX_DD_FULL_SCORE)


def score_excess_return(excess_annual: float) -> float:
    """
    Excess Returnscoring(full marks20pts, cannegativepts)
    full marks line: 12%above20pts
    penalty line:  negativepenalty, max deduct 10pts
    """
    if excess_annual >= EXCESS_FULL_SCORE_THRESHOLD:
        return 20.0
    elif excess_annual >= 0:
        return 20.0 * excess_annual / EXCESS_FULL_SCORE_THRESHOLD
    else:
        #  negativepenalty: -10%below deduct 10pts,  inbetweenlinear
        return max(EXCESS_MAX_PENALTY, 10.0 * excess_annual / 0.10)


def score_information_ratio(information_ratio: float) -> float:
    """
    Information Ratioscoring (max 10 pts)
    Pass line: 0.5 (below gets 0 pts)
    Full marks: 2.5 (above gets 10 pts)
    """
    if information_ratio <= IR_PASS_THRESHOLD:
        return 0.0
    elif information_ratio >= IR_FULL_SCORE_THRESHOLD:
        return 10.0
    else:
        return 10.0 * (information_ratio - IR_PASS_THRESHOLD) / (IR_FULL_SCORE_THRESHOLD - IR_PASS_THRESHOLD)


def score_sortino(sortino_ratio: float) -> float:
    """
    Sortino Ratioscoring (max 10 pts)
    Pass line: 0.5 (below gets 0 pts)
    Full marks: 4.0 (above gets 10 pts)
    """
    if sortino_ratio <= SORTINO_PASS_THRESHOLD:
        return 0.0
    elif sortino_ratio >= SORTINO_FULL_SCORE_THRESHOLD:
        return 10.0
    else:
        return 10.0 * (sortino_ratio - SORTINO_PASS_THRESHOLD) / (SORTINO_FULL_SCORE_THRESHOLD - SORTINO_PASS_THRESHOLD)


def score_var(break_rate: Optional[float], tolerance: float = AGENT_VAR_TOLERANCE) -> float:
    """
    VaRcalibrationscoring (max 5 pts)
    targetvalue: 5%, permittedrange: 5% ± tolerance
    Args:
        break_rate: VaRbreachrate
        tolerance: tolerance(Agent uses 0.01, Independent VaR uses 0.02)
    """
    if break_rate is None:
        return 0.0
    dev = abs(break_rate - 0.05)
    if dev >= tolerance:
        return 0.0
    return 5.0 * (1 - dev / tolerance)


def score_turnover(turnover: float) -> float:
    """
    Turnover Ratescoring (max 5 pts)
    ideal range: 80%-120% gets 5pts
    timesgood range: 60%-80% or 120%-140% gets 2.5pts
    """
    if TURNOVER_IDEAL_LOW <= turnover <= TURNOVER_IDEAL_HIGH:
        return 5.0
    elif TURNOVER_ACCEPTABLE_LOW <= turnover < TURNOVER_IDEAL_LOW or \
         TURNOVER_IDEAL_HIGH < turnover <= TURNOVER_ACCEPTABLE_HIGH:
        return 2.5
    else:
        return 0.0


# ============================================================================
# 10. Short Effectiveness Penaltyfunction
# ============================================================================

def calculate_avg_short_exposure(daily_weights: List[dict]) -> float:
    """computedaily avgshortexposure(allnegativeweightabsolute value sum of mean)."""
    short_exposures = []
    for dw in daily_weights:
        short_exp = sum(-w for w in dw.get('weights', {}).values() if w < 0)
        short_exposures.append(short_exp)
    return np.mean(short_exposures) if short_exposures else 0.0


def calculate_short_market_correlation(daily_weights: List[dict], market_returns: pd.Series) -> float:
    """computeshortexposureandmarketreturn related."""
    short_exposures = []
    dates = []
    for dw in daily_weights:
        short_exp = sum(-w for w in dw.get('weights', {}).values() if w < 0)
        short_exposures.append(short_exp)
        dates.append(pd.to_datetime(dw['date']))
    
    if len(short_exposures) < 20:
        return 0.0
    
    short_series = pd.Series(short_exposures, index=dates)
    
    # checkshortexposurewhetherall 0(noshort)
    if short_series.std() == 0:
        return 0.0
    
    market_aligned = market_returns.reindex(short_series.index)
    valid_idx = ~(short_series.isna() | market_aligned.isna())
    
    if valid_idx.sum() < 20:
        return 0.0
    
    corr = short_series[valid_idx].corr(market_aligned[valid_idx])
    
    # handlemay  nan
    if np.isnan(corr):
        return 0.0
    
    return corr


def penalty_short_exposure_linear(avg_short: float) -> float:
    """
    shortexposurelinearpenalty(max-6pts)
    formula: penalty = 4 × (0.10 - exposure) / 0.05
    targetvalue: ≥10%not penalty
    """
    if avg_short >= SHORT_EXPOSURE_TARGET:
        return 0.0
    penalty = 4.0 * (SHORT_EXPOSURE_TARGET - avg_short) / SHORT_EXPOSURE_STEP
    return max(-SHORT_EXPOSURE_MAX_PENALTY, -penalty)


def penalty_short_hedge(correlation: float) -> float:
    """
    shorthedgeeffectivenesspenalty(max-4pts)
    targetvalue: r < -0.1 not penalty
    """
    # handle nan  case
    if np.isnan(correlation):
        return -4.0  # unable tocomputerelated, treat as invalidhedge
    
    if correlation < -0.1:
        return 0.0
    else:
        return -4.0


# ============================================================================
# 11. constraint checkfunction(byrebalancing daycheck)
# ============================================================================
def audit_core_constraints(daily_weights, trades, risk_calibration, dates_for_audit, penalty_details=None):
    """
    fullcheckcoreconstraint(byrebalancing daycheck), return(warningcolumntable, totalpenalty, penaltydetailfielddict)
    """
    warns = []
    
    # initialpenaltydetail(useunified key name)
    if penalty_details is None:
        penalty_details = {
            'single asset position exceeds 25%': 0.0,
            'equity class exceeds 60%': 0.0,
            'bond class exceeds 60%': 0.0,
            'commodity class exceeds 15%': 0.0,
            'cash categoryETFexceeds 5%': 0.0,
            'single asset short exceeds -25%': 0.0,
            'total leverage exceeds 2.0': 0.0,
            'shorting non-permitted asset': 0.0,
            'rolling revaluation interval violation': 0.0,
            'risk_scale_change not triggered': 0.0,
            'risk scaling factor is constant': 0.0,
            'VaRvalue is constant': 0.0,
            'trading non-permitted asset': 0.0,
        }
    
    # each classpenaltyaccumulated
    position_penalty = 0
    leverage_penalty = 0
    other_penalty = 0
    
    # totalcountviolationtimescount
    money_violation_days = 0
    single_violation_days = 0
    class_violation_days = 0
    short_weight_violation_days = 0
    leverage_violation_days = 0
    
    # getrebalancedatecolumntable
    rebalance_history = risk_calibration.get('rebalance_history', [])
    rebalance_dates = set()
    for rh in rebalance_history:
        if rh.get('trigger') in ['scheduled', 'risk_scale_change', 'initial']:
            rebalance_dates.add(rh['date'])
    
    if not rebalance_dates:
        for i in range(1, len(daily_weights)):
            prev_w = daily_weights[i-1]['weights']
            curr_w = daily_weights[i]['weights']
            if any(abs(prev_w.get(etf, 0) - curr_w.get(etf, 0)) > 0.005 for etf in ALL_ETFS):
                rebalance_dates.add(daily_weights[i]['date'])
    
    # ========== 1. tradeinstrumentviolation ==========
    unknown_in_trades = set()
    for t in trades:
        etf = t.get('stock_code', '')
        if etf and etf not in ALL_ETFS:
            unknown_in_trades.add(etf)
    if unknown_in_trades:
        trade_penalty = min(len(unknown_in_trades) * 5, 15)
        penalty_details['trading non-permitted asset'] += trade_penalty
        other_penalty += trade_penalty
        warns.append(f"trades contains {len(unknown_in_trades)}  non-permittedinstrument: {unknown_in_trades}")
    
    # ========== 2. position classconstraint ==========
    for dw in daily_weights:
        date_str = dw['date']
        if date_str not in rebalance_dates:
            continue
        
        weights = dw.get('weights', {})
        date_violated = False
        
        # 2.1 singleassetposition
        for etf, w in weights.items():
            if etf not in ALL_ETFS:
                continue
            if abs(w) > MAX_SINGLE_POSITION:
                if not date_violated:
                    single_violation_days += 1
                    date_violated = True
                excess_pct = (abs(w) - MAX_SINGLE_POSITION) * 100
                excess_points = int(excess_pct)
                penalty_add = min(2 * excess_points, 10)
                penalty_details['single asset position exceeds 25%'] += penalty_add
                position_penalty = min(position_penalty + penalty_add, 30)
        
        # 2.2 asset classposition
        class_weights = defaultdict(float)
        for etf, w in weights.items():
            if etf not in ALL_ETFS:
                continue
            cls = ASSET_CLASS_MAP.get(etf, 'other')
            class_weights[cls] += abs(w)
        
        for cls, w in class_weights.items():
            cap = MAX_ASSET_CLASS_POSITION.get(cls, 0.60)
            if w > cap:
                if not date_violated:
                    class_violation_days += 1
                    date_violated = True
                excess = w - cap
                excess_5pct = int(excess / 0.05)
                penalty_add = min(excess_5pct * 3, 9)
                if cls == 'equity':
                    penalty_details['equity class exceeds 60%'] += penalty_add
                elif cls == 'bond':
                    penalty_details['bond class exceeds 60%'] += penalty_add
                elif cls == 'commodity':
                    penalty_details['commodity class exceeds 15%'] += penalty_add
                position_penalty = min(position_penalty + penalty_add, 30)
        
        # 2.3 cash categoryposition
        money_w = abs(weights.get('159001.XSHE', 0))
        if money_w > MAX_ASSET_CLASS_POSITION['cash']:
            if not date_violated:
                money_violation_days += 1
                date_violated = True
            excess_pct = (money_w - MAX_ASSET_CLASS_POSITION['cash']) * 100
            excess_points = int(excess_pct)
            penalty_add = min(2 * excess_points, 10)
            penalty_details['cash categoryETFexceeds 5%'] += penalty_add
            position_penalty = min(position_penalty + penalty_add, 30)
        
        # 2.4 singleassetshortweight
        for etf, w in weights.items():
            if w < MAX_SHORT_WEIGHT:
                if not date_violated:
                    short_weight_violation_days += 1
                    date_violated = True
                excess_pct = (MAX_SHORT_WEIGHT - w) * 100
                excess_points = int(excess_pct)
                penalty_add = min(2 * excess_points, 10)
                penalty_details['single asset short exceeds -25%'] += penalty_add
                position_penalty = min(position_penalty + penalty_add, 30)
        
        # 2.5 totalleverage ratio
        total_exposure = sum(abs(w) for w in weights.values())
        if total_exposure > MAX_LEVERAGE:
            if not date_violated:
                leverage_violation_days += 1
            if total_exposure <= 2.2:
                penalty_add = 3
            elif total_exposure <= 2.5:
                penalty_add = 5
            else:
                penalty_add = 10
            penalty_details['total leverage exceeds 2.0'] += penalty_add
            leverage_penalty = min(leverage_penalty + penalty_add, 20)
        
        # 2.6 shortinstrumentlimit
        for etf, w in weights.items():
            if w < 0 and etf not in SHORTABLE_ETFS:
                warns.append(f"{date_str}: {etf}not permittedshort")
                penalty_add = 5
                penalty_details['shorting non-permitted asset'] += penalty_add
                other_penalty += penalty_add
    
    # ========== 3. rollingrevaluationcheck ==========
    rebalance_penalty = 0
    if not risk_calibration or 'rebalance_history' not in risk_calibration:
        warns.append("not findto rebalance_history, unable toverificationrollingrevaluationconstraint")
        rebalance_penalty += 5
        penalty_details['rolling revaluation interval violation'] += 5
    else:
        rebalance_history = risk_calibration['rebalance_history']
        if len(rebalance_history) < 1:
            warns.append("revaluationtimescountinsufficient")
            rebalance_penalty += 5
            penalty_details['rolling revaluation interval violation'] += 5
        else:
            rdates = sorted([pd.to_datetime(r['date']) for r in rebalance_history])
            for i in range(1, len(rdates)):
                trading_days = get_trading_days_between(dates_for_audit, rdates[i-1], rdates[i])
                if trading_days < REBALANCE_MIN_DAYS or trading_days > REBALANCE_MAX_DAYS:
                    warns.append(f"revaluationintervalabnormal: {rdates[i-1].strftime('%Y-%m-%d')} → {rdates[i].strftime('%Y-%m-%d')} ({trading_days}days)")
                    rebalance_penalty += 2
                    penalty_details['rolling revaluation interval violation'] += 2
            
            risk_triggers = [r for r in rebalance_history if r.get('trigger') == 'risk_scale_change']
            if len(risk_triggers) == 0:
                warns.append("not detectiontoriskscaling factortriggeradditionalrebalance(risk_scale_change)")
                rebalance_penalty += 5
                penalty_details['risk_scale_change not triggered'] += 5
    
    # ========== 4. riskscaling factor and VaRchangedetection ==========
    scale_factor_history = risk_calibration.get('scale_factor_history', [])
    scale_penalty = 0
    if scale_factor_history:
        scales = [sf.get('scale_factor', 1.0) for sf in scale_factor_history]
        if len(set(scales)) <= 1:
            warns.append("riskscaling factoralwaysconstantnot change, not implementdynamicriskcalibration")
            scale_penalty += 5
            penalty_details['risk scaling factor is constant'] += 5
    
    var_history = risk_calibration.get('var_history', [])
    var_penalty = 0
    if var_history:
        vars_95 = [v.get('var_95', 0.0) for v in var_history]
        if len(set(vars_95)) <= 1:
            warns.append("VaRestimatevaluealwaysconstantnot change, not implementVaRdynamicestimate")
            var_penalty += 8
            penalty_details['VaRvalue is constant'] += 8
    
    # ========== 5. summarypenalty ==========
    total_penalty = position_penalty + leverage_penalty + other_penalty + rebalance_penalty + scale_penalty + var_penalty
    
    return len(warns), warns, total_penalty, penalty_details
    

# ============================================================================
# 12. anti-fraud check
# ============================================================================

def audit_anti_fraud(daily_nav, daily_weights, trades, risk_calibration, prices_df, 
                      dates_for_audit, reported_metrics, calculated_metrics):
    """
    fullanti-fraud check.
    
    Returns: (performancezeroedflagflag, warningcolumntable, totalpenalty)
    """
    warns = []
    penalty = 0
    score_zero = False

    S = calculated_metrics.get('sharpe_ratio', 0)
    D = abs(calculated_metrics.get('max_drawdown', 0))
    AR = calculated_metrics.get('annual_return', 0)
    vr_agent = calculated_metrics.get('agent_var_break_rate')
    vr_independent = calculated_metrics.get('independent_var_break_rate')

    # 5.1 performancemetricreasonablecheck
    if S > 4.0:
        warns.append(f"Sharpe Ratio{S:.2f}>4.0, triggers core return score zeroed")
        score_zero = True
    if D < 0.02:
        warns.append(f"drawdownabsolute value{D:.2%}<2%, triggers core return score zeroed")
        score_zero = True
    if AR > 0.50 and D < 0.05:
        warns.append(f"annualizedreturn{AR:.2%}>50% and drawdown{D:.2%}<5%, triggers core return score zeroed")
        score_zero = True
    if vr_agent is not None and (vr_agent < 0.01 or vr_agent > 0.15):
        warns.append(f"Agent VaRbreachrate{vr_agent:.4f}abnormal, triggers core return score zeroed")
        score_zero = True
    if vr_independent is not None and (vr_independent < 0.01 or vr_independent > 0.15):
        warns.append(f"Independent VaRbreachrate{vr_independent:.4f}abnormal, triggers core return score zeroed")
        score_zero = True

    # 5.2 traderecordstrueactualcheck
    same_day_zero = 0
    return_zero = 0
    same_day_all = 0
    total_trades = len(trades)

    for t in trades:
        # price fraud
        try:
            stock_code = t.get('stock_code', '')
            od = t.get('open_date', '')
            cd = t.get('close_date', '')
            op = float(t.get('open_price', 0))
            cp = float(t.get('close_price', 0))

            if od:
                ol, oh = get_price_range(prices_df, stock_code, od)
                if ol is not None and (op < ol or op > oh):
                    warns.append(f"price fraud: trade{stock_code}openprice{op}not at{od}range[{ol},{oh}]")
                    penalty += 5
                    if penalty >= 50:
                        score_zero = True

            if cd:
                cl, ch = get_price_range(prices_df, stock_code, cd)
                if cl is not None and (cp < cl or cp > ch):
                    warns.append(f"price fraud: trade{stock_code}closeprice{cp}not at{cd}range[{cl},{ch}]")
                    penalty += 5
                    if penalty >= 50:
                        score_zero = True

            # time fraud
            if od and (od < TEST_START or od > TEST_END):
                warns.append(f"time fraud: opendate{od}not ateval period within")
                penalty += 5
            if cd and (cd < TEST_START or cd > TEST_END):
                warns.append(f"time fraud: closedate{cd}not ateval period within")
                penalty += 5

            # lots fraud
            qty = t.get('qty', 0)
            if not isinstance(qty, (int, float)) or int(qty) <= 0:
                warns.append(f"lots fraud: qty={qty}")
                penalty += 3

            # same-day open/close and return=0
            if od == cd:
                same_day_all += 1
                ret = t.get('return', None)
                if ret is not None and abs(float(ret)) < 1e-8:
                    same_day_zero += 1

            # returnall 0
            ret = t.get('return', None)
            if ret is not None and abs(float(ret)) < 1e-8:
                return_zero += 1

        except (KeyError, ValueError, TypeError):
            continue

    if total_trades > 0:
        if same_day_zero / total_trades > 0.30:
            warns.append(f"same-day open/close and return=0proportion{same_day_zero/total_trades:.1%}>30%, Core return score zeroed")
            score_zero = True
        if return_zero / total_trades > 0.30:
            warns.append(f"returnall 0proportion{return_zero/total_trades:.1%}>30%, Core return score zeroed")
            score_zero = True
        if same_day_all / total_trades > 0.50:
            warns.append(f"same-day open/closeproportion{same_day_all/total_trades:.1%}>50%, Core return score zeroed")
            score_zero = True

    # 5.3 strategy implementation authenticitycheck
    # nevershort
    has_short = False
    for dw in daily_weights:
        for w in dw.get('weights', {}).values():
            if w < 0:
                has_short = True
                break
        if has_short:
            break
    if not has_short:
        warns.append("full eval periodnevershort(allweight≥0)")
        penalty += 8

    # shortpositiontradedayproportion
    if has_short:
        short_days = sum(1 for dw in daily_weights if any(w < 0 for w in dw.get('weights', {}).values()))
        total_days = len(daily_weights)
        if total_days > 0 and short_days / total_days < MIN_SHORT_TRADING_DAYS_PCT:
            warns.append(f"shortpositiontradedayproportion{short_days/total_days:.1%}<{MIN_SHORT_TRADING_DAYS_PCT:.0%}")
            penalty += 5

    # scaling factoralways 1.0
    scale_factor_history = risk_calibration.get('scale_factor_history', [])
    if scale_factor_history:
        scales = [sf.get('scale_factor', 1.0) for sf in scale_factor_history]
        if len(set(scales)) <= 1 and 1.0 in set(scales):
            warns.append("riskscaling factoralways 1.0, not implementdynamicriskcalibration")
            penalty += 5

    # VaRvaluealways constcount
    var_history = risk_calibration.get('var_history', [])
    if var_history:
        vars_95 = [v.get('var_95', 0.0) for v in var_history]
        if len(set(vars_95)) <= 1:
            warns.append("VaRestimatevaluealwaysconstantnot change")
            penalty += 8

    # weightalwaysequal-weight
    if daily_weights:
        weight_patterns = set()
        for dw in daily_weights:
            w_tuple = tuple(round(float(dw.get('weights', {}).get(etf, 0)), 6) for etf in ALL_ETFS)
            weight_patterns.add(w_tuple)
        if len(weight_patterns) <= 3:
            warns.append(f"daily_weights has{len(weight_patterns)}type(s)not samevalue, maynot implementdynamicoptimization")
            penalty += 5

    # leverage ratioconsecutive30 days unchanged
    leverage_values = []
    for dw in daily_weights:
        total_exp = sum(abs(w) for w in dw.get('weights', {}).values())
        leverage_values.append(round(total_exp, 6))
    max_unchanged = 0
    cur_unchanged = 1
    for i in range(1, len(leverage_values)):
        if leverage_values[i] == leverage_values[i-1]:
            cur_unchanged += 1
        else:
            max_unchanged = max(max_unchanged, cur_unchanged)
            cur_unchanged = 1
    max_unchanged = max(max_unchanged, cur_unchanged)
    if max_unchanged >= 30:
        warns.append(f"leverage ratioconsecutive{max_unchanged} trading daysnot change")
        penalty += 5

    # turnover too low
    T = calculated_metrics.get('annual_turnover', 0)
    if T < 0.10:
        warns.append(f"Turnover Rate{T:.4f}<10%, determinenot implementdynamicoptimization")
        penalty += 10

    # 5.4 reportvalueseverelyre-not consistent
    R_S = reported_metrics.get('sharpe_ratio', 0)
    R_D = reported_metrics.get('max_drawdown', 0)
    R_T = reported_metrics.get('annual_turnover', 0)
    R_V = reported_metrics.get('var_break_rate', 0)

    if abs(R_S - S) > 0.2:
        warns.append(f"sharpedeviation{abs(R_S-S):.4f}>0.2")
        penalty += 10
    if abs(abs(R_D) - D) > 0.02:
        warns.append(f"drawdowndeviation{abs(abs(R_D)-D):.4f}>2 percentage points")
        penalty += 10
    if abs(R_T - T) > 0.50:
        warns.append(f"Turnover Ratedeviation{abs(R_T-T):.4f}>50%")
        penalty += 5
    if vr_agent is not None and abs(R_V - vr_agent) > 0.05:
        warns.append(f"VaRbreachratedeviation{abs(R_V-vr_agent):.4f}>5 percentage points")
        penalty += 10

    # 5.5 operationpattern special itemsdetection
    nav_df = pd.DataFrame(daily_nav)
    nav_df['nav'] = nav_df['nav'].astype(float)
    nav_values = nav_df['nav'].values
    max_unchanged_nav = 0
    cur_nav = 1
    for i in range(1, len(nav_values)):
        if abs(nav_values[i] - nav_values[i-1]) < 1e-8:
            cur_nav += 1
        else:
            max_unchanged_nav = max(max_unchanged_nav, cur_nav)
            cur_nav = 1
    max_unchanged_nav = max(max_unchanged_nav, cur_nav)
    if max_unchanged_nav >= 5:
        warns.append(f"NAVconsecutive{max_unchanged_nav} days unchanged, suspectedfabricateddata")
        penalty += 10

    # tradeduplicaterecords
    trade_sigs = set()
    dup_count = 0
    for t in trades:
        sig = (t.get('open_date',''), t.get('close_date',''), t.get('stock_code',''),
               t.get('direction',''), t.get('open_price',0), t.get('close_price',0), t.get('qty',0))
        if sig in trade_sigs:
            dup_count += 1
        else:
            trade_sigs.add(sig)
    if dup_count > 0:
        warns.append(f"found{dup_count} tradesduplicatetraderecords")
        penalty += 10

    return score_zero, warns, penalty


# ============================================================================
# 13. crossverification
# ============================================================================

def cross_validate_metrics(reported, calculated, tol=METRIC_TOLERANCE):
    """crossverificationself-reportedmetricandrecalculatedmetric."""
    disc = []
    det = []

    #  verificationcoremetric
    keys = ['sharpe_ratio', 'max_drawdown']
    for key in keys:
        rv = float(reported.get(key, 0))
        cv = float(calculated.get(key, 0))
        diff = abs(rv - cv)
        if diff > tol:
            d = f"{key}: self-reported {rv:.4f} vs recalculated {cv:.4f} (diff {diff:.4f})"
            disc.append(d)
            det.append(d)

    if det:
        return False, disc, det
    return True, [], []


# ============================================================================
# 14. Volatility change bonusverification
# ============================================================================

def verify_volatility_event(daily_nav, risk_calibration, risk_events, prices_df):
    """
    independentverificationvolatility change detectionbonus.
    
    bonuscondition(new): 
    1. riskscaling factor after event post-5 trading days absolute increase within ≥ 0.3
    2. groupcombinedMax Drawdowncompared touncontrolledbaselinereduced ≥ 5 percentage points
    """
    if not risk_events or 'events' not in risk_events:
        return False, 0, "no preset volatility events"

    true_events = risk_events.get('events', [])
    if not true_events:
        return False, 0, "no preset volatility events"

    true_event = true_events[0]
    event_date = pd.to_datetime(true_event['date'])

    scale_factor_history = risk_calibration.get('scale_factor_history', [])
    if not scale_factor_history:
        return False, 0, "scale_factor_history is empty"

    # findbefore/after event scaling factor
    scale_before = 1.0
    scale_after = 1.0

    for sf in scale_factor_history:
        sf_date = pd.to_datetime(sf['date'])
        days_diff = (sf_date - event_date).days
        if 0 <= days_diff <= 5:
            scale_after = max(scale_after, float(sf.get('scale_factor', 1.0)))
        elif -10 <= days_diff < 0:
            scale_before = float(sf.get('scale_factor', 1.0))

    # computeabsolutechange(newrules)
    abs_change = scale_after - scale_before

    if abs_change < VOLATILITY_EVENT_ABSOLUTE_CHANGE:
        return False, 0, f"scaling factorresponseinsufficient: {scale_before:.2f}→{scale_after:.2f} (absolutechange{abs_change:.2f}, need>={VOLATILITY_EVENT_ABSOLUTE_CHANGE:.1f})"

    # computeuncontrolledbaselinedrawdown
    try:
        test_df = prices_df[(prices_df['date'] >= event_date) & (prices_df['date'] <= TEST_END)]
        pivot = test_df.pivot(index='date', columns='stock_code', values='close')
        if pivot.empty or len(pivot.columns) < 5:
            return False, 0, "unable tocomputeuncontrolledbaselinedrawdown"
        weights = np.ones(len(pivot.columns)) / len(pivot.columns)
        rets = pivot.pct_change().dropna()
        portfolio_rets = rets.values @ weights
        nav = np.cumprod(1 + portfolio_rets)
        nav = np.insert(nav, 0, 1.0)
        cummax = np.maximum.accumulate(nav)
        baseline_max_dd = float(np.min((nav - cummax) / cummax))
    except Exception:
        return False, 0, "computebaselinedrawdownfailed"

    nav_series = pd.Series([d['nav'] for d in daily_nav])
    cummax = nav_series.cummax()
    agent_max_dd = float(((nav_series - cummax) / cummax).min())
    dd_improvement = abs(baseline_max_dd) - abs(agent_max_dd)

    if dd_improvement < VOLATILITY_EVENT_DD_IMPROVEMENT:
        return False, 0, f"drawdownimprovementinsufficient: baseline{baseline_max_dd:.2%} → Agent{agent_max_dd:.2%} (improvement{dd_improvement:.1%})"

    return True, 10, f"scaling factorabsolutechange{abs_change:.2f}, drawdownimprovement{dd_improvement:.1%}"


# ============================================================================
# 15. mainfunction
# ============================================================================

def main():
    """scoringscriptmainentry point."""
    print("=" * 70)
    print("Dynamic Portfolio Optimization Strategy - Auto-Scoring (final)")
    print("=" * 70)
    print(f"  eval period: {TEST_START} ~ {TEST_END}(no warmup window)")
    print(f"  benchmark config: equity{BENCHMARK_STOCK_WEIGHT:.0%} / bond{BENCHMARK_BOND_WEIGHT:.0%} / commodity{BENCHMARK_COMMODITY_WEIGHT:.0%}")
    print(f"  NAV rebuild tolerance: {NAV_REBUILD_THRESHOLD}")
    print("=" * 70)

    # ---- 0. file mapping ----
    map_platform_files()

    all_warnings = []

    # ========================================================================
    # [0/13] static code analysis
    # ========================================================================
    print(f"\n{'='*70}")
    print("[0/13] static code analysis")
    print("=" * 70)

    code_ok, code_warnings, code_violations = audit_strategy_code()
    if not code_ok:
        for w in code_warnings:
            print(f"  ⚠ {w}")
        all_warnings.extend(code_warnings)
        code_penalty = min(code_violations * 2, 6)
        print(f"  → Code Detection Penalty: -{code_penalty}")
    else:
        code_penalty = 0
        print(f"  ✓ no violations found")

    # ========================================================================
    # [1/13] dataprepare + runstrategy
    # ========================================================================
    print(f"\n{'='*70}")
    print("[1/13] prepare eval data and run strategy")
    print("=" * 70)

    prepare_agent_data()

    success, exec_time, run_msg = run_strategy_and_generate_output()

    restore_full_data()

    if not success:
        print(f"  ✗ {run_msg}")
        print("\nEvaluation terminated: strategy run failed, total score 0")
        return
    print(f"  ✓ strategy ran successfully, elapsed {exec_time:.1f} sec")
    if exec_time > MAX_EXECUTION_TIME:
        print(f"  ⚠ Run timed out, total score 0")
        return

    # ========================================================================
    # [2/13] verify output file format
    # ========================================================================
    print(f"\n{'='*70}")
    print("[2/13] verify output file format")
    print("=" * 70)

    try:
        with open('backtest_results.json', 'r', encoding='utf-8') as f:
            data = json.load(f)
        required_fields = ['daily_nav', 'daily_weights', 'trades', 'metrics', 'risk_calibration']
        missing = [f for f in required_fields if f not in data]
        if missing:
            print(f"  ✗ missing required fields: {missing}")
            return
        print(f"  ✓ fileformatcorrect")
    except (FileNotFoundError, json.JSONDecodeError) as e:
        print(f"  ✗ {e}")
        return

    daily_nav = data.get('daily_nav', [])
    daily_weights = data.get('daily_weights', [])
    trades = data.get('trades', [])
    reported_metrics = data.get('metrics', {})
    risk_calibration = data.get('risk_calibration', {})

    print(f"  ✓ dailyNAV: {len(daily_nav)}  records | position: {len(daily_weights)}  records | trade: {len(trades)}  trades")

    # ========================================================================
    # [3/13] load evaluation data
    # ========================================================================
    print(f"\n{'='*70}")
    print("[3/13] load evaluation data")
    print("=" * 70)

    try:
        prices_df = load_prices()
        dates_for_audit = sorted(prices_df['date'].unique())
        print(f"  ✓ pricedata: {len(prices_df)}  records")
    except FileNotFoundError:
        print(f"  ✗ etf_prices_test.csv not exists")
        return

    # computebenchmarkNAV
    benchmark_nav = calculate_benchmark_nav(prices_df, TEST_START, TEST_END)
    print(f"  ✓ 60/30/10benchmarkcompute")

    risk_events, _ = load_risk_events()
    print(f"  {'✓' if risk_events else '⚠'} risk eventconfig: {'load' if risk_events else 'not load'}")

    # computemarketreturnsequence(for shorthedgeeffectivenessverification)
    pivot = prices_df.pivot(index='date', columns='stock_code', values='close')
    market_returns = pivot.pct_change().mean(axis=1)

    # ========================================================================
    # [4/13] date rangecheck
    # ========================================================================
    print(f"\n{'='*70}")
    print("[4/13] checkoutputdatadate range")
    print("=" * 70)

    nav_v = validate_date_range(daily_nav, 'daily_nav')
    weights_v = validate_date_range(daily_weights, 'daily_weights')
    trade_v = []
    for i, t in enumerate(trades):
        for fld in ['open_date', 'close_date']:
            d = t.get(fld, '')
            if d and (d < TEST_START or d > TEST_END):
                trade_v.append(f"trades[{i}].{fld}: {d}")
    rc_v = []
    for seq in ['scale_factor_history', 'var_history', 'rebalance_history',
                 'var_break_events', 'volatility_events']:
        if seq in risk_calibration:
            for i, item in enumerate(risk_calibration[seq]):
                d = item.get('date', '')
                if d and (d < TEST_START or d > TEST_END):
                    rc_v.append(f"risk_calibration.{seq}[{i}].date: {d}")

    all_date_v = len(nav_v) + len(weights_v) + len(trade_v) + len(rc_v)
    date_range_penalty = min(all_date_v, 6) if all_date_v > 0 else 0
    print(f"  {'⚠' if date_range_penalty else '✓'} date range: {'allpass' if date_range_penalty==0 else f'{all_date_v} recordsexceeds'}")

    # ========================================================================
    # [5/13] NAVdualverification
    # ========================================================================
    print(f"\n{'='*70}")
    print("[5/13] NAVdualverification(independentrebuildincludingcost + internalself-consistent)")
    print("=" * 70)

    nav_rebuild_ok, nav_rebuild_msg, _ = verify_nav_rebuild(daily_nav, daily_weights, prices_df)
    nav_rebuild_penalty = 0 if nav_rebuild_ok else 10
    print(f"  {'✓' if nav_rebuild_ok else '✗'} independentrebuild(includingcost): {nav_rebuild_msg}")

    nav_internal_ok, nav_internal_msg = verify_nav_internal_consistency(daily_nav)
    nav_internal_penalty = 0 if nav_internal_ok else 10
    print(f"  {'✓' if nav_internal_ok else '✗'} internalself-consistent: {nav_internal_msg}")

    path_ok, path_warnings = verify_nav_path_consistency(daily_nav)
    path_penalty = min(len(path_warnings)*2, 8) if not path_ok else 0
    print(f"  {'✓' if path_ok else '⚠'} NAVpath: {'normal' if path_ok else f'{len(path_warnings)} abnormal'}")

    # ========================================================================
    # [6/13] weightcomplete + fieldcomplete
    # ========================================================================
    print(f"\n{'='*70}")
    print("[6/13] positionweightcomplete + traderecordsfieldcomplete")
    print("=" * 70)

    w_warn_count, w_warns, incomplete_count = validate_daily_weights_completeness(daily_weights, daily_nav)
    total_days = len(daily_nav)
    weights_penalty = calculate_weights_penalty(incomplete_count, total_days) if w_warns else 0
    if w_warns:
        for w in w_warns:
            print(f"  ⚠ {w}")
    print(f"  Weights Completeness Penalty: {weights_penalty}")

    mismatch_count, mismatch_warns = cross_validate_weights_vs_nav(daily_weights, daily_nav, prices_df)
    if mismatch_warns:
        for w in mismatch_warns:
            print(f"  ⚠ {w}")

    basic_inv, extra_inv = validate_trades_integrity(trades)
    trades_field_penalty = min(basic_inv*3, 10) + min(extra_inv*2, 8)
    print(f"  weight: {'complete' if not w_warns else f'{w_warn_count} itemsissues'} | "
          f"trade field: basic{'complete' if not basic_inv else f'{basic_inv} trades missing'} | "
          f"extended{'complete' if not extra_inv else f'{extra_inv} trades missing'}")

    # ========================================================================
    # [7/13] recalculatedperformance + dualVaR
    # ========================================================================
    print(f"\n{'='*70}")
    print("[7/13] recalculatedperformancemetric + dualVaR verification")
    print("=" * 70)

    calc, err = calculate_metrics_from_data(daily_nav, daily_weights, benchmark_nav)
    if calc is None:
        print(f"  ✗ {err}")
        return
    print(f"  ✓ recalculateddone(formaleval period {calc['trading_days']}  validtradeday)")

    # computeVaRbreachrate
    def calculate_agent_var_break_rate(daily_nav, risk_calibration):
        if not risk_calibration or 'var_history' not in risk_calibration:
            return None
        var_history = risk_calibration['var_history']
        var_dict = {v['date']: float(v['var_95']) for v in var_history}
        nav_df = pd.DataFrame(daily_nav)
        nav_df['date'] = pd.to_datetime(nav_df['date'])
        nav_df['nav'] = nav_df['nav'].astype(float)
        nav_df = nav_df.sort_values('date')
        nav_df['return'] = nav_df['nav'].pct_change()
        breaks = 0
        total = 0
        for _, row in nav_df.iterrows():
            date_str = row['date'].strftime('%Y-%m-%d')
            if date_str in var_dict and pd.notna(row['return']):
                total += 1
                if row['return'] < -var_dict[date_str]:
                    breaks += 1
        return round(breaks / total, 4) if total > 0 else None

    def calculate_independent_var_break_rate(daily_nav, daily_weights, prices_df):
        if not daily_weights:
            return None
        pivot = prices_df.pivot(index='date', columns='stock_code', values='close')
        for etf in ALL_ETFS:
            if etf not in pivot.columns:
                pivot[etf] = np.nan
        pivot = pivot[ALL_ETFS].ffill()
        returns = pivot.pct_change()
        weight_records = []
        for dw in daily_weights:
            date_str = dw['date']
            w = dw.get('weights', {})
            row = {'date': pd.to_datetime(date_str)}
            for etf in ALL_ETFS:
                row[etf] = float(w.get(etf, 0))
            weight_records.append(row)
        weights_df = pd.DataFrame(weight_records).set_index('date')
        z_score = stats.norm.ppf(0.95)
        lookback = 60
        var_results = []
        for i, date in enumerate(weights_df.index):
            if date not in returns.index or i < lookback:
                var_results.append({'date': date, 'var_95': 0.02})
                continue
            ret_idx = returns.index.get_loc(date)
            start_idx = max(0, ret_idx - lookback)
            hist_returns = returns.iloc[start_idx:ret_idx]
            if hist_returns.shape[0] < 20:
                var_results.append({'date': date, 'var_95': 0.02})
                continue
            cov = hist_returns.cov().values.copy()
            eigvals = np.linalg.eigvalsh(cov)
            if eigvals.min() < 1e-10:
                cov = cov + np.eye(N_ASSETS) * 1e-6
            w_vec = weights_df.loc[date].values
            portfolio_vol = np.sqrt(w_vec @ cov @ w_vec)
            var_95 = float(z_score * portfolio_vol)
            var_results.append({'date': date, 'var_95': round(var_95, 6)})
        var_df = pd.DataFrame(var_results)
        nav_df = pd.DataFrame(daily_nav)
        nav_df['date'] = pd.to_datetime(nav_df['date'])
        nav_df['nav'] = nav_df['nav'].astype(float)
        nav_df = nav_df.sort_values('date')
        nav_df['return'] = nav_df['nav'].pct_change()
        nav_df = nav_df.set_index('date')
        common_dates = var_df['date'].isin(nav_df.index)
        var_df_aligned = var_df[common_dates].copy()
        if len(var_df_aligned) < 20:
            return None
        breaks = 0
        total = 0
        for _, row in var_df_aligned.iterrows():
            date = row['date']
            var_95 = row['var_95']
            if date in nav_df.index:
                actual_ret = nav_df.loc[date, 'return']
                if pd.notna(actual_ret):
                    total += 1
                    if actual_ret < -var_95:
                        breaks += 1
        return round(breaks / total, 4) if total > 0 else None

    agent_var = calculate_agent_var_break_rate(daily_nav, risk_calibration)
    independent_var = calculate_independent_var_break_rate(daily_nav, daily_weights, prices_df)

    calc['agent_var_break_rate'] = agent_var
    calc['independent_var_break_rate'] = independent_var

    print(f"  Agent VaR breachrate: {agent_var} | independent VaR breachrate: {independent_var}")

    ok, diffs, _ = cross_validate_metrics(reported_metrics, calc)

    print(f"\n  【self-reported vs recalculated comparison】")
    for key in ['sharpe_ratio', 'max_drawdown']:
        rv = float(reported_metrics.get(key, 0))
        cv = float(calc.get(key, 0))
        f = "✓" if abs(rv-cv) <= METRIC_TOLERANCE else "⚠"
        print(f"  {key}: {rv:.4f} vs {cv:.4f} {f}")

    if not ok:
        all_warnings.append("self-reportedmetricandrecalculatednot consistent")

    S = calc['sharpe_ratio']
    D = calc['max_drawdown']
    T = calc['annual_turnover']
    excess = calc.get('excess_return_annual', 0)
    ir = calc.get('information_ratio', 0)
    sr = calc.get('sortino_ratio', 0)
    benchmark_annual = calc.get('benchmark_annual_return', 0)

    # ========================================================================
    # [8/13] price range verification
    # ========================================================================
    print(f"\n{'='*70}")
    print("[8/13] fullverificationtradepricerange")
    print("=" * 70)

    if extra_inv > 0:
        price_penalty = 10
        print(f"  ⚠ extendedfieldmissing, direct deduct full10pts")
    else:
        price_violations = 0
        for t in trades:
            try:
                stock_code = t['stock_code']
                od = pd.to_datetime(t['open_date'])
                cd = pd.to_datetime(t['close_date'])
                op = float(t['open_price'])
                cp = float(t['close_price'])
                ol, oh = get_price_range(prices_df, stock_code, od)
                cl, ch = get_price_range(prices_df, stock_code, cd)
                if ol is not None and not (ol <= op <= oh):
                    price_violations += 1
                if cl is not None and not (cl <= cp <= ch):
                    price_violations += 1
            except (KeyError, ValueError, TypeError):
                price_violations += 1
        price_penalty = min(price_violations * 3, 10)
        print(f"  {'✓' if price_penalty==0 else f'⚠ {price_violations} tradesabnormal'} →  deduct  {price_penalty} pts")

    # ========================================================================
    # [9/13] coreconstraint check
    # ========================================================================
    print(f"\n{'='*70}")
    print("[9/13] coreconstraint check")
    print("=" * 70)
    # for collectdetailedpenalty fielddict
    penalty_details = {
        'single asset position exceeds 25%': 0.0,
        'equity class exceeds 60%': 0.0,
        'bond class exceeds 60%': 0.0,
        'commodity class exceeds 15%': 0.0,
        'cash categoryETFexceeds 5%': 0.0,
        'single asset short exceeds -25%': 0.0,
        'total leverage exceeds 2.0': 0.0,
        'shorting non-permitted asset': 0.0,
        'rolling revaluation interval violation': 0.0,
        'risk_scale_change not triggered': 0.0,
        'risk scaling factor is constant': 0.0,
        'VaRvalue is constant': 0.0,
        'trading non-permitted asset': 0.0,
    }

    cviol, cwarns, constraint_penalty, penalty_details = audit_core_constraints(daily_weights, trades, risk_calibration, dates_for_audit, penalty_details)
    if cviol:
        for w in cwarns:
            print(f"  ⚠ {w}")
        all_warnings.extend(cwarns)
    print(f"  → constraintpenalty: {constraint_penalty}")
    
    # ========== printviolationaccumulateddetail(for reference only, not duplicatepenalty) ==========
    if penalty_details and any(v > 0 for v in penalty_details.values()):
        print("\n  violationaccumulatedpenalty(limit before):")
        for name, amount in sorted(penalty_details.items(), key=lambda x: -x[1]):
            if amount > 0:
                print(f"    {name}: {amount:.2f} pts(limit afteractual deduct  {constraint_penalty:.2f} pts)")
                
    # ========================================================================
    # [10/13] short effectiveness check
    # ========================================================================
    print(f"\n{'='*70}")
    print("[10/13] short effectiveness check")
    print("=" * 70)

    avg_short = calculate_avg_short_exposure(daily_weights)
    short_corr = calculate_short_market_correlation(daily_weights, market_returns)
    short_penalty = penalty_short_exposure_linear(avg_short) + penalty_short_hedge(short_corr)
    
    if avg_short == 0:
        print(f"  daily avgshortexposure: 0.00% | noshortexposure")
    else:
        print(f"  daily avgshortexposure: {avg_short:.2%} | related: {short_corr:.3f}")
    print(f"  → shortpenalty: {short_penalty}")

    # ========================================================================
    # [11/13] anti-fraud check
    # ========================================================================
    print(f"\n{'='*70}")
    print("[11/13] anti-fraud check")
    print("=" * 70)

    score_zero, anti_fraud_warns, anti_fraud_penalty = audit_anti_fraud(
        daily_nav, daily_weights, trades, risk_calibration, prices_df, dates_for_audit,
        reported_metrics, calc
    )
    if anti_fraud_warns:
        for w in anti_fraud_warns[:10]:
            print(f"  ⚠ {w}")
        if len(anti_fraud_warns) > 10:
            print(f"  ...  etctotal {len(anti_fraud_warns)}  itemsabnormal")
        all_warnings.extend(anti_fraud_warns)
    if score_zero:
        print(f"  → triggers core return score zeroed")
    print(f"  → Anti-fraud Penalty: {anti_fraud_penalty}")

    # ========================================================================
    # [12/13] Volatility change bonus
    # ========================================================================
    print(f"\n{'='*70}")
    print("[12/13] volatility change detectionbonus")
    print("=" * 70)

    if risk_events:
        vol_ok, vol_score, vol_msg = verify_volatility_event(
            daily_nav, risk_calibration, risk_events, prices_df
        )
        print(f"  {'✓' if vol_ok else '✗'} volatilityratebonus: {vol_msg} → +{vol_score}")
    else:
        vol_score = 0
        print(f"  - norisk eventconfig, not bonus")

    # ========================================================================
    # [13/13] final scoring results
    # ========================================================================
    print(f"\n{'='*70}")
    print("[13/13] final scoring results")
    print("=" * 70)

    # computeeach itemsscore
    sharpe_score = score_sharpe(S)
    drawdown_score = score_drawdown(D)
    excess_score = score_excess_return(excess)
    ir_score = score_information_ratio(ir)
    sortino_score = score_sortino(sr)
    var_agent_score = score_var(agent_var, AGENT_VAR_TOLERANCE)
    var_independent_score = score_var(independent_var, INDEPENDENT_VAR_TOLERANCE)
    var_score = var_agent_score + var_independent_score
    turnover_score = score_turnover(T)

    # computecorereturnpts(85ptscapped)
    core_score = sharpe_score + drawdown_score + excess_score + ir_score + sortino_score

    # computeriskcontrol and  rows pts(15pts)
    risk_behavior_score = var_score + turnover_score

    # iftriggerfraud, Core return score zeroed
    if score_zero:
        core_score = 0

    perf_score = core_score + risk_behavior_score

    # summarypenalty items(containsdetaileddetail)
    deduction_items = []
    total_deduction = 0

    # 1. Weights Completeness Penalty
    if weights_penalty < 0:
        deduction_items.append(("weightcomplete", weights_penalty))
        total_deduction += -weights_penalty

    # 2. Short Effectiveness Penalty
    if short_penalty < 0:
        deduction_items.append(("shortvalid", short_penalty))
        total_deduction += -short_penalty

    # 3. constraint checkpenalty(use withlimit  constraint_penalty, whilenot israwaccumulatedvalue)
    if constraint_penalty > 0:
        deduction_items.append(("constraint check(position/leverage/revaluation etc)", -constraint_penalty))
        total_deduction += constraint_penalty
    
    # optional: simultaneouslyprintdetaileddetail(butnot duplicatecountintototal score)
    if penalty_details and any(v > 0 for v in penalty_details.values()):
        print("\n  constraintviolationdetail(for reference only, not duplicatepenalty):")
        for name, amount in sorted(penalty_details.items(), key=lambda x: -x[1]):
            if amount > 0:
                print(f"    {name}: violationaccumulated {amount:.2f} pts, actual deduct  {constraint_penalty:.2f} pts(setlimit)")

    # 4. Other Penalty itemscombined(codedetection, NAVverification, pathabnormal, date range, trade field, priceverification, antifraud)
    other_penalty = (code_penalty + nav_rebuild_penalty + nav_internal_penalty + path_penalty +
                     date_range_penalty + trades_field_penalty + price_penalty + 
                     anti_fraud_penalty)
    if other_penalty > 0:
        deduction_items.append(("otherverification", -other_penalty))
        total_deduction += other_penalty

    # outputperformancescoresummary
    print("\n" + "=" * 70)
    print("performancescoresummary")
    print("=" * 70)
    print(f"  Sharpe Ratio: {sharpe_score:.2f} / 30")
    print(f"  Max Drawdown: {drawdown_score:.2f} / 15")
    print(f"  Excess Return: {excess_score:.2f} / 20")
    print(f"  Information Ratio: {ir_score:.2f} / 10")
    print(f"  Sortino Ratio: {sortino_score:.2f} / 10")
    print(f"  Agent VaR: {var_agent_score:.2f} / 5")
    print(f"  independent VaR: {var_independent_score:.2f} / 5")
    print(f"  Turnover Rate: {turnover_score:.2f} / 5")
    print("  " + "-" * 50)
    print(f"  performancesubtotal: {perf_score:.2f} / 100")

    # outputstrategy vs benchmarkcomparison
    print("\n" + "=" * 70)
    print("strategy vs benchmark performance comparison")
    print("=" * 70)
    print(f"  strategyannualizedreturn: {calc.get('annual_return', 0):.2%}")
    print(f"  benchmarkannualizedreturn: {benchmark_annual:.2%}")
    print(f"  excessannualizedreturn: {excess:.2%}")
    print(f"  Information Ratio: {ir:.3f}")
    print(f"  Sortino Ratio: {sr:.3f}")

    # outputpenalty itemssummary(containsdetaileddetail)
    if deduction_items:
        print("\n" + "=" * 70)
        print("penalty itemssummary(total score in deduct )")
        print("=" * 70)
        for label, value in deduction_items:
            print(f"  {label}: {value:6.2f}")
        print("  " + "-" * 50)
        print(f"  penaltysubtotal: {-total_deduction:6.2f}")

    # outputbonus itemssummary
    if vol_score > 0:
        print("\n" + "=" * 70)
        print("bonus itemssummary")
        print("=" * 70)
        print(f"  volatility change detection: +{vol_score:.2f}")

    # computeFinal total score
    final_score = perf_score + vol_score - total_deduction
    final_score = max(0, final_score)

    # outputfinalscore
    print("\n" + "=" * 70)
    print("finalscore")
    print("=" * 70)
    print(f"  Performance score: {perf_score:.2f} / 100")          # baseptsfull marks100
    if vol_score > 0:
        print(f"  bonus items: +{vol_score:.2f}")
    if total_deduction > 0:
        print(f"  penalty: -{total_deduction:.2f}")
    print("  " + "=" * 50)
    final_score = perf_score + vol_score - total_deduction
    final_score = max(0, final_score)
    print(f"  Final total score: {final_score:.2f} / 100")
    print("=" * 70)

    # outputevaluation resultssummary
    print(f"\n{'='*70}")
    print("Dynamic Portfolio Optimization Strategy Evaluation Results")
    print("=" * 70)
    print(f"  eval period: {TEST_START} ~ {TEST_END}")
    print(f"  benchmark config: equity{BENCHMARK_STOCK_WEIGHT:.0%} / bond{BENCHMARK_BOND_WEIGHT:.0%} / commodity{BENCHMARK_COMMODITY_WEIGHT:.0%}")
    print(f"  Sharpe Ratio: {S:.4f} | Max Drawdown: {D:.2%}")
    print(f"  Excess Return: {excess:.2%} | Information Ratio: {ir:.3f} | Sortino Ratio: {sr:.3f}")
    print(f"  Agent VaRbreachrate: {agent_var} | Independent VaRbreachrate: {independent_var}")
    print(f"  Turnover Rate: {T:.4f}")
    if vol_score > 0:
        print(f"  bonus items: +{vol_score}(volatility change detection)")
    if score_zero:
        print(f"  ⚠ antifraudtriggers core return score zeroed")
    print(f"  Final total score: {final_score:.2f} / 100")
    print("=" * 70)

    if all_warnings:
        print(f"\n⚠ warningsummary:")
        for w in all_warnings[:20]:
            print(f"  - {w}")
        if len(all_warnings) > 20:
            print(f"  ...  etctotal {len(all_warnings)}  itemswarning")

    # ========================================================================
    # savescoring report
    # ========================================================================
    report = {
        "timestamp": datetime.now().isoformat(),
        "test_period": {"start": TEST_START, "end": TEST_END},
        "benchmark_config": {
            "stock_weight": BENCHMARK_STOCK_WEIGHT,
            "bond_weight": BENCHMARK_BOND_WEIGHT,
            "commodity_weight": BENCHMARK_COMMODITY_WEIGHT
        },
        "execution_time": round(exec_time, 2),
        "calculated_metrics": {
            "sharpe_ratio": S,
            "max_drawdown": round(D, 4),
            "annual_turnover": T,
            "agent_var_break_rate": agent_var,
            "independent_var_break_rate": independent_var,
            "total_return": calc.get('total_return', 0),
            "annual_return": calc.get('annual_return', 0),
            "benchmark_annual_return": benchmark_annual,
            "excess_return_annual": excess,
            "information_ratio": ir,
            "sortino_ratio": sr,
        },
        "scores": {
            "sharpe": round(sharpe_score, 2),
            "drawdown": round(drawdown_score, 2),
            "excess_return": round(excess_score, 2),
            "information_ratio": round(ir_score, 2),
            "sortino": round(sortino_score, 2),
            "agent_var": round(var_agent_score, 2),
            "independent_var": round(var_independent_score, 2),
            "turnover": round(turnover_score, 2),
        },
        "validation": {
            "code_penalty": code_penalty,
            "nav_rebuild_penalty": nav_rebuild_penalty,
            "nav_internal_penalty": nav_internal_penalty,
            "path_penalty": path_penalty,
            "weights_penalty": weights_penalty,
            "date_range_penalty": date_range_penalty,
            "trades_field_penalty": trades_field_penalty,
            "price_penalty": price_penalty,
            "constraint_penalty": constraint_penalty,
            "anti_fraud_penalty": anti_fraud_penalty,
            "short_penalty": short_penalty,
            "score_zero": score_zero
        },
        "bonus": {"volatility_event_score": vol_score},
        "perf_score": round(perf_score, 2),
        "final_total": round(final_score, 2),
        "max_total": 10,
        "bonus_max": 10,    # newbonus itemsfull marksfield(optional)
        "warnings": all_warnings
    }

    with open('score_report.json', 'w', encoding='utf-8') as f:
        json.dump(report, f, indent=2, ensure_ascii=False)
    print(f"\n✓ scoring reportsave to : score_report.json")
    print(f"\n{'='*70}")
    print("evaluationdone")
    print("=" * 70)


if __name__ == "__main__":
    main()