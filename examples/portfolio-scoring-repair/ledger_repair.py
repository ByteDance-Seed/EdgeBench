"""Install opt-in ledger-v2 into an exact original scorer via the event-v1 repair."""
import argparse
import ast
from pathlib import Path
from repair import repair


def install_return_basis(text):
    """Version only the performance metric time basis, not score thresholds."""
    tree = ast.parse(text)
    fn = next(n for n in tree.body if isinstance(n, ast.FunctionDef)
              and n.name == 'calculate_metrics_from_data')
    replacements = {
        'r': ('s.pct_change().dropna()', 's.div(s.shift(1).fillna(1.0)).sub(1.0)'),
        'cummax': ('s.cummax()', 's.cummax().clip(lower=1.0)'),
        'bench_total': ('bench_aligned.iloc[-1] / bench_aligned.iloc[0] - 1',
                        'bench_aligned.iloc[-1] - 1.0'),
        'agent_total': ('agent_aligned.iloc[-1] / agent_aligned.iloc[0] - 1',
                        'agent_aligned.iloc[-1] - 1.0'),
        'excess_annual': ('(1 + excess_total) ** (252 / len(common_idx)) - 1',
                          '(1 + agent_total) ** (252 / len(common_idx)) - '
                          '(1 + bench_total) ** (252 / len(common_idx))'),
        'agent_daily_ret': ('agent_aligned.pct_change().dropna()',
                            'agent_aligned.div(agent_aligned.shift(1).fillna(1.0)).sub(1.0)'),
        'bench_daily_ret': ('bench_aligned.pct_change().dropna()',
                            'bench_aligned.div(bench_aligned.shift(1).fillna(1.0)).sub(1.0)'),
    }
    lines = text.splitlines(keepends=True)
    matched = set()
    for node in ast.walk(fn):
        if not isinstance(node, ast.Assign):
            continue
        target = ast.unparse(node.targets[0])
        if target not in replacements:
            continue
        before, after = replacements[target]
        if ast.dump(node.value) != ast.dump(ast.parse(before, mode='eval').body):
            continue  # e.g. the separate zero-value initialization
        if target in matched or node.end_lineno != node.lineno:
            raise ValueError('Unexpected repeated/multiline metric assignment')
        indent = ' ' * node.col_offset
        lines[node.lineno - 1] = f'{indent}{target} = {after}\n'
        matched.add(target)
    if matched != set(replacements):
        raise ValueError('Unexpected performance metric source')
    return ''.join(lines)


def install(source, *, var_timing=False, return_basis=False):
    text = repair(source, event_contract=True).decode()
    tree = ast.parse(text)
    functions = {n.name: n for n in tree.body if isinstance(n, ast.FunctionDef)}
    main = functions['main']
    lines = text.splitlines(keepends=True)
    # Gate before any score is derived from submitted balances. An invalid ledger
    # is a zero-score task result, not an inferred fraud verdict or infra failure.
    anchor = next(n for n in main.body if isinstance(n, ast.Assign)
                  and ast.unparse(n.targets[0]) == 'benchmark_nav')
    lines[anchor.lineno - 1] = '''    accounting = audit_accounting_output(data, prices_df)
    if not accounting['ok']:
        report = {'final_total': 0, 'perf_score': 0,
                  'validation': {'accounting_valid': False},
                  'accounting_contract': 'portfolio-ledger-v2',
                  'warnings': ['ledger-v2: ' + error for error in accounting['errors']]}
        with open('score_report.json', 'w', encoding='utf-8') as output:
            json.dump(report, output, indent=2)
        print('Final total score: 0')
        print(json.dumps(report))
        return
''' + lines[anchor.lineno - 1]
    # Full-path reconciliation supersedes approximate same-day weights/returns
    # and normalization-to-first-close checks. Do not keep contradictory audits.
    replacements = {
        'nav_rebuild_ok, nav_rebuild_msg, _': "True, 'ledger-v2 full daily reconciliation passed', None",
        'nav_internal_ok, nav_internal_msg': "True, 'ledger-v2 fixed initial capital verified'",
        'mismatch_count, mismatch_warns': '0, []',
    }
    matched = set()
    for node in main.body:
        if isinstance(node, ast.Assign):
            target = ast.unparse(node.targets[0]).strip('()')
            if target in replacements:
                matched.add(target)
                lines[node.lineno - 1] = f'    {target} = {replacements[target]}\n'
                for i in range(node.lineno, node.end_lineno):
                    lines[i] = ''
    if matched != set(replacements):
        raise ValueError('Unexpected accounting call sites')
    # Signature equality cannot distinguish multiple legitimate same-size fills.
    # All main-path executions are already reconciled; identity remains enforced.
    anti = functions['audit_anti_fraud']
    sig = [n for n in ast.walk(anti) if isinstance(n, ast.Assign)
           and ast.unparse(n.targets[0]) == 'sig']
    if len(sig) != 1:
        raise ValueError('Unexpected duplicate audit')
    lines[sig[0].lineno - 1] = "        sig = t.get('execution_id')\n"
    for i in range(sig[0].lineno, sig[0].end_lineno):
        lines[i] = ''
    if var_timing:
        # Ledger-v2 requires one chronological weight row per market session.
        # A close fill at t cannot forecast the return earned before that fill.
        var_fn = next(n for n in main.body if isinstance(n, ast.FunctionDef)
                      and n.name == 'calculate_independent_var_break_rate')
        weights = [n for n in ast.walk(var_fn) if isinstance(n, ast.Assign)
                   and ast.unparse(n.targets[0]) == 'w_vec']
        if len(weights) != 1 or ast.unparse(weights[0].value) != 'weights_df.loc[date].values':
            raise ValueError('Unexpected independent VaR weight selection')
        node = weights[0]
        lines[node.lineno - 1] = '            w_vec = weights_df.iloc[i - 1].values\n'
        for i in range(node.lineno, node.end_lineno):
            lines[i] = ''
    report = next(n for n in main.body if isinstance(n, ast.Assign)
                  and ast.unparse(n.targets[0]) == 'report')
    lines[report.lineno - 1] += "        'accounting_contract': 'portfolio-ledger-v2',\n"
    if return_basis:
        lines[report.lineno - 1] += "        'return_basis_contract': 'portfolio-return-basis-v1',\n"
    if var_timing:
        lines[report.lineno - 1] += "        'risk_timing_contract': 'portfolio-var-timing-v1',\n"
    owner = ast.parse(Path(__file__).with_name('ledger_contract.py').read_text())
    embedded = [n for n in owner.body if isinstance(n, (ast.Import, ast.ImportFrom, ast.Assign, ast.ClassDef))
                or isinstance(n, ast.FunctionDef) and n.name != 'main']
    wrapper = '''
def audit_accounting_output(data, prices_df):
    # prepare_agent_data exposes only this authoritative period to the solver;
    # restore_full_data may add history/future marks needed by other audits.
    # Never derive the required calendar from the submitted output itself.
    period = prices_df[evaluation_period_mask(prices_df['date'])]
    market = [dict(date=pd.Timestamp(row.date).strftime('%Y-%m-%d'),
                   stock_code=row.stock_code, close=float(row.close))
              for row in period.itertuples(index=False)]
    return validate_ledger(data, market, ALL_ETFS)

'''
    lines[main.lineno - 1] = '\n'.join(ast.unparse(n) for n in embedded) + '\n' + wrapper + lines[main.lineno - 1]
    result_text = ''.join(lines)
    if return_basis:
        result_text = install_return_basis(result_text)
    result = result_text.encode()
    compile(result, '<ledger-v2 scorer>', 'exec')
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--var-timing-v1', action='store_true')
    parser.add_argument('--return-basis-v1', action='store_true')
    parser.add_argument('source', type=Path)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    if args.output.exists():
        parser.error('Output exists; keep original and versioned artifacts separate')
    args.output.write_bytes(install(
        args.source.read_bytes(), var_timing=args.var_timing_v1,
        return_basis=args.return_basis_v1))
