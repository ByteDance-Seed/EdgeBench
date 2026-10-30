# Apple Incremental Game -- Machine Production Optimization

## Problem Statement

APPLE ARTIS Corporation has developed a hierarchical system of machines for mass-producing apples. There are $N \times L$ types of machines, composed of $N$ types of IDs and $L$ types of Levels. A machine with Level $i$ and ID $j$ is referred to as machine $j^i$ ($0 \leq i < L,\ 0 \leq j < N$).

The production capacity of machine $j^0$ is $A_j$. The initial cost of machine $j^i$ is $C_{i,j}$.

Your objective is to maximize the total number of apples at the end of $T$ turns.

### Procedure of the Production Plan

Let $B_{i,j}$ be the number of machines $j^i$ (initially all 1), and $P_{i,j}$ be the power of machine $j^i$ (initially all 0). The initial number of apples is $K$.

Each turn proceeds as follows:

1. **Action**: Choose one of:
   - **Strengthen machine $j^i$**: Consume $C_{i,j} \times (P_{i,j} + 1)$ apples to increase $P_{i,j}$ by 1. Cannot strengthen if it would result in negative apples.
   - **Do nothing**.

2. **Production phase** (in order of Level 0, 1, 2, 3):
   - For Level 0 machines ($i = 0$): Increase apples by $A_j \times B_{i,j} \times P_{i,j}$.
   - For Level 1+ machines ($i \geq 1$): Increase $B_{i-1,j}$ by $B_{i,j} \times P_{i,j}$.

## Constraints

- $N = 10, L = 4, T = 500, K = 1$
- $1 \leq A_j \leq 100$, $A$ sorted in ascending order
- $1 \leq C_{i,j} \leq 1.25 \times 10^{12}$
- $C_{0,0} = 1$

## Scoring Formula

Let $S$ be the number of apples at the end of $T$ turns. Your score is:

$$\text{score} = \mathrm{round}(10^5 \times \log_2 S)$$

**Goal: Maximize score (maximize apples).**

The following cases result in WA:
- Strengthening action that makes apples negative
- Specifying a non-existent machine Level or ID
- Taking fewer than $T$ actions

## Input Format

From standard input:

```
N L T K
A_0 A_1 ... A_{N-1}
C_{0,0} C_{0,1} ... C_{0,N-1}
C_{1,0} C_{1,1} ... C_{1,N-1}
...
C_{L-1,0} C_{L-1,1} ... C_{L-1,N-1}
```

## Output Format

To standard output, exactly $T$ lines:

- To strengthen machine $j^i$: `i j`
- To do nothing: `-1`

Comment lines starting with `#` are allowed.

## Runtime Limits

| Resource | Limit |
|----------|-------|
| Time limit | 30 seconds / test case |
| Memory limit | 1 GB |
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

# Score it (official — use tester only)
./tools/bin/tester input.txt output.txt
# stderr: Score = <number>
```

Use `./tools/bin/gen <seed>` with any seed you choose in the range **0..10000** (inclusive). You may generate as many local test cases as needed within this range.

**Do not use `tools/src/verifier.py` for scoring** — it only checks output format. See `tools/README.md`.

### Remote Evaluation (limited submissions)

The final score is determined by remote evaluation on 50 fixed test cases that you cannot view directly. Each submission returns per-case scores and a total score.

**Remote evaluation has a submission limit (~100 times).** Use local testing to debug and optimize, and use remote evaluation to validate your final solution.

**Final score = sum of scores on all 50 test cases.**

## Input Generation

- $N = 10, L = 4, T = 500, K = 1$
- $A_0 = 1$; for $j \neq 0$: $A_j = \mathrm{round}(10^{\mathrm{rand\_double}(0,2)})$, then sorted ascending
- $C_{0,0} = 1$; otherwise $C_{i,j} = \mathrm{round}(A_j \times 500^i \times 10^{\mathrm{rand\_double}(0,2)})$, capped at $10^{15}$

## Hints

This is a resource allocation / incremental game optimization problem:
- Higher-level machines produce lower-level machines, creating exponential growth
- Early investment in cheap machines pays off over many turns
- Balance between investing in Level 0 machines (direct apple production) and higher-level machines (multiplicative growth)
- The cost of strengthening increases linearly with power level ($C_{i,j} \times (P_{i,j}+1)$)

Some directions:
- Greedy: always pick the action with best ROI (return on investment)
- Consider the time horizon: early turns favor long-term investments
- Simulate different strategies to find optimal strengthening order

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
        +-- verifier.py    # Format check only (not for scoring)
```
