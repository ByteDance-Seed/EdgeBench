"""Actual patched scorer entrypoint with synthetic data and frozen external effects."""
import ast
from contextlib import redirect_stdout
from copy import deepcopy
import io
import inspect
import json
from pathlib import Path
import runpy
import sys
import tempfile
import unittest
from unittest.mock import patch
import pandas as pd
import ledger_contract
from test_ledger_contract import fixture

judge = runpy.run_path(sys.argv.pop(1), run_name='judge_rules')
runtime = judge['main'].__globals__


class JudgeLedgerTests(unittest.TestCase):
    def full_event_report(self, outside=(), missing_event=None, missing_session=None):
        """Run through the actual report, not just the pre-performance gate."""
        dates = [str(d.date()) for d in pd.bdate_range('2025-01-02', periods=42)]
        assets = judge['ALL_ETFS']
        result = dict(
            accounting_contract='portfolio-ledger-v2', initial_capital=10_000_000,
            trades=[], metrics={},
            daily_nav=[dict(date=d, nav=1) for d in dates],
            daily_weights=[dict(date=d, weights=dict.fromkeys(assets, 0)) for d in dates],
            daily_accounting=[dict(date=d, cash=10_000_000, equity=10_000_000,
                                   shares=dict.fromkeys(assets, 0), commission=0,
                                   slippage_cost=0, borrow_cost=0) for d in dates],
            risk_calibration=dict(rebalance_history=[
                dict(date=dates[i], trigger='initial' if i == 0 else 'scheduled')
                for i in (0, 20, 40) if i != missing_event]))
        if missing_session is not None:
            for field in ('daily_nav', 'daily_weights', 'daily_accounting'):
                result[field].pop(missing_session)
        market = [dict(date=d, stock_code=a, close=100, low=99, high=101)
                  for d in sorted([*dates, *outside]) for a in assets]
        with tempfile.TemporaryDirectory() as directory:
            import os
            previous = os.getcwd()
            try:
                os.chdir(directory)
                pd.DataFrame(market).to_csv('etf_prices_test.csv', index=False)
                def strategy():
                    visible = pd.read_csv('etf_prices_test.csv')
                    self.assertEqual(sorted(visible.date.unique()), dates)
                    Path('backtest_results.json').write_text(json.dumps(result))
                    return True, 1, 'synthetic'
                with patch.dict(runtime, TEST_START=dates[0], TEST_END=dates[-1],
                                map_platform_files=lambda: None,
                                audit_strategy_code=lambda: (True, [], []),
                                run_strategy_and_generate_output=strategy), redirect_stdout(io.StringIO()):
                    judge['main']()
                self.assertEqual(sorted(pd.read_csv('etf_prices_test.csv').date.unique()),
                                 sorted([*dates, *outside]))
                return json.loads(Path('score_report.json').read_text())
            finally:
                os.chdir(previous)

    def test_full_report_events_keep_the_evaluator_period(self):
        baseline = self.full_event_report()
        # The existing missing-risk-trigger penalty is independent of this fix.
        self.assertEqual(baseline['validation']['constraint_penalty'], 5)
        for outside in (('2024-12-31',), ('2026-01-01',),
                        ('2024-12-31', '2026-01-01'), ('2025-01-01', '2025-03-03')):
            with self.subTest(outside=outside):
                report = self.full_event_report(outside)
                self.assertEqual(report['validation']['constraint_penalty'], 5)
                self.assertFalse(any(w.startswith('event contract:') for w in report['warnings']))
                self.assertEqual(report['final_total'], baseline['final_total'])

    def test_full_report_still_penalizes_missing_in_period_events(self):
        for missing in (0, 20, 40):
            with self.subTest(missing=missing):
                report = self.full_event_report(('2024-12-31', '2026-01-01'), missing)
                self.assertEqual(report['validation']['constraint_penalty'], 7)
                errors = [w for w in report['warnings'] if w.startswith('event contract:')]
                self.assertEqual(len(errors), 1)
                self.assertIn('initial' if missing == 0 else 'missing scheduled', errors[0])

    def test_full_report_cannot_shrink_calendar_to_submitted_sessions(self):
        report = self.full_event_report(('2024-12-31', '2026-01-01'), missing_session=20)
        self.assertFalse(report['validation']['accounting_valid'])
        self.assertTrue(any('calendar' in w for w in report['warnings']))

    def audit(self, result, market):
        with patch.dict(runtime, ALL_ETFS=['A', 'B']):
            return judge['audit_accounting_output'](result, pd.DataFrame(market))

    def test_embedded_public_owner_parity(self):
        for name in ('number', 'equal', 'dated_rows', '_validate', 'validate_ledger'):
            public = ast.parse(inspect.getsource(getattr(ledger_contract, name)))
            installed = ast.parse(inspect.getsource(judge[name]))
            self.assertEqual(ast.dump(public), ast.dump(installed))

    def test_real_scorer_adapter(self):
        result, market = fixture()
        self.assertTrue(self.audit(result, market)['ok'])
        result['daily_nav'][1]['nav'] = 1.01
        self.assertFalse(self.audit(result, market)['ok'])

    def test_main_writes_zero_before_metrics_for_invalid_ledger(self):
        result, market = fixture()
        result.update(metrics={}, risk_calibration={})
        result['trades'][0]['commission'] = 0
        frame = pd.DataFrame(market)
        frame['date'] = pd.to_datetime(frame['date'])
        with tempfile.TemporaryDirectory() as directory:
            import os
            previous = os.getcwd()
            try:
                os.chdir(directory)
                Path('backtest_results.json').write_text(json.dumps(result))
                def forbidden(*args, **kwargs):
                    raise AssertionError('Invalid ledger reached performance calculation')
                with patch.dict(runtime, ALL_ETFS=['A', 'B'], map_platform_files=lambda: None,
                                audit_strategy_code=lambda: (True, [], []),
                                prepare_agent_data=lambda: None, restore_full_data=lambda: None,
                                run_strategy_and_generate_output=lambda: (True, 1, 'synthetic'),
                                load_prices=lambda: frame, calculate_benchmark_nav=forbidden):
                    judge['main']()
                report = json.loads(Path('score_report.json').read_text())
                self.assertEqual(report['final_total'], 0)
                self.assertFalse(report['validation']['accounting_valid'])
                self.assertIn('commission', report['warnings'][0])
            finally:
                os.chdir(previous)

    def test_same_signature_fills_not_duplicate_penalty(self):
        result, market = fixture()
        result['trades'][2]['execution_id'] = 'distinct-same-size'
        metrics = dict(sharpe_ratio=1, max_drawdown=.05, annual_return=.1, annual_turnover=.2)
        frame = pd.DataFrame([dict(r, date=pd.Timestamp(r['date']), low=0, high=1000) for r in market])
        args = (result['daily_nav'], result['daily_weights'], result['trades'], {}, frame,
                list(frame.date.unique()), metrics, metrics)
        with patch.dict(runtime, ALL_ETFS=['A', 'B']):
            before = judge['audit_anti_fraud'](*args)[2]
            result['trades'][2]['execution_id'] = result['trades'][1]['execution_id']
            after = judge['audit_anti_fraud'](*args)[2]
        self.assertEqual(after - before, 10)
        self.assertFalse(self.audit(result, market)['ok'])

    def test_main_reconciles_only_the_authoritative_evaluation_period(self):
        result, market = fixture()
        result.update(metrics={}, risk_calibration={})
        # The scorer restores full prices after the strategy sees a bounded
        # period. Extra historical/future marks must not become required rows.
        full_market = market + [dict(date=day, stock_code=code, close=100)
                                for day in ('2025-01-02', '2025-01-08')
                                for code in ('A', 'B')]
        class ReachedPerformance(Exception):
            pass
        for missing in (None, 0, 1, 2, 'extra'):
            with self.subTest(missing=missing), tempfile.TemporaryDirectory() as directory:
                import os
                previous = os.getcwd()
                try:
                    os.chdir(directory)
                    pd.DataFrame(full_market).to_csv('etf_prices_test.csv', index=False)
                    submitted = deepcopy(result)
                    for field in ('daily_nav', 'daily_weights', 'daily_accounting'):
                        if isinstance(missing, int):
                            submitted[field].pop(missing)
                        elif missing == 'extra':
                            submitted[field].append(dict(submitted[field][-1], date='2025-01-08'))
                    def strategy():
                        visible = pd.read_csv('etf_prices_test.csv')
                        self.assertEqual(sorted(visible.date.unique()),
                                         ['2025-01-03', '2025-01-06', '2025-01-07'])
                        Path('backtest_results.json').write_text(json.dumps(submitted))
                        return True, 1, 'synthetic'
                    def performance(*args, **kwargs):
                        if missing is not None:
                            self.fail('Incomplete/out-of-period ledger reached performance')
                        raise ReachedPerformance()
                    with patch.dict(runtime, ALL_ETFS=['A', 'B'], TEST_START='2025-01-03',
                                    TEST_END='2025-01-07', map_platform_files=lambda: None,
                                    audit_strategy_code=lambda: (True, [], []),
                                    run_strategy_and_generate_output=strategy,
                                    calculate_benchmark_nav=performance):
                        if missing is None:
                            with self.assertRaises(ReachedPerformance):
                                judge['main']()
                        else:
                            judge['main']()
                            report = json.loads(Path('score_report.json').read_text())
                            self.assertFalse(report['validation']['accounting_valid'])
                            self.assertIn('calendar', report['warnings'][0])
                    self.assertEqual(pd.read_csv('etf_prices_test.csv').date.nunique(), 5)
                finally:
                    os.chdir(previous)


if __name__ == '__main__':
    unittest.main()
