module

public import Carleson.ToMathlib.ENorm
public import Carleson.ToMathlib.MeasureTheory.Function.SimpleFunc
public import Carleson.ToMathlib.MeasureTheory.Measure.NNReal

--Upstreaming status: not sure if this should go to mathlib; proof might be shortened

public section

open NNReal ENNReal MeasureTheory

-- This is Theorem 4.19 in https://doi.org/10.1007/978-3-319-30034-4
theorem lintegral_antitone_mul_le {f g k : ℝ≥0 → ℝ≥0∞} (hf : AEMeasurable f) (hg : AEMeasurable g)
  (h : ∀ {t}, ∫⁻ s in Set.Iio t, f s ≤ ∫⁻ s in Set.Iio t, g s) (hk : Antitone k) :
    ∫⁻ s, k s * f s ≤ ∫⁻ s, k s * g s := by
  sorry
