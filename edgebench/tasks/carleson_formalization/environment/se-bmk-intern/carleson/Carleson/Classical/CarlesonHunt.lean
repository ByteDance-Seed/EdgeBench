module

public import Carleson.Classical.ClassicalCarleson

/-! This file contains the Carleson-Hunt theorem, a generalization of `classical_carleson`. -/

public section

open MeasureTheory Real

noncomputable section

local notation "S_" => partialFourierSum

/-- Classical theorem of Carleson and Hunt asserting a.e. convergence of the partial Fourier sums
for `L^p` functions for `p > 1`. This is a strengthening of `classical_carleson`, and not officially
part of the blueprint. -/
theorem carleson_hunt {T : ℝ} [hT : Fact (0 < T)] {f : AddCircle T → ℂ} {p : ENNReal} (hp : 1 < p)
    (hf : MemLp f p AddCircle.haarAddCircle) :
    ∀ᵐ x, Filter.Tendsto (partialFourierSum' · f x) Filter.atTop (nhds (f x)) := by
  sorry

end
