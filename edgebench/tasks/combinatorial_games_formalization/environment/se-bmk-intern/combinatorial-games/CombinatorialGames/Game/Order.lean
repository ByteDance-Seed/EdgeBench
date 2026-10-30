/-
Copyright (c) 2025 Aaron Liu. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Aaron Liu
-/
module

public import CombinatorialGames.Game.Birthday

/-!
# Games are densely ordered

We provide instances of `DenselyOrdered` for `IGame` and `Game`.
-/

universe u

public noncomputable section
namespace IGame

theorem tiny_lf_of_not_nonpos_of_forall_neg_le {x a : IGame} (hx : 0 ⧏ x)
    (ha : ∀ y ∈ xᴿ, -a ≤ y) : ⧾a ⧏ x := by
  sorry

theorem tiny_le_of_pos_of_forall_neg_le {x a : IGame} (hx : 0 < x)
    (ha : ∀ y ∈ xᴿ, ∀ z ∈ yᴿ, -a ≤ z) : ⧾a ≤ x := by
  sorry

theorem tiny_toIGame_birthday_lt {x : IGame.{u}} (hx : 0 < x) : ⧾x.birthday.toIGame < x := by
  sorry

theorem lf_miny_of_not_nonneg_of_forall_le {x a : IGame} (hx : x ⧏ 0)
    (ha : ∀ y ∈ xᴸ, y ≤ a) : x ⧏ ⧿a := by
  sorry

theorem le_miny_of_neg_of_forall_le_neg {x a : IGame} (hx : x < 0)
    (ha : ∀ y ∈ xᴸ, ∀ z ∈ yᴸ, z ≤ a) : x ≤ ⧿a := by
  sorry

theorem lt_miny_toIGame_birthday {x : IGame.{u}} (hx : x < 0) : x < ⧿x.birthday.toIGame := by
  sorry

instance : DenselyOrdered IGame where
  dense a b hab := by
    refine ⟨⧾(b - a).birthday.toIGame + a, ?_, ?_⟩
    · simp [tiny_pos]
    · rw [← IGame.lt_sub_iff_add_lt]
      exact tiny_toIGame_birthday_lt (IGame.sub_pos.2 hab)

instance : DenselyOrdered Game where
  dense a b hab := by
    induction a using Game.ind with | mk a
    induction b using Game.ind with | mk b
    rw [Game.mk_lt_mk] at hab
    obtain ⟨c, hac, hcb⟩ := exists_between hab
    exact ⟨.mk c, hac, hcb⟩

end IGame
end
