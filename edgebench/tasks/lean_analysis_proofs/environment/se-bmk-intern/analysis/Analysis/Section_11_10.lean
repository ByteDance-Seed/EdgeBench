import Mathlib.Tactic
import Analysis.Section_9_6
import Analysis.Section_10_3
import Analysis.Section_11_9

/-!
# Analysis I, Section 11.10: Consequences of the fundamental theorems

I have attempted to make the translation as faithful a paraphrasing as possible of the
original text. When there is a choice between a more idiomatic Lean solution and a
more faithful translation, I have generally chosen the latter. In particular, there will
be places where the Lean code could be "golfed" to be more elegant and idiomatic, but I
have consciously avoided doing so.

Main constructions and results of this section:
- Integration by parts

-/

namespace Chapter11

open BoundedInterval Chapter9 Chapter10

/-- Proposition 11.10.1 (Integration by parts formula) / Exercise 11.10.1 -/
theorem integ_of_mul_deriv {a b:ℝ} (hab: a ≤ b) {F G: ℝ → ℝ}
  (hF: DifferentiableOn ℝ F (Icc a b)) (hG : DifferentiableOn ℝ G (Icc a b))
  (hF': IntegrableOn (derivWithin F (Icc a b)) (Icc a b))
  (hG': IntegrableOn (derivWithin G (Icc a b)) (Icc a b)) :
  integ (F * derivWithin G (Icc a b)) (Icc a b) = F b * G b - F a * G a -
    integ (G * derivWithin F (Icc a b)) (Icc a b) := by
  sorry

/-- Theorem 11.10.2.  Need to add continuity of α due to our conventions on `α_length` -/
theorem PiecewiseConstantOn.RS_integ_eq_integ_of_mul_deriv
  {a b:ℝ} {α f:ℝ → ℝ}
  (hα_diff: DifferentiableOn ℝ α (Icc a b)) (hαcont: Continuous α)
  (hα': IntegrableOn (derivWithin α (Icc a b)) (Icc a b))
  (hf: PiecewiseConstantOn f (Icc a b)) :
  IntegrableOn (f * derivWithin α (Icc a b)) (Icc a b) ∧
  Chapter11.integ (f * derivWithin α (Icc a b)) (Icc a b) = RS_integ f (Icc a b) α := by
  sorry

/-- Corollary 11.10.3 -/
theorem RS_integ_eq_integ_of_mul_deriv
  {a b:ℝ} (hab: a < b) {α f:ℝ → ℝ} (hα: Monotone α)
  (hα_diff: DifferentiableOn ℝ α (Icc a b)) (hαcont: Continuous α)
  (hα': IntegrableOn (derivWithin α (Icc a b)) (Icc a b))
  (hf: RS_IntegrableOn f (Icc a b) α) :
  IntegrableOn (f * derivWithin α (Icc a b)) (Icc a b) ∧
  integ (f * derivWithin α (Icc a b)) (Icc a b) = RS_integ f (Icc a b) α := by
  sorry

/-- Proposition 11.10.6 (Change of variables formula II)-/
theorem RS_integ_of_comp {a b:ℝ} (hab: a < b) {φ f: ℝ → ℝ}
  (hφ_cont: Continuous φ) (hφ_mono: Monotone φ) (hf: IntegrableOn f (Icc (φ a) (φ b))) :
  RS_IntegrableOn (f ∘ φ) (Icc a b) φ ∧
  RS_integ (f ∘ φ) (Icc a b) φ = integ f (Icc (φ a) (φ b)) := by
  sorry

/-- Proposition 11.10.7 (Change of variables formula III)-/
theorem integ_of_comp {a b:ℝ} (hab: a < b) {φ f: ℝ → ℝ}
  (hφ_diff: DifferentiableOn ℝ φ (Icc a b))
  (hφ_cont: Continuous φ) (hφ_mono: Monotone φ)
  (hφ': IntegrableOn (derivWithin φ (Icc a b)) (Icc a b))
  (hf: IntegrableOn f (Icc (φ a) (φ b))) :
  IntegrableOn (f ∘ φ * derivWithin φ (Icc a b)) (Icc a b) ∧
  integ (f ∘ φ * derivWithin φ (Icc a b)) (Icc a b) =
    integ f (Icc (φ a) (φ b)) := by
  sorry

/-- Exercise 11.10.3-/
example {a b:ℝ} (hab: a < b) {f: ℝ → ℝ} (hf: IntegrableOn f (Icc a b)) :
  IntegrableOn (fun x ↦ f (-x)) (Icc (-b) (-a)) ∧
  integ (fun x ↦ f (-x)) (Icc (-b) (-a)) = -integ f (Icc a b) := by
  sorry

/- Exercise 11.10.4: state and prove a version of `integ_of_comp` in which `φ` is `Antitone` rather than `Monotone`. -/

end Chapter11
