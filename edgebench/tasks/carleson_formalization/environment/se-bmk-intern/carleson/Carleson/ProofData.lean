module

public import Carleson.DoublingMeasure

@[expose] public section

open MeasureTheory Measure Metric Complex Set TopologicalSpace Bornology Function
open ENNReal hiding one_lt_two
open scoped NNReal
noncomputable section

/-! # ProofData.

This file introduces the class `ProofData`, used to bundle data common through most of
chapters 2-7 (except 3), and provides API for it.

-/

/-- Data common through most of chapters 2-7 (except 3). -/
class ProofData {X : Type*} (a : outParam ℕ) (q : outParam ℝ) (K : outParam (X → X → ℂ))
  (σ₁ σ₂ : outParam (X → ℤ)) (F G : outParam (Set X)) [PseudoMetricSpace X] extends
    KernelProofData a K where
  c : IsCancellative X (defaultτ a)
  q_mem_Ioc : q ∈ Ioc 1 2
  isBounded_F : IsBounded F
  isBounded_G : IsBounded G
  measurableSet_F : MeasurableSet F
  measurableSet_G : MeasurableSet G
  measurable_σ₁ : Measurable σ₁
  measurable_σ₂ : Measurable σ₂
  finite_range_σ₁ : Finite (range σ₁)
  finite_range_σ₂ : Finite (range σ₂)
  σ₁_le_σ₂ : σ₁ ≤ σ₂
  Q : SimpleFunc X (Θ X)
  BST_T_Q (θ : Θ X) : HasBoundedStrongType (linearizedNontangentialOperator Q θ K · ·)
    2 2 volume volume (C_Ts a)

export ProofData (q_mem_Ioc isBounded_F isBounded_G measurableSet_F measurableSet_G
  measurable_σ₁ measurable_σ₂ finite_range_σ₁ finite_range_σ₂ σ₁_le_σ₂ Q BST_T_Q)
attribute [instance] ProofData.c

section ProofData

variable {X : Type*} {a : ℕ} {q : ℝ} {K : X → X → ℂ} {σ₁ σ₂ : X → ℤ} {F G : Set X}
  [PseudoMetricSpace X] [ProofData a q K σ₁ σ₂ F G]

include a q K σ₁ σ₂ F G

variable (X) in
lemma S_spec : ∃ n : ℕ, (∀ x, -n ≤ σ₁ x ∧ σ₂ x ≤ n) ∧
    F ⊆ ball (cancelPt X) (defaultD a ^ n / 4) ∧
    G ⊆ ball (cancelPt X) (defaultD a ^ n / 4) ∧ 0 < n := by
  sorry

variable (X) in
open Classical in
def defaultS : ℕ := Nat.find (S_spec X)

lemma range_σ₁_subset : range σ₁ ⊆ Icc (-defaultS X) (defaultS X) := by
  sorry

lemma range_σ₂_subset : range σ₂ ⊆ Icc (-defaultS X) (defaultS X) := by
  sorry

lemma F_subset : F ⊆ ball (cancelPt X) (defaultD a ^ defaultS X / 4) := by
  sorry

lemma G_subset : G ⊆ ball (cancelPt X) (defaultD a ^ defaultS X / 4) := by
  sorry

lemma defaultS_pos : 0 < defaultS X := by
  sorry

lemma Icc_σ_subset_Icc_S {x : X} : Icc (σ₁ x) (σ₂ x) ⊆ Icc (-defaultS X) (defaultS X) := by
  sorry

variable (X)

lemma one_lt_q : 1 < q := by
  sorry
lemma q_le_two : q ≤ 2 := by
  sorry
lemma q_pos : 0 < q := by
  sorry
lemma q_nonneg : 0 ≤ q := by
  sorry
lemma inv_q_sub_half_nonneg : 0 ≤ q⁻¹ - 2⁻¹ := by
  sorry

-- Note: For exponent computations it is usually cleaner to argue in terms
-- of `q⁻¹` rather than `q`, both on paper and in Lean.
lemma inv_q_mem_Ico : q⁻¹ ∈ Ico 2⁻¹ 1 := by
  sorry

/-- `q` as an element of `ℝ≥0`. -/
def nnq : ℝ≥0 := ⟨q, q_nonneg X⟩

lemma one_lt_nnq : 1 < nnq X := by
  sorry
lemma nnq_le_two : nnq X ≤ 2 := by
  sorry
lemma nnq_pos : 0 < nnq X := by
  sorry
lemma nnq_mem_Ioc : nnq X ∈ Ioc 1 2 := by
  sorry

end ProofData

namespace ShortVariables
-- open this section to get shorter 1-letter names for a bunch of variables

set_option hygiene false
scoped notation "nnq" => nnq X

end ShortVariables

open scoped ShortVariables

variable {X : Type*} {a : ℕ} {q : ℝ} {K : X → X → ℂ} {σ₁ σ₂ : X → ℤ} {F G : Set X}

/-- Used in `third_exception` (Lemma 5.2.10). -/
lemma two_le_κZ [PseudoMetricSpace X] [ProofData a q K σ₁ σ₂ F G] : 2 ≤ κ * Z := by
  sorry

/-- Used in `third_exception` (Lemma 5.2.10). -/
lemma DκZ_le_two_rpow_100 [PseudoMetricSpace X] [ProofData a q K σ₁ σ₂ F G] :
    (D : ℝ≥0∞) ^ (-κ * Z) ≤ 2 ^ (-100 : ℝ) := by
  sorry

lemma four_le_Z [PseudoMetricSpace X] [ProofData a q K σ₁ σ₂ F G] : 4 ≤ Z := by
  sorry

section PseudoMetricSpace

variable [PseudoMetricSpace X] [ProofData a q K σ₁ σ₂ F G]

lemma volume_F_lt_top : volume F < ⊤ := by
  sorry
lemma volume_F_ne_top : volume F ≠ ⊤ := by
  sorry
lemma volume_G_lt_top : volume G < ⊤ := by
  sorry
lemma volume_G_ne_top : volume G ≠ ⊤ := by
  sorry

/-! Lemma 2.1.1 -/

def C2_1_1 (k : ℕ) (a : ℕ) : ℕ := 2 ^ (k * a)

set_option backward.isDefEq.respectTransparency false in
lemma Θ.finite_and_mk_le_of_le_dist {x₀ : X} {r R : ℝ} {f : Θ X} {k : ℕ}
    {𝓩 : Set (Θ X)} (h𝓩 : 𝓩 ⊆ ball_{x₀, R} f (r * 2 ^ k))
    (h2𝓩 : 𝓩.PairwiseDisjoint (ball_{x₀, R} · r)) :
    𝓩.Finite ∧ Cardinal.mk 𝓩 ≤ C2_1_1 k a := by
  sorry

lemma Θ.card_le_of_le_dist {x₀ : X} {r R : ℝ} {f : Θ X} {k : ℕ}
    {𝓩 : Set (Θ X)} (h𝓩 : 𝓩 ⊆ ball_{x₀, R} f (r * 2 ^ k))
    (h2𝓩 : 𝓩.PairwiseDisjoint (ball_{x₀, R} · r)) :
    Nat.card 𝓩 ≤ C2_1_1 k a := by
  sorry

end PseudoMetricSpace
