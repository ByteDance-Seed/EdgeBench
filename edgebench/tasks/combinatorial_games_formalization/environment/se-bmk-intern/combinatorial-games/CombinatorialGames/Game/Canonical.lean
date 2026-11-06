/-
Copyright (c) 2025 Tristan Figueroa-Reid. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Tristan Figueroa-Reid
-/
module

public import CombinatorialGames.Game.Birthday

/-!
# Canonical games

For any game G, its canonical game G' is the unique IGame game with
smallest birthday such that G'.Fits G.
From the literature, this file provides an explicit (though noncomputable) construction of canonical
games through undominating and unreversing games.

## Todo

- Define (un)reversibility
-/

universe u

public noncomputable section

namespace IGame

/-- Undominating a game. This returns garbage values on non-short games -/
def undominate (x : IGame) : IGame :=
  !{{y ∈ Set.range fun z : xᴸ ↦ undominate z | ∀ z ∈ xᴸ, ¬y < z} |
    {y ∈ Set.range fun z : xᴿ ↦ undominate z | ∀ z ∈ xᴿ, ¬z < y}}
termination_by x
decreasing_by igame_wf

theorem birthday_undominate_le (x : IGame) : x.undominate.birthday ≤ x.birthday := by
  sorry

theorem undominate_def {x : IGame} : x.undominate =
    !{{y ∈ undominate '' xᴸ | ∀ z ∈ xᴸ, ¬y < z} |
      {y ∈ undominate '' xᴿ | ∀ z ∈ xᴿ, ¬z < y}} := by
  sorry

@[simp]
theorem leftMoves_undominate {x : IGame} :
    x.undominateᴸ = {y ∈ undominate '' xᴸ | ∀ z ∈ xᴸ, ¬y < z} := by
  sorry

@[simp]
theorem rightMoves_undominate {x : IGame} :
    x.undominateᴿ = {y ∈ undominate '' xᴿ | ∀ z ∈ xᴿ, ¬z < y} := by
  sorry

instance {x : IGame} [hx : Short x] : Short (undominate x) := by
  rw [short_iff_birthday_finite] at hx ⊢
  exact (birthday_undominate_le x).trans_lt hx

@[simp]
theorem undominate_neg (x : IGame) : (-x).undominate = -x.undominate := by
  sorry

private theorem le_undominate (x : IGame) [Short x] : x ≤ undominate x := by
  sorry

theorem undominate_equiv (x : IGame) [Short x] : undominate x ≈ x := by
  sorry

end IGame
end
