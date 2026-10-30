import Mathlib.Tactic
import Analysis.Section_9_3
import Analysis.Section_9_4

/-!
# Analysis I, Section 9.7: The intermediate value theorem

I have attempted to make the translation as faithful a paraphrasing as possible of the original
text.  When there is a choice between a more idiomatic Lean solution and a more faithful
translation, I have generally chosen the latter.  In particular, there will be places where
the Lean code could be "golfed" to be more elegant and idiomatic, but I have consciously avoided
doing so.

Main constructions and results of this section:
- The intermediate value theorem.
-/

namespace Chapter9

/-- Theorem 9.7.1 (Intermediate value theorem) -/
theorem intermediate_value {a b:ℝ} (hab: a < b) {f:ℝ → ℝ} (hf: ContinuousOn f (.Icc a b)) {y:ℝ} (hy: y ∈ Set.Icc (f a) (f b) ∨ y ∈ Set.Icc (f b) (f a)) :
  ∃ c ∈ Set.Icc a b, f c = y := by
  sorry

open Classical in
noncomputable abbrev f_9_7_1 : ℝ → ℝ := fun x ↦ if x ≤ 0 then -1 else 1

example : 0 ∈ Set.Icc (f_9_7_1 (-1)) (f_9_7_1 1) ∧ ¬ ∃ x ∈ Set.Icc (-1) 1, f_9_7_1 x = 0 := by
  sorry

/-- Remark 9.7.2 -/
abbrev f_9_7_2 : ℝ → ℝ := fun x ↦ x^3 - x

example : f_9_7_2 (-2) = -6 := by
  sorry
example : f_9_7_2 2 = 6 := by
  sorry
example : f_9_7_2 (-1) = 0 := by
  sorry
example : f_9_7_2 0 = 0 := by
  sorry
example : f_9_7_2 1 = 0 := by
  sorry

/-- Remark 9.7.3 -/
example : ∃ x:ℝ, 0 ≤ x ∧ x ≤ 2 ∧ x^2 = 2 := by
  sorry

/-- Corollary 9.7.4 (Images of continuous functions) / Exercise 9.7.1 -/
theorem continuous_image_Icc {a b:ℝ} (hab: a < b) {f:ℝ → ℝ} (hf: ContinuousOn f (.Icc a b)) {y:ℝ} (hy: sInf (f '' .Icc a b) ≤ y ∧ y ≤ sSup (f '' .Icc a b)) : ∃ c ∈ Set.Icc a b, f c = y := by
  sorry

theorem continuous_image_Icc' {a b:ℝ} (hab: a < b) {f:ℝ → ℝ} (hf: ContinuousOn f (.Icc a b)) : f '' .Icc a b = .Icc (sInf (f '' .Icc a b)) (sSup (f '' .Icc a b)) := by
  sorry

/-- Exercise 9.7.2 -/
theorem exists_fixed_pt {f:ℝ → ℝ} (hf: ContinuousOn f (.Icc 0 1)) (hmap: f '' .Icc 0 1 ⊆ .Icc 0 1) : ∃ x ∈ Set.Icc 0 1, f x = x := by
  sorry

end Chapter9
