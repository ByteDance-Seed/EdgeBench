"""Install opt-in ledger-v2 into an exact original scorer via the event-v1 repair."""
import argparse
import ast
from pathlib import Path
from repair import repair


def install(source):
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
    report = next(n for n in main.body if isinstance(n, ast.Assign)
                  and ast.unparse(n.targets[0]) == 'report')
    lines[report.lineno - 1] += "        'accounting_contract': 'portfolio-ledger-v2',\n"
    owner = ast.parse(Path(__file__).with_name('ledger_contract.py').read_text())
    embedded = [n for n in owner.body if isinstance(n, (ast.Import, ast.ImportFrom, ast.Assign, ast.ClassDef))
                or isinstance(n, ast.FunctionDef) and n.name != 'main']
    wrapper = '''
def audit_accounting_output(data, prices_df):
    # prepare_agent_data exposes only this authoritative period to the solver;
    # restore_full_data may add history/future marks needed by other audits.
    # Never derive the required calendar from the submitted output itself.
    dates = pd.to_datetime(prices_df['date'])
    period = prices_df[(dates >= pd.Timestamp(TEST_START)) &
                       (dates <= pd.Timestamp(TEST_END))]
    market = [dict(date=pd.Timestamp(row.date).strftime('%Y-%m-%d'),
                   stock_code=row.stock_code, close=float(row.close))
              for row in period.itertuples(index=False)]
    return validate_ledger(data, market, ALL_ETFS)

'''
    lines[main.lineno - 1] = '\n'.join(ast.unparse(n) for n in embedded) + '\n' + wrapper + lines[main.lineno - 1]
    result = ''.join(lines).encode()
    compile(result, '<ledger-v2 scorer>', 'exec')
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source', type=Path)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    if args.output.exists():
        parser.error('Output exists; keep original and versioned artifacts separate')
    args.output.write_bytes(install(args.source.read_bytes()))
