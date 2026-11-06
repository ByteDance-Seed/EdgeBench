module

public import Mathlib.MeasureTheory.Function.LocallyIntegrable
public import Carleson.ToMathlib.MeasureTheory.Integral.IntegrableOn

public section

-- Upstreaming status: easy and useful; good to go

namespace MeasureTheory

theorem LocallyIntegrable.norm {X : Type*} {E : Type*} [MeasurableSpace X]
  [TopologicalSpace X] [NormedAddCommGroup E] {f : X → E} {μ : Measure X}
  (hf : LocallyIntegrable f μ) :
    LocallyIntegrable (fun x ↦ ‖f x‖) μ := by
  sorry

variable {X ε ε' : Type*} [MeasurableSpace X] [TopologicalSpace X]
  [TopologicalSpace ε] [ContinuousENorm ε] [TopologicalSpace ε'] [ContinuousENorm ε']
  {f g : X → ε} {μ : Measure X}

theorem LocallyIntegrable.congr'_enorm {f : X → ε} {g : X → ε'} (hf : LocallyIntegrable f μ)
    (hg : AEStronglyMeasurable g μ) (h : ∀ᵐ a ∂μ, ‖f a‖ₑ = ‖g a‖ₑ) : LocallyIntegrable g μ := by
  sorry

theorem locallyIntegrable_congr'_enorm {f : X → ε} {g : X → ε'}
    (hf : AEStronglyMeasurable f μ) (hg : AEStronglyMeasurable g μ) (h : ∀ᵐ a ∂μ, ‖f a‖ₑ = ‖g a‖ₑ) :
    LocallyIntegrable f μ ↔ LocallyIntegrable g μ := by
  sorry

end MeasureTheory
