module

public import Mathlib.MeasureTheory.Measure.Prod
public import Mathlib.MeasureTheory.MeasurableSpace.Defs
public import Mathlib.MeasureTheory.Measure.MeasureSpaceDef
public import Mathlib.MeasureTheory.Integral.Lebesgue.Basic

public section

namespace MeasureTheory

open MeasureTheory Measure Function
open scoped ENNReal

variable {α β : Type*}

variable [MeasurableSpace α] [MeasurableSpace β]
variable {μ : Measure α} {ν : Measure β}

-- Upstreaming status: looks ready for mathlib; perhaps want to add left variants also

-- Proof copied from `MeasureTheory.AEStronglyMeasurable.integral_prod_right'`
-- Was it intentional that there's no left version?
theorem AEMeasurable.lintegral_prod_right' [SFinite ν] ⦃f : α × β → ℝ≥0∞⦄
    (hf : AEMeasurable f (μ.prod ν)) : AEMeasurable (fun (x : α) ↦ ∫⁻ (y : β), f (x, y) ∂ν) μ := by
  sorry

-- XXX: the corresponding result for AEStronglyMeasurable doesn't exist; should it be added?
theorem AEMeasurable.lintegral_prod_right [SFinite ν] {f : α → β → ℝ≥0∞}
    (hf : AEMeasurable (uncurry f) (μ.prod ν)) : AEMeasurable (fun x ↦ ∫⁻ y, f x y ∂ν) μ := by
  sorry

end MeasureTheory
