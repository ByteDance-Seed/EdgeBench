# Triangulation Coloring -- Minimize Ugliness (CodeChef TRICOL)

## Problem Statement

Given **N = 512** points on a 2D canvas with colors (R, G, B), and a **triangulation** of those points, minimize:

$$G = X \cdot C + Y \cdot F + U^2$$

Where:

- **C** = number of color changes performed (must be ≤ **P**)
- **F** = number of edge flips performed (must be ≤ **Q**)
- **U** = number of **ugly** triangles **after all operations**, on the **final triangulation**
- An ugly triangle has **at least two vertices of the same color**

### Operations

1. **Change color** (cost **X**): recolor one point to R/G/B.
2. **Flip edge** (cost **Y**): if an edge is a diagonal of a **convex quadrilateral** formed by two adjacent triangles, replace it with the other diagonal. The result remains a valid triangulation.

Operations may be interleaved in any order.

## Constraints (official judge cases)

- **N = 512**, **M ≤ 1024** triangles in the input
- **P = N/2 = 256**, **Q = 1024**
- **X·Y ≤ 1600** with (X,Y) ∈ {(10,160), (20,80), (40,40), (80,20), (160,10)}
- Coordinates in **[1, 10⁴]**, no three collinear points

## Input / Output

See `tools/README.md`. Output lists **C F**, final color string, then **F** flip lines (1-indexed endpoints).

## Local Testing (agent workspace)

Use the **3 pre-built N=512 files** in `sample_data/` (see `sample_data/README.md`):

```bash
./eval_sample_data.sh
python3 solution.py < sample_data/0000.txt > output.txt
./tools/bin/tester sample_data/0000.txt output.txt
```

The tester applies your flips and counts **U on the final triangulation** (same as CodeChef).

## Evaluation

Your submission is scored on **10 fixed hidden test cases** (N=512). **Lower total score is better.**

Time limit: **30 seconds per case**.
