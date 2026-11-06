/-
Copyright (c) 2025 Violeta Hernández Palacios. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Violeta Hernández Palacios
-/
module

public import CombinatorialGames.NatOrdinal.Basic
public import Mathlib.SetTheory.Ordinal.Exponential

/-!
# Natural operations on `ω ^ x`

This file characterizes natural operations on powers of `ω`. In particular, we show:

- If `y < ω^ x`, then `ω^ x * n + y = of (ω ^ x.val * n + y.val)`.
- `ω^ (x + y) = ω^ x * ω^ y`.

These two results imply the validity of an algorithm to evaluate natural addition and
multiplication: write down the base `ω` Cantor Normal Forms of both ordinals, and add/multiply them
as polynomials.

## Implementation notes

Surreal exponentiation is not closed on the ordinals. Because of this, we opt against defining a
`Pow` instance on `NatOrdinal`. Instead, we implement our own custom typeclass `Wpow`, giving us
notation `ω^ x` for `of (ω ^ x.val)`. This typeclass will get reused for `IGame` and `Surreal` in
`CombinatorialGames.Surreal.Pow`.
-/

@[expose] public section

open Ordinal

theorem Ordinal.lt_mul_add_one {x y z : Ordinal} : x < y * (z + 1) ↔ ∃ w < y, x ≤ y * z + w := by
  sorry

/-- A typeclass for the the `ω^` notation. -/
class Wpow (α : Type*) where
  /-- The `ω`-map, i.e. base `ω` exponentiation. -/
  wpow : α → α

@[inherit_doc] prefix:75 "ω^ " => Wpow.wpow
recommended_spelling "wpow" for "ω^" in [«termω^_»]

namespace NatOrdinal
variable {x y z : NatOrdinal}

noncomputable instance : Wpow NatOrdinal where
  wpow x := of (ω ^ x.val)

theorem wpow_def (x : NatOrdinal) : ω^ x = of (ω ^ x.val) := by
  sorry
@[simp] theorem of_omega0_opow (x : Ordinal) : of (ω ^ x) = ω^ of x := by
  sorry
@[simp] theorem val_wpow (x : NatOrdinal) : (ω^ x).val = ω ^ x.val := by
  sorry

@[simp] theorem wpow_zero : ω^ (0 : NatOrdinal) = 1 := by
  sorry
@[simp] theorem wpow_pos (x : NatOrdinal) : 0 < ω^ x := by
  sorry
@[simp] theorem wpow_ne_zero (x : NatOrdinal) : ω^ x ≠ 0 := by
  sorry

theorem isNormal_wpow : Order.IsNormal (ω^ · : NatOrdinal → NatOrdinal) := by
  sorry

@[simp] theorem wpow_lt_wpow : ω^ x < ω^ y ↔ x < y := by
  sorry
@[simp] theorem wpow_le_wpow : ω^ x ≤ ω^ y ↔ x ≤ y := by
  sorry
@[simp] theorem wpow_inj : ω^ x = ω^ y ↔ x = y := by
  sorry

private theorem wpow_mul_natCast_add_of_lt_aux {x y : NatOrdinal} (hy : y < ω^ x) (n : ℕ) :
    (∀ z < ω^ x, z + y < ω^ x) ∧ ω^ x * n + y = of (ω ^ x.val * n + y.val) := by
  sorry

theorem add_lt_wpow (hx : x < ω^ z) (hy : y < ω^ z) : x + y < ω^ z := by
  sorry

/-- See `wpow_mul_natCast_add_of_lt` for a stronger version. -/
theorem wpow_mul_natCast_add_of_lt' (hy : y < ω^ x) (n : ℕ) :
    ω^ x * n + y = of (ω ^ x.val * n + y.val) := by
  sorry

/-- See `wpow_add_of_lt` for a stronger version. -/
theorem wpow_add_of_lt' (hy : y < ω^ x) : ω^ x + y = of (ω ^ x.val + y.val) := by
  sorry

theorem wpow_mul_natCast (x : NatOrdinal) (n : ℕ) : ω^ x * n = of (ω ^ x.val * n) := by
  sorry

theorem wpow_mul_natCast_lt (h : x < y) (n : ℕ) : ω^ x * n < ω^ y := by
  sorry

theorem lt_wpow_iff (hx : x ≠ 0) : y < ω^ x ↔ ∃ z < x, ∃ n : ℕ, y < ω^ z * n := by
  sorry

theorem wpow_le_iff (hx : x ≠ 0) : ω^ x ≤ y ↔ ∀ z < x, ∀ n : ℕ, ω^ z * n ≤ y := by
  sorry

theorem lt_wpow_add_one_iff : y < ω^ (x + 1) ↔ ∃ n : ℕ, y < ω^ x * n := by
  sorry

theorem wpow_add_one_le_iff : ω^ (x + 1) ≤ y ↔ ∀ n : ℕ, ω^ x * n ≤ y := by
  sorry

theorem wpow_mul_natCast_add_of_lt (hy : y < ω^ (x + 1)) (n : ℕ) :
    ω^ x * n + y = of (ω ^ x.val * n + y.val) := by
  sorry

theorem wpow_add_of_lt (hy : y < ω^ (x + 1)) : ω^ x + y = of (ω ^ x.val + y.val) := by
  sorry

theorem wpow_add_wpow (h : x ≤ y) : ω^ y + ω^ x = of (ω ^ y.val + ω ^ x.val) := by
  sorry

theorem wpow_add (x y : NatOrdinal) : ω^ (x + y) = ω^ x * ω^ y := by
  sorry

end NatOrdinal
end
