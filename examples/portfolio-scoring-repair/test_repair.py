"""Synthetic rule characterization against the real image module, without test data."""
import ast
import importlib.util
from pathlib import Path
import runpy
import sys
import unittest

import pandas as pd

ORIGINAL, REPAIRED = map(Path, sys.argv[1:3])
del sys.argv[1:3]
original = runpy.run_path(str(ORIGINAL), run_name='original_rules')
repaired = runpy.run_path(str(REPAIRED), run_name='repaired_rules')
spec = importlib.util.spec_from_file_location('repair', '/tmp/portfolio-repair.py')
repair_module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(repair_module)


def audit(module, *, metrics=None, trades=None):
    dates = ['2025-01-02', '2025-01-03', '2025-01-06', '2025-01-07']
    prices = pd.DataFrame([dict(date=pd.Timestamp(d), stock_code='510300.XSHG', low=9., high=11.) for d in dates])
    nav = [dict(date=d, nav=v) for d, v in zip(dates, [1., 1.01, 1.005, 1.02])]
    weights = [dict(date=d, weights={'510300.XSHG': -.1-i*.01}) for i, d in enumerate(dates)]
    values = dict(sharpe_ratio=3., max_drawdown=-.03, annual_return=.1,
                  annual_turnover=1., agent_var_break_rate=.05, independent_var_break_rate=.05)
    values.update(metrics or {})
    trade = dict(stock_code='510300.XSHG', open_date=dates[0], close_date=dates[2],
                 open_price=10., close_price=10., qty=100, direction='short')
    return module['audit_anti_fraud'](nav, weights, [trade] if trades is None else trades,
        {}, prices, dates, dict(values, var_break_rate=values['agent_var_break_rate']), values)


def trade(**changes):
    return dict(dict(stock_code='510300.XSHG', open_date='2025-01-02', close_date='2025-01-06',
                     open_price=10., close_price=10., qty=100, direction='short'), **changes)


class RepairTests(unittest.TestCase):
    def test_published_objective_boundaries(self):
        for metrics in ({'sharpe_ratio':4.01}, {'max_drawdown':-.019}):
            with self.subTest(metrics=metrics):
                self.assertTrue(audit(original, metrics=metrics)[0])
                zero, warnings, penalty = audit(repaired, metrics=metrics)
                self.assertFalse(zero)
                self.assertEqual(penalty, 0)
                self.assertTrue(any('diagnostic only' in w for w in warnings))
        self.assertEqual(repaired['score_sharpe'](4.01), 30.)
        self.assertEqual(repaired['score_drawdown'](-.019), 15.)

    def test_bookkeeping_records_are_not_fraud_proof(self):
        for t in (trade(close_date='2025-01-02', record_type='execution'),
                  trade(**{'return':0.}), trade(close_date='2025-01-02', **{'return':0.})):
            with self.subTest(trade=t):
                self.assertTrue(audit(original, trades=[t])[0])
                self.assertFalse(audit(repaired, trades=[t])[0])

    def test_ordinary_control_unchanged(self):
        self.assertEqual(audit(original), audit(repaired))
        for metrics in ({'sharpe_ratio':4.}, {'max_drawdown':-.02}):
            self.assertEqual(audit(original, metrics=metrics), audit(repaired, metrics=metrics))

    def test_actual_price_and_time_failures_still_count(self):
        # Enough out-of-range prices retain the existing core-score veto.
        bad = [trade(open_price=20., close_price=20., qty=i+1) for i in range(6)]
        before, after = audit(original, trades=bad), audit(repaired, trades=bad)
        self.assertEqual(before, after)
        self.assertTrue(after[0])
        self.assertGreaterEqual(after[2], 50)
        bad = [trade(open_date='2024-12-31')]
        self.assertEqual(audit(original, trades=bad), audit(repaired, trades=bad))
        self.assertGreater(audit(repaired, trades=bad)[2], 0)

    def test_unrelated_effects_and_source_are_preserved(self):
        before = ast.parse(ORIGINAL.read_text())
        after = ast.parse(REPAIRED.read_text())
        # Surrounding program remains identical, including NAV reconstruction,
        # metrics, scoring aggregation and execution. The targeted constraint
        # function has a separate structural equality assertion below.
        for tree in (before, after):
            tree.body = [n for n in tree.body if not (isinstance(n, ast.FunctionDef)
                         and n.name in {'audit_anti_fraud', 'validate_daily_weights_completeness', 'audit_core_constraints'})]
        self.assertEqual(ast.dump(before), ast.dump(after))
        self.assertEqual(audit(original, metrics={'agent_var_break_rate':.2}),
                         audit(repaired, metrics={'agent_var_break_rate':.2}))

    def test_complete_low_exposure_is_not_missing_data(self):
        dates = ['2025-01-02', '2025-01-03']
        nav = [dict(date=d, nav=1.) for d in dates]
        for gross in (0., .7, .799, .8, 1., 2.2, 2.3):
            with self.subTest(gross=gross):
                weights = {etf: 0. for etf in repaired['ALL_ETFS']}
                weights[next(iter(weights))] = gross
                records = [dict(date=d, weights=weights) for d in dates]
                before = original['validate_daily_weights_completeness'](records, nav)
                after = repaired['validate_daily_weights_completeness'](records, nav)
                if gross < .8:
                    self.assertEqual(before[2], 2)
                    self.assertEqual(after, (0, [], 0))
                    self.assertEqual(repaired['calculate_weights_penalty'](after[2], 2), 0)
                else:
                    self.assertEqual(before, after)

    def test_missing_fields_dates_and_unknown_assets_are_not_exempt(self):
        weights = {etf: .07 for etf in repaired['ALL_ETFS']}
        nav = [dict(date='2025-01-02', nav=1.)]
        missing = dict(weights)
        missing.pop(next(iter(missing)))
        for records in ([dict(date='2025-01-02', weights=missing)],
                        [dict(date='2025-01-02', weights=dict(weights, UNKNOWN=.01))], []):
            with self.subTest(records=records):
                before = original['validate_daily_weights_completeness'](records, nav)
                after = repaired['validate_daily_weights_completeness'](records, nav)
                self.assertEqual(before, after)
                self.assertGreater(after[0], 0)

    def test_position_audit_is_independent_of_event_labels_and_omission(self):
        dates = pd.bdate_range('2025-01-02', periods=41)
        def check(module, trigger, weights):
            records = [dict(date=str(dates[0].date()), weights=dict.fromkeys(module['ALL_ETFS'], 0.)),
                       dict(date=str(dates[18].date()), weights=weights)]
            events = [dict(date=str(dates[0].date()), trigger='initial'),
                      dict(date=str(dates[40].date()), trigger='risk_scale_change')]
            if trigger is not None:
                events.insert(1, dict(date=str(dates[18].date()), trigger=trigger))
            return module['audit_core_constraints'](records, [], {'rebalance_history': events}, dates)[3]
        # The same violations must survive removal, unknown labels and claims of
        # constraint repair. This does not exempt those events from interval rules.
        for weights in (dict.fromkeys(repaired['ALL_ETFS'], .25),
                        dict.fromkeys(repaired['ALL_ETFS'], -.30)):
            reference = check(original, 'scheduled', weights)
            keys = [k for k in reference if k not in {
                'rolling revaluation interval violation', 'risk_scale_change not triggered'}]
            for trigger in ('scheduled', 'constraint_repair', 'unrecognized', None):
                with self.subTest(weights=weights, trigger=trigger):
                    result = check(repaired, trigger, weights)
                    self.assertEqual({k: reference[k] for k in keys}, {k: result[k] for k in keys})
                    self.assertGreater(result['total leverage exceeds 2.0'], 0)
        self.assertEqual(check(repaired, None, dict.fromkeys(repaired['ALL_ETFS'], 0.))[
            'total leverage exceeds 2.0'], 0)

    def test_position_repair_preserves_interval_rules_and_penalty_arithmetic(self):
        before = next(n for n in ast.parse(ORIGINAL.read_text()).body
                      if isinstance(n, ast.FunctionDef) and n.name == 'audit_core_constraints')
        after = next(n for n in ast.parse(REPAIRED.read_text()).body
                     if isinstance(n, ast.FunctionDef) and n.name == 'audit_core_constraints')
        # Independently delimit the original label-dependent selection; every
        # subsequent constraint equation, counter, cap and interval rule is equal.
        first = next(i for i, n in enumerate(before.body)
                     if isinstance(n, ast.Assign) and ast.unparse(n.targets[0]) == 'rebalance_history')
        del before.body[first:first + 4]
        for node in ast.walk(before):
            if isinstance(node, ast.For) and ast.unparse(node.iter) == 'daily_weights':
                node.body = [n for n in node.body if not (isinstance(n, ast.If)
                             and ast.unparse(n.test) == 'date_str not in rebalance_dates')]
        before.body[0] = after.body[0]  # The changed docstring states daily scope.
        self.assertEqual(ast.dump(before), ast.dump(after))

    def test_unknown_source_and_repeated_patch_fail_closed(self):
        self.assertEqual(repair_module.repair(ORIGINAL.read_bytes()), REPAIRED.read_bytes())
        for data in (ORIGINAL.read_bytes()+b'\n', REPAIRED.read_bytes(), b''):
            with self.assertRaises(ValueError):
                repair_module.repair(data)


if __name__ == '__main__':
    unittest.main()
