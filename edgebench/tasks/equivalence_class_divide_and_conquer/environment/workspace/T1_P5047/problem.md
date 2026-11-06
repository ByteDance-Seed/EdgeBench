## Problem Description

Given a sequence $a$ of length $n$, answer $m$ queries, each asking for the number of inversions in a subarray.

## Input Format

The first line contains two integers $n,m$.

The second line contains $n$ integers representing the sequence.

The following $m$ lines each contain two integers representing the query interval.

## Output Format

Output $m$ lines, each containing one integer representing the answer to that query.

## Sample Input/Output #1

### Input #1

```
4 1
1 4 2 3
2 4
```

### Output #1

```
2
```

## Notes/Constraints

$1\leq n,m \leq 10^5$, $0 \leq a_i \leq 10^9$.

Time Limit: 0.25s

Memory Limit: 32MB
