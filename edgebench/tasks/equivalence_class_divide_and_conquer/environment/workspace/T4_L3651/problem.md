## Problem Description

Little W has a rooted tree with $n$ nodes (nodes labeled $1\sim n$), rooted at node $1$. The weight of node $i$ is $a_i$.

Let the parent of node $i$ be $f_i$ (for convenience, let $f_1=0$). Little W discovered that this tree has a remarkable property: for any integer $i\in[2,n]$,
$f_{i-1}\le f_i < i$.

Little C is very interested in this, so she decides to make $q$ queries. The $i$-th query gives an interval $[l_i,r_i]$, asking for:

$$ \left(\sum_{x=l_i}^{r_i}\sum_{y=l_i}^{r_i}[l_i\le
\operatorname{LCA}(x,y)\le r_i]\cdot a_x\cdot a_y\right)\bmod998244353
$$

where $\operatorname{LCA}(x,y)$ denotes the lowest common ancestor of $x$ and $y$.

Since Little C eagerly wants to know the answer for each query, this problem enforces online queries (see input format for details).

## Input Format

The first line contains two positive integers $n,q$, representing the number of nodes and the number of queries respectively.

The second line contains $n$ non-negative integers $a_{1\sim n}$, representing the weight of each node.

The third line contains $n-1$ positive integers $f_{2\sim n}$, representing the parent of each node.

The next $q$ lines each contain two non-negative integers
$l_i',r_i'$. Let $lst$ be the answer to the previous query (for the first query,
$lst=0$). Then the actual $l_i=l_i'\oplus lst$, $r_i=r_i'\oplus
lst$, where $\oplus$ denotes the bitwise XOR operation.

## Output Format

$q$ lines total, each containing one integer representing the answer to the corresponding query (modulo $998244353$).

## Sample Input/Output #1

### Input #1

```
6 3
1 2 3 4 5 6
1 1 2 2 3
1 2
11 12
131 132
```

### Output #1

```
9
130
441
```

## Notes/Constraints

Sample explanation:

The first query has interval $[1,2]$. $\operatorname{LCA}(1,1)=1$, $\operatorname{LCA}(1,2)=1$, $\operatorname{LCA}(2,1)=1$, $\operatorname{LCA}(2,2)=2$ all satisfy the condition. The answer is $1\times 1+1\times2+2\times1+2\times2=9$.

The second query has interval $[2,5]$. $\operatorname{LCA}(2,2)=2$, $\operatorname{LCA}(2,4)=2$, $\operatorname{LCA}(2,5)=2$, $\operatorname{LCA}(3,3)=3$, $\operatorname{LCA}(4,2)=2$, $\operatorname{LCA}(4,4)=4$, $\operatorname{LCA}(4,5)=2$, $\operatorname{LCA}(5,2)=2$, $\operatorname{LCA}(5,4)=2$, $\operatorname{LCA}(5,5)=5$ satisfy the condition; all other pairs have $\operatorname{LCA}$ equal to $1$. The answer is $130$.

The third query has interval $[1,6]$. Since the $\operatorname{LCA}$ is always within $[1,n]$, every pair satisfies the condition. The answer is $441$.

Data Range:

Subtask $1(20\%)$: $n,q\le5\times10^3$

Subtask $2(20\%)$: $n,q\le5\times10^4$

Subtask $3(20\%)$: The tree structure is randomly generated

Subtask $4(40\%)$: No special constraints

For $100\%$ of the data, $1\le n,q\le2.5\times10^5$, $0\le a_i <
998244353$, $1\le l_i\le r_i\le n$. It is guaranteed that for any integer
$i\in[2,n]$, $f_{i-1}\le f_i < i$.

Time Limit: 2s

Memory Limit: 512MB
