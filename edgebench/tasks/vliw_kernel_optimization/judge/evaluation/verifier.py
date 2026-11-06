import json
import random
from pathlib import Path

try:
    from tests.frozen_problem import Machine, Tree, Input, build_mem_image, reference_kernel2, N_CORES
except ModuleNotFoundError:
    from problem import Machine, Tree, Input, build_mem_image, reference_kernel2, N_CORES


def load_cases(path: str | Path) -> dict:
    with open(path, "r") as f:
        return json.load(f)


def run_case(solution_module, case: dict) -> dict:
    random.seed(case["seed"])
    forest = Tree.generate(case["forest_height"])
    inp = Input.generate(forest, case["batch_size"], case["rounds"])
    mem = build_mem_image(forest, inp)

    kb = solution_module.KernelBuilder()
    kb.build_kernel(forest.height, len(forest.values), len(inp.indices), case["rounds"])

    machine = Machine(mem, kb.instrs, kb.debug_info(), n_cores=N_CORES)
    machine.enable_pause = False
    machine.enable_debug = False
    machine.run()

    for ref_mem in reference_kernel2(mem):
        pass

    inp_values_p = ref_mem[6]
    got = machine.mem[inp_values_p : inp_values_p + len(inp.values)]
    expected = ref_mem[inp_values_p : inp_values_p + len(inp.values)]
    correct = got == expected

    return {
        "name": case["name"],
        "kind": case.get("kind", "correctness"),
        "correct": correct,
        "cycles": machine.cycle,
    }


def evaluate_solution(solution_module, case_file: str | Path) -> dict:
    config = load_cases(case_file)
    results = [run_case(solution_module, case) for case in config["cases"]]
    all_correct = all(result["correct"] for result in results)

    performance_cycles = [
        result["cycles"]
        for result in results
        if result["correct"] and result["kind"] == "performance"
    ]
    best_cycles = min(performance_cycles) if performance_cycles else None
    score_cycles = max(performance_cycles) if performance_cycles else None
    thresholds = config.get("thresholds", [])
    passed_thresholds = [
        threshold
        for threshold in thresholds
        if all_correct and score_cycles is not None and score_cycles < threshold
    ]
    score = compute_score(
        all_correct=all_correct,
        score_cycles=score_cycles,
    )

    return {
        "all_correct": all_correct,
        "best_cycles": best_cycles,
        "score_cycles": score_cycles,
        "passed_thresholds": passed_thresholds,
        "score": score,
        "results": results,
    }


def compute_score(
    all_correct: bool,
    score_cycles: int | None,
) -> float | None:
    if not all_correct or score_cycles is None:
        return None
    return float(score_cycles)


def print_report(report: dict) -> None:
    for result in report["results"]:
        status = "PASS" if result["correct"] else "FAIL"
        print(f"{result['name']}: {status}, cycles={result['cycles']}")
    print(f"all_correct={report['all_correct']}")
    print(f"best_cycles={report['best_cycles']}")
    print(f"score_cycles={report['score_cycles']}")
    print(f"passed_thresholds={report['passed_thresholds']}")
    if report["score"] is None:
        print("Score: invalid")
    else:
        print(f"Score: {report['score']:.2f}")
