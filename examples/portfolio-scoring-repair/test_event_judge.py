"""Exercise revised events through the actual patched judge function."""
import ast
import runpy
import sys
import unittest
import pandas as pd
from event_contract import validate_rebalance_history

judge = runpy.run_path(sys.argv.pop(1), run_name='judge_rules')


class JudgeEventTests(unittest.TestCase):
    def setUp(self):
        self.dates = pd.bdate_range('2025-01-02', periods=41)
        self.events = [{'date': str(self.dates[i].date()), 'trigger': 'initial' if i == 0 else 'scheduled'}
                       for i in (0, 20, 40)]

    def penalty(self, events):
        result = judge['audit_core_constraints']([], [], {'rebalance_history': events}, self.dates)
        return result[3]['rolling revaluation interval violation']

    def risk(self, i):
        return {'date': str(self.dates[i].date()), 'trigger': 'risk_scale_change'}

    def test_real_judge_uses_independent_clocks(self):
        self.assertEqual(self.penalty(self.events + [self.risk(18)]), 0)
        self.assertEqual(self.penalty(self.events + [self.risk(18), self.risk(23)]), 0)
        self.assertEqual(self.penalty(self.events + [self.risk(18), self.risk(22)]), 2)
        self.assertEqual(self.penalty([self.events[0], self.risk(20), self.risk(40)]), 4)

    def test_invalid_event_cannot_gain_an_exemption(self):
        self.assertGreater(self.penalty(self.events + [None]), 0)
        self.assertGreater(self.penalty(self.events + [dict(self.risk(18), trigger='constraint_repair')]), 0)
        self.assertGreater(self.penalty(self.events + [self.events[0]]), 0)

    def test_embedded_validator_equals_public_owner(self):
        import inspect
        public = ast.parse(inspect.getsource(validate_rebalance_history)).body[0]
        embedded = ast.parse(inspect.getsource(judge['validate_rebalance_history'])).body[0]
        self.assertEqual(ast.dump(public), ast.dump(embedded))


if __name__ == '__main__':
    unittest.main()
