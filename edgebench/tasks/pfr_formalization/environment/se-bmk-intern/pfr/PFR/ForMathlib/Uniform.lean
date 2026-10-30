module

public import Mathlib.MeasureTheory.Measure.Real
public import Mathlib.Probability.IdentDistrib
public import PFR.ForMathlib.FiniteRange.Defs
public import PFR.Mathlib.Probability.UniformOn

public section

open Function MeasureTheory Measure Set
open scoped ENNReal

namespace ProbabilityTheory
universe uΩ uS uT uU
variable {Ω : Type uΩ} {S : Type uS} {T : Type uT} [mΩ : MeasurableSpace Ω]
  {X : Ω → S} {Y : Ω → T} {μ : Measure Ω} {H : Set S}

/-- The assertion that the law of $X$ is the uniform probability measure on a finite set $H$.
While in applications $H$ will be non-empty finite set, $X$ measurable, and and $μ$ a probability
measure, it could be technically convenient to have a definition that works even without these
hypotheses. (For instance, `isUniform` would be well-defined, but false, for infinite `H`).

This should probably be refactored, requiring instead that `μ.map X = uniformOn H`. -/
structure IsUniform (H : Set S) (X : Ω → S) (μ : Measure Ω := by volume_tac) : Prop where
  eq_of_mem ⦃x⦄ (hx : x ∈ H) ⦃y⦄ (hy : y ∈ H) : μ (X ⁻¹' {x}) = μ (X ⁻¹' {y})
  measure_preimage_compl : μ (X ⁻¹' Hᶜ) = 0

/-- Uniform random variables only exist for non-empty sets H. -/
lemma IsUniform.nonempty {H : Finset S} (h : IsUniform H X μ) [hμ : NeZero μ] : H.Nonempty := by
  sorry

variable [MeasurableSpace S] [DiscreteMeasurableSpace S]

end ProbabilityTheory
