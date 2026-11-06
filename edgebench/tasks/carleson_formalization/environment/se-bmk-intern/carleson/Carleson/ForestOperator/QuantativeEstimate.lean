module

public import Carleson.ForestOperator.L2Estimate
public import Carleson.ToMathlib.BoundedCompactSupport

@[expose] public section

open ShortVariables TileStructure
variable {X : Type*} {a : ℕ} {q : ℝ} {K : X → X → ℂ} {σ₁ σ₂ : X → ℤ} {F G : Set X}
  [MetricSpace X] [ProofData a q K σ₁ σ₂ F G] [TileStructure Q D κ S o]
  {n j j' : ℕ} {t : Forest X n} {u u₁ u₂ p : 𝔓 X} {x x' : X} {𝔖 : Set (𝔓 X)}
  {f f₁ f₂ g g₁ g₂ : X → ℂ} {I J J' L : Grid X}
variable {E' : Type*} [NormedAddCommGroup E'] [NormedSpace ℝ E']

noncomputable section

open Set MeasureTheory Metric Function Complex Bornology TileStructure Filter
open scoped NNReal ENNReal ComplexConjugate

namespace TileStructure.Forest

/-! ## Section 7.3 and Lemma 7.3.1 -/

/-- The constant used in `local_dens1_tree_bound`.
Has value `2 ^ (101 * a ^ 3)` in the blueprint. -/
irreducible_def C7_3_2 (a : ℕ) : ℝ≥0 := 2 ^ ((𝕔 + 1) * a ^ 3)

/-- Part 1 of Lemma 7.3.2. -/
lemma local_dens1_tree_bound_exists (hu : u ∈ t) (hL : L ∈ 𝓛 (t u))
    (hp₂ : ∃ p ∈ t u, ¬Disjoint ↑L (E p) ∧ 𝔰 p ≤ s L) :
    volume (L ∩ G ∩ ⋃ p ∈ t u, E p) ≤ C7_3_2 a * dens₁ (t u) * volume (L : Set X) := by
  sorry

lemma volume_bound_of_Grid_lt {L L' : Grid X} (lL : L ≤ L') (sL : s L' = s L + 1) :
    volume (L' : Set X) ≤ 2 ^ (𝕔 * a ^ 3 + 5 * a) * volume (L : Set X) := by
  sorry

/-- Lemma 7.3.2. -/
lemma local_dens1_tree_bound (hu : u ∈ t) (hL : L ∈ 𝓛 (t u)) :
    volume (L ∩ G ∩ ⋃ p ∈ t u, E p) ≤ C7_3_2 a * dens₁ (t u) * volume (L : Set X) := by
  sorry

/-- The constant used in `local_dens2_tree_bound`.
Has value `2 ^ (201 * a ^ 3)` in the blueprint. -/
irreducible_def C7_3_3 (a : ℕ) : ℝ≥0 := 2 ^ ((2 * 𝕔 + 1) * (a : ℝ) ^ 3)

private lemma le_C7_3_3_exponent (ha : 4 ≤ a) (b : ℕ) (hb : b ≤ 16) :
    2 * 𝕔 * a ^ 3 + b * a ≤ (2 * 𝕔 + 1) * a ^ 3 := by
  sorry

-- Auxiliary result used to prove `local_dens2_tree_bound`
private lemma local_dens2_tree_bound_aux {p : 𝔓 X} (hpu : p ∈ t u) {r : ℝ}
    (hr : r ≥ 4 * (D : ℝ) ^ (𝔰 p)) (h₁ : (J : Set X) ⊆ ball (𝔠 p) r)
    (h₂ : volume (ball (𝔠 p) r) ≤ C7_3_3 a * volume (J : Set X)) :
    volume (F ∩ J) ≤ C7_3_3 a * dens₂ (t u) * volume (J : Set X) := by
  sorry

-- Special case of `local_dens2_tree_bound_aux` which is used twice
private lemma local_dens2_tree_bound_aux' {p : 𝔓 X} (hpu : p ∈ t u)
    (h₁ : (J : Set X) ⊆ ball (𝔠 p) (4 * (D : ℝ) ^ (𝔰 p)))
    (h₂ : volume (𝓘 p : Set X) ≤ 2 ^ (2 * 𝕔 * a ^ 3 + 10 * a) * volume (J : Set X)) :
    volume (F ∩ J) ≤ C7_3_3 a * dens₂ (t u) * volume (J : Set X) := by
  sorry

/-- Lemma 7.3.3. -/
lemma local_dens2_tree_bound (hu : u ∈ t) (hJ : J ∈ 𝓙 (t u)) :
    volume (F ∩ J) ≤ C7_3_3 a * dens₂ (t u) * volume (J : Set X) := by
  sorry

/-- The constant used in `density_tree_bound1` and `adjoint_tree_estimate`.
Has value `2 ^ (181 * a ^ 3)` in the blueprint. -/
irreducible_def C7_3_1_1 (a : ℕ) : ℝ≥0 := 2 ^ ((𝕔 + 6 + 𝕔 / 2 + 𝕔 / 4) * a ^ 3)

-- Main bound in the proof of Lemma 7.3.1
private lemma eLpNorm_approxOnCube_two_le {C : Set (Grid X)}
    (disj_C : C.PairwiseDisjoint (fun I ↦ (I : Set X)))
    {s : Set X} (hs : MeasurableSet s) {c : ℝ≥0∞}
    (hc : ∀ J ∈ C, volume (J ∩ s) ≤ c * volume (J : Set X))
    {f : X → ℂ} (hf : BoundedCompactSupport f) (h2f : ∀ x ∉ s, f x = 0) :
    eLpNorm (approxOnCube C (‖f ·‖)) 2 volume ≤ c ^ (2 : ℝ)⁻¹ * eLpNorm f 2 := by
  sorry

lemma eLpNorm_approxOnCube_two_le_self (hf : BoundedCompactSupport f)
    {C : Set (Grid X)} (pdC : C.PairwiseDisjoint (fun I ↦ (I : Set X))) :
    eLpNorm (approxOnCube C (‖f ·‖)) 2 volume ≤ eLpNorm f 2 volume := by
  sorry

-- Generalization that implies both parts of Lemma 7.3.1
private lemma density_tree_bound_aux (hf : BoundedCompactSupport f)
    (hg : BoundedCompactSupport g) (h2g : support g ⊆ G) (hu : u ∈ t)
    {c : ℝ≥0∞} (hc : eLpNorm (approxOnCube (𝓙 (t u)) (‖f ·‖)) 2 volume ≤ c * eLpNorm f 2 volume) :
    ‖∫ x, conj (g x) * carlesonSum (t u) f x‖ₑ ≤
    C7_3_1_1 a * dens₁ (t u) ^ (2 : ℝ)⁻¹ * c * eLpNorm f 2 volume * eLpNorm g 2 volume := by
  sorry

/-- First part of Lemma 7.3.1. -/
lemma density_tree_bound1 (hf : BoundedCompactSupport f)
    (hg : BoundedCompactSupport g) (h2g : support g ⊆ G) (hu : u ∈ t) :
    ‖∫ x, conj (g x) * carlesonSum (t u) f x‖ₑ ≤
    C7_3_1_1 a * dens₁ (t u) ^ (2 : ℝ)⁻¹ * eLpNorm f 2 volume * eLpNorm g 2 volume := by
  sorry

/-- The constant used in `density_tree_bound2` and `indicator_adjoint_tree_estimate`.
Has value `2 ^ (282 * a ^ 3)` in the blueprint. -/
irreducible_def C7_3_1_2 (a : ℕ) : ℝ≥0 := 2 ^ ((2 * 𝕔 + 7 + 𝕔 / 2 + 𝕔 / 4) * a ^ 3)

/-- Second part of Lemma 7.3.1. -/
lemma density_tree_bound2
    (hf : BoundedCompactSupport f) (h2f : support f ⊆ F)
    (hg : BoundedCompactSupport g) (h2g : support g ⊆ G) (hu : u ∈ t) :
    ‖∫ x, conj (g x) * carlesonSum (t u) f x‖ₑ ≤
    C7_3_1_2 a * dens₁ (t u) ^ (2 : ℝ)⁻¹ * dens₂ (t u) ^ (2 : ℝ)⁻¹ *
    eLpNorm f 2 volume * eLpNorm g 2 volume := by
  sorry

end TileStructure.Forest

section Extras

omit [TileStructure Q D κ S o] in
-- TODO: move somewhere else
lemma _root_.MeasureTheory.BoundedCompactSupport.const_smul (hf : BoundedCompactSupport f) (c : ℝ) :
    BoundedCompactSupport (c • f) := by
  sorry

omit [TileStructure Q D κ S o] [MetricSpace X] in
-- rename, move somewhere else
lemma smul_le_indicator {A : Set X} (hf : f.support ⊆ A) {C : ℝ} (hC : ∀ x, ‖f x‖ ≤ C)
    (hCpos : 0 < C) : ∀ x, ‖(C⁻¹ • f) x‖ ≤ A.indicator 1 x := by
  sorry

end Extras
