import Mathlib.Tactic
/-!
# Analysis I, Section 9.10: Limits at infinity

I have attempted to make the translation as faithful a paraphrasing as possible of the original
text.  When there is a choice between a more idiomatic Lean solution and a more faithful
translation, I have generally chosen the latter.  In particular, there will be places where
the Lean code could be "golfed" to be more elegant and idiomatic, but I have consciously avoided
doing so.

Main constructions and results of this section:
- Bare-bones API for the Mathlib versions of adherent at infinity, and limits at infinity.
-/

namespace Chapter9

theorem BddAbove.unbounded_iff' (X:Set ℝ) : ¬ BddAbove X ↔ sSup ((fun x:ℝ ↦ (x:EReal)) '' X) = ⊤ := by
  sorry

theorem BddBelow.unbounded_iff (X:Set ℝ) : ¬ BddBelow X ↔ ∀ M, ∃ x ∈ X, x < M := by
  sorry

theorem BddBelow.unbounded_iff' (X:Set ℝ) : ¬ BddBelow X ↔ sInf ((fun x:ℝ ↦ (x:EReal)) '' X) = ⊥ := by
  sorry

/-- Definition 9.10.13 (Limit at infinity) -/
theorem Filter.Tendsto.AtTop.iff {X: Set ℝ} (f:ℝ → ℝ) (L:ℝ) : Filter.Tendsto f (.atTop ⊓ .principal X) (nhds L) ↔ ∀ ε > (0:ℝ), ∃ M, ∀ x ∈ X ∩ .Ici M, |f x - L| < ε := by
  sorry

/-- Exercise 9.10.4 -/
example : Filter.Tendsto (fun x:ℝ ↦ 1/x) (.atTop ⊓ .principal (.Ioi 0)) (nhds 0) := by
  sorry

open Classical in
/-- Exercise 9.10.1 -/
example (a:ℕ → ℝ) (L:ℝ) : Filter.Tendsto (fun x:ℝ ↦ (if h:(∃ n:ℕ, x = n) then a h.choose else 0)) (.atTop ⊓ .principal ((fun n:ℕ ↦ (n:ℝ)) '' .univ)) (nhds L) ↔ Filter.atTop.Tendsto a (nhds L) := by
  sorry

end Chapter9
