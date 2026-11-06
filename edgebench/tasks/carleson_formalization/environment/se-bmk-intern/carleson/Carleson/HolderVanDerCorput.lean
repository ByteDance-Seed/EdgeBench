module

public import Carleson.TileStructure
public import Carleson.HolderNorm

/-! This should roughly contain the contents of chapter 8. -/

@[expose] public section

open scoped ShortVariables
variable {X : Type*} {a : ℕ} {q : ℝ} {K : X → X → ℂ} {σ₁ σ₂ : X → ℤ} {F G : Set X}
  [MetricSpace X] [ProofData a q K σ₁ σ₂ F G]

noncomputable section

open Set MeasureTheory Metric Function Complex Bornology TileStructure
open scoped NNReal ENNReal ComplexConjugate

/-- `cutoff R t x y` is `L(x, y)` in the proof of Lemma 8.0.1. -/
def cutoff (R t : ℝ) (x y : X) : ℝ :=
  max 0 (1 - dist x y / (t * R))

variable {R t : ℝ} {x y : X}

lemma cutoff_nonneg : 0 ≤ cutoff R t x y := by
  sorry

lemma cutoff_comm : cutoff R t x y = cutoff R t y x := by
  sorry

lemma cutoff_Lipschitz (hR : 0 < R) (ht : 0 < t) :
    LipschitzWith ⟨(1 / (t * R)), by positivity⟩ (fun y ↦ cutoff R t x y) := by
  sorry

@[fun_prop]
lemma cutoff_continuous (hR : 0 < R) (ht : 0 < t) : Continuous (fun y ↦ cutoff R t x y) := by
  sorry

/-- `cutoff R t x` is measurable in `y`. -/
@[fun_prop]
lemma cutoff_measurable (hR : 0 < R) (ht : 0 < t) : Measurable (fun y ↦ cutoff R t x y) := by
  sorry

lemma cutoff_eq_zero (hR : 0 < R) (ht : 0 < t) {x y : X} (hy : y ∉ ball x (t * R)) :
    cutoff R t x y = 0 := by
  sorry

lemma hasCompactSupport_cutoff [ProperSpace X] (hR : 0 < R) (ht : 0 < t) {x : X} :
    HasCompactSupport (fun y ↦ cutoff R t x y) := by
  sorry

lemma integrable_cutoff (hR : 0 < R) (ht : 0 < t) {x : X} :
    Integrable (fun y ↦ cutoff R t x y) := by
  sorry

lemma integrable_cutoff_mul {z : X} (hR : 0 < R) (ht : 0 < t) {x : X} {φ : X → ℂ}
    (hc : Continuous φ) (hφ : φ.support ⊆ ball z R) :
    Integrable (fun y ↦ cutoff R t x y * φ y) := by
  sorry

-- Is this useful for mathlib? neither exact? nor aesop can prove this. Same for the next lemma.
lemma leq_of_max_neq_left {a b : ℝ} (h : max a b ≠ a) : a < b := by
  sorry

lemma leq_of_max_neq_right {a b : ℝ} (h : max a b ≠ b) : b < a := by
  sorry

/-- Equation 8.0.4 from the blueprint -/
lemma aux_8_0_4 (hR : 0 < R) (ht : 0 < t) (h : cutoff R t x y ≠ 0) : y ∈ ball x (t * R) := by
  sorry

lemma aux_8_0_5 (hR : 0 < R) (ht : 0 < t) (h : y ∈ ball x (2⁻¹ * t * R)) :
    2⁻¹ ≤ cutoff R t x y := by
  sorry

lemma aux_8_0_6 (hR : 0 < R) (ht : 0 < t) :
    2⁻¹ * volume.real (ball x (2⁻¹ * t * R)) ≤ ∫ y, cutoff R t x y := by
  sorry

lemma integral_cutoff_pos {R t : ℝ} (hR : 0 < R) (ht : 0 < t) : 0 < ∫ y, cutoff R t x y := by
  sorry

/-- The constant occurring in Lemma 8.0.1. -/
def C8_0_1 (a : ℝ) (t : ℝ≥0) : ℝ≥0 := ⟨2 ^ (4 * a) * t ^ (- (a + 1)), by positivity⟩

/-- `φ ↦ \tilde{φ}` in the proof of Lemma 8.0.1. -/
def holderApprox (R t : ℝ) (φ : X → ℂ) (x : X) : ℂ :=
  (∫ y, cutoff R t x y * φ y) / (∫ y, cutoff R t x y)

lemma integral_mul_holderApprox {R t : ℝ} (hR : 0 < R) (ht : 0 < t) (φ : X → ℂ) :
    (∫ y, cutoff R t x y) * holderApprox R t φ x = ∫ y, cutoff R t x y * φ y := by
  sorry

lemma support_holderApprox_subset_aux {z : X} {R R' t : ℝ} (hR : 0 < R)
    {φ : X → ℂ} (hφ : φ.support ⊆ ball z R') (ht : t ∈ Ioc (0 : ℝ) 1) :
    support (holderApprox R t φ) ⊆ ball z (R + R') := by
  sorry

/-- Part of Lemma 8.0.1. -/
lemma support_holderApprox_subset {z : X} {R t : ℝ} (hR : 0 < R)
    {φ : X → ℂ} (hφ : φ.support ⊆ ball z R) (ht : t ∈ Ioc (0 : ℝ) 1) :
    support (holderApprox R t φ) ⊆ ball z (2 * R) := by
  sorry

open Filter

/-- Part of Lemma 8.0.1: Equation (8.0.1).
Note that the norm `||φ||_C^τ` is normalized by definition, i.e., on the ball `B (z, 2 * R)`,
it is `(2 * R) ^ τ` times the best Hölder constant of `φ`, so the Lean statement corresponds to the
blueprint statement.
-/
lemma dist_holderApprox_le {z : X} {R t : ℝ} (hR : 0 < R) {C : ℝ≥0} (ht : 0 < t) (h't : t ≤ 1)
    {φ : X → ℂ} (hφ : support φ ⊆ ball z R) (h2φ : HolderOnWith C nnτ φ (ball z (2 * R))) (x : X) :
    dist (φ x) (holderApprox R t φ x) ≤ (t/2) ^ τ * ((2 * R) ^ τ * C) := by
  sorry

lemma enorm_holderApprox_sub_le {z : X} {R t : ℝ} (hR : 0 < R) (ht : 0 < t) (h't : t ≤ 1)
    {φ : X → ℂ} (hφ : support φ ⊆ ball z R) (x : X) :
    ‖φ x - holderApprox R t φ x‖ₑ ≤ ENNReal.ofReal (t/2) ^ τ * iHolENorm φ z (2 * R) τ := by
  sorry

/-- Part of Lemma 8.0.1: sup norm control in Equation (8.0.2). Note that it only uses the sup
norm of `φ`, no need for a Hölder control. -/
lemma holderApprox_le {R t : ℝ} (hR : 0 < R) {C : ℝ≥0} (ht : 0 < t)
    {φ : X → ℂ} (hC : ∀ x, ‖φ x‖ ≤ C) (x : X) :
    ‖holderApprox R t φ x‖ ≤ C := by
  sorry

/-- Auxiliary lemma: part of the Lipschitz control in Equation (8.0.2), when the distance between
the points is at most `R`. -/
lemma norm_holderApprox_sub_le_aux {z : X} {R t : ℝ} (hR : 0 < R) (ht : 0 < t) (h't : t ≤ 1)
    {C : ℝ≥0} {φ : X → ℂ} (hc : Continuous φ) (hφ : φ.support ⊆ ball z R)
    (hC : ∀ x, ‖φ x‖ ≤ C) {x x' : X} (h : dist x x' < R) :
    ‖holderApprox R t φ x' - holderApprox R t φ x‖ ≤
      2⁻¹ * 2 ^ (4 * a) * t ^ (-1 - a : ℝ) * C * dist x x' / (2 * R) := by
  sorry

/-- Part of Lemma 8.0.1: Lipschitz norm control in Equation (8.0.2). Note that it only uses the sup
norm of `φ`, no need for a Hölder control. -/
lemma norm_holderApprox_sub_le {z : X} {R t : ℝ} (hR : 0 < R) (ht : 0 < t) (h't : t ≤ 1)
    {C : ℝ≥0} {φ : X → ℂ} (hc : Continuous φ) (hφ : φ.support ⊆ ball z R)
    (hC : ∀ x, ‖φ x‖ ≤ C) {x x' : X} :
    ‖holderApprox R t φ x - holderApprox R t φ x'‖ ≤
    2⁻¹ * 2 ^ (4 * a) * t ^ (-1 - a : ℝ) * C * dist x x' / (2 * R) := by
  sorry

lemma lipschitzWith_holderApprox {z : X} {R t : ℝ} (hR : 0 < R) (ht : 0 < t) (h't : t ≤ 1)
    {C : ℝ≥0} {φ : X → ℂ} (hc : Continuous φ) (hφ : φ.support ⊆ ball z R)
    (hC : ∀ x, ‖φ x‖ ≤ C) :
    LipschitzWith (2⁻¹ * 2 ^ (4 * a) * t ^ (-1 - a : ℝ) * C / (2 * R)).toNNReal
      (holderApprox R t φ) := by
  sorry

lemma iLipENorm_holderApprox' {z : X} {R t : ℝ} (ht : 0 < t) (h't : t ≤ 1)
    {C : ℝ≥0} {φ : X → ℂ} (hc : Continuous φ) (hφ : φ.support ⊆ ball z R) (hC : ∀ x, ‖φ x‖ ≤ C) :
    iLipENorm (holderApprox R t φ) z (2 * R) ≤
      2 ^ (4 * a) * (ENNReal.ofReal t) ^ (-1 - a : ℝ) * C := by
  sorry

lemma iLipENorm_holderApprox_le {z : X} {R t : ℝ} (ht : 0 < t) (h't : t ≤ 1)
    {φ : X → ℂ} (hφ : support φ ⊆ ball z R) :
    iLipENorm (holderApprox R t φ) z (2 * R) ≤
      2 ^ (4 * a) * (ENNReal.ofReal t) ^ (-1 - a : ℝ) * iHolENorm φ z (2 * R) τ := by
  sorry

/-- The constant occurring in Proposition 2.0.5.
Has value `2 ^ (7 * a)` in the blueprint. -/
def C2_0_5 (a : ℝ) : ℝ≥0 := 2 ^ (7 * a)

--NOTE (MI) : there was a missing minus sign in the exponent.
/-- Proposition 2.0.5. -/
theorem holder_van_der_corput {z : X} {R : ℝ} {φ : X → ℂ}
    (φ_supp : support φ ⊆ ball z R) {f g : Θ X} :
    ‖∫ x, exp (I * (f x - g x)) * φ x‖ₑ ≤
    (C2_0_5 a : ℝ≥0∞) * volume (ball z R) * iHolENorm φ z (2 * R) τ *
      (1 + edist_{z, R} f g) ^ (- (2 * a^2 + a^3 : ℝ)⁻¹) := by
  sorry
