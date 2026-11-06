## Problem Description

This is an interactive problem. The distributed files contain samples and the interaction library. The distributed interaction library differs from the one used in actual testing.

You need to include the header file `hpmq.h`. For local testing, you need to compile your program together with the distributed interaction library file. Input and output are handled by the interaction library; you only need to implement the specified function `solve`.

You need to implement the `solve()` function using the Data class. You may use the member functions of the Data class, as well as functions automatically synthesized by the C++ compiler (including constructors and assignment operators).

Given $n$ points on a plane, the $(i+1)$-th point is $(x_i,y_i)$ with initial value $d_i$, $0\le i<n$;

You need to perform $m$ operations in order; all operations are known from the beginning;

The $(j+1)$-th operation gives three numbers $a_j,b_j,c_j$ and $o_j$, representing the half-plane $a_jx+b_jy<c_j$, $0\le j<m$;

You need to execute the following in order:

First set $s_j=\epsilon_D$, then for each $i$ satisfying $a_jx_i+b_jy_i<c_j$, first set $s_j$ to $s_j+d_i$, then set $d_i$ to $o_j\cdot d_i$;

After completing these modifications, $s_j$ is the answer for this operation;

Here $d_i$ belongs to an abstract data type $D$, and $o_j$ belongs to an abstract data type $O$;

An abstract operation $+:D\times D\to D$ is defined on $D$;

An abstract operation $\cdot:O\times D\to D$ is defined on $D,O$;

An abstract operation $\cdot:O\times O\to O$ is defined on $O$;

$\epsilon_D$ is a special element in $D$ called the identity element;

$\epsilon_O$ is a special element in $O$ called the identity element;

These operations satisfy the following properties:

For any $a,b,c\in D$, $a+b=b+a$, $(a+b)+c=a+(b+c)$, $a+\epsilon_D=\epsilon_D+a=a$;

For any $u,v,w\in O$, $(u\cdot v)\cdot w=u\cdot(v\cdot w)$, $u\cdot\epsilon_O=\epsilon_O\cdot u=u$;

For any $u,v\in O$, $a,b\in D$, $(u\cdot v)\cdot a=u\cdot (v\cdot a)$, $u\cdot (a+b)=(u\cdot a)+(u\cdot b)$, $\epsilon_O\cdot a=a$, $u\cdot \epsilon_D=\epsilon_D$;

Each execution of $+$ or $\cdot$ has a certain cost. Specifically, when computing $a+b$ or $a\cdot b$, if neither $a$ nor $b$ is $\epsilon_D$ or $\epsilon_O$, the cost is 1; otherwise the cost is 0. You must ensure each answer is correct, and the total cost must not exceed the **cost limit** of the current subtask.

### Implementation Details

You must include `hpmq.h`.

The header file defines data types `Data` ($D$) and `Operation` ($O$). You may use the following defined member functions to operate on data of types `Data` and `Operation`:

```c++
void Data::add_eq(const Data &a)
```

`w.add(a)` computes $w+a$ and stores the result in $w$. The cost per call is 1 when neither $w$ nor $a$ is the identity element, otherwise 0;

```c++
void Data::add(const Data &a,const Data &b)
```

`w.add(a,b)` computes $a+b$ and stores the result in $w$. The cost per call is 1 when neither $a$ nor $b$ is the identity element, otherwise 0;

```c++
void Data::clr()
```

`w.clr()` stores $\epsilon_D$ in $w$. The cost per call is 0;

```c++
void Data::print()const
```

`w.print()` outputs $w$ as the answer to one operation. The cost per call is 0. This function must be called exactly $m$ times, corresponding to the answers for each operation in order;

```c++
bool Data::empty()const
```

`w.empty()` checks whether $w$ is $\epsilon_D$. Returns $\mathrm{true}$ if so, $\mathrm{false}$ otherwise. The cost per call is 0;



```c++
void Operation::apply(Data &a)const
```

`w.apply(a)` computes $w\cdot a$ and stores the result in $a$. The cost per call is 1 when neither $w$ nor $a$ is the identity element, otherwise 0;

```c++
void Operation::apply(Operation &u)const
```

`w.apply(u)` computes $w\cdot u$ and stores the result in $u$. The cost per call is 1 when neither $w$ nor $u$ is the identity element, otherwise 0;

```c++
void Operation::clr()
```

`w.clr()` stores $\epsilon_O$ in $w$. The cost per call is 0;

```c++
bool Operation::empty()const
```

`w.empty()` checks whether $w$ is $\epsilon_O$. Returns $\mathrm{true}$ if so, $\mathrm{false}$ otherwise. The cost per call is 0;



Additionally, you may use the assignment operator, copy constructor, or default constructor for types `Data` or `Operation`. Using `Data` as an example:

`w=u` copies $u$ into $w$. The cost per call is 0;

`Data w(u);` or `Data w=u;` copies $u$ into a newly defined $w$. The cost per call is 0;

`Data w;` stores $\epsilon_D$ in a newly defined $w$, with cost 0;

`Operation w;` stores $\epsilon_O$ in a newly defined $w$, with cost 0;



Operations on `Data` or `Operation` other than those described above may be considered an attack on the judging system depending on the circumstances.

`sizeof(Data)` and `sizeof(Operation)` are both at most 64. Additionally, the interaction library requires no more than 64MB of space. The time and memory limits include the time and space used by the interaction library. A correct program can be written using only assignment, constructors, `apply`, and `add`; other functions may provide convenience.



You need to implement the following function:

```c++
void solve(
	const int n,
	const int m,
	const int *x,
	const int *y,
	const Data *d,
	const int *a,
	const int *b,
	const int *c,
	const Operation *o)
```

- $n$: the number of points;
- $x,y,d$: arrays of size $n$, where $(x_i,y_i)$ is the coordinate of the $(i+1)$-th point, and the initial value of this point is $d_i$;
- $m$: the number of operations;
- $a,b,c,o$: arrays of size $m$, where the range of the $(i+1)$-th operation is the half-plane $a_ix+b_iy<c_i$, and the modification operation is $o_i$;

### Testing Method

The distributed interaction library reads input data in the following format:

- Line 1: $n$
- Next $n$ lines: $x_i\;y_i\;d_i$ ($d_i$ is represented by two integers)
- Line $n+2$: $m$
- Next $m$ lines: $a_i\;b_i\;c_i\;o_i$ ($o_i$ is represented by 4 integers)

Elements of $D$ are $2\times 1$ matrices, elements of $O$ are $2\times 2$ matrices, and the matrix entries are integers modulo $2^{32}$;

$+$ corresponds to matrix addition, $\cdot$ corresponds to matrix multiplication. Refer to the distributed interaction library implementation for details;

The input/output format and definitions of $D,O$, etc. may differ in the actual testing environment;

The distributed interaction library prints your answers in the following format:

- First $m$ lines: $s_i$, represented by two integers
- Line $m+1$: total cost

## Sample Input/Output #1

### Input #1

```
The file 1.in in the distributed files can be used as a local test sample, but the interaction library is not guaranteed to be consistent with the one configured for this problem
```

### Output #1

```
The file 1.out in the distributed files can be used as a local test sample, but the interaction library is not guaranteed to be consistent with the one configured for this problem
```

## Notes/Constraints

For all data:

$|x_i|\le 10^6$, $|y_i|\le 10^6$;

$|a_i|\le 10^3$, $|b_i|\le 10^3$, $b_i\ne 0$, $|c_i|\le 10^6$;

$x_i,y_i,a_i,b_i,c_i$ are integers;

For any $i,j$, $a_ix_j+b_iy_j\ne c_i$, i.e., no point lies on any line;

For any $i\ne j$, $\left(\frac{a_i}{b_i},\frac{c_i}{b_i}\right)\ne \left(\frac{a_j}{b_j},\frac{c_j}{b_j}\right)$, i.e., no two lines coincide;

The data is divided into 8 subtasks. Each subtask has fixed $n,m$ and an allowed cost limit. Each subtask may depend on other subtasks; a subtask's score is awarded only when all test cases of that subtask and its dependencies are passed;

| Subtask | n              | m      | Cost Limit            | Score |
| ------- | -------------- | ------ | --------------------- | ----- |
| 1       | $2\times 10^4$ | $10^3$ | $4\times 10^7$        | 5     |
| 2       | $2\times 10^4$ | $10^3$ | $8\times 10^5$        | 15    |
| 3       | $2\times 10^5$ | $10^2$ | $4\times 10^7$        | 5     |
| 4       | $2\times 10^5$ | $10^2$ | $1.25\times 10^6$     | 15    |
| 5       | $2^{16}$       | $10^4$ | $8\times 10^7$        | 20    |
| 6       | $2\times 10^5$ | $10^4$ | $2.5\times 10^7$      | 10    |
| 7       | $2\times 10^5$ | $10^4$ | $1.25\times 10^8$     | 15    |
| 8       | $2\times 10^5$ | $10^4$ | $2.5\times 10^7$      | 15    |


Subtask 5 has a special constraint: $-2^7\le x_i<2^7$, $-2^7\le y_i<2^7$, and for any $i\ne j$, $\left(x_i,y_i\right)\ne \left(x_j,y_j\right)$, i.e., no two points coincide;

Subtask 6 has a special constraint: for $0\le i<n,\;0\le j<m$, $x_i=0$, $y_i=2i$, $a_j=0$, $|b_j|=1$;

Time Limit: 2s

Memory Limit: 512MB
