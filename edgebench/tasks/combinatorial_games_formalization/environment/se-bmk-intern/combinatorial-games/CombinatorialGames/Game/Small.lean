/-
Copyright (c) 2025 Tristan Figueroa-Reid. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Tristan Figueroa-Reid
-/
module

public import CombinatorialGames.Game.Impartial.Grundy

/-!
# Small games all around

We define dicotic games, games `x` where both players can move from
every nonempty subposition of `x`. We prove that these games are small, and relate them
to infinitesimals.

## TODO

- Define infinitesimal games as games `x` such that `∀ r : ℝ, 0 < r → -r < x ∧ x < r`
  - (Does this hold for small infinitesimal games?)
- Prove that any short dicotic game is an infinitesimal (but not vice versa, consider `ω⁻¹`)
-/

public section

namespace IGame
namespace Dicotic

/--
One half of the **lawnmower theorem**: any dicotic game is smaller than any positive numeric game.
-/
theorem lt_of_numeric_of_pos (x) [Dicotic x] {y} [Numeric y] (hy : 0 < y) : x < y := by
  sorry

/--
One half of the **lawnmower theorem**: any dicotic game is greater than any negative numeric game.
-/
theorem lt_of_numeric_of_neg (x) [Dicotic x] {y} [Numeric y] (hy : y < 0) : y < x := by
  sorry

end Dicotic

namespace Impartial

/-- One half of the **lawnmower theorem** for impartial games. -/
protected theorem lt_of_numeric_of_pos (x) [Impartial x] {y} [Numeric y] (hy : 0 < y) : x < y := by
  sorry

/-- One half of the **lawnmower theorem** for impartial games. -/
protected theorem lt_of_numeric_of_neg (x) [Impartial x] {y} [Numeric y] (hy : y < 0) : y < x := by
  sorry

end Impartial
end IGame
end
