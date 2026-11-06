module

public import Mathlib.Data.Set.Card
public import Mathlib.Algebra.Group.Pointwise.Finset.BigOperators
public import PFR.Main
public import PFR.MultiTauFunctional
public import PFR.BoundingMutual

/-!
# Endgame for the Torsion PFR theorem
-/

public section

open MeasureTheory ProbabilityTheory Set
open scoped Pointwise

section AnalyzeMinimizer

universe u

variable {G Ωₒ : Type u} [MeasurableFinGroup G] [hΩ₀ : MeasureSpace Ωₒ] {p : multiRefPackage G Ωₒ}
  {Ω : Fin p.m → Type u}
  (hΩ : ∀ i, MeasureSpace (Ω i)) {X : ∀ i, Ω i → G} (h_min : multiTauMinimizes p Ω hΩ X)
  (hΩ_prob : ∀ i, IsProbabilityMeasure (hΩ i).volume) (hX_mes : ∀ i, Measurable (X i))

local notation3 "k" => D[X; hΩ]

variable {Ω' : Type u} {Y : Fin p.m × Fin p.m → Ω' → G}

local notation3 "W" => ∑ i, ∑ j, Y (i, j)
local notation3 "Z1" => ∑ i: Fin p.m, ∑ j, (i:ℤ) • Y (i, j)
local notation3 "Z2" => ∑ i, ∑ j: Fin p.m, (j:ℤ) • Y (i, j)
local notation3 "Z3" => ∑ i: Fin p.m, ∑ j: Fin p.m, (-i-j:ℤ) • Y (i, j)
local notation3 "P" => fun i ↦ ∑ j, Y (i, j)
local notation3 "Q" => fun j ↦ ∑ i, Y (i, j)
local notation3 "R" => fun r ↦ ∑ i, ∑ j, if (i+j+r = 0) then Y r else 0

variable [hΩ' : MeasureSpace Ω'] [hΩ'_prob : IsProbabilityMeasure hΩ'.volume]
  (h_mes : ∀ i j, Measurable (Y (i, j))) (h_indep : iIndepFun Y)
  (hident : ∀ i j, IdentDistrib (Y (i, j)) (X i))

include h_mes h_indep in
omit hΩ'_prob in

include h_mes h_indep hident h_min in
/-- We have `I[Z_1 : Z_2 | W], I[Z_2 : Z_3 | W], I[Z_1 : Z_3 | W] ≤ 4m^2 η k`.
-/
lemma mutual_information_le_t_12 : I[Z1 : Z2 | W] ≤ p.m * (4*p.m+1) * p.η * k := by
  sorry

include h_mes h_indep hident h_min in
lemma mutual_information_le_t_23 : I[Z2 : Z3 | W] ≤ p.m * (4*p.m+1) * p.η * k := by
  sorry

include h_mes h_indep hident h_min in
lemma mutual_information_le_t_13 : I[Z1 : Z3 | W] ≤ p.m * (4*p.m+1) * p.η * k := by
  sorry

include h_mes h_indep hident in

include h_mes in
omit hΩ'_prob in

set_option linter.flexible false in
include h_mes h_indep hident in
lemma Q_dist (j j' : Fin p.m) : d[Q j # -(Q j')] ≤ 2 * k := by
  sorry

include h_mes h_indep hident in

include h_mes h_indep in
omit hΩ'_prob in

include h_mes h_indep hident in
/-- We have $\bbH[W] \leq (2m-1)k + \frac1m \sum_{i=1}^m \bbH[X_i]$. -/
lemma entropy_of_W_le : H[W] ≤ (2*p.m - 1) * k + (p.m:ℝ)⁻¹ * ∑ i, H[X i] := by
  sorry

/-- We have $\bbH[Z_2] \leq (8m^2-16m+1) k + \frac{1}{m} \sum_{i=1}^m \bbH[X_i]$. -/
lemma entropy_of_Z_two_le : H[Z2] ≤ (8 * p.m^2 - 16 * p.m + 1) * k + (p.m:ℝ)⁻¹ * ∑ i, H[X i] := by
  sorry

include h_mes h_indep hident in
/-- We have $\bbI[W : Z_2] \leq 2(m-1) k$. -/
lemma mutual_of_W_Z_two_le : I[W : Z2] ≤ 2 * (p.m-1) * k := by
  sorry

set_option linter.flexible false in
include h_mes h_indep hident hΩ_prob hX_mes in
/-- We have $\sum_{i=1}^m d[X_i;Z_2|W] \leq 4(m^3-m^2) k$. -/
lemma sum_of_conditional_distance_le : ∑ i, d[ X i # Z2 | W] ≤ 4 * (p.m^3 - p.m^2)*k := by
  sorry

/-- Let $G$ be an abelian group, let $(T_1,T_2,T_3)$ be a $G^3$-valued random variable such that
$T_1+T_2+T_3=0$ holds identically, and write
  \[
    \delta := \bbI[T_1 : T_2] + \bbI[T_1 : T_3] + \bbI[T_2 : T_3].
  \]
  Let $Y_1,\dots,Y_n$ be some further $G$-valued random variables and let $\alpha>0$ be a constant.
  Then there exists a random variable $U$ such that
$$  d[U;U] + \alpha \sum_{i=1}^n d[Y_i;U] \leq
  \Bigl(2 + \frac{\alpha n}{2} \Bigr) \delta + \alpha \sum_{i=1}^n d[Y_i;T_2].$$
-/
lemma dist_of_U_add_le {G : Type*} [MeasurableFinGroup G] {Ω : Type u} [hΩ : MeasureSpace Ω]
    [IsProbabilityMeasure (ℙ : Measure Ω)] {T₁ T₂ T₃ : Ω → G} (hsum : T₁ + T₂ + T₃ = 0)
    (hmes₁ : Measurable T₁) (hmes₂ : Measurable T₂) (hmes₃ : Measurable T₃) {n : ℕ}
    {Ω' : Fin n → Type*} (hΩ' : ∀ i, MeasureSpace (Ω' i)) [∀ i, IsProbabilityMeasure (hΩ' i).volume]
    {Y : ∀ i, (Ω' i) → G} (hY : ∀ i, Measurable (Y i)) {α : ℝ} (hα : α > 0) :
    ∃ (Ω'' : Type u) (hΩ'': MeasureSpace Ω'') (U: Ω'' → G),
      IsProbabilityMeasure hΩ''.volume ∧ Measurable U ∧
        d[U # U] + α * ∑ i, d[Y i # U] ≤
          (2 + α * n / 2) * (I[T₁ : T₂] + I[T₁ : T₃] + I[T₂ : T₃]) + α * ∑ i, d[Y i # T₂] := by
  sorry

include h_mes h_indep hident h_min hΩ hΩ_prob hX_mes in
/-- We have $k = 0$. -/
lemma k_eq_zero (hη_eq : p.η = 1 / (32 * p.m ^ 3)) : k = 0 := by
  sorry

end AnalyzeMinimizer

universe u
/-- Suppose that $G$ is a finite abelian group of torsion $m$. Suppose that $X$ is a $G$-valued
random variable. Then there exists a subgroup $H \leq G$ such that
\[ d[X;U_H] \leq 64 m^3 d[X;X].\]. -/
lemma dist_of_X_U_H_le {G : Type u} [AddCommGroup G] [Finite G] [MeasurableSpace G]
    [MeasurableSingletonClass G] {m : ℕ} (hm : m ≥ 2) (htorsion : ∀ x:G, m • x = 0) {Ω : Type u}
    [MeasureSpace Ω] [IsProbabilityMeasure (ℙ:Measure Ω)] {X: Ω → G} (hX: Measurable X) :
    ∃ H : AddSubgroup G, ∃ Ω' : Type u, ∃ mΩ : MeasureSpace Ω', IsProbabilityMeasure mΩ.volume ∧
      ∃ U : Ω' → G, IsUniform H U ∧ Measurable U ∧ d[X # U] ≤ 64 * m^3 * d[X # X] := by
  sorry

open Real

/-- Suppose that $G$ is a finite abelian group of torsion $m$. If $A \subset G$ is non-empty and
$|A+A| \leq K|A|$, then $A$ can be covered by at most $K ^
{(64m^3+2)/2}|A|^{1/2}/|H|^{1/2}$ translates of a subspace $H$ of $G$ with
$|H|/|A| \in [K^{-64m^3}, K^{64m^3}]$. -/
lemma torsion_PFR_conjecture_aux {G : Type*} [AddCommGroup G] [Finite G] {m : ℕ} (hm : m ≥ 2)
    (htorsion : ∀ x:G, m • x = 0) {A : Set G} [A_fin: Finite A] {K : ℝ} (h₀A : A.Nonempty)
    (hA : Nat.card (A + A) ≤ K * A.ncard) :
    ∃ (H : AddSubgroup G) (c : Set G),
    c.ncard ≤ K ^ (128 * m^3 + 1) * A.ncard ^ (1/2:ℝ) * (H : Set G).ncard ^ (-1/2 : ℝ)
      ∧ (H : Set G).ncard ≤ K ^ (256 * m^3) * A.ncard
      ∧ A.ncard ≤ K ^ (256 * m^3) * (H : Set G).ncard ∧ A ⊆ c + H := by
  sorry

/-- Suppose that $G$ is a finite abelian group of torsion $m$.
If $A \subset G$ is non-empty and $|A+A| \leq K|A|$, then $A$ can be covered by most $mK^{64m^3+1}$
translates of a subspace $H$ of $G$ with $|H| \leq |A|$. -/
theorem torsion_PFR {G : Type*} [AddCommGroup G] [Finite G] {m : ℕ} (hm : m ≥ 2)
     (htorsion : ∀ x:G, m • x = 0) {A : Set G} [Finite A] {K : ℝ} (h₀A : A.Nonempty)
     (hA : Nat.card (A + A) ≤ K * A.ncard) :
     ∃ (H : AddSubgroup G) (c : Set G),
      Nat.card c < m * K ^ (256*m^3+1) ∧ (H : Set G).ncard ≤ A.ncard ∧ A ⊆ c + H := by
  sorry
