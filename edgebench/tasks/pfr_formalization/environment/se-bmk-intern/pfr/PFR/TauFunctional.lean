module

public import Mathlib.MeasureTheory.Measure.Prokhorov
public import PFR.ForMathlib.Entropy.RuzsaDist

/-!
# The tau functional

Definition of the tau functional and basic facts

## Main definitions:

* `η`: $1/9$
* `τ`: The tau functional $\tau[X_1; X_2] = d[X_1; X_2] + \eta d[X^0_1; X_1] + \eta d[X^0_2; X_2].$

## Main results

* `tau_minimizer_exists`: A pair of random variables minimizing $\tau$ exists.
* `condRuzsaDistance_ge_of_min`: If $X_1,X_2$ is a tau-minimizer with $k = d[X_1;X_2]$,
  then $d[X'_1|Z, X'_2|W]$ is at least
  $$k - \eta (d[X^0_1;X'_1|Z] - d[X^0_1;X_1] ) - \eta (d[X^0_2;X'_2|W] - d[X^0_2;X_2] )$$
  for any $X'_1, Z, X'_2, W$.
-/

@[expose] public section

open MeasureTheory ProbabilityTheory
universe uG

variable (Ω₀₁ Ω₀₂ : Type*) [MeasureSpace Ω₀₁] [MeasureSpace Ω₀₂]
  [IsProbabilityMeasure (ℙ : Measure Ω₀₁)] [IsProbabilityMeasure (ℙ : Measure Ω₀₂)]
variable (G : Type uG) [AddCommGroup G] [Finite G] [MeasurableSpace G]

/-- A structure that packages all the fixed information in the main argument. In this way, when
defining the τ functional, we will only only need to refer to the package once in the notation
instead of stating the reference spaces, the reference measures and the reference random
variables.

The η parameter has now been incorporated into the package, in preparation for being able to
manipulate the package. -/
structure refPackage where
  /-- The first variable in a package. -/
  X₀₁ : Ω₀₁ → G
  /-- The second variable in a package. -/
  X₀₂ : Ω₀₂ → G
  hmeas1 : Measurable X₀₁
  hmeas2 : Measurable X₀₂
  /-- The constant that parameterizes how good the package is. The argument only works for
  small enough `η`, typically `≤ 1/9` or `< 1/8`. -/
  η : ℝ
  hη : 0 < η
  hη' : 8 * η ≤ 1

variable (p : refPackage Ω₀₁ Ω₀₂ G)
variable {Ω₀₁ Ω₀₂ G}

variable {Ω Ω' Ω₁ Ω₂ Ω'₁ Ω'₂ S T : Type*}

/-- If $X_1,X_2$ are two $G$-valued random variables, then
$$ \tau[X_1; X_2] := d[X_1; X_2] + \eta d[X^0_1; X_1] + \eta d[X^0_2; X_2].$$
Here, $X^0_1$ and $X^0_2$ are two random variables fixed once and for all in most of the argument.
To lighten notation, We package `X^0_1` and `X^0_2` in a single object named `p`.

We denote it as `τ[X₁ ; μ₁ # X₂ ; μ₂ | p]` where `p` is a fixed package containing the information
of the reference random variables. When the measurable spaces have a canonical measure `ℙ`, we
can use `τ[X₁ # X₂ | p]`
-/
noncomputable def tau {Ω₁ Ω₂ : Type*} [MeasurableSpace Ω₁] [MeasurableSpace Ω₂]
    (X₁ : Ω₁ → G) (X₂ : Ω₂ → G) (μ₁ : Measure Ω₁) (μ₂ : Measure Ω₂) : ℝ :=
  d[X₁ ; μ₁ # X₂ ; μ₂] + p.η * d[p.X₀₁ ; ℙ # X₁ ; μ₁] + p.η * d[p.X₀₂ ; ℙ # X₂ ; μ₂]

@[inherit_doc tau]
notation3:max "τ[" X₁ " ; " μ₁ " # " X₂ " ; " μ₂ " | " p"]" => tau p X₁ X₂ μ₁ μ₂

@[inherit_doc tau]
notation3:max "τ[" X₁ " # " X₂ " | " p"]" =>
  tau p X₁ X₂ MeasureTheory.MeasureSpace.volume MeasureTheory.MeasureSpace.volume

omit [IsProbabilityMeasure (ℙ : Measure Ω₀₁)] [IsProbabilityMeasure (ℙ : Measure Ω₀₂)]
[Finite G] in

/-- Property recording the fact that two random variables minimize the tau functional. Expressed
in terms of measures on the group to avoid quantifying over all spaces, but this implies comparison
with any pair of random variables, see Lemma `is_tau_min`. -/
def tau_minimizes {Ω : Type*} [MeasureSpace Ω] (X₁ : Ω → G) (X₂ : Ω → G) : Prop :=
  ∀ (ν₁ : Measure G) (ν₂ : Measure G), IsProbabilityMeasure ν₁ → IsProbabilityMeasure ν₂ →
      τ[X₁ # X₂ | p] ≤ τ[id ; ν₁ # id ; ν₂ | p]
