module

public import Mathlib.MeasureTheory.Function.LpSeminorm.Monotonicity
public import Carleson.ToMathlib.Data.ENNReal

public section

-- Upstreaming status: can be upstreamed/being worked on
-- Many remaining declarations require PRing a new enorm class to mathlib first,
-- i.e. are not a good first target.

noncomputable section

open ENNReal NNReal Function Set

variable {α α' E E₁ E₂ : Type*}

@[simp] lemma enorm_toReal_le {x : ℝ≥0∞} : ‖x.toReal‖ₑ ≤ x := by
  sorry

@[simp] lemma enorm_toReal {x : ℝ≥0∞} (hx : x ≠ ⊤) : ‖x.toReal‖ₑ = x := by
  sorry

@[simp] lemma enorm_NNReal {x : ℝ≥0} : ‖x‖ₑ = x := by
  sorry

-- TODO appropriate generality (ENormedDivisionSemiring?), for ℝ≥0 it is already there
-- @[simp] lemma enorm_inv'' {a : ℝ≥0} (ha : a ≠ 0): ‖a⁻¹‖ₑ = ‖a‖ₑ⁻¹ := by
--   simp_rw [enorm_NNReal, coe_inv ha]

/-- An enormed monoid is an additive monoid endowed with a continuous enorm.
Note: not sure if this is the "right" class to add to Mathlib. -/
class ENormedAddCommSubMonoid (E : Type*) [TopologicalSpace E] extends ENormedAddCommMonoid E, Sub E where
  sub_add_cancel_of_enorm_le : ∀ ⦃x y : E⦄, ‖y‖ₑ ≤ ‖x‖ₑ → x - y + y = x
  add_right_cancel_of_enorm_lt_top : ∀ ⦃x : E⦄, ‖x‖ₑ < ⊤ → ∀ {y z : E}, y + x = z + x → y = z
  esub_self : ∀ x : E, x - x = 0

/-- An enormed space is an additive monoid endowed with a continuous enorm.
Note: not sure if this is the "right" class to add to Mathlib. -/
class ENormedSpace (E : Type*) [TopologicalSpace E] extends ENormedAddCommMonoid E, Module ℝ≥0 E where
  enorm_smul_eq_smul : ∀ (c : ℝ≥0) (x : E), ‖c • x‖ₑ = c • ‖x‖ₑ

export ENormedAddCommSubMonoid
  (sub_add_cancel_of_enorm_le add_right_cancel_of_enorm_lt_top esub_self)
export ENormedSpace (enorm_smul_eq_smul)

-- mathlib has this (in the _root_ namespace), in a less general setting
attribute [simp] ENormedSpace.enorm_smul_eq_smul

set_option backward.isDefEq.respectTransparency false in
instance : ENormedSpace ℝ≥0∞ where
  enorm := id
  enorm_zero := by simp
  enorm_eq_zero := by simp
  -- enorm_neg := by simp
  enorm_add_le := by simp
  add_comm := by simp [add_comm]
  continuous_enorm := continuous_id
  enorm_smul_eq_smul := by simp
  add_smul := fun _ _ _ ↦ Module.add_smul ..
  zero_smul := by simp

instance : ENormedSpace ℝ≥0 where
  enorm := ofNNReal
  enorm_zero := by simp
  add_smul r s x := by
    simp only [smul_eq_mul]
    ring
  zero_smul := by simp
  enorm_eq_zero := by simp
  enorm_add_le := by simp
  add_comm := by simp [add_comm]
  continuous_enorm := by fun_prop
  enorm_smul_eq_smul c x := by simp [ENNReal.smul_def]

set_option backward.isDefEq.respectTransparency false in
instance [NormedAddCommGroup E] [NormedSpace ℝ E] : ENormedSpace E where
  enorm_smul_eq_smul := by
    simp_rw [enorm_eq_nnnorm, ENNReal.smul_def, NNReal.smul_def, nnnorm_smul]; simp

namespace MeasureTheory

lemma esub_zero [TopologicalSpace E] [ENormedAddCommSubMonoid E] {x : E} : x - 0 = x := by
  sorry

section ENormedSpace

variable {ε : Type*} [TopologicalSpace ε] [ENormedSpace ε]

-- TODO: this lemma and Mathlib's `enorm_smul` could be unified using a `ENormedDivisionSemiring`
-- typeclass (which includes ENNReal and normed fields like ℝ and ℂ),
-- i.e. assuming 𝕜 is a normed semifield.
-- Investigate if this is worthwhile when upstreaming this to mathlib.
-- Update: change this lemma to prove ENormSMulClass for ENormedSpace's.
lemma enorm_smul_eq_mul {c : ℝ≥0} (z : ε) : ‖c • z‖ₑ = ‖c‖ₑ * ‖z‖ₑ := by
  sorry

instance : ContinuousConstSMul ℝ≥0 ℝ≥0∞ where
  continuous_const_smul t := ENNReal.continuous_const_mul (by simp)

open MeasureTheory

-- TODO: put next to MeasureTheory.eLpNorm_const_smul_le (which perhaps can stay)
theorem eLpNorm_const_nnreal_smul_le {α : Type*} {m0 : MeasurableSpace α} {p : ℝ≥0∞}
  {μ : Measure α} {c : ℝ≥0} {f : α → ε} : eLpNorm (c • f) p μ ≤ ‖c‖ₑ * eLpNorm f p μ := by
  sorry

-- TODO: put next to eLpNorm_const_smul
theorem eLpNorm_const_smul' {α : Type*} {m0 : MeasurableSpace α} {p : ℝ≥0∞}
  {μ : Measure α} {c : ℝ≥0} {f : α → ε} :
    eLpNorm (c • f) p μ = ‖c‖ₑ * eLpNorm f p μ := by
  sorry

set_option backward.isDefEq.respectTransparency false in
theorem eLpNorm_top_smul {α : Type*} {m0 : MeasurableSpace α} {p : ℝ≥0∞}
  {μ : Measure α} {f : α → ℝ≥0∞} (hf : AEStronglyMeasurable f μ) : eLpNorm (∞ • f) p μ = ⊤ * eLpNorm f p μ := by
  sorry

-- TODO: find better place for this?
theorem _root_.ENNReal.toNNReal_smul {α : Type*} {c : ℝ≥0∞} (hc : c ≠ ⊤) {f : α → ℝ≥0∞} :
    c.toNNReal • f = c • f := by
  sorry

-- TODO: put next to eLpNorm_const_smul
set_option backward.isDefEq.respectTransparency false in
theorem eLpNorm_const_smul'' {α : Type*} {m0 : MeasurableSpace α} {p : ℝ≥0∞}
  {μ : Measure α} {c : ℝ≥0∞} (hc : c ≠ ⊤) {f : α → ℝ≥0∞} :
    eLpNorm (c • f) p μ = c * eLpNorm f p μ := by
  sorry

-- TODO: put next to eLpNorm_const_smul
theorem eLpNorm_const_smul''' {α : Type*} {m0 : MeasurableSpace α} {p : ℝ≥0∞}
  {μ : Measure α} {c : ℝ≥0∞} {f : α → ℝ≥0∞} (hf : AEStronglyMeasurable f μ) :
    eLpNorm (c • f) p μ = c * eLpNorm f p μ := by
  sorry

-- TODO: put next to the unprimed version; perhaps both should stay
lemma eLpNormEssSup_const_nnreal_smul_le {α : Type*} {m0 : MeasurableSpace α} {μ : Measure α}
    {c : ℝ≥0} {f : α → ε} : eLpNormEssSup (c • f) μ ≤ ‖c‖ₑ * eLpNormEssSup f μ := by
  sorry

end ENormedSpace

end MeasureTheory
