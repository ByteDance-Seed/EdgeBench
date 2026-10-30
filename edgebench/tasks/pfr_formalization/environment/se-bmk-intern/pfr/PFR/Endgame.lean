module

public import PFR.FirstEstimate
public import PFR.SecondEstimate

/-!
# Endgame

The endgame on tau-minimizers.

Assumptions:

* $X_1, X_2$ are tau-minimizers
* $X_1, X_2, \tilde X_1, \tilde X_2$ be independent random variables, with $X_1,\tilde X_1$ copies
    of $X_1$ and $X_2,\tilde X_2$ copies of $X_2$.
* $d[X_1;X_2] = k$
* $U := X_1 + X_2$
* $V := \tilde X_1 + X_2$
* $W := X_1 + \tilde X_1$
* $S := X_1 + X_2 + \tilde X_1 + \tilde X_2$.
* $I_1 := I[U : V | S]$
* $I_2 := I[U : W | S]$
* $I_3 := I[V : W | S]$ (not explicitly defined in Lean)

# Main results:

* `sum_condMutual_le` : An upper bound on the total conditional mutual information $I_1+I_2+I_3$.
* `sum_dist_diff_le`: A sum of the "costs" of $U$, $V$, $W$.
* `construct_good`: A construction of two random variables with small Ruzsa distance between them
  given some random variables with control on total cost, as well as total mutual information.
-/

public section

open MeasureTheory ProbabilityTheory

variable {G : Type*} [AddCommGroup G] [Finite G] [hG : MeasurableSpace G]
  [MeasurableSingletonClass G]

variable {Ω₀₁ Ω₀₂ : Type*} [MeasureSpace Ω₀₁] [MeasureSpace Ω₀₂]
  [IsProbabilityMeasure (ℙ : Measure Ω₀₁)] [IsProbabilityMeasure (ℙ : Measure Ω₀₂)]

variable (p : refPackage Ω₀₁ Ω₀₂ G)

variable {Ω : Type*} [mΩ : MeasureSpace Ω]

variable (X₁ X₂ X₁' X₂' : Ω → G)
  (hX₁ : Measurable X₁) (hX₂ : Measurable X₂) (hX₁' : Measurable X₁') (hX₂' : Measurable X₂')

variable (h₁ : IdentDistrib X₁ X₁') (h₂ : IdentDistrib X₂ X₂')

variable (h_indep : iIndepFun ![X₁, X₂, X₁', X₂'])

variable (h_min : tau_minimizes p X₁ X₂)

/-- `k := d[X₁ # X₂]`, the Ruzsa distance `rdist` between X₁ and X₂. -/
local notation3 "k" => d[X₁ # X₂]

/-- `U := X₁ + X₂` -/
local notation3 "U" => X₁ + X₂

/-- `V := X₁' + X₂` -/
local notation3 "V" => X₁' + X₂

/-- `W := X₁' + X₁` -/
local notation3 "W" => X₁' + X₁

/-- `S := X₁ + X₂ + X₁' + X₂'` -/
local notation3 "S" => X₁ + X₂ + X₁' + X₂'

/-- `I₁ := I[U : V | S]`, the conditional mutual information of `U = X₁ + X₂` and `V = X₁' + X₂`
given the quadruple sum `S = X₁ + X₂ + X₁' + X₂'`. -/
local notation3 "I₁" => I[U : V | S]

/-- `I₂ := I[U : W | S]`, the conditional mutual information of `U = X₁ + X₂` and `W = X₁' + X₁`
given the quadruple sum `S = X₁ + X₂ + X₁' + X₂'`. -/
local notation3 "I₂" => I[U : W | S]

--(Mantas) this times out in the proof below

include h_indep hX₁ hX₂ hX₁' hX₂' h₁ in
/-- The quantity `I_3 = I[V:W|S]` is equal to `I_2`. -/
lemma I₃_eq [IsProbabilityMeasure (ℙ : Measure Ω)] : I[V : W | S] = I₂ := by
  sorry

include h_indep hX₁ hX₂ hX₁' hX₂' h₁ h₂ h_min in
/--
`I[U : V | S] + I[V : W | S] + I[W : U | S]` is less than or equal to
`6 * η * k - (1 - 5 * η) / (1 - η) * (2 * η * k - I₁)`.
-/
lemma sum_condMutual_le [Module (ZMod 2) G] [IsProbabilityMeasure (ℙ : Measure Ω)] :
    I[U : V | S] + I[V : W | S] + I[W : U | S]
      ≤ 6 * p.η * k - (1 - 5 * p.η) / (1 - p.η) * (2 * p.η * k - I₁) := by
  sorry

local notation3:max "c[" A "; " μ " # " B " ; " μ' "]" =>
  d[p.X₀₁; ℙ # A; μ] - d[p.X₀₁ # X₁] + (d[p.X₀₂; ℙ # B; μ'] - d[p.X₀₂ # X₂])

local notation3:max "c[" A " # " B "]" =>
  d[p.X₀₁ # A] - d[p.X₀₁ # X₁] + (d[p.X₀₂ # B] - d[p.X₀₂ # X₂])

local notation3:max "c[" A " | " B " # " C " | " D "]" =>
  d[p.X₀₁ # A|B] - d[p.X₀₁ # X₁] + (d[p.X₀₂ # C|D] - d[p.X₀₂ # X₂])

/--
$$ \sum_{i=1}^2 \sum_{A\in\{U,V,W\}} \big(d[X^0_i;A|S] - d[X^0_i;X_i]\big)$$
is less than or equal to
$$ \leq (6 - 3\eta) k + 3(2 \eta k - I_1).$$
-/
lemma sum_dist_diff_le [IsProbabilityMeasure (ℙ : Measure Ω)] [Module (ZMod 2) G] :
    c[U|S # U|S] + c[V|S # V|S] + c[W|S # W|S] ≤ (6 - 3 * p.η)*k + 3 * (2*p.η*k - I₁) := by
  sorry

section construct_good

variable {Ω' : Type*} [MeasureSpace Ω']
variable {T₁ T₂ T₃ : Ω' → G} (hT : T₁ + T₂ + T₃ = 0)
variable (hT₁ : Measurable T₁) (hT₂ : Measurable T₂) (hT₃ : Measurable T₃)
  [IsProbabilityMeasure (ℙ : Measure Ω')] [Module (ZMod 2) G]
  --[IsProbabilityMeasure (ℙ : Measure Ω)]

local notation3:max "δ[" μ "]" => I[T₁ : T₂ ; μ] + I[T₂ : T₃ ; μ] + I[T₃ : T₁ ; μ]
local notation3:max "δ" => I[T₁ : T₂] + I[T₂ : T₃] + I[T₃ : T₁]

local notation3:max "ψ[" A " # " B "]" => d[A # B] + p.η * (c[A # B])
local notation3:max "ψ[" A "; " μ " # " B " ; " μ' "]" =>
  d[A ; μ # B ; μ'] + p.η * c[A ; μ # B ; μ']

include hT₁ hT₂ hT₃ hT h_min in
/-- If $T_1, T_2, T_3$ are $G$-valued random variables with $T_1+T_2+T_3=0$ holds identically and
$$ \delta := \sum_{1 \leq i < j \leq 3} I[T_i;T_j]$$
Then there exist random variables $T'_1, T'_2$ such that
$$ d[T'_1;T'_2] + \eta (d[X_1^0;T'_1] - d[X_1^0;X_1]) + \eta(d[X_2^0;T'_2] - d[X_2^0;X_2]) $$
is at most
$$ \delta + \eta ( d[X^0_1;T_1]-d[X^0_1;X_1]) + \eta (d[X^0_2;T_2]-d[X^0_2;X_2]) $$
$$ + \tfrac12 \eta I[T_1: T_3] + \tfrac12 \eta I[T_2: T_3].$$
-/
lemma construct_good_prelim :
    k ≤ δ + p.η * c[T₁ # T₂] + p.η * (I[T₁: T₃] + I[T₂ : T₃])/2 := by
  sorry

include hT₁ hT₂ hT₃ hT h_min in
/-- If $T_1, T_2, T_3$ are $G$-valued random variables with $T_1+T_2+T_3=0$ holds identically and
-
$$ \delta := \sum_{1 \leq i < j \leq 3} I[T_i;T_j]$$

Then there exist random variables $T'_1, T'_2$ such that

$$ d[T'_1;T'_2] + \eta (d[X_1^0;T'_1] - d[X_1^0;X _1]) + \eta(d[X_2^0;T'_2] - d[X_2^0;X_2])$$

is at most

$$\delta + \frac{\eta}{3} \biggl( \delta + \sum_{i=1}^2 \sum_{j = 1}^3
    (d[X^0_i;T_j] - d[X^0_i; X_i]) \biggr).$$
-/
lemma construct_good :
    k ≤ δ + (p.η/3) * (δ + c[T₁ # T₁] + c[T₂ # T₂] + c[T₃ # T₃]) := by
  sorry

include hT₁ hT₂ hT₃ hT h_min in
omit [IsProbabilityMeasure (ℙ : Measure Ω')] in
lemma construct_good' (μ : Measure Ω') [IsProbabilityMeasure μ] :
    k ≤ δ[μ] + (p.η/3) * (δ[μ] + c[T₁ ; μ # T₁ ; μ] + c[T₂ ; μ # T₂ ; μ] + c[T₃ ; μ # T₃ ; μ]) := by
  sorry

variable {R : Ω' → G} (hR : Measurable R)
local notation3:max "δ'" => I[T₁ : T₂|R] + I[T₂ : T₃|R] + I[T₃ : T₁|R]

lemma cond_construct_good :
    k ≤ δ' + (p.η/3) * (δ' + c[T₁ | R # T₁ | R] + c[T₂ | R # T₂ | R] + c[T₃ | R # T₃ | R]) := by
  sorry

end construct_good

include hX₁ hX₂ h_min h₁ h₂ h_indep hX₁ hX₂ hX₁' hX₂' in
/-- If `d[X₁ ; X₂] > 0` then there are `G`-valued random variables `X₁', X₂'` such that
Phrased in the contrapositive form for convenience of proof. -/
theorem tau_strictly_decreases_aux [IsProbabilityMeasure (ℙ : Measure Ω)] [Module (ZMod 2) G]
    (hpη : p.η = 1 / 9) : d[X₁ # X₂] = 0 := by
  sorry
