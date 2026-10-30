/-
Copyright (c) 2024 Violeta Hernández Palacios. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Violeta Hernández Palacios
-/
module

public meta import CombinatorialGames.Tactic.Register
public import CombinatorialGames.NatOrdinal.Basic

import CombinatorialGames.Tactic.OrdinalAlias
import Mathlib.Data.Nat.Bitwise

/-!
# Nimbers

The goal of this file is to define the nimbers, constructed as ordinals endowed with new
arithmetical operations. The nim sum `a + b` is recursively defined as the least ordinal not equal
to any `a' + b` or `a + b'` for `a' < a` and `b' < b`. There is also a nim product, defined in the
`CombinatorialGames.Nimber.Field` file.

Nim arithmetic arises within the context of impartial games. By the Sprague-Grundy theorem, each
impartial game is equivalent to some game of nim. If `x ≈ nim o₁` and `y ≈ nim o₂`, then
`x + y ≈ nim (o₁ + o₂)` and `x * y ≈ nim (o₁ * o₂)`, where the ordinals are summed or multiplied
together as nimbers.

## Notation

Following [On Numbers And Games][conway2001] (p. 121), we define notation `∗o` for the cast from
`Ordinal` to `Nimber`. Note that for general `n : ℕ`, `∗n` is **not** the same as `↑n`. For
instance, `∗2 ≠ 0`, whereas `↑2 = ↑1 + ↑1 = 0`.

## Implementation notes

The nimbers inherit the order from the ordinals - this makes working with minimum excluded values
much more convenient. However, the fact that nimbers are of characteristic 2 prevents the order from
interacting with the arithmetic in any nice way.

To reduce API duplication, we opt not to implement operations on `Nimber` on `Ordinal`. The order
isomorphisms `Nimber.of` and `Nimber.val` allow us to cast between them whenever needed.
-/

universe u v

open Function Order

public noncomputable section

/-! ### Basic casts between `Ordinal` and `Nimber` -/

ordinal_alias!
  /-- A type synonym for ordinals with nimber addition and multiplication. -/ Nimber

namespace Nimber

attribute [game_cmp] of_zero of_one
attribute [simp] succ_zero succ_ne_zero

@[inherit_doc] scoped prefix:75 "∗" => of
recommended_spelling "of" for "∗" in [Nimber.«term∗_»]

@[simp] theorem Iio_two : Set.Iio (∗2) = {0, 1} := by
  sorry
theorem lt_two_iff {x : Nimber} : x < ∗2 ↔ x = 0 ∨ x = 1 := by
  sorry

@[simp] theorem succ_one : Order.succ 1 = ∗2 := by
  sorry

theorem not_small_nimber : ¬ Small.{u} Nimber.{u} := by
  sorry

/-! ### Nimber addition -/

variable {a b c : Nimber.{u}}

-- We write the binders like this so that the termination checker works.
private def add (a b : Nimber.{u}) : Nimber.{u} :=
  sInf {x | (∃ a', ∃ (_ : a' < a), Nimber.add a' b = x) ∨
    ∃ b', ∃ (_ : b' < b), Nimber.add a b' = x}ᶜ
termination_by (a, b)

#adaptation_note /-- noncomputable is now needed -/ in
/-- Nimber addition is recursively defined so that `a + b` is the smallest nimber not equal to
`a' + b` or `a + b'` for `a' < a` and `b' < b`. -/
@[no_expose]
noncomputable instance : Add Nimber :=
  ⟨Nimber.add⟩

theorem add_def (a b : Nimber) :
    a + b = sInf {x | (∃ a' < a, a' + b = x) ∨ ∃ b' < b, a + b' = x}ᶜ := by
  sorry

/-- The set in the definition of `Nimber.add` is nonempty. -/
private theorem add_nonempty (a b : Nimber.{u}) :
    {x | (∃ a' < a, a' + b = x) ∨ ∃ b' < b, a + b' = x}ᶜ.Nonempty := by
  sorry

theorem exists_of_lt_add (h : c < a + b) : (∃ a' < a, a' + b = c) ∨ ∃ b' < b, a + b' = c := by
  sorry

theorem add_le_of_forall_ne (h₁ : ∀ a' < a, a' + b ≠ c) (h₂ : ∀ b' < b, a + b' ≠ c) :
    a + b ≤ c := by
  sorry

private theorem add_ne_of_lt (a b : Nimber) :
    (∀ a' < a, a' + b ≠ a + b) ∧ ∀ b' < b, a + b' ≠ a + b := by
  sorry

/-- A version of `add_le_nadd` stated in terms of `Ordinal`. -/
theorem add_le_nadd' (a b : Ordinal) : (∗a + ∗b).val ≤ (NatOrdinal.of a + NatOrdinal.of b).val := by
  sorry

theorem add_le_nadd (a b : Nimber) : a + b ≤ ∗(NatOrdinal.of a.val + NatOrdinal.of b.val).val := by
  sorry

protected theorem add_comm (a b : Nimber) : a + b = b + a := by
  sorry

instance : IsLeftCancelAdd Nimber where
  add_left_cancel a b c h := by
    apply le_antisymm <;>
    apply le_of_not_gt
    · exact fun hc ↦ (add_ne_of_lt a b).2 c hc h.symm
    · exact fun hb ↦ (add_ne_of_lt a c).2 b hb h

instance : IsRightCancelAdd Nimber where
  add_right_cancel a b c h := by
    simp_rw [Nimber.add_comm] at h
    exact add_left_cancel h

theorem add_eq_zero {a b : Nimber} : a + b = 0 ↔ a = b := by
  sorry

theorem add_ne_zero_iff : a + b ≠ 0 ↔ a ≠ b := by
  sorry

@[simp]
theorem add_self (a : Nimber) : a + a = 0 := by
  sorry

protected theorem add_assoc (a b c : Nimber) : a + b + c = a + (b + c) := by
  sorry

protected theorem add_zero (a : Nimber) : a + 0 = a := by
  sorry

protected theorem zero_add (a : Nimber) : 0 + a = a := by
  sorry

instance : Neg Nimber :=
  ⟨id⟩

@[simp]
protected theorem neg_eq (a : Nimber) : -a = a := by
  sorry

instance : AddCommGroupWithOne Nimber where
  add_assoc := Nimber.add_assoc
  add_zero := Nimber.add_zero
  zero_add := Nimber.zero_add
  nsmul := nsmulRec
  zsmul := zsmulRec
  neg_add_cancel := add_self
  add_comm := Nimber.add_comm

@[simp]
theorem add_cancel_right (a b : Nimber) : a + b + b = a := by
  sorry

@[simp]
theorem add_cancel_left (a b : Nimber) : a + (a + b) = b := by
  sorry

theorem add_trichotomy {a b c : Nimber} (h : a + b + c ≠ 0) :
    b + c < a ∨ c + a < b ∨ a + b < c := by
  sorry

theorem lt_add_cases {a b c : Nimber} (h : a < b + c) : a + c < b ∨ a + b < c := by
  sorry

/-- Nimber addition of naturals corresponds to the bitwise XOR operation. -/
theorem add_nat (a b : ℕ) : ∗a + ∗b = ∗(a ^^^ b) := by
  sorry

end Nimber
