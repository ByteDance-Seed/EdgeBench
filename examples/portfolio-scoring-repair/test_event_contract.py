"""Public interval contract tests: no market observations or judge imports."""
from datetime import date, timedelta
import unittest
from event_contract import validate_rebalance_history


class EventContractTests(unittest.TestCase):
    def setUp(self):
        # A holiday is absent: elapsed time must use sessions, not calendar days.
        self.dates = [str(date(2025, 1, 1) + timedelta(days=i)) for i in range(90)
                      if (date(2025, 1, 1) + timedelta(days=i)).weekday() < 5
                      and i != 7][:61]

    def events(self, risks=(), count=None):
        count = count if count is not None else len(self.dates)
        return [{'date': self.dates[i], 'trigger': 'initial' if i == 0 else 'scheduled'}
                for i in range(0, count, 20)] + [
                    {'date': self.dates[i], 'trigger': 'risk_scale_change'} for i in risks]

    def test_independent_clocks_and_exact_five_sessions(self):
        for risks in [(), (18,), (10, 15), (18, 23), (20, 25), (1, 60)]:
            self.assertEqual(validate_rebalance_history(self.events(risks), self.dates), [])
        errors = validate_rebalance_history(self.events((18, 22)), self.dates)
        self.assertEqual(len(errors), 1)
        self.assertIn('4 elapsed sessions', errors[0])  # Scheduled 20 cannot reset risk clock.

    def test_empty_short_and_partial_final_periods(self):
        for n in (1, 19, 20, 21, 40, 41, 59, 60, 61):
            self.assertEqual(validate_rebalance_history(self.events(count=n), self.dates[:n]), [])
        self.assertTrue(validate_rebalance_history([], self.dates))
        self.assertTrue(validate_rebalance_history(None, self.dates))
        self.assertTrue(validate_rebalance_history([], []))

    def test_risk_events_cannot_replace_model_updates(self):
        events = self.events((10, 20, 30, 40, 50, 60))
        events = [e for e in events if e['trigger'] != 'scheduled']
        errors = validate_rebalance_history(events, self.dates)
        self.assertEqual(sum('missing scheduled' in e for e in errors), 3)

    def test_invalid_duplicate_and_unknown_records(self):
        mutations = [None, {'date': '2030-01-01', 'trigger': 'scheduled'},
                     {'date': self.dates[18], 'trigger': 'constraint_repair'},
                     {'date': self.dates[18], 'trigger': 'scheduled'},
                     self.events()[0], {'date': self.dates[0], 'trigger': []}]
        for row in mutations:
            self.assertTrue(validate_rebalance_history(self.events() + [row], self.dates))
        for dates in ([*self.dates, self.dates[0]], list(reversed(self.dates)), ['invalid']):
            self.assertTrue(validate_rebalance_history(self.events(), dates))

    def test_event_input_order_does_not_change_contract(self):
        events = self.events((18, 22))
        self.assertEqual(validate_rebalance_history(events, self.dates),
                         validate_rebalance_history(list(reversed(events)), self.dates))


if __name__ == '__main__':
    unittest.main()
