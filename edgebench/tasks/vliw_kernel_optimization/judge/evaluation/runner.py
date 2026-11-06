import argparse
import importlib.util
import json
from pathlib import Path

from verifier import evaluate_solution, print_report


def import_solution(path: Path):
    spec = importlib.util.spec_from_file_location("solution", path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Unable to import solution from {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--solution", default="solution.py")
    parser.add_argument("--cases", default="test_cases/hidden_cases.json")
    parser.add_argument("--output", default=None)
    args = parser.parse_args()

    try:
        solution_module = import_solution(Path(args.solution))
        report = evaluate_solution(solution_module, args.cases)
    except Exception as exc:
        report = {
            "all_correct": False,
            "best_cycles": None,
            "score_cycles": None,
            "passed_thresholds": [],
            "score": 0.0,
            "results": [],
            "error": repr(exc),
        }
        print(f"Evaluation error: {report['error']}")

    print_report(report)

    if args.output:
        with open(args.output, "w") as f:
            json.dump(report, f, indent=2)

    return 0 if report["all_correct"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
