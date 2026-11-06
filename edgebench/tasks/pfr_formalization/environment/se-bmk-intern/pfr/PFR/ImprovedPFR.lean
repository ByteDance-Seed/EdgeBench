module

public import PFR.Main

/-!
# Improved PFR

An improvement to PFR that lowers the exponent from 12 to 11.
-/

public section

/- In this file the power notation will always mean the base and exponent are real numbers. -/
local macro_rules | `($x ^ $y) => `(HPow.hPow ($x : ℝ) ($y : ℝ))

open MeasureTheory ProbabilityTheory

section GeneralInequality
variable {G : Type*} [AddCommGroup G] [Finite G] [hG : MeasurableSpace G]
  [MeasurableSingletonClass G] [Module (ZMod 2) G] [MeasurableAdd₂ G]

variable {Ω : Type*} [MeasureSpace Ω] [IsProbabilityMeasure (ℙ : Measure Ω)]

variable {Ω₀ : Type*} [MeasureSpace Ω₀] [IsProbabilityMeasure (ℙ : Measure Ω₀)]

variable (Y : Ω₀ → G) (hY : Measurable Y)

variable (Z₁ Z₂ Z₃ Z₄ : Ω → G)
  (hZ₁ : Measurable Z₁) (hZ₂ : Measurable Z₂) (hZ₃ : Measurable Z₃) (hZ₄ : Measurable Z₄)

variable (h_indep : iIndepFun ![Z₁, Z₂, Z₃, Z₄])

local notation3 "Sum" => Z₁ + Z₂ + Z₃ + Z₄

include hY hZ₁ hZ₂ hZ₃ hZ₄ h_indep in
lemma gen_ineq_aux1 :
    d[Y # Z₁ + Z₂ | ⟨Z₁ + Z₃, Sum⟩] ≤ d[Y # Z₁]
      + (d[Z₁ # Z₂] + d[Z₁ # Z₃] + d[Z₂ # Z₄] - d[Z₁ | Z₁ + Z₂ # Z₃ | Z₃ + Z₄]) / 2
      + (H[Z₁ + Z₂] - H[Z₃ + Z₄] + H[Z₂] - H[Z₁]) / 4 := by
  sorry

include hY hZ₁ hZ₂ hZ₃ hZ₄ h_indep in
lemma gen_ineq_aux2 :
    d[Y # Z₁ + Z₂ | ⟨Z₁ + Z₃, Sum⟩] ≤ d[Y # Z₁]
      + (d[Z₁ # Z₃] + d[Z₁ | Z₁ + Z₃ # Z₂ | Z₂ + Z₄]) / 2
      + (H[Z₂ | Z₂ + Z₄] - H[Z₁ | Z₁ + Z₃] + H[Z₁] - H[Z₃]) / 4 := by
  sorry

include hY hZ₁ hZ₂ hZ₃ hZ₄ h_indep in
/-- Let `Z₁, Z₂, Z₃, Z₄` be independent `G`-valued random variables, and let `Y` be another
`G`-valued random variable. Set `S := Z₁ + Z₂ + Z₃ + Z₄`. Then
`d[Y # Z₁ + Z₂ | ⟨Z₁ + Z₃, Sum⟩] - d[Y # Z₁] ≤`
`(d[Z₁ # Z₂] + 2 * d[Z₁ # Z₃] + d[Z₂ # Z₄]) / 4`
`+ (d[Z₁ | Z₁ + Z₃ # Z₂ | Z₂ + Z₄] - d[Z₁ | Z₁ + Z₂ # Z₃ | Z₃ + Z₄]) / 4`
`+ (H[Z₁ + Z₂] - H[Z₃ + Z₄] + H[Z₂] - H[Z₃] + H[Z₂ | Z₂ + Z₄] - H[Z₁ | Z₁ + Z₃]) / 8`.
-/
lemma gen_ineq_00 : d[Y # Z₁ + Z₂ | ⟨Z₁ + Z₃, Sum⟩] - d[Y # Z₁] ≤
    (d[Z₁ # Z₂] + 2 * d[Z₁ # Z₃] + d[Z₂ # Z₄]) / 4
    + (d[Z₁ | Z₁ + Z₃ # Z₂ | Z₂ + Z₄] - d[Z₁ | Z₁ + Z₂ # Z₃ | Z₃ + Z₄]) / 4
    + (H[Z₁ + Z₂] - H[Z₃ + Z₄] + H[Z₂] - H[Z₃] + H[Z₂ | Z₂ + Z₄] - H[Z₁ | Z₁ + Z₃]) / 8 := by
  sorry

include hY hZ₁ hZ₂ hZ₃ hZ₄ h_indep in
/-- Other version of `gen_ineq_00`, in which we switch to the complement in the second term. -/
lemma gen_ineq_01 : d[Y # Z₁ + Z₂ | ⟨Z₂ + Z₄, Sum⟩] - d[Y # Z₁] ≤
    (d[Z₁ # Z₂] + 2 * d[Z₁ # Z₃] + d[Z₂ # Z₄]) / 4
    + (d[Z₁ | Z₁ + Z₃ # Z₂ | Z₂ + Z₄] - d[Z₁ | Z₁ + Z₂ # Z₃ | Z₃ + Z₄]) / 4
    + (H[Z₁ + Z₂] - H[Z₃ + Z₄] + H[Z₂] - H[Z₃] + H[Z₂ | Z₂ + Z₄] - H[Z₁ | Z₁ + Z₃]) / 8 := by
  sorry

include hY hZ₁ hZ₂ hZ₃ hZ₄ h_indep in
/-- Other version of `gen_ineq_00`, in which we switch to the complement in the first term. -/
lemma gen_ineq_10 : d[Y # Z₃ + Z₄ | ⟨Z₁ + Z₃, Sum⟩] - d[Y # Z₁] ≤
    (d[Z₁ # Z₂] + 2 * d[Z₁ # Z₃] + d[Z₂ # Z₄]) / 4
    + (d[Z₁ | Z₁ + Z₃ # Z₂ | Z₂ + Z₄] - d[Z₁ | Z₁ + Z₂ # Z₃ | Z₃ + Z₄]) / 4
    + (H[Z₁ + Z₂] - H[Z₃ + Z₄] + H[Z₂] - H[Z₃] + H[Z₂ | Z₂ + Z₄] - H[Z₁ | Z₁ + Z₃]) / 8 := by
  sorry

end GeneralInequality

section MainEstimates

open MeasureTheory ProbabilityTheory

variable {G : Type*} [AddCommGroup G] [Finite G] [hG : MeasurableSpace G]
  [MeasurableSingletonClass G] [Module (ZMod 2) G]

variable {Ω₀₁ Ω₀₂ : Type*} [MeasureSpace Ω₀₁] [MeasureSpace Ω₀₂]
  [IsProbabilityMeasure (ℙ : Measure Ω₀₁)] [IsProbabilityMeasure (ℙ : Measure Ω₀₂)]

variable {p : refPackage Ω₀₁ Ω₀₂ G}

variable {Ω : Type*} [MeasureSpace Ω] [IsProbabilityMeasure (ℙ : Measure Ω)]

variable {X₁ X₂ X₁' X₂' : Ω → G}
  (hX₁ : Measurable X₁) (hX₂ : Measurable X₂) (hX₁' : Measurable X₁') (hX₂' : Measurable X₂')

variable (h₁ : IdentDistrib X₁ X₁') (h₂ : IdentDistrib X₂ X₂')

variable (h_indep : iIndepFun ![X₁, X₂, X₂', X₁'])

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

/-- `I₁ := I[X₁ + X₂ : X₁' + X₂ | X₁ + X₂ + X₁' + X₂']`, the conditional mutual information
of `X₁ + X₂` and `X₁' + X₂` given the quadruple sum `X₁ + X₂ + X₁' + X₂'`. -/
local notation3 "I₁" => I[X₁ + X₂ : X₁' + X₂ | X₁ + X₂ + X₁' + X₂']

/-- `I₂ := I[X₁ + X₂ : X₁' + X₁ | X₁ + X₂ + X₁' + X₂']`, the conditional mutual information
of `X₁ + X₂` and `X₁' + X₁` given the quadruple sum `X₁ + X₂ + X₁' + X₂'`. -/
local notation3 "I₂" => I[X₁ + X₂ : X₁' + X₁ | X₁ + X₂ + X₁' + X₂']

local notation3:max "c[" A "; " μ " # " B " ; " μ' "]" =>
  d[p.X₀₁; ℙ # A; μ] - d[p.X₀₁ # X₁] + (d[p.X₀₂; ℙ # B; μ'] - d[p.X₀₂ # X₂])

local notation3:max "c[" A " # " B "]" =>
  d[p.X₀₁ # A] - d[p.X₀₁ # X₁] + (d[p.X₀₂ # B] - d[p.X₀₂ # X₂])

local notation3:max "c[" A " | " B " # " C " | " D "]" =>
  d[p.X₀₁ # A|B] - d[p.X₀₁ # X₁] + (d[p.X₀₂ # C|D] - d[p.X₀₂ # X₂])

section aux

variable {Ω' : Type*} [MeasureSpace Ω'] [IsProbabilityMeasure (ℙ : Measure Ω')]
variable {T₁ T₂ T₃ : Ω' → G} (hT : T₁ + T₂ + T₃ = 0)
variable (hT₁ : Measurable T₁) (hT₂ : Measurable T₂) (hT₃ : Measurable T₃)

local notation3:max "δ[" μ "]" => I[T₁ : T₂ ; μ] + I[T₂ : T₃ ; μ] + I[T₃ : T₁ ; μ]
local notation3:max "δ" => I[T₁ : T₂] + I[T₂ : T₃] + I[T₃ : T₁]

local notation3:max "ψ[" A " # " B "]" => d[A # B] + p.η * (c[A # B])
local notation3:max "ψ[" A "; " μ " # " B " ; " μ' "]" =>
  d[A ; μ # B ; μ'] + p.η * c[A ; μ # B ; μ']

include hT hT₁ hT₂ hT₃ h_min in
omit [IsProbabilityMeasure (ℙ : Measure Ω₀₁)] [IsProbabilityMeasure (ℙ : Measure Ω₀₂)]
[IsProbabilityMeasure (ℙ : Measure Ω)] in
/-- For any $T_1, T_2, T_3$ adding up to $0$, then $k$ is at most
$$ \delta + \eta (d[X^0_1;T_1|T_3]-d[X^0_1;X_1]) + \eta (d[X^0_2;T_2|T_3]-d[X^0_2;X_2])$$
where $\delta = I[T₁ : T₂ ; μ] + I[T₂ : T₃ ; μ] + I[T₃ : T₁ ; μ]$. -/
lemma construct_good_prelim' : k ≤ δ + p.η * c[T₁ | T₃ # T₂ | T₃] := by
  sorry

open Module

include hT hT₁ hT₂ hT₃ h_min in
omit [IsProbabilityMeasure (ℙ : Measure Ω₀₁)] [IsProbabilityMeasure (ℙ : Measure Ω₀₂)]
[IsProbabilityMeasure (ℙ : Measure Ω)] in
/-- In fact $k$ is at most
 $$ \delta + \frac{\eta}{6} \sum_{i=1}^2 \sum_{1 \leq j,l \leq 3; j \neq l}
     (d[X^0_i;T_j|T_l] - d[X^0_i; X_i]).$$
-/
lemma construct_good_improved' :
    k ≤ δ + (p.η / 6) *
     ((d[p.X₀₁ # T₁ | T₂] - d[p.X₀₁ # X₁]) + (d[p.X₀₁ # T₁ | T₃] - d[p.X₀₁ # X₁])
    + (d[p.X₀₁ # T₂ | T₁] - d[p.X₀₁ # X₁]) + (d[p.X₀₁ # T₂ | T₃] - d[p.X₀₁ # X₁])
    + (d[p.X₀₁ # T₃ | T₁] - d[p.X₀₁ # X₁]) + (d[p.X₀₁ # T₃ | T₂] - d[p.X₀₁ # X₁])
    + (d[p.X₀₂ # T₁ | T₂] - d[p.X₀₂ # X₂]) + (d[p.X₀₂ # T₁ | T₃] - d[p.X₀₂ # X₂])
    + (d[p.X₀₂ # T₂ | T₁] - d[p.X₀₂ # X₂]) + (d[p.X₀₂ # T₂ | T₃] - d[p.X₀₂ # X₂])
    + (d[p.X₀₂ # T₃ | T₁] - d[p.X₀₂ # X₂]) + (d[p.X₀₂ # T₃ | T₂] - d[p.X₀₂ # X₂])) := by
  sorry

include h_min in
omit [IsProbabilityMeasure (ℙ : Measure Ω₀₁)] [IsProbabilityMeasure (ℙ : Measure Ω₀₂)]
[IsProbabilityMeasure (ℙ : Measure Ω)] in
/-- Rephrase `construct_good_improved'` with an explicit probability measure, as we will
apply it to (varying) conditional measures. -/
lemma construct_good_improved'' {Ω' : Type*} [MeasurableSpace Ω'] (μ : Measure Ω')
    [IsProbabilityMeasure μ] {T₁ T₂ T₃ : Ω' → G}
    (hT : T₁ + T₂ + T₃ = 0) (hT₁ : Measurable T₁) (hT₂ : Measurable T₂) (hT₃ : Measurable T₃) :
    k ≤ I[T₁ : T₂ ; μ] + I[T₂ : T₃ ; μ] + I[T₃ : T₁ ; μ] + (p.η / 6) *
    ((d[p.X₀₁ ; ℙ # T₁ | T₂ ; μ] - d[p.X₀₁ # X₁]) + (d[p.X₀₁ ; ℙ # T₁ | T₃ ; μ] - d[p.X₀₁ # X₁])
      + (d[p.X₀₁ ; ℙ # T₂ | T₁ ; μ] - d[p.X₀₁ # X₁]) + (d[p.X₀₁ ; ℙ # T₂ | T₃ ; μ] - d[p.X₀₁ # X₁])
      + (d[p.X₀₁ ; ℙ # T₃ | T₁ ; μ] - d[p.X₀₁ # X₁]) + (d[p.X₀₁ ; ℙ # T₃ | T₂ ; μ] - d[p.X₀₁ # X₁])
      + (d[p.X₀₂ ; ℙ # T₁ | T₂ ; μ] - d[p.X₀₂ # X₂]) + (d[p.X₀₂ ; ℙ # T₁ | T₃ ; μ] - d[p.X₀₂ # X₂])
      + (d[p.X₀₂ ; ℙ # T₂ | T₁ ; μ] - d[p.X₀₂ # X₂]) + (d[p.X₀₂ ; ℙ # T₂ | T₃ ; μ] - d[p.X₀₂ # X₂])
      + (d[p.X₀₂ ; ℙ # T₃ | T₁ ; μ] - d[p.X₀₂ # X₂]) + (d[p.X₀₂ ; ℙ # T₃ | T₂ ; μ] - d[p.X₀₂ # X₂]))
    := by
  sorry

end aux

include hX₁ hX₂ hX₁' hX₂' h_min in
omit [IsProbabilityMeasure (ℙ : Measure Ω₀₁)] [IsProbabilityMeasure (ℙ : Measure Ω₀₂)] in
/-- $k$ is at most
$$ \leq I(U : V \, | \, S) + I(V : W \, | \,S) + I(W : U \, | \, S) + \frac{\eta}{6}
\sum_{i=1}^2 \sum_{A,B \in \{U,V,W\}: A \neq B} (d[X^0_i;A|B,S] - d[X^0_i; X_i]).$$
-/
lemma averaged_construct_good :
    k ≤ (I[U : V | S] + I[V : W | S] + I[W : U | S]) + p.η / 6 *
      (((d[p.X₀₁ # U | ⟨V, S⟩] - d[p.X₀₁ # X₁]) + (d[p.X₀₁ # U | ⟨W, S⟩] - d[p.X₀₁ # X₁])
      + (d[p.X₀₁ # V | ⟨U, S⟩] - d[p.X₀₁ # X₁]) + (d[p.X₀₁ # V | ⟨W, S⟩] - d[p.X₀₁ # X₁])
      + (d[p.X₀₁ # W | ⟨U, S⟩] - d[p.X₀₁ # X₁]) + (d[p.X₀₁ # W | ⟨V, S⟩] - d[p.X₀₁ # X₁]))
      + ((d[p.X₀₂ # U | ⟨V, S⟩] - d[p.X₀₂ # X₂]) + (d[p.X₀₂ # U | ⟨W, S⟩] - d[p.X₀₂ # X₂])
      + (d[p.X₀₂ # V | ⟨U, S⟩] - d[p.X₀₂ # X₂]) + (d[p.X₀₂ # V | ⟨W, S⟩] - d[p.X₀₂ # X₂])
      + (d[p.X₀₂ # W | ⟨U, S⟩] - d[p.X₀₂ # X₂]) + (d[p.X₀₂ # W | ⟨V, S⟩] - d[p.X₀₂ # X₂])))
    := by
  sorry

variable (p)

include hX₁ hX₂ hX₁' hX₂' h_indep h₁ h₂ in
omit [IsProbabilityMeasure (ℙ : Measure Ω₀₂)] in
lemma dist_diff_bound_1 :
      (d[p.X₀₁ # U | ⟨V, S⟩] - d[p.X₀₁ # X₁]) + (d[p.X₀₁ # U | ⟨W, S⟩] - d[p.X₀₁ # X₁])
    + (d[p.X₀₁ # V | ⟨U, S⟩] - d[p.X₀₁ # X₁]) + (d[p.X₀₁ # V | ⟨W, S⟩] - d[p.X₀₁ # X₁])
    + (d[p.X₀₁ # W | ⟨U, S⟩] - d[p.X₀₁ # X₁]) + (d[p.X₀₁ # W | ⟨V, S⟩] - d[p.X₀₁ # X₁])
    ≤ (16 * k + 6 * d[X₁ # X₁] + 2 * d[X₂ # X₂]) / 4 + (H[X₁ + X₁'] - H[X₂ + X₂']) / 4
      + (H[X₂ | X₂ + X₂'] - H[X₁ | X₁ + X₁']) / 4 := by
  sorry

include hX₁ hX₂ hX₁' hX₂' h₁ h₂ h_indep in
omit [IsProbabilityMeasure (ℙ : Measure Ω₀₁)] in
lemma dist_diff_bound_2 :
      ((d[p.X₀₂ # U | ⟨V, S⟩] - d[p.X₀₂ # X₂]) + (d[p.X₀₂ # U | ⟨W, S⟩] - d[p.X₀₂ # X₂])
    + (d[p.X₀₂ # V | ⟨U, S⟩] - d[p.X₀₂ # X₂]) + (d[p.X₀₂ # V | ⟨W, S⟩] - d[p.X₀₂ # X₂])
    + (d[p.X₀₂ # W | ⟨U, S⟩] - d[p.X₀₂ # X₂]) + (d[p.X₀₂ # W | ⟨V, S⟩] - d[p.X₀₂ # X₂]))
    ≤ (16 * k + 6 * d[X₂ # X₂] + 2 * d[X₁ # X₁]) / 4 + (H[X₂ + X₂'] - H[X₁ + X₁']) / 4
      + (H[X₁ | X₁ + X₁'] - H[X₂ | X₂ + X₂']) / 4 := by
  sorry

include hX₁ hX₂ hX₁' hX₂' h₁ h₂ h_indep h_min in
lemma averaged_final : k ≤ (6 * p.η * k - (1 - 5 * p.η) / (1 - p.η) * (2 * p.η * k - I₁))
    + p.η / 6 * (8 * k + 2 * (d[X₁ # X₁] + d[X₂ # X₂])) := by
  sorry

include hX₁ hX₂ hX₁' hX₂' h₁ h₂ h_indep h_min in
/-- Suppose $0 < \eta < 1/8$. Let $X_1, X_2$ be tau-minimizers. Then $d[X_1;X_2] = 0$. The proof
of this lemma uses copies `X₁', X₂'` already in the context. For a version that does not assume
these are given and constructs them instead, use `tau_strictly_decreases'`.
-/
theorem tau_strictly_decreases_aux' (hp : 8 * p.η < 1) : d[X₁ # X₂] = 0 := by
  sorry

include hX₁ hX₂ h_min in
theorem tau_strictly_decreases' (hp : 8 * p.η < 1) : d[X₁ # X₂] = 0 := by
  sorry

end MainEstimates

section EntropicPFR

open MeasureTheory ProbabilityTheory
universe uG

open scoped Topology
open Filter Set

variable {Ω₀₁ Ω₀₂ : Type*} [MeasureSpace Ω₀₁] [MeasureSpace Ω₀₂]
  [IsProbabilityMeasure (ℙ : Measure Ω₀₁)] [IsProbabilityMeasure (ℙ : Measure Ω₀₂)]

variable {G : Type uG} [AddCommGroup G] [Module (ZMod 2) G] [Finite G] [MeasurableSpace G]
  [MeasurableSingletonClass G]
variable (p : refPackage Ω₀₁ Ω₀₂ G)

/-- For `p.η ≤ 1/8`, there exist τ-minimizers `X₁, X₂` at zero Rusza distance. For `p.η < 1/8`,
all minimizers are fine, by `tau_strictly_decreases'`. For `p.η = 1/8`, we use a limit of
minimizers for `η < 1/8`, which exists by compactness. -/
lemma tau_minimizer_exists_rdist_eq_zero :
    ∃ (Ω : Type uG) (_ : MeasureSpace Ω) (X₁ : Ω → G) (X₂ : Ω → G),
      Measurable X₁ ∧ Measurable X₂ ∧ IsProbabilityMeasure (ℙ : Measure Ω) ∧ tau_minimizes p X₁ X₂
      ∧ d[X₁ # X₂] = 0 := by
  sorry

/-- `entropic_PFR_conjecture_improv`: For two $G$-valued random variables $X^0_1, X^0_2$, there is
some subgroup $H \leq G$ such that $d[X^0_1;U_H] + d[X^0_2;U_H] \le 10 d[X^0_1;X^0_2]$. -/
theorem entropic_PFR_conjecture_improv (hpη : p.η = 1 / 8) :
    ∃ (H : Submodule (ZMod 2) G) (Ω : Type uG) (mΩ : MeasureSpace Ω) (U : Ω → G),
    IsProbabilityMeasure (ℙ : Measure Ω) ∧ Measurable U ∧
    IsUniform H U ∧ d[p.X₀₁ # U] + d[p.X₀₂ # U] ≤ 10 * d[p.X₀₁ # p.X₀₂] := by
  sorry

/-- `entropic_PFR_conjecture_improv'`: For two $G$-valued random variables $X^0_1, X^0_2$, there is
some subgroup $H \leq G$ such that $d[X^0_1;U_H] + d[X^0_2;U_H] \le 10 d[X^0_1;X^0_2]$., and
d[X^0_1; U_H] and d[X^0_2; U_H] are at most 5/2 * d[X^0_1;X^0_2] -/
theorem entropic_PFR_conjecture_improv' (hpη : p.η = 1 / 8) :
    ∃ H : AddSubgroup G, ∃ Ω : Type uG, ∃ mΩ : MeasureSpace Ω, ∃ U : Ω → G,
    IsProbabilityMeasure (ℙ : Measure Ω) ∧ Measurable U ∧
    IsUniform H U ∧ d[p.X₀₁ # U] + d[p.X₀₂ # U] ≤ 10 * d[p.X₀₁ # p.X₀₂] ∧ d[p.X₀₁ # U]
      ≤ 11/2 * d[p.X₀₁ # p.X₀₂] ∧ d[p.X₀₂ # U] ≤ 11/2 * d[p.X₀₁ # p.X₀₂] := by
  sorry

end EntropicPFR

section PFR

open Pointwise Set MeasureTheory ProbabilityTheory Real Fintype Function

variable {G Ω : Type*} [AddCommGroup G] [Module (ZMod 2) G] [Finite G]
    {A B : Set G} {K : ℝ}

/-- Auxiliary statement towards the polynomial Freiman-Ruzsa (PFR) conjecture: if $A$ is a subset of
an elementary abelian 2-group of doubling constant at most $K$, then there exists a subgroup $H$
such that $A$ can be covered by at most $K^6 |A|^{1/2} / |H|^{1/2}$ cosets of $H$, and $H$ has
the same cardinality as $A$ up to a multiplicative factor $K^10$. -/
lemma PFR_conjecture_improv_aux (h₀A : A.Nonempty) (hA : Nat.card (A + A) ≤ K * A.ncard) :
    ∃ (H : Submodule (ZMod 2) G) (c : Set G),
      Nat.card c ≤ K ^ 6 * A.ncard ^ (1/2) * (H : Set G).ncard ^ (-1/2) ∧
      (H : Set G).ncard ≤ K ^ 10 * A.ncard ∧
      A.ncard ≤ K ^ 10 * (H : Set G).ncard ∧ A ⊆ c + H := by
  sorry

/-- The **polynomial Freiman-Ruzsa (PFR) conjecture**: if $A$ is a subset of an elementary abelian
2-group of doubling constant at most $K$, then $A$ can be covered by at most $2K^{11$} cosets of
a subgroup of cardinality at most $|A|$. -/
theorem PFR_conjecture_improv (h₀A : A.Nonempty) (hA : Nat.card (A + A) ≤ K * A.ncard) :
     ∃ (H : Submodule (ZMod 2) G) (c : Set G),
      Nat.card c < 2 * K ^ 11 ∧ (H : Set G).ncard ≤ A.ncard ∧ A ⊆ c + H := by
  sorry

/-- Corollary of `PFR_conjecture_improv` in which the ambient group is not required to be finite
(but) then $H$ and $c$ are finite. -/
theorem PFR_conjecture_improv' {G : Type*} [AddCommGroup G] [Module (ZMod 2) G]
    {A : Set G} {K : ℝ} (h₀A : A.Nonempty) (Afin : A.Finite)
    (hA : Nat.card (A + A) ≤ K * A.ncard) :
    ∃ (H : Submodule (ZMod 2) G) (c : Set G), c.Finite ∧ (H : Set G).Finite ∧
      Nat.card c < 2 * K ^ 11 ∧ (H : Set G).ncard ≤ A.ncard ∧ A ⊆ c + H := by
  sorry

end PFR
