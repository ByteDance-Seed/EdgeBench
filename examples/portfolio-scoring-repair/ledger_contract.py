"""Public Portfolio ledger-v2 validator; no evaluator, network or score access."""
import argparse
import csv
from datetime import date
import json
import math

VERSION = 'portfolio-ledger-v2'
INITIAL_CAPITAL = 10_000_000.0
COMMISSION_RATE = 0.0005
SLIPPAGE_RATE = 0.0001
BORROW_RATE = 0.04


class ContractError(ValueError):
    """Malformed or economically inconsistent submitted accounting."""


def number(value, name):
    if isinstance(value, bool) or not isinstance(value, (int, float)) or not math.isfinite(value):
        raise ContractError(f'{name}: finite JSON number required')
    return float(value)


def equal(value, expected, name, tolerance=0.01):
    if abs(number(value, name) - expected) > tolerance:
        raise ContractError(f'{name}: expected {expected:.12g}, got {value!r}')


def dated_rows(rows, calendar, name):
    if not isinstance(rows, list) or any(not isinstance(r, dict) for r in rows):
        raise ContractError(f'{name}: array of objects required')
    if [r.get('date') for r in rows] != calendar:
        raise ContractError(f'{name}: exactly one row per session, in calendar order, required')
    return rows


def _validate(result, market, instruments):
    if not isinstance(result, dict) or result.get('accounting_contract') != VERSION:
        raise ContractError(f'accounting_contract must be {VERSION}')
    equal(result.get('initial_capital'), INITIAL_CAPITAL, 'initial_capital', 0)
    codes = sorted(instruments)
    if not codes or len(codes) != len(set(codes)):
        raise ContractError('market: unique instrument universe required')
    prices = {}
    for row in market:
        day, code = row['date'], row['stock_code']
        if not isinstance(day, str) or date.fromisoformat(day).isoformat() != day:
            raise ContractError('market: canonical ISO date required')
        key = (day, code)
        if key in prices or code not in codes:
            raise ContractError('market: duplicate or unknown instrument')
        price = number(row['close'], 'market close')
        if price <= 0:
            raise ContractError('market close must be positive')
        prices[key] = price
    calendar = sorted({day for day, _ in prices})
    if not calendar or set(prices) != {(day, code) for day in calendar for code in codes}:
        raise ContractError('market: complete session/instrument close grid required')
    ledger = dated_rows(result.get('daily_accounting'), calendar, 'daily_accounting')
    navs = dated_rows(result.get('daily_nav'), calendar, 'daily_nav')
    weights = dated_rows(result.get('daily_weights'), calendar, 'daily_weights')
    trades = result.get('trades')
    if not isinstance(trades, list):
        raise ContractError('trades: array required')
    executions = {day: [] for day in calendar}
    identities, last_day = set(), ''
    for trade in trades:
        if not isinstance(trade, dict):
            raise ContractError('trade: object required')
        identity, day = trade.get('execution_id'), trade.get('date')
        if not isinstance(identity, str) or not identity.strip() or identity in identities:
            raise ContractError('execution_id: nonempty globally unique ID required')
        identities.add(identity)
        if day not in executions or day < last_day:
            raise ContractError('trades: off-calendar date or nonchronological execution')
        last_day = day
        executions[day].append(trade)
    shares = dict.fromkeys(codes, 0)
    cash, previous_day, previous_equity = INITIAL_CAPITAL, None, INITIAL_CAPITAL
    for day, row, nav, weight in zip(calendar, ledger, navs, weights):
        prior_shares = dict(shares)
        days = (date.fromisoformat(day) - date.fromisoformat(previous_day)).days if previous_day else 0
        borrow = (sum(max(-shares[c], 0) * prices[(previous_day, c)] for c in codes)
                  * BORROW_RATE * days / 365) if previous_day else 0.0
        cash -= borrow
        fees = slippage = 0.0
        for trade in executions[day]:
            code, direction, qty = trade.get('stock_code'), trade.get('direction'), trade.get('qty')
            if trade.get('record_type') != 'execution' or code not in shares:
                raise ContractError('trade: execution record and permitted instrument required')
            if isinstance(qty, bool) or not isinstance(qty, int) or qty <= 0:
                raise ContractError('qty: positive integer required')
            holding = shares[code]
            legal = ((direction == 'buy' and holding >= 0)
                     or (direction == 'sell' and holding >= qty)
                     or (direction == 'short' and holding <= 0)
                     or (direction == 'cover' and holding <= -qty))
            if not legal:
                raise ContractError(f'{day}/{code}: invalid {direction} inventory transition')
            price = prices[(day, code)]
            for field in ('price', 'open_price', 'close_price'):
                equal(trade.get(field), price, f'{day}/{code}/{field}', 1e-8)
            if trade.get('open_date') != day or trade.get('close_date') != day:
                raise ContractError('compatibility dates must equal execution date')
            notional = qty * price
            fee, slip = notional * COMMISSION_RATE, notional * SLIPPAGE_RATE
            equal(trade.get('commission'), fee, f'{day}/commission')
            equal(trade.get('slippage_cost'), slip, f'{day}/slippage_cost')
            sign = 1 if direction in ('buy', 'cover') else -1
            cash -= sign * notional + fee + slip
            shares[code] += sign * qty
            fees += fee
            slippage += slip
        equity = cash + sum(shares[c] * prices[(day, c)] for c in codes)
        if equity <= 0 or not math.isfinite(equity):
            raise ContractError(f'{day}: positive finite equity required')
        pnl = sum(prior_shares[c] * (prices[(day, c)] - prices[(previous_day, c)])
                  for c in codes) if previous_day else 0.0
        equal(equity, previous_equity + pnl - borrow - fees - slippage, f'{day}/flow')
        for field, expected in [('cash', cash), ('equity', equity), ('commission', fees),
                                ('slippage_cost', slippage), ('borrow_cost', borrow)]:
            equal(row.get(field), expected, f'{day}/{field}')
        if not isinstance(row.get('shares'), dict) or set(row['shares']) != set(codes):
            raise ContractError(f'{day}/shares: complete instrument universe required')
        if not isinstance(weight.get('weights'), dict) or set(weight['weights']) != set(codes):
            raise ContractError(f'{day}/weights: complete instrument universe required')
        for code in codes:
            equal(row['shares'][code], shares[code], f'{day}/{code}/shares', 0)
            equal(weight['weights'][code], shares[code] * prices[(day, code)] / equity,
                  f'{day}/{code}/weight', 1e-8)
        equal(nav.get('nav'), equity / INITIAL_CAPITAL, f'{day}/nav', 1e-8)
        previous_day, previous_equity = day, equity
    return len(calendar)


def validate_ledger(result, market, instruments):
    """Reconstruct from authoritative closes and executions; reports never drive balances.

    Returns the first actionable error. Local success qualifies supplied public
    data only; it cannot predict hidden-period returns or certify causal strategy use.
    """
    try:
        count = _validate(result, market, instruments)
        return {'ok': True, 'contract': VERSION, 'validated_sessions': count, 'errors': []}
    except (ContractError, KeyError, TypeError, ValueError, OverflowError) as exc:
        return {'ok': False, 'contract': VERSION, 'validated_sessions': 0, 'errors': [str(exc)]}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('result')
    parser.add_argument('prices', help='Public CSV with date, stock_code, close')
    args = parser.parse_args()
    with open(args.result, encoding='utf-8') as source:
        result = json.load(source)
    with open(args.prices, encoding='utf-8-sig') as source:
        market = [dict(row, close=float(row['close'])) for row in csv.DictReader(source)]
    report = validate_ledger(result, market, sorted({row['stock_code'] for row in market}))
    print(json.dumps(report))
    return 0 if report['ok'] else 1


if __name__ == '__main__':
    raise SystemExit(main())
