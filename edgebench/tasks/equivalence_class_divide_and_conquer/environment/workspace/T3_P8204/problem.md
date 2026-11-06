## Problem Description

Given a rooted tree with $n$ vertices, numbered $1,2,\dots,n$, where vertex $1$ is the root. Define the directed neighborhood $N(x,y)$ as the set of vertices in the subtree rooted at $x$ that are at distance less than $y$ from $x$, where $1\le x\le n,\;0\le y\le n$, and $x,y$ are integers.

Given $m$ directed neighborhoods $N(x_i,y_i)_{i=1}^m$, starting from $N(1,0)$, you can reach each given directed neighborhood using at most $5m$ operations. The available operations are:

1. Move from directed neighborhood $N(x,y)$ to $N(x',y')$, where $N(x,y)\subseteq N(x',y')$;
2. Undo one operation 1, i.e., return to the position before the last un-undone operation 1, and mark that operation 1 as undone;
3. Declare that the current position has reached directed neighborhood $N(x_i,y_i)$, where the current neighborhood must be $N(x_i,y_i)$;

The cost of operation 1 is the difference in the number of elements between the two directed neighborhoods before and after the move. Operations 2 and 3 have no cost. Operation 2 can only be executed when there exists an un-undone operation 1. Operation 3 must be executed exactly once for each $1\le i\le m$.

You must ensure that the total cost of operations does not exceed $2.5\times{10}^{9}$.

## Input Format

The first line contains two integers $n\ m$;

The next line contains $n-1$ integers, representing the parent $f_2,\dots,f_n$ of vertices numbered $2,3,\dots,n$ respectively. It is guaranteed that the parent's index is smaller than the child's index;

The next $m$ lines each contain two integers $x_i\ y_i$, representing each given directed neighborhood.

## Output Format

The first line contains one integer $m'$, representing the number of operations you performed;

The next $m'$ lines each describe an operation;

Operation 1 is represented as $1\ x'\ y'$;

Operation 2 is represented as $2$;

Operation 3 is represented as $3\ i$.

## Sample Input/Output #1

### Input #1

```
8 4
1 1 1 2 2 2 5
2 1
1 1
6 0
1 2
```

### Output #1

```
16
1 2 1
3 1
2
1 6 0
3 3
2
1 1 1
1 1 1
3 2
2
1 1 2
1 1 2
3 4
2
2
2
```

## Notes/Constraints

For $100\%$ of the data, $1\le n,m\le 10^6$, $1\le f_i\le i-1$, $1\le x_i\le n,\;0\le y_i\le n$, and all values are integers.

Time Limit: 2s

Memory Limit: 512MB
