**[Role]**

You are a black-box combinatorial optimization expert. You need to solve a large-scale Order-of-Addition (OofA) permutation optimization problem, with the goal of finding a full permutation sequence that minimizes the response value.

This is a scientific problem in the field of statistical experimental design. You need to thoroughly study how each component (the ordering of m=1000 components contains 1000 elements) affects the response value, and explore what kind of ordering can minimize the response value as much as possible.

**[Black-Box Evaluation Interface]**

You do not need to know the specific business scenario or cost calculation formula. The only available response value computation interface is the Cython extension in the current directory:

```python
from cost_complex_cy import cost_complex_with_builtin_data

m = 1000
pai = list(range(1, m + 1))
cost = cost_complex_with_builtin_data(pai, m=m, seed=1)
```

- Input: An integer array of length `m = 1000`, which must be a permutation of `1..1000`.
- Output: A floating-point number representing the total cost/response value of that permutation — lower is better.
- Example usage file: `test_cost_complex_cython.py`.

**[Mandatory Black-Box Constraint]**

You may only pass candidate permutations to the public function `cost_complex_with_builtin_data(pai, m=1000, seed=1)` and read the response value it returns.

It is forbidden to use, call, probe, or reflectively access any internal attributes, private functions, or private data structures of the `cost_complex_cy` module, including but not limited to:

```python
cost_complex_cy._build_ctx(...)
cost_complex_cy._build*
cost_complex_cy._ctx*
cost_complex_cy._data*
cost_complex_cy._cache*
getattr(cost_complex_cy, ...)
dir(cost_complex_cy)
cost_complex_cy.__dict__
```

It is also forbidden to replicate the cost function using such internal data, bypass the black-box interaction, or export internal data for offline search. The evaluation system will perform static analysis on submitted code; any such internal access will result in `TOTAL_SCORE 0` and the submission will be flagged as a violation.

**[Evaluation Isolation]**

The `cost_complex_cy.cpython-311-x86_64-linux-gnu.so` and `score_vcpom_result.py` in the root directory are provided for you to run your search algorithm and estimate your local score. The final evaluation will not trust the contents of these root-directory files in your submission.

The evaluation system will use private copies from a hidden test directory:

```text
tests/cost_complex_cy.cpython-311-x86_64-linux-gnu.so
tests/score_vcpom_result.py
```

The working environment deletes the `tests/` directory, so the Agent cannot see these tests and private copies; `tests/` will not be archived during submission either. Therefore, modifying the `.so` or scoring function in the root directory will not improve your score. The final result is determined solely by the permutation, cost, and number of function calls in `final_result.txt`.

**[Reference Result]**

A reference result file is provided in the directory:

```text
vcpom_m1000_final_result.txt
```

This file is read-only and must not be modified, deleted, or overwritten. To prevent direct copying of the answer, the file does not contain a reference permutation — it only contains the reference cost and number of search evaluations:

```text
my_cost=200690260.6677975
my_num=200000
```

It can only be used as a benchmark for result quality and evaluation count, not as a starting permutation.

**[Final Submission Requirements]**

You must generate a new result file:

```text
final_result.txt
```

Do not write results back to `vcpom_m1000_final_result.txt`.

`final_result.txt` must use the following key-value format:

```text
final_pai=3,1,4,2,...
final_cost=123456789.0
final_num=1000
```

Field requirements:

1. `final_pai`: A permutation of length 1000 that must contain exactly `1..1000`, separated by commas without brackets.
2. `final_cost`: The response value you report for `final_pai`. The evaluation will recompute and verify it using `cost_complex_with_builtin_data(final_pai, m=1000, seed=1)`.
3. `final_num`: The number of times your algorithm called the public black-box function `cost_complex_with_builtin_data(...)`. You may also use the field name `num` or `my_num`, but `final_num` is recommended. Do not count only the final verification call; every black-box evaluation during the search must be included.

**[Task Objective]**

1. Design and implement efficient heuristic search / combinatorial optimization algorithms.
2. Find a permutation with the lowest possible cost within a limited number of black-box evaluations.
3. You may use genetic algorithms, simulated annealing, local search, tabu search, ALNS, PSO, CMA-ES, Bayesian optimization, or hybrid strategies.
4. The final result is determined by the contents of `final_result.txt`.

**[Scoring Method]**

The evaluation will check:

1. The submitted code does not call or probe internal attributes, private functions, or private data structures of `cost_complex_cy`; if detected, the output will be `TOTAL_SCORE 0`.
2. `vcpom_m1000_final_result.txt` has not been modified and does not contain `final_pai`.
3. `final_result.txt` exists and contains the required fields.
4. `final_pai` is a valid permutation of `1..1000`.
5. `final_cost` matches the cost recomputed by the black-box function.
6. A continuous score is calculated using `score_cost_num(cost, num)` from the evaluation system's private `tests/score_vcpom_result.py`.

Lower cost and fewer function calls result in a higher score.

The scoring function uses the reference cost and reference evaluation count from `vcpom_m1000_final_result.txt`:

```python
score_cost_num(
    cost,
    num,
    cost_ref=200690260.6677975,
    num_ref=200000,
    cost_weight=3.0,
    num_weight=0.5,
)
```

The scoring first caps both sub-scores:

```python
cost_sub = min(1.0, cost_ref / cost)
num_sub = min(1.0, num_ref / num)
score = 100 * (cost_sub ** 3.0) * (num_sub ** 0.5)
```

If `final_cost <= cost_ref` and `final_num <= num_ref`, the score is a perfect 100. When the cost exceeds the reference or the number of evaluations exceeds the reference, the score decreases; cost penalty is heavier, meaning a very low evaluation count cannot compensate for significantly worse cost.