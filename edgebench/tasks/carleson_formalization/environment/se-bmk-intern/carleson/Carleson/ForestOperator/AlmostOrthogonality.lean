module

public import Carleson.ForestOperator.QuantativeEstimate

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

/-! ## Section 7.4 except Lemmas 4-6 -/

variable (t) in
/-- The operator `S_{2,𝔲} f(x)`, given above Lemma 7.4.3. -/
def adjointBoundaryOperator (u : 𝔓 X) (f : X → ℂ) (x : X) : ℝ≥0∞ :=
  ‖adjointCarlesonSum (t u) f x‖ₑ + MB volume 𝓑 c𝓑 r𝓑 f x + ‖f x‖ₑ

variable (t u₁ u₂) in
/-- The set `𝔖` defined in the proof of Lemma 7.4.4.
We append a subscript 0 to distinguish it from the section variable. -/
def 𝔖₀ : Set (𝔓 X) := { p ∈ t u₁ ∪ t u₂ | 2 ^ ((Z : ℝ) * n / 2) ≤ dist_(p) (𝒬 u₁) (𝒬 u₂) }

/-- Part 1 of Lemma 7.4.1.
Todo: update blueprint with precise properties needed on the function. -/
lemma adjoint_tile_support1 : adjointCarleson p f =
    (ball (𝔠 p) (5 * D ^ 𝔰 p)).indicator (adjointCarleson p ((𝓘 p : Set X).indicator f)) := by
  sorry

/-- Part 2 of Lemma 7.4.1.
Todo: update blueprint with precise properties needed on the function. -/
lemma adjoint_tile_support2 (hu : u ∈ t) (hp : p ∈ t u) : adjointCarleson p f =
    (𝓘 u : Set X).indicator (adjointCarleson p ((𝓘 u : Set X).indicator f)) := by
  sorry

lemma adjoint_tile_support2_sum (hu : u ∈ t) :
    adjointCarlesonSum (t u) f =
    (𝓘 u : Set X).indicator (adjointCarlesonSum (t u) ((𝓘 u : Set X).indicator f)) := by
  sorry

/-- A partially applied variant of `adjoint_tile_support2_sum`, used to prove Lemma 7.7.3. -/
lemma adjoint_tile_support2_sum_partial (hu : u ∈ t) :
    adjointCarlesonSum (t u) f = (adjointCarlesonSum (t u) ((𝓘 u : Set X).indicator f)) := by
  sorry

lemma enorm_adjointCarleson_le {x : X} :
    ‖adjointCarleson p f x‖ₑ ≤
    C2_1_3 a * 2 ^ (4 * a) * (volume (ball (𝔠 p) (8 * D ^ 𝔰 p)))⁻¹ * ∫⁻ y in E p, ‖f y‖ₑ := by
  sorry

lemma enorm_adjointCarleson_le_mul_indicator {x : X} :
    ‖adjointCarleson p f x‖ₑ ≤
    C2_1_3 a * 2 ^ (4 * a) * (volume (ball (𝔠 p) (8 * D ^ 𝔰 p)))⁻¹ * (∫⁻ y in E p, ‖f y‖ₑ) *
      (ball (𝔠 p) (8 * D ^ 𝔰 p)).indicator 1 x := by
  sorry

lemma adjoint_density_tree_bound1 (hf : BoundedCompactSupport f)
    (hg : BoundedCompactSupport g) (h2g : support g ⊆ G) (hu : u ∈ t) :
    ‖∫ x, conj (adjointCarlesonSum (t u) g x) * f x‖ₑ ≤
    C7_3_1_1 a * dens₁ (t u) ^ (2 : ℝ)⁻¹ * eLpNorm f 2 volume * eLpNorm g 2 volume := by
  sorry

/-- Part 1 of Lemma 7.4.2. -/
lemma adjoint_tree_estimate
    (hg : BoundedCompactSupport g) (h2g : support g ⊆ G) (hu : u ∈ t) :
    eLpNorm (adjointCarlesonSum (t u) g) 2 volume ≤
    C7_3_1_1 a * dens₁ (t u) ^ (2 : ℝ)⁻¹ * eLpNorm g 2 volume := by
  sorry

lemma adjoint_density_tree_bound2
    (hf : BoundedCompactSupport f) (h2f : support f ⊆ F)
    (hg : BoundedCompactSupport g) (h2g : support g ⊆ G) (hu : u ∈ t) :
    ‖∫ x, conj (adjointCarlesonSum (t u) g x) * f x‖ₑ ≤
    C7_3_1_2 a * dens₁ (t u) ^ (2 : ℝ)⁻¹ * dens₂ (t u) ^ (2 : ℝ)⁻¹ *
    eLpNorm f 2 volume * eLpNorm g 2 volume := by
  sorry

/-- Part 2 of Lemma 7.4.2. -/
lemma indicator_adjoint_tree_estimate
    (hg : BoundedCompactSupport g) (h2g : support g ⊆ G) (hu : u ∈ t) :
    eLpNorm (F.indicator (adjointCarlesonSum (t u) g)) 2 ≤
    C7_3_1_2 a * dens₁ (t u) ^ (2 : ℝ)⁻¹ * dens₂ (t u) ^ (2 : ℝ)⁻¹ * eLpNorm g 2 := by
  sorry

/-- The constant used in `adjoint_tree_control`.
Has value `2 ^ (182 * a ^ 3)` in the blueprint. -/
irreducible_def C7_4_3 (a : ℕ) : ℝ≥0 := 2 ^ ((𝕔 + 7 + 𝕔 / 2 + 𝕔 / 4) * a ^ 3)

lemma le_C7_4_3 (ha : 4 ≤ a) : C7_3_1_1 a + CMB (defaultA a) 2 + 1 ≤ C7_4_3 a := by
  sorry

/-- Lemma 7.4.3. -/
lemma adjoint_tree_control
    (hu : u ∈ t) (hf : BoundedCompactSupport f) (h2f : f.support ⊆ G) :
    eLpNorm (adjointBoundaryOperator t u f ·) 2 volume ≤ C7_4_3 a * eLpNorm f 2 volume := by
  sorry

/-- Part 1 of Lemma 7.4.7. -/
lemma overlap_implies_distance (hu₁ : u₁ ∈ t) (hu₂ : u₂ ∈ t) (hu : u₁ ≠ u₂)
    (h2u : 𝓘 u₁ ≤ 𝓘 u₂) (hp : p ∈ t u₁ ∪ t u₂)
    (hpu₁ : ¬Disjoint (𝓘 p : Set X) (𝓘 u₁)) : p ∈ 𝔖₀ t u₁ u₂ := by
  sorry

/-- Part 2 of Lemma 7.4.7. -/
lemma 𝔗_subset_𝔖₀ (hu₁ : u₁ ∈ t) (hu₂ : u₂ ∈ t) (hu : u₁ ≠ u₂) (h2u : 𝓘 u₁ ≤ 𝓘 u₂) :
    t u₁ ⊆ 𝔖₀ t u₁ u₂ := by
  sorry

end TileStructure.Forest
