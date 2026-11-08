"""Synthetic performance-contract tests against the real judge function.

Copyright 2026 The SForge Authors
SPDX-License-Identifier: Apache-2.0
"""
import ast
from pathlib import Path
import sys
import unittest
import numpy as np
import pandas as pd
from ledger_repair import install

original, before, after = (Path(p).read_bytes() for p in sys.argv[1:4])
del sys.argv[1:4]


def extract(source):
    tree = ast.parse(source)
    fn = next(n for n in tree.body if isinstance(n, ast.FunctionDef)
              and n.name == 'calculate_metrics_from_data')
    namespace = dict(np=np, pd=pd, TEST_START='2025-01-01')
    exec(compile(ast.Module(body=[fn], type_ignores=[]), '<judge-metrics>', 'exec'), namespace)
    return namespace[fn.name]


old, repaired = extract(before), extract(after)


def evaluate(fn, nav, benchmark, weights=None):
    dates = pd.bdate_range('2025-01-01', periods=len(nav))
    daily_nav = [dict(date=str(d.date()), nav=float(v)) for d, v in zip(dates, nav)]
    daily_weights = [] if weights is None else [
        dict(date=str(d.date()), weights=dict(A=float(v))) for d, v in zip(dates, weights)]
    result, error = fn(daily_nav, daily_weights, pd.Series(benchmark, index=dates))
    if error:
        raise AssertionError(error)
    return result


class ReturnBasisTests(unittest.TestCase):
    def test_first_session_cost_survives_flat_subsequent_nav(self):
        nav = [.9994] * 252
        result = evaluate(repaired, nav, [1.] * 252)
        self.assertEqual(result['trading_days'], 252)
        for name in ('total_return', 'annual_return', 'max_drawdown', 'excess_return_annual'):
            self.assertEqual(result[name], -.0006, name)
        self.assertEqual(evaluate(old, nav, [1.] * 252)['excess_return_annual'], 0)
        self.assertLess(result['sharpe_ratio'], 0)

    def test_separately_annualized_wealth_difference(self):
        result = evaluate(repaired, np.linspace(.9994, 1.1, 126), np.linspace(1., 1.3, 126))
        # Half-year wealth multipliers, each squared; do not square their difference.
        self.assertEqual(result['annual_return'], .21)
        self.assertEqual(result['benchmark_annual_return'], .69)
        self.assertEqual(result['excess_return_annual'], -.48)

    def test_large_underperformance_remains_real_valued(self):
        result = evaluate(repaired, np.linspace(1., .5, 243), np.linspace(1., 2., 243))
        expected = .5 ** (252 / 243) - 2. ** (252 / 243)
        self.assertAlmostEqual(result['excess_return_annual'], expected, places=4)
        self.assertTrue(all(np.isfinite(v) for v in result.values()))

    def test_same_paths_have_zero_relative_metrics(self):
        nav = [1., .99, 1.02, 1.01, 1.03]
        result = evaluate(repaired, nav, nav)
        for name in ('excess_return_annual', 'information_ratio', 'sortino_ratio'):
            self.assertEqual(result[name], 0)

    def test_sharpe_and_information_ratio_use_all_session_returns(self):
        nav = [.9994, 1.002, .997, 1.008]
        benchmark = [1., 1.001, .998, 1.003]
        result = evaluate(repaired, nav, benchmark)
        returns = np.array([nav[0] - 1.] + [nav[i] / nav[i - 1] - 1 for i in range(1, 4)])
        bench_returns = np.array([0.] + [benchmark[i] / benchmark[i - 1] - 1 for i in range(1, 4)])
        sharpe = returns.mean() / returns.std(ddof=1) * np.sqrt(252)
        excess = nav[-1] ** 63 - benchmark[-1] ** 63
        ir = excess / ((returns - bench_returns).std(ddof=1) * np.sqrt(252))
        self.assertAlmostEqual(result['sharpe_ratio'], sharpe, places=4)
        self.assertAlmostEqual(result['information_ratio'], ir, places=4)

    def test_initial_capital_remains_running_peak_until_recovery(self):
        result = evaluate(repaired, [.99, .98, 1.01, .99], [1.] * 4)
        self.assertEqual(result['max_drawdown'], -.02)

    def test_turnover_keeps_weight_change_definition_and_half_year_floor(self):
        weights = [0., .5] + [.5] * 250
        result = evaluate(repaired, [1.] * 252, [1.] * 252, weights)
        self.assertEqual(result['annual_turnover'], .25)
        short = evaluate(repaired, [1.] * 4, [1.] * 4, [0., .5, .5, .5])
        self.assertEqual(short['annual_turnover'], .5)

    def test_flat_wealth_is_finite_zero(self):
        result = evaluate(repaired, [1.] * 4, [1.] * 4)
        self.assertEqual(result.pop('trading_days'), 4)
        self.assertTrue(all(v == 0 for v in result.values()))

    def test_default_off_parity_and_composable_timing(self):
        self.assertEqual(install(original), before)
        self.assertEqual(install(original, return_basis=False), before)
        self.assertEqual(install(original, return_basis=True), after)
        combined = install(original, var_timing=True, return_basis=True)
        # Both feature combinations expose the same real metric function.
        sample = ([.9994, 1.01, .99, 1.02], [1., 1.01, 1., 1.01])
        self.assertEqual(evaluate(extract(combined), *sample), evaluate(repaired, *sample))

    def test_scope_excludes_score_thresholds_risk_and_audits(self):
        left, right = ast.parse(before), ast.parse(after)
        changes = []
        for a, b in zip(left.body, right.body):
            if ast.dump(a) != ast.dump(b):
                changes.append(getattr(a, 'name', type(a).__name__))
        self.assertEqual(len(left.body), len(right.body))
        self.assertEqual(changes, ['calculate_metrics_from_data', 'main'])
        main = next(n for n in right.body if isinstance(n, ast.FunctionDef) and n.name == 'main')
        markers = 0
        for node in ast.walk(main):
            if isinstance(node, ast.Dict):
                for i in reversed(range(len(node.keys))):
                    if isinstance(node.keys[i], ast.Constant) and node.keys[i].value == 'return_basis_contract':
                        self.assertEqual(node.values[i].value, 'portfolio-return-basis-v1')
                        del node.keys[i], node.values[i]
                        markers += 1
        self.assertEqual(markers, 1)
        previous = next(n for n in left.body if isinstance(n, ast.FunctionDef) and n.name == 'main')
        self.assertEqual(ast.dump(main), ast.dump(previous))

    def test_source_drift_and_reapplication_rejected(self):
        for source in (original + b'\n', after):
            with self.assertRaises(ValueError):
                install(source, return_basis=True)


if __name__ == '__main__':
    unittest.main()
