import Mathlib.Tactic
import Mathlib.Data.Real.Sign
import Analysis.Section_9_1

set_option doc.verso.suggestions false

/-!
# Analysis I, Section 9.3: Limiting values of functions

I have attempted to make the translation as faithful a paraphrasing as possible of the original
text.  When there is a choice between a more idiomatic Lean solution and a more faithful
translation, I have generally chosen the latter.  In particular, there will be places where
the Lean code could be "golfed" to be more elegant and idiomatic, but I have consciously avoided
doing so.

Main constructions and results of this section:

- Limits of continuous functions
- Connection with Mathilb's filter convergence concepts
- Limit laws for functions

Technical point: in the text, the functions `f` studied are defined only on subsets `X` of {lean}`ℝ`, and
left undefined elsewhere.  However, in Lean, this then creates some fiddly conversions when trying
to restrict `f` to various subsets of `X` (which, technically, are not precisely subsets of {lean}`ℝ`,
though they can be coerced to such).  To avoid this issue we will deviate from the text by having
our functions defined on all of {lean}`ℝ` (with the understanding that they are assigned "junk" values
outside of the domain `X` of interest).
-/

/-- Definition 9.3.1
Note the books uses ≤ instead of <, but < matches mathlib's definition of neighborhood.
-/
abbrev Real.CloseFn (ε:ℝ) (X:Set ℝ) (f: ℝ → ℝ) (L:ℝ) : Prop :=
  ∀ x ∈ X, |f x - L| < ε

/-- Definition 9.3.3 -/
abbrev Real.CloseNear (ε:ℝ) (X:Set ℝ) (f: ℝ → ℝ) (L:ℝ) (x₀:ℝ) : Prop :=
  ∃ δ > 0, ε.CloseFn (X ∩ .Ioo (x₀-δ) (x₀+δ)) f L

namespace Chapter9

/-- Example 9.3.2
Slight change from the book to accomodate the change to {lean}`Real.CloseFn`
-/
example : (5.1:ℝ).CloseFn (.Icc 1 3) (fun x ↦ x^2) 4 := by
  sorry

/-- Example 9.3.2
Slight change from the book to accomodate the change to {lean}`Real.CloseFn`
-/
example : (0.42:ℝ).CloseFn (.Icc 1.9 2.1) (fun x ↦ x^2) 4 := by
  sorry

/-- Example 9.3.4 -/
example: ¬(0.1:ℝ).CloseFn (.Icc 1 3) (fun x ↦ x^2) 4 := by
  sorry

/-- Example 9.3.4 -/
example: (0.1:ℝ).CloseNear (.Icc 1 3) (fun x ↦ x^2) 4 2 := by
  sorry

/-- Example 9.3.5 -/
example: ¬(0.1:ℝ).CloseFn (.Icc 1 3) (fun x ↦ x^2) 9 := by
  sorry

/-- Example 9.3.5 -/
example: (0.1:ℝ).CloseNear (.Icc 1 3) (fun x ↦ x^2) 9 3 := by
  sorry

/-- Definition 9.3.6 (Convergence of functions at a point)-/
abbrev Convergesto (X:Set ℝ) (f: ℝ → ℝ) (L:ℝ) (x₀:ℝ) : Prop := ∀ ε > (0:ℝ), ε.CloseNear X f L x₀

/-- Example 9.3.8 -/
example: Convergesto (.Icc 1 3) (fun x ↦ x^2) 4 2 := by
  sorry

-- Remark 9.3.11 is not quite true in Lean: the hypothesis `AdherentPt x₀ E` is safely removed
-- from most theorems (with the exception of Convergesto.uniq).

/-- Corollary 9.3.13 -/
theorem Convergesto.uniq {E:Set ℝ} {f: ℝ → ℝ} {L L':ℝ} {x₀:ℝ} (h: AdherentPt x₀ E)
  (hf: Convergesto E f L x₀) (hf': Convergesto E f L' x₀) : L = L' := by
  sorry

/-- Proposition 9.3.14 (Limit laws for functions) / Exercise 9.3.2 -/
theorem Convergesto.smul {E:Set ℝ} {f: ℝ → ℝ} {L:ℝ} {x₀:ℝ}
  (hf: Convergesto E f L x₀) (c:ℝ) :
  Convergesto E (c • f) (c * L) x₀ := by
  sorry

theorem Convergesto.const (E:Set ℝ) (x₀:ℝ) (c:ℝ)
  : Convergesto E (fun _ ↦ c) c x₀ := by
  sorry

theorem Convergesto.id (E:Set ℝ) (x₀:ℝ)
  : Convergesto E (fun x ↦ x) x₀ x₀ := by
  sorry

theorem Convergesto.sq (E:Set ℝ) (x₀:ℝ)
  : Convergesto E (fun x ↦ x^2) (x₀^2) x₀ := by
  sorry

theorem Convergesto.linear (E:Set ℝ) (x₀:ℝ) (c:ℝ)
  : Convergesto E (fun x ↦ c * x) (c * x₀) x₀ := by
  sorry

theorem Convergesto.quadratic (E:Set ℝ) (x₀:ℝ) (c d:ℝ)
  : Convergesto E (fun x ↦ x^2 + c * x + d) (x₀^2 + c * x₀ + d) x₀ := by
  sorry

theorem Convergesto.restrict {X Y:Set ℝ} {f: ℝ → ℝ} {L:ℝ} {x₀:ℝ} (hf: Convergesto X f L x₀) (hY: Y ⊆ X) : Convergesto Y f L x₀ := by
  sorry

theorem Real.sign_def (x:ℝ) : Real.sign x = if x < 0 then -1 else if x > 0 then 1 else 0 := by
  sorry

/-- Example 9.3.16 -/
theorem Convergesto.sign_right : Convergesto (.Ioi 0) Real.sign 1 0 := by
  sorry

/-- Example 9.3.16 -/
theorem Convergesto.sign_left : Convergesto (.Iio 0) Real.sign (-1) 0 := by
  sorry

/-- Example 9.3.16 -/
theorem Convergesto.sign_all : ¬ ∃ L, Convergesto (.univ) Real.sign L 0 := by
  sorry

noncomputable abbrev f_9_3_17 : ℝ → ℝ := fun x ↦ if x = 0 then 1 else 0

theorem Convergesto.f_9_3_17_remove : Convergesto (.univ \ {0}) f_9_3_17 0 0 := by
  sorry

theorem Convergesto.f_9_3_17_all : ¬ ∃ L, Convergesto .univ f_9_3_17 L 0 := by
  sorry

/-- Proposition 9.3.18 / Exercise 9.3.3 -/
theorem Convergesto.local {E:Set ℝ} {f: ℝ → ℝ} {L:ℝ} {x₀:ℝ} {δ:ℝ} (hδ: δ > 0) :
  Convergesto E f L x₀ ↔ Convergesto (E ∩ .Ioo (x₀-δ) (x₀+δ)) f L x₀ := by
  sorry

/-- Example 9.3.19.  The point of this example is somewhat blunted by the ability to remove the hypothesis that {lit}`g` is non-zero from the relevant part of Proposition 9.3.14 -/
example : Convergesto .univ (fun x ↦ (x+2)/(x+1)) (4/3:ℝ) 2 := by
  sorry

/-- Example 9.3.20 -/
example : Convergesto (.univ \ {1}) (fun x ↦ (x^2-1)/(x-1)) 2 1 := by
  sorry

open Classical in
/-- Example 9.3.21 -/
noncomputable abbrev f_9_3_21 : ℝ → ℝ := fun x ↦ if x ∈ (fun q:ℚ ↦ (q:ℝ)) '' .univ then 1 else 0

example : Filter.atTop.Tendsto (fun n ↦ f_9_3_21 (1/n:ℝ)) (nhds 1) := by
  sorry

example : Filter.atTop.Tendsto (fun n ↦ f_9_3_21 ((Real.sqrt 2)/n:ℝ)) (nhds 0) := by
  sorry

example : ¬ ∃ L, Convergesto .univ f_9_3_21 L 0 := by
  sorry

/- Exercise 9.3.4: State a definition of limit superior and limit inferior for functions, and prove an analogue of Proposition 9.3.9 for those definitions. -/

/-- Exercise 9.3.5 (Continuous version of squeeze test) -/
theorem Convergesto.squeeze {E:Set ℝ} {f g h: ℝ → ℝ} {L:ℝ} {x₀:ℝ}
  (hfg: ∀ x ∈ E, f x ≤ g x) (hgh: ∀ x ∈ E, g x ≤ h x)
  (hf: Convergesto E f L x₀) (hh: Convergesto E h L x₀) :
  Convergesto E g L x₀ := by
  sorry

end Chapter9
