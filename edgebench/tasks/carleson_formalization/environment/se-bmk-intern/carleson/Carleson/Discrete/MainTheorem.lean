module

public import Carleson.Discrete.ExceptionalSet
public import Carleson.Discrete.ForestComplement
public import Carleson.Discrete.ForestUnion

@[expose] public section

open MeasureTheory NNReal Set
open scoped ShortVariables
variable {X : Type*} {a : ℕ} {q : ℝ} {K : X → X → ℂ} {σ₁ σ₂ : X → ℤ} {F G : Set X}
  [MetricSpace X] [ProofData a q K σ₁ σ₂ F G] [TileStructure Q D κ S o]

/-! ## Proposition 2.0.2 -/

/-- The constant used in Proposition 2.0.2.
Has value `2 ^ (442 * a ^ 3) / (q - 1) ^ 5` in the blueprint. -/
noncomputable def C2_0_2 (a : ℕ) (q : ℝ≥0) : ℝ≥0 :=
    2 ^ ((3 * 𝕔 + 17 + 5 * (𝕔 / 4)) * a ^ 3) / (q - 1) ^ 5

lemma le_C2_0_2 (ha : 4 ≤ a) {q : ℝ≥0} (hq : q ∈ Ioc 1 2) :
    C5_1_2 a q + C5_1_3 a q ≤ C2_0_2 a q := by
  sorry

omit [TileStructure Q D κ S o] in
lemma C2_0_2_pos : 0 < C2_0_2 a nnq := by
  sorry

variable (X) in
theorem discrete_carleson :
    ∃ G', MeasurableSet G' ∧ 2 * volume G' ≤ volume G ∧
    ∀ f : X → ℂ, Measurable f → (∀ x, ‖f x‖ ≤ F.indicator 1 x) →
    ∫⁻ x in G \ G', ‖carlesonSum univ f x‖ₑ ≤
    C2_0_2 a nnq * volume G ^ (1 - q⁻¹) * volume F ^ q⁻¹ := by
  sorry
