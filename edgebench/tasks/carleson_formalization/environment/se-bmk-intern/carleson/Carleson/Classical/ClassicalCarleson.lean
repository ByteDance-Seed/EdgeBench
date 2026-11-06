module

public import Carleson.Classical.Approximation
public import Carleson.Classical.ControlApproximationEffect

public section

/- This file contains the proof of the classical Carleson theorem from Section 11.1. -/

open MeasureTheory Real

noncomputable section

local notation "S_" => partialFourierSum

/- Theorem 1.1 (Classical Carleson) -/
theorem exceptional_set_carleson {f : ℝ → ℂ}
    (cont_f : Continuous f) (periodic_f : f.Periodic (2 * π))
    {ε : ℝ} (εpos : 0 < ε) :
    ∃ E ⊆ Set.Icc 0 (2 * π), MeasurableSet E ∧ volume.real E ≤ ε ∧
    ∃ N₀, ∀ x ∈ (Set.Icc 0 (2 * π)) \ E, ∀ N > N₀,
    ‖f x - S_ N f x‖ ≤ ε := by
  sorry

theorem carleson_interval {f : ℝ → ℂ} (cont_f : Continuous f) (periodic_f : f.Periodic (2 * π)) :
    ∀ᵐ x ∂volume.restrict (Set.Icc 0 (2 * π)),
      Filter.Tendsto (S_ · f x) Filter.atTop (nhds (f x)) := by
  sorry

section
open Pointwise

--TODO: might be generalized
lemma Function.Periodic.ae_of_ae_restrict {T : ℝ} (hT : 0 < T) {a : ℝ} {P : (x : ℝ) → Prop}
    (hP : Function.Periodic P T)
    (h : ∀ᵐ x ∂volume.restrict (Set.Ico a (a + T)), P x) : ∀ᵐ x, P x := by
  sorry

end

/- **Carleson's theorem** asserting a.e. point-wise convergence of the partial Fourier sums for
periodic continuous functions. -/
theorem classical_carleson {f : ℝ → ℂ} (cont_f : Continuous f) (periodic_f : f.Periodic (2 * π)) :
    ∀ᵐ x, Filter.Tendsto (S_ · f x) Filter.atTop (nhds (f x)) := by
  sorry

theorem classical_carleson_check : ClassicalCarleson := by
  sorry

end
