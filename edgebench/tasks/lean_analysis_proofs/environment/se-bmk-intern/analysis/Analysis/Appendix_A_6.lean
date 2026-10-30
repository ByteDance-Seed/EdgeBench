import Mathlib.Tactic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv

/-!
# Analysis I, Appendix A.6: Some examples of proofs and quantifiers

Some examples of proofs and quantifiers in Lean

-/

/-- Proposition A.6.1 -/
example : ∀ ε > (0:ℝ), ∃ δ > 0, 2 * δ < ε := by
  sorry

example : ¬ ∃ δ > 0, ∀ ε > (0:ℝ), 2 * δ < ε := by
  sorry

open Real in
/-- Proposition A.6.2.  The proof below is somewhat non-idiomatic for Lean, but illustrates how to implement a "let ε be a quantity to be chosen later" type of proof. -/
example : ∃ ε > 0, ∀ x, 0 < x ∧ x < ε → sin x > x / 2 := by
  sorry

open Real in
/-- Proposition A.6.2: a more idiomatic proof -/
example : ∃ ε > 0, ∀ x, 0 < x ∧ x < ε → sin x > x / 2 := by
  sorry
