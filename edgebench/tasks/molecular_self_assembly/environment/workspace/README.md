# Molecules -- Atom Bonding Optimization

## Problem Statement

Consider a two-dimensional plane defined by $0 \leq x < L$ and $0 \leq y < L$ with toroidal structure (left/right and top/bottom edges wrap around). There are $N$ points on this plane with given initial positions and velocities.

At each time step $t = 0, 1, \ldots, T - 1$, two phases occur:

1. **Bonding Phase**: Bond pairs of points from different connected components. The bonding cost is the toroidal distance (rounded). After bonding, velocities merge by conservation of momentum.

2. **Movement Phase**: All points move by their component's velocity (mod L).

Plan bonds so that at time $T$, exactly $M$ connected components exist, each of size $K$, while minimizing total bonding cost.

## Constraints

- $N = 300$, $T = 1000$, $M = 10$, $K = 30$, $L = 10^5$
- Positions: integers in $[0, L)$
- Velocities: integers in $[-100, 100]$

## Scoring Formula

$$\text{Score} = \text{round}\left(10^6 \times \log_2\left(\frac{L \times (N - M)}{D_{\text{sum}} + 1}\right)\right)$$

where $D_{\text{sum}}$ is the total bonding cost. Higher is better.

**Goal: Maximize score (minimize total bonding cost).**

## Input Format

```
N T M K L
x_0 y_0 vx_0 vy_0
x_1 y_1 vx_1 vy_1
...
x_{N-1} y_{N-1} vx_{N-1} vy_{N-1}
```

## Output Format

Exactly $N - M = 290$ lines, each: `t i j` meaning bond point $i$ and $j$ at time $t$.

```
t_1 i_1 j_1
t_2 i_2 j_2
...
```

Bonds are processed in ascending order of $t$. Output order is arbitrary but processing is by time.

## Runtime Limits

| Resource | Limit |
|----------|-------|
| Time limit | 30 seconds / test case |
| Memory limit | 1 GB |
| GPU | Not available |

## Programming Language

Python 3.10+. Your solution should be a single file `solution.py` that reads from stdin and writes to stdout.

## Evaluation Method

### Local Testing (unlimited)

```bash
# Generate test input
./tools/bin/gen <seed> > input.txt

# Run your solution
python3 solution.py < input.txt > output.txt

# Score it
./tools/bin/tester input.txt output.txt
# stderr: Score = <number>
```

Use `./tools/bin/gen <seed>` with any seed you choose in the range **0..10000** (inclusive). You may generate as many local test cases as needed within this range.

**Use `./tools/bin/tester` for official scores** — `src/verifier.py` is reference only. See `tools/README.md`.

### Remote Evaluation (limited submissions)

Final score on 50 fixed test cases. **Final score = sum of scores on all 50 test cases.**

## Hints

- Points move with constant velocity on a torus. You can predict future positions.
- Bonding nearby points at the right time minimizes cost.
- Group points with similar velocities -- they stay close together.
- Use MST or greedy approaches to form spanning trees within groups.
- Consider timing: wait for points to approach each other before bonding.

## Directory Structure

```
(your workspace)
+-- README.md              # This file
+-- tools/
    +-- README.md          # Tool usage details
    +-- bin/
    |   +-- gen            # Input generator
    |   +-- tester         # Scoring program
    +-- src/
        +-- gen.py         # Generator source code
        +-- verifier.py    # Reference only (tester is authoritative)
```
