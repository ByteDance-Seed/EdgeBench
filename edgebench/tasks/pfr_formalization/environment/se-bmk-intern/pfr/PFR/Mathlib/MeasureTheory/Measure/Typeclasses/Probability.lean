module

public import Mathlib.MeasureTheory.Measure.Typeclasses.Probability
public import PFR.Mathlib.MeasureTheory.Measure.MeasureSpaceDef

public section

namespace MeasureTheory
variable {Ω : Type*} [Countable Ω] [MeasurableSpace Ω] {μ : Measure Ω}

lemma measure_eq_one_of_forall_singleton {X : Type*} [Countable X] [MeasurableSpace X]
    {μ : Measure X} [IsProbabilityMeasure μ] {s : Set X} (hμ : ∀ x ∈ sᶜ, μ {x} = 0) : μ s = 1 := by
  sorry

end MeasureTheory
