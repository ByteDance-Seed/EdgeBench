# Treant's Forest -- Maze Obstruction Strategy

## Problem Statement

There is a forest consisting of an $N \times N$ grid of cells. Each cell is either an "empty cell" or a "tree". The cell $(0, \lfloor N/2 \rfloor)$ is the entrance. A legendary flower blooms at cell $(t_i, t_j)$.

An adventurer enters the forest seeking the legendary flower. As the boss of tree monsters called "Treants", your role is to place Treants to confuse the adventurer and maximize the number of turns it takes for the adventurer to reach the flower.

### Game Mechanics

The game is turn-based. Each turn:

1. **You place treants**: Choose any number of unrevealed empty cells and place Treants there. Once placed, these cells become trees permanently. You must maintain at least one path from the entrance to the flower.

2. **Adventurer acts**:
   - If at the flower, the game ends.
   - Reveals cells in 4 cardinal directions until hitting a tree.
   - If the flower is revealed, sets it as destination.
   - If destination is unreachable, unsets it.
   - If no valid destination, picks a random unrevealed reachable cell.
   - Moves one step toward destination (BFS shortest path; tie-breaking: up, down, left, right).

### Key Constraints
- Cannot place treants on revealed cells.
- Must always maintain a path from entrance to flower.
- Treants cannot be moved once placed.

## Constraints

- $20 \leq N \leq 40$
- Manhattan distance from entrance to flower $\geq 5$
- All empty cells are initially reachable from the entrance

## Scoring Formula

The **absolute score** for a test case is the number of turns the adventurer takes to reach the flower.

**Goal: Maximize turns (higher is better).**

## Input Format

From standard input:

```
N ti tj
b_{0,0}...b_{0,N-1}
...
b_{N-1,0}...b_{N-1,N-1}
```

Where $b_{i,j}$ is `.` (empty) or `T` (tree).

**Note on evaluation format**: For batch evaluation, the input file also contains destination candidate lines after the grid. Your solution reads only the grid part. The output file should contain one treant placement per turn.

## Output Format

To standard output, one line per turn until the adventurer reaches the flower:

```
m x0 y0 x1 y1 ... xm-1 ym-1
```

Where $m$ is the number of treants to place, followed by their coordinates. Use `0` to place no treants. Use `-1` to stop placing treants for remaining turns (cutoff).

**Important**: For batch evaluation, your solution must produce a complete trace of all placements. The tester replays the game using your placements to compute the score.

## Runtime Limits

| Resource | Limit |
|----------|-------|
| Time limit | 60 seconds / test case |
| Memory limit | 1 GB |
| GPU | Not available |

## Programming Language

Python 3.10+. Your solution should be a single file `solution.py` that reads from stdin and writes to stdout.

## Evaluation Method

This is an **interactive** problem adapted for batch evaluation.

### Local Testing (unlimited)

`tools/` provides an input generator and scoring program:

```bash
# Generate test input (includes grid + destination candidates for replay)
./tools/bin/gen <seed> > input.txt

# Run your solution (reads grid, outputs treant placements)
python3 solution.py < input.txt > output.txt

# Score it (replays the game with your placements)
./tools/bin/tester input.txt output.txt
# stderr: Score = <number> (turns taken by adventurer)
```

Your solution reads the grid from stdin and outputs treant placements to stdout. The tester replays the interaction deterministically.

Use `./tools/bin/gen <seed>` with any seed you choose in the range **0..10000** (inclusive). You may generate as many local test cases as needed within this range.

**Do not use `tools/src/verifier.py` for scoring** — it only checks output format. See `tools/README.md`.

### Remote Evaluation (limited submissions)

The final score is determined by remote evaluation on 50 fixed test cases. Each submission returns per-case scores and a total score.

**Remote evaluation has a submission limit (~100 times).** Use local testing to debug and optimize.

**Final score = sum of scores on all 50 test cases.**

## Solution Architecture

Your solution should:
1. Read the initial grid (N, ti, tj, then N grid rows) from stdin.
2. Track revealed cells as the adventurer explores.
3. For each turn, output treant placements based on the current game state.
4. The tester simulates the adventurer's movement and feeds back state changes.

**For batch mode**: Your solution can pre-compute all placements based on the grid, or simulate the adventurer's behavior internally to make adaptive decisions.

## Hints

- The adventurer always takes BFS shortest paths, so you can predict movement.
- Place treants to block short paths, forcing longer detours.
- Never block ALL paths -- the game ends immediately with WA.
- Consider the adventurer's line-of-sight reveal mechanism: placing treants near the adventurer's path can limit what they see.
- The adventurer's destination choice among unrevealed cells is random, so your strategy should be robust.

## Directory Structure

```
(your workspace)
+-- README.md              # This file
+-- tools/
    +-- README.md          # Tool usage details
    +-- bin/
    |   +-- gen            # Input generator
    |   +-- tester         # Scoring program (replays interaction)
    +-- src/
        +-- gen.py             # Generator source code
        +-- verifier.py        # Format check only (not for scoring)
        +-- interactive_runner.py  # Original interactive runner (reference)
```
