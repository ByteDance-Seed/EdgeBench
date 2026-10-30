# Warehouse Manager -- Forklift Operations Optimization

## Problem Statement

Chef's warehouse is an $R \times C$ grid. A forklift starts at the northwest corner (0,0). $R \times C - 1$ goods arrive one by one in a given order, must be loaded and placed in the warehouse, then later dispatched from the entrance in order $1, 2, \ldots, R \times C - 1$.

The forklift can move N/S/E/W, pick up (P) arriving goods, dispatch (D) goods at the entrance, load (Lx) from adjacent cells, and unload (Ux) to adjacent cells. A forklift carrying a good cannot enter an occupied cell.

Minimize the total instruction string length.

## Constraints

- $T = 5$ test cases per input
- $6 \leq R, C \leq 20$
- Good 1 is never the last to arrive
- Output string length $\leq 500{,}000$ per test case

## Scoring Formula

Per test case: $(S + 2) / (R + C - 1) - 2 \times R \times C + 20$

where $S$ is the instruction string length. Score is averaged over $T$ cases. **Minimize.**

## Input Format

```
T
R_1 C_1
a_1 a_2 ... a_{R1*C1-1}
R_2 C_2
a_1 a_2 ... a_{R2*C2-1}
...
```

## Output Format

One line per test case: the forklift command string.

Commands: `N`, `S`, `E`, `W` (move), `P` (pick up arrival), `D` (dispatch at entrance), `Lx` (load from direction x), `Ux` (unload to direction x).

## Runtime Limits

| Resource | Limit |
|----------|-------|
| Time limit | 30 seconds / test case |
| Memory limit | 1 GB |
| GPU | Not available |

## Programming Language

Python 3.10+. Single file `solution.py`.

## Evaluation Method

### Local Testing

```bash
./tools/bin/gen <seed> > input.txt
python3 solution.py < input.txt > output.txt
./tools/bin/tester input.txt output.txt
```

### Remote Evaluation

50 fixed test cases. **Final score = sum of per-input average scores.**

## Hints

- Plan storage positions to minimize movement during both placement and retrieval.
- Consider placing goods that will be dispatched first (low IDs) near the entrance.
- BFS for pathfinding in the grid.
- The arrival order is random; you may need to temporarily rearrange goods.

## Directory Structure

```
(your workspace)
+-- README.md
+-- tools/
    +-- README.md
    +-- bin/{gen, tester}
    +-- src/{gen.py, verifier.py}
```
