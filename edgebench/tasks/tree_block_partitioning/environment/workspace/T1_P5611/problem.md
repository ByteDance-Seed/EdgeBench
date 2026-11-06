## Important Notice

Before submitting for testing, you must verify that your time complexity is $O(n\sqrt n)$, otherwise it will not pass the judge.

## Problem Description

Given a sequence of length $n$, there are $m$ query operations.

A query operation is of the form $l\;r\;L\;R$, meaning: if all positions in the sequence whose values are not in $[L,R]$ are replaced with $0$ (positions with values in $[L,R]$ remain unchanged), find the maximum subarray sum within the interval $[l,r]$ of the sequence. The subarray may be empty.

## Input Format

The first line contains two integers $n,m$.

The second line contains $n$ integers representing the sequence.

The following $m$ lines each contain four integers $l\;r\;L\;R$ representing a query operation.

## Output Format

Output $m$ lines, each containing one integer representing the answer.

## Sample Input/Output #1

### Input #1

```
6 5
-1 1 -4 5 -1 4
1 1 4 5
1 1 4 514
2 3 3 3
1 6 -1 5
2 5 2 5
```

### Output #1

```
0
0
0
9
5
```

## Notes/Constraints

Sample explanation:

In the fourth query, the value range restriction is $[-1,5]$, the sequence becomes `-1 1 0 5 -1 4`, and the maximum subarray in interval $[1,6]$ is $[2,6]$, with sum $9$.

In the fifth query, the value range restriction is $[2,5]$, the sequence becomes `0 0 0 5 0 4`, and the maximum subarray in interval $[2,5]$ is $[4,4]$ (tied), with sum $5$.

Data Range:

For $100\%$ of the data, $1\leq n,m \le 10^5$, the absolute value of all numbers in the sequence $\le 10^9$.

Time Limit: 1s

Memory Limit: 64MB
