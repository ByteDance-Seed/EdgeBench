module

public import Carleson.ToMathlib.MeasureTheory.Integral.Bochner.ContinuousLinearMap
public import Carleson.ToMathlib.MeasureTheory.Integral.Lebesgue
public import Carleson.ToMathlib.MeasureTheory.Function.LpSeminorm.Basic
public import Carleson.TwoSidedCarleson.WeakCalderonZygmund

@[expose] public section

open MeasureTheory Set Bornology Function Metric
open ENNReal hiding one_lt_two
open scoped NNReal

noncomputable section

variable {X : Type*} {a : ℕ} [MetricSpace X] [DoublingMeasure X (defaultA a : ℕ)]
variable {τ C r R : ℝ} {q q' : ℝ≥0}
variable {F G : Set X}
variable {K : X → X → ℂ} {x x' : X} [IsTwoSidedKernel a K]

/-! ## Section 10.1 and Lemma 10.0.2 -/

variable (K) in
/-- The operator `T_*^r g(x)`, defined in (10.1.31), above Lemma 10.1.6. -/
def simpleNontangentialOperator (r : ℝ) (g : X → ℂ) (x : X) : ℝ≥0∞ :=
  ⨆ (R > r) (x' ∈ ball x R), ‖czOperator K R g x'‖ₑ

/-- The constant used in `estimate_x_shift`. -/
irreducible_def C10_1_2 (a : ℕ) : ℝ≥0 := 2 ^ (a ^ 3 + 2 * a + 2)
-- exact estimate from proof: C_K * (defaultA + 2 * defaultA²) ≤ C10_1_2

lemma _laverage_mul_measure_ball {g : X → ℂ} {x₀ : X} {n : ℝ} :
    ∫⁻ (a : X) in ball x₀ (n * r), ‖g a‖ₑ = (⨍⁻ (a : X) in ball x₀ (n * r), ‖g a‖ₑ ∂volume) * volume (ball x₀ (n * r)) := by
  sorry

lemma estimate_10_1_2 {g : X → ℂ} (hg : BoundedFiniteSupport g) (hr : 0 < r) :
    (∫⁻ (y : X) in (ball x r)ᶜ ∩ ball x (2*r), ‖K x y * g y‖ₑ) ≤
    2 ^ (a ^ 3 + a) * globalMaximalFunction volume 1 g x := by
  sorry

lemma estimate_10_1_3 (ha : 4 ≤ a) {g : X → ℂ} (hg : BoundedFiniteSupport g) (hr : 0 < r) (hx : dist x x' ≤ r) :
    ‖∫ (y : X) in (ball x (2*r))ᶜ, K x y * g y - K x' y * g y‖ₑ ≤
    2 ^ (a ^ 3 + 2 * a) * globalMaximalFunction volume 1 g x := by
  sorry

lemma estimate_10_1_4 {g : X → ℂ} (hg : BoundedFiniteSupport g) (hr : 0 < r) (hx : dist x x' ≤ r) :
    (∫⁻ (y : X) in (ball x' r)ᶜ ∩ ball x (2*r), ‖K x' y * g y‖ₑ) ≤
    2 ^ (a ^ 3 + 2 * a) * globalMaximalFunction volume 1 g x := by
  sorry

/-- Lemma 10.1.2 -/
theorem estimate_x_shift (ha : 4 ≤ a)
    {g : X → ℂ} (hg : BoundedFiniteSupport g) (hr : 0 < r) (hx : dist x x' ≤ r) :
    edist (czOperator K r g x) (czOperator K r g x') ≤
    C10_1_2 a * globalMaximalFunction volume 1 g x := by
  sorry

/-- The constant used in `cotlar_control`. -/
irreducible_def C10_1_3 (a : ℕ) : ℝ≥0 := 2 ^ (a ^ 3 + 4 * a + 1)

lemma radius_change {g : X → ℂ} (hg : BoundedFiniteSupport g volume) (hr : r ∈ Ioc 0 R)
    (hx : dist x x' ≤ R / 4) :
    ‖czOperator K r ((ball x (R / 2))ᶜ.indicator g) x' - czOperator K R ((ball x (R / 2))ᶜ.indicator g) x'‖ₑ ≤
      2 ^ (a ^ 3 + 4 * a) * globalMaximalFunction volume 1 g x := by
  sorry

omit [IsTwoSidedKernel a K] in
lemma cut_out_ball {g : X → ℂ} (hr : r ∈ Ioc 0 R) (hx : dist x x' ≤ R / 4) :
    czOperator K R g x' = czOperator K R ((ball x (R / 2))ᶜ.indicator g) x' := by
  sorry

/-- Lemma 10.1.3 -/
theorem cotlar_control (ha : 4 ≤ a) {g : X → ℂ} (hg : BoundedFiniteSupport g) (hr : r ∈ Ioc 0 R)
    (hx : dist x x' ≤ R / 4) :
    ‖czOperator K R g x‖ₑ ≤ ‖czOperator K r ((ball x (R / 2))ᶜ.indicator g) x'‖ₑ +
    C10_1_3 a * globalMaximalFunction volume 1 g x := by
  sorry

/-- The constant used in `cotlar_set_F₂`. -/
irreducible_def C10_1_4 (a : ℕ) : ℝ≥0 := 2 ^ (a ^ 3 + 22 * a + 2)

lemma globalMaximalFunction_zero_enorm_ae_zero (hR : 0 < R) {f : X → ℂ} (hf : AEStronglyMeasurable f)
    (hMzero : globalMaximalFunction volume 1 f x = 0) :
    ∀ᵐ x' ∂(volume.restrict (ball x R)), ‖f x'‖ₑ = 0 := by
  sorry

/-- Part 1 of Lemma 10.1.4 about `F₁`. -/
theorem cotlar_set_F₁ (hr : 0 < r) (hR : r ≤ R) {g : X → ℂ} (hg : BoundedFiniteSupport g) :
    volume.restrict (ball x (R / 4))
      {x' | 4 * globalMaximalFunction volume 1 (czOperator K r g) x < ‖czOperator K r g x'‖ₑ } ≤
    volume (ball x (R / 4)) / 4 := by
  sorry

/-- Part 2 of Lemma 10.1.4 about `F₂`. -/
theorem cotlar_set_F₂ (ha : 4 ≤ a) (hr : 0 < r) (hR : r ≤ R)
    (hT : ∀ r > 0, HasBoundedStrongType (czOperator K r) 2 2 volume volume (C_Ts a))
    {g : X → ℂ} (hg : BoundedFiniteSupport g) :
    volume.restrict (ball x (R / 4))
      {x' | C10_1_4 a * globalMaximalFunction volume 1 g x <
        ‖czOperator K r ((ball x (R / 2)).indicator g) x'‖ₑ } ≤
    volume (ball x (R / 4)) / 4 := by
  sorry

/-- The constant used in `cotlar_estimate`. -/
irreducible_def C10_1_5 (a : ℕ) : ℝ≥0 := 2 ^ (a ^ 3 + 22 * a + 3)

/-- Lemma 10.1.5 -/
theorem cotlar_estimate (ha : 4 ≤ a)
    (hT : ∀ r > 0, HasBoundedStrongType (czOperator K r) 2 2 volume volume (C_Ts a))
    {g : X → ℂ} (hg : BoundedFiniteSupport g) (hr : r ∈ Ioc 0 R) :
    ‖czOperator K R g x‖ₑ ≤ 4 * globalMaximalFunction volume 1 (czOperator K r g) x +
      C10_1_5 a * globalMaximalFunction volume 1 g x := by
  sorry

omit [IsTwoSidedKernel a K] in
/-- Part of Lemma 10.1.6. -/
lemma lowerSemicontinuous_simpleNontangentialOperator {g : X → ℂ} :
    LowerSemicontinuous (simpleNontangentialOperator K r g) := by
  sorry

omit [IsTwoSidedKernel a K] in
lemma aestronglyMeasurable_simpleNontangentialOperator {g : X → ℂ} :
    AEStronglyMeasurable (simpleNontangentialOperator K r g) volume := by
  sorry

/-- The constant used in `simple_nontangential_operator`.
It is not tight and can be improved by some `a` + `constant`. -/
irreducible_def C10_1_6 (a : ℕ) : ℝ≥0 := 2 ^ (a ^ 3 + 26 * a + 6)

/-- Lemma 10.1.6. The formal statement includes the measurability of the operator.
See also `simple_nontangential_operator_le` -/
theorem simple_nontangential_operator (ha : 4 ≤ a)
    (hT : ∀ r > 0, HasBoundedStrongType (czOperator K r) 2 2 volume volume (C_Ts a)) (hr : 0 < r) :
    HasBoundedStrongType (simpleNontangentialOperator K r) 2 2 volume volume (C10_1_6 a) := by
  sorry

/-- This is the first step of the proof of Lemma 10.0.2, and should follow from 10.1.6 +
monotone convergence theorem. (measurability should be proven without any restriction on `r`.) -/
theorem simple_nontangential_operator_le (ha : 4 ≤ a)
    (hT : ∀ r > 0, HasBoundedStrongType (czOperator K r) 2 2 volume volume (C_Ts a)) (hr : 0 ≤ r) :
    HasBoundedStrongType (simpleNontangentialOperator K r) 2 2 volume volume (C10_1_6 a) := by
  sorry

/-- Part of Lemma 10.1.7, reformulated. -/
theorem small_annulus_right {g : X → ℂ} (hg : BoundedFiniteSupport g) {R₁ R₂ : ℝ} (hR₁ : 0 < R₁) :
    ContinuousWithinAt (fun R₂ ↦ ∫ y in Annulus.oo x R₁ R₂, K x y * g y) (Ioo R₁ R₂) R₁ := by
  sorry

/-- Part of Lemma 10.1.7, reformulated -/
theorem small_annulus_left {g : X → ℂ} (hg : BoundedFiniteSupport g) {R₁ R₂ : ℝ} (hR₁ : 0 ≤ R₁) :
    ContinuousWithinAt (fun R ↦ ∫ y in Annulus.oo x R R₂, K x y * g y) (Ioo R₁ R₂) R₂ := by
  sorry

/-- Lemma 10.1.8. -/
theorem nontangential_operator_boundary {f : X → ℂ} (hf : BoundedFiniteSupport f) :
    nontangentialOperator K f x =
    ⨆ (R₂ : ℝ) (R₁ ∈ Ioo 0 R₂) (x' ∈ ball x R₁),
      ‖∫ y in ball x' R₂ \ ball x' R₁, K x' y * f y‖ₑ := by
  sorry

omit [IsTwoSidedKernel a K] in
/-- Part of Lemma 10.1.6. -/
lemma lowerSemicontinuous_nontangentialOperator {g : X → ℂ} :
    LowerSemicontinuous (nontangentialOperator K g) := by
  sorry

omit [IsTwoSidedKernel a K] in
lemma aestronglyMeasurable_nontangentialOperator {g : X → ℂ} :
    AEStronglyMeasurable (nontangentialOperator K g) volume := by
  sorry

/-- The constant used in `nontangential_from_simple`. -/
irreducible_def C10_0_2 (a : ℕ) : ℝ≥0 := 2 ^ (3 * a ^ 3)

/-- Lemma 10.0.2. The formal statement includes the measurability of the operator. -/
theorem nontangential_from_simple (ha : 4 ≤ a)
    (hT : ∀ r > 0, HasBoundedStrongType (czOperator K r) 2 2 volume volume (C_Ts a)) :
    HasBoundedStrongType (nontangentialOperator K) 2 2 volume volume (C10_0_2 a) := by
  sorry

end
