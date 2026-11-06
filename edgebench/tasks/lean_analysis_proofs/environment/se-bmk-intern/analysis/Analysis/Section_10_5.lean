import Mathlib.Tactic
import Analysis.Section_9_1
import Analysis.Section_10_1
import Analysis.Section_10_2

/-!
# Analysis I, Section 10.5: L'Hôpital's rule

I have attempted to make the translation as faithful a paraphrasing as possible of the original
text.  When there is a choice between a more idiomatic Lean solution and a more faithful
translation, I have generally chosen the latter.  In particular, there will be places where
the Lean code could be "golfed" to be more elegant and idiomatic, but I have consciously avoided
doing so.

Main constructions and results of this section:
- L'Hôpital's rule.

-/

open Chapter9
namespace Chapter10

/-- Proposition 10.5.1 (L'Hôpital's rule, I) / Exercise 10.5.1-/
theorem _root_.Filter.Tendsto.of_div {X: Set ℝ} {f g: ℝ → ℝ} {x₀ f'x₀ g'x₀:ℝ}
  (hfx₀: f x₀ = 0) (hgx₀: g x₀ = 0) (hg_non: g'x₀ ≠ 0)
  (hf'x₀: HasDerivWithinAt f f'x₀ X x₀) (hg'x₀: HasDerivWithinAt g g'x₀ X x₀) :
  (∃ δ > 0, ∀ x ∈ X \ {x₀} ∩ .Ioo (x₀ - δ) (x₀ + δ), g x ≠ 0) ∧
  (nhdsWithin x₀ (X \ {x₀})).Tendsto (fun x ↦ f x / g x) (nhds (f'x₀ / g'x₀))
  := by
  sorry

/-- Proposition 10.5.2 (L'Hôpital's rule, II) -/
theorem _root_.Filter.Tendsto.of_div' {a b L:ℝ} (hab: a < b) {f g f' g': ℝ → ℝ}
  (hf: DifferentiableOn ℝ f (.Icc a b)) (hg: DifferentiableOn ℝ g (.Icc a b))
  (hf': f' = derivWithin f (.Icc a b)) (hg': g' = derivWithin g (.Icc a b))
  (hfa: f a = 0) (hga: g a = 0) (hgnon: ∀ x ∈ Set.Icc a b, g' x ≠ 0)
  (hderiv: (nhdsWithin a (.Icc a b)).Tendsto (fun x ↦ f' x / g' x) (nhds L)) :
  (∀ x ∈ Set.Ioc a b, g x ≠ 0) ∧
  (nhdsWithin a (.Ioc a b)).Tendsto (fun x ↦ f x / g x) (nhds L) := by
  sorry

end Chapter10
