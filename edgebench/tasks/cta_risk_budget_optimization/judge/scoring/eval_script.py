#!/usr/bin/env python3
"""
CTA Fund - Cross-border Commodity Futures Multi-Strategy - Automated Eval Script
============================================================
Max 80 points = Automated scoring (80 pts)

Scoring difficulty: iterated to ensure AI scores <30 within 30 min.
Core difficulty mechanisms:
1. Schema gate: NAV must be total CNY amount, otherwise multiple dimensions score 0
2. Risk veto: max drawdown>15% or vol out of range -> risk dimension all 0
3. Performance scoring strict: merely beating benchmark earns 0; must significantly exceed or reach absolute targets
4. Signal verification: each factor must pass specific statistical tests, not simple column checks
5. Code compliance (10 pts): random seed / library restrictions / cost source / FX source / time limit

Usage:
    python eval_script.py --submission_dir <submission_dir> --data_dir <data_dir> \
        --standard_answer_dir <standard_answer_dir> \
        --run_agent_code --timeout 14400

Output:
    eval_results.json / eval_report.xlsx
"""

import argparse
import json
import os
import sys
import subprocess
import traceback
import time
import importlib.util
import re
from datetime import datetime
import numpy as np
import pandas as pd
from openpyxl import Workbook
from openpyxl.styles import Font, Alignment, PatternFill, Border, Side

PERF_START_DATE = '2020-07-01'

OVERSEAS_TICKERS = [
    'CL.CME', 'GC.CME', 'SI.CME', 'HG.CME', 'W.CME', 'S.CME',
    'C.CME', 'BO.CME', 'SB.ICE', 'CT.ICE', 'LME.LME', 'LMA.LME'
]

MEANREV_PAIRS = [
    ('M.DCE', 'Y.DCE'),
    ('RB.SHF', 'I.DCE'),
    ('J.DCE', 'JM.DCE'),
    ('CU.SHF', 'LME.LME'),
    ('AU.SHF', 'GC.CME'),
    ('SC.INE', 'CL.CME'),
]

SECTOR_MAP = {
    'CU.SHF': 'non_ferrous_metals', 'AL.SHF': 'non_ferrous_metals', 'ZN.SHF': 'non_ferrous_metals',
    'AU.SHF': 'precious_metals', 'AG.SHF': 'precious_metals',
    'RB.SHF': 'ferrous_metals', 'HC.SHF': 'ferrous_metals', 'I.DCE': 'ferrous_metals',
    'J.DCE': 'ferrous_metals', 'JM.DCE': 'ferrous_metals',
    'M.DCE': 'agriculture', 'Y.DCE': 'agriculture', 'P.DCE': 'agriculture',
    'CF.CZC': 'agriculture', 'SR.CZC': 'agriculture',
    'TA.CZC': 'chemicals', 'MA.CZC': 'chemicals',
    'SC.INE': 'energy',
    'CL.CME': 'energy', 'GC.CME': 'precious_metals', 'SI.CME': 'precious_metals',
    'HG.CME': 'non_ferrous_metals', 'W.CME': 'agriculture', 'S.CME': 'agriculture',
    'C.CME': 'agriculture', 'BO.CME': 'agriculture',
    'SB.ICE': 'agriculture', 'CT.ICE': 'agriculture',
    'LME.LME': 'non_ferrous_metals', 'LMA.LME': 'non_ferrous_metals',
}

NAV_SCHEMA = {
    'date': 'Trading date (YYYY-MM-DD)',
    'nav': 'Fund total NAV (CNY), initial=1500000000.00, unit NAV prohibited',
    'daily_pnl': 'Daily P&L (CNY)',
    'daily_return': 'Daily return (decimal)',
    'drawdown': 'Current drawdown (decimal)',
    'dd_scale': 'Drawdown control scaling factor',
    'num_positions': 'Number of positions',
}

SIGNAL_ALIASES = {
    'tsmom': 'TSMOM',
    'time_series_momentum': 'TSMOM',
    'ts_momentum': 'TSMOM',
    'xsmom': 'XSMOM',
    'cross_sectional_momentum': 'XSMOM',
    'xs_momentum': 'XSMOM',
    'carry': 'CARRY',
    'basis': 'CARRY',
    'carry_basis': 'CARRY',
    'breakout': 'BREAKOUT',
    'vol_breakout': 'BREAKOUT',
    'volatility_breakout': 'BREAKOUT',
    'vol_breakout': 'BREAKOUT',
    'meanrev': 'MEANREV',
    'mean_reversion': 'MEANREV',
    'mean_reversion_return': 'MEANREV',
    'pair': 'MEANREV',
    'pairs': 'MEANREV',
    'mean_reversion_cn': 'MEANREV',
}

ALLOWED_LIBS = ['pandas', 'numpy', 'scipy', 'sklearn', 'scikit-learn',
                'statsmodels', 'matplotlib', 'openpyxl', 'seaborn', 'pyyaml', 'yaml']


class CTAEvaluator:
    def __init__(self, submission_dir, data_dir, standard_answer_dir=None,
                 run_agent_code=False, timeout=14400):
        self.submission_dir = submission_dir
        self.data_dir = data_dir
        self.standard_answer_dir = standard_answer_dir
        self.run_agent_code = run_agent_code
        self.timeout = timeout
        self.results = {}
        self.scores = {}
        self.details = {}
        self.agent_run_output = None
        self.adjustment_log = []
        self.benchmark_metrics = {}
        self.raw_data = {}
        self.found_files = {}
        self.threshold_status = {}
        self.schema_compliant = True
        self.schema_errors = []
        self.normalization_notes = {}

    def evaluate_all(self):
        print("=" * 60)
        print("CTA Fund - Automated Eval System (strict)")
        print("=" * 60)

        self._load_raw_data()
        self._load_benchmark()
        if self.run_agent_code:
            self._run_agent_code()
        self._check_file_existence()
        self._check_delivery_threshold()
        self._check_schema_compliance()

        # Scored dimensions
        if self._can_evaluate('backtest_verification'):
            self._verify_backtest_against_raw_data()
        else:
            self.scores['backtest_verification'] = 0
            self.details['backtest_verification'] = {'blocked': True}

        if self._can_evaluate('performance_metrics'):
            self._evaluate_performance_metrics()
        else:
            self.scores['performance_metrics'] = 0
            self.details['performance_metrics'] = {'blocked': True}

        if self._can_evaluate('risk_constraints'):
            self._evaluate_risk_constraints()
        else:
            self.scores['risk_constraints'] = 0
            self.details['risk_constraints'] = {'blocked': True}

        if self._can_evaluate('signal_generation'):
            self._evaluate_signal_generation()
        else:
            self.scores['signal_generation'] = 0
            self.details['signal_generation'] = {'blocked': True}

        self._evaluate_code_compliance()
        self._verify_costs_and_fx()
        self._calculate_total_score()
        self._generate_report()
        return self.results

    # ============================================================
    # Data Loading
    # ============================================================
    def _load_raw_data(self):
        print("\n[0a] Loading raw data...")
        try:
            pf = self._find_file(self.data_dir, ['futures_price_data.xlsx'])
            if pf:
                self.raw_data['domestic'] = pd.read_excel(pf, sheet_name='domestic_futures')
                self.raw_data['overseas'] = pd.read_excel(pf, sheet_name='overseas_futures')
                self.raw_data['carry'] = pd.read_excel(pf, sheet_name='carry_basis_data')
            sf = self._find_file(self.data_dir, ['futures_contract_specs.xlsx'])
            if sf:
                self.raw_data['specs'] = pd.read_excel(sf, sheet_name='contract_specs')
                self.raw_data['costs'] = pd.read_excel(sf, sheet_name='transaction_costs')
            mf = self._find_file(self.data_dir, ['macro_factors_data.xlsx'])
            if mf:
                self.raw_data['fx'] = pd.read_excel(mf, sheet_name='fx_rates_daily')
            print(f"  Raw data loaded")
        except Exception as e:
            print(f"  WARNING: {e}")

    def _load_benchmark(self):
        print("\n[0b] Loading benchmark performance metrics...")
        for d in [self.standard_answer_dir,
                  os.path.join(self.data_dir, 'answer_output'),
                  os.path.join(self.data_dir, 'scoring_scheme_attachment-standard_answer')]:
            if d:
                for p in self._find_files(d, ['nav_history', 'daily_nav', 'nav_cn']):
                    if p.lower().endswith(('.csv', '.xlsx', '.xls')):
                        try:
                            df = pd.read_csv(p) if p.lower().endswith('.csv') else pd.read_excel(p)
                            df = self._normalize_nav_df(df)
                            nc = [c for c in df.columns if 'nav' in c.lower()]
                            dc = [c for c in df.columns if 'date' in c.lower()]
                            if nc and dc:
                                df['dp'] = pd.to_datetime(df[dc[0]])
                                perf = df[df['dp'] >= pd.Timestamp(PERF_START_DATE)]
                                if len(perf) > 20:
                                    s = perf[nc[0]].values.astype(float)
                                    dr = np.diff(s)/s[:-1]; dr = dr[np.isfinite(dr)]
                                    tr = s[-1]/s[0]-1; ny = len(s)/252
                                    ar = (1+tr)**(1/max(ny,.1))-1
                                    av = np.std(dr)*np.sqrt(252)
                                    sh = (ar-.02)/av if av>0 else 0
                                    md = np.max((np.maximum.accumulate(s)-s)/np.maximum.accumulate(s))
                                    dv = np.std(dr[dr<0])*np.sqrt(252) if np.any(dr<0) else av
                                    so = (ar-.02)/dv if dv>0 else 0
                                    ca = ar/md if md>0 else 0
                                    self.benchmark_metrics = {
                                        'annual_return': round(ar,6), 'sharpe': round(sh,6),
                                        'max_drawdown': round(md,6), 'calmar': round(ca,6),
                                        'sortino': round(so,6), 'annual_vol': round(av,6),
                                    }
                                    print(f"  Benchmark loaded from file")
                                    return
                        except:
                            pass
        self.benchmark_metrics = {
            'annual_return': -0.055311, 'sharpe': -6.053179,
            'max_drawdown': 0.281859, 'calmar': -0.196235,
            'sortino': -8.363969, 'annual_vol': 0.012441,
        }
        print("  WARNING: Using hardcoded benchmark")

    # ============================================================
    # Agent Code Execution
    # ============================================================
    def _run_agent_code(self):
        print("\n[1] Running Agent code...")
        main_script = None
        code_files = list(self._iter_submission_code_files())

        def entry_priority(path):
            rel = os.path.relpath(path, self.submission_dir)
            base = os.path.basename(path).lower()
            depth = rel.count(os.sep)
            if rel == 'run.py':
                return (0, depth, base)
            if rel == 'main.py':
                return (1, depth, base)
            if depth == 0 and base.endswith('.py'):
                return (2, depth, base)
            if 'run' in base or 'main' in base:
                return (3, depth, base)
            return (9, depth, base)

        entry_candidates = [
            p for p in code_files
            if os.path.basename(p).lower() in {'run.py', 'main.py'} or
            'run' in os.path.basename(p).lower() or
            'main' in os.path.basename(p).lower()
        ]
        if not entry_candidates:
            entry_candidates = [p for p in code_files if os.path.relpath(p, self.submission_dir).count(os.sep) == 0]
        if entry_candidates:
            main_script = sorted(entry_candidates, key=entry_priority)[0]
        if not main_script:
            self.details['agent_code_run'] = {'status': 'SKIPPED'}; return
        try:
            t0 = time.time()
            r = subprocess.run([sys.executable, main_script], capture_output=True, text=True,
                             timeout=self.timeout, cwd=self.submission_dir)
            elapsed = time.time() - t0
            self.agent_run_output = {'returncode': r.returncode, 'elapsed': elapsed,
                                     'stderr': r.stderr[-2000:]}
            self.details['agent_code_run'] = {
                'status': 'SUCCESS' if r.returncode == 0 else 'FAILED',
                'elapsed': elapsed, 'within_limit': elapsed <= self.timeout}
        except subprocess.TimeoutExpired:
            self.details['agent_code_run'] = {'status': 'TIMEOUT'}
        except Exception as e:
            self.details['agent_code_run'] = {'status': 'ERROR', 'error': str(e)}

    # ============================================================
    # File Existence & Threshold
    # ============================================================
    def _check_file_existence(self):
        print("\n[2] Checking file completeness...")
        required = {
            'strategy_code': {'patterns': ['.py', '.zip'], 'exts': ('.py', '.zip')},
            'signal_matrix': {'patterns': ['signal', 'signals', 'signal_cn'], 'exts': ('.csv', '.xlsx', '.xls')},
            'nav_history': {'patterns': ['nav', 'daily_nav', 'nav_cn'], 'exts': ('.csv', '.xlsx', '.xls')},
            'performance_report': {'patterns': ['perform', 'performance', 'perf_cn'], 'exts': ('.csv', '.xlsx', '.xls', '.md', '.txt', '.docx')},
            'stress_test_report': {'patterns': ['stress', 'stress_cn'], 'exts': ('.csv', '.xlsx', '.xls', '.md', '.txt', '.docx')},
            'risk_budget_table': {'patterns': ['risk_budget', 'budget', 'risk_budget_cn'], 'exts': ('.csv', '.xlsx', '.xls')},
            'holdings_detail': {'patterns': ['holding', 'holdings', 'position_cn', 'position', 'positions'], 'exts': ('.csv', '.xlsx', '.xls')},
            'trade_records': {'patterns': ['trade', 'trades', 'trade_cn'], 'exts': ('.csv', '.xlsx', '.xls')},
            'sensitivity_report': {'patterns': ['sensitiv', 'sensitivity', 'sens_cn'], 'exts': ('.csv', '.xlsx', '.xls', '.md', '.txt', '.docx')},
        }
        for key, cfg in required.items():
            candidates = []
            for full in self._iter_submission_files(include_outputs=True):
                f = os.path.basename(full)
                fl = f.lower()
                if not fl.endswith(cfg['exts']):
                    continue
                if key == 'strategy_code':
                    candidates.append(full)
                elif key == 'risk_budget_table':
                    if (('risk' in fl and 'budget' in fl) or
                            ('risk' in fl and 'budget' in fl) or
                            any(p in fl for p in cfg['patterns'])):
                        candidates.append(full)
                elif any(p in fl for p in cfg['patterns']):
                    candidates.append(full)
            if candidates:
                self.found_files[key] = sorted(
                    candidates,
                    key=lambda p: self._delivery_file_priority(p, cfg['patterns'])
                )[0]
        print(f"  found {len(self.found_files)}/{len(required)}  files")

    def _check_delivery_threshold(self):
        print("\n[2.5] Deliverables threshold check...")
        self.threshold_status = {
            'backtest_verification': (
                'nav_history' in self.found_files and
                'holdings_detail' in self.found_files and
                'trade_records' in self.found_files
            ),
            'performance_metrics': ('nav_history' in self.found_files),
            'risk_constraints': ('nav_history' in self.found_files and 'holdings_detail' in self.found_files),
            'signal_generation': ('signal_matrix' in self.found_files),
        }
        for dim, ok in self.threshold_status.items():
            print(f"  {dim}: {'✓' if ok else 'x(0 pts)'}")

    def _can_evaluate(self, dim):
        return self.threshold_status.get(dim, False)

    # ============================================================
    # Schema Compliance (STRICT GATE)
    # ============================================================
    def _check_schema_compliance(self):
        """Check nav_history schema compliance -- non-compliance causes severe deductions across multiple dimensions"""
        print("\n[2.6] Schema compliance check...")
        self.schema_compliant = True
        self.schema_errors = []

        nav_df = self._load_df('nav_history')
        if nav_df is None or len(nav_df) == 0:
            self.schema_compliant = False
            self.schema_errors.append('nav file is empty')
            print("  x nav file is empty")
            return

        nav_col = [c for c in nav_df.columns if 'nav' in c.lower() or 'nav_cn' in c]
        if not nav_col:
            self.schema_compliant = False
            self.schema_errors.append('nav column not found')
            print("  x nav column not found")
            return

        nav_vals = nav_df[nav_col[0]].dropna().values.astype(float)
        if len(nav_vals) == 0:
            self.schema_compliant = False
            self.schema_errors.append('nav column is empty')
            return

        initial = nav_vals[0]
        # CRITICAL: nav must be in CNY total (≈1.5 billion), NOT unit NAV (≈1.0)
        if initial < 100:
            self.schema_compliant = False
            self.schema_errors.append(f'nav appears to be unit NAV (initial={initial:.4f}), should be total CNY (~1500000000)')
            print(f"  ✗ nav is unit NAV (initial={initial:.4f})，should be total CNY")
        elif initial < 1e8 or initial > 1e10:
            self.schema_compliant = False
            self.schema_errors.append(f'nav initial value={initial:.0f} not in reasonable range (1e8~1e10)')
            print(f"  ✗ nav initial value abnormal: {initial:.0f}")
        else:
            print(f"  ✓ nav schema compliant (initial={initial:.0f})")

        required_cols = {
            'daily_pnl': ['daily_pnl', 'pnl', 'pnl_cn'],
            'daily_return': ['daily_return', 'return', 'return_rate_cn'],
            'drawdown': ['drawdown', 'drawdown_cn'],
            'dd_scale': ['dd_scale', 'scale_cn'],
            'num_positions': ['num_positions', 'positions', 'Number of positions'],
        }
        for name, aliases in required_cols.items():
            if self._find_col(nav_df, aliases) is None:
                self.schema_compliant = False
                self.schema_errors.append(f'missing {name} column')
                print(f"  x missing {name} column")

    # ============================================================
    # Backtest Verification (10 points) - closed-loop accounting
    # ============================================================
    def _verify_backtest_against_raw_data(self):
        print("\n[3] Authenticity verification (full closed-loop)...")
        det = {}

        nav_df = self._load_df('nav_history')
        holdings_df = self._load_df('holdings_detail')
        trade_df = self._load_df('trade_records')
        if nav_df is None or holdings_df is None or trade_df is None:
            self.scores['backtest_verification'] = 0
            self.details['backtest_verification'] = {'blocked': True, 'reason': 'missing nav/position/trade core file'}
            print("  missing nav_history, holdings_detail, or trade_records, authenticity check=0/10")
            return

        try:
            raw_parts = []
            if 'domestic' in self.raw_data:
                raw_parts.append(self.raw_data['domestic'][['date', 'ticker', 'close']])
            if 'overseas' in self.raw_data:
                raw_parts.append(self.raw_data['overseas'][['date', 'ticker', 'close']])
            if not raw_parts:
                raise ValueError('missing raw market data')
            raw_all = pd.concat(raw_parts, ignore_index=True)
            raw_all['date'] = pd.to_datetime(raw_all['date'])
            price_pivot = raw_all.pivot_table(index='date', columns='ticker', values='close').sort_index().ffill()
            raw_dates = set(pd.DatetimeIndex(price_pivot.index).normalize())

            specs_dict = {}
            if 'specs' in self.raw_data:
                for _, row in self.raw_data['specs'].iterrows():
                    specs_dict[str(row['ticker'])] = {
                        'multiplier': float(row.get('multiplier', 1)),
                        'currency': str(row.get('currency', 'CNY')).upper(),
                    }
            costs_dict = {}
            if 'costs' in self.raw_data:
                for _, row in self.raw_data['costs'].iterrows():
                    costs_dict[str(row['ticker'])] = {
                        'cost': float(row.get('total_round_trip_cost_per_lot', 0)),
                        'currency': str(row.get('currency', specs_dict.get(str(row['ticker']), {}).get('currency', 'CNY'))).upper(),
                    }

            fx_series = pd.Series(dtype=float)
            if 'fx' in self.raw_data:
                fx_df = self.raw_data['fx'].copy()
                fx_df['date'] = pd.to_datetime(fx_df['date'])
                if 'USDCNY' in fx_df.columns:
                    fx_series = fx_df.drop_duplicates('date').set_index('date')['USDCNY'].astype(float).sort_index()

            def fx_for(date, currency):
                if str(currency).upper() != 'USD':
                    return 1.0
                if len(fx_series) == 0:
                    return 7.0
                v = fx_series.asof(pd.Timestamp(date))
                return 7.0 if pd.isna(v) else float(v)

            nav_date_col = self._find_col(nav_df, ['date', 'date_cn'])
            nav_col = self._find_col(nav_df, ['nav', 'nav_cn'])
            pnl_col = self._find_col(nav_df, ['daily_pnl', 'pnl', 'pnl_cn'])
            ret_col = self._find_col(nav_df, ['daily_return', 'return', 'return_rate_cn'])
            dd_col = self._find_col(nav_df, ['drawdown', 'drawdown_cn'])
            h_date_col = self._find_col(holdings_df, ['date', 'date_cn'])
            h_ticker_col = self._find_col(holdings_df, ['ticker', 'instrument_cn', 'contract_cn'])
            h_lots_col = self._find_col(holdings_df, ['lots', 'position_lots', 'position', 'position_lots_cn', 'lots_cn'])
            t_date_col = self._find_col(trade_df, ['date', 'date_cn'])
            t_ticker_col = self._find_col(trade_df, ['ticker', 'instrument_cn', 'contract_cn'])
            t_lots_col = self._find_col(trade_df, [
                'trade_lots', 'lots_change', 'lots_delta', 'position_change',
                'trade_lots_cn', 'filled_lots_cn', 'lots_change_cn'
            ])
            t_cost_col = self._find_col(trade_df, ['transaction_cost_cny', 'transaction_cost', 'cost_cny', 'cost', 'fee_cn', 'cost_cn'])
            t_fx_col = self._find_col(trade_df, ['fx_rate', 'usdcny', 'fx_cn'])

            if not all([nav_date_col, nav_col, h_date_col, h_ticker_col, h_lots_col, t_date_col, t_ticker_col, t_lots_col]):
                raise ValueError('nav/position/trade files missing date, ticker, or lots core fields')

            nav = nav_df.copy()
            nav['dp'] = pd.to_datetime(nav[nav_date_col])
            nav = nav.dropna(subset=['dp']).sort_values('dp').drop_duplicates('dp', keep='last')
            nav_dates = list(nav['dp'])
            agent_nav = pd.to_numeric(nav[nav_col], errors='coerce').astype(float).values

            holdings = holdings_df.copy()
            holdings['dp'] = pd.to_datetime(holdings[h_date_col])
            holdings['ticker_norm'] = holdings[h_ticker_col].astype(str)
            holdings['lots_norm'] = pd.to_numeric(holdings[h_lots_col], errors='coerce').fillna(0.0)
            holdings = holdings.dropna(subset=['dp'])

            trades = trade_df.copy()
            trades['dp'] = pd.to_datetime(trades[t_date_col])
            trades['ticker_norm'] = trades[t_ticker_col].astype(str)
            trades['trade_lots_norm'] = pd.to_numeric(trades[t_lots_col], errors='coerce').fillna(0.0)
            trades = trades.dropna(subset=['dp'])

            # 1 point: core files and date alignment.
            def date_valid_ratio(values):
                dates = set(pd.DatetimeIndex(pd.to_datetime(values)).normalize())
                dates = {d for d in dates if pd.notna(d)}
                return 0.0 if not dates else len(dates & raw_dates) / len(dates)

            min_date_ratio = min(
                date_valid_ratio(nav['dp']),
                date_valid_ratio(holdings['dp']),
                date_valid_ratio(trades['dp']),
            )
            if min_date_ratio >= 0.95:
                date_score = 1.0
            elif min_date_ratio >= 0.80:
                date_score = 0.5
            else:
                date_score = 0.0
            det['date_alignment'] = {'valid_ratio': round(float(min_date_ratio), 4), 'score': date_score}
            print(f"  File and date alignment: valid_ratio={min_date_ratio:.4f}, score={date_score}/1")

            # 2 points: nav, daily_pnl, daily_return, drawdown accounting identity.
            # Split the score so a conventional negative drawdown series does not
            # invalidate otherwise correct NAV/PnL accounting.
            nav_accounting_score = 0.0
            if all([pnl_col, ret_col, dd_col]) and len(nav) > 2 and self.schema_compliant:
                pnl = pd.to_numeric(nav[pnl_col], errors='coerce').astype(float).values
                ret = pd.to_numeric(nav[ret_col], errors='coerce').astype(float).values
                dd = pd.to_numeric(nav[dd_col], errors='coerce').astype(float).values
                nav_diff = np.diff(agent_nav)
                pnl_sub = pnl[1:]
                denom = np.maximum.reduce([
                    np.abs(nav_diff), np.abs(pnl_sub),
                    np.maximum(np.abs(agent_nav[:-1]) * 1e-6, 1.0)
                ])
                pnl_pass = np.abs(nav_diff - pnl_sub) <= denom * 0.01
                ret_expected = np.divide(pnl_sub, agent_nav[:-1], out=np.zeros_like(pnl_sub), where=agent_nav[:-1] != 0)
                ret_pass = np.abs(ret[1:] - ret_expected) <= 1e-4
                peak = np.maximum.accumulate(agent_nav)
                dd_expected_pos = np.divide(peak - agent_nav, peak, out=np.zeros_like(agent_nav), where=peak != 0)
                dd_expected_neg = -dd_expected_pos
                dd_pos_pass = np.abs(dd - dd_expected_pos) <= 1e-4
                dd_neg_pass = np.abs(dd - dd_expected_neg) <= 1e-4
                dd_pos_ratio = float(np.mean(dd_pos_pass))
                dd_neg_ratio = float(np.mean(dd_neg_pass))
                if dd_neg_ratio > dd_pos_ratio:
                    dd_pass = dd_neg_pass
                    dd_convention = 'negative'
                else:
                    dd_pass = dd_pos_pass
                    dd_convention = 'positive'

                pnl_pass_ratio = float(np.mean(pnl_pass))
                ret_pass_ratio = float(np.mean(ret_pass))
                dd_pass_ratio = float(np.mean(dd_pass))

                pnl_score = 0.8 if pnl_pass_ratio >= 0.95 else (0.4 if pnl_pass_ratio >= 0.85 else 0.0)
                ret_score = 0.7 if ret_pass_ratio >= 0.95 else (0.35 if ret_pass_ratio >= 0.85 else 0.0)
                dd_score = 0.5 if dd_pass_ratio >= 0.95 else (0.25 if dd_pass_ratio >= 0.85 else 0.0)
                nav_accounting_score = round(pnl_score + ret_score + dd_score, 4)
                det['nav_accounting'] = {
                    'pass_ratio': round(min(pnl_pass_ratio, ret_pass_ratio, dd_pass_ratio), 4),
                    'pnl_pass_ratio': round(pnl_pass_ratio, 4),
                    'return_pass_ratio': round(ret_pass_ratio, 4),
                    'drawdown_pass_ratio': round(dd_pass_ratio, 4),
                    'drawdown_convention': dd_convention,
                    'component_scores': {
                        'daily_pnl': pnl_score,
                        'daily_return': ret_score,
                        'drawdown': dd_score,
                    },
                    'score': nav_accounting_score,
                }
            else:
                det['nav_accounting'] = {'score': 0, 'reason': 'schema non-compliant or missing daily_pnl/daily_return/drawdown'}
            print(f"  NAV accounting consistency: score={nav_accounting_score}/2")

            holding_group = holdings.groupby(['dp', 'ticker_norm'])['lots_norm'].sum().reset_index()
            trade_group = trades.groupby(['dp', 'ticker_norm'])['trade_lots_norm'].sum().reset_index()
            all_tickers = sorted(set(holding_group['ticker_norm']) | set(trade_group['ticker_norm']))
            holding_pivot = holding_group.pivot_table(index='dp', columns='ticker_norm', values='lots_norm', aggfunc='sum')
            trade_pivot = trade_group.pivot_table(index='dp', columns='ticker_norm', values='trade_lots_norm', aggfunc='sum')
            holding_pivot = holding_pivot.reindex(index=nav_dates, columns=all_tickers).fillna(0.0)
            trade_pivot = trade_pivot.reindex(index=nav_dates, columns=all_tickers).fillna(0.0)

            # 2 points: holdings must be explainable by trades.
            continuity_score = 0
            if len(nav_dates) > 1 and all_tickers:
                prev_h = holding_pivot.shift(1).iloc[1:]
                curr_h = holding_pivot.iloc[1:]
                day_trades = trade_pivot.iloc[1:]
                expected_h = prev_h + day_trades
                active = (prev_h.abs() > 1e-9) | (curr_h.abs() > 1e-9) | (day_trades.abs() > 1e-9)
                mismatches = ((curr_h - expected_h).abs() > 1e-6) & active
                active_count = int(active.to_numpy().sum())
                violation_ratio = 1.0 if active_count == 0 else float(mismatches.to_numpy().sum() / active_count)
                if active_count > 0 and violation_ratio < 0.01:
                    continuity_score = 2
                elif active_count > 0 and violation_ratio <= 0.10:
                    continuity_score = 1
                det['position_trade_continuity'] = {
                    'active_checks': active_count,
                    'violation_ratio': round(float(violation_ratio), 4),
                    'score': continuity_score,
                }
            else:
                det['position_trade_continuity'] = {'score': 0, 'reason': 'position or trade data is empty'}
            print(f"  Position-trade continuity: score={continuity_score}/2")

            # Replay daily PnL and NAV from raw prices, previous-day holdings, costs, and FX.
            replay_pnl = [0.0]
            replay_nav = [agent_nav[0] if len(agent_nav) else 0.0]
            missing_price_checks = 0
            for i in range(1, len(nav_dates)):
                curr_date = nav_dates[i]
                prev_date = nav_dates[i - 1]
                position_pnl = 0.0
                if curr_date in price_pivot.index and prev_date in price_pivot.index:
                    prev_lots = holding_pivot.iloc[i - 1]
                    for ticker, lots in prev_lots[prev_lots.abs() > 1e-12].items():
                        if ticker not in price_pivot.columns:
                            missing_price_checks += 1
                            continue
                        curr_price = price_pivot.loc[curr_date, ticker]
                        prev_price = price_pivot.loc[prev_date, ticker]
                        if pd.isna(curr_price) or pd.isna(prev_price):
                            missing_price_checks += 1
                            continue
                        spec = specs_dict.get(ticker, {'multiplier': 1.0, 'currency': 'CNY'})
                        position_pnl += float(lots) * spec['multiplier'] * (float(curr_price) - float(prev_price)) * fx_for(curr_date, spec['currency'])
                else:
                    missing_price_checks += 1

                trade_cost = 0.0
                day_trades = trade_pivot.iloc[i]
                for ticker, lots in day_trades[day_trades.abs() > 1e-12].items():
                    cost_info = costs_dict.get(ticker, {'cost': 0.0, 'currency': specs_dict.get(ticker, {}).get('currency', 'CNY')})
                    trade_cost += abs(float(lots)) * cost_info['cost'] * fx_for(curr_date, cost_info['currency'])

                daily_pnl = position_pnl - trade_cost
                replay_pnl.append(daily_pnl)
                replay_nav.append(replay_nav[-1] + daily_pnl)

            replay_score = 0
            replay_nav = np.array(replay_nav, dtype=float)
            replay_pnl = np.array(replay_pnl, dtype=float)
            if len(replay_nav) > 20:
                agent_aligned = agent_nav[:len(replay_nav)]
                nav_corr = self._safe_corr(replay_nav[1:], agent_aligned[1:])
                nav_rel_err = float(np.mean(np.abs(replay_nav[1:] - agent_aligned[1:]) / np.maximum(np.abs(agent_aligned[1:]), 1.0)))
                pnl_p95_err = float('inf')
                if pnl_col:
                    submitted_pnl = pd.to_numeric(nav[pnl_col], errors='coerce').fillna(0.0).astype(float).values[:len(replay_pnl)]
                    pnl_denom = np.maximum.reduce([
                        np.abs(submitted_pnl[1:]),
                        np.abs(replay_pnl[1:]),
                        np.maximum(np.abs(agent_aligned[:-1]) * 1e-6, 1.0),
                    ])
                    pnl_p95_err = float(np.percentile(np.abs(submitted_pnl[1:] - replay_pnl[1:]) / pnl_denom, 95))

                if nav_corr >= 0.995 and nav_rel_err <= 0.005 and pnl_p95_err <= 0.02:
                    replay_score = 3
                elif nav_corr >= 0.98 and nav_rel_err <= 0.02 and pnl_p95_err <= 0.05:
                    replay_score = 2
                elif nav_corr >= 0.90 or nav_rel_err <= 0.10:
                    replay_score = 1
                det['pnl_nav_replay'] = {
                    'nav_corr': round(float(nav_corr), 4),
                    'mean_nav_rel_err': round(float(nav_rel_err), 4),
                    'p95_daily_pnl_err': None if not np.isfinite(pnl_p95_err) else round(float(pnl_p95_err), 4),
                    'missing_price_checks': int(missing_price_checks),
                    'score': replay_score,
                }
            else:
                det['pnl_nav_replay'] = {'score': 0, 'reason': 'insufficient valid nav days'}
            print(f"  PnL/NAV full replay: score={replay_score}/3")

            # 2 points: submitted trade costs and FX must match raw input sources.
            cost_fx_score = 0
            if t_cost_col and t_lots_col:
                cost_checks = []
                fx_mismatches = 0
                fx_checks = 0
                for _, row in trades.iterrows():
                    ticker = row['ticker_norm']
                    lots = abs(float(row['trade_lots_norm']))
                    if lots <= 1e-12:
                        continue
                    cost_info = costs_dict.get(ticker, {'cost': 0.0, 'currency': specs_dict.get(ticker, {}).get('currency', 'CNY')})
                    expected_cost = lots * cost_info['cost'] * fx_for(row['dp'], cost_info['currency'])
                    submitted_cost = pd.to_numeric(pd.Series([row.get(t_cost_col)]), errors='coerce').iloc[0]
                    if pd.notna(submitted_cost) and expected_cost > 0:
                        cost_checks.append(abs(float(submitted_cost) - expected_cost) / max(expected_cost, 1.0))

                    spec = specs_dict.get(ticker, {'currency': cost_info.get('currency', 'CNY')})
                    if str(spec.get('currency', 'CNY')).upper() == 'USD':
                        fx_checks += 1
                        if t_fx_col:
                            submitted_fx = pd.to_numeric(pd.Series([row.get(t_fx_col)]), errors='coerce').iloc[0]
                            expected_fx = fx_for(row['dp'], 'USD')
                            if pd.isna(submitted_fx) or abs(float(submitted_fx) - expected_fx) / max(expected_fx, 1.0) > 0.005:
                                fx_mismatches += 1
                if cost_checks:
                    cost_median_err = float(np.median(cost_checks))
                    cost_p95_err = float(np.percentile(cost_checks, 95))
                    fx_mismatch_ratio = 0.0 if fx_checks == 0 else (
                        None if not t_fx_col else float(fx_mismatches / fx_checks)
                    )
                    fx_ok_full = fx_mismatch_ratio is None or fx_mismatch_ratio <= 0.01
                    fx_ok_partial = fx_mismatch_ratio is None or fx_mismatch_ratio <= 0.10
                    if cost_median_err <= 0.05 and cost_p95_err <= 0.20 and fx_ok_full:
                        cost_fx_score = 2
                    elif cost_median_err <= 0.30 and fx_ok_partial:
                        cost_fx_score = 1
                    det['costs_fx'] = {
                        'cost_median_rel_err': round(cost_median_err, 4),
                        'cost_p95_rel_err': round(cost_p95_err, 4),
                        'fx_mismatch_ratio': None if fx_mismatch_ratio is None else round(float(fx_mismatch_ratio), 4),
                        'score': cost_fx_score,
                    }
                else:
                    det['costs_fx'] = {'score': 0, 'reason': 'no valid trade cost verification samples'}
            else:
                det['costs_fx'] = {'score': 0, 'reason': 'trade records missing cost column or trade lots field'}
            print(f"  Cost and FX check: score={cost_fx_score}/2")

            score = date_score + nav_accounting_score + continuity_score + replay_score + cost_fx_score
        except Exception as e:
            det['error'] = str(e)[:300]
            score = 0
            print(f"  Full replay failed: {e}")

        self.scores['backtest_verification'] = score
        det['total'] = score
        self.details['backtest_verification'] = det
        print(f"  Authenticity check total: {score}/10")

    # ============================================================
    # Performance Metrics (25 points) - VERY STRICT
    # ============================================================
    def _evaluate_performance_metrics(self):
        print("\n[4] Performance metrics (strict)...")
        score = 0
        ms = {}
        cm = {}

        nav_df = self._load_df('nav_history')
        holdings_df = self._load_df('holdings_detail')
        if nav_df is None or len(nav_df) < 10:
            self.scores['performance_metrics'] = 0
            self.details['performance_metrics'] = {'error': 'insufficient nav data'}
            return

        # Schema penalty
        if not self.schema_compliant:
            print("  Schema non-compliant (unit NAV), performance metrics score x0.3")
            schema_mult = 0.3
        else:
            schema_mult = 1.0

        nav_col = [c for c in nav_df.columns if 'nav' in c.lower() or 'nav_cn' in c]
        date_col = [c for c in nav_df.columns if 'date' in c.lower() or 'date_cn' in c]
        if not (nav_col and date_col):
            self.scores['performance_metrics'] = 0; return

        nav_df['dp'] = pd.to_datetime(nav_df[date_col[0]])
        perf = nav_df[nav_df['dp'] >= pd.Timestamp(PERF_START_DATE)].copy()
        if len(perf) < 10:
            perf = nav_df.copy()

        s = perf[nav_col[0]].values.astype(float)
        dr = np.diff(s)/s[:-1]; dr = dr[np.isfinite(dr)]
        if len(dr) < 20:
            self.scores['performance_metrics'] = 0; return

        tr = s[-1]/s[0]-1; ny = len(s)/252
        ar = (1+tr)**(1/max(ny,.1))-1
        av = np.std(dr)*np.sqrt(252)
        sh = (ar-.02)/av if av>0 else 0
        md = np.max((np.maximum.accumulate(s)-s)/np.maximum.accumulate(s))
        dv = np.std(dr[dr<0])*np.sqrt(252) if np.any(dr<0) else av
        so = (ar-.02)/dv if dv>0 else 0
        ca = ar/md if md>0 else 0
        cm = {'annual_return': ar, 'sharpe': sh, 'max_drawdown': md, 'sortino': so, 'calmar': ca}

        b = self.benchmark_metrics

        # VERY STRICT scoring: only significant outperformance or reaching absolute targets scores
        # Matching benchmark = 0 points (benchmark is poor, matching it is not an achievement)

        # Annual Return (5 pts): must reach absolute target or significantly exceed benchmark
        if ar >= 0.08:
            ms['annual_return'] = 5
        elif ar >= 0.05:
            ms['annual_return'] = 3
        elif ar > 0:
            ms['annual_return'] = 1
        else:
            ms['annual_return'] = 0  # Negative return = 0, even if "better than benchmark"

        # Sharpe (5 pts)
        if sh >= 0.8:
            ms['sharpe_ratio'] = 5
        elif sh >= 0.5:
            ms['sharpe_ratio'] = 3
        elif sh > 0:
            ms['sharpe_ratio'] = 1
        else:
            ms['sharpe_ratio'] = 0

        # Max Drawdown (5 pts): must be <=15% for any points
        if md <= 0.10:
            ms['max_drawdown'] = 5
        elif md <= 0.15:
            ms['max_drawdown'] = 3
        elif md <= 0.20:
            ms['max_drawdown'] = 1
        else:
            ms['max_drawdown'] = 0  # >20% = 0 points

        # Calmar (5 pts)
        if ca >= 0.5:
            ms['calmar_ratio'] = 5
        elif ca >= 0.2:
            ms['calmar_ratio'] = 2
        elif ca > 0:
            ms['calmar_ratio'] = 1
        else:
            ms['calmar_ratio'] = 0

        # Sortino (5 pts)
        if so >= 1.0:
            ms['sortino_ratio'] = 5
        elif so >= 0.5:
            ms['sortino_ratio'] = 2
        elif so > 0:
            ms['sortino_ratio'] = 1
        else:
            ms['sortino_ratio'] = 0

        exposure_stats = self._compute_exposure_stats(nav_df, holdings_df)
        exposure_status = exposure_stats.get('participation_status', 'fail')
        if exposure_status == 'partial':
            for k in ['max_drawdown', 'sharpe_ratio', 'sortino_ratio', 'calmar_ratio']:
                ms[k] = min(ms.get(k, 0), 1)
            print("  Low participation penalty: max drawdown/risk-adjusted metrics capped at 1 pt each, performance total capped at 10")
        elif exposure_status != 'pass':
            for k in ['max_drawdown', 'sharpe_ratio', 'sortino_ratio', 'calmar_ratio']:
                ms[k] = 0
            print("  Low vol/exposure penalty: max drawdown and risk-adjusted metrics score 0")

        score = sum(ms.values())
        if exposure_status == 'partial':
            score = min(score, 10)
        perf_cap = 25
        cap_reasons = []
        backtest_det = self.details.get('backtest_verification', {})
        backtest_score = self.scores.get('backtest_verification', 0)
        nav_accounting_score = backtest_det.get('nav_accounting', {}).get('score', 0)
        replay_score = backtest_det.get('pnl_nav_replay', {}).get('score', 0)
        cost_fx_score = backtest_det.get('costs_fx', {}).get('score', 0)
        if backtest_score < 5:
            perf_cap = min(perf_cap, 10)
            cap_reasons.append('authenticity check<5')
        if nav_accounting_score == 0 or replay_score <= 1:
            perf_cap = min(perf_cap, 10)
            cap_reasons.append('NAV/PnL authenticity insufficient')
        if cost_fx_score == 0:
            perf_cap = min(perf_cap, 12)
            cap_reasons.append('cost and FX check=0')
        if score > perf_cap:
            print(f"  Authenticity constraint: performance total capped at{perf_cap}/25，reason={cap_reasons}")
            score = perf_cap
        score = int(score * schema_mult)  # Apply schema penalty
        metric_score_keys = {
            'annual_return': 'annual_return',
            'sharpe': 'sharpe_ratio',
            'max_drawdown': 'max_drawdown',
            'sortino': 'sortino_ratio',
            'calmar': 'calmar_ratio',
        }
        for k, v in cm.items():
            print(f"  {k}: {v:.4f} (benchmark: {b.get(k, 'N/A')}, score: {ms.get(metric_score_keys.get(k, k), 0)}/5)")

        self.scores['performance_metrics'] = score
        self.details['performance_metrics'] = ms
        self.details['computed_metrics'] = cm
        self.details['exposure_participation'] = exposure_stats
        self.details['performance_authenticity_cap'] = {'cap': perf_cap, 'reasons': cap_reasons} if cap_reasons else {'cap': 25}
        if schema_mult < 1:
            print(f"  Performance score after schema penalty: {score}/25")
        print(f"  Performance metrics total: {score}/25")

    # ============================================================
    # Risk Constraints (20 points) - GATE + STRICT
    # ============================================================
    def _evaluate_risk_constraints(self):
        print("\n[5] Risk control constraints (strict)...")
        score = 0
        cs = {}

        nav_df = self._load_df('nav_history')
        holdings_df = self._load_df('holdings_detail')
        exposure_stats = self._compute_exposure_stats(nav_df, holdings_df)
        backtest_det = self.details.get('backtest_verification', {})
        verified_cost_fx_score = backtest_det.get('costs_fx', {}).get('score', 0)

        # ---- GATE: Max drawdown > 20% → ALL risk = 0 ----
        gate_passed = True
        gate_reason = 'drawdown>20% or vol out of range'
        if nav_df is not None:
            nc = [c for c in nav_df.columns if 'nav' in c.lower() or 'nav_cn' in c]
            if nc:
                s = nav_df[nc[0]].values.astype(float)
                md = np.max((np.maximum.accumulate(s)-s)/np.maximum.accumulate(s))
                av = np.std(np.diff(s)/s[:-1]) * np.sqrt(252) if len(s) > 1 else 0
                if md > 0.20:
                    gate_passed = False
                    gate_reason = 'max drawdown>20%'
                    print(f"  ✗ Veto: max drawdown{md*100:.1f}%>20%, risk dimension all 0 pts")
                elif av > 0 and (av < 0.05 or av > 0.20):
                    gate_passed = False
                    gate_reason = 'annual vol out of range'
                    print(f"  ✗ Veto: annual vol{av*100:.1f}%outside [5%,20%], risk dimension all 0 pts")

        if gate_passed and exposure_stats.get('participation_status') != 'pass':
            gate_passed = False
            gate_reason = 'low vol/exposure or insufficient participation'
            print(
                "  ✗ Veto: "
                f"annual vol{exposure_stats.get('annual_vol', 0)*100:.1f}%, "
                f"avg gross exposure{exposure_stats.get('avg_gross_exposure', 0)*100:.1f}%, "
                f"active participation rate{exposure_stats.get('active_exposure_ratio', 0)*100:.1f}%"
            )

        if not gate_passed:
            self.scores['risk_constraints'] = 0
            self.details['risk_constraints'] = {
                'gate_failed': True,
                'reason': gate_reason,
                'exposure_participation': exposure_stats,
            }
            print(f"  Risk control total: 0/20")
            return

        # ---- 5.1 Risk Indicators (10 pts) - ALL must pass for full marks ----
        met = 0
        if nav_df is not None:
            nc = [c for c in nav_df.columns if 'nav' in c.lower() or 'nav_cn' in c]
            if nc:
                s = nav_df[nc[0]].values.astype(float)
                dr = np.diff(s)/s[:-1]; dr = dr[np.isfinite(dr)]
                av = np.std(dr)*np.sqrt(252) if len(dr)>0 else 0
                if 0.08 <= av <= 0.15: met += 1
                md = np.max((np.maximum.accumulate(s)-s)/np.maximum.accumulate(s))
                if md <= 0.15: met += 1
                if len(dr) > 250:
                    if abs(np.percentile(dr, 1)) <= 0.03: met += 1
                if len(dr) > 0 and np.min(dr) >= -0.02: met += 1
                if len(dr) > 5:
                    wr = np.convolve(dr, np.ones(5), mode='valid')
                    if np.min(wr) >= -0.05: met += 1

        # STRICT: need ALL 5 for full marks, 4=6pts, 3=3pts, <3=0
        if met >= 5: cs['risk_metrics'] = 10
        elif met >= 4: cs['risk_metrics'] = 6
        elif met >= 3: cs['risk_metrics'] = 3
        else: cs['risk_metrics'] = 0
        print(f"  Risk metrics: {met}/5 items, score={cs['risk_metrics']}/10")

        # ---- 5.2 Drawdown Control (5 pts) - daily check from holdings ----
        dd_score = 0
        if nav_df is not None and holdings_df is not None:
            nc = [c for c in nav_df.columns if 'nav' in c.lower() or 'nav_cn' in c]
            hd = [c for c in holdings_df.columns if 'date' in c.lower() or 'date_cn' in c]
            hl = [c for c in holdings_df.columns if 'lots' in c.lower() or 'lots_cn' in c or 'position' in c.lower()]

            if nc and hd and hl:
                s = nav_df[nc[0]].values.astype(float)
                dates = pd.to_datetime(nav_df.iloc[:, 0])
                dd = (np.maximum.accumulate(s)-s)/np.maximum.accumulate(s)
                holdings_df['dp'] = pd.to_datetime(holdings_df[hd[0]])

                correct = 0; total = 0
                for i in range(1, len(dd)):
                    if dd[i] > 0.05:
                        total += 1
                        cd = dates.iloc[i]; pd_ = dates.iloc[max(0,i-5)]
                        ch = holdings_df[holdings_df['dp']==cd]
                        ph = holdings_df[holdings_df['dp']==pd_]
                        if len(ch) > 0 and len(ph) > 0:
                            cr = ch[hl[0]].abs().sum()
                            pr = ph[hl[0]].abs().sum()
                            if pr > 0:
                                ratio = cr/pr
                                expected = 0.35 if dd[i]>0.12 else (0.60 if dd[i]>0.08 else 0.85)
                                if ratio <= expected: correct += 1

                if total == 0:
                    dd_score = 5
                elif correct >= total * 0.9:
                    dd_score = 4
                elif correct >= total * 0.7:
                    dd_score = 2
                elif correct > 0:
                    dd_score = 1
                print(f"  Drawdown control: {correct}/{total} correct, score={dd_score}/5")

        cs['drawdown_control'] = dd_score

        # ---- 5.3 Cross-border (5 pts) - daily notional value ----
        cb_score = 0
        cb_checks = 0
        if holdings_df is not None and len(holdings_df) > 0:
            ht = [c for c in holdings_df.columns if 'ticker' in c.lower() or 'instrument_cn' in c]
            hl = [c for c in holdings_df.columns if 'lots' in c.lower() or 'lots_cn' in c or 'position' in c.lower()]
            hd = [c for c in holdings_df.columns if 'date' in c.lower() or 'date_cn' in c]

            if ht and hl and hd:
                holdings_df['dp'] = pd.to_datetime(holdings_df[hd[0]])
                # Pre-build lookups
                price_lk = {}
                if 'domestic' in self.raw_data and 'overseas' in self.raw_data:
                    ra = pd.concat([self.raw_data['domestic'][['date','ticker','close']],
                                   self.raw_data['overseas'][['date','ticker','close']]], ignore_index=True)
                    ra['date'] = pd.to_datetime(ra['date'])
                    for _, r in ra.iterrows(): price_lk[(r['date'],r['ticker'])] = float(r['close'])
                mult_lk = {}
                if 'specs' in self.raw_data:
                    for _, r in self.raw_data['specs'].iterrows(): mult_lk[r['ticker']] = float(r['multiplier'])

                violations = 0; days = 0
                for date, dg in holdings_df.groupby('dp'):
                    days += 1
                    on = 0.0; tn = 0.0
                    for _, r in dg.iterrows():
                        t = r[ht[0]]; l = abs(r[hl[0]])
                        if l == 0: continue
                        m = mult_lk.get(t, 1); p = price_lk.get((date, t), 0)
                        n = l * m * p; tn += n
                        if t in OVERSEAS_TICKERS: on += n
                    if tn > 0 and on/tn > 0.40: violations += 1

                if days > 0:
                    if violations == 0: cb_checks += 2
                    elif violations/days < 0.02: cb_checks += 1
                    print(f"  Overseas ratio (notional value): violations{violations}/{days} days")

                # FX/cost check reuses the closed-loop verification result.
                trade_df = self._load_df('trade_records')
                if trade_df is not None and len(trade_df) > 0:
                    tt = [c for c in trade_df.columns if 'ticker' in c.lower() or 'instrument_cn' in c]
                    if tt:
                        ot = trade_df[trade_df[tt[0]].astype(str).isin(OVERSEAS_TICKERS)]
                        if len(ot) > 0 and verified_cost_fx_score >= 2:
                            cb_checks += 2
                        elif len(ot) > 0 and verified_cost_fx_score >= 1:
                            cb_checks += 1
                        print(f"  FX conversion: reusing Cost and FX check={verified_cost_fx_score}/2" if len(ot) > 0 else "")

        if cb_checks >= 4: cb_score = 5
        elif cb_checks >= 3: cb_score = 3
        elif cb_checks >= 1: cb_score = 1
        cs['cross_border'] = cb_score

        score = sum(cs.values())
        risk_cap = 20
        cap_reasons = []
        nav_accounting_score = backtest_det.get('nav_accounting', {}).get('score', 0)
        replay_score = backtest_det.get('pnl_nav_replay', {}).get('score', 0)
        backtest_score = self.scores.get('backtest_verification', 0)
        cost_fx_det = backtest_det.get('costs_fx', {})
        if nav_accounting_score == 0:
            risk_cap = min(risk_cap, 8)
            cap_reasons.append('NAV accounting consistency=0')
        if replay_score <= 1:
            risk_cap = min(risk_cap, 8)
            cap_reasons.append('PnL/NAV replay<=1')
        if verified_cost_fx_score == 0:
            risk_cap = min(risk_cap, 8)
            cap_reasons.append('cost and FX check=0')
            cost_median_err = cost_fx_det.get('cost_median_rel_err')
            cost_p95_err = cost_fx_det.get('cost_p95_rel_err')
            if (
                isinstance(cost_median_err, (int, float)) and cost_median_err > 0.50
            ) or (
                isinstance(cost_p95_err, (int, float)) and cost_p95_err > 0.50
            ):
                risk_cap = min(risk_cap, 6)
                cap_reasons.append('cost under/miscounted severely')
        elif verified_cost_fx_score == 1:
            risk_cap = min(risk_cap, 12)
            cap_reasons.append('cost and FX check only partially passed')
        if backtest_score < 5:
            risk_cap = min(risk_cap, 8)
            cap_reasons.append('authenticity check<5')
        if score > risk_cap:
            print(f"  Authenticity constraint: risk total capped at{risk_cap}/20，reason={cap_reasons}")
            score = risk_cap
        cs['authenticity_cap'] = {'cap': risk_cap, 'reasons': cap_reasons} if cap_reasons else {'cap': 20}
        self.scores['risk_constraints'] = score
        self.details['risk_constraints'] = cs
        print(f"  Risk control total: {score}/20")

    # ============================================================
    # Signal Generation (15 points) - STRICT per-factor checks
    # ============================================================
    def _evaluate_signal_generation(self):
        print("\n[6] Signal generation (strict)...")
        score = 0
        ss = {}
        signal_df = self._load_df('signal_matrix')

        if signal_df is None or len(signal_df) == 0:
            self.scores['signal_generation'] = 0; return

        expected = ['TSMOM', 'XSMOM', 'CARRY', 'BREAKOUT', 'MEANREV']
        found = [c for c in expected if c in signal_df.columns]

        # ---- 6.1 Factor Verification (5 pts) - STRICT per-factor ----
        fv = {}
        pass_count = 0
        for col in found:
            vals = signal_df[col].dropna()
            if len(vals) == 0: fv[col] = 'EMPTY'; continue

            in_range = vals.min() >= -2.0 and vals.max() <= 2.0
            nonzero = (vals.abs() > 0.001).sum() / len(vals)

            if col == 'TSMOM':
                # Must show sector-specific behavior: different std per sector
                if 'ticker' in signal_df.columns:
                    by_sector = signal_df.groupby(signal_df['ticker'].map(SECTOR_MAP))[col]
                    sector_std = by_sector.std().dropna()
                    # STRICT: at least 3 sectors must have different std (cv > 0.2)
                    if len(sector_std) >= 3:
                        cv = sector_std.std() / sector_std.mean() if sector_std.mean() > 0 else 0
                        tsmom_ok = in_range and nonzero > 0.1 and cv > 0.15
                    else:
                        tsmom_ok = False
                else:
                    tsmom_ok = False  # No ticker column = can't verify sector behavior
                fv[col] = 'PASS' if tsmom_ok else 'FAIL'

            elif col == 'XSMOM':
                # Must be cross-sectionally ranked: roughly equal long/short
                long_r = (vals > 0.01).sum() / len(vals)
                short_r = (vals < -0.01).sum() / len(vals)
                balanced = abs(long_r - short_r) < 0.15  # STRICT: must be within 15%
                fv[col] = 'PASS' if (in_range and balanced and nonzero > 0.1) else 'FAIL'

            elif col == 'CARRY':
                # Must be standardized: mean near 0, std near 1
                carry_mean = abs(vals.mean())
                carry_std = vals.std()
                standardized = carry_mean < 0.2 and 0.5 < carry_std < 1.5
                fv[col] = 'PASS' if (in_range and standardized and nonzero > 0.1) else 'FAIL'

            elif col == 'BREAKOUT':
                # Must be sparse: >40% zeros (only signals on breakout days)
                zero_r = (vals.abs() < 0.001).sum() / len(vals)
                sparse = zero_r > 0.40
                fv[col] = 'PASS' if (in_range and sparse and nonzero > 0.05) else 'FAIL'

            elif col == 'MEANREV':
                # Must be sparse (only for cointegrated pairs) and small magnitude
                zero_r = (vals.abs() < 0.001).sum() / len(vals)
                sparse = zero_r > 0.50  # Most pairs not cointegrated
                small = vals.abs().mean() < 0.5
                fv[col] = 'PASS' if (in_range and sparse and small and nonzero > 0.01) else 'FAIL'

            if 'PASS' in fv.get(col, ''): pass_count += 1

        # STRICT: need ALL 5 factors passing for full marks
        if len(found) >= 5 and pass_count >= 5: ss['factor_validation'] = 5
        elif len(found) >= 5 and pass_count >= 4: ss['factor_validation'] = 3
        elif len(found) >= 4 and pass_count >= 3: ss['factor_validation'] = 1
        else: ss['factor_validation'] = 0
        print(f"  Factor validation: {fv}, passed={pass_count}/{len(found)}, score={ss['factor_validation']}/5")

        # ---- 6.2 Cointegration (5 pts) - must be in code AND produce valid results ----
        coint_info = self._check_cointegration_in_code()
        coint_in_code = coint_info.get('valid', False)
        meanrev_pair_info = self._check_meanrev_pair_signal(signal_df)
        # Also check MEANREV signal has non-zero output.
        meanrev_nonzero = False
        if 'MEANREV' in found:
            mv = signal_df['MEANREV'].dropna()
            if len(mv) > 0 and (mv.abs() > 0.001).sum() > 0:
                meanrev_nonzero = True

        if coint_in_code and meanrev_pair_info.get('valid', False): ss['cointegration_test'] = 5
        elif coint_in_code: ss['cointegration_test'] = 2
        elif meanrev_pair_info.get('valid', False) or meanrev_nonzero: ss['cointegration_test'] = 1
        else: ss['cointegration_test'] = 0
        ss['cointegration_evidence'] = {'code': coint_info, 'pair_signal': meanrev_pair_info, 'meanrev_nonzero': meanrev_nonzero}
        print(f"  Cointegration test: code={coint_in_code}, pair MEANREV={meanrev_pair_info.get('valid', False)}, score={ss['cointegration_test']}/5")

        # ---- 6.3 Conflict Handling (5 pts) ----
        methods, conflict_code_files = self._check_conflict_handling(signal_df, found)
        explicit_methods = [m for m in methods if m != 'signal_disagreement']
        has_disagreement = 'signal_disagreement' in methods
        if len(explicit_methods) >= 3: ss['conflict_resolution'] = 5
        elif len(explicit_methods) >= 2: ss['conflict_resolution'] = 3
        elif len(explicit_methods) >= 1 or has_disagreement: ss['conflict_resolution'] = 1
        else: ss['conflict_resolution'] = 0
        ss['conflict_evidence'] = {'methods': methods, 'explicit_methods': explicit_methods, 'scanned_code_files': conflict_code_files}
        print(f"  Conflict resolution: methods={methods}, score={ss['conflict_resolution']}/5")

        score = sum(v for v in ss.values() if isinstance(v, (int, float)))
        self.scores['signal_generation'] = score
        self.details['signal_generation'] = ss
        print(f"  Signal generation total: {score}/15")

    # ============================================================
    # Code Compliance (10 points) - NEW DIMENSION
    # ============================================================
    def _evaluate_code_compliance(self):
        """Code compliance check (10 pts) - random seed / library restrictions / cost source / FX source / time limit"""
        print("\n[7] Code compliance check (10 pts)...")
        score = 0
        cc = {}

        all_code, code_files = self._read_submission_code()
        scanned_code_files = len(code_files)

        # 1. Random seed (2 pts): fixed integer seed or deterministic/no-random.
        seed_info = self._detect_fixed_seed(all_code)
        uses_random = self._uses_random_process(all_code)
        cc['random_seed'] = 2 if (seed_info['fixed'] or not uses_random) else 0
        if seed_info['fixed']:
            seed_note = f"fixed_seed={seed_info['seed']} via {seed_info['source']}"
        elif not uses_random:
            seed_note = 'deterministic/no-random'
        else:
            seed_note = 'missing'
        cc['random_seed_evidence'] = seed_info
        print(f"  Random seed: {seed_note}, score={cc['random_seed']}/2")

        # 2. Library restrictions (2 pts): no disallowed imports
        disallowed = []
        for lib in ['torch', 'tensorflow', 'keras', 'xgboost', 'lightgbm',
                     'catboost', 'prophet', 'pymc', 'hmmlearn', 'cvxpy']:
            if f'import {lib}' in all_code or f'from {lib}' in all_code:
                disallowed.append(lib)
        cc['library_restrictions'] = 2 if len(disallowed) == 0 else 0
        print(f"  Library restrictions: {'✓' if not disallowed else 'violations:'+str(disallowed)}, score={cc['library_restrictions']}/2")

        # 3. Transaction cost source (2 pts): must read from contract_specs
        cost_from_input = ('transaction_cost' in all_code or 'transaction_cost' in all_code) and \
                          ('contract_specs' in all_code or 'futures_contract' in all_code)
        cc['cost_source'] = 2 if cost_from_input else 0
        print(f"  Trade cost source: {'✓' if cost_from_input else '✗'}, score={cc['cost_source']}/2")

        # 4. FX rate source (2 pts): must read from macro_factors
        fx_from_input = ('USDCNY' in all_code or 'fx_rate' in all_code or 'fx_cn' in all_code) and \
                        ('macro_factors' in all_code or 'fx_rates' in all_code)
        cc['fx_source'] = 2 if fx_from_input else 0
        print(f"  FX source: {'✓' if fx_from_input else '✗'}, score={cc['fx_source']}/2")

        # 5. Time limit (2 pts): code must complete within 4 hours
        time_ok = True
        if self.agent_run_output and 'elapsed' in self.agent_run_output:
            time_ok = self.agent_run_output['elapsed'] <= 14400
        elif self.details.get('agent_code_run', {}).get('status') == 'TIMEOUT':
            time_ok = False
        cc['time_limit'] = 2 if time_ok else 0
        print(f"  4-hour limit: {'✓' if time_ok else '✗'}, score={cc['time_limit']}/2")

        score = sum(cc[k] for k in ['random_seed', 'library_restrictions', 'cost_source', 'fx_source', 'time_limit'])
        cc['scanned_code_files'] = scanned_code_files
        self.scores['code_compliance'] = score
        self.details['code_compliance'] = cc
        print(f"  Code compliance total: {score}/10")

    # ============================================================
    # Cost & FX Verification (informational, scored in compliance)
    # ============================================================
    def _verify_costs_and_fx(self):
        print("\n[8] Trade cost and FX verification (informational)...")
        v = {'costs_from_input': False, 'fx_from_input': False}
        c, code_files = self._read_submission_code()
        v['scanned_code_files'] = len(code_files)
        if ('transaction_cost' in c or 'transaction_cost' in c) and ('contract_specs' in c or 'futures_contract' in c):
            v['costs_from_input'] = True
        if ('USDCNY' in c or 'fx_rate' in c or 'fx_cn' in c) and ('macro_factors' in c or 'fx_rates' in c):
            v['fx_from_input'] = True
        self.details['costs_fx_verification'] = v

    # ============================================================
    # Total Score
    # ============================================================
    def _evaluate_stress_sensitivity_evidence(self):
        """Hard gate: reports must be backed by the verified NAV/holding/trade/cost/FX chain."""
        bv = self.details.get('backtest_verification', {})
        closed_loop_ok = (
            self.scores.get('backtest_verification', 0) >= 7 and
            bv.get('nav_accounting', {}).get('score', 0) >= 2 and
            bv.get('position_trade_continuity', {}).get('score', 0) >= 2 and
            bv.get('pnl_nav_replay', {}).get('score', 0) >= 2 and
            bv.get('costs_fx', {}).get('score', 0) >= 1
        )
        evidence = {
            'closed_loop_ok': bool(closed_loop_ok),
            'stress_test': {'passed': False},
            'sensitivity': {'passed': False},
        }
        if not closed_loop_ok:
            reason = 'underlying NAV/position/trade/cost/FX closed-loop check failed'
            evidence['stress_test']['reason'] = reason
            evidence['sensitivity']['reason'] = reason
            return evidence

        final_nav = self._latest_nav_value()
        stress_tables = self._load_report_tables('stress_test_report')
        stress_ok, stress_reason = self._check_stress_tables(stress_tables, final_nav)
        evidence['stress_test'] = {'passed': bool(stress_ok), 'reason': stress_reason}

        sensitivity_tables = self._load_report_tables('sensitivity_report')
        sensitivity_ok, sensitivity_reason = self._check_sensitivity_tables(sensitivity_tables)
        evidence['sensitivity'] = {'passed': bool(sensitivity_ok), 'reason': sensitivity_reason}
        return evidence

    def _calculate_total_score(self):
        print("\n[9] Computing total score...")
        auto_keys = ['backtest_verification', 'performance_metrics', 'risk_constraints',
                     'signal_generation', 'code_compliance']
        auto = sum(self.scores.get(k, 0) for k in auto_keys)
        self.scores['auto_total'] = auto

        stress_sensitivity_evidence = self._evaluate_stress_sensitivity_evidence()
        self.details['stress_sensitivity_evidence'] = stress_sensitivity_evidence

        grand = auto
        self.scores['grand_total'] = grand

        print(f"  Authenticity check: {self.scores.get('backtest_verification',0)}/10")
        print(f"  Performance metrics: {self.scores.get('performance_metrics',0)}/25")
        print(f"  Risk control: {self.scores.get('risk_constraints',0)}/20")
        print(f"  Signal generation: {self.scores.get('signal_generation',0)}/15")
        print(f"  Code compliance: {self.scores.get('code_compliance',0)}/10")
        print(f"  Automated total: {auto}/80")
        print(f"  Total: {grand}/80")

    # ============================================================
    # Report Generation
    # ============================================================
    def _generate_report(self):
        if self.normalization_notes:
            self.details['format_normalization'] = self.normalization_notes
        results = {
            'timestamp': datetime.now().isoformat(),
            'scores': self.scores, 'details': self.details,
            'benchmark': self.benchmark_metrics,
            'schema_compliant': self.schema_compliant,
            'schema_errors': self.schema_errors,
            'total_max_score': 80,
        }
        jp = os.path.join(self.submission_dir, 'eval_results.json')
        with open(jp, 'w', encoding='utf-8') as f:
            json.dump(results, f, ensure_ascii=False, indent=2, default=str)

        wb = Workbook(); ws = wb.active; ws.title = 'Eval Results'
        hf = PatternFill(start_color='1F4E79', end_color='1F4E79', fill_type='solid')
        hfn = Font(color='FFFFFF', bold=True, size=11)
        ws.append(['Dimension','Item','Max','Score','Criteria'])
        for c in ws[1]: c.fill = hf; c.font = hfn; c.alignment = Alignment(horizontal='center')

        items = [
            ('Authenticity check(10)','File and date alignment',1,'-','core files complete and date validity>=95%=1'),
            ('Authenticity check(10)','NAV accounting consistency',2,'-','daily_pnl0.8+daily_return0.7+drawdown0.5; drawdown supports pos/neg'),
            ('Authenticity check(10)','Position-trade continuity',2,'-','position changes explained by trades, violation rate&lt;1%=2,&lt;=10%=1'),
            ('Authenticity check(10)','PnL/NAV full replay',3,'-','corr>=0.995&nav_err<=0.5%&pnl_err<=2%=3'),
            ('Authenticity check(10)','Cost and FX check',2,'-','per-trade cost match and USD FX correct=2, partial match=1'),
            ('Performance metrics(25)','annual_return',5,'-','≥8%=5,≥5%=3,>0=1'),
            ('Performance metrics(25)','sharpe_ratio',5,'-','≥0.8=5,≥0.5=3,>0=1'),
            ('Performance metrics(25)','max_drawdown',5,'-','after effective participation: <=10%=5,<=15%=3,<=20%=1'),
            ('Performance metrics(25)','calmar_ratio',5,'-','low exposure=0; >=0.5=5,>=0.2=2,>0=1'),
            ('Performance metrics(25)','sortino_ratio',5,'-','low exposure=0; >=1.0=5,>=0.5=2,>0=1'),
            ('Risk control(20)','Risk metrics (veto)',10,'-','low vol/exposure or <5 items compliant: deduction'),
            ('Risk control(20)','Drawdown control (daily)',5,'-','90% correct=4,70%=2'),
            ('Risk control(20)','Cross-border (daily notional)',5,'-','notional value ratio<=40%, FX/cost reuse closed-loop check'),
            ('Signal generation(15)','Factor validation (strict)',5,'-','5 factors all pass=5, 4=3, 3=1'),
            ('Signal generation(15)','Cointegration test',5,'-','submitted code real cointegration/ADF+pair spread signal=5'),
            ('Signal generation(15)','Conflict resolution',5,'-','3 explicit methods=5, 2=3, signal disagreement only max 1'),
            ('Code compliance(10)','Random seed',2,'-','submitted code fixed int seed/recorded seed or no random process=2'),
            ('Code compliance(10)','Library restrictions',2,'-','no prohibited libs=2'),
            ('Code compliance(10)','Cost source',2,'-','from contract_specs=2'),
            ('Code compliance(10)','FX source',2,'-','from macro_factors=2'),
            ('Code compliance(10)','Time limit',2,'-','completed within 4 hours=2'),
        ]
        for item in items: ws.append(list(item))

        auto = self.scores.get('auto_total',0)
        grand = self.scores.get('grand_total',0)
        ws.append(['Total','Automated scoring',80,auto,'authenticity10+perf25+risk20+signal15+compliance10'])
        ws.append(['Total','Total',80,grand,''])

        for col in ws.columns:
            ml = max(len(str(c.value or '')) for c in col)
            ws.column_dimensions[col[0].column_letter].width = min(ml+3, 45)

        ep = os.path.join(self.submission_dir, 'eval_report.xlsx')
        wb.save(ep)
        print(f"\nEval report saved: {ep}")

    # ============================================================
    # Helpers
    # ============================================================
    def _compute_exposure_stats(self, nav_df=None, holdings_df=None):
        """Compute whether the strategy took enough real risk to earn drawdown/risk credits."""
        stats = {
            'annual_vol': 0.0,
            'avg_gross_exposure': 0.0,
            'active_exposure_ratio': 0.0,
            'participation_status': 'fail',
            'thresholds': {
                'pass': 'annual_vol>=5%, avg_gross_exposure>=10%, active_exposure_ratio>=70%',
                'partial': 'annual_vol>=3%, avg_gross_exposure>=5%, active_exposure_ratio>=40%',
            },
        }
        try:
            nav_df = nav_df if nav_df is not None else self._load_df('nav_history')
            holdings_df = holdings_df if holdings_df is not None else self._load_df('holdings_detail')
            if nav_df is None or len(nav_df) == 0:
                stats['reason'] = 'missing nav_history'
                return stats

            nav_date_col = self._find_col(nav_df, ['date', 'date_cn'])
            nav_col = self._find_col(nav_df, ['nav', 'nav_cn'])
            if not (nav_date_col and nav_col):
                stats['reason'] = 'nav_history missing date or nav column'
                return stats

            nav = nav_df[[nav_date_col, nav_col]].copy()
            nav['dp'] = pd.to_datetime(nav[nav_date_col])
            nav['nav_value'] = pd.to_numeric(nav[nav_col], errors='coerce')
            nav = nav.dropna(subset=['dp', 'nav_value']).sort_values('dp').drop_duplicates('dp', keep='last')
            perf_nav = nav[nav['dp'] >= pd.Timestamp(PERF_START_DATE)].copy()
            if len(perf_nav) < 10:
                perf_nav = nav.copy()
            if len(perf_nav) > 1:
                s = perf_nav['nav_value'].values.astype(float)
                dr = np.diff(s) / s[:-1]
                dr = dr[np.isfinite(dr)]
                stats['annual_vol'] = float(np.std(dr) * np.sqrt(252)) if len(dr) else 0.0

            if holdings_df is None or len(holdings_df) == 0:
                stats['reason'] = 'missing holdings_detail'
                return stats
            h_date_col = self._find_col(holdings_df, ['date', 'date_cn'])
            h_ticker_col = self._find_col(holdings_df, ['ticker', 'instrument_cn', 'contract_cn'])
            h_lots_col = self._find_col(holdings_df, ['lots', 'position_lots', 'position', 'position_lots_cn', 'lots_cn'])
            if not all([h_date_col, h_ticker_col, h_lots_col]):
                stats['reason'] = 'holdings_detail missing date, ticker, or lots column'
                return stats

            raw_parts = []
            if 'domestic' in self.raw_data:
                raw_parts.append(self.raw_data['domestic'][['date', 'ticker', 'close']])
            if 'overseas' in self.raw_data:
                raw_parts.append(self.raw_data['overseas'][['date', 'ticker', 'close']])
            if not raw_parts:
                stats['reason'] = 'missing raw market data'
                return stats
            raw_all = pd.concat(raw_parts, ignore_index=True)
            raw_all['date'] = pd.to_datetime(raw_all['date'])
            price_pivot = raw_all.pivot_table(index='date', columns='ticker', values='close').sort_index().ffill()

            specs_dict = {}
            if 'specs' in self.raw_data:
                for _, row in self.raw_data['specs'].iterrows():
                    specs_dict[str(row['ticker'])] = {
                        'multiplier': float(row.get('multiplier', 1)),
                        'currency': str(row.get('currency', 'CNY')).upper(),
                    }

            fx_series = pd.Series(dtype=float)
            if 'fx' in self.raw_data:
                fx_df = self.raw_data['fx'].copy()
                fx_df['date'] = pd.to_datetime(fx_df['date'])
                if 'USDCNY' in fx_df.columns:
                    fx_series = fx_df.drop_duplicates('date').set_index('date')['USDCNY'].astype(float).sort_index()

            def fx_for(date, currency):
                if str(currency).upper() != 'USD':
                    return 1.0
                if len(fx_series) == 0:
                    return 7.0
                v = fx_series.asof(pd.Timestamp(date))
                return 7.0 if pd.isna(v) else float(v)

            holdings = holdings_df[[h_date_col, h_ticker_col, h_lots_col]].copy()
            holdings['dp'] = pd.to_datetime(holdings[h_date_col])
            holdings['ticker_norm'] = holdings[h_ticker_col].astype(str)
            holdings['lots_norm'] = pd.to_numeric(holdings[h_lots_col], errors='coerce').fillna(0.0)
            holdings = holdings.dropna(subset=['dp'])
            perf_dates = list(perf_nav['dp'])
            nav_series = perf_nav.set_index('dp')['nav_value'].sort_index()
            ratios = []
            for date in perf_dates:
                day = holdings[holdings['dp'] == date]
                total_notional = 0.0
                price_date = date if date in price_pivot.index else price_pivot.index.asof(pd.Timestamp(date))
                if pd.isna(price_date):
                    ratios.append(0.0)
                    continue
                for _, row in day.iterrows():
                    ticker = row['ticker_norm']
                    lots = abs(float(row['lots_norm']))
                    if lots <= 1e-12 or ticker not in price_pivot.columns:
                        continue
                    price = price_pivot.loc[price_date, ticker]
                    if pd.isna(price):
                        continue
                    spec = specs_dict.get(ticker, {'multiplier': 1.0, 'currency': 'CNY'})
                    total_notional += lots * spec['multiplier'] * float(price) * fx_for(date, spec['currency'])
                nav_value = nav_series.asof(pd.Timestamp(date))
                ratios.append(0.0 if pd.isna(nav_value) or nav_value <= 0 else total_notional / float(nav_value))

            if ratios:
                ratios = np.asarray(ratios, dtype=float)
                stats['avg_gross_exposure'] = float(np.mean(ratios))
                stats['active_exposure_ratio'] = float(np.mean(ratios >= 0.10))

            if (stats['annual_vol'] >= 0.05 and
                    stats['avg_gross_exposure'] >= 0.10 and
                    stats['active_exposure_ratio'] >= 0.70):
                stats['participation_status'] = 'pass'
            elif (stats['annual_vol'] >= 0.03 and
                    stats['avg_gross_exposure'] >= 0.05 and
                    stats['active_exposure_ratio'] >= 0.40):
                stats['participation_status'] = 'partial'
            else:
                stats['reason'] = 'low volatility, low avg exposure, or insufficient active participation'

            for k in ['annual_vol', 'avg_gross_exposure', 'active_exposure_ratio']:
                stats[k] = round(float(stats[k]), 6)
            return stats
        except Exception as e:
            stats['reason'] = str(e)[:200]
            return stats

    def _latest_nav_value(self):
        nav_df = self._load_df('nav_history')
        if nav_df is None or len(nav_df) == 0:
            return None
        date_col = self._find_col(nav_df, ['date', 'date_cn'])
        nav_col = self._find_col(nav_df, ['nav', 'nav_cn'])
        if not (date_col and nav_col):
            return None
        nav = nav_df[[date_col, nav_col]].copy()
        nav['dp'] = pd.to_datetime(nav[date_col])
        nav['nav_value'] = pd.to_numeric(nav[nav_col], errors='coerce')
        nav = nav.dropna(subset=['dp', 'nav_value']).sort_values('dp')
        return None if len(nav) == 0 else float(nav['nav_value'].iloc[-1])

    def _load_report_tables(self, key):
        if key not in self.found_files:
            return []
        path = self.found_files[key]
        try:
            lower = path.lower()
            if lower.endswith('.csv'):
                return [pd.read_csv(path)]
            if lower.endswith(('.xlsx', '.xls')):
                sheets = pd.read_excel(path, sheet_name=None)
                return [df for df in sheets.values() if isinstance(df, pd.DataFrame) and len(df) > 0]
        except Exception:
            return []
        return []

    def _concat_tables(self, tables):
        frames = []
        for df in tables:
            if df is not None and len(df) > 0:
                temp = df.copy()
                temp.columns = [str(c).strip() for c in temp.columns]
                frames.append(temp)
        return pd.concat(frames, ignore_index=True, sort=False) if frames else pd.DataFrame()

    def _has_col_like(self, df, aliases):
        return self._find_col(df, aliases) is not None

    def _check_stress_tables(self, tables, final_nav):
        df = self._concat_tables(tables)
        if len(df) == 0:
            return False, 'missing CSV/XLSX structured stress test results'
        scenario_col = self._find_col(df, ['scenario_id', 'scenario_name', 'scenario', 'scenario_cn', 'scenario2_cn'])
        base_nav_col = self._find_col(df, ['base_nav', 'current_nav', 'nav_before', 'base_nav_cn', 'current_nav_cn'])
        shocked_col = self._find_col(df, ['shocked_nav', 'stress_nav', 'nav_after', 'shocked_nav_cn'])
        pnl_col = self._find_col(df, ['estimated_pnl_cny', 'estimated_loss', 'loss_cny', 'pnl_cny', 'pnl2_cn', 'loss_cn'])
        impact_col = self._find_col(df, ['impact_on_nav_pct', 'estimated_return', 'impact_pct', 'return', 'impact_ratio_cn'])
        ticker_col = self._find_col(df, ['largest_loss_ticker', 'ticker', 'instrument_cn'])
        if scenario_col is None or df[scenario_col].dropna().nunique() < 8:
            return False, 'stress test must contain at least 8 distinct scenarios'
        if base_nav_col is None:
            return False, 'stress test missing base_nav/current_nav, cannot verify replay-based NAV'
        if shocked_col is None and pnl_col is None and impact_col is None:
            return False, 'stress test missing shocked NAV, estimated PnL, or NAV impact fields'
        if ticker_col is None:
            return False, 'stress test missing instrument-level impact, cannot verify real positions'
        if final_nav is not None:
            base_vals = pd.to_numeric(df[base_nav_col], errors='coerce').dropna()
            if len(base_vals) == 0:
                return False, 'base_nav field has no valid values'
            rel_err = abs(float(base_vals.median()) - final_nav) / max(abs(final_nav), 1.0)
            if rel_err > 0.01:
                return False, f'base_nav inconsistent with nav_history final NAV (rel_err={rel_err:.4f})'
        numeric_cols = df.select_dtypes(include=[np.number]).columns
        if len(numeric_cols) == 0:
            return False, 'stress test results missing verifiable numeric columns'
        return True, 'stress test structured results passed closed-loop basic check'

    def _check_sensitivity_tables(self, tables):
        df = self._concat_tables(tables)
        if len(df) == 0:
            return False, 'missing CSV/XLSX structured sensitivity results'
        param_col = self._find_col(df, ['parameter_name', 'parameter', 'param', 'param_cn'])
        base_col = self._find_col(df, ['base_value', 'base', 'base_value_cn', 'benchmark_value_cn'])
        test_col = self._find_col(df, ['test_value', 'value', 'adjusted_value', 'test_value_cn', 'perturbed_value_cn'])
        if param_col is None or df[param_col].dropna().nunique() < 3:
            return False, 'sensitivity analysis must contain at least 3 distinct parameters'
        metric_cols = [
            self._find_col(df, ['annual_return', 'annual_return']),
            self._find_col(df, ['sharpe', 'sharpe_cn']),
            self._find_col(df, ['max_drawdown', 'max_drawdown']),
            self._find_col(df, ['nav_final', 'final_nav', 'delta_nav', 'final_nav_cn', 'nav_change_cn']),
        ]
        metric_cols = [c for c in metric_cols if c is not None]
        if not metric_cols:
            return False, 'sensitivity analysis missing performance/NAV result fields'
        if base_col is not None and test_col is not None:
            base_vals = pd.to_numeric(df[base_col], errors='coerce')
            test_vals = pd.to_numeric(df[test_col], errors='coerce')
            rel = (test_vals - base_vals).abs() / base_vals.abs().replace(0, np.nan)
            if not ((rel >= 0.15) & (rel <= 0.25)).any():
                return False, 'sensitivity analysis does not show ~+/-20% parameter perturbation'
        varied = False
        for col in metric_cols:
            vals = pd.to_numeric(df[col], errors='coerce').dropna()
            if len(vals) > 1 and vals.nunique() > 1:
                varied = True
                break
        if not varied:
            return False, 'sensitivity results are constant or have no valid numeric variation'
        return True, 'sensitivity structured results passed closed-loop basic check'

    def _find_col(self, df, aliases):
        """Find a column by exact or substring match across English/Chinese aliases."""
        if df is None:
            return None
        normalized = {str(c).lower().strip(): c for c in df.columns}
        for alias in aliases:
            key = str(alias).lower().strip()
            if key in normalized:
                return normalized[key]
        for alias in aliases:
            key = str(alias).lower().strip()
            for col in df.columns:
                if key in str(col).lower().strip():
                    return col
        return None

    def _safe_corr(self, x, y):
        x = np.asarray(x, dtype=float)
        y = np.asarray(y, dtype=float)
        mask = np.isfinite(x) & np.isfinite(y)
        if mask.sum() < 3:
            return 0.0
        x = x[mask]
        y = y[mask]
        if np.std(x) == 0 or np.std(y) == 0:
            return 1.0 if np.allclose(x, y, rtol=1e-8, atol=1e-8) else 0.0
        return float(np.corrcoef(x, y)[0, 1])

    def _find_file(self, directory, names):
        files = self._find_files(directory, names)
        return files[0] if files else None

    def _find_files(self, directory, names):
        """Find files robustly, including accidental double extensions like .xlsx.xlsx."""
        if not directory or not os.path.exists(directory):
            return []
        wanted = [n.lower() for n in names]
        matches = []
        for root, dirs, files in os.walk(directory):
            dirs[:] = [d for d in dirs if not d.startswith('.') and d not in {'__MACOSX', '__pycache__'}]
            for f in files:
                fl = f.lower()
                if fl.startswith('.') or fl.startswith('~$') or fl.startswith('.~'):
                    continue
                full = os.path.join(root, f)
                for w in wanted:
                    stem = os.path.splitext(w)[0]
                    if fl == w or fl == w + '.xlsx' or fl == w + '.csv':
                        matches.append(full); break
                    if fl.startswith(stem) and fl.endswith(('.csv', '.xlsx', '.xls')):
                        matches.append(full); break
                    if stem in fl and fl.endswith(('.csv', '.xlsx', '.xls')):
                        matches.append(full); break
        # Prefer shallower paths and exact-looking names.
        matches = sorted(set(matches), key=lambda p: (p.count(os.sep), len(os.path.basename(p)), p))
        return matches

    def _read_table(self, path):
        if path.lower().endswith('.csv'):
            return pd.read_csv(path)
        return pd.read_excel(path)

    def _normalize_nav_df(self, df):
        """Keep prompt-enforced nav_history schema strict; do not auto-fix unit NAV."""
        return df

    def _normalize_signal_df(self, df):
        """Accept both wide signal tables and long tables with strategy/signal columns."""
        if df is None or len(df) == 0:
            return df
        df = df.copy()
        lower_cols = {str(c).lower(): c for c in df.columns}
        if {'date', 'ticker', 'signal', 'strategy'}.issubset(lower_cols):
            date_col = lower_cols['date']
            ticker_col = lower_cols['ticker']
            signal_col = lower_cols['signal']
            strategy_col = lower_cols['strategy']
            temp = df[[date_col, ticker_col, signal_col, strategy_col]].copy()
            temp['strategy_norm'] = (
                temp[strategy_col].astype(str).str.lower().str.replace('-', '_', regex=False)
                .map(SIGNAL_ALIASES)
            )
            temp = temp.dropna(subset=['strategy_norm'])
            if len(temp) > 0:
                wide = temp.pivot_table(
                    index=[date_col, ticker_col],
                    columns='strategy_norm',
                    values=signal_col,
                    aggfunc='mean',
                ).reset_index()
                wide = wide.rename(columns={date_col: 'date', ticker_col: 'ticker'})
                for c in ['TSMOM', 'XSMOM', 'CARRY', 'BREAKOUT', 'MEANREV']:
                    if c not in wide.columns:
                        wide[c] = 0.0
                self.normalization_notes['signal_matrix'] = 'detected long-format signal_matrix, auto-pivoted to wide 5-factor format'
                return wide
        rename = {}
        for c in df.columns:
            key = str(c).lower().replace('-', '_')
            if key in SIGNAL_ALIASES:
                rename[c] = SIGNAL_ALIASES[key]
        if rename:
            df = df.rename(columns=rename)
        return df

    def _load_df(self, key):
        if key in self.found_files:
            p = self.found_files[key]
            try:
                df = self._read_table(p)
                if key == 'nav_history':
                    return self._normalize_nav_df(df)
                if key == 'signal_matrix':
                    return self._normalize_signal_df(df)
                return df
            except: pass
        return None

    def _iter_submission_files(self, include_outputs=True):
        """Iterate agent-visible files while excluding judge/input/reference artifacts."""
        if not self.submission_dir or not os.path.exists(self.submission_dir):
            return
        excluded_dirs = {
            'scoring', 'input', 'inputs', 'hidden', 'standard_answer',
            'answer_output', '__pycache__', '.git', '__MACOSX',
            'scoring_scheme_details_attachment', 'scoring_scheme', 'real_results_attachment', 'real_results',
        }
        if not include_outputs:
            excluded_dirs.add('outputs')
        excluded_prefixes = (
            'standard_answer', 'eval_report', 'eval_results', 'test_output',
            'scorer_manifest', 'manual_adjustment', 'scoring_scheme', 'real_results',
        )
        for root, dirs, files in os.walk(self.submission_dir):
            rel_root = os.path.relpath(root, self.submission_dir)
            parts = [] if rel_root == '.' else rel_root.split(os.sep)
            if any(p in excluded_dirs or p.startswith(excluded_prefixes) for p in parts):
                dirs[:] = []
                continue
            dirs[:] = [
                d for d in dirs
                if not (
                    d.startswith('.') or d in excluded_dirs or
                    d.startswith(excluded_prefixes)
                )
            ]
            for f in files:
                fl = f.lower()
                if (
                    fl.startswith('.') or fl.startswith('~$') or fl.startswith('.~') or
                    fl.startswith(excluded_prefixes)
                ):
                    continue
                yield os.path.join(root, f)

    def _delivery_file_priority(self, path, patterns):
        rel = os.path.relpath(path, self.submission_dir)
        parts = rel.split(os.sep)
        base = os.path.basename(path).lower()
        stem = os.path.splitext(base)[0]
        exact = 0 if any(stem == p or base == p for p in patterns) else 1
        outputs_penalty = 1 if 'outputs' in parts else 0
        return (outputs_penalty, exact, rel.count(os.sep), len(base), rel)

    def _iter_submission_code_files(self):
        """Only read agent-submitted source files, never judge/scoring assets."""
        if not self.submission_dir or not os.path.exists(self.submission_dir):
            return
        excluded_dirs = {
            'scoring', 'input', 'inputs', 'hidden', 'standard_answer',
            'answer_output', 'outputs', '__pycache__', '.git', '__MACOSX',
            'scoring_scheme_details_attachment', 'scoring_scheme', 'real_results_attachment', 'real_results',
        }
        excluded_prefixes = (
            'standard_answer', 'eval_report', 'eval_results', 'test_output',
            'scorer_manifest', 'manual_adjustment', 'scoring_scheme', 'real_results',
        )
        excluded_files = {'score.py'}
        for root, dirs, files in os.walk(self.submission_dir):
            rel_root = os.path.relpath(root, self.submission_dir)
            parts = [] if rel_root == '.' else rel_root.split(os.sep)
            if any(p in excluded_dirs or p.startswith(excluded_prefixes) for p in parts):
                dirs[:] = []
                continue
            dirs[:] = [
                d for d in dirs
                if not (
                    d.startswith('.') or d in excluded_dirs or
                    d.startswith(excluded_prefixes)
                )
            ]
            for f in files:
                fl = f.lower()
                if (
                    not fl.endswith('.py') or fl.startswith('.') or fl.startswith('~$') or
                    fl in excluded_files or fl.startswith('eval_script') or
                    fl.startswith(excluded_prefixes)
                ):
                    continue
                yield os.path.join(root, f)

    def _read_submission_code(self):
        code_parts = []
        code_files = []
        for path in self._iter_submission_code_files():
            try:
                with open(path, 'r', encoding='utf-8', errors='ignore') as fh:
                    code_parts.append(fh.read())
                    code_files.append(path)
            except:
                pass
        return '\n'.join(code_parts), code_files

    def _detect_fixed_seed(self, code):
        direct_patterns = [
            (r'\b(?:np|numpy)\.random\.seed\s*\(\s*(\d+)\s*\)', 'np.random.seed'),
            (r'\brandom\.seed\s*\(\s*(\d+)\s*\)', 'random.seed'),
            (r'\b(?:np|numpy)\.random\.default_rng\s*\(\s*(\d+)\s*\)', 'default_rng'),
            (r'\bdefault_rng\s*\(\s*(\d+)\s*\)', 'default_rng'),
            (r'\brandom_state\s*=\s*(\d+)\b', 'random_state'),
            (r'["\']random_state["\']\s*:\s*(\d+)\b', 'random_state'),
        ]
        for pattern, source in direct_patterns:
            m = re.search(pattern, code, flags=re.I)
            if m:
                return {
                    'fixed': True,
                    'seed': int(m.group(1)),
                    'source': source,
                    'evidence': m.group(0)[:120],
                }

        seed_vars = self._find_constant_seed_variables(code)
        for name, value in seed_vars.items():
            var = re.escape(name)
            use_patterns = [
                r'\b(?:np|numpy)\.random\.seed\s*\(\s*' + var + r'\s*\)',
                r'\brandom\.seed\s*\(\s*' + var + r'\s*\)',
                r'\b(?:np|numpy)\.random\.default_rng\s*\(\s*' + var + r'\s*\)',
                r'\bdefault_rng\s*\(\s*' + var + r'\s*\)',
                r'\brandom_state\s*=\s*' + var + r'\b',
                r'["\']random_state["\']\s*:\s*' + var + r'\b',
            ]
            for pattern in use_patterns:
                m = re.search(pattern, code, flags=re.I)
                if m:
                    return {
                        'fixed': True,
                        'seed': value,
                        'source': f'constant variable {name}',
                        'evidence': m.group(0)[:120],
                    }

        recorded = self._find_recorded_seed()
        if recorded and self._code_uses_recorded_seed(code, recorded['key']):
            return {
                'fixed': True,
                'seed': recorded['seed'],
                'source': 'config/diagnostics',
                'evidence': f"{recorded['key']} in {recorded['file']}",
            }

        return {'fixed': False, 'seed': None, 'source': 'missing', 'evidence': ''}

    def _find_constant_seed_variables(self, code):
        seed_vars = {}
        patterns = [
            r'\b([A-Za-z_][A-Za-z0-9_]*(?:seed|random_state)[A-Za-z0-9_]*)\s*=\s*(\d+)\b',
            r'\b([A-Z_][A-Z0-9_]*SEED[A-Z0-9_]*)\s*=\s*(\d+)\b',
        ]
        for pattern in patterns:
            for m in re.finditer(pattern, code, flags=re.I):
                seed_vars[m.group(1)] = int(m.group(2))
        return seed_vars

    def _find_recorded_seed(self):
        seed_keys = {'random_seed', 'seed', 'rng_seed', 'random_state', 'np_random_seed'}
        for path in self._iter_submission_files(include_outputs=True):
            base = os.path.basename(path).lower()
            if not base.endswith('.json'):
                continue
            if not any(token in base for token in ('config', 'diagnostic', 'setting', 'param')):
                continue
            try:
                with open(path, 'r', encoding='utf-8', errors='ignore') as fh:
                    data = json.load(fh)
            except:
                continue
            found = self._extract_seed_from_json(data, seed_keys)
            if found:
                rel = os.path.relpath(path, self.submission_dir)
                found['file'] = rel
                return found
        return None

    def _extract_seed_from_json(self, data, seed_keys):
        if isinstance(data, dict):
            for key, value in data.items():
                key_norm = str(key).lower()
                if key_norm in seed_keys:
                    seed = self._coerce_seed_int(value)
                    if seed is not None:
                        return {'key': key_norm, 'seed': seed}
                found = self._extract_seed_from_json(value, seed_keys)
                if found:
                    return found
        elif isinstance(data, list):
            for value in data:
                found = self._extract_seed_from_json(value, seed_keys)
                if found:
                    return found
        return None

    def _coerce_seed_int(self, value):
        if isinstance(value, bool):
            return None
        if isinstance(value, int):
            return value
        if isinstance(value, float) and value.is_integer():
            return int(value)
        if isinstance(value, str) and re.fullmatch(r'\d+', value.strip()):
            return int(value.strip())
        return None

    def _code_uses_recorded_seed(self, code, recorded_key):
        seed_terms = r'(?:random_seed|rng_seed|np_random_seed|random_state|\bseed\b|config|diagnostic)'
        seed_use_patterns = [
            r'\b(?:np|numpy)\.random\.seed\s*\([^\n;]*' + seed_terms + r'[^\n;]*\)',
            r'\brandom\.seed\s*\([^\n;]*' + seed_terms + r'[^\n;]*\)',
            r'\b(?:np|numpy)\.random\.default_rng\s*\([^\n;]*' + seed_terms + r'[^\n;]*\)',
            r'\bdefault_rng\s*\([^\n;]*' + seed_terms + r'[^\n;]*\)',
            r'\brandom_state\s*=\s*[^\n,)\]}]*' + seed_terms,
            r'["\']random_state["\']\s*:\s*[^\n,)\]}]*' + seed_terms,
        ]
        has_seed_use = any(re.search(p, code, flags=re.I) for p in seed_use_patterns)
        key_or_file_ref = (
            re.search(r'["\']' + re.escape(recorded_key) + r'["\']', code, flags=re.I) or
            re.search(r'\b(?:config|diagnostic|diagnostics)\b', code, flags=re.I)
        )
        return bool(has_seed_use and key_or_file_ref)

    def _uses_random_process(self, code):
        patterns = [
            r'\b(?:np|numpy)\.random\.',
            r'\brandom\.(?:random|randint|choice|shuffle|sample|seed)\b',
            r'\bdefault_rng\s*\(',
            r'\brandom_state\b',
            r'\btrain_test_split\s*\(',
            r'\bshuffle\s*\(',
            r'\bsample\s*\(',
            r'\bpermutation\s*\(',
            r'\bchoice\s*\(',
        ]
        return any(re.search(p, code) for p in patterns)

    def _check_meanrev_pair_signal(self, signal_df):
        if not {'date', 'ticker', 'MEANREV'}.issubset(set(signal_df.columns)):
            return {
                'valid': False,
                'reason': 'signal_matrix missing date/ticker/MEANREV columns',
                'active_pair_days': 0,
            }
        df = signal_df[['date', 'ticker', 'MEANREV']].copy()
        df['date_norm'] = pd.to_datetime(df['date'], errors='coerce')
        df['ticker_norm'] = df['ticker'].astype(str)
        df['meanrev_norm'] = pd.to_numeric(df['MEANREV'], errors='coerce').fillna(0.0)
        active_pair_days = 0
        opposite_days = 0
        active_pairs = 0
        for t1, t2 in MEANREV_PAIRS:
            left = df[df['ticker_norm'] == t1][['date_norm', 'meanrev_norm']].rename(columns={'meanrev_norm': 's1'})
            right = df[df['ticker_norm'] == t2][['date_norm', 'meanrev_norm']].rename(columns={'meanrev_norm': 's2'})
            merged = left.merge(right, on='date_norm', how='inner').dropna()
            both = merged[(merged['s1'].abs() > 0.001) & (merged['s2'].abs() > 0.001)]
            if len(both) == 0:
                continue
            active_pairs += 1
            active_pair_days += len(both)
            opposite_days += int((np.sign(both['s1']) == -np.sign(both['s2'])).sum())
        opposite_ratio = 0.0 if active_pair_days == 0 else opposite_days / active_pair_days
        return {
            'valid': active_pairs >= 1 and active_pair_days >= 20 and opposite_ratio >= 0.80,
            'active_pairs': int(active_pairs),
            'active_pair_days': int(active_pair_days),
            'opposite_ratio': round(float(opposite_ratio), 4),
        }

    def _check_cointegration_in_code(self):
        code, code_files = self._read_submission_code()
        has_test_call = bool(re.search(r'\b(?:adfuller|coint)\s*\(', code))
        has_pair_logic = bool(re.search(r'\b(pair|pairs|spread|hedge|residual|cointegr)\b|cointegration|spread|residual', code, re.IGNORECASE))
        has_meanrev_context = bool(re.search(r'\b(MEANREV|meanrev|mean_reversion)\b|mean_reversion', code, re.IGNORECASE))
        return {
            'valid': bool(has_test_call and has_pair_logic and has_meanrev_context),
            'has_test_call': has_test_call,
            'has_pair_logic': has_pair_logic,
            'has_meanrev_context': has_meanrev_context,
            'scanned_code_files': len(code_files),
        }

    def _check_conflict_handling(self, signal_df, found_cols):
        methods = []
        code, code_files = self._read_submission_code()
        if re.search(r'\bconflict\b|conflict', code, re.IGNORECASE) and re.search(r'\b(if|where|sign|neutral|zero|reduce|scale|filter)\b|threshold|zero_out|reduce_position', code, re.IGNORECASE):
            methods.append('explicit_conflict_resolution')
        if re.search(r'\b(combined_signal|strategy_weights|weighted_signal)\b', code) and re.search(r'[=+\-*/]', code):
            methods.append('weighted_combination')
        if re.search(r'\b(signal_threshold|threshold|signal_threshold|signal_strength_filter)\b', code, re.IGNORECASE) and re.search(r'\b(abs|where|if|clip)\b', code):
            methods.append('signal_strength_filter')
        if re.search(r'\b(priority|priority)\b', code, re.IGNORECASE) and re.search(r'\b(if|elif|sort|rank|where)\b', code):
            methods.append('priority_rules')
        if len(found_cols) >= 2 and 'TSMOM' in found_cols and 'CARRY' in found_cols:
            t = signal_df['TSMOM']; ca = signal_df['CARRY']
            both = (t.abs()>0.01)&(ca.abs()>0.01)
            if both.sum() > 0 and (np.sign(t[both])!=np.sign(ca[both])).sum() > 0:
                methods.append('signal_disagreement')
        return list(dict.fromkeys(methods)), len(code_files)


def main():
    parser = argparse.ArgumentParser(description='CTA strategy system automated evaluation')
    parser.add_argument('--submission_dir', type=str, required=True)
    parser.add_argument('--data_dir', type=str, required=True)
    parser.add_argument('--standard_answer_dir', type=str, default=None)
    parser.add_argument('--run_agent_code', action='store_true')
    parser.add_argument('--timeout', type=int, default=14400)
    args = parser.parse_args()

    ev = CTAEvaluator(args.submission_dir, args.data_dir,
                      standard_answer_dir=args.standard_answer_dir,
                      run_agent_code=args.run_agent_code,
                      timeout=args.timeout)
    ev.evaluate_all()
    print("\n" + "="*60 + "\nEvaluation complete!\n" + "="*60)

if __name__ == '__main__':
    main()
