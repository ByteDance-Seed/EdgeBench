## Problem Description

This is an interactive problem. The distributed files contain samples and the interaction library. The distributed interaction library differs from the one used in actual testing.

You need to include the header file `data.h`. For local testing, you need to compile your program together with the distributed interaction library file. Input and output are handled by the interaction library; you only need to implement the specified function `solve`.

You need to implement the `solve()` function using the `Data` class. You may use the `Data` class member functions `add()`, `sub()`, `clr()`, as well as functions automatically synthesized by the C++ compiler (including constructors and assignment operators).

Let the set of all elements of type `Data` be $D$.

For any $a,b,c\in D$, the following properties hold:

  - $a+b, a-b \in D$
  - $(a+b)+c=a+(b+c)$
  - $a+b=b+a$

There exists an identity element $e \in D$ such that for any $a,b\in D$:

  - $a+e=e+a=a$
  - $a+(e-a)=(e-a)+a=e$
  - $a-b=a+(e-b)$

The above properties can also be stated as: $(D,+,-,e)$ forms a commutative group.

Given $n$ points, the $i$-th point has coordinates $(x_i,y_i)$ and a weight $d_i$ of type `Data`, $i=1,2,\dots,n$;

Given $m$ half-planes $(A_i,B_i,C_i)$, $i=1,2,\dots,m$;

There are $q$ queries $l_i,r_i$, $i=1,2,\dots,q$;

In the $i$-th query, you need to answer the sum of point weights in the intersection of a range of half-planes. Specifically:

Let the set $S_i = \{ k \mid \forall l_i \le j \le r_i, A_jx_k + B_jy_k \ge C_j \}$, compute $\sum\limits_{k \in S_i} d_k$.

### Interface Description

Use `a.clr()` to set $a$ to the identity element $e$.

Use `a.add(b,c)` to set $a$ to $b+c$.

Use `a.sub(b,c)` to set $a$ to $b-c$.

Use `a=b` to set $a$ to $b$.

### Judging Details

The interface of the function `solve` that you need to implement is as follows:

```cpp
void solve(
	int n,
	int xy[][2],
	Data d[],
	int m,
	int abc[][3],
	int q,
	int lr[][2],
	Data ans[]);
```

During judging, the interaction library will call `solve` exactly once.

In the parameters of the `solve` function, $x_i$ corresponds to `xy[i][0]`, $y_i$ corresponds to `xy[i][1]`, $d_i$ corresponds to `d[i]`;

$A_i,B_i,C_i$ correspond to `abc[i][0],abc[i][1],abc[i][2]`;

$l_i,r_i$ correspond to `lr[i][0],lr[i][1]`, and the answer to the $i$-th query must be stored in `ans[i]`;

$n,m,q$ correspond to `n,m,q`.

You may perform any number of element assignments, copies, or calls to `clr()`, but the total number of calls to `add()` and `sub()` combined must not exceed $4\times 10^7$.

For C++ contestants, please ensure your program begins with:

```cpp
#include "data.h"
```

The file `grader.cpp` in the problem directory is our provided reference implementation of the interaction library. The interaction library used in final testing differs from this reference, so contestants' solutions should not depend on the interaction library implementation.

For C++ contestants:

You need to name your submission file `chesed.cpp` and compile it in the problem directory using the following command:

```
g++ grader.cpp chesed.cpp -o chesed -O2 -lm
```

For the compiled executable:

First, read data from the test case's input file.

After reading is complete, the interaction library will call the function `solve` exactly once, testing your function with the input data.

After your function returns correctly, the interaction library will output the answer for each query to the output file. If your output matches the corresponding test case's output file exactly (ignoring trailing spaces on lines), you pass that test case.

### Constraints

For $25\%$ of the data, $n,m,q\le 100$;

For another $25\%$ of the data, $q\le 100$;

For another $25\%$ of the data, $l_i=r_i$, and $x_i,y_i$ are chosen independently and uniformly at random within the data range;

For $100\%$ of the data, $1\le n\le 2\times 10^5$, $1\le m\le 10^4$, $1\le q\le 10^5$, $|A_j|,|B_j|\le 10^4$, $|x_i|,|y_i|,|C_j|\le 10^5$, $B_j>0$, $C_j<0$, $-10^6\le C_j<0$, $1\le l_i\le r_i\le m$.

Time Limit: 2s

Memory Limit: 512MB
