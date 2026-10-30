/-
Copyright (c) 2024 Violeta Hernández Palacios. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Violeta Hernández Palacios
-/
module

public import CombinatorialGames.Game.Special

import CombinatorialGames.Tactic.GameCmp

/-!
# Multiplication of pre-games can't be lifted to the quotient

We show that there exist equivalent pre-games `x₁ ≈ x₂` and `y` such that `x₁ * y ≉ x₂ * y`. In
particular, we cannot define the multiplication of games in general.

The specific counterexample we use is `x₁ = y = {0 | 0}` and `x₂ = {-1, 0 | 0, 1}`. The first game
is colloquially known as `star`, so we use the name `star'` for the second. We prove that
`star ≈ star'` and `star * star ≈ star`, but `star' * star ≉ star`.
-/

public noncomputable section
open IGame

namespace IGame

/-- The game `⋆' = {-1, 0 | 0, 1}`, which is equivalent but not identical to `⋆`. -/
@[game_cmp] def star' : IGame := !{{0, -1} | {0, 1}}
local notation " ⋆' " => star'

/-- `⋆'` is equivalent to `⋆`. -/
theorem star'_equiv_star : ⋆' ≈ ⋆ := by
  sorry

/-- `⋆' * ⋆` is not equivalent to `*`. -/
theorem star'_mul_star_not_equiv : ¬ ⋆' * ⋆ ≈ ⋆ := by
  sorry

/-- Pre-game multiplication cannot be lifted to games. -/
theorem mul_not_lift : ∃ x₁ x₂ y : IGame, x₁ ≈ x₂ ∧ ¬ x₁ * y ≈ x₂ * y := by
  sorry

end IGame
end
