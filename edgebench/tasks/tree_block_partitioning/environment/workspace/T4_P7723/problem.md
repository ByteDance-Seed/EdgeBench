## Problem Description

This is an interactive problem. The distributed files contain samples and the interaction library. The distributed interaction library differs from the one used in actual testing.

You need to include the header file `data.h`. For local testing, you need to compile your program together with the distributed interaction library file. Input and output are handled by the interaction library; you only need to implement the specified function `solve`.

On a 2D plane, there are initially $n$ points $(i,p_i)$, each with weight $d_i$, $0\le i<n$;

There are $m$ operations, numbered from $0$ to $m-1$, executed in ascending order of their indices;

The operation with index $w$ gives $x_1,x_2,y_1,y_2$, satisfying $0<x1<x2<n$, $0<y1<y2<n$.

The grid coordinate of a point $(x,y)$ is defined as $([x\ge x1]+[x\ge x2],[y\ge y1]+[y\ge y2])$.

The following steps are performed in order:

1. Query the sum of weights of points with grid coordinate $(X,Y)$, and record it in $ans[X][Y]$.
2. For each point with grid coordinate $(X,Y)$, apply modification $o[X][Y]$.
3. All points' coordinates change simultaneously. For a point with grid coordinate $(X,Y)$, its coordinate changes from $(x,y)$ to $(x+dx[X],y+dy[Y])$;
    where
    $dx[0]=0$, $dx[1]=n-x2$, $dx[2]=x1-x2$.
    $dy[0]=0$, $dy[1]=n-y2$, $dy[2]=y1-y2$.
    $x1,x2,y1,y2,o,ans$ are all arrays, indexed by the operation number.



Here $d_i$ belongs to an abstract data type $D$, and $o[X][Y]$ belongs to an abstract data type $O$;

An abstract operation $+:D\times D\to D$ is defined on $D$;

An abstract operation $\cdot:O\times D\to D$ is defined on $D,O$;

An abstract operation $\cdot:O\times O\to O$ is defined on $O$;

$\epsilon_D$ is a special element in $D$ called the identity element;

$\epsilon_O$ is a special element in $O$ called the identity element;

These operations satisfy the following properties:

For any $a,b,c\in D$, $a+b=b+a$, $(a+b)+c=a+(b+c)$, $a+\epsilon_D=\epsilon_D+a=a$;

For any $u,v,w\in O$, $(u\cdot v)\cdot w=u\cdot(v\cdot w)$, $u\cdot\epsilon_O=\epsilon_O\cdot u=u$;

For any $u,v\in O$, $a,b\in D$, $(u\cdot v)\cdot a=u\cdot (v\cdot a)$, $u\cdot (a+b)=(u\cdot a)+(u\cdot b)$, $\epsilon_O\cdot a=a$, $u\cdot \epsilon_D=\epsilon_D$;

Each execution of $+$ or $\cdot$ has a certain cost. Specifically, when computing $a+b$ or $a\cdot b$, if neither $a$ nor $b$ is $\epsilon_D$ or $\epsilon_O$, the cost is $1$; otherwise the cost is $0$. You must ensure each answer is correct, and the total cost must not exceed the **cost limit** of the current subtask.


### Implementation Details

The header file defines data types `Data` ($D$) and `Operation` ($O$). You may use the following defined member functions to operate on data of types `Data` and `Operation`:

```c++
void Data::add_eq(const Data &a)
```

`w.add_eq(a)` computes $w+a$ and stores the result in $w$. The cost per call is $1$ when neither $w$ nor $a$ is the identity element, otherwise $0$;

```c++
void Data::add(const Data &a,const Data &b)
```

`w.add(a,b)` computes $a+b$ and stores the result in $w$. The cost per call is $1$ when neither $a$ nor $b$ is the identity element, otherwise $0$;

```c++
void Data::clr()
```

`w.clr()` stores $\epsilon_D$ in $w$. The cost per call is $0$;

```c++
bool Data::empty()const
```

`w.empty()` checks whether $w$ is $\epsilon_D$. Returns $\mathrm{true}$ if so, $\mathrm{false}$ otherwise. The cost per call is $0$;



```c++
void Operation::apply(Data &a)const
```

`w.apply(a)` computes $w\cdot a$ and stores the result in $a$. The cost per call is $1$ when neither $w$ nor $a$ is the identity element, otherwise $0$;

```c++
void Operation::apply(Operation &u)const
```

`w.apply(u)` computes $w\cdot u$ and stores the result in $u$. The cost per call is $1$ when neither $w$ nor $u$ is the identity element, otherwise $0$;

```c++
void Operation::clr()
```

`w.clr()` stores $\epsilon_O$ in $w$. The cost per call is $0$;

```c++
bool Operation::empty()const
```

`w.empty()` checks whether $w$ is $\epsilon_O$. Returns $\mathrm{true}$ if so, $\mathrm{false}$ otherwise. The cost per call is $0$;



Additionally, you may use the assignment operator, copy constructor, or default constructor for types `Data` or `Operation`. Using `Data` as an example:

`w=u` copies $u$ into $w$. The cost per call is $0$;

`Data w(u);` or `Data w=u;` copies $u$ into a newly defined $w$. The cost per call is $0$;

`Data w;` stores $\epsilon_D$ in a newly defined $w$, with cost $0$;

`Operation w;` stores $\epsilon_O$ in a newly defined $w$, with cost $0$;



Operations on `Data` or `Operation` other than those described above may be considered an attack on the judging system depending on the circumstances.

`sizeof(Data)` and `sizeof(Operation)` are both at most $64$. Additionally, the interaction library requires no more than 64MB of space. The time and memory limits include the time and space used by the interaction library. A correct program can be written using only assignment, constructors, `apply`, and `add`; other functions may provide convenience.



You need to implement the following function:

```c++
void solve(
	const int n,
	const int m,
	const int p[],
	const Data d[],
	const int x1[],
	const int x2[],
	const int y1[],
	const int y2[],
	const Operation o[][3][3],
	Data ans[][3][3])
```

- $n$: the number of points;
- $m$: the number of operations;
- $p$: $(i,p[i])$ represents the coordinate of each point, $0\le i<n$;
- $d$: $d[i]$ represents the initial weight of each point, $0\le i<n$;
- $x1,x2,y1,y2,o,ans$: $x1[i],y1[i],x2[i],y2[i],o[i]$ represent the input for each operation. You need to store the corresponding answers in $ans[i]$, $0\le i<m$.

For convenience, a template is provided below. Please complete the following code:

```cpp
#include"data.h"
#include <bits/stdc++.h>

void solve(const int n, const int m, const int p[], const Data d[],
           const int x1[], const int x2[], const int y1[], const int y2[],
           const Operation o[][3][3], Data ans[][3][3]) {
  // complete this
}
```

## Input Format

The distributed interaction library reads input data in the following format:

- Line 1: $n$
- Next $n$ lines: $p_i\;d_i$ ($d_i$ is represented by two integers)
- Line $n+2$: $m$
- Next $m$ lines: $x1_i\;x2_i\;y1_i\;y2_i\;o_i$ ($o_i$ is represented by $9 \times 4$ integers)

Elements of $D$ are $2\times 1$ matrices, elements of $O$ are $2\times 2$ matrices, and the matrix entries are integers modulo $2^{32}$;

$+$ corresponds to matrix addition, $\cdot$ corresponds to matrix multiplication. Refer to the distributed interaction library implementation for details;

The input/output format and definitions of $D,O$, etc. may differ in the actual testing environment;

## Output Format

The distributed interaction library prints your answers in the following format:

- For each query, output $13$ lines, where lines $1, 2, 3, 5, 6, 7, 9, 10, 11$ contain two integers, representing $ans[0][0],ans[0][1],ans[0][2],ans[1][0],ans[1][1],ans[1][2],ans[2][0],ans[2][1],ans[2][2]$ for this query respectively. The remaining lines are blank;
- The total cost is printed to stderr, along with a warning if the total cost exceeds the cost limit.

## Sample Input/Output #1

### Input #1

```
4
1 1 1
2 10 5
0 6 9
3 10 4
2
2 3 1 3 10 10 11 11 10 5 7 3 2 3 6 3 2 2 8 2 3 7 2 4 7 11 8 6 9 5 3 7 11 10 10 8 8 5 5 7
1 2 1 2 2 3 6 11 1 1 5 11 5 2 8 6 1 6 9 2 7 11 3 6 9 10 8 2 9 2 9 8 2 11 3 9 4 11 2 5
```

### Output #1

```
0 0
11 6
0 0

6 9
0 0
0 0

0 0
0 0
10 4


0 0
0 0
15 10

0 0
0 0
125 85

30 66
100 78
0 0
```

## Sample Input/Output #2

### Input #2

```
10
3 5 8
1 4 6
6 8 10
9 7 5
7 6 2
4 9 1
8 8 5
0 3 5
2 6 2
5 10 3
10
4 8 8 9 5 8 3 6 7 7 10 11 10 9 10 3 5 11 3 4 10 3 8 1 3 8 4 11 3 11 5 6 2 5 11 9 6 6 2 1
4 6 5 6 1 2 1 7 10 7 9 11 11 10 10 5 3 2 2 8 2 1 6 1 9 6 6 5 9 4 6 7 2 7 5 4 3 8 1 6
1 5 6 9 7 3 9 2 5 3 2 10 6 11 5 10 5 9 8 5 11 3 3 5 5 10 2 6 2 5 8 4 5 6 10 2 10 11 1 7
3 4 3 9 9 7 1 3 8 4 2 10 5 8 11 3 4 2 1 7 3 9 8 5 4 4 6 6 8 11 11 1 4 7 2 3 2 2 3 10
6 9 2 7 4 6 1 5 6 7 2 4 2 3 11 10 1 10 1 4 10 6 8 3 3 8 1 1 11 2 8 5 5 9 4 11 5 5 9 8
5 7 5 8 10 11 9 8 10 4 1 7 7 1 5 2 10 6 4 5 4 2 1 10 1 3 5 11 1 6 2 1 6 1 6 10 11 10 1 8
3 6 1 6 10 11 9 3 7 3 9 6 1 9 11 6 7 6 3 9 4 11 4 7 2 4 5 5 5 3 4 11 3 4 4 4 6 4 1 9
6 8 2 6 11 5 7 6 6 5 7 5 9 10 6 11 4 4 2 7 2 11 4 9 3 8 7 9 3 3 5 10 2 9 9 4 7 9 7 11
2 5 1 4 5 6 7 1 2 1 1 9 6 10 6 6 1 9 5 10 7 1 8 10 1 4 4 3 9 11 11 6 9 6 8 2 8 10 11 7
6 7 3 6 11 11 11 3 6 6 9 7 6 7 2 5 3 1 8 8 1 9 4 10 9 11 6 4 2 11 10 8 3 6 6 5 11 3 11 8
```

### Output #2

```
17 24
0 0
7 5

18 8
8 5
0 0

16 5
0 0
0 0


157 111
0 0
235 169

40 42
63 68
0 0

126 60
0 0
147 95


215 530
0 0
0 0

2324 2024
2479 1783
0 0

1578 1592
837 509
194 446


0 0
7116 10231
7239 9388

4607 8460
0 0
0 0

6944 6628
64844 45048
0 0


72300 52348
265311 254999
50596 23640

0 0
279180 126900
244936 114292

35348 63827
0 0
0 0


172112 792956
2447373 1106786
929486 443832

1119770 935959
0 0
0 0

1649144 359228
0 0
3553200 2614140


0 0
6950234 5535094
22444890 7998435

0 0
10443636 7892656
71682584 26662760

8776334 5075523
11841632 7740868
0 0


0 0
134875573 343366288
91300520 125610782

59108239 90936089
21697728 43262120
0 0

228318480 448464600
0 0
128593760 97023136


0 0
0 0
2054901740 1978497310

0 0
72853820 66252472
1991063770 2020209575

600177312 754769101
3803713784 3298681920
1004356824 1001672808


3063260331 3299980482
4100473464 1966207784
3031825976 3091919392

0 0
325795536 455181888
0 0

2133373140 3095093880
3643561634 2339855333
576229212 1245355280
```

## Notes/Constraints

For $100\%$ of the data, $n\le 10^5,m\le 2\times 10^4$.

There are 10 test cases, all with $n=10^5$;

The values of $m$ for each test case are $10,100,1000,2000,5000,10000,12500,15000,17500,20000$ respectively;

The cost limit for all test cases is $10^8$.

Each test case is worth $10$ points.

Time Limit: 2s

Memory Limit: 512MB
