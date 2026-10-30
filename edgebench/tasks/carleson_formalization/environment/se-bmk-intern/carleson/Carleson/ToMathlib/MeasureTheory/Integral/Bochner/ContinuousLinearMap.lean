module

public import Mathlib.MeasureTheory.Integral.Bochner.ContinuousLinearMap

public section

open MeasureTheory

-- Upstreaming status: looks ready for upstreaming; pay attention to the correct file to move to!

-- Put after `setIntegral_re_add_im`

lemma starRingEnd_div_mul_eq_norm {α 𝕜 : Type*} [RCLike 𝕜] {f : α → 𝕜} (x : α) :
    starRingEnd 𝕜 (f x / ‖f x‖) * f x = ‖f x‖ := by
  sorry

-- move to Mathlib.Analysis.Normed.Module.Basic, next to nnnorm_algebraMap'
lemma enorm_algebraMap' {𝕜 : Type*} (𝕜' : Type*) [NormedField 𝕜] [SeminormedRing 𝕜']
    [NormedAlgebra 𝕜 𝕜'] [NormOneClass 𝕜'] (x : 𝕜) : ‖(algebraMap 𝕜 𝕜') x‖ₑ = ‖x‖ₑ := by
  sorry

lemma enorm_integral_norm_eq_integral_enorm {α 𝕜 : Type*} [MeasurableSpace α] [RCLike 𝕜]
    {μ : Measure α} {f : α → 𝕜} (hf : Integrable f μ) : ‖∫ x, ‖f x‖ ∂μ‖ₑ = ∫⁻ x, ‖f x‖ₑ ∂μ := by
  sorry

lemma enorm_integral_starRingEnd_mul_eq_lintegral_enorm
    {𝕜 : Type*} [RCLike 𝕜] {α : Type*} [MeasurableSpace α] {μ : Measure α} {f : α → 𝕜}
    (hf : Integrable f μ) :
    ‖∫ x, starRingEnd 𝕜 (f x / ‖f x‖) * f x ∂μ‖ₑ = ∫⁻ x, ‖f x‖ₑ ∂μ := by
  sorry

lemma enorm_integral_mul_starRingEnd_comm
    {𝕜 : Type*} [RCLike 𝕜] {α : Type*} [MeasurableSpace α] {μ : Measure α} {f g : α → 𝕜} :
    ‖∫ x, f x * starRingEnd 𝕜 (g x) ∂μ‖ₑ = ‖∫ x, g x * starRingEnd 𝕜 (f x) ∂μ‖ₑ := by
  sorry

-- Like this it fits copy-paste next to setIntegral_union
section SetIntegral_Union_2

variable {X E : Type*} [MeasurableSpace X]
variable [NormedAddCommGroup E] [NormedSpace ℝ E]
variable {f : X → E} {s t : Set X} {μ : Measure X}

theorem MeasureTheory.setIntegral_union_2
    (hst : Disjoint s t) (ht : MeasurableSet t) (hfst : IntegrableOn f (s ∪ t) μ) :
    ∫ x in s ∪ t, f x ∂μ = ∫ x in s, f x ∂μ + ∫ x in t, f x ∂μ := by
  sorry

end SetIntegral_Union_2
