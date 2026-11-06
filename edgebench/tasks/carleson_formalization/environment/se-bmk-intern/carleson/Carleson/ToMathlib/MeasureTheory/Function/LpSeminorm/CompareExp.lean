module

public import Mathlib.MeasureTheory.Function.LpSeminorm.CompareExp
public import Carleson.ToMathlib.MeasureTheory.Function.LpSeminorm.Basic

/- This file upgrades Hölder's inequality to use enorm. -/

--Upstreaming status: ready

public section

open Filter ENNReal
open scoped Topology

namespace MeasureTheory

section Bilinear

variable {α E F G : Type*} {m : MeasurableSpace α}
  [TopologicalSpace E] [ENormedAddCommMonoid E] [TopologicalSpace F] [ENormedAddCommMonoid F]
  [TopologicalSpace G] [ENormedAddCommMonoid G] {μ : Measure α}
  {f : α → E} {g : α → F}

open NNReal

--TODO: move?
instance : ENormSMulClass ℝ≥0 ℝ≥0∞ where
  enorm_smul r x := by
    simp only [enorm_eq_self, enorm_NNReal]
    rw [ENNReal.smul_def, smul_eq_mul]

theorem eLpNorm_le_eLpNorm_top_mul_eLpNorm' (p : ℝ≥0∞) (f : α → E) {g : α → F}
    (hg : AEStronglyMeasurable g μ) (b : E → F → G) (c : ℝ≥0)
    (h : ∀ᵐ x ∂μ, ‖b (f x) (g x)‖ₑ ≤ c * ‖f x‖ₑ * ‖g x‖ₑ) :
    eLpNorm (fun x => b (f x) (g x)) p μ ≤ c * eLpNorm f ∞ μ * eLpNorm g p μ := by
  sorry

theorem eLpNorm_le_eLpNorm_mul_eLpNorm_top'' (p : ℝ≥0∞) {f : α → E} (hf : AEStronglyMeasurable f μ)
    (g : α → F) (b : E → F → G) (c : ℝ≥0)
    (h : ∀ᵐ x ∂μ, ‖b (f x) (g x)‖ₑ ≤ c * ‖f x‖ₑ * ‖g x‖ₑ) :
    eLpNorm (fun x => b (f x) (g x)) p μ ≤ c * eLpNorm f p μ * eLpNorm g ∞ μ := by
  sorry

theorem eLpNorm'_le_eLpNorm'_mul_eLpNorm'' {p q r : ℝ} (hf : AEStronglyMeasurable f μ)
    (hg : AEStronglyMeasurable g μ) (b : E → F → G) (c : ℝ≥0)
    (h : ∀ᵐ x ∂μ, ‖b (f x) (g x)‖ₑ ≤ c * ‖f x‖ₑ * ‖g x‖ₑ) (hro_lt : 0 < r) (hrp : r < p)
    (hpqr : 1 / r = 1 / p + 1 / q) :
    eLpNorm' (fun x => b (f x) (g x)) r μ ≤ c * eLpNorm' f p μ * eLpNorm' g q μ := by
  sorry

/-- Hölder's inequality, as an inequality on the `ℒp` seminorm of an elementwise operation
`fun x => b (f x) (g x)`. -/
theorem eLpNorm_le_eLpNorm_mul_eLpNorm_of_enorm {p q r : ℝ≥0∞}
    (hf : AEStronglyMeasurable f μ) (hg : AEStronglyMeasurable g μ) (b : E → F → G) (c : ℝ≥0)
    (h : ∀ᵐ x ∂μ, ‖b (f x) (g x)‖ₑ ≤ c * ‖f x‖ₑ * ‖g x‖ₑ) [hpqr : HolderTriple p q r] :
    eLpNorm (fun x => b (f x) (g x)) r μ ≤ c * eLpNorm f p μ * eLpNorm g q μ := by
  sorry

/-- Hölder's inequality, as an inequality on the `ℒp` seminorm for functions to `ℝ≥0∞`. -/
theorem eLpNorm_le_eLpNorm_mul_eLpNorm_of_enorm' {p q r : ℝ≥0∞} {f g : α → ℝ≥0∞}
    (hf : AEStronglyMeasurable f μ) (hg : AEStronglyMeasurable g μ)
    (hpqr : HolderTriple p q r) :
    eLpNorm (fun x => f x * g x) r μ ≤ eLpNorm f p μ * eLpNorm g q μ := by
  sorry

/-- Hölder's inequality, as an inequality on the `ℒp` seminorm of an elementwise operation
`fun x => b (f x) (g x)`. -/
theorem eLpNorm_le_eLpNorm_mul_eLpNorm'_of_enorm {p q r : ℝ≥0∞} (hf : AEStronglyMeasurable f μ)
    (hg : AEStronglyMeasurable g μ) (b : E → F → G) (c : ℝ≥0)
    (h : ∀ᵐ x ∂μ, ‖b (f x) (g x)‖ₑ ≤ c * ‖f x‖ₑ * ‖g x‖ₑ) [hpqr : HolderTriple p q r] :
    eLpNorm (fun x => b (f x) (g x)) r μ ≤ c * eLpNorm f p μ * eLpNorm g q μ := by
  sorry

open NNReal in
theorem MemLp.of_bilin' {p q r : ℝ≥0∞} {f : α → E} {g : α → F} (b : E → F → G) (c : ℝ≥0)
    (hf : MemLp f p μ) (hg : MemLp g q μ)
    (h : AEStronglyMeasurable (fun x ↦ b (f x) (g x)) μ)
    (hb : ∀ᵐ (x : α) ∂μ, ‖b (f x) (g x)‖ₑ ≤ c * ‖f x‖ₑ * ‖g x‖ₑ)
    [hpqr : HolderTriple p q r] :
    MemLp (fun x ↦ b (f x) (g x)) r μ := by
  sorry

end Bilinear

end MeasureTheory
