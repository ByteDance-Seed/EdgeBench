"""Synthetic causal tests against the actual nested judge function, without data access."""
import ast
from copy import deepcopy
from pathlib import Path
import sys
import unittest
import numpy as np
import pandas as pd
from scipy import stats
from ledger_repair import install

original, before, after = (Path(p).read_bytes() for p in sys.argv[1:4])
del sys.argv[1:4]


def extract(source):
    tree = ast.parse(source)
    main = next(n for n in tree.body if isinstance(n, ast.FunctionDef) and n.name == 'main')
    fn = next(n for n in main.body if isinstance(n, ast.FunctionDef)
              and n.name == 'calculate_independent_var_break_rate')
    namespace = dict(np=np, pd=pd, stats=stats, ALL_ETFS=['RISK', 'STABLE'], N_ASSETS=2)
    exec(compile(ast.Module(body=[fn], type_ignores=[]), '<judge-var>', 'exec'), namespace)
    return namespace[fn.name]


old, repaired = extract(before), extract(after)


def fixture(days=100):
    rng = np.random.default_rng(928)
    dates = pd.bdate_range('2025-01-01', periods=days)
    returns = rng.normal(size=(days, 2)) * [0.02, 0.001]
    prices = 100 * np.cumprod(1 + returns, axis=0)
    market = pd.DataFrame([dict(date=d, stock_code=code, close=prices[i, j])
                           for i, d in enumerate(dates)
                           for j, code in enumerate(['RISK', 'STABLE'])])
    nav = [dict(date=str(d.date()), nav=100. if i < days - 1 else 99.5)
           for i, d in enumerate(dates)]
    weights = [dict(date=str(d.date()), weights=dict(RISK=1., STABLE=0.)) for d in dates]
    return nav, weights, market


class VarTimingTests(unittest.TestCase):
    def test_post_close_rotation_cannot_rewrite_realized_interval_risk(self):
        nav, weights, market = fixture()
        rotated = deepcopy(weights)
        rotated[-1]['weights'] = dict(RISK=0., STABLE=1.)
        # This is the regression: current-close holdings can cross the 1% veto.
        self.assertEqual(old(nav, weights, market), 0.)
        self.assertGreaterEqual(old(nav, rotated, market), .01)
        self.assertEqual(repaired(nav, weights, market), repaired(nav, rotated, market))

    def test_previous_session_position_does_change_the_forecast(self):
        nav, weights, market = fixture()
        weights[-2]['weights'] = dict(RISK=0., STABLE=1.)
        self.assertEqual(repaired(nav, weights, market), round(1 / 99, 4))
        # Moving the same rotation to the loss day's close is too late.
        weights[-2]['weights'] = dict(RISK=1., STABLE=0.)
        weights[-1]['weights'] = dict(RISK=0., STABLE=1.)
        self.assertEqual(repaired(nav, weights, market), 0.)

    def test_current_and_future_prices_do_not_enter_forecast(self):
        nav, weights, market = fixture()
        changed = market.copy()
        last = changed.date.max()
        changed.loc[changed.date == last, 'close'] *= 10
        future = changed[changed.date == last].copy()
        future['date'] = last + pd.offsets.BDay(1)
        future['close'] *= 100
        changed = pd.concat([changed, future], ignore_index=True)
        self.assertEqual(repaired(nav, weights, market), repaired(nav, weights, changed))

    def test_first_covariance_session_uses_prior_trading_session(self):
        nav, weights, market = fixture(61)
        weights[-2]['weights'] = dict(RISK=0., STABLE=1.)
        self.assertEqual(repaired(nav, weights, market), round(1 / 60, 4))

    def test_unchanged_positions_preserve_existing_result(self):
        nav, weights, market = fixture()
        for w in weights:
            w['weights'] = dict(RISK=.5, STABLE=.5)
        self.assertEqual(old(nav, weights, market), repaired(nav, weights, market))

    def test_fallback_and_short_history_parity(self):
        for days in (1, 19, 20, 60):
            nav, weights, market = fixture(days)
            nav[-1]['nav'] = 97.
            self.assertEqual(old(nav, weights, market), repaired(nav, weights, market))

    def test_zero_exposure_is_finite_and_retains_loss_detection(self):
        nav, weights, market = fixture()
        for w in weights:
            w['weights'] = dict(RISK=0., STABLE=0.)
        # Net costs still count as losses under the unchanged net-NAV rule.
        self.assertEqual(repaired(nav, weights, market), round(1 / 99, 4))

    def test_default_off_is_byte_identical(self):
        self.assertEqual(install(original), before)
        self.assertEqual(install(original, var_timing=False), before)
        self.assertEqual(install(original, var_timing=True), after)

    def test_only_weight_selection_and_report_marker_change(self):
        tree = ast.parse(after)
        changed = 0
        fn = next(n for n in ast.walk(tree) if isinstance(n, ast.FunctionDef)
                  and n.name == 'calculate_independent_var_break_rate')
        for n in ast.walk(fn):
            if isinstance(n, ast.Assign) and ast.unparse(n.targets[0]) == 'w_vec':
                self.assertEqual(ast.unparse(n.value), 'weights_df.iloc[i - 1].values')
                n.value = ast.parse('weights_df.loc[date].values', mode='eval').body
                changed += 1
        for n in ast.walk(tree):
            if isinstance(n, ast.Dict):
                for i, key in reversed(list(enumerate(n.keys))):
                    if isinstance(key, ast.Constant) and key.value == 'risk_timing_contract':
                        self.assertEqual(n.values[i].value, 'portfolio-var-timing-v1')
                        del n.keys[i], n.values[i]
                        changed += 1
        self.assertEqual(changed, 2)
        self.assertEqual(ast.dump(tree), ast.dump(ast.parse(before)))

    def test_unknown_source_and_reapplication_rejected(self):
        for source in (original + b'\n', after):
            with self.assertRaises(ValueError):
                install(source, var_timing=True)


if __name__ == '__main__':
    unittest.main()
