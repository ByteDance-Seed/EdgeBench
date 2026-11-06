module

public import Mathlib.MeasureTheory.Function.LpSeminorm.CompareExp

public section

noncomputable section

open MeasureTheory Filter
open scoped NNReal ENNReal Topology symmDiff

variable {α E : Type*} {m : MeasurableSpace α} {p : ℝ≥0∞} {μ : Measure α} [NormedAddCommGroup E]
variable {X : Type*} [TopologicalSpace X] [MeasurableSpace X]
  {μ : Measure X} [IsFiniteMeasureOnCompacts μ]

namespace MeasureTheory

-- Upstreaming status: upstreamed in https://github.com/leanprover-community/mathlib4/pull/37559

/-- A bounded measurable function with compact support is in L^p. -/
theorem _root_.HasCompactSupport.memLp_of_enorm_bound {f : X → E} (hf : HasCompactSupport f)
    (h2f : AEStronglyMeasurable f μ) {C : ℝ≥0∞} (hfC : ∀ᵐ x ∂μ, ‖f x‖ₑ ≤ C) (hC : C ≠ ⊤) :
      MemLp f p μ := by
  sorry

end MeasureTheory
