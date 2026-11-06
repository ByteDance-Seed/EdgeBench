## Problem Description

This is an interactive problem. The distributed files contain samples and the interaction library. The distributed interaction library differs from the one used in actual testing.

You need to include the header file `data.h`. For local testing, you need to compile your program together with the distributed interaction library file. Input and output are handled by the interaction library; you only need to implement the specified function `solve`.

You may call the following functions:

```cpp
void Data::add_eq(const Data &a);
void Data::add(const Data &a,const Data &b);
void Data::clr();
void Operation::apply(Data &w)const;
void Operation::apply(Operation &w)const;
void Operation::clr();
```

Two binary operations $+,*$ are defined as follows:

For any elements $a,b,c$ of type `Data`,

`a.add_eq(b)` sets $a$ to $a+b$;

`a.add(b,c)` sets $a$ to $b+c$;

`a.clr()` sets $a$ to $e_+$, where $e_+$ is a constant of type `Data`;

$e_++a=a+e_+=a$

$a+b=b+a$

$(a+b)+c=a+(b+c)$

For any elements $f,g,h$ of type `Operation`, and any elements $a,b$ of type `Data`,

`f.apply(a)` sets $a$ to $f*a$;

`f.apply(g)` sets $g$ to $f*g$;

`f.clr()` sets $f$ to $e_*$, where $e_*$ is a constant of type `Operation`;

$(f*g)*h=f*(g*h)$

$(f*g)*a=f*(g*a)$

$f*(a+b)=(f*a)+(f*b)$

$e_**f=f*e_*=f$

$e_**a=a$ 

Additionally, the constructors, destructors, and assignment operations of types `Data` and `Operation` are also allowed to be called.

You need to implement the following function:

```cpp
void solve(
	int n,
	int m,
	int fa[],
	Data d0[],
	int x[],
	int y[],
	Operation o[][2],
	Data ans[][2]);
```

Given a rooted tree with $n$ nodes (numbered $1,2,\dots,n$);

For $2\le i\le n$, `fa[i]` is the parent of node $i$ (guaranteed to be less than $i$);

Each node has state information. The initial state of node $i$ is `d0[i]`.

You need to execute $m$ operations (numbered $0,1,\dots,m-1$), performed in ascending order of their indices.

Operation $i$ is described by `x[i],y[i],o[i][0],o[i][1]`. You need to store the answers in `ans[i][0],ans[i][1]`;

Specifically, you need to classify the tree nodes into two categories: category-1 nodes are those whose distance (edge weight 1) to node `x[i]` is at most `y[i]`; category-2 nodes are all nodes not in category 1;

For each category-1 node with index $j$, execute `ans[i][0].add_eq(d0[j])` followed by `o[i][0].apply(d0[j])` in order;

For each category-2 node with index $j$, execute `ans[i][1].add_eq(d0[j])` followed by `o[i][1].apply(d0[j])` in order;

You may substitute the required operations with other operations, but you must ensure that after the `solve` function completes, the values of `ans[i][0]` and `ans[i][1]` are equal to the values obtained by the above operations.

You must ensure the total cost of operations does not exceed the problem's limit. Specifically: when computing $a+b$ or $a*b$, if neither $a$ nor $b$ is $e_+$ and neither is $e_*$, the cost is 1; otherwise the cost is 0. The total cost is the sum of costs across all computations of $a+b$ and $a*b$.



## Data Range

For $20\%$ of the data, $n,m\le 10^3$.

For another $20\%$ of the data, $fa[i] = i-1$.

For another $20\%$ of the data, $fa[i] = i/2$ (rounded down).

For another $20\%$ of the data, $n,m\le 3\times 10^4$.

For all data, $1\le n,m\le 10^5$, for $2\le i\le n$ we have $1\le fa[i]\le i-1$, for $0\le i\le m-1$ we have $0\le y[i]\le n-1$, and the total cost limit is $1.5\times 10^8$.

Time Limit: 12s

Memory Limit: 512MB
