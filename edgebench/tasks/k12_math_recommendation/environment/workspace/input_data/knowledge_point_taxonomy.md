# High School Math Knowledge Point System & Typical Error Types

This file describes the knowledge points (kp_id = 1 ~ 50) used in the task, including their names, chapters, expected mastery grade, and typical error types. Agents can use this file to engineer features or design interpretable rules.

## Knowledge Point Hierarchy

Organized in three levels: **chapter -> section -> knowledge point (kp)**.

### Compulsory 1: Sets & Functions (kp_id 1-10)
| kp_id | Name | Typical Errors |
|---|---|---|
| 1 | Basic concepts and operations of sets | Confusing empty set with {0}; complement errors |
| 2 | Domain and range of functions | Missing domain restrictions from denominators/radicals; nested composite function domain errors |
| 3 | Monotonicity of functions | Mixing counterexample/definition methods; misidentifying monotone interval unions |
| 4 | Parity of functions | Ignoring domain asymmetry; misjudging parity of composite functions |
| 5 | Properties of exponential functions | Reversing monotonicity for base <1 vs >1 |
| 6 | Properties of logarithmic functions | Misusing change-of-base formula; sign errors in log operations |
| 7 | Properties of power functions | Domain errors for fractional exponents |
| 8 | Function graph transformations | Reversing horizontal shift direction; misunderstanding scaling coefficients |
| 9 | Function zeros and equation roots | Incomplete conditions for the zero-existence theorem |
| 10 | Inverse function concept | Forgetting domain-range swap |

### Compulsory 2: Geometry (kp_id 11-20)
| kp_id | Name | Typical Errors |
|---|---|---|
| 11 | Spatial solid structures | Missing coefficient in oblique axonometric drawing |
| 12 | Three-view identification | Confusing front view with side view |
| 13 | Point-line-plane positional relationships | Errors in skew line determination |
| 14 | Line-plane parallelism | Incomplete theorem conditions |
| 15 | Line-plane perpendicularity | Errors applying the three-perpendicular theorem |
| 16 | Dihedral angles | Errors constructing the plane angle |
| 17 | Line equations | Missing case when slope is undefined |
| 18 | Circles and equations | Errors completing the square for center and radius |
| 19 | Line-circle positional relationships | Distance formula errors |
| 20 | Spatial rectangular coordinate system | Wrong coordinate axis direction |

### Compulsory 3 & 4: Trigonometric Functions & Sequences (kp_id 21-30)
| kp_id | Name | Typical Errors |
|---|---|---|
| 21 | Arbitrary angles and radian measure | Degree-radian conversion errors |
| 22 | Definition of trigonometric functions | Wrong quadrant sign determination |
| 23 | Same-angle trigonometric identities | Missing sign check when taking square roots |
| 24 | Trigonometric reduction formulas | Quadrant-sign mismatch |
| 25 | Trig function graph properties | Confusing amplitude, period, and phase |
| 26 | Sum and difference formulas | Sign errors; expansion errors |
| 27 | Double-angle and half-angle formulas | Wrong coefficient in 1-cos2x |
| 28 | Sequence concepts and general terms | Missing n=1 special case when deriving a_n from S_n |
| 29 | Arithmetic sequences | Memorizing general term or sum formula incorrectly |
| 30 | Geometric sequences | Missing special case when common ratio is 1 |

### Compulsory 5: Solving Triangles & Inequalities (kp_id 31-40)
| kp_id | Name | Typical Errors |
|---|---|---|
| 31 | Law of sines | Missing "larger side opposite larger angle" condition |
| 32 | Law of cosines | Wrong substitution order in formula |
| 33 | Comprehensive triangle solving | Missing obtuse angle determination |
| 34 | Quadratic inequalities | Missing discriminant case discussion |
| 35 | Rational inequalities | Missing denominator sign discussion |
| 36 | Absolute value inequalities | Incomplete case analysis |
| 37 | AM-GM inequality | Missing equality condition |
| 38 | Linear programming | Drawing feasible region incorrectly |
| 39 | Vector concepts | Ignoring zero vector direction |
| 40 | Plane vector operations | Missing sign in dot product |

### Elective: Derivatives, Statistics & Probability (kp_id 41-50)
| kp_id | Name | Typical Errors |
|---|---|---|
| 41 | Definition and geometric meaning of derivatives | Point-slope form errors for tangent lines |
| 42 | Derivatives of basic elementary functions | Chain rule errors for composite functions |
| 43 | Derivative operation rules | Quotient rule formula errors |
| 44 | Derivatives and monotonicity | Failing to check points where derivative equals zero |
| 45 | Derivatives, extrema and absolute values | Missing endpoint values |
| 46 | Definite integrals | Wrong order of upper/lower limit substitution |
| 47 | Classical probability | Failing to verify equal-likelihood condition |
| 48 | Geometric probability | Wrong choice of measure |
| 49 | Conditional probability | Confusing P(A|B) with P(AB) |
| 50 | Normal distribution | Errors applying the 3σ rule |

## Error Type Categories (for diagnostic reference)

1. **Conceptual confusion**: Imprecise understanding of definitions and theorem conditions.
2. **Formula errors**: Wrong signs or coefficients in formulas.
3. **Incomplete case analysis**: Not enumerating all cases.
4. **Computational errors**: Substitution and arithmetic mistakes.
5. **Misreading the problem**: Misinterpreting problem conditions.
6. **Wrong method selection**: Choosing a suboptimal method leading to unnecessary complexity.
7. **Non-standard expression**: Correct result but formatting issues.

## Prerequisite Relationships

The `prerequisite_kp_ids` column in `knowledge_graph.csv` gives the direct prerequisites for each knowledge point (e.g., kp_26 "Sum and difference formulas" has prerequisite kp_24 "Reduction formulas"). Transitive prerequisites can be obtained via graph traversal. Instructional design constraints require that when recommending a question, the student's mastery of its **direct prerequisites** should be ≥ 0.3.
