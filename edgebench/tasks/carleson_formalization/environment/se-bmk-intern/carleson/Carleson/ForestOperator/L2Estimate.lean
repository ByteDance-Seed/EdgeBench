module

public import Carleson.ForestOperator.PointwiseEstimate
public import Carleson.ToMathlib.MeasureTheory.Integral.MeanInequalities

@[expose] public section

noncomputable section

open Set MeasureTheory Metric Function Complex Bornology TileStructure Filter
open scoped NNReal ENNReal ComplexConjugate

open ShortVariables
variable {X : Type*} {a : ℕ} {q : ℝ} {K : X → X → ℂ} {σ₁ σ₂ : X → ℤ} {F G : Set X}
  [MetricSpace X] [ProofData a q K σ₁ σ₂ F G] {f : X → ℂ}

lemma integrableOn_K_mul_f {x' : X} (hf : BoundedCompactSupport f volume) {r : ℝ≥0∞} (hr : 0 < r) :
    IntegrableOn (fun y ↦ K x' y * f y) (EAnnulus.ci x' r) := by
  sorry

-- Truncated version of `K` used in proof of `nontangential_pointwise_bound`
private def K' (b : ℤ) (c : ℤ) (x y : X) := ∑ i ∈ (Icc b c).toFinset, Ks i x y

namespace K'

private lemma eq_K (b : ℤ) (c : ℤ) (x y : X)
    (h : dist x y ∈ Icc ((D : ℝ) ^ (b - 1) / 2) (D ^ c / 4)) : K' b c x y = K x y := by
  sorry

private lemma integrableOn_mul_f {x' : X} (hf : BoundedCompactSupport f) {r : ℝ≥0∞} (hr : 0 < r)
    (s₁ s₂ : ℤ) : IntegrableOn (fun y ↦ K' s₁ s₂ x' y * f y) (EAnnulus.ci x' r) := by
  sorry

private lemma support_subset (b : ℤ) (c : ℤ) (x : X) :
    support (K' b c x) ⊆ Annulus.cc x (D ^ (b - 1) / 4) (D ^ c / 2) := by
  sorry

private lemma enorm_le_enorm_K (a : ℤ) (b : ℤ) (x y : X) : ‖K' a b x y‖ₑ ≤ ‖K x y‖ₑ := by
  sorry

end K'

-- Bound needed for proof of `nontangential_pointwise_bound`, splitting the annulus between radii
-- `r₁` and `r₄` into annuli between `r₁` and `r₂`, between `r₂` and `r₃`, and between `r₃` and
-- `r₄`. Note that we assume only `r₁ ≤ r₂` and `r₃ ≤ r₄`.
private lemma annulus_integral_bound {x : X} {g : X → ℂ} {r₁ r₂ r₃ r₄ : ℝ} (h₁₂ : r₁ ≤ r₂)
    (h₃₄ : r₃ ≤ r₄) (hg : IntegrableOn g (Annulus.cc x r₁ r₄)) :
    ‖∫ y in Annulus.cc x r₁ r₄, g y‖ₑ ≤ ‖∫ y in Annulus.oc x r₂ r₃, g y‖ₑ +
    ((∫⁻ y in Annulus.cc x r₁ r₂, ‖g y‖ₑ) + ∫⁻ y in Annulus.cc x r₃ r₄, ‖g y‖ₑ) := by
  sorry

open ShortVariables TileStructure
variable {X : Type*} {a : ℕ} {q : ℝ} {K : X → X → ℂ} {σ₁ σ₂ : X → ℤ} {F G : Set X}
  [MetricSpace X] [ProofData a q K σ₁ σ₂ F G] [TileStructure Q D κ S o]
  {n j j' : ℕ} {t : Forest X n} {u u₁ u₂ p : 𝔓 X} {x x' : X} {𝔖 : Set (𝔓 X)}
  {f f₁ f₂ g g₁ g₂ : X → ℂ} {I J J' L : Grid X}
variable {E' : Type*} [NormedAddCommGroup E'] [NormedSpace ℝ E']

namespace TileStructure.Forest

lemma eLpNorm_MB_le {𝕜 : Type*} [RCLike 𝕜] {f : X → 𝕜} (hf : BoundedCompactSupport f) :
    eLpNorm (MB volume 𝓑 c𝓑 r𝓑 f ·) 2 volume ≤ CMB (defaultA a : ℝ≥0) 2 * eLpNorm f 2 volume := by
  sorry

/-! ## Section 7.2 and Lemma 7.2.1 -/

/-- The constant used in `nontangential_operator_bound`.
Has value `2 ^ (102 * a ^ 3)` in the blueprint. -/
irreducible_def C7_2_2 (a : ℕ) : ℝ≥0 := 2 ^ ((𝕔 + 2) * a ^ 3)

-- Bound for (7.2.3) in the proof of `nontangential_pointwise_bound`
omit [TileStructure Q D κ S o] in
private lemma nontangential_integral_bound₁
    (hf : BoundedCompactSupport f) {θ : Θ X} {x x' : X} {R₁ R₂ : ℝ}
    (hR₁ : dist x x' < R₁) (hR₂ : ENNReal.ofReal R₂ < upperRadius Q θ x') :
    ‖∫ y in Annulus.oc x' R₁ R₂, K x' y * f y‖ₑ ≤
    2 * linearizedNontangentialOperator Q θ K f x := by
  sorry

-- Bound for (7.2.4) and (7.2.5) in the proof of `nontangential_pointwise_bound`
private lemma nontangential_integral_bound₂ (hf : BoundedCompactSupport f) {x x' : X}
    {I : Grid X} (hx : x ∈ I) (hx' : x' ∈ I) {R : ℝ} (h : R ≤ 8 * D ^ s I) :
    ∫⁻ y in Annulus.cc x' ((D : ℝ) ^ (s I - 1) / 4) R, ‖K x' y * f y‖ₑ ≤
    2 ^ (7 * a + (𝕔 + 1) * a ^ 3) * MB volume 𝓑 c𝓑 r𝓑 f x := by
  sorry

-- Pointwise bound needed for Lemma 7.2.2
private lemma nontangential_pointwise_bound (hf : BoundedCompactSupport f) (θ : Θ X) (x : X) :
    nontangentialMaximalFunction θ f x ≤
    2 * linearizedNontangentialOperator Q θ K f x +
    2 ^ (7 * a + (𝕔 + 1) * a ^ 3 + 1) * MB volume 𝓑 c𝓑 r𝓑 f x := by
  sorry

lemma le_C7_2_2 (a4 : 4 ≤ a) :
    2 * C_Ts a + 2 ^ (7 * a + (𝕔 + 1) * a ^ 3 + 1) * CMB (defaultA a) 2 ≤ C7_2_2 a := by
  sorry

/-- Lemma 7.2.2. -/
lemma nontangential_operator_bound (hf : BoundedCompactSupport f) (θ : Θ X) :
    eLpNorm (nontangentialMaximalFunction θ f) 2 volume ≤ C7_2_2 a * eLpNorm f 2 volume := by
  sorry

open scoped Classical in
/-- The set of cubes in Lemma 7.2.4. -/
def kissing (I : Grid X) : Finset (Grid X) :=
  {J | s J = s I ∧ ¬Disjoint (ball (c I) (16 * D ^ s I)) (ball (c J) (16 * D ^ s J))}

lemma subset_of_kissing (h : J ∈ kissing I) :
    ball (c J) (D ^ s J / 4) ⊆ ball (c I) (33 * D ^ s I) := by
  sorry

lemma volume_le_of_kissing (h : J ∈ kissing I) :
    volume (ball (c I) (33 * D ^ s I)) ≤ 2 ^ (9 * a) * volume (ball (c J) (D ^ s J / 4)) := by
  sorry

lemma pairwiseDisjoint_of_kissing :
    (SetLike.coe (kissing I)).PairwiseDisjoint
    fun i ↦ ball (c i) (D ^ s i / 4) := by
  sorry

/-- Lemma 7.2.4. -/
lemma boundary_overlap (I : Grid X) : (kissing I).card ≤ 2 ^ (9 * a) := by
  sorry

lemma e728_push_toReal (hf : BoundedCompactSupport f) :
    (t.boundaryOperator u f x).toReal = ∑ I : Grid X,
      (I : Set X).indicator (fun _ ↦ ∑ J ∈ 𝓙' t u (c I) (s I), (ijIntegral f I J).toReal) x := by
  sorry

lemma e728_rearrange (hf : BoundedCompactSupport f) (hg : BoundedCompactSupport g) :
    ∫ x, conj (g x) * (t.boundaryOperator u f x).toReal =
    ∑ I : Grid X, ((volume (ball (c I) (16 * D ^ s I)))⁻¹.toReal * ∫ x in I, conj (g x)) *
      ∑ J ∈ 𝓙' t u (c I) (s I), (D ^ ((s J - s I) / (a : ℝ)) * ∫⁻ y in J, ‖f y‖ₑ).toReal := by
  sorry

open scoped Classical in
/-- Equation (7.2.8) in the proof of Lemma 7.2.3. -/
lemma e728 (hf : BoundedCompactSupport f) (hg : BoundedCompactSupport g) :
    ‖∫ x, conj (g x) * (t.boundaryOperator u f x).toReal‖ₑ ≤
    ∑ J ∈ 𝓙 (t u), ∫⁻ y in J, ‖f y‖ₑ * MB volume 𝓑 c𝓑 r𝓑 g y *
      ∑ I : Grid X, if (J : Set X) ⊆ ball (c I) (16 * D ^ s I) ∧ s J ≤ s I then
        (D : ℝ≥0∞) ^ ((s J - s I) / (a : ℝ)) else 0 := by
  sorry

open scoped Classical in
/-- Bound for the inner sum in Equation (7.2.8). -/
lemma boundary_geometric_series :
    (∑ I : Grid X, if (J : Set X) ⊆ ball (c I) (16 * D ^ s I) ∧ s J ≤ s I then
      (D : ℝ≥0∞) ^ ((s J - s I) / (a : ℝ)) else 0) ≤ 2 ^ (9 * a + 1) := by
  sorry

/-- can be improved to `2 ^ (10 * a + 5 / 2)` -/
irreducible_def C7_2_3 (a : ℕ) : ℝ≥0 := 2 ^ (12 * (a : ℝ))

lemma boundary_operator_bound_aux (hf : BoundedCompactSupport f) (hg : BoundedCompactSupport g) :
    ‖∫ x, conj (g x) * (t.boundaryOperator u f x).toReal‖ₑ ≤
      C7_2_3 a * eLpNorm f 2 volume * eLpNorm g 2 volume := by
  sorry

set_option backward.isDefEq.respectTransparency false in
/-- Lemma 7.2.3. -/
lemma boundary_operator_bound (hf : BoundedCompactSupport f) :
    eLpNorm (t.boundaryOperator u f) 2 volume ≤ C7_2_3 a * eLpNorm f 2 volume := by
  sorry

/-- The constant used in `tree_projection_estimate`.
Has value `2 ^ (130 * a ^ 3)` in the blueprint. -/
irreducible_def C7_2_1 (a : ℕ) : ℝ≥0 := 2 ^ ((𝕔 + 5 + 𝕔 / 4) * a ^ 3)

-- Auxiliary function used in the proof of Lemma 7.2.1
private def eI𝒬u_mul (u : 𝔓 X) (f : X → ℂ) : X → ℂ := fun y ↦ exp (.I * 𝒬 u y) * f y

private lemma boundedCompactSupport_eI𝒬u_mul (u : 𝔓 X) {f : X → ℂ} (hf : BoundedCompactSupport f) :
    BoundedCompactSupport (eI𝒬u_mul u f) := by
  sorry

private lemma norm_eI𝒬u_mul_eq (u : 𝔓 X) (f : X → ℂ) (x : X) : ‖eI𝒬u_mul u f x‖ = ‖f x‖ := by
  sorry

-- The bound for `carlesonSum` from `pointwise_tree_estimate` (Lemma 7.1.3)
variable (t) (u) (f) in
private def cS_bound (x' : X) :=
    C7_1_3 a * (MB volume 𝓑 c𝓑 r𝓑 (approxOnCube (𝓙 (t u)) (‖f ·‖)) x' +
    t.boundaryOperator u (approxOnCube (𝓙 (t u)) (‖f ·‖)) x') +
    nontangentialMaximalFunction (𝒬 u) (approxOnCube (𝓙 (t u)) (eI𝒬u_mul u f)) x'

private lemma aeMeasurable_cS_bound : AEMeasurable (cS_bound t u f) := by
  sorry

-- The natural constant for Lemma 7.2.1 is ≤ the simpler constant `C7_2_1` we use instead.
private lemma le_C7_2_1 {a : ℕ} (ha : 4 ≤ a) :
    C7_1_3 a * CMB (defaultA a) 2 + C7_1_3 a * C7_2_3 a + C7_2_2 a ≤ (C7_2_1 a : ℝ≥0∞) := by
  sorry

-- Main estimate used in the proof of `tree_projection_estimate`
private lemma eLpNorm_two_cS_bound_le : eLpNorm (cS_bound t u f) 2 volume ≤
    C7_2_1 a * eLpNorm (approxOnCube (𝓙 (t u)) (‖f ·‖)) 2 volume := by
  sorry

/- TODO: PR next to `Complex.norm_real` -/
@[simp 1100, norm_cast]
 protected lemma Complex.enorm_real (x : ℝ) : ‖(x : ℂ)‖ₑ = ‖x‖ₑ := by
  sorry

/-- Lemma 7.2.1. -/
lemma tree_projection_estimate
    (hf : BoundedCompactSupport f) (hg : BoundedCompactSupport g) (hu : u ∈ t) :
    ‖∫ x, conj (g x) * carlesonSum (t u) f x‖ₑ ≤
    C7_2_1 a * eLpNorm (approxOnCube (𝓙 (t u)) (‖f ·‖)) 2 volume *
    eLpNorm (approxOnCube (𝓛 (t u)) (‖g ·‖)) 2 volume := by
  sorry

end TileStructure.Forest
