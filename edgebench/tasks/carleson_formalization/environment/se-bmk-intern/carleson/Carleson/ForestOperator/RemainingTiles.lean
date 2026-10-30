module

public import Carleson.Calculations
public import Carleson.ForestOperator.AlmostOrthogonality

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

/-! ## Section 7.6 and Lemma 7.4.6 -/

variable (t u₁) in
/-- The definition `𝓙'` at the start of Section 7.6.
We use a different notation to distinguish it from the 𝓙' used in Section 7.5 -/
def 𝓙₆ : Set (Grid X) := 𝓙 (t u₁) ∩ Iic (𝓘 u₁)

/-- Part of Lemma 7.6.1. -/
-- Very similar to Lemma 7.5.1. Todo: simplify
lemma union_𝓙₆ (hu₁ : u₁ ∈ t) : ⋃ J ∈ 𝓙₆ t u₁, (J : Set X) = 𝓘 u₁ := by
  sorry

/-- Part of Lemma 7.6.1. -/
lemma pairwiseDisjoint_𝓙₆ : (𝓙₆ t u₁).PairwiseDisjoint (fun I ↦ (I : Set X)) := by
  sorry

/-- The constant used in `thin_scale_impact`. This is denoted `s₁` in the proof of Lemma 7.6.3.
Has value `Z * n / (202 * a ^ 3) - 2` in the blueprint. -/
-- Todo: define this recursively in terms of previous constants
irreducible_def C7_6_3 (a n : ℕ) : ℝ := Z * n / ((2 * 𝕔 + 2) * a ^ 3) - 2

lemma nonneg_C7_6_3_add_two : 0 ≤ C7_6_3 a n + 2 := by
  sorry

/-- Some preliminary relations for Lemma 7.6.3. -/
lemma thin_scale_impact_prelims (hu₁ : u₁ ∈ t) (hJ : J ∈ 𝓙₆ t u₁)
    (hd : ¬Disjoint (ball (𝔠 p) (8 * D ^ 𝔰 p)) (ball (c J) (8 * D ^ s J)))
    (h : s J - C7_6_3 a n < 𝔰 p) :
    dist (𝔠 p) (c J) < 16 * D ^ (𝔰 p + C7_6_3 a n + 2) ∧
    ∃ J', J < J' ∧ s J' = s J + 1 ∧
      ∃ p ∈ t u₁, ↑(𝓘 p) ⊆ ball (c J') (100 * D ^ (s J' + 1)) := by
  sorry

/-- The key relation of Lemma 7.6.3, which will eventually be shown to lead to a contradiction. -/
lemma thin_scale_impact_key (hu₁ : u₁ ∈ t) (hu₂ : u₂ ∈ t) (hu : u₁ ≠ u₂)
    (h2u : 𝓘 u₁ ≤ 𝓘 u₂) (hp : p ∈ t u₂ \ 𝔖₀ t u₁ u₂) (hJ : J ∈ 𝓙₆ t u₁)
    (hd : ¬Disjoint (ball (𝔠 p) (8 * D ^ 𝔰 p)) (ball (c J) (8 * D ^ s J)))
    (h : s J - C7_6_3 a n < 𝔰 p) :
    (2 : ℝ) ^ (Z * (n + 1) - 1) <
    2 ^ (a * (𝕔 * a ^ 2 * (C7_6_3 a n + 2 + 1) + 9)) * 2 ^ ((Z : ℝ) * n / 2) := by
  sorry

/-- Lemma 7.6.3. -/
lemma thin_scale_impact (hu₁ : u₁ ∈ t) (hu₂ : u₂ ∈ t) (hu : u₁ ≠ u₂)
    (h2u : 𝓘 u₁ ≤ 𝓘 u₂) (hp : p ∈ t u₂ \ 𝔖₀ t u₁ u₂) (hJ : J ∈ 𝓙₆ t u₁)
    (hd : ¬Disjoint (ball (𝔠 p) (8 * D ^ 𝔰 p)) (ball (c J) (8 * D ^ s J))) :
    𝔰 p ≤ s J - C7_6_3 a n := by
  sorry

/-- Lemma 7.6.3 with a floor on the constant to avoid casting. -/
lemma thin_scale_impact' (hu₁ : u₁ ∈ t) (hu₂ : u₂ ∈ t) (hu : u₁ ≠ u₂)
    (h2u : 𝓘 u₁ ≤ 𝓘 u₂) (hp : p ∈ t u₂ \ 𝔖₀ t u₁ u₂) (hJ : J ∈ 𝓙₆ t u₁)
    (hd : ¬Disjoint (ball (𝔠 p) (8 * D ^ 𝔰 p)) (ball (c J) (8 * D ^ s J))) :
    𝔰 p ≤ s J - ⌊C7_6_3 a n⌋ := by
  sorry

/-- The constant used in `square_function_count`. -/
irreducible_def C7_6_4 (a : ℕ) (s : ℤ) : ℝ≥0 := 2 ^ (14 * (a : ℝ) + 1) * (8 * D ^ (- s)) ^ κ

open Classical in
/-- Lemma 7.6.4. -/
lemma square_function_count (hJ : J ∈ 𝓙₆ t u₁) {s' : ℤ} :
    ⨍⁻ x in J, (∑ I with s I = s J - s' ∧ Disjoint (I : Set X) (𝓘 u₁) ∧
    ¬Disjoint (J : Set X) (ball (c I) (8 * D ^ s I)),
    (ball (c I) (8 * D ^ s I)).indicator 1 x) ^ 2 ∂volume ≤ C7_6_4 a s' := by
  sorry

open Classical in
lemma sum_𝓙₆_indicator_sq_eq {f : Grid X → X → ℝ≥0∞} :
    (∑ J ∈ (𝓙₆ t u₁).toFinset, (J : Set X).indicator (f J) x) ^ 2 =
    ∑ J ∈ (𝓙₆ t u₁).toFinset, (J : Set X).indicator (f J · ^ 2) x := by
  sorry

open Classical in
lemma btp_expansion (hf : BoundedCompactSupport f) :
    eLpNorm (approxOnCube (𝓙₆ t u₁) (‖adjointCarlesonSum (t u₂ \ 𝔖₀ t u₁ u₂) f ·‖)) 2 volume =
    (∑ J ∈ (𝓙₆ t u₁).toFinset, (volume (J : Set X))⁻¹ *
    (∫⁻ y in J, ‖adjointCarlesonSum (t u₂ \ 𝔖₀ t u₁ u₂) f y‖ₑ) ^ 2) ^ (2 : ℝ)⁻¹ := by
  sorry

open Classical in
/-- Equation (7.6.3) of Lemma 7.6.2. -/
lemma e763 (hu₁ : u₁ ∈ t) (hu₂ : u₂ ∈ t) (hu : u₁ ≠ u₂) (h2u : 𝓘 u₁ ≤ 𝓘 u₂)
    (hf : BoundedCompactSupport f) :
    eLpNorm (approxOnCube (𝓙₆ t u₁) (‖adjointCarlesonSum (t u₂ \ 𝔖₀ t u₁ u₂) f ·‖)) 2 volume ≤
    ∑ k ∈ Finset.Icc ⌊C7_6_3 a n⌋ (2 * S),
    (∑ J ∈ (𝓙₆ t u₁).toFinset, (volume (J : Set X))⁻¹ *
    (∫⁻ y in J, ∑ p ∈ (t u₂ \ 𝔖₀ t u₁ u₂).toFinset with
      ¬Disjoint ↑J (ball (𝔠 p) (8 * D ^ 𝔰 p)) ∧ 𝔰 p = s J - k,
    ‖adjointCarleson p f y‖ₑ) ^ 2) ^ (2 : ℝ)⁻¹ := by
  sorry

open Classical in
/-- The critical bound on the integral in Equation (7.6.3). It holds for _any_ cubes `I, J`. -/
lemma btp_integral_bound :
    ∫⁻ y in J, ∑ p ∈ (t u₂ \ 𝔖₀ t u₁ u₂).toFinset with
      ¬Disjoint ↑J (ball (𝔠 p) (8 * D ^ 𝔰 p)) ∧ 𝓘 p = I, ‖adjointCarleson p f y‖ₑ ≤
    C2_1_3 a * 2 ^ (4 * a) * ∫⁻ y in J, (ball (c I) (8 * D ^ s I)).indicator 1 y *
      MB volume 𝓑 c𝓑 r𝓑 f y := by
  sorry

attribute [fun_prop] AEMeasurable.restrict

open Classical in
/-- Equation (7.6.4) of Lemma 7.6.2 (before applying Cauchy–Schwarz). -/
lemma e764_preCS (hu₁ : u₁ ∈ t) (hu₂ : u₂ ∈ t) (hu : u₁ ≠ u₂) (h2u : 𝓘 u₁ ≤ 𝓘 u₂)
    (hf : BoundedCompactSupport f) :
    eLpNorm (approxOnCube (𝓙₆ t u₁) (‖adjointCarlesonSum (t u₂ \ 𝔖₀ t u₁ u₂) f ·‖)) 2 volume ≤
    C2_1_3 a * 2 ^ (4 * a) * ∑ k ∈ Finset.Icc ⌊C7_6_3 a n⌋ (2 * S),
    (∑ J ∈ (𝓙₆ t u₁).toFinset, (volume (J : Set X))⁻¹ *
    (∑ I with s I = s J - k ∧ Disjoint (I : Set X) (𝓘 u₁) ∧
      ¬Disjoint ↑J (ball (c I) (8 * D ^ s I)),
    ∫⁻ y in J, (ball (c I) (8 * D ^ s I)).indicator 1 y *
      MB volume 𝓑 c𝓑 r𝓑 f y) ^ 2) ^ (2 : ℝ)⁻¹ := by
  sorry

/-- Equation (7.6.4) of Lemma 7.6.2 (after applying Cauchy–Schwarz and simplification). -/
lemma e764_postCS (hu₁ : u₁ ∈ t) (hu₂ : u₂ ∈ t) (hu : u₁ ≠ u₂) (h2u : 𝓘 u₁ ≤ 𝓘 u₂)
    (hf : BoundedCompactSupport f) :
    eLpNorm (approxOnCube (𝓙₆ t u₁) (‖adjointCarlesonSum (t u₂ \ 𝔖₀ t u₁ u₂) f ·‖)) 2 volume ≤
    C2_1_3 a * 2 ^ (11 * a + 2) *
    (∑ k ∈ Finset.Icc ⌊C7_6_3 a n⌋ (2 * S), (D : ℝ≥0∞) ^ (-k * κ / 2)) *
    eLpNorm ((𝓘 u₁ : Set X).indicator (MB volume 𝓑 c𝓑 r𝓑 f ·)) 2 volume := by
  sorry

/-- The constant used in `bound_for_tree_projection`. -/
irreducible_def C7_6_2 (a n : ℕ) : ℝ≥0 :=
  C2_1_3 a * 2 ^ (21 * a + 5) * 2 ^ (-(𝕔 / ((4 * 𝕔 + 4) * a) * Z * n * κ))

omit [TileStructure Q D κ S o] in
lemma btp_constant_bound :
    C2_1_3 a * 2 ^ (11 * a + 2) *
    ∑ k ∈ Finset.Icc ⌊C7_6_3 a n⌋ (2 * S), (D : ℝ≥0∞) ^ (-k * κ / 2) ≤ C7_6_2 a n := by
  sorry

/-- Lemma 7.6.2. -/
lemma bound_for_tree_projection (hu₁ : u₁ ∈ t) (hu₂ : u₂ ∈ t) (hu : u₁ ≠ u₂) (h2u : 𝓘 u₁ ≤ 𝓘 u₂)
    (hf : BoundedCompactSupport f) :
    eLpNorm (approxOnCube (𝓙₆ t u₁) (‖adjointCarlesonSum (t u₂ \ 𝔖₀ t u₁ u₂) f ·‖)) 2 volume ≤
    C7_6_2 a n * eLpNorm ((𝓘 u₁ : Set X).indicator (MB volume 𝓑 c𝓑 r𝓑 f ·)) 2 volume := by
  sorry

lemma cntp_approxOnCube_eq (hu₁ : u₁ ∈ t) :
    approxOnCube (𝓙 (t u₁))
      (‖(𝓘 u₁ : Set X).indicator (adjointCarlesonSum (t u₂ \ 𝔖₀ t u₁ u₂) f₂) ·‖) =
    approxOnCube (𝓙₆ t u₁) (‖adjointCarlesonSum (t u₂ \ 𝔖₀ t u₁ u₂) f₂ ·‖) := by
  sorry

/-- The constant used in `correlation_near_tree_parts`.
Has value `2 ^ (232 * a ^ 3 + 21 * a + 5- 25/(101a) * Z n κ)` in the blueprint. -/
irreducible_def C7_4_6 (a n : ℕ) : ℝ≥0 := C7_2_1 a * C7_6_2 a n

set_option backward.isDefEq.respectTransparency false in
/-- Lemma 7.4.6 -/
lemma correlation_near_tree_parts (hu₁ : u₁ ∈ t) (hu₂ : u₂ ∈ t) (hu : u₁ ≠ u₂) (h2u : 𝓘 u₁ ≤ 𝓘 u₂)
    (hf₁ : BoundedCompactSupport f₁) (hf₂ : BoundedCompactSupport f₂) :
    ‖∫ x, adjointCarlesonSum (t u₁) f₁ x * conj (adjointCarlesonSum (t u₂ \ 𝔖₀ t u₁ u₂) f₂ x)‖ₑ ≤
    C7_4_6 a n *
    eLpNorm ((𝓘 u₁ : Set X).indicator (adjointBoundaryOperator t u₁ f₁) ·) 2 volume *
    eLpNorm ((𝓘 u₁ : Set X).indicator (adjointBoundaryOperator t u₂ f₂) ·) 2 volume := by
  sorry

end TileStructure.Forest
