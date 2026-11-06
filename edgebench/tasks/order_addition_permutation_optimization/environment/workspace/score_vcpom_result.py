from __future__ import annotations

from pathlib import Path
from typing import Dict, List


def parse_result_file(file_path: str | Path) -> Dict[str, float | int | List[int]]:
    """Parse a result file.

    `final_pai` is optional so the public baseline can expose only cost/num
    without leaking the reference permutation.
    """
    path = Path(file_path)
    lines = [line.strip() for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]

    data: Dict[str, str] = {}
    for line in lines:
        if "=" in line:
            k, v = line.split("=", 1)
            data[k.strip()] = v.strip()

    if "final_cost" in data:
        cost = float(data["final_cost"])
    elif "my_cost" in data:
        cost = float(data["my_cost"])
    else:
        raise ValueError("Missing final_cost/my_cost in result file")

    final_pai: List[int] = []
    if "final_pai" in data and data["final_pai"]:
        final_pai = [int(x) for x in data["final_pai"].split(",") if x]

    # Prefer reading num/final_num/my_num from the file. The public baseline does not
    # contain final_pai, so the evaluation count must be explicitly specified and cannot
    # be inferred from the permutation length.
    if "num" in data:
        num = int(float(data["num"]))
    elif "final_num" in data:
        num = int(float(data["final_num"]))
    elif "my_num" in data:
        num = int(float(data["my_num"]))
    else:
        raise ValueError("Missing num/final_num/my_num in result file")

    return {
        "final_cost": cost,
        "num": num,
        "final_pai": final_pai,
    }


def score_cost_num(
    cost: float,
    num: int,
    cost_ref: float = 200690260.6677975,
    num_ref: int = 200000,
    cost_weight: float = 3.0,
    num_weight: float = 0.5,
) -> float:
    """Return a score from 0 to 100; lower cost/num yields a higher score."""
    if cost <= 0:
        raise ValueError("cost must be > 0")
    if num <= 0:
        raise ValueError("num must be > 0")
    if cost_ref <= 0 or num_ref <= 0:
        raise ValueError("cost_ref and num_ref must be > 0")

    # Lower ratio is better; default reference values come from vcpom_m1000_final_result.txt.
    # Scores are capped at the reference value; a very low evaluation count cannot
    # compensate for significantly worse cost.
    cost_sub = min(1.0, cost_ref / cost)
    num_sub = min(1.0, num_ref / num)

    raw = (cost_sub ** cost_weight) * (num_sub ** num_weight)
    score = 100.0 * raw
    return max(0.0, min(100.0, score))


def main() -> None:
    result_path = Path(__file__).with_name("vcpom_m1000_final_result.txt")
    parsed = parse_result_file(result_path)

    final_cost = float(parsed["final_cost"])
    num = int(parsed["num"])
    score = score_cost_num(cost=final_cost, num=num)

    print(f"file={result_path}")
    print(f"cost={final_cost}")
    print(f"num={num}")
    print(f"has_final_pai={bool(parsed['final_pai'])}")
    print(f"score={score:.4f}")

    print("\nExamples:")
    examples = [
        (final_cost, num, "baseline(from file)"),
        (final_cost * 0.9, num, "cost decreased by 10%"),
        (final_cost * 1.1, num, "cost increased by 10%"),
        (final_cost, max(1, int(num * 0.8)), "num decreased by 20%"),
        (final_cost, int(num * 1.2), "num increased by 20%"),
        (final_cost * 0.9, max(1, int(num * 0.8)), "both cost and num decreased"),
        (final_cost * 1.1, int(num * 1.2), "both cost and num increased"),
    ]

    for c, n, tag in examples:
        s = score_cost_num(cost=c, num=n)
        print(f"- {tag}: cost={c:.4f}, num={n}, score={s:.4f}")


if __name__ == "__main__":
    main()
