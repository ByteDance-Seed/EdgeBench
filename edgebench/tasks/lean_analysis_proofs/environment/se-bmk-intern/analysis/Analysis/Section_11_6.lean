import Mathlib.Tactic
import Analysis.Section_9_8
import Analysis.Section_11_5

/-!
# Analysis I, Section 11.6: Riemann integrability of monotone functions

I have attempted to make the translation as faithful a paraphrasing as possible of the original
text. When there is a choice between a more idiomatic Lean solution and a more faithful
translation, I have generally chosen the latter. In particular, there will be places where the
Lean code could be "golfed" to be more elegant and idiomatic, but I have consciously avoided
doing so.

Main constructions and results of this section:
- Riemann integrability of monotone functions.

-/

namespace Chapter11
open Chapter9 BoundedInterval

set_option maxHeartbeats 300000 in
/-- Proposition 11.6.1 -/
theorem integ_of_monotone {a b:ℝ} {f:ℝ → ℝ} (hf: MonotoneOn f (Icc a b)) :
  IntegrableOn f (Icc a b) := by
  sorry

/-- Proposition 11.6.1 -/
theorem integ_of_antitone {a b:ℝ} {f:ℝ → ℝ} (hf: AntitoneOn f (Icc a b)) :
  IntegrableOn f (Icc a b) := by
  sorry

/-- Corollary 11.6.3 / Exercise 11.6.1 -/
theorem integ_of_bdd_monotone {I:BoundedInterval} {f:ℝ → ℝ} (hbound: BddOn f I)
  (hf: MonotoneOn f I) : IntegrableOn f I := by
  sorry

theorem integ_of_bdd_antitone {I:BoundedInterval} {f:ℝ → ℝ} (hbound: BddOn f I)
  (hf: AntitoneOn f I) : IntegrableOn f I := by
  sorry

/-- Proposition 11.6.4 (Integral test) -/
theorem summable_iff_integ_of_antitone {f:ℝ → ℝ} (hnon: ∀ x ≥ 0, f x ≥ 0)
  (hf: AntitoneOn f (.Ici 0)) :
  Summable f ↔ ∃ M, ∀ N ≥ 0, integ f (Icc 0 N) ≤ M := by
  sorry

-- Exercise 11.6.2: Formulate a reasonable notion of a piecewise monotone function, and then
-- show that all bounded piecewise monotone functions are Riemann integrable.

/-- Exercise 11.6.4 -/
example : ∃ (f:ℝ → ℝ) (hnon: ∀ x ≥ 0, f x ≥ 0), Summable f ∧ ¬ ∃ M, ∀ N ≥ 0, integ f (Icc 0 N) ≤ M := by
  sorry

example : ∃ (f:ℝ → ℝ) (hnon: ∀ x ≥ 0, f x ≥ 0), ¬ Summable f ∧ ∃ M, ∀ N ≥ 0, integ f (Icc 0 N) ≤ M := by
  sorry

end Chapter11
