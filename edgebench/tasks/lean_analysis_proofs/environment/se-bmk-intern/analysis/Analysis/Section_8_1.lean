import Mathlib.Tactic

/-!
# Analysis I, Section 8.1: Countability

I have attempted to make the translation as faithful a paraphrasing as possible of the original
text. When there is a choice between a more idiomatic Lean solution and a more faithful
translation, I have generally chosen the latter. In particular, there will be places where the
Lean code could be "golfed" to be more elegant and idiomatic, but I have consciously avoided
doing so.

Main constructions and results of this section:

- Custom notions for "equal cardinality", "countable", and "at most countable".  Note that Mathlib's
`Countable` typeclass corresponds to what we call "at most countable" in this text.
- Countability of the integers and rationals.

Note that as the Chapter 3 set theory has been deprecated, we will not re-use relevant constructions from that theory here, replacing them with Mathlib counterparts instead.

-/

namespace Chapter8

/-- The definition of equal cardinality. For simplicity we restrict attention to the Type 0 universe.
This is analogous to `Chapter3.SetTheory.Set.EqualCard`, but we are not using the latter since
the Chapter 3 set theory is deprecated. -/
abbrev EqualCard (X Y : Type) : Prop := ∃ f : X → Y, Function.Bijective f

/-- Relation with Mathlib's `Equiv` concept -/
theorem EqualCard.iff {X Y : Type} : EqualCard X Y ↔ Nonempty (X ≃ Y) := by
  sorry

/-- Equivalence with Mathlib's `Cardinal.mk` concept -/
theorem EqualCard.iff' {X Y : Type} : EqualCard X Y ↔ Cardinal.mk X = Cardinal.mk Y := by
  sorry

theorem EqualCard.refl (X : Type) : EqualCard X X := by
  sorry

theorem EqualCard.symm {X Y : Type} (hXY : EqualCard X Y) : EqualCard Y X := by
  sorry

theorem EqualCard.trans {X Y Z : Type} (hXY : EqualCard X Y) (hYZ : EqualCard Y Z) :
  EqualCard X Z := by
  sorry

instance EqualCard.instSetoid : Setoid Type := ⟨ EqualCard, ⟨ refl, symm, trans ⟩ ⟩

abbrev CountablyInfinite (X : Type) : Prop := EqualCard X ℕ

abbrev AtMostCountable (X : Type) : Prop := CountablyInfinite X ∨ Finite X

/-- Equivalence with Mathlib's `Countable` typeclass -/
theorem CountablyInfinite.iff' (X : Type) : CountablyInfinite X ↔ Countable X ∧ Infinite X := by
  sorry

theorem CountablyInfinite.toCountable {X : Type} (hX: CountablyInfinite X) : Countable X := by
  sorry

/-- Examples 8.1.3 -/
example : CountablyInfinite ℕ := by
  sorry

example : CountablyInfinite (.univ \ {0}: Set ℕ) := by
  sorry

example : CountablyInfinite ((fun n:ℕ ↦ 2*n) '' .univ) := by
  sorry

/-- Proposition 8.1.4 (Well ordering principle / Exercise 8.1.2 -/
theorem Nat.exists_unique_min {X : Set ℕ} (hX : X.Nonempty) :
  ∃! m ∈ X, ∀ n ∈ X, m ≤ n := by
  sorry

def Int.exists_unique_min : Decidable (∀ (X : Set ℤ) (hX : X.Nonempty), ∃! m ∈ X, ∀ n ∈ X, m ≤ n) := by
  -- the first line of this construction should be either `apply isTrue` or `apply isFalse`.
  sorry

def NNRat.exists_unique_min : Decidable (∀ (X : Set NNRat) (hX : X.Nonempty), ∃! m ∈ X, ∀ n ∈ X, m ≤ n) := by
  -- the first line of this construction should be either `apply isTrue` or `apply isFalse`.
  sorry

open Classical in
noncomputable abbrev Nat.min (X : Set ℕ) : ℕ := if hX : X.Nonempty then (exists_unique_min hX).exists.choose else 0

theorem Nat.min_eq {X : Set ℕ} (hX : X.Nonempty) {a:ℕ} (ha : a ∈ X ∧ ∀ n ∈ X, a ≤ n) : min X = a := by
  sorry

@[simp]
theorem Nat.min_empty : min ∅ = 0 := by
  sorry

example : Nat.min ((fun n ↦ 2*n) '' (.Ici 1)) = 2 := by
  sorry

theorem Nat.min_eq_sInf {X : Set ℕ} (hX : X.Nonempty) : min X = sInf X := by
  sorry

open Classical in
/-- Equivalence with Mathlib's `Nat.find` method -/
theorem Nat.min_eq_find {X : Set ℕ} (hX : X.Nonempty) : min X = Nat.find hX := by
  sorry

theorem Nat.countable_of_infinite (X : Set ℕ) [Infinite X] : CountablyInfinite X := by
  sorry

theorem AtMostCountable.subset' {A: Type} {X Y: Set A} (hX: AtMostCountable X) (hY: Y ⊆ X) : AtMostCountable Y := by
  sorry

/-- Proposition 8.1.8 / Exercise 8.1.4 -/
theorem AtMostCountable.image_nat (Y: Type) (f: ℕ → Y) : AtMostCountable (f '' .univ) := by
  sorry

/-- Lemma 8.1.12 -/
theorem CountablyInfinite.lower_diag : CountablyInfinite { n : ℕ × ℕ | n.2 ≤ n.1 } := by
  sorry

/-- Corollary 8.1.13 -/
theorem CountablyInfinite.prod_nat : CountablyInfinite (ℕ × ℕ) := by
  sorry

/-- Corollary 8.1.15 -/
theorem Rat.countablyInfinite : CountablyInfinite ℚ := by
  sorry

/-- Exercise 8.1.1 -/
example (X: Type) : Infinite X ↔ ∃ Y : Set X, Y ≠ .univ ∧ EqualCard Y X := by
  sorry

/-- Exercise 8.1.6 -/
example (A: Type) : AtMostCountable A ↔ ∃ f : A → ℕ, Function.Injective f := by
  sorry

/-- Exercise 8.1.9 -/
example {I X:Type} (hI: AtMostCountable I) (A: I → Set X) (hA: ∀ i, AtMostCountable (A i)) :
  AtMostCountable (⋃ i, A i) := by
  sorry

/-- Exercise 8.1.10.  Note the lack of the `noncomputable` keyword in the {lit}`abbrev`. -/
abbrev explicit_bijection : ℕ → ℚ := sorry

theorem explicit_bijection_spec : Function.Bijective explicit_bijection := by
  sorry

end Chapter8
