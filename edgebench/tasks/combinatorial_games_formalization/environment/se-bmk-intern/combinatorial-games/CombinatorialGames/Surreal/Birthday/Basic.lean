/-
Copyright (c) 2025 Aaron Liu. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Aaron Liu
-/
module

public import CombinatorialGames.Game.Birthday
public import CombinatorialGames.Surreal.Ordinal

import Mathlib.Algebra.Order.Group.OrderIso

/-!
# Birthday of a surreal number

TODO: write a better docstring
-/

universe u

public noncomputable section

namespace Surreal
open IGame NatOrdinal Order Set

/-- The birthday of a surreal number is defined as the least birthday
among all *numeric* pre-games that define it.

The numeric condition can be removed, see `Surreal.birthday_toGame`. -/
def birthday (x : Surreal.{u}) : NatOrdinal.{u} :=
  sInf (IGame.birthday '' {c | ∃ _ : Numeric c, mk c = x})

theorem birthday_eq_iGameBirthday (x : Surreal) :
    ∃ (y : IGame) (_ : Numeric y), mk y = x ∧ y.birthday = birthday x := by
  sorry

theorem birthday_mk_le (x : IGame) [Numeric x] : birthday (mk x) ≤ x.birthday := by
  sorry

@[simp]
theorem birthday_zero : birthday 0 = 0 := by
  sorry

@[simp]
theorem birthday_eq_zero {x : Surreal} : birthday x = 0 ↔ x = 0 := by
  sorry

private theorem birthday_neg_le (x : Surreal) : (-x).birthday ≤ x.birthday := by
  sorry

@[simp]
theorem birthday_neg (x : Surreal) : (-x).birthday = x.birthday := by
  sorry

theorem le_toSurreal_birthday (x : Surreal) : x ≤ x.birthday.toSurreal := by
  sorry

theorem neg_toSurreal_birthday_le (x : Surreal) : -x.birthday.toSurreal ≤ x := by
  sorry

@[simp]
theorem birthday_toSurreal (o : NatOrdinal) : birthday o.toSurreal = o := by
  sorry

@[simp, norm_cast]
theorem birthday_natCast (n : ℕ) : birthday n = n := by
  sorry

@[simp]
theorem birthday_ofNat (n : ℕ) [n.AtLeastTwo] : birthday ofNat(n) = n := by
  sorry

@[simp]
theorem birthday_one : birthday 1 = 1 := by
  sorry

theorem birthday_ofSets_le {s t : Set Surreal.{u}}
    [Small.{u} s] [Small.{u} t] {H : ∀ x ∈ s, ∀ y ∈ t, x < y} :
    !{s | t}.birthday ≤ max (sSup (succ ∘ birthday '' s)) (sSup (succ ∘ birthday '' t)) := by
  sorry

theorem birthday_add_le (x y : Surreal) : (x + y).birthday ≤ x.birthday + y.birthday := by
  sorry

theorem birthday_sub_le (x y : Surreal) : (x - y).birthday ≤ x.birthday + y.birthday := by
  sorry

/- This is currently an open problem, see https://mathoverflow.net/a/476829/147705. -/
proof_wanted birthday_mul_le (x y : Surreal) : (x * y).birthday ≤ x.birthday * y.birthday

/-- The birthday of a surreal number is at least the birthday of the corresponding game. -/
theorem birthday_toGame_le (x : Surreal) : x.toGame.birthday ≤ x.birthday := by
  sorry

/-- Surreals with a bounded birthday form a small set. -/
instance small_setOf_birthday_le (o : NatOrdinal.{u}) : Small.{u} {x | birthday x ≤ o} := by
  have h₁ : {x | birthday x ≤ o} ⊆ toGame ⁻¹' {x | x.birthday ≤ o} := by
    intro x hx
    exact x.birthday_toGame_le.trans hx
  have h₂ := Set.restrictPreimage_injective {x | x.birthday ≤ o} toGame.injective
  have : Small.{u} (toGame ⁻¹' {x | x.birthday ≤ o}) := small_of_injective h₂
  exact small_subset h₁

/-- Surreals with a bounded birthday form a small set. -/
instance small_setOf_birthday_lt (o : NatOrdinal.{u}) : Small.{u} {x | birthday x < o} := by
  refine small_subset (?_ : {x : Surreal | x.birthday < o} ⊆ {x : Surreal | x.birthday ≤ o})
  simp +contextual [le_of_lt]

/-- A variant of `small_setOf_birthday_le` in simp-normal form -/
instance small_subtype_birthday_le (o : NatOrdinal.{u}) : Small.{u} {x // birthday x ≤ o} :=
  small_setOf_birthday_le o

/-- A variant of `small_setOf_birthday_lt` in simp-normal form -/
instance small_subtype_birthday_lt (o : NatOrdinal.{u}) : Small.{u} {x // birthday x < o} :=
  small_setOf_birthday_lt o

end Surreal
