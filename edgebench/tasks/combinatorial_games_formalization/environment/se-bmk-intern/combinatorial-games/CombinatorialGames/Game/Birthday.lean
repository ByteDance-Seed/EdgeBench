/-
Copyright (c) 2022 Violeta Hernández Palacios. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Violeta Hernández Palacios
-/
module

public import CombinatorialGames.Game.Ordinal
public import CombinatorialGames.Game.Special

import Mathlib.Algebra.Order.Group.OrderIso
import Mathlib.Data.Fintype.Order
import Mathlib.Data.Set.Finite.Lattice

/-!
# Birthdays of games

There are two related but distinct notions of a birthday within combinatorial game theory. One is
the birthday of an `IGame`, which represents the "step" at which it is constructed. We define it
recursively as the least ordinal larger than the birthdays of its left and right options. On the
other hand, the birthday of a `Game` is the smallest birthday among all `IGame`s that quotient to
it.

The birthday of an `IGame` can be understood as representing the depth of its game tree. Meanwhile,
the birthday of a `Game` more closely matches Conway's original description. The lemma
`Game.birthday_eq_iGameBirthday` links both definitions together.
-/

universe u

open NatOrdinal Order Set

/-! ### Stuff for Mathlib -/

theorem ciSup_eq_bot {α : Type*} {ι : Sort*} [ConditionallyCompleteLinearOrderBot α] {f : ι → α}
    (hf : BddAbove (range f)) : ⨆ i, f i = ⊥ ↔ ∀ i, f i = ⊥ := by
  sorry

/-! ### `IGame` birthday -/

public noncomputable section

namespace IGame

/-- The birthday of an `IGame` is inductively defined as the least strict upper bound of the
birthdays of its options. It may be thought as the "step" in which a certain game is constructed. -/
def birthday (x : IGame.{u}) : NatOrdinal.{u} :=
  ⨆ p, ⨆ y : x.moves p, succ (birthday y)
termination_by x
decreasing_by igame_wf

theorem lt_birthday_iff {x : IGame} {o : NatOrdinal} : o < x.birthday ↔
    ∃ p y, y ∈ x.moves p ∧ o ≤ y.birthday := by
  sorry

theorem birthday_le_iff {x : IGame} {o : NatOrdinal} : x.birthday ≤ o ↔
    ∀ p, ∀ y ∈ x.moves p, y.birthday < o := by
  sorry

theorem birthday_eq_max (x : IGame) : birthday x =
    max (⨆ y : xᴸ, succ y.1.birthday) (⨆ y : xᴿ, succ y.1.birthday) := by
  sorry

@[aesop apply unsafe]
theorem birthday_lt_of_mem_moves {p : Player} {x y : IGame} (hy : y ∈ x.moves p) :
    y.birthday < x.birthday := by
  sorry

theorem birthday_lt_of_subposition {x y : IGame} (hy : Subposition y x) :
    y.birthday < x.birthday := by
  sorry

theorem birthday_ofSets (s t : Set IGame.{u}) [Small.{u} s] [Small.{u} t] :
    birthday !{s | t} = max (sSup (succ ∘ birthday '' s)) (sSup (succ ∘ birthday '' t)) := by
  sorry

theorem birthday_ofSets_const (s : Set IGame.{u}) [Small.{u} s] :
    birthday !{fun _ ↦ s} = sSup (succ ∘ birthday '' s) := by
  sorry

@[simp]
theorem birthday_eq_zero {x : IGame} : birthday x = 0 ↔ x = 0 := by
  sorry

@[simp] theorem birthday_zero : birthday 0 = 0 := by
  sorry
@[simp] theorem birthday_one : birthday 1 = 1 := by
  sorry
@[simp] theorem birthday_star : birthday ⋆ = 1 := by
  sorry

@[simp]
theorem birthday_half : birthday ½ = 2 := by
  sorry

@[simp]
theorem birthday_up : birthday ↑ = 2 := by
  sorry

@[simp]
theorem birthday_down : birthday ↓ = 2 := by
  sorry

@[simp]
theorem birthday_neg (x : IGame) : (-x).birthday = x.birthday := by
  sorry

@[simp]
theorem birthday_toIGame (o : NatOrdinal) : o.toIGame.birthday = o := by
  sorry

theorem le_toIGame_birthday (x : IGame) : x ≤ x.birthday.toIGame := by
  sorry

theorem neg_toIGame_birthday_le (x : IGame) : -x.birthday.toIGame ≤ x := by
  sorry

/-- A game without right options is equivalent to an ordinal. -/
theorem equiv_ordinal_of_right_eq_empty {x : IGame} (hx : xᴿ = ∅) :
    ∃ o : NatOrdinal, x ≈ o := by
  sorry

/-- A game without left options is equivalent to the negative of an ordinal. -/
theorem equiv_neg_ordinal_of_left_eq_empty {x : IGame} (hx : xᴸ = ∅) :
    ∃ o : NatOrdinal, x ≈ -o := by
  sorry

@[simp]
theorem birthday_add (x y : IGame) : (x + y).birthday = x.birthday + y.birthday := by
  sorry

@[simp]
theorem birthday_sub (x y : IGame) : (x - y).birthday = x.birthday + y.birthday := by
  sorry

@[simp, norm_cast]
theorem birthday_natCast : ∀ n : ℕ, birthday n = n
  := by
  sorry

@[simp]
theorem birthday_ofNat (n : ℕ) [n.AtLeastTwo] : birthday ofNat(n) = n := by
  sorry

@[simp]
theorem birthday_tiny (x : IGame) : (⧾x).birthday = x.birthday + 2 := by
  sorry

@[simp]
theorem birthday_miny (x : IGame) : (⧿x).birthday = x.birthday + 2 := by
  sorry

/-- Games with a bounded birthday form a small set. -/
instance small_setOf_birthday_lt (o : NatOrdinal.{u}) : Small.{u} {x | birthday x < o} := by
  induction o using SuccOrder.prelimitRecOn with
  | succ o _ ih =>
    apply small_subset
      (s := range fun s : Set {x | birthday x < o} × Set {x | birthday x < o} ↦
        (!{s.1 | ↑s.2} : IGame))
    refine fun x hx ↦ ⟨((↑) ⁻¹' xᴸ, (↑) ⁻¹' xᴿ), ?_⟩
    simp_rw [lt_succ_iff, birthday_le_iff] at hx
    ext p; cases p <;> simp_all
  | isSuccPrelimit o ho ih =>
    convert @small_biUnion _ _ (Iio o) _ (fun i _ => {x : IGame.{u} | x.birthday < i}) ih
    ext x
    simpa using ho.lt_iff_exists_lt

/-- Games with a bounded birthday form a small set. -/
instance small_setOf_birthday_le (o : NatOrdinal.{u}) : Small.{u} {x | birthday x ≤ o} := by
  convert small_setOf_birthday_lt (succ o) using 1
  simp

/-- A variant of `small_setOf_birthday_le` in simp-normal form -/
instance small_subtype_birthday_le (o : NatOrdinal.{u}) : Small.{u} {x // birthday x ≤ o} :=
  small_setOf_birthday_le o

/-- A variant of `small_setOf_birthday_lt` in simp-normal form -/
instance small_subtype_birthday_lt (o : NatOrdinal.{u}) : Small.{u} {x // birthday x < o} :=
  small_setOf_birthday_lt o

/-! #### Short games -/

/-- The finset of all games with birthday ≤ n. -/
noncomputable def birthdayFinset : ℕ → Finset IGame.{u}
  | 0 => {0}
  | n + 1 => ((birthdayFinset n).powerset ×ˢ (birthdayFinset n).powerset).map
    ⟨fun a => !{a.1 | a.2}, fun a b hab => by aesop⟩

theorem mem_birthdayFinset_succ {x : IGame} {n : ℕ} : x ∈ birthdayFinset (n + 1) ↔
    ∃ l r, (l ⊆ birthdayFinset n ∧ r ⊆ birthdayFinset n) ∧ !{l | r} = x := by
  sorry

@[simp] theorem birthdayFinset_zero : birthdayFinset 0 = {0} := by
  sorry

theorem birthdayFinset_one :
    birthdayFinset 1 = ⟨[0, 1, -1, ⋆], by aesop (add simp [IGame.ext_iff])⟩ := by
  sorry

@[simp]
theorem card_birthdayFinset (n : ℕ) :
    (birthdayFinset.{u} (n + 1)).card = 4 ^ (birthdayFinset.{u} n).card := by
  sorry

theorem mem_birthdayFinset_of_mem_moves {p : Player} {x y : IGame}
    {n : ℕ} (hnx : x ∈ birthdayFinset (n + 1)) (hy : y ∈ x.moves p) : y ∈ birthdayFinset n := by
  sorry

@[simp]
theorem mem_birthdayFinset {x : IGame} {n : ℕ} : x ∈ birthdayFinset n ↔ x.birthday ≤ n := by
  sorry

theorem strictMono_birthdayFinset : StrictMono birthdayFinset := by
  sorry

theorem short_iff_birthday_finite {x : IGame} : x.Short ↔ x.birthday < of .omega0 := by
  sorry

theorem Short.birthday_lt_omega0 (x : IGame) [Short x] : birthday x < of .omega0 := by
  sorry

end IGame

/-! ### `Game` birthday -/

namespace Game

/-- The birthday of a game is defined as the least birthday among all pre-games that define it. -/
noncomputable def birthday (x : Game.{u}) : NatOrdinal.{u} :=
  sInf (IGame.birthday '' (mk ⁻¹' {x}))

theorem birthday_eq_iGameBirthday (x : Game) :
    ∃ y : IGame, Game.mk y = x ∧ y.birthday = birthday x := by
  sorry

theorem birthday_mk_le (x : IGame) : birthday (mk x) ≤ x.birthday := by
  sorry

theorem le_birthday_iff {x : Game} {o : NatOrdinal} :
    o ≤ x.birthday ↔ ∀ y, mk y = x → o ≤ y.birthday := by
  sorry

@[simp]
theorem birthday_zero : birthday 0 = 0 := by
  sorry

@[simp]
theorem birthday_eq_zero {x : Game} : birthday x = 0 ↔ x = 0 := by
  sorry

private theorem birthday_neg_le (x : Game) : (-x).birthday ≤ x.birthday := by
  sorry

@[simp]
theorem birthday_neg (x : Game) : (-x).birthday = x.birthday := by
  sorry

theorem le_toGame_birthday (x : Game) : x ≤ x.birthday.toGame := by
  sorry

theorem neg_toGame_birthday_le (x : Game) : -x.birthday.toGame ≤ x := by
  sorry

@[simp]
theorem birthday_toGame (o : NatOrdinal) : birthday o.toGame = o := by
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

@[simp]
theorem birthday_star : birthday (Game.mk ⋆) = 1 := by
  sorry

theorem birthday_ofSets_le {s t : Set Game.{u}} [Small.{u} s] [Small.{u} t] :
    birthday !{s | t} ≤ max (sSup (succ ∘ birthday '' s)) (sSup (succ ∘ birthday '' t)) := by
  sorry

theorem birthday_add_le (x y : Game) : (x + y).birthday ≤ x.birthday + y.birthday := by
  sorry

theorem birthday_sub_le (x y : Game) : (x - y).birthday ≤ x.birthday + y.birthday := by
  sorry

/-- Games with a bounded birthday form a small set. -/
instance small_setOf_birthday_le (o : NatOrdinal.{u}) : Small.{u} {x | birthday x ≤ o} := by
  refine small_subset (s := mk '' {x | IGame.birthday x ≤ o}) fun x hx ↦ ?_
  obtain ⟨y, rfl, hy⟩ := birthday_eq_iGameBirthday x
  exact mem_image_of_mem mk (hy.trans_le hx)

/-- Games with a bounded birthday form a small set. -/
instance small_setOf_birthday_lt (o : NatOrdinal.{u}) : Small.{u} {x | birthday x < o} :=
  small_subset (s := {x | birthday x ≤ o}) <| setOf_subset_setOf.2 fun _ => le_of_lt

/-- A variant of `small_setOf_birthday_le` in simp-normal form -/
instance small_subtype_birthday_le (o : NatOrdinal.{u}) : Small.{u} {x // birthday x ≤ o} :=
  small_setOf_birthday_le o

/-- A variant of `small_setOf_birthday_lt` in simp-normal form -/
instance small_subtype_birthday_lt (o : NatOrdinal.{u}) : Small.{u} {x // birthday x < o} :=
  small_setOf_birthday_lt o

end Game
end
