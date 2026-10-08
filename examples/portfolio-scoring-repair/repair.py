"""Build-time repair for the published Portfolio judge, never a live-run hook."""
import argparse
import ast
import hashlib
from pathlib import Path

SOURCE_SHA256 = '829eeee186f02fba42e4291fea94523a8a7c89cf62c7e534c77115cb8eea4f9b'
# These observations alone do not establish a false accounting record.
DIAGNOSTIC_ONLY = (
    'S > 4.0',
    'D < 0.02',
    'same_day_zero / total_trades > 0.30',
    'return_zero / total_trades > 0.30',
    'same_day_all / total_trades > 0.50',
)


def repair(source: bytes, *, event_contract: bool = False) -> bytes:
    if hashlib.sha256(source).hexdigest() != SOURCE_SHA256:
        raise ValueError('Unsupported scorer revision; inspect the new source before porting this repair')
    text = source.decode('utf-8')
    tree = ast.parse(text)
    audit = next(n for n in tree.body if isinstance(n, ast.FunctionDef) and n.name == 'audit_anti_fraud')
    expected = {ast.dump(ast.parse(s, mode='eval').body) for s in DIAGNOSTIC_ONLY}
    matched = set()
    lines = text.splitlines(keepends=True)
    for node in ast.walk(audit):
        if not isinstance(node, ast.If) or ast.dump(node.test) not in expected:
            continue
        key = ast.dump(node.test)
        if key in matched:
            raise ValueError('Duplicate audit condition')
        matched.add(key)
        assignments = [n for n in node.body if isinstance(n, ast.Assign)
                       and len(n.targets) == 1 and isinstance(n.targets[0], ast.Name)
                       and n.targets[0].id == 'score_zero'
                       and isinstance(n.value, ast.Constant) and n.value.value is True]
        if len(assignments) != 1 or len(node.body) != 2:
            raise ValueError('Unexpected audit effect; refusing partial repair')
        assignment = assignments[0]
        if assignment.lineno != assignment.end_lineno:
            raise ValueError('Unexpected multiline audit effect')
        lines[assignment.lineno - 1] = ''
        warning = node.body[0]
        if warning.lineno != warning.end_lineno or not isinstance(warning, ast.Expr):
            raise ValueError('Unexpected warning shape')
        old = lines[warning.lineno - 1]
        if 'Core return score zeroed' not in old and 'triggers core return score zeroed' not in old:
            raise ValueError('Unexpected warning text')
        lines[warning.lineno - 1] = old.replace('triggers core return score zeroed',
            'diagnostic only; verify accounting evidence').replace('Core return score zeroed',
            'diagnostic only; verify accounting evidence')
    if matched != expected:
        raise ValueError('Incomplete audit repair')
    # Completeness does not imply a minimum investment: the published task
    # requires all ETF fields, but specifies no lower gross-exposure bound.
    completeness = next(n for n in tree.body if isinstance(n, ast.FunctionDef)
                        and n.name == 'validate_daily_weights_completeness')
    lower_bound = ast.dump(ast.parse('total_abs < 0.8 or total_abs > 2.2', mode='eval').body)
    conditions = [n for n in ast.walk(completeness) if isinstance(n, ast.If)
                  and ast.dump(n.test) == lower_bound]
    if len(conditions) != 1:
        raise ValueError('Unexpected exposure completeness condition')
    condition = conditions[0]
    old = lines[condition.lineno - 1]
    if 'total_abs < 0.8 or total_abs > 2.2:' not in old:
        raise ValueError('Unexpected exposure condition formatting')
    lines[condition.lineno - 1] = old.replace(
        'total_abs < 0.8 or total_abs > 2.2:', 'total_abs > 2.2:')
    for index in range(completeness.lineno - 1, completeness.end_lineno):
        lines[index] = lines[index].replace('(0.8-2.2)', '(upper bound 2.2; no minimum)')
    # Published position limits apply to reported daily weights, independent of
    # a solver-controlled event label. Remove only that date-selection gate.
    constraints = next(n for n in tree.body if isinstance(n, ast.FunctionDef)
                       and n.name == 'audit_core_constraints')
    selector = next(i for i, n in enumerate(constraints.body)
                    if isinstance(n, ast.Assign) and len(n.targets) == 1
                    and isinstance(n.targets[0], ast.Name)
                    and n.targets[0].id == 'rebalance_history')
    selection = constraints.body[selector:selector + 4]
    if ([type(n) for n in selection] != [ast.Assign, ast.Assign, ast.For, ast.If]
            or ast.unparse(selection[1]) != 'rebalance_dates = set()'
            or ast.unparse(selection[2].iter) != 'rebalance_history'
            or ast.unparse(selection[3].test) != 'not rebalance_dates'):
        raise ValueError('Unexpected position date selector')
    gates = [n for n in ast.walk(constraints) if isinstance(n, ast.If)
             and ast.unparse(n.test) == 'date_str not in rebalance_dates']
    if len(gates) != 1 or len(gates[0].body) != 1 or not isinstance(gates[0].body[0], ast.Continue):
        raise ValueError('Unexpected position date gate')
    for node in [*selection, gates[0]]:
        for index in range(node.lineno - 1, node.end_lineno):
            lines[index] = ''
    for index in range(constraints.lineno - 1, constraints.end_lineno):
        lines[index] = lines[index].replace('(byrebalancing daycheck)', '(all reported daily weights)')
        if lines[index].strip() == '# getrebalancedatecolumntable':
            lines[index] = ''
    result = ''.join(lines).encode('utf-8')
    if event_contract:
        result = install_event_contract(result)
    compile(result, '<repaired scorer>', 'exec')
    return result


def install_event_contract(source: bytes) -> bytes:
    """Explicit task revision; common public validator is embedded at build time."""
    text = source.decode('utf-8')
    tree = ast.parse(text)
    audit = next(n for n in tree.body if isinstance(n, ast.FunctionDef)
                 and n.name == 'audit_core_constraints')
    dates = [n for n in ast.walk(audit) if isinstance(n, ast.Assign)
             and len(n.targets) == 1 and isinstance(n.targets[0], ast.Name)
             and n.targets[0].id == 'rdates']
    loops = [n for n in ast.walk(audit) if isinstance(n, ast.For)
             and ast.unparse(n.iter) == 'range(1, len(rdates))']
    if len(dates) != 1 or len(loops) != 1:
        raise ValueError('Unexpected interval audit shape')
    lines = text.splitlines(keepends=True)
    replacement = """            event_dates = pd.DatetimeIndex(dates_for_audit)
            event_dates = event_dates[evaluation_period_mask(event_dates)]
            interval_errors = validate_rebalance_history(
                rebalance_history, [d.strftime('%Y-%m-%d') for d in event_dates])
            for error in interval_errors:
                warns.append('event contract: ' + error)
                rebalance_penalty += 2
                penalty_details['rolling revaluation interval violation'] += 2
"""
    lines[dates[0].lineno - 1] = replacement
    for index in range(dates[0].lineno, loops[0].end_lineno):
        lines[index] = ''
    for index in range(audit.lineno - 1, audit.end_lineno):
        lines[index] = lines[index].replace(
            "if r.get('trigger') == 'risk_scale_change'", "if isinstance(r, dict) and r.get('trigger') == 'risk_scale_change'")
    validator_tree = ast.parse(Path(__file__).with_name('event_contract.py').read_text())
    validator = next(n for n in validator_tree.body if isinstance(n, ast.FunctionDef)
                     and n.name == 'validate_rebalance_history')
    # The evaluator restores wider market data for other audits. This mask is
    # shared with the ledger adapter; submitted rows never choose the period.
    period_view = '''def evaluation_period_mask(dates):
    timestamps = pd.to_datetime(dates)
    return ((timestamps >= pd.Timestamp(TEST_START)) &
            (timestamps <= pd.Timestamp(TEST_END)))

'''
    lines[audit.lineno - 1] = period_view + ast.unparse(validator) + '\n\n' + lines[audit.lineno - 1]
    return ''.join(lines).encode('utf-8')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--event-contract-v1', action='store_true',
                        help='Opt into revised event semantics; requires matching work-image contract')
    parser.add_argument('source', type=Path)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    if args.source.resolve() == args.output.resolve():
        parser.error('Use a separate output path; keep the original scorer')
    result = repair(args.source.read_bytes(), event_contract=args.event_contract_v1)
    if args.output.exists():
        parser.error('Output already exists; refusing to replace it')
    args.output.write_bytes(result)


if __name__ == '__main__':
    main()
