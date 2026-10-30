## Problem Description

Given an unrooted, edge-weighted tree with $n$ nodes, where each node has an index that forms a permutation of $1 \sim n$.

There are $m$ queries. Each query gives $l,r$, and asks for the sum of distances over all pairs of node indices $(i,j)$ satisfying $l \le i<j \le r$ on the tree. The distance between two nodes is defined as the sum of edge weights on the simple path connecting them.

## Input Format

The first line contains two space-separated integers $n$ $m$.

The next $n-1$ lines each contain three space-separated integers $u$ $v$ $d$, representing an edge between $u$ and $v$ with weight $d$.

The next $m$ lines each contain two space-separated integers $l$ $r$, representing a query.

## Output Format

$m$ lines total, each representing the answer to the corresponding query, taken modulo $2^{32}$.

## Sample Input/Output #1

### Input #1

```
6 6
2 1 1
5 1 1
3 1 3
4 5 1
6 3 3
2 5
1 5
1 4
3 6
2 6
1 1
```

### Output #1

```
19
26
18
28
44
0
```

## Notes/Constraints

For $100\%$ of the data, $1\le n,m,d\le 2\cdot 10^5$, and all values are integers.

Time Limit: 4s

Memory Limit: 128MB
