# Grid Turing Robot -- Transition Rule Design

## Problem Statement

There is a board consisting of $N \times N$ cells. The top-left cell has coordinates $(0, 0)$, and a cell $i$ rows down and $j$ columns to the right has coordinates $(i, j)$. The outer edge of the $N \times N$ grid is surrounded by walls, and there may also be walls between adjacent cells.

Each cell can be painted with a color. Let $C$ be the total number of colors used, where each color is represented by an integer $0, 1, \ldots, C-1$. You may freely set the initial colors of the board.

The robot has one variable representing its internal state. This state can take values from $0$ to $Q-1$, where $Q$ is freely chosen. The initial internal state is $0$.

Based on the current color $c$ of the cell and the internal state $q$, the robot simultaneously performs:

- Repaints the current cell with color $A(c, q)$
- Updates its internal state to $S(c, q)$
- Moves in the direction $D(c, q)$ (U, D, L, R, or S for stay). If there is a wall, the robot stays in place.

A sequence of $K$ destination cells and an upper limit $T$ on the number of steps are given. The robot starts at the first destination and aims to visit all destinations in order within $T$ steps.

If the robot visits a destination before it is its turn (before reaching all prior destinations), that visit does not count. The robot must reach each destination once it becomes the current target.

Design the initial color configuration and transition rules so that all destinations are visited in order.

## Constraints

- $10 \leq N \leq 20$
- $N \leq K \leq N^2$
- All cells are mutually reachable
- Step limit: $X \leq T \leq 2X$ where $X$ is the minimum number of moves needed

## Scoring Formula

Let $C$ be the number of colors, $Q$ the number of states, and $V$ the number of destinations successfully visited in order within $T$ steps:

- If $V = K$: Score = $C + Q$ (lower is better)
- If $V < K$: Score = $2N^4 + (K - V) \times N^2$ (penalty)

**Goal: Minimize the score.** Visiting all destinations is critical to avoid the large penalty.

## Input Format

```
N K T
v_{0,0} ... v_{0,N-2}
...
v_{N-1,0} ... v_{N-1,N-2}
h_{0,0} ... h_{0,N-1}
...
h_{N-2,0} ... h_{N-2,N-1}
x_0 y_0
...
x_{K-1} y_{K-1}
```

- $v_{i,j}$: binary string; '1' means wall between $(i,j)$ and $(i,j+1)$
- $h_{i,j}$: binary string; '1' means wall between $(i,j)$ and $(i+1,j)$
- $(x_k, y_k)$: $k$-th destination coordinates

## Output Format

```
C Q M
s_{0,0} ... s_{0,N-1}
...
s_{N-1,0} ... s_{N-1,N-1}
c_0 q_0 A(c_0,q_0) S(c_0,q_0) D(c_0,q_0)
...
c_{M-1} q_{M-1} A(c_{M-1},q_{M-1}) S(c_{M-1},q_{M-1}) D(c_{M-1},q_{M-1})
```

- $C$: number of colors ($1 \leq C \leq N^4$)
- $Q$: number of states ($1 \leq Q \leq N^4$)
- $M$: number of transition rules ($0 \leq M \leq T$)
- $s_{i,j}$: initial color of cell $(i,j)$, $0 \leq s_{i,j} < C$
- Each rule: color $c$, state $q$, new color $A$, new state $S$, direction $D$ (U/D/L/R/S)
- No duplicate $(c, q)$ pairs
- Only output rules for pairs that actually occur during simulation

## Runtime Limits

| Resource | Limit |
|----------|-------|
| Time limit | 30 seconds / test case |
| Memory limit | 512 MB |
| GPU | Not available |

## Programming Language

Python 3.10+. Your solution should be a single file `solution.py` that reads from stdin and writes to stdout.

## Evaluation Method

Evaluation is split into **local testing** and **remote evaluation**.

### Local Testing (unlimited)

`tools/` provides an input generator and scoring program for local testing:

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

**Score with `./tools/bin/tester` only** — `src/verifier.py` is loaded by the tester; do not run it directly. See `tools/README.md`.

### Remote Evaluation (limited submissions)

The final score is determined by remote evaluation on 50 fixed test cases that you cannot view directly. Each submission returns per-case scores and a total score.

**Remote evaluation has a submission limit (~100 times).** Use local testing to debug and optimize, and use remote evaluation to validate your final solution.

**Final score = sum of scores on all 50 test cases.** Lower is better.

## Input Generation

- $N = \text{rand}(10, 20)$
- $W = \text{rand}(0, N-1)$ wall segments placed by extending from random internal vertices
- $K = \text{rand}(N, N^2)$ destinations chosen from shuffled cells
- $T = \text{rand}(X, 2X)$ where $X$ is minimum moves to visit all destinations in order

## Hints

This is a Turing-machine-style programming problem:
- **Key insight**: The robot's behavior is determined only by (current cell color, internal state), not position. You must encode position information in the colors.
- **Simple approach**: Assign a unique color to each cell (C = N*N), use BFS paths with state transitions
- **Better approaches**: Reduce the number of colors and states used while still visiting all destinations
- Consider that visiting all K destinations is essential to avoid the huge penalty (2*N^4)

## Directory Structure

```
(your workspace)
├── README.md              # This file
└── tools/
    ├── README.md          # Tool usage details
    ├── bin/
    │   ├── gen            # Input generator
    │   └── tester         # Scoring program
    └── src/
        ├── gen.py         # Generator source code
        └── verifier.py    # Scoring logic (used by bin/tester)
```
