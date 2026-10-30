module

public import Mathlib.Probability.ConditionalProbability
public import PFR.ForMathlib.FiniteRange.Defs

public section

open MeasureTheory Set

namespace ProbabilityTheory
variable {Ω α : Type*} {m : MeasurableSpace Ω} (μ : Measure Ω)
 [MeasurableSpace α] [MeasurableSingletonClass α]

-- TODO: Replace `sum_meas_smul_cond_fiber` once `FiniteRange` is in Mathlib.

end ProbabilityTheory
