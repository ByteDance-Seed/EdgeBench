import Mathlib.Tactic
import Analysis.Section_9_9
import Analysis.Section_11_4

/-!
# Analysis I, Section 11.5: Riemann integrability of continuous functions

I have attempted to make the translation as faithful a paraphrasing as possible of the original
text. When there is a choice between a more idiomatic Lean solution and a more faithful
translation, I have generally chosen the latter. In particular, there will be places where the
Lean code could be "golfed" to be more elegant and idiomatic, but I have consciously avoided
doing so.

Main constructions and results of this section:
- Riemann integrability of uniformly continuous functions.
- Riemann integrability of bounded continuous functions.

-/

namespace Chapter11
open BoundedInterval
open Chapter9

/-- Theorem 11.5.1 -/
theorem integ_of_uniform_cts {I: BoundedInterval} {f:ℝ → ℝ} (hf: UniformContinuousOn f I) :
  IntegrableOn f I := by
  sorry

/-- Corollary 11.5.2 -/
theorem integ_of_cts {a b:ℝ} {f:ℝ → ℝ} (hf: ContinuousOn f (Icc a b)) :
  IntegrableOn f (Icc a b) := by
  sorry

example : ContinuousOn (fun x:ℝ ↦ 1/x) (Icc 0 1) := by
  sorry

example : ¬ IntegrableOn (fun x:ℝ ↦ 1/x) (Icc 0 1) := by
  sorry

open PiecewiseConstantOn ConstantOn in
set_option maxHeartbeats 300000 in
/-- Proposition 11.5.3-/
theorem integ_of_bdd_cts {I: BoundedInterval} {f:ℝ → ℝ} (hbound: BddOn f I)
  (hf: ContinuousOn f I) : IntegrableOn f I := by
  sorry

/-- Definition 11.5.4 -/
abbrev PiecewiseContinuousOn (f:ℝ → ℝ) (I:BoundedInterval) : Prop :=
  ∃ P: Partition I, ∀ J ∈ P.intervals, ContinuousOn f J

/-- Example 11.5.5 -/
noncomputable abbrev f_11_5_5 : ℝ → ℝ := fun x ↦
  if x < 2 then x^2
  else if x = 2 then 7
  else x^3

example : ¬ ContinuousOn f_11_5_5 (Icc 1 3) := by
  sorry

example : ContinuousOn f_11_5_5 (Ico 1 2) := by
  sorry

example : ContinuousOn f_11_5_5 (Icc 2 2) := by
  sorry

example : ContinuousOn f_11_5_5 (Ioc 2 3) := by
  sorry

example : PiecewiseContinuousOn f_11_5_5 (Icc 1 3) := by
  sorry

/-- Proposition 11.5.6 / Exercise 11.5.1 -/
theorem integ_of_bdd_piecewise_cts {I: BoundedInterval} {f:ℝ → ℝ}
  (hbound: BddOn f I) (hf: PiecewiseContinuousOn f I) : IntegrableOn f I := by
  sorry

/-- Exercise 11.5.2 -/
theorem integ_zero {a b:ℝ} (hab: a ≤ b) (f: ℝ → ℝ) (hf: ContinuousOn f (Icc a b))
  (hnonneg: MajorizesOn f (fun _ ↦ 0) (Icc a b)) (hinteg : integ f (Icc a b) = 0) :
  ∀ x ∈ Icc a b, f x = 0 := by
  sorry

end Chapter11
