import Mathlib.Analysis.Calculus.ParametricIntegral
import Mathlib.Analysis.Calculus.ContDiff.FiniteDimension
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import SphereEversion.ToMathlib.Analysis.Calculus

open TopologicalSpace MeasureTheory Filter FirstCountableTopology Metric Set Function
open scoped Topology

section

variable {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] [CompleteSpace E]
  {H : Type*} [NormedAddCommGroup H] [NormedSpace ℝ H]

/-!
We could weaken `FiniteDimensional ℝ H` with `SecondCountable (H →L[ℝ] E)` if needed,
but that is less convenient to work with.
-/

open Real ContinuousLinearMap Asymptotics Interval

@[inherit_doc] local notation:70 u " ⬝ " φ =>
  ContinuousLinearMap.comp (ContinuousLinearMap.toSpanSingleton ℝ u) φ

variable [FiniteDimensional ℝ H]

end

section

variable {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] [CompleteSpace E]
  {H : Type*} [NormedAddCommGroup H] [NormedSpace ℝ H] [FiniteDimensional ℝ H]

open Real ContinuousLinearMap Asymptotics

@[inherit_doc] local notation:70 u " ⬝ " φ =>
  ContinuousLinearMap.comp (ContinuousLinearMap.toSpanSingleton ℝ u) φ

theorem contDiff_parametric_primitive_of_contDiff' {F : H → ℝ → E} {n : ℕ} (hF : ContDiff ℝ n ↿F)
    {s : H → ℝ} (hs : ContDiff ℝ n s) (a : ℝ) : ContDiff ℝ n fun x : H ↦ ∫ t in a..s x, F x t := by
  sorry

end

section

universe v u

variable {E : Type u}

variable [NormedAddCommGroup E] [NormedSpace ℝ E] [CompleteSpace E] {H : Type v}
  [NormedAddCommGroup H] [NormedSpace ℝ H] [FiniteDimensional ℝ H]

-- Should we directly prove the version below?
theorem contDiff_parametric_primitive_of_contDiff {F : H → ℝ → E} {n : ℕ∞} (hF : ContDiff ℝ n ↿F)
    {s : H → ℝ} (hs : ContDiff ℝ n s) (a : ℝ) : ContDiff ℝ n fun x : H ↦ ∫ t in a..s x, F x t := by
  sorry

theorem contDiff_parametric_primitive_of_contDiff'' {F : H → ℝ → E} {n : ℕ∞} (hF : ContDiff ℝ n ↿F)
    (a : ℝ) : ContDiff ℝ n fun x : H × ℝ ↦ ∫ t in a..x.2, F x.1 t := by
  sorry

theorem contDiff_parametric_integral_of_contDiff {F : H → ℝ → E} {n : ℕ∞} (hF : ContDiff ℝ n ↿F)
    (a b : ℝ) : ContDiff ℝ n fun x : H ↦ ∫ t in a..b, F x t := by
  sorry

theorem ContDiff.fderiv_parametric_integral {F : H → ℝ → E} (hF : ContDiff ℝ 1 ↿F) (a b : ℝ) :
    (fderiv ℝ fun x : H ↦ ∫ t in a..b, F x t) = fun x : H ↦
      ∫ t in a..b, fderiv ℝ (fun x' ↦ F x' t) x := by
  sorry

end
