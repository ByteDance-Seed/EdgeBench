module

public import Mathlib.Analysis.Convolution

public section

-- Upstreaming status: seems ready to go

open scoped Convolution

namespace MeasureTheory

universe u𝕜 uG uE uE' uF

variable {𝕜 : Type u𝕜} {G : Type uG} {E : Type uE} {E' : Type uE'} {F : Type uF}

variable [NormedAddCommGroup E] [NormedAddCommGroup E'] [NormedAddCommGroup F]
  {f : G → E} {g : G → E'}

variable [NontriviallyNormedField 𝕜]

variable [NormedSpace 𝕜 E] [NormedSpace 𝕜 E'] [NormedSpace 𝕜 F]
variable {L : E →L[𝕜] E' →L[𝕜] F}

variable [MeasurableSpace G]

/-- Special case of `convolution_flip` when `L` is symmetric. -/
theorem convolution_symm {f : G → E} {g : G → E} (L : E →L[𝕜] E →L[𝕜] F)
    (hL : ∀ (x y : E), L x y = L y x) [NormedSpace ℝ F] [AddCommGroup G]
    {μ : Measure G} [μ.IsAddLeftInvariant] [μ.IsNegInvariant] [MeasurableNeg G] [MeasurableAdd G] :
    f ⋆[L, μ] g = g ⋆[L, μ] f := by
  sorry

variable [AddGroup G] [MeasurableAdd₂ G] [MeasurableNeg G] {μ : Measure G} [SigmaFinite μ]

/-- The convolution of two a.e. strongly measurable functions is a.e. strongly measurable. -/
@[fun_prop]
protected theorem AEStronglyMeasurable.convolution [NormedSpace ℝ F] [μ.IsAddRightInvariant]
    (hf : AEStronglyMeasurable f μ) (hg : AEStronglyMeasurable g μ) :
    AEStronglyMeasurable (f ⋆[L, μ] g) μ := by
  sorry

/-- This implies both of the following theorems `convolutionExists_of_memLp_memLp` and
`enorm_convolution_le_eLpNorm_mul_eLpNorm`. -/
lemma lintegral_enorm_convolution_integrand_le_eLpNorm_mul_eLpNorm
    [μ.IsNegInvariant] [μ.IsAddLeftInvariant] {p q : ENNReal} (hpq : p.HolderConjugate q)
    (hL : ∀ (x y : G), ‖L (f x) (g y)‖ ≤ ‖f x‖ * ‖g y‖)
    (hf : AEStronglyMeasurable f μ) (hg : AEStronglyMeasurable g μ) (x₀ : G) :
    ∫⁻ a, ‖L (f a) (g (x₀ - a))‖ₑ ∂μ ≤ eLpNorm f p μ * eLpNorm g q μ := by
  sorry

/-- If `MemLp f p μ` and `MemLp g q μ`, where `p` and `q` are Hölder conjugates, then the
convolution of `f` and `g` exists everywhere. -/
theorem ConvolutionExists.of_memLp_memLp
    [μ.IsNegInvariant] [μ.IsAddLeftInvariant] [μ.IsAddRightInvariant]
    {p q : ENNReal} (hpq : p.HolderConjugate q)
    (hL : ∀ (x y : G), ‖L (f x) (g y)‖ ≤ ‖f x‖ * ‖g y‖) (hf : AEStronglyMeasurable f μ)
    (hg : AEStronglyMeasurable g μ) (hfp : MemLp f p μ) (hgq : MemLp g q μ) :
    ConvolutionExists f g L μ := by
  sorry

/-- If `p` and `q` are Hölder conjugates, then the convolution of `f` and `g` is bounded everywhere
by `eLpNorm f p μ * eLpNorm g q μ`. -/
theorem enorm_convolution_le_eLpNorm_mul_eLpNorm [NormedSpace ℝ F]
    [μ.IsNegInvariant] [μ.IsAddLeftInvariant] {p q : ENNReal} (hpq : p.HolderConjugate q)
    (hL : ∀ (x y : G), ‖L (f x) (g y)‖ ≤ ‖f x‖ * ‖g y‖)
    (hf : AEStronglyMeasurable f μ) (hg : AEStronglyMeasurable g μ) (x₀ : G) :
    ‖(f ⋆[L, μ] g) x₀‖ₑ ≤ eLpNorm f p μ * eLpNorm g q μ := by
  sorry

end MeasureTheory
