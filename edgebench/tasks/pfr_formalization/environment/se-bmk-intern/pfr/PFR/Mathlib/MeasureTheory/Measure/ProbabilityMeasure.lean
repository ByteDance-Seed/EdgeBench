module

public import Mathlib.MeasureTheory.Measure.ProbabilityMeasure

public section

open MeasureTheory ProbabilityMeasure Topology Metric Filter Set ENNReal NNReal
open scoped BoundedContinuousFunction Topology ENNReal NNReal

variable {ι X : Type*} [MeasurableSpace X] [TopologicalSpace X]

/-- The measure of any connected component depends continuously on the `FiniteMeasure`. -/
lemma continuous_finiteMeasure_apply_of_isClopen [OpensMeasurableSpace X]
    {s : Set X} (s_clopen : IsClopen s) :
    Continuous fun μ : FiniteMeasure X ↦ (μ : Measure X).real s := by
  sorry
