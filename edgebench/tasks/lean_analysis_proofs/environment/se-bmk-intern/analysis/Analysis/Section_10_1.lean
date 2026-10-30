import Mathlib.Tactic
import Mathlib.Analysis.Calculus.Deriv.Basic
/-!
# Analysis I, Section 10.1: Basic definitions

I have attempted to make the translation as faithful a paraphrasing as possible of the original
text.  When there is a choice between a more idiomatic Lean solution and a more faithful
translation, I have generally chosen the latter.  In particular, there will be places where
the Lean code could be "golfed" to be more elegant and idiomatic, but I have consciously avoided
doing so.

Main constructions and results of this section:
- API for Mathlib's `HasDerivWithinAt`, `derivWithin`, and `DifferentiableWithinAt`.

Note that the Mathlib conventions differ slightly from that in the text, in that
differentiability is defined even at points that are not limit points of the domain;
derivatives in such cases may not be unique, but `derivWithin` still selects one such
derivative in such cases (or {lean}`0`, if no derivative exists).

-/

namespace Chapter10

variable (x₀ : ℝ)

theorem _root_.DifferentiableWithinAt.of_hasDeriv {X: Set ℝ} {x₀ : ℝ} {f: ℝ → ℝ} {L:ℝ}
  (hL: HasDerivWithinAt f L X x₀) : DifferentiableWithinAt ℝ f X x₀ := by
  sorry

#check DifferentiableWithinAt.hasDerivWithinAt

theorem derivative_unique' (X: Set ℝ) {x₀ : ℝ}
  (hx₀: ClusterPt x₀ (.principal (X \ {x₀}))) {f: ℝ → ℝ} {L :ℝ}
  (hL: HasDerivWithinAt f L X x₀)
  (hdiff : DifferentiableWithinAt ℝ f X x₀):
  L = derivWithin f X x₀ := by
  sorry

/-- Example 10.1.3 -/
example (x₀:ℝ) : HasDerivWithinAt (fun x ↦ x^2) (2 * x₀) .univ x₀ := by
  sorry

example (x₀:ℝ) : DifferentiableWithinAt ℝ (fun x ↦ x^2) .univ x₀ := by
  sorry

example (x₀:ℝ) : derivWithin (fun x ↦ x^2) .univ x₀ = 2 * x₀ := by
  sorry

/-- Remark 10.1.4 -/
example (X: Set ℝ) (x₀ : ℝ) {f g: ℝ → ℝ} (hfg: f = g):
  DifferentiableWithinAt ℝ f X x₀ ↔ DifferentiableWithinAt ℝ g X x₀ := by
  sorry

example (X: Set ℝ) (x₀ : ℝ) {f g: ℝ → ℝ} (L:ℝ) (hfg: f = g):
  HasDerivWithinAt f L X x₀ ↔ HasDerivWithinAt g L X x₀ := by
  sorry

example : ∃ (X: Set ℝ) (x₀ :ℝ) (f g: ℝ → ℝ) (L:ℝ) (hfg: f x₀ = g x₀),
  HasDerivWithinAt f L X x₀ ∧ ¬ HasDerivWithinAt g L X x₀ := by
  sorry

/-- Example 10.1.6 -/

abbrev f_10_1_6 : ℝ → ℝ := abs

example : (nhdsWithin 0 (.Ioi 0)).Tendsto (fun x ↦ (f_10_1_6 x - f_10_1_6 0) / (x - 0)) (nhds 1) := by
  sorry

example : (nhdsWithin 0 (.Iio 0)).Tendsto (fun x ↦ (f_10_1_6 x - f_10_1_6 0) / (x - 0)) (nhds (-1)) := by
  sorry

example : ¬ ∃ L, (nhdsWithin 0 (.univ \ {0})).Tendsto (fun x ↦ (f_10_1_6 x - f_10_1_6 0) / (x - 0))
   (nhds L) := by
  sorry

example : ¬ DifferentiableWithinAt ℝ f_10_1_6 (.univ) 0 := by
  sorry

example : DifferentiableWithinAt ℝ f_10_1_6 (.Ioi 0) 0 := by
  sorry

example : derivWithin f_10_1_6 (.Ioi 0) 0 = 1 := by
  sorry

example : DifferentiableWithinAt ℝ f_10_1_6 (.Iio 0) 0 := by
  sorry

example : derivWithin f_10_1_6 (.Iio 0) 0 = -1 := by
  sorry

/-Definition 10.1.11 (Differentiability on a domain)-/
#check DifferentiableOn.eq_1

/-- Theorem 10.1.13 (a) (Differential calculus) / Exercise 10.1.4 -/
theorem _root_.HasDerivWithinAt.of_const (X: Set ℝ) (x₀ : ℝ) (c:ℝ) :
  HasDerivWithinAt (fun x ↦ c) 0 X x₀ := by
  sorry

/-- Theorem 10.1.13 (b) (Differential calculus) / Exercise 10.1.4 -/
theorem _root_.HasDerivWithinAt.of_id (X: Set ℝ) (x₀ : ℝ) :
  HasDerivWithinAt (fun x ↦ x) 1 X x₀ := by
  sorry

/-- Theorem 10.1.13 (c) (Sum rule) / Exercise 10.1.4 -/
theorem _root_.HasDerivWithinAt.of_add {X: Set ℝ} {x₀ f'x₀ g'x₀: ℝ}
  {f g: ℝ → ℝ} (hf: HasDerivWithinAt f f'x₀ X x₀) (hg: HasDerivWithinAt g g'x₀ X x₀) :
  HasDerivWithinAt (f + g) (f'x₀ + g'x₀) X x₀ := by
  sorry

/-- Theorem 10.1.13 (d) (Product rule) / Exercise 10.1.4 -/
theorem _root_.HasDerivWithinAt.of_mul {X: Set ℝ} {x₀ f'x₀ g'x₀: ℝ}
  {f g: ℝ → ℝ} (hf: HasDerivWithinAt f f'x₀ X x₀) (hg: HasDerivWithinAt g g'x₀ X x₀) :
  HasDerivWithinAt (f * g) (f'x₀ * (g x₀) + (f x₀) * g'x₀) X x₀ := by
  sorry

/-- Theorem 10.1.13 (e) (Differential calculus) / Exercise 10.1.4 -/
theorem _root_.HasDerivWithinAt.of_smul {X: Set ℝ} {x₀ f'x₀: ℝ} (c:ℝ)
  {f: ℝ → ℝ} (hf: HasDerivWithinAt f f'x₀ X x₀) :
  HasDerivWithinAt (c • f) (c * f'x₀) X x₀ := by
  sorry

/-- Theorem 10.1.13 (f) (Difference rule) / Exercise 10.1.4 -/
theorem _root_.HasDerivWithinAt.of_sub {X: Set ℝ} {x₀ f'x₀ g'x₀: ℝ}
  {f g: ℝ → ℝ} (hf: HasDerivWithinAt f f'x₀ X x₀) (hg: HasDerivWithinAt g g'x₀ X x₀) :
  HasDerivWithinAt (f - g) (f'x₀ - g'x₀) X x₀ := by
  sorry

/-- Theorem 10.1.13 (g) (Differential calculus) / Exercise 10.1.4 -/
theorem _root_.HasDerivWithinAt.of_inv {X: Set ℝ} {x₀ g'x₀: ℝ}
  {g: ℝ → ℝ} (hgx₀ : g x₀ ≠ 0) (hg: HasDerivWithinAt g g'x₀ X x₀) :
  HasDerivWithinAt (1/g) (-g'x₀ / (g x₀)^2) X x₀ := by
  sorry

/-- Theorem 10.1.13 (h) (Quotient rule) / Exercise 10.1.4 -/
theorem _root_.HasDerivWithinAt.of_div {X: Set ℝ} {x₀ f'x₀ g'x₀: ℝ}
  {f g: ℝ → ℝ} (hgx₀ : g x₀ ≠ 0) (hf: HasDerivWithinAt f f'x₀ X x₀)
  (hg: HasDerivWithinAt g g'x₀ X x₀) :
  HasDerivWithinAt (f / g) ((f'x₀ * (g x₀) - (f x₀) * g'x₀) / (g x₀)^2) X x₀ := by
  sorry

example (x₀:ℝ) (hx₀: x₀ ≠ 1): HasDerivWithinAt (fun x ↦ (x-2)/(x-1)) (1 /(x₀-1)^2) (.univ \ {1}) x₀ := by
  sorry

/-- Exercise 10.1.5 -/
theorem _root_.HasDerivWithinAt.of_pow (n:ℕ) (x₀:ℝ) : HasDerivWithinAt (fun x ↦ x^n)
(n * x₀^((n:ℤ)-1)) .univ x₀ := by
  sorry

/-- Exercise 10.1.6 -/
theorem _root_.HasDerivWithinAt.of_zpow (n:ℤ) (x₀:ℝ) (hx₀: x₀ ≠ 0) :
  HasDerivWithinAt (fun x ↦ x^n) (n * x₀^(n-1)) (.univ \ {0}) x₀ := by
  sorry

end Chapter10
