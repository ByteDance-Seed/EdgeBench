module

public import Mathlib.MeasureTheory.Function.LpSeminorm.Basic
public import Mathlib.MeasureTheory.Measure.WithDensity
public import Carleson.ToMathlib.MeasureTheory.Measure.NNReal
public import Carleson.ToMathlib.MeasureTheory.Measure.AEMeasurable

--Upstreaming status: ready

public section

noncomputable section

open scoped NNReal ENNReal

variable {α ε : Type*} {m : MeasurableSpace α} [ENorm ε] {f : α → ε}

namespace MeasureTheory

lemma eLpNormEssSup_congr_measure {μ ν : Measure α} (h : ae ν = ae μ) :
    eLpNormEssSup f ν = eLpNormEssSup f μ := by
  sorry

lemma eLpNormEssSup_withDensity {μ : Measure α} {d : α → ℝ≥0∞} (hd : AEMeasurable d μ)
  (hd' : ∀ᵐ (x : α) ∂μ, d x ≠ 0) :
    eLpNormEssSup f (μ.withDensity d) = eLpNormEssSup f μ := by
  sorry

lemma eLpNormEssSup_nnreal_scale_constant' {f : ℝ≥0 → ℝ≥0∞} {a : ℝ≥0} (h : a ≠ 0)
  (hf : AEStronglyMeasurable f) :
    eLpNormEssSup (fun x ↦ f (a * x)) volume = eLpNormEssSup f volume := by
  sorry

lemma eLpNorm_withDensity_scale_constant' {f : ℝ≥0 → ℝ≥0∞} (hf : AEStronglyMeasurable f) {p : ℝ≥0∞}
  {a : ℝ≥0} (h : a ≠ 0) :
  eLpNorm (fun t ↦ f (a * t)) p (volume.withDensity (fun (t : ℝ≥0) ↦ t⁻¹))
    = eLpNorm f p (volume.withDensity (fun (t : ℝ≥0) ↦ t⁻¹))  := by
  sorry

end MeasureTheory
