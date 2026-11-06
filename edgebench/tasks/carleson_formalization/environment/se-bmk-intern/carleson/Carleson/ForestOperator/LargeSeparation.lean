module

public import Carleson.Calculations
public import Carleson.ForestOperator.AlmostOrthogonality
public import Carleson.HolderVanDerCorput
public import Carleson.ToMathlib.Data.NNReal

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

/-! ## Section 7.5 -/

variable (t u₁ u₂) in
/-- The definition `𝓙'` at the start of Section 7.5.1.
We use a different notation to distinguish it from the 𝓙' used in Section 7.6 -/
def 𝓙₅ : Set (Grid X) := 𝓙 (𝔖₀ t u₁ u₂) ∩ Iic (𝓘 u₁)

/-- The definition of χ-tilde, defined in the proof of Lemma 7.5.2 -/
def χtilde (J : Grid X) (u₁ : 𝔓 X) : X → ℝ≥0 :=
  (𝓘 u₁ : Set X).indicator fun x ↦ (8 - D ^ (- s J) * dist x (c J)).toNNReal

lemma χtilde_pos_iff : 0 < χtilde J u₁ x ↔ x ∈ 𝓘 u₁ ∧ x ∈ ball (c J) (8 * D ^ s J) := by
  sorry

lemma χtilde_le_eight : χtilde J u₁ x ≤ 8 := by
  sorry

lemma four_lt_χtilde (xJ : x ∈ J) (xu : x ∈ 𝓘 u₁) : 4 < χtilde J u₁ x := by
  sorry

lemma dist_χtilde_le (mx : x ∈ 𝓘 u₁) (mx' : x' ∈ 𝓘 u₁) :
    dist (χtilde J u₁ x) (χtilde J u₁ x') ≤ dist x x' / D ^ s J := by
  sorry

lemma stronglyMeasurable_χtilde : StronglyMeasurable (χtilde J u₁) := by
  sorry

variable (t u₁ u₂) in
open scoped Classical in
/-- The definition of χ, defined in the proof of Lemma 7.5.2 -/
def χ (J : Grid X) (x : X) : ℝ≥0 :=
  χtilde J u₁ x / ∑ J' ∈ 𝓙₅ t u₁ u₂, χtilde J' u₁ x

lemma stronglyMeasurable_χ : StronglyMeasurable (χ t u₁ u₂ J) := by
  sorry

-- /-- The definition of `B`, defined in (7.5.1) -/

variable (t u₁ u₂) in
/-- The definition of h_J, defined in the proof of Section 7.5.2 -/
def holderFunction (f₁ f₂ : X → ℂ) (J : Grid X) (x : X) : ℂ :=
  χ t u₁ u₂ J x * (exp (.I * 𝒬 u₁ x) * adjointCarlesonSum (t u₁) f₁ x) *
  conj (exp (.I * 𝒬 u₂ x) * adjointCarlesonSum (t u₂ ∩ 𝔖₀ t u₁ u₂) f₂ x)

/- AUXILIARY LEMMAS:START -/

lemma IF_subset_THEN_not_disjoint {A B : Grid X} (h : (A : Set X) ⊆ B) :
    ¬ Disjoint (B : Set X) (A : Set X) := by
  sorry

lemma IF_disjoint_with_ball_THEN_distance_bigger_than_radius {J : X} {r : ℝ} {pSet : Set X} {p : X}
    (belongs : p ∈ pSet) (h : Disjoint (Metric.ball J r) pSet) :
    dist J p ≥ r := by
  sorry

lemma dist_triangle5 (a b c d e : X) :
    dist a e ≤ dist a b + dist b c + dist c d + dist d e := by
  sorry

lemma 𝓘_subset_iUnion_𝓙_𝔖₀ : (𝓘 u₁ : Set X) ⊆ ⋃ J ∈ 𝓙 (t.𝔖₀ u₁ u₂), (J : Set X) := by
  sorry

/- AUXILIARY LEMMAS:END -/

/-! ### Subsection 7.5.1 and Lemma 7.5.2 -/

/-- Part of Lemma 7.5.1. -/
lemma union_𝓙₅ (hu₁ : u₁ ∈ t) (hu₂ : u₂ ∈ t) (hu : u₁ ≠ u₂) (h2u : 𝓘 u₁ ≤ 𝓘 u₂) :
    ⋃ J ∈ 𝓙₅ t u₁ u₂, (J : Set X) = 𝓘 u₁ := by
  sorry

/-- Part of Lemma 7.5.1. -/
lemma pairwiseDisjoint_𝓙₅ : (𝓙₅ t u₁ u₂).PairwiseDisjoint (fun I ↦ (I : Set X)) := by
  sorry

open scoped Classical in
lemma four_lt_sum_χtilde
    (hu₁ : u₁ ∈ t) (hu₂ : u₂ ∈ t) (hu : u₁ ≠ u₂) (h2u : 𝓘 u₁ ≤ 𝓘 u₂) (hx : x ∈ 𝓘 u₁) :
    4 < ∑ J' ∈ 𝓙₅ t u₁ u₂, χtilde J' u₁ x := by
  sorry

lemma bigger_than_𝓙_is_not_in_𝓙₀ {𝔖 : Set (𝔓 X)} {A B : Grid X}
    (le : A ≤ B) (sle : s A < s B) (A_in : A ∈ 𝓙 𝔖) :
    B ∉ 𝓙₀ 𝔖 := by
  sorry

/-- Lemma 7.5.3 (stated somewhat differently). -/
lemma moderate_scale_change (hJ : J ∈ 𝓙₅ t u₁ u₂) (hJ' : J' ∈ 𝓙₅ t u₁ u₂)
    (hd : ¬Disjoint (ball (c J) (8 * D ^ s J)) (ball (c J') (8 * D ^ s J'))) :
    s J - 1 ≤ s J' := by
  sorry

open scoped Classical in
/-- Part of Lemma 7.5.2. -/
lemma sum_χ (hu₁ : u₁ ∈ t) (hu₂ : u₂ ∈ t) (hu : u₁ ≠ u₂) (h2u : 𝓘 u₁ ≤ 𝓘 u₂) (x : X) :
    ∑ J ∈ 𝓙₅ t u₁ u₂, χ t u₁ u₂ J x = (𝓘 u₁ : Set X).indicator 1 x := by
  sorry

/-- Part of Lemma 7.5.2. -/
lemma χ_le_indicator (hJ : J ∈ 𝓙₅ t u₁ u₂) :
    χ t u₁ u₂ J x ≤ (ball (c J) (8 * D ^ s J)).indicator 1 x := by
  sorry

lemma χ_eq_zero_of_notMem_ball (hJ : J ∈ 𝓙₅ t u₁ u₂) (nx : x ∉ ball (c J) (8 * D ^ s J)) :
    χ t u₁ u₂ J x = 0 := by
  sorry

lemma boundedCompactSupport_toReal_χ (hJ : J ∈ 𝓙₅ t u₁ u₂) :
    BoundedCompactSupport fun x ↦ (χ t u₁ u₂ J x : ℝ) := by
  sorry

/-- The constant used in `dist_χ_le`.
Has value `2 ^ (227 * a ^ 3)` in the blueprint. -/
irreducible_def C7_5_2 (a : ℕ) : ℝ≥0 := 2 ^ ((2 * 𝕔 + 2 + 𝕔 / 4) * a ^ 3)

lemma one_le_C7_5_2 : 1 ≤ C7_5_2 a := by
  sorry

open scoped Classical in
lemma quarter_add_two_mul_D_mul_card_le (hJ : J ∈ 𝓙₅ t u₁ u₂) :
    1 / 4 + 2 * (D : ℝ) * {J' ∈ (𝓙₅ t u₁ u₂).toFinset |
      ¬Disjoint (ball (c J) (8 * D ^ s J)) (ball (c J') (8 * D ^ s J'))}.card ≤ C7_5_2 a := by
  sorry

/-- Part of Lemma 7.5.2. -/
lemma dist_χ_le (hu₁ : u₁ ∈ t) (hu₂ : u₂ ∈ t) (hu : u₁ ≠ u₂)
    (h2u : 𝓘 u₁ ≤ 𝓘 u₂) (hJ : J ∈ 𝓙₅ t u₁ u₂) (mx : x ∈ 𝓘 u₁) (mx' : x' ∈ 𝓘 u₁) :
    dist (χ t u₁ u₂ J x) (χ t u₁ u₂ J x') ≤ C7_5_2 a * dist x x' / D ^ s J := by
  sorry

/-! ### Subsection 7.5.2 and Lemma 7.5.4 -/

/-- The constant used in `holder_correlation_tile`.
Has value `2 ^ (128 * a ^ 3)` in the blueprint. -/
irreducible_def C7_5_5 (a : ℕ) : ℝ≥0 := 2 ^ ((𝕔 + 3 + 𝕔 / 4) * a ^ 3)

section OneInOneOut

omit [ProofData a q K σ₁ σ₂ F G] in
lemma ψ_le_max [ProofData a q K σ₁ σ₂ F G] {x : ℝ} : ψ x ≤ max 0 ((2 - 4 * x) ^ (a : ℝ)⁻¹) := by
  sorry

lemma le_of_mem_E {y : X} (hy : y ∈ E p) (hx' : x' ∉ ball (𝔠 p) (5 * D ^ 𝔰 p)) :
    2 - 4 * ((D : ℝ) ^ (-𝔰 p) * dist y x) ≤ dist x x' / D ^ (𝔰 p) * 4 := by
  sorry

lemma enorm_ψ_le_edist {y : X} (my : y ∈ E p) (hx' : x' ∉ ball (𝔠 p) (5 * D ^ 𝔰 p)) :
    ‖ψ (D ^ (-𝔰 p) * dist y x)‖ₑ ≤ 4 * (edist x x' / D ^ 𝔰 p) ^ (a : ℝ)⁻¹ := by
  sorry

lemma holder_correlation_tile_one
    (hf : BoundedCompactSupport f) (hx' : x' ∉ ball (𝔠 p) (5 * D ^ 𝔰 p)) :
    ‖adjointCarleson p f x‖ₑ ≤ C7_5_5 a / volume (ball (𝔠 p) (4 * D ^ 𝔰 p)) *
      (edist x x' / D ^ 𝔰 p) ^ (a : ℝ)⁻¹ * ∫⁻ x in E p, ‖f x‖ₑ := by
  sorry

end OneInOneOut

section BothIn

lemma integrable_adjointCarleson_interior (hf : BoundedCompactSupport f) :
    Integrable (fun y ↦ exp (.I * 𝒬 u x) * (conj (Ks (𝔰 p) y x) * exp (.I * (Q y y - Q y x)) * f y))
      (volume.restrict (E p)) := by
  sorry

attribute [fun_prop] continuous_conj Continuous.comp_aestronglyMeasurable

set_option backward.isDefEq.respectTransparency false in
/-- Sub-equations (7.5.10) and (7.5.11) in Lemma 7.5.5. -/
lemma holder_correlation_rearrange (hf : BoundedCompactSupport f) :
    edist (exp (.I * 𝒬 u x) * adjointCarleson p f x) (exp (.I * 𝒬 u x') * adjointCarleson p f x') ≤
    (∫⁻ y in E p, ‖f y‖ₑ * ‖Ks (𝔰 p) y x‖ₑ * ‖- Q y x + Q y x' + 𝒬 u x - 𝒬 u x'‖ₑ) +
      ∫⁻ y in E p, ‖f y‖ₑ * ‖Ks (𝔰 p) y x - Ks (𝔰 p) y x'‖ₑ := by
  sorry

/-- Multiplicative factor for the bound on `‖- Q y x + Q y x' + 𝒬 u x - 𝒬 u x'‖ₑ`. -/
irreducible_def Q7_5_5 (a : ℕ) : ℝ≥0 := 10 * 2 ^ (6 * a)

lemma QQQQ_bound_real {y : X} (my : y ∈ E p) (hu : u ∈ t) (hp : p ∈ t u)
    (hx : x ∈ ball (𝔠 p) (5 * D ^ 𝔰 p)) (hx' : x' ∈ ball (𝔠 p) (5 * D ^ 𝔰 p)) :
    ‖-Q y x + Q y x' + 𝒬 u x - 𝒬 u x'‖ ≤ Q7_5_5 a * (dist x x' / D ^ 𝔰 p) ^ (a : ℝ)⁻¹ := by
  sorry

lemma QQQQ_bound {y : X} (my : y ∈ E p) (hu : u ∈ t) (hp : p ∈ t u)
    (hx : x ∈ ball (𝔠 p) (5 * D ^ 𝔰 p)) (hx' : x' ∈ ball (𝔠 p) (5 * D ^ 𝔰 p)) :
    ‖-Q y x + Q y x' + 𝒬 u x - 𝒬 u x'‖ₑ ≤ Q7_5_5 a * (edist x x' / D ^ 𝔰 p) ^ (a : ℝ)⁻¹ := by
  sorry

lemma holder_correlation_tile_two (hu : u ∈ t) (hp : p ∈ t u) (hf : BoundedCompactSupport f)
    (hx : x ∈ ball (𝔠 p) (5 * D ^ 𝔰 p)) (hx' : x' ∈ ball (𝔠 p) (5 * D ^ 𝔰 p)) :
    edist (exp (.I * 𝒬 u x) * adjointCarleson p f x) (exp (.I * 𝒬 u x') * adjointCarleson p f x') ≤
    C7_5_5 a / volume (ball (𝔠 p) (4 * D ^ 𝔰 p)) *
      (edist x x' / D ^ 𝔰 p) ^ (a : ℝ)⁻¹ * ∫⁻ x in E p, ‖f x‖ₑ := by
  sorry

end BothIn

/-- Lemma 7.5.5. -/
lemma holder_correlation_tile (hu : u ∈ t) (hp : p ∈ t u) (hf : BoundedCompactSupport f) :
    edist (exp (.I * 𝒬 u x) * adjointCarleson p f x) (exp (.I * 𝒬 u x') * adjointCarleson p f x') ≤
    C7_5_5 a / volume (ball (𝔠 p) (4 * D ^ 𝔰 p)) *
      (edist x x' / D ^ 𝔰 p) ^ (a : ℝ)⁻¹ * ∫⁻ x in E p, ‖f x‖ₑ := by
  sorry

/-- Part of Lemma 7.5.6. -/
lemma limited_scale_impact_first_estimate (hu₁ : u₁ ∈ t) (hu₂ : u₂ ∈ t) (hu : u₁ ≠ u₂)
    (h2u : 𝓘 u₁ ≤ 𝓘 u₂) (hp : p ∈ t u₂ \ 𝔖₀ t u₁ u₂) (hJ : J ∈ 𝓙₅ t u₁ u₂)
    (h : ¬Disjoint (ball (𝔠 p) (8 * D ^ 𝔰 p)) (ball (c J) (8⁻¹ * D ^ s J))) : s J ≤ 𝔰 p := by
  sorry

/-- Part of Lemma 7.5.6. -/
lemma limited_scale_impact_second_estimate (hp : p ∈ t u₂ \ 𝔖₀ t u₁ u₂) (hJ : J ∈ 𝓙₅ t u₁ u₂)
    (h : ¬Disjoint (ball (𝔠 p) (8 * D ^ 𝔰 p)) (ball (c J) (8⁻¹ * D ^ s J))) :
    𝔰 p ≤ s J + 3 := by
  sorry

/-- Lemma 7.5.6. -/
lemma limited_scale_impact (hu₁ : u₁ ∈ t) (hu₂ : u₂ ∈ t) (hu : u₁ ≠ u₂)
    (h2u : 𝓘 u₁ ≤ 𝓘 u₂) (hp : p ∈ t u₂ \ 𝔖₀ t u₁ u₂) (hJ : J ∈ 𝓙₅ t u₁ u₂)
    (h : ¬ Disjoint (ball (𝔠 p) (8 * D ^ 𝔰 p)) (ball (c J) (8⁻¹ * D ^ s J))) :
    𝔰 p ∈ Icc (s J) (s J + 3) := by
  sorry

open scoped Classical in
lemma local_tree_control_sumsumsup (hu₁ : u₁ ∈ t) (hu₂ : u₂ ∈ t) (hu : u₁ ≠ u₂)
    (h2u : 𝓘 u₁ ≤ 𝓘 u₂) (hJ : J ∈ 𝓙₅ t u₁ u₂) :
    ⨆ x ∈ ball (c J) (8⁻¹ * D ^ s J), ‖adjointCarlesonSum (t u₂ \ 𝔖₀ t u₁ u₂) f x‖ₑ ≤
    ∑ k ∈ Finset.Icc (s J) (s J + 3),
    ∑ p with 𝔰 p = k ∧ ¬Disjoint (ball (𝔠 p) (8 * D ^ 𝔰 p)) (ball (c J) (8⁻¹ * D ^ s J)),
      ⨆ x ∈ ball (c J) (8⁻¹ * D ^ s J), ‖adjointCarleson p f x‖ₑ := by
  sorry

lemma local_tree_control_sup_bound {k : ℤ} (mk : k ∈ Finset.Icc (s J) (s J + 3))
    (mp : 𝔰 p = k ∧ ¬Disjoint (ball (𝔠 p) (8 * D ^ 𝔰 p)) (ball (c J) (8⁻¹ * D ^ s J)))
    (nfm : AEMeasurable fun x ↦ ‖f x‖ₑ) :
    ⨆ x ∈ ball (c J) (8⁻¹ * D ^ s J), ‖adjointCarleson p f x‖ₑ ≤
    2 ^ ((𝕔 + 3) * a ^ 3) * (volume (ball (c J) (16 * D ^ k)))⁻¹ * ∫⁻ x in E p, ‖f x‖ₑ := by
  sorry

/-- The constant used in `local_tree_control`.
Has value `2 ^ (104 * a ^ 3)` in the blueprint. -/
irreducible_def C7_5_7 (a : ℕ) : ℝ≥0 := 2 ^ ((𝕔 + 4) * a ^ 3)

/-- Lemma 7.5.7. -/
lemma local_tree_control (hu₁ : u₁ ∈ t) (hu₂ : u₂ ∈ t) (hu : u₁ ≠ u₂)
    (h2u : 𝓘 u₁ ≤ 𝓘 u₂) (hJ : J ∈ 𝓙₅ t u₁ u₂) (hf : BoundedCompactSupport f) :
    ⨆ x ∈ ball (c J) (8⁻¹ * D ^ s J), ‖adjointCarlesonSum (t u₂ \ 𝔖₀ t u₁ u₂) f x‖ₑ ≤
    C7_5_7 a * ⨅ x ∈ J, MB volume 𝓑 c𝓑 r𝓑 f x := by
  sorry

/-- Lemma 7.5.8. -/
lemma scales_impacting_interval (hu₁ : u₁ ∈ t) (hu₂ : u₂ ∈ t) (hu : u₁ ≠ u₂)
    (h2u : 𝓘 u₁ ≤ 𝓘 u₂) (hJ : J ∈ 𝓙₅ t u₁ u₂) (hp : p ∈ t u₁ ∪ (t u₂ ∩ 𝔖₀ t u₁ u₂))
    (h : ¬Disjoint (ball (𝔠 p) (8 * D ^ 𝔰 p)) (ball (c J) (16 * D ^ s J))) : s J ≤ 𝔰 p := by
  sorry

lemma volume_cpDsp_bound {J : Grid X}
    (hd : ¬Disjoint (ball (𝔠 p) (8 * D ^ 𝔰 p)) (ball (c J) (16 * D ^ s J))) (hs : s J ≤ 𝔰 p) :
    volume (ball (c J) (32 * D ^ 𝔰 p)) / 2 ^ (4 * a) ≤ volume (ball (𝔠 p) (4 * D ^ 𝔰 p)) := by
  sorry

open scoped Classical in
lemma gtc_integral_bound {k : ℤ} {ℭ : Set (𝔓 X)}
    (hs : ∀ p ∈ ℭ, ¬Disjoint (ball (𝔠 p) (8 * D ^ 𝔰 p)) (ball (c J) (16 * D ^ s J)) → s J ≤ 𝔰 p) :
    ∑ p ∈ ℭ with ¬Disjoint (ball (𝔠 p) (8 * D ^ 𝔰 p)) (ball (c J) (16 * D ^ s J)) ∧ 𝔰 p = k,
      ∫⁻ x in E p, ‖f x‖ₑ ≤
    ∫⁻ x in ball (c J) (32 * D ^ k), ‖f x‖ₑ := by
  sorry

/-- Part 1 of equation (7.5.18) of Lemma 7.5.9. -/
lemma global_tree_control1_edist_part1
    (hu : u ∈ t) {ℭ : Set (𝔓 X)} (hℭ : ℭ ⊆ t u) (hf : BoundedCompactSupport f)
    (hs : ∀ p ∈ ℭ, ¬Disjoint (ball (𝔠 p) (8 * D ^ 𝔰 p)) (ball (c J) (16 * D ^ s J)) → s J ≤ 𝔰 p)
    (hx : x ∈ ball (c J) (16 * D ^ s J)) (hx' : x' ∈ ball (c J) (16 * D ^ s J)) :
    edist (exp (.I * 𝒬 u x) * adjointCarlesonSum ℭ f x)
      (exp (.I * 𝒬 u x') * adjointCarlesonSum ℭ f x') ≤
    C7_5_5 a * 2 ^ (4 * a) * edist x x' ^ (a : ℝ)⁻¹ * ∑ k ∈ Finset.Icc (s J) S,
        D ^ (-k / (a : ℝ)) * ⨍⁻ x in ball (c J) (32 * D ^ k), ‖f x‖ₑ ∂volume := by
  sorry

lemma gtc_sum_Icc_le_two : ∑ k ∈ Finset.Icc (s J) S, (D : ℝ≥0∞) ^ ((s J - k) / (a : ℝ)) ≤ 2 := by
  sorry

/-- The constant used in `global_tree_control1_edist`.
Has value `2 ^ (128 * a ^ 3 + 4 * a + 1)` in the blueprint. -/
irreducible_def C7_5_9d (a : ℕ) : ℝ≥0 := C7_5_5 a * 2 ^ (4 * a + 1)

/-- Part 2 of equation (7.5.18) of Lemma 7.5.9. -/
lemma global_tree_control1_edist_part2
    (hu : u ∈ t) {ℭ : Set (𝔓 X)} (hℭ : ℭ ⊆ t u) (hf : BoundedCompactSupport f)
    (hs : ∀ p ∈ ℭ, ¬Disjoint (ball (𝔠 p) (8 * D ^ 𝔰 p)) (ball (c J) (16 * D ^ s J)) → s J ≤ 𝔰 p)
    (hx : x ∈ ball (c J) (16 * D ^ s J)) (hx' : x' ∈ ball (c J) (16 * D ^ s J)) :
    edist (exp (.I * 𝒬 u x) * adjointCarlesonSum ℭ f x)
      (exp (.I * 𝒬 u x') * adjointCarlesonSum ℭ f x') ≤
    C7_5_9d a * (edist x x' / D ^ s J) ^ (a : ℝ)⁻¹ * ⨅ x ∈ J, MB volume 𝓑 c𝓑 r𝓑 f x := by
  sorry

/-- Equation (7.5.18) of Lemma 7.5.9 for `ℭ = t u₁`. -/
lemma global_tree_control1_edist_left (hu₁ : u₁ ∈ t) (hu₂ : u₂ ∈ t) (hu : u₁ ≠ u₂)
    (h2u : 𝓘 u₁ ≤ 𝓘 u₂) (hJ : J ∈ 𝓙₅ t u₁ u₂) (hf : BoundedCompactSupport f)
    (hx : x ∈ ball (c J) (16 * D ^ s J)) (hx' : x' ∈ ball (c J) (16 * D ^ s J)) :
    edist (exp (.I * 𝒬 u₁ x) * adjointCarlesonSum (t u₁) f x)
      (exp (.I * 𝒬 u₁ x') * adjointCarlesonSum (t u₁) f x') ≤
    C7_5_9d a * (edist x x' / D ^ s J) ^ (a : ℝ)⁻¹ * ⨅ x ∈ J, MB volume 𝓑 c𝓑 r𝓑 f x := by
  sorry

/-- Equation (7.5.18) of Lemma 7.5.9 for `ℭ = t u₂ ∩ 𝔖₀ t u₁ u₂`. -/
lemma global_tree_control1_edist_right (hu₁ : u₁ ∈ t) (hu₂ : u₂ ∈ t) (hu : u₁ ≠ u₂)
    (h2u : 𝓘 u₁ ≤ 𝓘 u₂) (hJ : J ∈ 𝓙₅ t u₁ u₂) (hf : BoundedCompactSupport f)
    (hx : x ∈ ball (c J) (16 * D ^ s J)) (hx' : x' ∈ ball (c J) (16 * D ^ s J)) :
    edist (exp (.I * 𝒬 u₂ x) * adjointCarlesonSum (t u₂ ∩ 𝔖₀ t u₁ u₂) f x)
      (exp (.I * 𝒬 u₂ x') * adjointCarlesonSum (t u₂ ∩ 𝔖₀ t u₁ u₂) f x') ≤
    C7_5_9d a * (edist x x' / D ^ s J) ^ (a : ℝ)⁻¹ * ⨅ x ∈ J, MB volume 𝓑 c𝓑 r𝓑 f x := by
  sorry

/-- The constant used in `global_tree_control1_supbound`.
Has value `2 ^ (128 * a ^ 3 + 4 * a + 3)` in the blueprint. -/
irreducible_def C7_5_9s (a : ℕ) : ℝ≥0 := C7_5_5 a * 2 ^ (4 * a + 3)

lemma one_le_C7_5_9s : 1 ≤ C7_5_9s a := by
  sorry

lemma C7_5_9d_le_C7_5_9s : C7_5_9d a ≤ C7_5_9s a := by
  sorry

/-- Equation (7.5.17) of Lemma 7.5.9. -/
lemma global_tree_control1_supbound (hu₁ : u₁ ∈ t) (hu₂ : u₂ ∈ t) (hu : u₁ ≠ u₂)
    (h2u : 𝓘 u₁ ≤ 𝓘 u₂) (ℭ : Set (𝔓 X)) (hℭ : ℭ = t u₁ ∨ ℭ = t u₂ ∩ 𝔖₀ t u₁ u₂)
    (hJ : J ∈ 𝓙₅ t u₁ u₂) (hf : BoundedCompactSupport f) :
    ⨆ x ∈ ball (c J) (16 * D ^ s J), ‖adjointCarlesonSum ℭ f x‖ₑ ≤
    (⨅ x ∈ ball (c J) (8⁻¹ * D ^ s J), ‖adjointCarlesonSum ℭ f x‖ₑ) +
    C7_5_9s a * ⨅ x ∈ J, MB volume 𝓑 c𝓑 r𝓑 f x := by
  sorry

/-- The constant used in `global_tree_control2`.
Has value `2 ^ (129 * a ^ 3)` in the blueprint. -/
irreducible_def C7_5_10 (a : ℕ) : ℝ≥0 := 2 ^ ((𝕔 + 4 + 𝕔 / 4) * a ^ 3)

lemma le_C7_5_10 (ha : 4 ≤ a) : C7_5_7 a + C7_5_9s a ≤ C7_5_10 a := by
  sorry

lemma C7_5_9s_le_C7_5_10 (ha : 4 ≤ a) : C7_5_9s a ≤ C7_5_10 a := by
  sorry

lemma one_le_C7_5_10 (ha : 4 ≤ a) : 1 ≤ C7_5_10 a := by
  sorry

/-- Lemma 7.5.10 -/
lemma global_tree_control2 (hu₁ : u₁ ∈ t) (hu₂ : u₂ ∈ t) (hu : u₁ ≠ u₂)
    (h2u : 𝓘 u₁ ≤ 𝓘 u₂) (hJ : J ∈ 𝓙₅ t u₁ u₂) (hf : BoundedCompactSupport f) :
    ⨆ x ∈ ball (c J) (16 * D ^ s J), ‖adjointCarlesonSum (t u₂ ∩ 𝔖₀ t u₁ u₂) f x‖ₑ ≤
    (⨅ x ∈ ball (c J) (8⁻¹ * D ^ s J), ‖adjointCarlesonSum (t u₂) f x‖ₑ) +
    C7_5_10 a * ⨅ x ∈ J, MB volume 𝓑 c𝓑 r𝓑 f x := by
  sorry

/-- The product on the right-hand side of Lemma 7.5.4. -/
def P7_5_4 (t : Forest X n) (u₁ u₂ : 𝔓 X) (f₁ f₂ : X → ℂ) (J : Grid X) : ℝ≥0∞ :=
  ((⨅ x ∈ ball (c J) (8⁻¹ * D ^ s J), ‖adjointCarlesonSum (t u₁) f₁ x‖ₑ) +
    ⨅ x ∈ J, MB volume 𝓑 c𝓑 r𝓑 f₁ x) *
  ((⨅ x ∈ ball (c J) (8⁻¹ * D ^ s J), ‖adjointCarlesonSum (t u₂) f₂ x‖ₑ) +
    ⨅ x ∈ J, MB volume 𝓑 c𝓑 r𝓑 f₂ x)

lemma P7_5_4_le_adjointBoundaryOperator_mul (mx : x ∈ ball (c J) (8⁻¹ * D ^ s J)) :
    P7_5_4 t u₁ u₂ f₁ f₂ J ≤
    adjointBoundaryOperator t u₁ f₁ x * adjointBoundaryOperator t u₂ f₂ x := by
  sorry

/-- The support of `holderFunction` is in `𝓘 u₁`. -/
lemma support_holderFunction_subset (u₂ : 𝔓 X) (f₁ f₂ : X → ℂ) (J : Grid X) (hu₁ : u₁ ∈ t) :
    support (holderFunction t u₁ u₂ f₁ f₂ J) ⊆ 𝓘 u₁ := by
  sorry

lemma enorm_holderFunction_le (hu₁ : u₁ ∈ t) (hu₂ : u₂ ∈ t) (hu : u₁ ≠ u₂) (h2u : 𝓘 u₁ ≤ 𝓘 u₂)
    (hJ : J ∈ 𝓙₅ t u₁ u₂) (hf₁ : BoundedCompactSupport f₁) (hf₂ : BoundedCompactSupport f₂)
    (mx : x ∈ ball (c J) (16 * D ^ s J)) :
    ‖holderFunction t u₁ u₂ f₁ f₂ J x‖ₑ ≤ C7_5_9s a * C7_5_10 a * P7_5_4 t u₁ u₂ f₁ f₂ J := by
  sorry

lemma holder_correlation_tree_1 (hu₁ : u₁ ∈ t) (hu₂ : u₂ ∈ t) (hu : u₁ ≠ u₂) (h2u : 𝓘 u₁ ≤ 𝓘 u₂)
    (hJ : J ∈ 𝓙₅ t u₁ u₂) (hf₁ : BoundedCompactSupport f₁) (hf₂ : BoundedCompactSupport f₂)
    (mx : x ∈ ball (c J) (16 * D ^ s J)) (mx' : x' ∈ 𝓘 u₁) :
    edist (χ t u₁ u₂ J x) (χ t u₁ u₂ J x') *
    ‖exp (.I * 𝒬 u₁ x) * adjointCarlesonSum (t u₁) f₁ x‖ₑ *
    ‖exp (.I * 𝒬 u₂ x) * adjointCarlesonSum (t u₂ ∩ 𝔖₀ t u₁ u₂) f₂ x‖ₑ ≤
    C7_5_2 a * C7_5_9s a * C7_5_10 a * P7_5_4 t u₁ u₂ f₁ f₂ J * (edist x x' / D ^ s J) := by
  sorry

lemma holder_correlation_tree_2 (hu₁ : u₁ ∈ t) (hu₂ : u₂ ∈ t) (hu : u₁ ≠ u₂) (h2u : 𝓘 u₁ ≤ 𝓘 u₂)
    (hJ : J ∈ 𝓙₅ t u₁ u₂) (hf₁ : BoundedCompactSupport f₁) (hf₂ : BoundedCompactSupport f₂)
    (mx : x ∈ ball (c J) (16 * D ^ s J)) (mx' : x' ∈ ball (c J) (16 * D ^ s J)) :
    χ t u₁ u₂ J x' * edist (exp (.I * 𝒬 u₁ x) * adjointCarlesonSum (t u₁) f₁ x)
      (exp (.I * 𝒬 u₁ x') * adjointCarlesonSum (t u₁) f₁ x') *
    ‖exp (.I * 𝒬 u₂ x) * adjointCarlesonSum (t u₂ ∩ 𝔖₀ t u₁ u₂) f₂ x‖ₑ ≤
    C7_5_9d a * C7_5_10 a * P7_5_4 t u₁ u₂ f₁ f₂ J * (edist x x' / D ^ s J) ^ (a : ℝ)⁻¹ := by
  sorry

lemma holder_correlation_tree_3 (hu₁ : u₁ ∈ t) (hu₂ : u₂ ∈ t) (hu : u₁ ≠ u₂) (h2u : 𝓘 u₁ ≤ 𝓘 u₂)
    (hJ : J ∈ 𝓙₅ t u₁ u₂) (hf₁ : BoundedCompactSupport f₁) (hf₂ : BoundedCompactSupport f₂)
    (mx : x ∈ ball (c J) (16 * D ^ s J)) (mx' : x' ∈ ball (c J) (16 * D ^ s J)) :
    χ t u₁ u₂ J x' * ‖exp (.I * 𝒬 u₁ x') * adjointCarlesonSum (t u₁) f₁ x'‖ₑ *
    edist (exp (.I * 𝒬 u₂ x) * adjointCarlesonSum (t u₂ ∩ 𝔖₀ t u₁ u₂) f₂ x)
      (exp (.I * 𝒬 u₂ x') * adjointCarlesonSum (t u₂ ∩ 𝔖₀ t u₁ u₂) f₂ x') ≤
    C7_5_9s a * C7_5_9d a * P7_5_4 t u₁ u₂ f₁ f₂ J * (edist x x' / D ^ s J) ^ (a : ℝ)⁻¹ := by
  sorry

/-- An intermediate constant in Lemma 7.5.4. -/
def I7_5_4 (a : ℕ) : ℝ≥0 := 2 ^ ((4 * 𝕔 + 9 + 3 * (𝕔 / 4)) * a ^ 3 + 12 * a)

lemma le_I7_5_4 (ha : 4 ≤ a) :
    32 * C7_5_2 a * C7_5_9s a * C7_5_10 a + C7_5_9d a * C7_5_10 a + C7_5_9s a * C7_5_9d a
    ≤ I7_5_4 a := by
  sorry

lemma edist_holderFunction_le (hu₁ : u₁ ∈ t) (hu₂ : u₂ ∈ t) (hu : u₁ ≠ u₂) (h2u : 𝓘 u₁ ≤ 𝓘 u₂)
    (hJ : J ∈ 𝓙₅ t u₁ u₂) (hf₁ : BoundedCompactSupport f₁) (hf₂ : BoundedCompactSupport f₂)
    (mx : x ∈ ball (c J) (16 * D ^ s J)) (mx' : x' ∈ ball (c J) (16 * D ^ s J)) :
    edist (holderFunction t u₁ u₂ f₁ f₂ J x) (holderFunction t u₁ u₂ f₁ f₂ J x') ≤
    I7_5_4 a * P7_5_4 t u₁ u₂ f₁ f₂ J * (edist x x' / D ^ s J) ^ (a : ℝ)⁻¹ := by
  sorry

/-- The constant used in `holder_correlation_tree`.
Has value `2 ^ (485 * a ^ 3)` in the blueprint. -/
irreducible_def C7_5_4 (a : ℕ) : ℝ≥0 := 2 ^ ((4 * 𝕔 + 10 + 3 * (𝕔 / 4)) * a ^ 3)

lemma le_C7_5_4 (ha : 4 ≤ a) :
    C7_5_9s a * C7_5_10 a + 16 ^ τ * I7_5_4 a ≤ C7_5_4 a := by
  sorry

/-- Lemma 7.5.4. -/
lemma holder_correlation_tree (hu₁ : u₁ ∈ t) (hu₂ : u₂ ∈ t) (hu : u₁ ≠ u₂) (h2u : 𝓘 u₁ ≤ 𝓘 u₂)
    (hJ : J ∈ 𝓙₅ t u₁ u₂) (hf₁ : BoundedCompactSupport f₁) (hf₂ : BoundedCompactSupport f₂) :
    iHolENorm (holderFunction t u₁ u₂ f₁ f₂ J) (c J) (16 * D ^ s J) τ ≤
    C7_5_4 a * P7_5_4 t u₁ u₂ f₁ f₂ J := by
  sorry

/-! ### Subsection 7.5.3 and Lemma 7.4.5 -/

/-- The constant used in `lower_oscillation_bound`.
Has value `2 ^ (Z * n / 2 - 201 * a ^ 3)` in the blueprint. -/
irreducible_def C7_5_11 (a n : ℕ) : ℝ≥0 := 2 ^ (Z * n / 2 - (2 * 𝕔 + 1) * (a : ℝ) ^ 3)

/-- A binomial bound used in Lemma 7.4.5. -/
lemma C7_5_11_binomial_bound (a4 : 4 ≤ a) :
    (1 + C7_5_11 a n : ℝ≥0∞) ^ (-(2 * a ^ 2 + a ^ 3 : ℝ)⁻¹) ≤
    2 ^ ((𝕔 / 4) * a ^ 3 + 7) * 2 ^ (-(Z * n : ℝ) / (4 * a ^ 2 + 2 * a ^ 3)) := by
  sorry

/-- Lemma 7.5.11 -/
lemma lower_oscillation_bound (hu₁ : u₁ ∈ t) (hu₂ : u₂ ∈ t) (hu : u₁ ≠ u₂)
    (h2u : 𝓘 u₁ ≤ 𝓘 u₂) (hJ : J ∈ 𝓙₅ t u₁ u₂) :
    C7_5_11 a n ≤ dist_{c J, 8 * D ^ s J} (𝒬 u₁) (𝒬 u₂) := by
  sorry

open Classical in
lemma cdtp_le_iHolENorm (hu₁ : u₁ ∈ t) (hu₂ : u₂ ∈ t) (hu : u₁ ≠ u₂)
    (h2u : 𝓘 u₁ ≤ 𝓘 u₂) (hf₁ : BoundedCompactSupport f₁) (hf₂ : BoundedCompactSupport f₂) :
    ‖∫ x, adjointCarlesonSum (t u₁) f₁ x * conj (adjointCarlesonSum (t u₂ ∩ 𝔖₀ t u₁ u₂) f₂ x)‖ₑ ≤
    ∑ J ∈ 𝓙₅ t u₁ u₂, C2_0_5 a * volume (ball (c J) (8 * D ^ s J)) *
      iHolENorm (holderFunction t u₁ u₂ f₁ f₂ J) (c J) (2 * (8 * D ^ s J)) τ *
      (1 + edist_{c J, 8 * D ^ s J} (𝒬 u₂) (𝒬 u₁)) ^ (-(2 * a^2 + a^3 : ℝ)⁻¹) := by
  sorry

/-- The constant used in `correlation_distant_tree_parts`.
Has value `2 ^ (511 * a ^ 3) * 2 ^ (-(Z n) / (4a^2 + 2a^3))` in the blueprint. -/
irreducible_def C7_4_5 (a n : ℕ) : ℝ≥0 :=
  2 ^ ((4 * 𝕔 + 11 + 4 * (𝕔 / 4)) * a ^ 3) * 2 ^ (-(Z * n : ℝ) / (4 * a ^ 2 + 2 * a ^ 3))

lemma le_C7_4_5 (a4 : 4 ≤ a) :
    C2_0_5 a * C7_5_4 a * 2 ^ ((𝕔 / 4) * a ^ 3 + 7 + 6 * a)
      * 2 ^ (-(Z * n : ℝ) / (4 * a ^ 2 + 2 * a ^ 3)) ≤ C7_4_5 a n := by
  sorry

/-- Lemma 7.4.5 -/
lemma correlation_distant_tree_parts (hu₁ : u₁ ∈ t) (hu₂ : u₂ ∈ t) (hu : u₁ ≠ u₂)
    (h2u : 𝓘 u₁ ≤ 𝓘 u₂) (hf₁ : BoundedCompactSupport f₁) (hf₂ : BoundedCompactSupport f₂) :
    ‖∫ x, adjointCarlesonSum (t u₁) f₁ x * conj (adjointCarlesonSum (t u₂ ∩ 𝔖₀ t u₁ u₂) f₂ x)‖ₑ ≤
    C7_4_5 a n *
    eLpNorm ((𝓘 u₁ : Set X).indicator (adjointBoundaryOperator t u₁ f₁) ·) 2 volume *
    eLpNorm ((𝓘 u₁ : Set X).indicator (adjointBoundaryOperator t u₂ f₂) ·) 2 volume := by
  sorry

end TileStructure.Forest
