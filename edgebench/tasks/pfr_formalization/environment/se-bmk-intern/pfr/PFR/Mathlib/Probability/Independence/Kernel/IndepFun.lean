module

public import Mathlib.Data.Finset.Pairwise
public import Mathlib.Probability.Independence.Kernel.IndepFun

public section

open MeasureTheory MeasurableSpace

open scoped MeasureTheory ENNReal

namespace ProbabilityTheory.Kernel
variable {ι α β β' γ γ' Ω : Type*} {_mα : MeasurableSpace α} {_mΩ : MeasurableSpace Ω}
  {κ : Kernel α Ω} {μ : Measure α} {f : Ω → β} {g : Ω → β'}

section iIndepFun

variable {β γ : ι → Type*} {m : ∀ i, MeasurableSpace (β i)} {mγ : ∀ i, MeasurableSpace (γ i)}
  {f : ∀ i, Ω → β i}

-- maybe `Fintype J` is not necessary?

end ProbabilityTheory.Kernel.iIndepFun
