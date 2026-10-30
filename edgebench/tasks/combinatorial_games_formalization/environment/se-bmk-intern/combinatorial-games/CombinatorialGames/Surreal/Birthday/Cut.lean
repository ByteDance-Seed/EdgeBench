/-
Copyright (c) 2025 Violeta Hernández Palacios. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Violeta Hernández Palacios, Aaron Liu
-/
module

public import CombinatorialGames.Surreal.Cut

import CombinatorialGames.Mathlib.WithTop

/-!
# Birthday of cuts

We introduce the birthday of a (surreal) cut as `Cut.birthday`, and relate it to the birthdays of
games and surreal numbers.

This definition doesn't exist in the literature, but it's useful in proving results about the
birthdays of games. In particular, it allows us to prove the equality
`birthday_toGame : x.toGame.birthday = x.birthday` for surreal numbers `x`. See
https://mathoverflow.net/a/497645/147705 for a "plaintext" version of this proof.
-/

universe u

open Set

public noncomputable section

namespace Surreal.Cut

/-! ### Birthday of cuts -/

/-- The birthday of a cut `x` is defined as the infimum of `⨆ a ∈ s, a.birthday + 1` over all
sets `s` of surreals where either the infimum of the left cuts or the supremum of right cuts of `s`
equals `x`.

The birthday takes values in `WithTop NatOrdinal`. Cuts with birthday `⊤` are precisely those where
the set `s` is not small.

This isn't a term in the literature, but it's useful for proving that birthdays of surreals equal
those of their associated games. -/
def birthday (x : Cut) : WithTop NatOrdinal :=
  sInf <| (fun s ↦ sSup ((fun x ↦ x.birthday + 1) '' s)) ''
     {s : Set Surreal | sInf (leftSurreal '' s) = x ∨ sSup (rightSurreal '' s) = x}

theorem birthday_eq_sSup_birthday (x : Cut) :
    ∃ s : Set Surreal, (sInf (leftSurreal '' s) = x ∨ sSup (rightSurreal '' s) = x) ∧
      sSup ((fun x ↦ (x.birthday : WithTop _) + 1) '' s) = birthday x := by
  sorry

theorem birthday_sInf_leftSurreal_le (s : Set Surreal) :
    (sInf (leftSurreal '' s)).birthday ≤
      sSup ((fun x ↦ (x.birthday : WithTop _) + 1) '' s)  := by
  sorry

theorem birthday_sSup_rightSurreal_le (s : Set Surreal) :
    (sSup (rightSurreal '' s)).birthday ≤
      (sSup ((fun x ↦ (x.birthday : WithTop _) + 1) '' s)) := by
  sorry

theorem birthday_iInf_leftSurreal_le {ι : Type*} (f : ι → Surreal) :
    (⨅ i, leftSurreal (f i)).birthday ≤ ⨆ i, ((f i).birthday : WithTop _) + 1 := by
  sorry

theorem birthday_iSup_rightSurreal_le {ι : Type*} (f : ι → Surreal) :
    (⨆ i, rightSurreal (f i)).birthday ≤ ⨆ i, ((f i).birthday : WithTop _) + 1 := by
  sorry

theorem birthday_sInf_leftSurreal_le' (s : Set Surreal.{u}) [Small.{u} s] :
    (sInf (leftSurreal '' s)).birthday ≤
      (sSup ((fun x ↦ x.birthday + 1) '' s) : NatOrdinal) := by
  sorry

theorem birthday_sSup_rightSurreal_le' (s : Set Surreal.{u}) [Small.{u} s] :
    (sSup (rightSurreal '' s)).birthday ≤
      (sSup ((fun x ↦ x.birthday + 1) '' s) : NatOrdinal) := by
  sorry

theorem birthday_iInf_leftSurreal_le' {ι : Type*} (f : ι → Surreal.{u}) [Small.{u} ι] :
    (⨅ i, leftSurreal (f i)).birthday ≤ ⨆ i, (f i).birthday + 1 := by
  sorry

theorem birthday_iSup_rightSurreal_le' {ι : Type*} (f : ι → Surreal.{u}) [Small.{u} ι] :
    (⨆ i, rightSurreal (f i)).birthday ≤ ⨆ i, (f i).birthday + 1 := by
  sorry

theorem birthday_lt_sSup_birthday {a : Surreal} {s : Set Surreal} (ha : a ∈ s) :
    a.birthday < sSup ((fun x : Surreal ↦ (x.birthday : WithTop NatOrdinal) + 1) '' s) := by
  sorry

theorem sSup_birthday_lt_top_iff {s : Set Surreal.{u}} :
    sSup ((fun x : Surreal ↦ (x.birthday : WithTop NatOrdinal) + 1) '' s) < ⊤ ↔ Small.{u} s := by
  sorry

theorem sSup_birthday_eq_top_iff {s : Set Surreal.{u}} :
    sSup ((fun x : Surreal ↦ (x.birthday : WithTop NatOrdinal) + 1) '' s) = ⊤ ↔ ¬ Small.{u} s := by
  sorry

@[simp]
theorem birthday_bot : birthday ⊥ = 0 := by
  sorry

@[simp]
theorem birthday_top : birthday ⊤ = 0 := by
  sorry

private theorem birthday_neg_le (x : Cut) : (-x).birthday ≤ x.birthday := by
  sorry

@[simp]
theorem birthday_neg (x : Cut) : (-x).birthday = x.birthday := by
  sorry

@[simp]
theorem birthday_leftSurreal (x : Surreal) : (leftSurreal x).birthday = x.birthday + 1 := by
  sorry

@[simp]
theorem birthday_rightSurreal (x : Surreal) : (rightSurreal x).birthday = x.birthday + 1 := by
  sorry

theorem exists_birthday_lt_of_mem_Ioo {x y z : Cut} (h : y ∈ Ioo x z) :
    ∃ a : Surreal, a.birthday < y.birthday ∧ Fits a x z := by
  sorry

theorem birthday_iInf_le {ι : Type*} (f : ι → Cut) : (⨅ i, f i).birthday ≤ ⨆ i, (f i).birthday := by
  sorry

theorem birthday_iSup_le {ι : Type*} (f : ι → Cut) : (⨆ i, f i).birthday ≤ ⨆ i, (f i).birthday := by
  sorry

theorem birthday_sInf_le (s : Set Cut) : (sInf s).birthday ≤ sSup (birthday '' s) := by
  sorry

theorem birthday_sSup_le (s : Set Cut) : (sSup s).birthday ≤ sSup (birthday '' s) := by
  sorry

theorem birthday_simplestBtwn_le {x y : Cut.{u}} (h : x < y) :
    (simplestBtwn h).birthday ≤ max x.birthday y.birthday := by
  sorry

private theorem birthday_game_le (x : IGame) :
    (supLeft x).birthday ≤ x.birthday ∧ (infRight x).birthday ≤ x.birthday ∧
    (leftGame (.mk x)).birthday ≤ x.birthday + 1 ∧
    (rightGame (.mk x)).birthday ≤ x.birthday + 1 := by
  sorry

theorem birthday_supLeft_le (x : IGame) : (supLeft x).birthday ≤ x.birthday := by
  sorry

theorem birthday_infRight_le (x : IGame) : (infRight x).birthday ≤ x.birthday := by
  sorry

theorem birthday_leftGame_le (x : Game) : (leftGame x).birthday ≤ x.birthday + 1 := by
  sorry

theorem birthday_rightGame_le (x : Game) : (rightGame x).birthday ≤ x.birthday + 1 := by
  sorry

/-- The smallest birthday among *numeric* games equivalent to a surreal, is also the smallest
birthday among *all* games in general. -/
@[simp]
theorem _root_.Surreal.birthday_toGame (x : Surreal) : x.toGame.birthday = x.birthday := by
  sorry

end Surreal.Cut
end
