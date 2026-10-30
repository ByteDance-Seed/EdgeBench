/-
Copyright (c) 2025 Violeta Hernández Palacios. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Violeta Hernández Palacios
-/
module

public import CombinatorialGames.Game.Impartial.Grundy
public import CombinatorialGames.Nimber.Field

/-!
# Multiplication of impartial games

We prove here that the product of impartial games is impartial, and that its Grundy value equals the
product of the Grundy values of its factors. This implies that game multiplication is algebraically
well-behaved on impartial games, i.e. it respects equivalence, and there are no zero divisors.
-/

open Nimber

public section

namespace IGame.Impartial

private theorem mul' (x y : IGame) [Impartial x] [Impartial y] :
    Impartial (x * y) ∧ grundyAux right (x * y) = grundyAux right x * grundyAux right y := by
  sorry

protected instance mul (x y : IGame) [Impartial x] [Impartial y] : Impartial (x * y) :=
  (mul' x y).1

end Impartial

namespace Impartial

variable {x y x₁ x₂ y₁ y₂ : IGame} [Impartial x] [Impartial y]
  [Impartial x₁] [Impartial x₂] [Impartial y₁] [Impartial y₂]

@[simp]
theorem grundy_mul (x y : IGame) [Impartial x] [Impartial y] :
    grundy (x * y) = grundy x * grundy y := by
  sorry

theorem _root_.IGame.nim_mul_equiv (a b : Nimber) : nim a * nim b ≈ nim (a * b) := by
  sorry

theorem mul_equiv_zero : x * y ≈ 0 ↔ x ≈ 0 ∨ y ≈ 0 := by
  sorry

protected instance mulOption (x y a b : IGame)
    [Impartial x] [Impartial y] [Impartial a] [Impartial b] :
    Impartial (mulOption x y a b) :=
  .sub ..

theorem mul_congr_left (he : x₁ ≈ x₂) : x₁ * y ≈ x₂ * y := by
  sorry

theorem mul_congr_right (he : y₁ ≈ y₂) : x * y₁ ≈ x * y₂ := by
  sorry

theorem mul_congr (hx : x₁ ≈ x₂) (hy : y₁ ≈ y₂) : x₁ * y₁ ≈ x₂ * y₂ := by
  sorry

end IGame.Impartial
end
