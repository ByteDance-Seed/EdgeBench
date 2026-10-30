## Problem Description

This is an interactive problem. The distributed files contain samples and the interaction library. The distributed interaction library differs from the one used in actual testing.

You need to include the header file `lib.h`. For local testing, you need to compile your program together with the distributed interaction library file. Input and output are handled by the interaction library; you only need to implement the specified functions `update` and `query`.

When compiling locally, compile together with `lib.cpp`;

The interaction library provides the following data type and functions:

```cpp
struct Data{
	unsigned short a,b,c,d;
	void operator*=(const Data &x);
	void clr();
};
```

The Data type is a unital monoid $(D,*,e)$, specifically:

$D$ is the set of elements of type Data;

$*:D\times D\to D$

$e\in D$

$\forall x,y,z\in D, x*(y*z)=(x*y)*z$

$\forall x\in D, x*e=e*x=x$

Use `x.clr()` to set $x$ to $e$;

Use `x=y` to set $x$ to $y$;

Use `x*=y` to set $x$ to $x*y$. The number of calls to this operation has an upper bound constant of $2\times 10^7$, excluding cases where $x=e$ or $y=e$.

Initially, each point $(x,y)$ on the plane corresponds to a weight $d(x,y)\in D$;

You need to implement the following functions:

```cpp
void update(int x,int dim,Data d1,Data d2);
```

For each $(x_0,y_0)$, perform the operation:

If $dim=0$ and $x_0<x$, set $d(x_0,y_0)$ to $d(x_0,y_0)*d1$;

If $dim=0$ and $x_0\ge x$, set $d(x_0,y_0)$ to $d(x_0,y_0)*d2$;

If $dim=1$ and $y_0<x$, set $d(x_0,y_0)$ to $d(x_0,y_0)*d1$;

If $dim=1$ and $y_0\ge x$, set $d(x_0,y_0)$ to $d(x_0,y_0)*d2$;

```cpp
Data query(int x,int y);
```

Query $d(x,y)$ and return the answer.

For convenience, a template is provided below. Please complete the following code:

```cpp
#include "lib.h"
#include <bits/stdc++.h>

void update(int x,int dim,Data d1,Data d2){
	// complete this
}
Data query(int x,int y){
	// complete this
}
```

## Sample Input/Output #1

### Input #1

```
10
2 200842854 123159544
2 192001936 902183645
2 996055655 154684468
2 957446126 232761122
1 739061119 1 4 6
1 762263616 1 5 8
1 669159682 0 10 7
2 361701640 274578757
1 392040275 0 2 8
1 800311125 1 3 2
```

### Output #1

```
(0,0,0,0)
(0,0,0,0)
(0,0,0,0)
(0,0,0,0)
(19,19,329,10)
```

## Notes/Constraints

There are ten test cases.

For the first 8 test cases, the number of operations is $10,1000,10000,20000,40000,60000,80000,10^5$ respectively, and $x,y,dim$ are chosen uniformly at random;

For the remaining test cases, the number of operations is $10^5$.

For all data:

For update operations, $1\le x\le 10^9$, $dim\in\{0,1\}$;

For query operations, $1\le x,y\le 10^9$.

Time Limit: 2s

Memory Limit: 512MB
