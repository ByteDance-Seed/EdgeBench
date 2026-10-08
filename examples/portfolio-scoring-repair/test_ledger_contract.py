"""Synthetic contract examples derived from explicit cash flows, not validator output."""
from copy import deepcopy
import unittest
from ledger_contract import validate_ledger


def fixture():
    dates = ['2025-01-03', '2025-01-06', '2025-01-07']
    market = [dict(date=d, stock_code=c, close=p) for d, a in zip(dates, [100, 200, 200])
              for c, p in [('A', a), ('B', 50)]]
    def trade(identity, day, code, side, quantity, price, fee, slip):
        return dict(execution_id=identity, record_type='execution', date=day, stock_code=code,
                    direction=side, qty=quantity, price=price, commission=fee, slippage_cost=slip,
                    open_date=day, close_date=day, open_price=price, close_price=price)
    # Short sale proceeds 500 less 0.25 commission and 0.05 slippage.
    # Two distinct same-sized purchases at Monday close cost 400 + 0.20 + 0.04.
    # Borrow is 500 * 4% * 3/365 across the weekend, then * 1/365 before cover.
    borrow = [0, 60 / 365, 20 / 365]
    cash = [10_000_499.7, 10_000_099.46 - 60 / 365, 9_999_599.16 - 80 / 365]
    equity = [cash[0] - 500, cash[1] - 100, cash[2] + 400]
    shares = [{'A': 0, 'B': -10}, {'A': 2, 'B': -10}, {'A': 2, 'B': 0}]
    result = dict(accounting_contract='portfolio-ledger-v2', initial_capital=10_000_000,
                  trades=[trade('short-1', dates[0], 'B', 'short', 10, 50, .25, .05),
                          trade('buy-1', dates[1], 'A', 'buy', 1, 200, .1, .02),
                          trade('buy-2', dates[1], 'A', 'buy', 1, 200, .1, .02),
                          trade('cover-1', dates[2], 'B', 'cover', 10, 50, .25, .05)],
                  daily_accounting=[dict(date=d, cash=cash[i], equity=equity[i], shares=shares[i],
                                         commission=[.25, .2, .25][i], slippage_cost=[.05, .04, .05][i],
                                         borrow_cost=borrow[i]) for i, d in enumerate(dates)],
                  daily_nav=[dict(date=d, nav=equity[i] / 10_000_000) for i, d in enumerate(dates)],
                  daily_weights=[dict(date=d, weights={'A': [0, 400, 400][i] / equity[i],
                                                       'B': [-500, -500, 0][i] / equity[i]})
                                 for i, d in enumerate(dates)])
    return result, market


class LedgerTests(unittest.TestCase):
    def test_close_timing_weekend_borrow_and_distinct_identical_fills(self):
        result, market = fixture()
        self.assertEqual(validate_ledger(result, market, ['A', 'B'])['validated_sessions'], 3)
        self.assertLess(result['daily_nav'][-1]['nav'], 1)  # No ownership during doubling.

    def test_negative_evidence(self):
        mutations = {
            'missing fee': lambda r: r['trades'][0].pop('commission'),
            'omitted fee': lambda r: r['trades'][0].update(commission=0),
            'double fee': lambda r: r['trades'][0].update(commission=.5),
            'missing slippage': lambda r: r['trades'][0].update(slippage_cost=0),
            'missing borrow': lambda r: r['daily_accounting'][1].update(borrow_cost=0),
            'business-day borrow': lambda r: r['daily_accounting'][1].update(borrow_cost=20/365),
            'duplicate ID': lambda r: r['trades'][2].update(execution_id='buy-1'),
            'omitted execution': lambda r: r['trades'].pop(2),
            'extra execution new ID': lambda r: r['trades'].insert(2, dict(r['trades'][1], execution_id='extra')),
            'middle NAV tamper': lambda r: r['daily_nav'][1].update(nav=1.01),
            'middle cash tamper': lambda r: r['daily_accounting'][1].update(cash=10_000_100),
            'weight tamper': lambda r: r['daily_weights'][1]['weights'].update(A=.5),
            'inventory tamper': lambda r: r['daily_accounting'][1]['shares'].update(A=3),
            'fractional qty': lambda r: r['trades'][0].update(qty=1.5),
            'NaN NAV': lambda r: r['daily_nav'][1].update(nav=float('nan')),
            'infinite price': lambda r: r['trades'][0].update(price=float('inf')),
            'invalid cover': lambda r: r['trades'][0].update(direction='cover'),
            'off-calendar': lambda r: r['trades'][0].update(date='2025-01-04'),
            'missing session': lambda r: r['daily_accounting'].pop(1),
            'duplicate session': lambda r: r['daily_nav'].insert(1, deepcopy(r['daily_nav'][0])),
            'reordered dates': lambda r: r['daily_weights'].reverse(),
            'missing asset': lambda r: r['daily_accounting'][0]['shares'].pop('A'),
            'wrong version': lambda r: r.update(accounting_contract='portfolio-event-v1'),
            'capital changed': lambda r: r.update(initial_capital=100_000),
        }
        for name, mutate in mutations.items():
            with self.subTest(name=name):
                result, market = fixture()
                mutate(result)
                self.assertFalse(validate_ledger(result, market, ['A', 'B'])['ok'])

    def test_cash_only_full_path_cannot_hide_middle_nav(self):
        result, market = fixture()
        result['trades'] = []
        for row, nav, weights in zip(result['daily_accounting'], result['daily_nav'], result['daily_weights']):
            row.update(cash=10_000_000, equity=10_000_000, shares={'A': 0, 'B': 0},
                       commission=0, slippage_cost=0, borrow_cost=0)
            nav['nav'] = 1
            weights['weights'] = {'A': 0, 'B': 0}
        self.assertTrue(validate_ledger(result, market, ['A', 'B'])['ok'])
        result['daily_nav'][1]['nav'] = 1.01
        self.assertFalse(validate_ledger(result, market, ['A', 'B'])['ok'])

    def test_market_input_not_silently_filled_or_overwritten(self):
        result, market = fixture()
        for invalid in (market[:-1], market + market[:1]):
            self.assertFalse(validate_ledger(result, invalid, ['A', 'B'])['ok'])


if __name__ == '__main__':
    unittest.main()
