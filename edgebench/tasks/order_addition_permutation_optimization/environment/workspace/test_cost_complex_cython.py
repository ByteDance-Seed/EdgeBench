from __future__ import annotations

import time

from cost_complex_cy import cost_complex_with_builtin_data


def main() -> None:
    m = 1000
    pai = list(range(1, m + 1))

    t0 = time.perf_counter()
    cy_val = cost_complex_with_builtin_data(pai, m=m, seed=1)
    t1 = time.perf_counter()

    print("Cython .so call with built-in data succeeded.")
    print(f"m={m}")
    print(f"cython={cy_val}")
    print(f"cython_elapsed_seconds={t1 - t0:.6f}")


if __name__ == "__main__":
    main()
