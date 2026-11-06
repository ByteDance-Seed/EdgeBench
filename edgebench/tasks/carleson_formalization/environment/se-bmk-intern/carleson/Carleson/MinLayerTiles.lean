module

public import Carleson.TileStructure
public import Carleson.ToMathlib.MinLayer

public section

noncomputable section

open Set
open scoped ShortVariables
variable {X : Type*} [PseudoMetricSpace X] {a : ℕ} {q : ℝ} {K : X → X → ℂ}
  {σ₁ σ₂ : X → ℤ} {F G : Set X} [ProofData a q K σ₁ σ₂ F G] [TileStructure Q D κ S o]
variable {A : Set (𝔓 X)} {p : 𝔓 X} {n : ℕ}

lemma exists_scale_add_le_of_mem_minLayer (hp : p ∈ A.minLayer n) :
    ∃ p' ∈ A.minLayer 0, p' ≤ p ∧ 𝔰 p' + n ≤ 𝔰 p := by
  sorry

lemma exists_le_add_scale_of_mem_maxLayer (hp : p ∈ A.maxLayer n) :
    ∃ p' ∈ A.maxLayer 0, p ≤ p' ∧ 𝔰 p + n ≤ 𝔰 p' := by
  sorry

lemma exists_scale_add_le_of_mem_layersAbove (hp : p ∈ A.layersAbove n) :
    ∃ p' ∈ A.minLayer 0, p' ≤ p ∧ 𝔰 p' + n ≤ 𝔰 p := by
  sorry

lemma exists_le_add_scale_of_mem_layersBelow (hp : p ∈ A.layersBelow n) :
    ∃ p' ∈ A.maxLayer 0, p ≤ p' ∧ 𝔰 p + n ≤ 𝔰 p' := by
  sorry

end
