/-
Copyright (c) 2025 Violeta Hernández Palacios. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Violeta Hernández Palacios
-/
module

import CombinatorialGames.Game.Specific.Nim
import CombinatorialGames.Nimber.Field
import CombinatorialGames.Tactic.GameCmp

/-!
Tests for the `game_cmp` tactic.
-/

open IGame Nimber
open scoped CharTwo

-- Basic order relations
example : (0 : IGame) < 1 := by
  sorry
example : (-3 : ℤ) ≤ (3 : IGame) := by
  sorry
example : 1 ≥ ½ := by
  sorry
example : ↑ > 0 := by
  sorry
example : ⋆ ⧏ ⧾⋆ := by
  sorry
example : (!{{1} | {2}} : IGame) ≈ !{{0, 1} | {2, 3}} := by
  sorry
example : ⋆ ‖ 0 := by
  sorry

-- Arithmetic
example : (2 : IGame) + 2 ≈ 4 := by
  sorry
example : (3 : IGame) - 2 ≈ 1 := by
  sorry
example : (2 : IGame) * 2 ≈ 4 := by
  sorry

-- Ordinals and nimbers
example : NatOrdinal.toIGame 3 ≈ 3 := by
  sorry
example : nim 1 + nim (∗2) ≈ nim (∗3) := by
  sorry
example : nim 2 ≈ nim 0 := by
  sorry -- Be careful, `↑2` is not the same as `∗2`.
