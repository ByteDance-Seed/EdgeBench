module

public import Carleson.Discrete.MainTheorem
public import Carleson.TileExistence

@[expose] public section

open MeasureTheory Measure NNReal Metric Complex Set
open scoped ENNReal
noncomputable section

open scoped ShortVariables
variable {X : Type*} {a : ℕ} {q : ℝ} {K : X → X → ℂ} {σ₁ σ₂ : X → ℤ} {F G : Set X}
  [MetricSpace X] [ProofData a q K σ₁ σ₂ F G]

theorem integrable_tile_sum_operator
    {f : X → ℂ} (hf : Measurable f) (h2f : ∀ x, ‖f x‖ ≤ F.indicator 1 x) {x : X} {s : ℤ} :
    Integrable fun y ↦ Ks s x y * f y * exp (I * (Q x y - Q x x)) := by
  sorry

section

variable [TileStructure Q D κ S o]

@[reducible] -- Used to simplify notation in the proof of `tile_sum_operator`
private def 𝔓X_s (s : ℤ) := (@Finset.univ (𝔓 X) _).filter (fun p ↦ 𝔰 p = s)

private lemma 𝔰_eq {s : ℤ} {p : 𝔓 X} (hp : p ∈ 𝔓X_s s) : 𝔰 p = s := by
  sorry

open scoped Classical in
private lemma 𝔓_biUnion : @Finset.univ (𝔓 X) _ = (Icc (-S : ℤ) S).toFinset.biUnion 𝔓X_s := by
  sorry

private lemma sum_eq_zero_of_notMem_Icc {f : X → ℂ} {x : X} (s : ℤ)
    (hs : s ∈ (Icc (-S : ℤ) S).toFinset.filter (fun t ↦ t ∉ Icc (σ₁ x) (σ₂ x))) :
    ∑ i ∈ Finset.univ.filter (fun p ↦ 𝔰 p = s), carlesonOn i f x = 0 := by
  sorry

lemma exists_Grid {x : X} (hx : x ∈ G) {s : ℤ} (hs : s ∈ (Icc (σ₁ x) (σ₂ x)).toFinset) :
    ∃ I : Grid X, GridStructure.s I = s ∧ x ∈ I := by
  sorry

/-- Lemma 4.0.3 -/
theorem tile_sum_operator {G' : Set X} {f : X → ℂ} {x : X} (hx : x ∈ G \ G') :
    ∑ (p : 𝔓 X), carlesonOn p f x =
    ∑ s ∈ Icc (σ₁ x) (σ₂ x), ∫ y, Ks s x y * f y * exp (I * (Q x y - Q x x)) := by
  sorry

end

/-- The constant used in Proposition 2.0.1.
Has value `2 ^ (442 * a ^ 3) / (q - 1) ^ 5` in the blueprint. -/
def C2_0_1 (a : ℕ) (q : ℝ≥0) : ℝ≥0 := C2_0_2 a q

lemma C2_0_1_pos [TileStructure Q D κ S o] : C2_0_1 a nnq > 0 := by
  sorry

variable (X) in
/-- Proposition 2.0.1 -/
theorem finitary_carleson : ∃ G', MeasurableSet G' ∧ 2 * volume G' ≤ volume G ∧
    ∀ f : X → ℂ, Measurable f → (∀ x, ‖f x‖ ≤ F.indicator 1 x) →
    ∫⁻ x in G \ G', ‖∑ s ∈ Icc (σ₁ x) (σ₂ x), ∫ y, Ks s x y * f y * exp (I * Q x y)‖ₑ ≤
    C2_0_1 a nnq * (volume G) ^ (1 - q⁻¹) * (volume F) ^ q⁻¹ := by
  sorry
