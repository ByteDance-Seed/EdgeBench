module

public import PFR.Fibring
public import PFR.TauFunctional

/-!
# First estimate

The first estimate on tau-minimizers.

Assumptions:

* $X_1, X_2$ are tau-minimizers
* $X_1, X_2, \tilde X_1, \tilde X_2$ are independent random variables, with $X_1,\tilde X_1$ copies
  of $X_1$ and $X_2,\tilde X_2$ copies of $X_2$.
* $k := d[X_1;X_2]$
* $I_1 := I [X_1+X_2 : \tilde X_1 + X_2 | X_1+X_2+\tilde X_1+\tilde X_2]$

## Main results

* `first_estimate` : $I_1 ≤ 2 η k$
* `ent_ofsum_le` : $H[X_1+X_2+\tilde X_1+\tilde X_2] \le \tfrac{1}{2} H[X_1]+\tfrac{1}{2} H[X_2] +
  (2 + \eta) k - I_1.$
-/

public section

open MeasureTheory ProbabilityTheory

variable {G : Type*} [addgroup : AddCommGroup G] [Finite G] [hG : MeasurableSpace G]
  [MeasurableSingletonClass G]

variable {Ω₀₁ Ω₀₂ : Type*} [MeasureSpace Ω₀₁] [MeasureSpace Ω₀₂]

variable (p : refPackage Ω₀₁ Ω₀₂ G)

variable {Ω : Type*} [MeasureSpace Ω] [IsProbabilityMeasure (ℙ : Measure Ω)]

variable (X₁ X₂ X₁' X₂' : Ω → G)
  (hX₁ : Measurable X₁) (hX₂ : Measurable X₂) (hX₁' : Measurable X₁') (hX₂' : Measurable X₂')

variable (h₁ : IdentDistrib X₁ X₁') (h₂ : IdentDistrib X₂ X₂')
variable (h_indep : iIndepFun ![X₁, X₂, X₂', X₁'])
variable (h_min : tau_minimizes p X₁ X₂)

/-- `k := d[X₁ # X₂]`, the Ruzsa distance `rdist` between X₁ and X₂. -/
local notation3 "k" => d[X₁ # X₂]

/-- `I₁ := I[X₁ + X₂ : X₁' + X₂ | X₁ + X₂ + X₁' + X₂']`, the conditional mutual information
of `X₁ + X₂` and `X₁' + X₂` given the quadruple sum `X₁ + X₂ + X₁' + X₂'`. -/
local notation3 "I₁" => I[X₁ + X₂ : X₁' + X₂ | X₁ + X₂ + X₁' + X₂']

include h_indep hX₁ hX₂ hX₁' hX₂' h₁ h₂ in
/-- The sum of
$$ d[X_1+\tilde X_2;X_2+\tilde X_1] + d[X_1|X_1+\tilde X_2; X_2|X_2+\tilde X_1] $$
and
$$ I[X_1+ X_2 : \tilde X_1 + X_2 \,|\, X_1 + X_2 + \tilde X_1 + \tilde X_2] $$
is equal to $2k$. -/
lemma rdist_add_rdist_add_condMutual_eq [Module (ZMod 2) G] :
    d[X₁ + X₂' # X₂ + X₁'] + d[X₁ | X₁ + X₂' # X₂ | X₂ + X₁']
      + I[X₁ + X₂ : X₁' + X₂ | X₁ + X₂ + X₁' + X₂'] = 2 * k := by
  sorry

include h_min hX₁ hX₂ hX₁' hX₂' in

include h_min hX₁ hX₂ hX₁' hX₂' in

variable [Module (ZMod 2) G]

include hX₁ hX₂' h_indep h₂ in
/-- `d[X₀₁ # X₁ + X₂'] - d[X₀₁ # X₁] ≤ k/2 + H[X₂]/4 - H[X₁]/4`. -/
lemma diff_rdist_le_1 [IsProbabilityMeasure (ℙ : Measure Ω₀₁)] :
    d[p.X₀₁ # X₁ + X₂'] - d[p.X₀₁ # X₁] ≤ k/2 + H[X₂]/4 - H[X₁]/4 := by
  sorry

include hX₁' hX₂ h_indep h₁ in
/-- $$ d[X^0_2;X_2+\tilde X_1] - d[X^0_2; X_2] \leq \tfrac{1}{2} k +
  \tfrac{1}{4} \mathbb{H}[X_1] - \tfrac{1}{4} \mathbb{H}[X_2].$$ -/
lemma diff_rdist_le_2 [IsProbabilityMeasure (ℙ : Measure Ω₀₂)] :
    d[p.X₀₂ # X₂ + X₁'] - d[p.X₀₂ # X₂] ≤ k/2 + H[X₁]/4 - H[X₂]/4 := by
  sorry

include h_indep hX₁ hX₂' h₂ in
/-- $$ d[X_1^0;X_1|X_1+\tilde X_2] - d[X_1^0;X_1] \leq
    \tfrac{1}{2} k + \tfrac{1}{4} \mathbb{H}[X_1] - \tfrac{1}{4} \mathbb{H}[X_2].$$ -/
lemma diff_rdist_le_3 [IsProbabilityMeasure (ℙ : Measure Ω₀₁)] :
    d[p.X₀₁ # X₁ | X₁ + X₂'] - d[p.X₀₁ # X₁] ≤ k/2 + H[X₁]/4 - H[X₂]/4 := by
  sorry

include h_indep hX₂ hX₁' h₁
/-- $$ d[X_2^0; X_2|X_2+\tilde X_1] - d[X_2^0; X_2] \leq
    \tfrac{1}{2}k + \tfrac{1}{4} \mathbb{H}[X_2] - \tfrac{1}{4} \mathbb{H}[X_1].$$ -/
lemma diff_rdist_le_4 [IsProbabilityMeasure (ℙ : Measure Ω₀₂)] :
    d[p.X₀₂ # X₂ | X₂ + X₁'] - d[p.X₀₂ # X₂] ≤ k/2 + H[X₂]/4 - H[X₁]/4 := by
  sorry

include hX₁ hX₂ hX₁' hX₂' h₁ h₂ h_min in
/-- We have $I_1 \leq 2 \eta k$ -/
lemma first_estimate
    [IsProbabilityMeasure (ℙ : Measure Ω₀₁)] [IsProbabilityMeasure (ℙ : Measure Ω₀₂)] :
    I₁ ≤ 2 * p.η * k := by
  sorry

include hX₁ hX₂ hX₁' hX₂' h₁ h₂ h_min in
/-- $$\mathbb{H}[X_1+X_2+\tilde X_1+\tilde X_2]
  \le \tfrac{1}{2} \mathbb{H}[X_1]+\tfrac{1}{2} \mathbb{H}[X_2] + (2 + \eta) k - I_1.$$ -/
lemma ent_ofsum_le
    [IsProbabilityMeasure (ℙ : Measure Ω₀₁)] [IsProbabilityMeasure (ℙ : Measure Ω₀₂)] :
    H[X₁ + X₂ + X₁' + X₂'] ≤ H[X₁]/2 + H[X₂]/2 + (2+p.η)*k - I₁ := by
  sorry
