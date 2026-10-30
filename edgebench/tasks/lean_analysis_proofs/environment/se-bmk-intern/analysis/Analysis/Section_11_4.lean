import Mathlib.Tactic
import Analysis.Section_9_6
import Analysis.Section_11_3

/-!
# Analysis I, Section 11.4: Basic properties of the Riemann integral

I have attempted to make the translation as faithful a paraphrasing as possible of the original
text. When there is a choice between a more idiomatic Lean solution and a more faithful
translation, I have generally chosen the latter. In particular, there will be places where the
Lean code could be "golfed" to be more elegant and idiomatic, but I have consciously avoided
doing so.

Main constructions and results of this section:
- Basic properties of the Riemann integral.

-/

namespace Chapter11
open Chapter9

/-- Theorem 11.4.1(d) / Exercise 11.4.1 -/
theorem IntegrableOn.nonneg {I: BoundedInterval} {f:ℝ → ℝ} (hf: IntegrableOn f I) (hf_nonneg: ∀ x ∈ I, 0 ≤ f x) :
  0 ≤ integ f I := by
  sorry

/-- Theorem 11.4.1(f) / Exercise 11.4.1 -/
theorem IntegrableOn.const (c:ℝ) (I: BoundedInterval) :
  IntegrableOn (fun _ ↦ c) I ∧ integ (fun _ ↦ c) I = c * |I|ₗ := by
  sorry

/-- Theorem 11.4.1(f) / Exercise 11.4.1 -/
theorem IntegrableOn.const' {I: BoundedInterval} {f:ℝ → ℝ} (hf: ConstantOn f I) :
  IntegrableOn f I ∧ integ f I = (constant_value_on f I) * |I|ₗ := by
  sorry

open Classical in
/-- Theorem 11.4.1 (g)  / Exercise 11.4.1 -/
theorem IntegrableOn.of_extend {I J: BoundedInterval} (hIJ: I ⊆ J)
  {f: ℝ → ℝ} (h: IntegrableOn f I) :
  IntegrableOn (fun x ↦ if x ∈ I then f x else 0) J := by
  sorry

open Classical in
/-- Theorem 11.4.1 (g)  / Exercise 11.4.1 -/
theorem IntegrableOn.of_extend' {I J: BoundedInterval} (hIJ: I ⊆ J)
  {f: ℝ → ℝ} (h: IntegrableOn f I) :
  integ (fun x ↦ if x ∈ I then f x else 0) J = integ f I := by
  sorry

/-- Theorem 11.4.3 (Max and min preserve integrability)-/
theorem IntegrableOn.max {I: BoundedInterval} {f g:ℝ → ℝ} (hf: IntegrableOn f I) (hg: IntegrableOn g I) :
  IntegrableOn (f ⊔ g) I  := by
  sorry

/-- Corollary 11.4.4 -/
theorem IntegrableOn.abs {I: BoundedInterval} {f:ℝ → ℝ} (hf: IntegrableOn f I) :
  IntegrableOn (abs f) I := by
  sorry

/-- Theorem 11.4.5 (Products preserve Riemann integrability).
It is convenient to first establish the non-negative case.-/
theorem integ_of_mul_nonneg {I: BoundedInterval} {f g:ℝ → ℝ} (hf: IntegrableOn f I) (hg: IntegrableOn g I)
  (hf_nonneg: MajorizesOn f 0 I) (hg_nonneg: MajorizesOn g 0 I) :
  IntegrableOn (f * g) I := by
  sorry

theorem integ_of_mul {I: BoundedInterval} {f g:ℝ → ℝ} (hf: IntegrableOn f I) (hg: IntegrableOn g I) :
  IntegrableOn (f * g) I := by
  sorry
open BoundedInterval

end Chapter11
