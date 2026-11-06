module

public import Mathlib.MeasureTheory.Measure.Real
public import PFR.Mathlib.MeasureTheory.Measure.Prod

public section

open Function Set
open scoped ENNReal NNReal

namespace MeasureTheory
variable {α β R Ω Ω' : Type*} {_ : MeasurableSpace Ω} {_ : MeasurableSpace Ω'}
  {_ : MeasurableSpace α} {_ : MeasurableSpace β}

lemma Measure.nnreal_smul_real_apply (c : ℝ≥0) (μ : Measure Ω) (s : Set Ω) :
    (c • μ).real s = c • μ.real s := by
  sorry

variable [MeasurableSingletonClass Ω] [MeasurableSingletonClass Ω']

lemma measureReal_preimage_fst_singleton_eq_sum [Fintype Ω'] (μ : Measure (Ω × Ω'))
    [IsFiniteMeasure μ] (x : Ω) :
    μ.real (Prod.fst ⁻¹' {x}) = ∑ y : Ω', μ.real {(x, y)} := by
  sorry

lemma measureReal_preimage_snd_singleton_eq_sum [Fintype Ω] (μ : Measure (Ω × Ω'))
    [IsFiniteMeasure μ] (y : Ω') :
    μ.real (Prod.snd ⁻¹' {y}) = ∑ x : Ω, μ.real {(x, y)} := by
  sorry

end MeasureTheory
