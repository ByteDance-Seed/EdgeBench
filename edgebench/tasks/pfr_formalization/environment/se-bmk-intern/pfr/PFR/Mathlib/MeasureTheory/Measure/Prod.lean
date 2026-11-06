module

public import Mathlib.MeasureTheory.Measure.Prod

public section

open Function
open scoped ENNReal NNReal

namespace MeasureTheory.Measure
variable {Ω α β γ : Type*} [MeasurableSpace Ω]
  [MeasurableSpace α] [MeasurableSpace β] [MeasurableSpace γ] {X : Ω → α} {Y : Ω → β} {Z : Ω → γ}

lemma prod_of_full_measure_finset {μ : Measure α} {ν : Measure β} [SigmaFinite ν]
    {A : Finset α} {B : Finset β} (hA : μ Aᶜ = 0) (hB : ν Bᶜ = 0) :
    (μ.prod ν) (A ×ˢ B : Finset (α × β))ᶜ = 0 := by
  sorry

end MeasureTheory.Measure

open MeasureTheory

set_option linter.flexible false in
instance {α β : Type*} [MeasurableSpace α] [MeasurableSpace β] {μ : Measure α}
    [IsZeroOrProbabilityMeasure μ] {ν : Measure β} [IsZeroOrProbabilityMeasure ν] :
    IsZeroOrProbabilityMeasure (μ.prod ν) := by
  rcases eq_zero_or_isProbabilityMeasure μ with rfl | hμ
  · simp; infer_instance
  rcases eq_zero_or_isProbabilityMeasure ν with rfl | hν
  · simp; infer_instance
  infer_instance
