# SMT-LIB Subset and Scoring Contract

## Supported Logics

The benchmark covers:

| Logic | Requirements |
|---|---|
| `QF_UF` | Equality, disequality, and uninterpreted functions. |
| `QF_LRA` | Exact rational linear real arithmetic. |
| `QF_LIA` | Integer linear constraints, search, cuts, or branch-and-bound. |
| `QF_UFLRA` | Combination of UF and real arithmetic with shared equalities. |

Inputs are quantifier-free and contain exactly one `check-sat`.

## Commands

Supported commands:

```smt2
(set-logic <Logic>)
(declare-const <name> <sort>)
(declare-fun <name> (<sort> ...) <sort>)
(define-fun <name> ((<arg> <sort>) ...) <sort> <term>)
(assert <term>)
(check-sat)
(exit)
```

You may treat `set-info` and `set-option` as no-ops. Scoring inputs do not require `get-model`, `push`, `pop`, arrays, bit-vectors, strings, floating point, nonlinear arithmetic, datatypes, optimization, interpolation, or incremental solving.

## Sorts and Terms

Supported sorts are `Bool`, `Int`, and `Real`. In `QF_UF`, `Int` and `Real` may appear only as uninterpreted carrier sorts with no arithmetic.

Boolean and common term constructs:

```smt2
true false
(not p)
(and p q ...)
(or p q ...)
(=> p q)
(ite c t e)
(= a b)
(distinct a b ...)
```

Arithmetic is linear:

```smt2
(+ a b ...)
(- a b)
(- a)
(* c x)
(* x c)
(/ x c)
(< a b)
(> a b)
(<= a b)
(>= a b)
```

Use exact integer/rational arithmetic. Numeric literals may be integers, decimals, unary negatives such as `(- 3)`, `-3` style literals, or rationals such as `(/ 7 2)`.

Assertions may contain `let` and annotated terms like `(! term :named name)`.

## Output

For SAT, the first non-empty line must be `sat`, followed by a JSON object with a `values` object:

```text
sat
{"values":{"x":"3","r":"(/ 7 2)","b":"true","a":"@a","(f a)":"@fa"}}
```

Keys are SMT-LIB symbols or canonical ground terms that appear in the assertions. Values are SMT-LIB literals encoded as strings:

```text
Bool: true, false
Int: 0, -3, 42
Real: 0, -2, 1.5, (/ 7 2)
UF/carrier values: stable labels such as @a, @fa
```

For uninterpreted functions, provide values for ground applications needed to evaluate the assertions, such as `"(f a)"`. The evaluator checks every assertion under the witness and enforces congruence.

For UNSAT or UNKNOWN, stdout must contain exactly one non-empty line:

```text
unsat
```

or:

```text
unknown
```

Debug logs must go to stderr.

## Scoring

Difficulty-weighted final score:

```text
FinalScore = 100 * (
    0.10 * Score_easy
  + 0.20 * Score_medium
  + 0.70 * Score_hard
)
```

SAT cases receive full credit only when the `sat` label is paired with a valid JSON model witness. An invalid or missing model receives 0 for that case.

UNSAT status-only output is accepted as formatted output, but because no proof certificate is required, it receives only capped partial credit on true UNSAT cases. In the provided evaluator this cap is `0.20` case credit. `unknown`, timeout, malformed output, wrong status, and invalid SAT models receive 0.

Official hidden scoring uses a 60 second per-case timeout, 4 evaluator workers, satisfiability-preserving perturbation with a private salt, and a 7200 second wall-clock budget.

## Restrictions

Do not call, bundle, link, or wrap external SAT/SMT solvers such as Z3, cvc5, CVC4, Yices, MathSAT, Boolector, Bitwuzla, OpenSMT, PySMT, or remote solver services.

Do not hardcode public answers or use benchmark file names, paths, hashes, manifests, expected-answer files, file sizes, assertion counts, operator histograms, logic-specific priors, family/template markers, or other benchmark fingerprints to choose `sat` or `unsat`.

Submissions should implement semantic SMT reasoning. Strategies based on all-UNSAT, majority-status, or public-feature classification are invalid for the task goal and are intentionally low-scoring under hidden evaluation.
