import Mathlib.Tactic
import Analysis.Section_8_1
import Analysis.Section_8_2

/-!
# Analysis I, Section 8.3: Uncountable sets

I have attempted to make the translation as faithful a paraphrasing as possible of the original
text. When there is a choice between a more idiomatic Lean solution and a more faithful
translation, I have generally chosen the latter. In particular, there will be places where the
Lean code could be "golfed" to be more elegant and idiomatic, but I have consciously avoided
doing so.

Main constructions and results of this section:

- Uncountable sets.

Some non-trivial API is provided beyond what is given in the textbook in order connect these
notions with existing summation notions.

-/

namespace Chapter8

theorem Uncountable.iff (X:Type) : Uncountable X ↔ ¬ AtMostCountable X := by
  sorry

open Real in
/-- Corollary 8.3.4 -/
theorem Uncountable.real : Uncountable ℝ := by
  sorry

/-- Exercise 8.3.1 -/
example {X:Type} [Finite X] : Nat.card (Set X) = 2 ^ Nat.card X := by
  sorry

open Classical in
/-- Exercise 8.3.2.  Some subtle type changes due to how sets are implemented in Mathlib. Also we shift the sequence {lit}`D` by one so that we can work in {lean}`Set A` rather than {lean}`Set B`. -/
theorem Schroder_Bernstein_lemma {X: Type} {A B C: Set X} (hAB: A ⊆ B) (hBC: B ⊆ C) (f: C ↪ A) :
  let D : ℕ → Set A := Nat.rec ((f.image ∘ ((B.embeddingOfSubset _ hBC).image)) {x:B | ↑x ∉ A}) (fun _ ↦ (f.image ∘ ((B.embeddingOfSubset _ hBC).image) ∘ (A.embeddingOfSubset _ hAB).image))
  Set.univ.PairwiseDisjoint D ∧
  let g : A → B := fun x ↦ if h: x ∈ ⋃ n, D n ∧ ∃ y:B, f ⟨↑y, hBC y.property⟩ = x then h.2.choose else ⟨ ↑x, hAB x.property ⟩
  Function.Bijective g
  := by
  sorry

abbrev LeCard (X Y: Type) : Prop := ∃ f: X → Y, Function.Injective f

/-- Exercise 8.3.3 -/
theorem Schroder_Bernstein {X Y:Type} (hXY : LeCard X Y) (hYX : LeCard Y X) : EqualCard X Y := by
  sorry

abbrev LtCard (X Y: Type) : Prop := LeCard X Y ∧ ¬ EqualCard X Y

/-- Exercise 8.3.4 -/
example {X:Type} : LtCard X (Set X) := by
  sorry

example {A B C: Type} (hAB: LtCard A B) (hBC: LtCard B C) :
  LtCard A C := by
  sorry

abbrev CardOrder : Preorder Type := {
  le := LeCard
  lt := LtCard
  le_refl := by
    sorry
  le_trans := by
    sorry
  lt_iff_le_not_ge := by
    sorry
}

/-- Exercise 8.3.5 -/
example (X:Type) : ¬ CountablyInfinite (Set X) := by
  sorry

end Chapter8
