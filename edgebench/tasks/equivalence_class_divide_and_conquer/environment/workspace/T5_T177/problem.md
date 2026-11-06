### Problem Description

Given a tree rooted at $1$ with vertices $1,\dots,n$, there are $m$ queries. Each query gives $l,r$ and asks how many pairs $(a,b)$ satisfy $l\le a<b\le r$ and $l\le lca(a,b)\le r$, where $lca(a,b)$ denotes the lowest common ancestor of vertices $a,b$ on the tree.

### Input Format

The first line contains two integers $n,m$.

The next $n-1$ lines each contain two integers $x,y$, representing each edge $(x,y)$ on the tree.

The next $m$ lines each contain two integers $l,r$, representing a query.

### Output Format

$m$ lines total, each containing one integer, representing the answer to each query in order.

### Sample Input

```
10 10
9 6
5 3
5 9
1 8
5 4
8 4
10 7
2 3
7 9
1 2
4 10
3 3
3 3
7 10
1 3
2 7
7 9
6 6
2 7
```

### Sample Output

```
1
21
0
0
6
3
14
3
0
14
```

### Data Range

For $10\%$ of the data, $n,m\le 100$.

For another $10\%$ of the data, $n,m\le 5000$.

For another $10\%$ of the data, $n\le 5000$.

For another $20\%$ of the data, $n,m\le 100000$.

For another $20\%$ of the data, every node on the tree is adjacent to at most two other nodes.

For $100\%$ of the data, all values are integers, $n,m\le 5\times 10^5$, $1\le x,y\le n$, the input edges form a tree, and $1\le l\le r\le n$.

Time Limit: 12s

Memory Limit: 512MB
