module

public import Carleson.ToMathlib.Analysis.SpecialFunctions.ImproperIntegrals
public import Carleson.ToMathlib.MeasureTheory.Measure.NNReal

public section

--Upstreaming status: ready

namespace MeasureTheory

open ENNReal

theorem setLIntegral_Ioo_rpow {p : ℝ} {a b : ℝ≥0∞} (hp : -1 < p) :
    ∫⁻ (t : ℝ≥0∞) in Set.Ioo a b, t ^ p = (b ^ (p + 1) - a ^ (p + 1)) / ENNReal.ofReal (p + 1) := by
  sorry

theorem setLIntegral_Iio_rpow {p : ℝ} {b : ℝ≥0∞} (hp : -1 < p) :
    ∫⁻ (t : ℝ≥0∞) in Set.Iio b, t ^ p = b ^ (p + 1) / ENNReal.ofReal (p + 1) := by
  sorry

end MeasureTheory
