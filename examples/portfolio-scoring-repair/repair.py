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


def repair(source: bytes) -> bytes:
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
    result = ''.join(lines).encode('utf-8')
    compile(result, '<repaired scorer>', 'exec')
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source', type=Path)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    if args.source.resolve() == args.output.resolve():
        parser.error('Use a separate output path; keep the original scorer')
    result = repair(args.source.read_bytes())
    if args.output.exists():
        parser.error('Output already exists; refusing to replace it')
    args.output.write_bytes(result)


if __name__ == '__main__':
    main()
