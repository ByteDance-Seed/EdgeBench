import Mathlib.Tactic
import Mathlib.Data.Real.Sign
import Analysis.Section_9_3
import Analysis.Section_9_4

/-!
# Analysis I, Section 9.5: Left and right limits

I have attempted to make the translation as faithful a paraphrasing as possible of the original
text.  When there is a choice between a more idiomatic Lean solution and a more faithful
translation, I have generally chosen the latter.  In particular, there will be places where
the Lean code could be "golfed" to be more elegant and idiomatic, but I have consciously avoided
doing so.

Main constructions and results of this section:
- Left and right limits.
-/

namespace Chapter9

/-- Definition 9.5.1.  We give left and right limits the "junk" value of 0 if the limit does not exist. -/
abbrev RightLimitExists (X: Set ℝ) (f: ℝ → ℝ) (x₀:ℝ) : Prop := ∃ L, (nhdsWithin x₀ (X ∩ .Ioi x₀)).Tendsto f (nhds L)

open Classical in
noncomputable abbrev right_limit (X: Set ℝ) (f: ℝ → ℝ) (x₀:ℝ) : ℝ := if h : RightLimitExists X f x₀ then h.choose else 0

abbrev LeftLimitExists (X: Set ℝ) (f: ℝ → ℝ) (x₀:ℝ) : Prop := ∃ L, (nhdsWithin x₀ (X ∩ .Iio x₀)).Tendsto f (nhds L)

open Classical in
noncomputable abbrev left_limit (X: Set ℝ) (f: ℝ → ℝ) (x₀:ℝ) : ℝ := if h: LeftLimitExists X f x₀ then h.choose else 0

/-- Example 9.5.2.  The second part of this example is no longer operative as we assign "junk" values to our functions instead of leaving them undefined. -/
example : right_limit .univ Real.sign 0 = 1 := by
  sorry

example : left_limit .univ Real.sign 0 = -1 := by
  sorry

theorem right_limit.conv {X: Set ℝ} {f: ℝ → ℝ} {x₀:ℝ} (had: AdherentPt x₀ (X ∩ .Ioi x₀))
  (h: RightLimitExists X f x₀)
  (a:ℕ → ℝ) (ha: ∀ n, a n ∈ X ∩ .Ioi x₀)
  (hconv: Filter.atTop.Tendsto a (nhds x₀)) :
  Filter.atTop.Tendsto (fun n ↦ f (a n)) (nhds (right_limit X f x₀)) := by
  sorry

theorem left_limit.conv {X: Set ℝ} {f: ℝ → ℝ} {x₀:ℝ} (had: AdherentPt x₀ (X ∩ .Iio x₀))
  (h: LeftLimitExists X f x₀)
  (a:ℕ → ℝ) (ha: ∀ n, a n ∈ X ∩ .Iio x₀)
  (hconv: Filter.atTop.Tendsto a (nhds x₀)) :
  Filter.atTop.Tendsto (fun n ↦ f (a n)) (nhds (left_limit X f x₀)) := by
  sorry

/-- Proposition 9.5.3 -/
theorem ContinuousAt.iff_eq_left_right_limit {X: Set ℝ} {f: ℝ → ℝ} {x₀:ℝ} (h: x₀ ∈ X)
  (had_left: AdherentPt x₀ (X ∩ .Iio x₀)) (had_right: AdherentPt x₀ (X ∩ .Ioi x₀)) :
  ContinuousWithinAt f X x₀ ↔ (RightLimitExists X f x₀ ∧ right_limit X f x₀ = f x₀) ∧ (LeftLimitExists X f x₀ ∧ left_limit X f x₀ = f x₀) := by
  sorry

abbrev HasJumpDiscontinuity (X: Set ℝ) (f: ℝ → ℝ) (x₀:ℝ) : Prop :=
  RightLimitExists X f x₀ ∧ LeftLimitExists X f x₀ ∧ right_limit X f x₀ ≠ left_limit X f x₀

example : HasJumpDiscontinuity .univ Real.sign 0 := by
  sorry

abbrev HasRemovableDiscontinuity (X: Set ℝ) (f: ℝ → ℝ) (x₀:ℝ) : Prop :=
  RightLimitExists X f x₀ ∧ LeftLimitExists X f x₀ ∧ right_limit X f x₀ = left_limit X f x₀
  ∧ right_limit X f x₀ ≠ f x₀

example : HasRemovableDiscontinuity .univ f_9_3_17 0 := by
  sorry

example : ¬ HasRemovableDiscontinuity .univ (fun x ↦ 1/x) 0 := by
  sorry

example : ¬ HasJumpDiscontinuity .univ (fun x ↦ 1/x) 0 := by
  sorry

/- Exercise 9.5.1: Write down a definition of what it would mean for a limit of a function to be `+∞` or `-∞`, apply to `fun x ↦ 1/x`, and state and prove a version of Proposition 9.3.9. -/

end Chapter9
