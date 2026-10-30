# A Fast Linear-Arithmetic Solver for DPLL(T)-

Bruno Dutertre and Leonardo de Moura 

Computer Science Laboratory, SRI International, 333 Ravenswood Avenue, Menlo Park, CA 94025, USA {bruno, demoura}@csl.sri.com 

Abstract. We present a new Simplex-based linear arithmetic solver that can be integrated efficiently in the DPLL $( T )$ framework. The new solver improves over existing approaches by enabling fast backtracking, supporting a priori simplification to reduce the problem size, and providing an efficient form of theory propagation. We also present a new and simple approach for solving strict inequalities. Experimental results show substantial performance improvements over existing tools that use other Simplex-based solvers in DPLL(T ) decision procedures. The new solver is even competitive with state-of-the-art tools specialized for the difference logic fragment. 

# 1 Introduction

Decision procedures for quantifier-free linear arithmetic determine whether a boolean combination of linear equalities, inequalities, and disequalities is satisfiable. Several tools for solving this problem rely on the DPLL(T ) approach [1]: they combine boolean satisfiability solvers based on the Davis-Putnam-Logemann-Loveland (DPLL) procedure, and arithmetic solvers capable of deciding the satisfiability of conjunctions of linear constraints. Results of a first satisfiability modulo theories (SMT) competition, comparing several of these tools, are presented in [2]. Several tools (e.g., Barcelogic [21] or Slice [20]) are specialized for the difference-logic fragment of linear arithmetic and rely on graph algorithms. For general linear arithmetic, existing tools rely either on Fourier-Motzkin elimination [3] (used by CVClite [4], CVC [5], SVC [6]) or on Simplex methods [7] (used by MathSat [8], ICS [9], Simplics, Yices, ARIO [10]). Fourier-Motzkin elimination explodes on many problems and Simplex is generally superior. 

The common methods for integrating a Simplex solver with DPLL rely on incremental versions of Simplex such as described in [11,12,13,14]. A tableau is constructed and updated incrementally: rows are added as DPLL proceeds and are later removed when DPLL backtracks. These frequent addition and removal of rows and the related bookkeeping have a significant cost. For example, backtracking may require pivoting operations. This paper presents a simpler and more efficient solver that considerably reduces this overhead. The approach relies on transforming the original formula $\varPhi$ into 

an equisatisfiable $\varPhi ^ { \prime }$ such that the satisfiability of $\varPhi ^ { \prime }$ is decided by solving a series of problems of the form 

$$
\text {f i n d} x \in \mathbb {R} ^ {n} \text {s u c h t h a t} A x = 0 \text {a n d} l _ {i} \leq x _ {i} \leq u _ {i} \text {f o r} i = 1, \dots , n,
$$

where the matrix $A$ is fixed and $l _ { i }$ and $u _ { i }$ are bounds on $x _ { i }$ that may vary with each problem. Variants of Simplex can efficiently solve problems in this form. Section 4 presents such a variant designed to be efficient in the DPPL $( T )$ context, and Section 5 shows how to extend it to problems with strict inequalities. Since $A$ is fixed, no row is ever added or removed from the tableau, and backtracking is very cheap. The new solver has additional advantages: it is possible to simplify the problem a priori by eliminating irrelevant variables, and a simple but useful form of theory propagation can be implemented cheaply. 

# 2 Background

Given a quantifier-free theory $T$ , a $T$ -solver is a procedure for deciding whether a finite set of atoms of $T$ is satisfiable. If $\varPhi$ is a formula built by boolean combination of atoms of $T$ , then the satisfiability of $\varPhi$ can be decided by combining a boolean satisfiability solver and a $T$ -solver. The DPLL $( T )$ approach is an efficient method for such integrations that relies on the DPLL procedure. 

# 2.1 Solvers for DPPL $_ { ( T ) }$

In the DPLL $( T )$ framework, a $T$ -solver maintains a state that is an internal representation of the atoms asserted so far. This solver must provide operations for updating the state by asserting new atoms, checking whether the state is consistent, and backtracking. Optionally, the solver may also implement theory propagation, that is, identify atoms that are implied by the current state. To interact with the DPLL search, the solver must produce explanations for conflicts and propagated atoms. In an inconsistent state $S$ , an explanation is any inconsistent subset of the atoms asserted in $S$ . Similarly, an explanation for an implied atom $\gamma$ is a subset $\varGamma$ of the asserted atoms such that $T \models \gamma$ . An explanation $\varGamma$ is minimal if no proper subset of $\varGamma$ is an explanation. 

The solver is assumed initialized for a fixed formula $\varPhi$ and we denote by $\mathcal { A }$ the set of atoms that occur in $\varPhi$ . The set of atoms asserted so far is denoted by $\alpha$ . The solver also maintains a stack of checkpoints that mark consistent states to which the solver can backtrack. We assume that a $T$ -solver implements the following API.1 

– Assert(γ) asserts atom $\gamma$ in the current state. It returns either ok or unsat $\langle { T } \rangle$ where $\varGamma$ is a subset of $\alpha$ . In the first case, $\gamma$ is inserted into $\alpha$ . In the latter case, $\alpha \cup \{ \gamma \}$ is inconsistent and $\varGamma$ is the explanation. 

– Check() checks whether $\alpha$ is consistent. If so, it returns ok, otherwise it returns unsat $\langle { T } \rangle$ . As previously $T \subseteq \alpha$ is an explanation for the inconsistency. A new checkpoint is created when ok is returned. 

– Backtrack() backtracks to the consistent state represented by the checkpoint on the top of the stack. 

– Propagate() performs theory propagation. It returns a set $\{ \langle { \varGamma } _ { 1 } , { \gamma } _ { 1 } \rangle , \dots , \langle { \varGamma } _ { t } , { \gamma } _ { t } \rangle \}$ where $T _ { i } \subseteq \alpha$ and $\gamma _ { i } \in \mathcal { A } \backslash \alpha$ . For every pair $\langle { T _ { i } , \gamma _ { i } } \rangle$ produced, $\gamma _ { i }$ is an atom not already asserted that is implied by $T _ { i }$ , and $T _ { i }$ is a subset of $\alpha$ . 

Assert must be sound but is not required to be complete: $A s s e r t ( \gamma )$ may return ok even if $\alpha \cup \{ \gamma \}$ is inconsistent. Similarly, Propagate must be sound but does not have to be exhaustive. On the other hand, function Check is required to be sound and complete: if $C h e c k ( ) = { \circ } { \mathsf { k } }$ then $\alpha$ must be consistent. This model enables several atoms to be asserted in a single “batch”, using several calls to Assert followed by a single call to Check. Assert can then implement only inexpensive (and possibly incomplete) consistency checks while Check implements a complete (and possibly expensive) consistencychecking procedure. The state $S ^ { \prime }$ after executing Backtrack must be logically equivalent to the state $S$ when the checkpoint was created, but $S ^ { \prime }$ may be different from $S$ . 

# 2.2 Existing Simplex Solvers for DPLL $_ { ( T ) }$

A quantifier-free linear arithmetic formula is a first-order formula whose atoms are either propositional variables of equalities, disequalities, or inequalities of the form 

$$
a _ {1} x _ {1} + \dots + a _ {n} x _ {n} \bowtie b,
$$

where $a _ { 1 } , \ldots , a _ { n }$ and $b$ are rational numbers, $x _ { 1 } , \ldots , x _ { n }$ are real (or integer) variables, and $\Join$ is one of the operators $=$ , ≤, <, >, ≥, or $\neq$ . In the DPLL(T ) framework, deciding the satisfiability of such formulas requires a linear-arithmetic solver. A common approach is to use incremental forms of Simplex similar to the algorithms described in [11,12,13,14]. Tools based on this approach include our own tools, Yices and Simplics, and others such as MathSat [8]. 

In these algorithms, a solver state includes a Simplex tableau that is derived from all equalities and inequalities asserted so far. A tableau can be written as a set of equalities of the form 

$$
x _ {i} = b _ {i} + \sum_ {x _ {j} \in \mathcal {N}} a _ {i j} x _ {j}, \quad x _ {i} \in \mathcal {B} \tag {1}
$$

where $\boldsymbol { B }$ and $\mathcal { N }$ are disjoint sets of variables. Elements of $\boldsymbol { B }$ and $\mathcal { N }$ are called basic and nonbasic variables, respectively. Additional constraints are imposed on some variables of $B \cup { \mathcal { N } }$ . So-called slack variables are required to be non-negative, and the tableau may also contain zero variables, which are all implicitly equal to 0. Zero variables are used to generate explanations (cf. [11]). 

A pivoting operation $p i \nu o t ( x _ { r } , x _ { s } )$ swaps a basic variable $x _ { r }$ and a nonbasic variable $x _ { s }$ such that $a _ { r s } \neq 0$ . After pivoting, $x _ { s }$ becomes basic and $x _ { r }$ becomes nonbasic. The tableau is updated by replacing equation $\begin{array} { r } { x _ { r } = b _ { r } + \sum _ { x _ { j } \in \mathcal { N } } a _ { r j } x _ { j } } \end{array}$ with 

$$
x _ {s} = - \frac {b _ {r}}{a _ {r s}} + \frac {x _ {r}}{a _ {r s}} - \sum_ {x _ {j} \in \mathcal {N} \backslash \left\{x _ {s} \right\}} \frac {a _ {r j} x _ {j}}{a _ {r s}} \tag {2}
$$

and then equation (2) is used to eliminate $x _ { s }$ from the rest of the tableau by substitution. 

![image](https://cdn-mineru.openxlab.org.cn/result/2026-05-08/0daa7321-4a81-489f-b898-02adf6a2c1ee/50c08a753daf5038e35cd519fcbf5cfd97e5d7075ad5f8e9fa98e39be0355c6e.jpg)



(a)Heuristic vs. No Propagation


![image](https://cdn-mineru.openxlab.org.cn/result/2026-05-08/0daa7321-4a81-489f-b898-02adf6a2c1ee/724b9019c1ef4a960c76fbeb5bde141cf986208614a3b07cdc0d2ddf36d542f9.jpg)



(b)Heuristic vs. Full Propagation



Fig. 1. Impact of theory propagation in Simplics


Assertion of equalities or inequalities adds new equations to the tableau. For example, let $\gamma$ be an atom of the form $t \geq 0$ where $t$ is an arithmetic term. The operation $A s s e r t ( \gamma )$ involves three steps. First, $\gamma$ is normalized by substituting any basic variable $x _ { i }$ occurring in $t$ with the term $\begin{array} { r } { b _ { i } + \sum _ { x _ { j } \in \mathcal { N } } a _ { i j } x _ { j } } \end{array}$ . The solver checks then whether the resulting inequality $t ^ { \prime } \geq 0$ is satisfiable. This step uses the Simplex algorithm to maximize $t ^ { \prime }$ subject to the tableau constraints. If $t ^ { \prime }$ has a maximum $M$ and $M$ is negative, then $t ^ { \prime } \geq 0$ is not satisfiable and an explanation is generated. Otherwise, a fresh slack variable $s _ { k }$ is created and a row of the form $s _ { k } \ = \ t ^ { \prime \prime }$ is added to the tableau. Some bookkeeping is required to record that $s _ { k }$ is nonnegative and is associated with atom $\gamma$ . Processing of equalities and strict inequalities follows the same general principles. Backtracking removes rows from the tableau. For example, to retract $\gamma$ , the solver retrieves the slack variable $s _ { k }$ associated with $\gamma$ . If $s _ { k }$ is a basic variable in the current state then the corresponding equation is removed from the tableau. Otherwise, a pivoting operation is applied first to make $s _ { k }$ basic. 

Disequalities are treated separately since they cannot be incorporated into the tableau. When a disequality $t \neq 0$ is asserted, it is first normalized as before, and then the solver must check whether the current tableau implies $t ~ = ~ 0$ . This can be implemented via the zero-detection procedure described in [11] for example. 

# 2.3 Performance

Assertions and backtracking have a significant cost in solvers based on incremental Simplex algorithms. Part of this cost (e.g., the pivoting involved in Assert operations) cannot be avoided, but there is also significant overhead in the frequent additions and removals of rows, creations and deletions of slack variables, and associated bookkeeping. The remainder of the paper describes a different type of solver, still based on the Simplex method, which significantly reduces this overhead. The new approach is simpler and more uniform than incremental Simplex. It is also more economical as irrelevant variables can be eliminated a priori and fewer slack variables are necessary. 

Some of the simplifications are based on lessons we learned from experiments with our previous tools Simplics and Yices:2 

– Minimal explanations are critical. Dramatic improvements were observed when comparing Simplics and Yices, which generate minimal explanations, and their predecessor ICS, which does not. 

– Theory propagation is useful if it can be done cheaply. Figure 1 compares the results of Simplics on the real-arithmetic subset of the SMT-LIB benchmarks [15] using different levels of theory propagation. By default, Simplics uses a heuristic form of propagation that is relatively inexpensive but incomplete (no pivoting is used). This is compared in Figure 1(a) with Simplics running with no propagation at all, and in Figure 1(b) with Simplics running with complete propagation (where pivoting is used). On these benchmarks, full propagation is just too expensive, but no propagation is also a poor choice. Heuristic propagation is clearly superior. 

– Zero detection is expensive and can be avoided. On a few examples in the SMT-LIB benchmarks, Simplics spends as much as $30 \%$ of its time in the zero-detection procedure. A simpler alternative is to rewrite a disequality $t \neq 0$ as the disjunction of two strict inequalities $( t < 0 ) \lor ( t > 0 )$ . This transformation may seem wasteful since it may entail additional case splits, but it works well in practice. After this transformation, Simplics can solve six problems of the SMT-LIB benchmarks that it cannot solve otherwise. 

# 3 Preprocessing

Incremental Simplex algorithms can be avoided by rewriting a linear arithmetic formula $\varPhi$ into an equisatisfiable formula of the form $\varPhi _ { A } \wedge \varPhi ^ { \prime }$ , where $\varPhi _ { A }$ is a conjunction of linear equalities, and all the atoms occurring in $\varPhi ^ { \prime }$ are elementary atoms of the form $y \bowtie b$ , where $y$ is a variable and $b$ is a rational constant. The transformation is straightforward. For example, let $\varPhi$ be the formula 

$$
x \geq 0 \wedge (x + y \leq 2 \vee x + 2 y - z \geq 6) \wedge (x + y = 2 \vee x + 2 y - z > 4).
$$

We introduce two variables $s _ { 1 }$ and $s _ { 2 }$ and rewrite $\varPhi$ to $\varPhi _ { A } \wedge \varPhi ^ { \prime }$ as follows. 

$$
\begin{array}{l} \left(s _ {1} = x + y \wedge s _ {2} = x + 2 y - z\right) \wedge \\ (x \geq 0 \wedge (s _ {1} \leq 2 \vee s _ {2} \geq 6) \wedge (s _ {1} = 2 \vee s _ {2} > 4)) \\ \end{array}
$$

Clearly, this new formula and $\varPhi$ are equisatisfiable. In general, starting from a formula $\varPhi$ , the transformation introduces a new variable $s _ { i }$ for every linear term $t _ { i }$ that is not already a variable and occurs as the left side of an atom $t _ { i } \bowtie b$ of $\varPhi$ . Then $\varPhi _ { A }$ is the conjunction of all the equalities $s _ { i } = t _ { i }$ and $\varPhi ^ { \prime }$ is obtained by replacing every term $t _ { i }$ by the corresponding $s _ { i }$ in $\varPhi$ . 

Let $x _ { 1 } , \ldots , x _ { n }$ be the arithmetic variables of $\varPhi _ { A } \wedge \varPhi ^ { \prime }$ , that is, all the variables originally in $\varPhi$ and $m$ -additional variables $s _ { 1 } , \ldots , s _ { m }$ introduced by the previous transformation $( m \leq n )$ ). Then formula $\varPhi _ { A }$ can be written in matrix form as $A x = 0$ , where $A$ is a fixed $m \times n$ rational matrix and $x$ is a vector in $\mathbb { R } ^ { n }$ . The rows of $A$ are linearly independent so $A$ has rank $m$ . Checking whether $\varPhi$ is satisfiable amounts to finding an $x$ such that $A x = 0$ and $x$ satisfies $\varPhi ^ { \prime }$ . In other words, checking the satisfiability of $\varPhi$ in linear arithmetic is equivalent to checking the satisfiability of $\varPhi ^ { \prime }$ in linear arithmetic 

modulo $A x = 0$ . Since all atoms of $\varPhi ^ { \prime }$ are elementary, this requires a solver for deciding the consistency of a set of elementary atoms $\varGamma$ modulo the constraints $A x = 0$ . If $\varGamma$ contains only equalities and (nonstrict) inequalities, this reduces to searching for $x \in \mathbb { R } ^ { n }$ such that 

$$
A x = 0 \text {a n d} l _ {j} \leq x _ {j} \leq u _ {j} \text {f o r} j = 1, \dots , n \tag {3}
$$

where $l _ { j }$ is either $- \infty$ or a rational number, and $u _ { j }$ is either $+ \infty$ or a rational number. 

Since the elementary atoms of $\varPhi ^ { \prime }$ are known in advance, we can immediately simplify the constraints $A x = 0$ by removing any variable $x _ { i }$ that does not occur in any elementary atom of $\varPhi ^ { \prime }$ . This is done by Gaussian elimination. In practice, this presimplification can reduce the matrix size significantly (cf. [16]). 

The variables $s _ { i }$ introduced during the transformation play the same role as the slack variables of standard Simplex. However, the presence of both lower and upper bounds is beneficial. For example, incremental Simplex algorithms need two slack variables to represent a constraint such as $1 \leq x + 3 y \leq 4$ , whereas a single $s _ { k }$ is sufficient if the general form (3) is used. Overall, rewriting $\varPhi$ into $\varPhi _ { A } \wedge \varPhi ^ { \prime }$ and relying on the general form leads to problems with fewer variables than the algorithms discussed previously. 

# 4 Basic Solver

We first describe a basic solver that handles equalities and nonstrict inequalities with real variables. Extensions to strict inequalities and integer variables are presented in the next sections. The basic solver decides the satisfiability of problems in form (3) and implements the API of Section 2.1 for integration with a DPLL-based SAT solver. 

The solver state includes a tableau derived from the constraint matrix $A$ . We will write such a tableau in the form: 

$$
x _ {i} = \sum_ {x _ {j} \in \mathcal {N}} a _ {i j} x _ {j} \quad x _ {i} \in \mathcal {B},
$$

where $\boldsymbol { B }$ and $\mathcal { N }$ denote the set of basic and nonbasic variables, respectively.3 Since all rows of this tableau are linear combinations of rows of the original matrix $A$ , the equality $\begin{array} { r } { x _ { i } = \sum _ { x _ { j } \in \mathcal { N } } a _ { i j } x _ { j } } \end{array}$ is satisfied by any $x$ such that $A x = 0$ . 

In addition to this tableau, the solver state stores upper and lower bounds $l _ { i }$ and $u _ { i }$ for every variable $x _ { i }$ and a mapping $\beta$ that assigns a rational value $\beta ( x _ { i } )$ to every variable $x _ { i }$ . The bounds on nonbasic variables are always satisfied by $\beta$ , that is, the following invariant is maintained 

$$
\forall x _ {j} \in \mathcal {N}, l _ {j} \leq \beta \left(x _ {j}\right) \leq u _ {j}. \tag {4}
$$

Furthermore, $\beta$ satisfies the constraint $A x = 0$ . In the initial state, $l _ { j } = - \infty , u _ { j } = + \infty .$ and $\beta ( x _ { j } ) = 0$ for all $j$ . 

Figure 2 describes two auxiliary procedures that modify $\beta$ . Procedure update $( x _ { i } , v )$ sets the value of a nonbasic variable $x _ { i }$ to $v$ and adjusts the value of all basic variables so that all equations remain satisfied. Procedure pivotAndUpdate $( x _ { i } , x _ { j } , v )$ applies pivoting to the basic variable $x _ { i }$ and the nonbasic variable $x _ { j }$ ; it also sets the value of $x _ { i }$ to $v$ and adjusts the values of all basic variables to keep all equations satisfied. 

procedure update $( x _ { i } , v )$ 

$$
\text {f o r e a c h} x _ {j} \in \mathcal {B}, \beta (x _ {j}) := \beta (x _ {j}) + a _ {j i} (v - \beta (x _ {i}))
$$

$$
\beta (x _ {i}) := v
$$

procedure pivotAndUpdate $( x _ { i } , x _ { j } , v )$ 

$$
\theta := \frac {v - \beta (x _ {i})}{a _ {i j}}
$$

$$
\beta (x _ {i}) := v
$$

$$
\beta (x _ {j}) := \beta (x _ {j}) + \theta
$$

for each $x _ { k } \in \mathcal { B } \setminus \{ x _ { i } \} , \beta ( x _ { k } ) : = \beta ( x _ { k } ) + a _ { k j } \theta$ 

$$
\operatorname {p i v o t} \left(x _ {i}, x _ {j}\right)
$$

Fig. 2. Auxiliary procedures 

# 4.1 Main Algorithm

The main procedure of our algorithm is based on the dual Simplex and relies on Bland’s pivot-selection rule to ensure termination. It relies on a total order on the variables. Assuming an assignment $\beta$ that satisfies the previous invariants, but where $l _ { i } \le \beta ( x _ { i } ) \le$ $u _ { i }$ may not hold for some basic variables $x _ { i }$ , procedure Check searches for a new $\beta$ that satisfies all constraints. The procedure is shown in Figure 3. It either terminates with a new assignment and basis that satisfy all lower and upper bounds (line 4), or finds the constraints to be unsatisfiable (lines 8 and 13). The body of the main loop selects a basic variable $x _ { i }$ that does not satisfy its bounds (line 3). If $x _ { i }$ is below $l _ { i }$ , then it looks for a variable $x _ { j }$ in the row $\begin{array} { r } { x _ { i } = \sum _ { x _ { j } \in \mathcal { N } } a _ { i j } x _ { j } } \end{array}$ that can compensate the gap in $x _ { i }$ (lines 6-7). If no such $x _ { j }$ exists the problem is unsatisfiable (line 8) because the value of $x _ { i }$ is maximal and is below the lower bound $l _ { i }$ . Otherwise, the procedure pivots $x _ { i }$ and $x _ { j }$ , and $x _ { i }$ is set to $l _ { i }$ (line 9). The case where $x _ { i }$ is above its upper bound (lines 10-14) is symmetrical. 

The following property implies the correctness of Check; a proof is given in [16]. 

Theorem 1. Procedure Check always terminates. 

# 4.2 Generating Explanations

An inconsistency may be detected by Check at line 8 or 13. Let us assume a conflict is detected at line 8. There is then a basic variable $x _ { i }$ such that $\beta ( x _ { i } ) < l _ { i }$ and for every nonbasic variable $x _ { j }$ we have $a _ { i j } > 0 \Rightarrow \beta ( x _ { j } ) \geq u _ { j }$ and $a _ { i j } < 0 \Rightarrow \beta ( x _ { j } ) \leq l _ { j }$ . Let $\mathcal { N } ^ { + } = \{ x _ { j } \in \dot { \mathcal { N } } | a _ { i j } > 0 \}$ and $\mathcal { N } ^ { - } = \{ x _ { j } \in \mathcal { N } | a _ { i j } < 0 \}$ . Since $\beta$ satisfies all bounds on nonbasic variables, we have $\beta ( x _ { j } ) = l _ { j }$ for every $x _ { j } \in \mathcal { N } ^ { - }$ and $\beta ( x _ { j } ) = u _ { j }$ for every $x _ { j } \in \mathcal { N } ^ { + }$ . It follows that 

$$
\beta (x _ {i}) = \sum_ {x _ {j} \in \mathcal {N}} a _ {i j} \beta (x _ {j}) = \sum_ {x _ {j} \in \mathcal {N} ^ {+}} a _ {i j} u _ {j} + \sum_ {x _ {j} \in \mathcal {N} ^ {-}} a _ {i j} l _ {j}.
$$

The equation $\begin{array} { r } { x _ { i } = \sum _ { x _ { j } \in \mathcal { N } } a _ { i j } x _ { j } } \end{array}$ holds for any $x$ such that $A x = 0$ . Therefore, for any such $x$ , we have 

$$
\beta (x _ {i}) - x _ {i} = \sum_ {x _ {j} \in \mathcal {N} ^ {+}} a _ {i j} (u _ {j} - x _ {j}) + \sum_ {x _ {j} \in \mathcal {N} ^ {-}} a _ {i j} (l _ {j} - x _ {j}),
$$

1. procedure Check() 

2. loop 

3. select the smallest basic variable $x _ { i }$ such that $\beta ( x _ { i } ) < l _ { i }$ or $\beta ( x _ { i } ) > u _ { i }$ 

4. if there is no such $x _ { i }$ then return satisfiable 

5. if $\beta ( x _ { i } ) < l _ { i }$ then 

6. select the smallest nonbasic variable $x _ { j }$ such that 

7. $( a _ { i j } > 0$ and $\beta ( x _ { j } ) < u _ { j } )$ or $( a _ { i j } < 0$ and $\beta ( x _ { j } ) > l _ { j }$ 

8. if there is no such $x _ { j }$ then return unsatisfiable 

9. pivotAndUpdate $( x _ { i } , x _ { j } , l _ { i } )$ 

10. if $\beta ( x _ { i } ) > u _ { i }$ then 

11. select the smallest nonbasic variable $x _ { j }$ such that 

12. $( a _ { i j } < 0$ and $\beta ( x _ { j } ) < u _ { j } )$ or $( a _ { i j } > 0$ and $\beta ( x _ { j } ) > l _ { j } ,$ 

13. if there is no such $x _ { j }$ then return unsatisfiable 

14. pivotAndUpdate $( x _ { i } , x _ { j } , u _ { i } )$ 

15. end loop 

Fig. 3. Check procedure 

from which one can derive the following implication: 

$$
\bigwedge_ {x _ {j} \in \mathcal {N} ^ {+}} x _ {j} \leq u _ {j} \wedge \bigwedge_ {x _ {j} \in \mathcal {N} ^ {-}} l _ {j} \leq x _ {j} \Rightarrow x _ {i} \leq \beta (x _ {i}).
$$

Since $\beta ( x _ { i } ) < l _ { i }$ , this is inconsistent with $l _ { i } \leq x _ { i }$ . The explanation for the conflict is then the following set of elementary atoms: 

$$
\Gamma = \{x _ {j} \leq u _ {j} \mid j \in \mathcal {N} ^ {+} \} \cup \{x _ {j} \geq l _ {j} \mid j \in \mathcal {N} ^ {-} \} \cup \{x _ {i} \geq l _ {i} \}.
$$

It is easy to see that $\varGamma$ is minimal. Explanations for conflicts at line 13 are generated in the same way. 

# 4.3 Assertion Procedures

The Assert function relies on two procedures shown in Figure 4 for updating the bounds $l _ { i }$ and $u _ { i }$ . Procedure AssertUpper $( x _ { i } \leq c _ { i } )$ has no effect if $u _ { i } \leq c _ { i }$ and returns unsatisfiable if $c _ { i } ~ < ~ l _ { i }$ ; otherwise the current upper bound on $x _ { i }$ is set to $c _ { i }$ . If variable $x _ { i }$ is nonbasic, then $\beta$ is updated to maintain invariant (4). If an immediate conflict is detected at line 3 then generating a minimal explanation is straightforward. 

Procedure AssertLower $\left( x _ { i } \geq c _ { i } \right)$ does the same thing for the lower bound. An equality $x _ { i } = c _ { i }$ is asserted by calling both AssertUpper and AssertLower. 

# 4.4 Backtracking

Efficient backtracking is important since the number of backtracks is often very large. In our approach, backtracking can be efficiently implemented. We just need to save the value of $u _ { i } \ ( l _ { i } )$ on a stack before it is updated by the procedure AssertUpper (AssertLower). This information is used to restore the old bounds when backtracking is performed. Backtracking does not require saving the successive $\beta \mathrm { s }$ on a stack. Only 

1. procedure AssertUpper $( x _ { i } \leq c _ { i } )$ ) 

2. if $c _ { i } \geq u _ { i }$ then return satisfiable 

3. if $c _ { i } < l _ { i }$ then return unsatisfiable 

4. $u _ { i } : = c _ { i }$ 

5. if $x _ { i }$ is a nonbasic variable and $\beta ( x _ { i } ) > c _ { i }$ then update $( x _ { i } , c _ { i } )$ 

6. return ok 

1. procedure AssertLower $( x _ { i } \geq c _ { i }$ ) 

2. if $c _ { i } \leq l _ { i }$ then return satisfiable 

3. if $c _ { i } > u _ { i }$ then return unsatisfiable 

4. $l _ { i } : = c _ { i }$ 

5. if $x _ { i }$ is a nonbasic variable and $\beta ( x _ { i } ) < c _ { i }$ then update $( x _ { i } , c _ { i } )$ 

6. return ok 

Fig. 4. Assertion procedures 

one assignment $\beta$ needs to be stored, namely, the one corresponding to the last successful Check. After a successful Check, the assignment $\beta$ is a model for the current set of constraints and for the set of constraints asserted at any previous checkpoint. Since no pivoting or other expensive operation is used, backtracking is very cheap. 

# 4.5 Theory Propagation

Given a set of elementary atoms $\mathcal { A }$ from the formula $\varPhi ^ { \prime }$ , then unate propagation is very cheap to implement. For example, if bound $x _ { i } \geq c _ { i }$ has been asserted then any unassigned atom of $\mathcal { A }$ of the form $x _ { i } \geq c ^ { \prime }$ with $c ^ { \prime } < c _ { i }$ is immediately implied. Similarly, the negation of any atom $x _ { i } \leq u$ with $u \textless c _ { i }$ is implied. This type of propagation is useful in practice. It occurs frequently in several SMT-LIB benchmarks. 

Another method is based on bound refinement. Given a row of a tableau, such as $\begin{array} { r } { x _ { i } = \sum _ { x _ { j } \in \mathcal { N } } a _ { i j } x _ { j } } \end{array}$ , one can derive a lower or upper bound on $x _ { i }$ from the lower or upper bounds on the nonbasic variables $x _ { j }$ . These computed bounds may imply unassigned elementary atoms with variable $x _ { i }$ . This is a heuristic technique as the computed bounds may be weaker than the current bounds asserted on $x _ { i }$ (for example, the computed bounds may be $- \infty$ or $+ \infty ,$ ). However, bound refinement is quite general. It is applicable with any equality $a _ { 1 } x _ { 1 } + \ldots + a _ { n } x _ { n } = 0 $ derived by linear combination of rows of $A$ , not just with rows of a tableau. 

# 4.6 Example

Figure 5 illustrates the algorithm on a small example. Each row represents a state. The columns contain the tableaux, bounds, and assignments. The first row contains the initial state. Suppose $x \le - 4$ is asserted. Then the value of $x$ must be adjusted, since $\beta _ { 0 } ( x ) > - 4$ . Since $s _ { 1 }$ and $s _ { 2 }$ depend on $x$ , their values are also modified. No pivoting is required since the basic variables do not have bounds, so $A _ { 1 } = A _ { 0 }$ . Next, $x \geq - 8$ is asserted. Since $\beta _ { 1 } ( x )$ satisfies this bound, nothing changes: $A _ { 2 } = A _ { 1 }$ and $\beta _ { 2 } = \beta _ { 1 }$ . 

<table><tr><td>A0 = {s1 = -x + y
s2 = x + y}</td><td></td><td>β0 = (x → 0, y → 0, s1 → 0, s2 → 0)</td></tr><tr><td>A1 = A0</td><td>x ≤ -4</td><td>β1 = (x → -4, y → 0, s1 → 4, s2 → -4)</td></tr><tr><td>A2 = A1</td><td>-8 ≤ x ≤ -4</td><td>β2 = β1</td></tr><tr><td>A3 = {y = x + s1
s2 = 2x + s1}</td><td>-8 ≤ x ≤ -4
s1 ≤ 1</td><td>β3 = (x → -4, y → -3, s1 → 1, s2 → -7)</td></tr></table>

Fig. 5. Example 

Next, $s _ { 1 } \leq 1$ is asserted. The current value of $s _ { 1 }$ does not satisfy this bound, so Check must be invoked. Check pivots $s _ { 1 }$ and $y$ to decrease $s _ { 1 }$ . The resulting state $S _ { 3 }$ is shown in the last row; all constraints are satisfied. 

If $s _ { 2 } \geq - 3$ is asserted in $S _ { 3 }$ and Check is called then an inconsistency is detected: Tableau $A _ { 2 }$ does not allow $s _ { 2 }$ to increase since both $x$ and $s _ { 1 }$ are at their upper bound. Therefore, $s _ { 2 } \geq - 3$ is inconsistent with state $S _ { 3 }$ . 

# 5 Strict Inequalities

The previous method generalizes to strict inequalities using a simple observation. 

Lemma 1. A set of linear arithmetic literals $\varGamma$ containing strict inequalities $S \ =$ $\{ p _ { 1 } > 0 , \ldots , p _ { n } > 0 \}$ is satisfiable iff there exists a rational number $\delta > 0$ such that $\varGamma _ { \delta } = ( \varGamma \cup S _ { \delta } ) \vee S$ is satisfiable, where $S _ { \delta } = \left\{ p _ { 1 } \geq \delta , \ldots , p _ { n } \geq \delta \right\}$ . 

This lemma says that we can replace all strict inequalities by nonstrict ones if a small enough $\delta$ is known. Rather than computing an explicit value for $\delta$ , we treat it symbolically, as an infinitesimal parameter. Bounds and variable assignments now range over the set $\mathbb { Q } _ { \delta }$ of pairs of rationals. A pair $( c , k )$ of $\mathbb { Q } _ { \delta }$ is denoted by $c { + } k \delta$ and the following operations and comparison are defined in $\mathbb { Q } _ { \delta }$ : 

$$
\begin{array}{l} \left(c _ {1}, k _ {1}\right) + \left(c _ {1}, k _ {2}\right) \equiv \left(c _ {1} + c _ {2}, k _ {1} + k _ {2}\right) \\ a \times (c, k) \equiv (a \times c, a \times k) \\ \end{array}
$$

$$
\left(c _ {1}, k _ {1}\right) \leq \left(c _ {2}, k _ {2}\right) \equiv \left(c _ {1} <   c _ {2}\right) \vee \left(c _ {1} = c _ {2} \wedge k _ {1} \leq k _ {2}\right),
$$

where $a$ is a rational. Strict bounds in $\mathbb { Q }$ are converted to nonstrict bounds in $\mathbb { Q } _ { \delta }$ : inequality $x _ { i } > l _ { i }$ is converted to $x _ { i } \geq l _ { i } + \delta$ , and $x _ { i } < u _ { i }$ is converted to $x _ { i } \leq u _ { i } - \delta$ . Then all updates to $\beta$ used in the previous algorithm can be performed in $\mathbb { Q } _ { \delta }$ . The matrix $A$ does not change; all its coefficients are rational numbers. 

By this process, a problem $s$ with strict bounds in the rational is converted into a problem $S ^ { \prime }$ in the general form (3) but where the bounds $l _ { i }$ and $u _ { i }$ , and the variables $x _ { i }$ are elements of $\mathbb { Q } _ { \delta }$ . If an assignment $\beta ^ { \prime }$ satisfies $S '$ then it can be converted into a rational assignment $\beta$ that satisfies $S$ . This relies on substituting the symbolic parameter $\delta$ with a small enough positive rational number $\delta _ { 0 } \in \mathbb { Q }$ , which can always be done since 

there is a finite number of inequalities in $S ^ { \prime }$ (cf. [16]). If $S ^ { \prime }$ is unsatisfiable in $\mathbb { Q } _ { \delta }$ , then by Lemma 1, $S$ is also unsatisfiable in the rationals. 

# 6 Extensions

The previous solver is sound and complete for the reals. If some or all of the variables $x _ { i }$ are required to be integer, the algorithm is not complete. Nothing ensures that the assignment $\beta$ constructed by Check gives an integer value to integer variables. To be complete in the integer or mixed integer case, we employ a branch and cut strategy, that is, the combination of branch-and-bound with a cutting plane generation algorithm [17,18]. The branch-and-bound algorithm works when problems are solved in $\mathbb { Q } _ { \delta }$ rather than $\mathbb { Q }$ . In other words, it can be used when strict inequalities are present. The cutting-plane method we use is based on mixed integer Gomory cuts. Such a cutting-plane algorithm is critical as it dramatically accelerates the convergence of branch-and-cut in several cases. 

Also, it is possible to integrate the linear-arithmetic solver presented in this paper with solvers for other theories. The simplest method is to perform case-splits on equalities between variables that are shared between different theories. In most cases, the number of such shared variables is small in comparison with the total number of variables and this method is quite efficient. This approach is described in detail at [19]. It can be extended with an opportunistic equality-propagation method [16]. 

# 7 Experiments

Figure 6 compares a prototype SMT solver that uses the previous algorithms with other tools that participated in last year’s SMT competition. The comparison uses all the SMT-LIB benchmarks in the QF RDL (real difference logic), QF IDL (integer difference logic), QF LRA (linear real arithmetic), and QF LIA (linear integer arithmetic) divisions. The experiments were conducted on identical PCs, all equipped with a 32bit Pentium 4 processor running at 3 GHz. The timeout was set to 1 hour and the memory usage was limited to 1 GB. With these timing and memory constraints, running all the benchmarks required approximately 60 CPU days. 

Each point on the graphs represents a benchmark: $^ +$ denotes a difference logic problem and $\times$ denotes a problem outside the difference-logic fragment. The axes correspond to the CPU time taken by the new solver ( $y$ -axis) or the other solver $\scriptstyle { \dot { x } }$ -axis) on each benchmark. CPU times are measured in seconds. Points below the diagonal are then SMT-LIB benchmarks where our new solver is faster. Points on the leftmost vertical edge are problems where a solver aborted, typically by running out of memory. The graphs comparing our new solver with Barcelogic and Simplics have fewer points, because Barcelogic supports only difference logic and Simplics does not support integer problems. 

Table 1 summarizes the results. For each tool, it lists the number of instances solved and unsolved, and the total runtime. As can be seen, the new algorithm largely outperforms the other solvers. It is even faster on problems in the difference logic fragment 

![image](https://cdn-mineru.openxlab.org.cn/result/2026-05-08/0daa7321-4a81-489f-b898-02adf6a2c1ee/a10b52ade9bbb7b386e92da2cd2c1dd3c0b895874dd56c5bb7bb898902890eef.jpg)



(a)Ario 1.1 vs. New Solver


![image](https://cdn-mineru.openxlab.org.cn/result/2026-05-08/0daa7321-4a81-489f-b898-02adf6a2c1ee/8edf4d1943cbaa2d486cb7069441c2b1c889e45ef3ee982319a8de8d6b6272bf.jpg)



(b)BarcelogicTools vs. New Solver


![image](https://cdn-mineru.openxlab.org.cn/result/2026-05-08/0daa7321-4a81-489f-b898-02adf6a2c1ee/7f0cff20297718fe3230e22ba2c1416665beb9b32e00232c92442731593bac23.jpg)



(c)CVC Lite 2.0 vs. New Solver


![image](https://cdn-mineru.openxlab.org.cn/result/2026-05-08/0daa7321-4a81-489f-b898-02adf6a2c1ee/99083bad78a47cfcfa9edf1a73e7058b2c4ed5600a32a02c839e3f4f19a8c4fd.jpg)



(d)MathSAT 3.3.1 vs. New Solver


![image](https://cdn-mineru.openxlab.org.cn/result/2026-05-08/0daa7321-4a81-489f-b898-02adf6a2c1ee/4435d9860bbe001f5e1eaee2e00245674f799c674bb2dacfab78134eedcb5768.jpg)



(e)Simplics vs. New Solver


![image](https://cdn-mineru.openxlab.org.cn/result/2026-05-08/0daa7321-4a81-489f-b898-02adf6a2c1ee/8ce21f25635a30db8e7e62c08b23dddd636b1eabd5411b9f1a5d032b5e2c4284.jpg)



(f)Yices vs. New Solver



Fig. 6. Experimental results


than tools that are specialized for this fragment. The performance improvement is due to efficient backtracking and to the presimplification enabled by our approach, efficient theory propagation based on bound refinement also has a big impact. 


Table 1. Experimental results: Summary


<table><tr><td></td><td>sat</td><td>unsat</td><td>failed</td><td>time (secs)</td></tr><tr><td>Ario 1.1</td><td>186</td><td>640</td><td>517</td><td>1218371</td></tr><tr><td>BarcelogicTools</td><td>153</td><td>417</td><td>92</td><td>401842</td></tr><tr><td>CVC Lite</td><td>117</td><td>454</td><td>772</td><td>1193747</td></tr><tr><td>MathSAT 3.3.1</td><td>330</td><td>779</td><td>234</td><td>739533</td></tr><tr><td>Yices</td><td>358</td><td>756</td><td>229</td><td>702129</td></tr><tr><td>Simplices</td><td>240</td><td>351</td><td>110</td><td>476940</td></tr><tr><td>New Solver</td><td>412</td><td>869</td><td>62</td><td>267198</td></tr></table>

# 8 Conclusion

We have presented a new Simplex-based solver designed for efficiently solving SMT problems involving linear arithmetic. The main features of the new approach include the possibility to presimplify the input problem by eliminating variables, a reduction in the number of slack variables, and fast backtracking. A simple but useful form of theory propagation can also be implemented cheaply. Another result of the paper is a simple approach for solving strict inequalities that does not require modification of the basic Simplex algorithm. This approach is more generally applicable to other forms of solvers, such as graph-based solvers for difference logic. 

Experimental results show that the new Simplex-based solver outperforms the most competitive solvers from SMT-COMP’05, including specialized solvers on difference logic problems. 

Applications for the algorithm presented in this paper go beyond SMT. We are currently extending the solver to support a form of weighted MAX-SMT, that is, the search for an assignment to an SMT problem that maximizes a linear objective function. This MAX-SMT solver will be integrated to SRI’s CALO system4, as part of a module that combines learning and deductive algorithms. 

# References



1. Ganzinger, H., Hagen, G., Nieuwenhuis, R., Oliveras, A., Tinelli, C.: DPLL(T): Fast Decision Procedures. In Alur, R., Peled, D., eds.: Int. Conference on Computer Aided Verification (CAV’04). Volume 3114 of LNCS., Springer (2004) 175–188 





2. Barrett, C., de Moura, L., Stump, A.: Design and Results of the 1st Satisfiability Modulo Theories Competition (SMT-COMP 2005). To appear in Journal of Automated Reasoning (2006) 





3. Dantzig, G., Curtis, B.: Fourier-Motzkin Elimination and its Dual. Journal of Combinatorial Theory (1973) 288–297 





4. Barrett, C., Berezin, S.: CVC Lite: A New Implementation of the Cooperating Validity Checker. In: Int. Conf. on Computer-Aided Verification (CAV). Volume 3114 of LNCS., Springer (2004) 





5. Stump, A., Barrett, C., Dill, D.: CVC: A Cooperating Validity Checker. In: Int. Conference on Computer Aided Verification (CAV’02). Volume 2404 of LNCS., Springer (2002) 





6. Barrett, C., Dill, D., Levitt, J.: Validity Checking for Combinations of Theories with Equality. In: Int. Conference on Formal Methods in Computer-Aided Design (FMCAD). Volume 1166 of LNCS. (1996) 187–201 





7. Chvatal, V.: Linear Programming. W. H. Freeman (1983) 





8. Bozzano, M., Bruttomesso, R., Cimatti, A., Junttila, T., van Rossum, P., Schulz, S., Sebastiani, R.: The MathSAT 3 system. In: Int. Conference on Automated Deduction (CADE). Volume 3632 of LNCS., Springer (2005) 





9. Filliˆatre, J.C., Owre, S., Rueß, H., Shankar, N.: ICS: Integrated Canonization and Solving. In: Proc. of CAV’01. Volume 2102 of LNCS. (2001) 





10. Sheini, H.M., Sakallah, K.A.: A Scalable Method for Solving Satisfiability of Integer Linear Arithmetic Logic. In: SAT’05. Volume 3569 of LNCS., Springer (2005) 241–256 





11. Rueß, H., Shankar, N.: Solving Linear Arithmetic Constraints. Technical Report SRI-CSL-04-01, SRI International (2004) 





12. Detlefs, D., Nelson, G., Saxe, J.B.: Simplify: A Theorem Prover for Program Checking. Technical Report HPL-2003-148, HP Labs (2003) 





13. Necula, G.: Compiling with Proofs. Technical Report CMU-CS-98-154, School of Computer Science, Carnegie Mellon University (1998) 





14. Badros, G., Borning, A., Stuckey, P.: The Cassowary Linear Arithmetic Constraint Solving Algorithm. ACM Transactions on Computer-Human Interaction (TOCHI) 8(4) (2001) 267– 306 





15. Ranise, S., Tinelli, C.: The satisfiability modulo theories library (smt-lib) (2006) Available at http://goedel.cs.uiowa.edu/smtib. 





16. Dutertre, B., de Moura, L.: Integrating Simplex with DPLL $( T )$ . Technical report, CSL-06- 01, SRI International (2006) 





17. Schrijver, A.: Theory of Linear and Integer Programming. Wiley, New York (1986) 





18. Nemhauser, G., Wosley, L.: Integer and Combinatorial Optimization. Wiley (1999) 





19. Bozzano, M., Bruttomesso, R., Cimatti, A., Junttila, T., van Rossum, P., Ranise, S., Sebastiani, R.: Efficient Satisfiability Modulo Theories via Delayed Theory Combination. In: Int. Conf. on Computer-Aided Verification (CAV). Volume 3576 of LNCS., Springer (2005) 





20. Wang, C., Ivancic, F., Ganai, M., Gupta, A.: Deciding Separation Logic Formulae with SAT and Incremental Negative Cycle Elimination. In: Logic for Programming Artificial Intelligence and Reasoning (LPAR). (2005) 





21. Nieuwenhuis, R., Oliveras, A.: DPLL(T) with Exhaustive Theory Propagation and its Application to Difference Logic. In: Int. Conference on Computer Aided Verification (CAV’05), Springer (2005) 321–334 

