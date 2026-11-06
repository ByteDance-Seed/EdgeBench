# Wireless Electricity -- Wire Placement Optimization

## Problem Statement

Chefland lies on a 2D plane with $N$ cities and $M$ wire segments. Two metal plates define positive and negative poles:
- **Positive plate**: $(-1, 0)$ to $(0, -1)$
- **Negative plate**: $(10^6+1, 10^6)$ to $(10^6, 10^6+1)$

A wire is "positive" if it intersects the positive plate or another positive wire (transitively). Similarly for "negative". No wire may be both.

For each city $i$, the transmission cost is $S_i^2 + T_i^2$, where $S_i$ and $T_i$ are minimum distances to endpoints of any positive and negative wire respectively.

You can translate (not rotate) each wire by $(h_i, v_i)$ with movement cost $h_i^2 + v_i^2$.

Minimize $P + Q$ where $P$ = total transmission cost and $Q$ = total movement cost.

## Constraints

- $N = 10^4$, $M = 2500$
- City coordinates: random in $[0, 10^6]$
- Wire lengths parameterized by $L \in \{8000, 10000, 12000, 14000, 16000\}$
- $|h_i|, |v_i| \leq 10^6$

## Scoring

Score = $P + Q$. **Minimize.**

Must have at least one positive and one negative wire, with no short circuits.

## Input Format

```
N M
X_1 Y_1
...
X_N Y_N
A_1 B_1 C_1 D_1
...
A_M B_M C_M D_M
```

## Output Format

$M$ lines, each: `h_i v_i`

## Runtime Limits

| Resource | Limit |
|----------|-------|
| Time limit | 5 seconds / test case |
| Memory limit | 1 GB |

## Programming Language

C++17. Single file `solution.cpp`. Compile with `g++ -std=c++17 -O2 -o solution solution.cpp`.

## Evaluation Method

### Local Testing

```bash
./tools/bin/gen <seed> > input.txt
g++ -std=c++17 -O2 -o solution solution.cpp
./solution < input.txt > output.txt
./tools/bin/tester input.txt output.txt
```

### Remote Evaluation

50 fixed test cases. **Final score = sum of P+Q on all 50 cases.**

## Hints

- Moving no wires (all zeros) is a valid baseline if the original configuration has positive and negative wires.
- Focus on positioning wires near city clusters.
- Use spatial data structures (k-d trees) to find nearest cities efficiently.
- Consider which wires to make positive/negative vs. neutral.

## Directory Structure

```
(your workspace)
+-- README.md
+-- solution.cpp
+-- tools/
    +-- README.md
    +-- bin/{gen, tester}
    +-- src/{gen.cpp, tester.cpp}
```
