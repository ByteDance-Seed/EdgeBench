# CVRPTW Solver Optimization

Implement and optimize a C++17 solver for the Capacitated Vehicle Routing Problem with Time Windows.

## Interface

Build with `make`. The solver binary must be named `cvrptw_solver` and must support:

```bash
./cvrptw_solver <input.txt> <output.txt> <time_budget_sec>
```

The program reads the instance from `<input.txt>` and writes the solution to `<output.txt>`. Standard input and standard output are not part of the grading contract.

## Input

Instances are Solomon-style text files with depot id 0, coordinates, demands, time windows, service times, vehicle capacity, and a maximum vehicle count. Distances use `EUC_2D_X10`: `round(sqrt(dx*dx + dy*dy) * 10) / 10`.

## Output

Output must contain one route count, one route line per vehicle, and a cost line:

```text
Routes: <NV>
Route 1: 0 <customer ids> 0
Route 2: 0 <customer ids> 0
Cost: <total distance with 2 decimals>
```

Every customer must be served exactly once. Each route must start and end at depot 0. Capacity, time windows, service times, route count, and cost must be feasible under the verifier.

## Workspace

You may modify `src/`, `include/`, and `Makefile`. Keep the binary name and CLI unchanged. Public sample instances in `instances/public/` are for format and feasibility debugging only; hidden evaluation instances and score references are not included in the workspace. The hidden judge enforces a 20-minute total wall-clock budget per submission; each instance is called with up to 60 seconds, capped by the remaining global budget. Use `./tools/verify <input.txt> <output.txt>` to check feasibility and cost consistency for a single sample output.

## Constraints

Use only local computation. Do not read hidden judge files, internal cases, reference solutions, BKS tables, or evaluator internals. Do not rely on network access.
