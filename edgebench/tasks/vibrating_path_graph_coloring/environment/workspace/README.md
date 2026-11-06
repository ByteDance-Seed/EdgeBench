# Vibrating Path -- Graph K-Coloring by Hitting Vertices

## Problem Statement

You are given an undirected weighted graph with $N$ vertices and $M$ edges. All edge weights are pairwise distinct.

A *vibrating path* starting at vertex $u$ is a unique sequence of vertices following minimum-weight edges (with specific removal rules). When you "hit" a vertex, all edges on its longest vibrating path disappear.

Your task: make the graph $K$-colorable by hitting vertices, then provide a valid $K$-coloring. Minimize the total cost of all hits.

## Constraints

- $N \in \{10^3, 10^4\}$
- $M = 10^5$
- $K \in \{1, 2, 3, 4\}$
- Costs $C_i \in [1, 512]$, uniformly random
- Edge weights are a random permutation of $1 \dots M$

## Scoring

Score = sum of costs of all hits. **Minimize.**

Each hit must remove at least one edge. The coloring must be valid (no edge connects same-colored vertices).

## Input Format

```
N M K
C_1 C_2 ... C_N
u_1 v_1 S_1
u_2 v_2 S_2
...
u_M v_M S_M
```

Vertices are 1-indexed.

## Output Format

```
Q
v_1 v_2 ... v_Q
x_1 x_2 ... x_N
```

- Line 1: number of hits $Q$
- Line 2: the vertices hit in order (1-indexed)
- Line 3: coloring of each vertex ($1 \leq x_i \leq K$)

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
./tools/bin/gen <seed> > input.txt
python3 solution.py < input.txt > output.txt
./tools/bin/tester input.txt output.txt
# stderr: Score = <number>
```

### Remote Evaluation (limited submissions)

Final score on 50 fixed test cases. **Final score = sum of scores on all 50 test cases.** Lower is better.

## Hints

- The vibrating path from a vertex is deterministic -- you can compute it.
- Hitting vertices with many high-weight edges removes more edges per hit.
- For $K=1$: all edges must be removed. For $K \geq 2$: only remove edges that prevent valid coloring.
- Consider graph coloring heuristics (greedy, DSatur) to identify which edges are problematic.
- Hit cheap vertices (low $C_i$) when possible.

## Directory Structure

```
(your workspace)
+-- README.md
+-- tools/
    +-- README.md
    +-- bin/
    |   +-- gen
    |   +-- tester
    +-- src/
        +-- gen.py
        +-- verifier.py
```
