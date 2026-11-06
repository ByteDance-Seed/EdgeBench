## Problem Description

Given a tree with $n$ nodes, where nodes are labeled from $1$ to $n$.

Define the distance $d(a,b)$ between two nodes $a,b$ on the tree as the smallest non-negative integer $k$ such that there exists a sequence of nodes $v_0,v_1,...,v_k$ satisfying $v_0=a,v_k=b$, and for $0\leq i\leq k-1$, there is an edge between $v_i$ and $v_{i+1}$ on the tree.

There are $m$ queries, each containing parameters $p_0,d_0,p_1,d_1$, asking for:

$$\sum\limits_{d(p_0,a)\leq d_0}\sum\limits_{d(p_1,b)\leq d_1}d(a,b)$$

## Input Format

The first line contains one integer $n$, the number of nodes in the tree.

The next line contains $n-1$ integers $f_2,f_3,...,f_n$, indicating that there is an edge between $i$ and $f_i$ ($1\leq f_i\leq i-1$).

The next line contains one integer $m$, the number of queries.

The next $m$ lines each describe a query: four integers $p_0,d_0,p_1,d_1$ ($1\leq p_0,p_1\leq n,0\leq d_0,d_1\leq n-1$).

## Output Format

$m$ lines total, each containing one integer representing the answer to the corresponding query.

## Sample Input/Output #1

### Input #1

```
7
1 1 2 3 5 2
5
5 1 5 0
2 0 5 0
2 2 4 5
7 2 2 4
3 2 5 4
```

### Output #1

```
2
3
69
57
70
```

## Notes/Constraints

For $100\%$ of the data, $1\leq n\leq 10^5,1\leq m\leq 10^5$.

Time Limit: 4s

Memory Limit: 512MB
