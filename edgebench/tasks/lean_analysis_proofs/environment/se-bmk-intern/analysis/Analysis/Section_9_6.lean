import Mathlib.Tactic
import Mathlib.Data.Real.Sign
import Analysis.Section_9_3
import Analysis.Section_9_4

/-!
# Analysis I, Section 9.6: The maximum principle

I have attempted to make the translation as faithful a paraphrasing as possible of the original
text.  When there is a choice between a more idiomatic Lean solution and a more faithful
translation, I have generally chosen the latter.  In particular, there will be places where
the Lean code could be "golfed" to be more elegant and idiomatic, but I have consciously avoided
doing so.

Main constructions and results of this section:
- Continuous functions on closed and bounded intervals are bounded.
- Continuous functions on closed and bounded intervals attain their maximum and minimum.
-/

namespace Chapter9

/-- Definition 9.6.1 -/
abbrev BddAboveOn (f:ℝ → ℝ) (X:Set ℝ) : Prop := ∃ M, ∀ x ∈ X, f x ≤ M

abbrev BddBelowOn (f:ℝ → ℝ) (X:Set ℝ) : Prop := ∃ M, ∀ x ∈ X, -M ≤ f x

abbrev BddOn (f:ℝ → ℝ) (X:Set ℝ) : Prop := ∃ M, ∀ x ∈ X, |f x| ≤ M

/-- Remark 9.6.2 -/
theorem BddOn.iff (f:ℝ → ℝ) (X:Set ℝ) : BddOn f X ↔ BddAboveOn f X ∧ BddBelowOn f X := by
  sorry

example : Continuous (fun x:ℝ ↦ x) := by
  sorry

example : ¬ BddOn (fun x:ℝ ↦ x) .univ  := by
  sorry

example : BddOn (fun x:ℝ ↦ x) (.Icc 1 2) := by
  sorry

example : ContinuousOn (fun x:ℝ ↦ 1/x) (.Ioo 0 1) := by
  sorry

example : ¬ BddOn (fun x:ℝ ↦ 1/x) (.Ioo 0 1) := by
  sorry

/-- Lemma 9.6.3 -/
theorem BddOn.of_continuous_on_compact {a b:ℝ} (_h:a < b) {f:ℝ → ℝ} (hf: ContinuousOn f (.Icc a b) ) :
  BddOn f (.Icc a b) := by
  sorry

/- Definition 9.6.5.  Use the Mathlib `IsMaxOn` type. -/
#check isMaxOn_iff
#check isMinOn_iff

/-- Remark 9.6.6 -/
theorem BddAboveOn.isMaxOn {f:ℝ → ℝ} {X:Set ℝ} {x₀:ℝ} (h: IsMaxOn f X x₀): BddAboveOn f X := by
  sorry

theorem BddBelowOn.isMinOn {f:ℝ → ℝ} {X:Set ℝ} {x₀:ℝ} (h: IsMinOn f X x₀): BddBelowOn f X := by
  sorry

/-- Proposition 9.6.7 (Maximum principle) -/
theorem IsMaxOn.of_continuous_on_compact {a b:ℝ} (h:a < b) {f:ℝ → ℝ} (hf: ContinuousOn f (.Icc a b)) :
  ∃ xmax ∈ Set.Icc a b, IsMaxOn f (.Icc a b) xmax := by
  sorry

example : IsMaxOn (fun x ↦ x^2) (.Icc (-2) 2) 2 := by
  sorry

example : IsMaxOn (fun x ↦ x^2) (.Icc (-2) 2) (-2) := by
  sorry

theorem sSup.of_isMaxOn {f:ℝ → ℝ} {X:Set ℝ} {x₀:ℝ} (hx₀: x₀ ∈ X) (h: IsMaxOn f X x₀) :
  sSup (f '' X) = f x₀ := by
  sorry

theorem sInf.of_isMinOn {f:ℝ → ℝ} {X:Set ℝ} {x₀:ℝ} (hx₀: x₀ ∈ X) (h: IsMinOn f X x₀) :
  sInf (f '' X) = f x₀ := by
  sorry

theorem sSup.of_continuous_on_compact {a b:ℝ} (h:a < b) (f:ℝ → ℝ) (hf: ContinuousOn f (.Icc a b)) : ∃ xmax ∈ Set.Icc a b, sSup (f '' .Icc a b) = f xmax := by
  sorry

theorem sInf.of_continuous_on_compact {a b:ℝ} (h:a < b) (f:ℝ → ℝ) (hf: ContinuousOn f (.Icc a b)) : ∃ xmin ∈ Set.Icc a b, sInf (f '' .Icc a b) = f xmin := by
  sorry

/-- Exercise 9.6.1 a) -/
example : ∃ f: ℝ → ℝ, ContinuousOn f (.Ioo 1 2) ∧ BddOn f (.Ioo 1 2) ∧
  ∃ x₀ ∈ Set.Ioo 1 2, IsMinOn f (.Ioo 1 2) x₀ ∧
  ¬ ∃ x₀ ∈ Set.Ioo 1 2, IsMaxOn f (.Ioo 1 2) x₀
  := by
  sorry

/-- Exercise 9.6.1 b) -/
example : ∃ f: ℝ → ℝ, ContinuousOn f (.Ici 0) ∧ BddOn f (.Ici 0) ∧
  ∃ x₀ ∈ Set.Ici 0, IsMaxOn f (.Ici 0) x₀ ∧
  ¬ ∃ x₀ ∈ Set.Ici 0, IsMinOn f (.Ici 0) x₀
  := by
  sorry

/-- Exercise 9.6.1 c) -/
example : ∃ f: ℝ → ℝ, BddOn f (.Icc (-1) 1) ∧
  (¬ ∃ x₀ ∈ Set.Icc (-1) 1, IsMinOn f (.Icc (-1) 1) x₀) ∧
  (¬ ∃ x₀ ∈ Set.Icc (-1) 1, IsMaxOn f (.Icc (-1) 1) x₀)
  := by
  sorry

/-- Exercise 9.6.1 d) -/
example : ∃ f: ℝ → ℝ, ¬ BddAboveOn f (.Icc (-1) 1) ∧ ¬ BddBelowOn f (.Icc (-1) 1) := by
  sorry

/-- Exercise 9.6.2 -/
theorem BddOn.add (f g : ℝ → ℝ) (X : Set ℝ) (hf : BddOn f X) (hg : BddOn g X) :
    BddOn (f + g) X := by
  sorry

theorem BddOn.sub (f g : ℝ → ℝ) (X : Set ℝ) (hf : BddOn f X) (hg : BddOn g X) :
    BddOn (f - g) X := by
  sorry

theorem BddOn.mul (f g : ℝ → ℝ) (X : Set ℝ) (hf : BddOn f X) (hg : BddOn g X) :
    BddOn (f * g) X := by
  sorry

def BddOn.div : Decidable (∀ (f g : ℝ → ℝ) (X : Set ℝ) (_ : ∀ x ∈ X, g x ≠ 0) (_ : BddOn f X)
    (_: BddOn g X), (BddOn (f / g) X)) := by
  -- the first line of this construction should be either `apply isTrue` or `apply isFalse`, depending on whether you believe the given statement to be true or false.
  sorry

end Chapter9
