module

public import Mathlib.Probability.UniformOn
public import PFR.Mathlib.Data.Set.Card

public section

open Function MeasureTheory Measure

namespace ProbabilityTheory
variable {Ω Ω' : Type*} [MeasurableSpace Ω] [MeasurableSingletonClass Ω]
  [MeasurableSpace Ω'] [MeasurableSingletonClass Ω'] {s t : Set Ω} {x : Ω}

lemma real_uniformOn_apply_singleton_of_mem (hx : x ∈ s) (hs : s.Finite) :
    (uniformOn s).real {x} = 1 / Nat.card s := by
  sorry

lemma real_uniformOn_apply_singleton_of_not_mem (hx : x ∉ s) :
    (uniformOn s).real {x} = 0 := by
  sorry

instance uniformOn.instIsProbabilityMeasure [Nonempty s] [Finite s] :
    IsProbabilityMeasure (uniformOn s) := isProbabilityMeasure_uniformOn ‹_› .of_subtype

lemma map_uniformOn {f : Ω → Ω'} (hmes : Measurable f) (hf : Injective f) :
    (uniformOn s).map f = uniformOn (f '' s) := by
  sorry

end ProbabilityTheory
