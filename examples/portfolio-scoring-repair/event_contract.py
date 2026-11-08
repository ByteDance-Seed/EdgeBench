"""Public event-contract validator; uses only supplied dates and event records."""
import argparse
import json
from pathlib import Path


def validate_rebalance_history(history, trading_dates):
    """Return public contract errors; never compute returns, hidden events or scores.

    The evaluation calendar is authoritative. Its first session is initialization;
    scheduled model updates occur at offsets 20, 40, ... independently of trades.
    Additional risk events have their own five-elapsed-session minimum.
    """
    from datetime import date

    def canonical(value):
        return isinstance(value, str) and date.fromisoformat(value).isoformat() == value

    if not isinstance(trading_dates, list) or not trading_dates:
        return ['trading_dates must be a nonempty list']
    try:
        if not all(canonical(d) for d in trading_dates):
            return ['trading_dates must use YYYY-MM-DD']
    except ValueError:
        return ['trading_dates must use valid YYYY-MM-DD dates']
    if trading_dates != sorted(set(trading_dates)):
        return ['trading_dates must be sorted and unique']
    if not isinstance(history, list):
        return ['rebalance_history must be a list']
    positions = {d: i for i, d in enumerate(trading_dates)}
    by_trigger = {'initial': [], 'scheduled': [], 'risk_scale_change': []}
    errors, seen = [], set()
    for row in history:
        if not isinstance(row, dict):
            errors.append('rebalance_history entries must be objects')
            continue
        day, trigger = row.get('date'), row.get('trigger')
        if not isinstance(day, str) or day not in positions:
            errors.append('event date must be in the trading calendar')
            continue
        if not isinstance(trigger, str) or trigger not in by_trigger:
            errors.append('trigger must be initial, scheduled or risk_scale_change; executions belong in trades')
            continue
        identity = (day, trigger)
        if identity in seen:
            errors.append(f'duplicate {trigger} event on {day}')
            continue
        seen.add(identity)
        by_trigger[trigger].append(positions[day])
    if by_trigger['initial'] != [0]:
        errors.append('one initial model event is required at the first trading session')
    expected = set(range(20, len(trading_dates), 20))
    actual = set(by_trigger['scheduled'])
    for i in sorted(expected - actual):
        errors.append(f'missing scheduled model update on {trading_dates[i]}')
    for i in sorted(actual - expected):
        errors.append(f'off-calendar scheduled model update on {trading_dates[i]}')
    risk = sorted(by_trigger['risk_scale_change'])
    for left, right in zip(risk, risk[1:]):
        if right - left < 5:
            errors.append(f'additional risk events are only {right - left} elapsed sessions apart: '
                          f'{trading_dates[left]} -> {trading_dates[right]}')
    return errors


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('results', type=Path, help='Public/local backtest_results.json')
    parser.add_argument('calendar', type=Path, help='JSON array of public trading dates, sorted and unique')
    args = parser.parse_args()
    payload = json.loads(args.results.read_text())
    risk = payload.get('risk_calibration') if isinstance(payload, dict) else None
    errors = validate_rebalance_history(
        risk.get('rebalance_history') if isinstance(risk, dict) else None,
        json.loads(args.calendar.read_text()),
    )
    print(json.dumps({'valid': not errors, 'errors': errors}, indent=2))
    raise SystemExit(bool(errors))


if __name__ == '__main__':
    main()
