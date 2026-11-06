/-
Copyright (c) 2020 Fox Thomson. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Fox Thomson, Julia Markus Himmel, Violeta Hernández Palacios
-/
module

public import CombinatorialGames.Game.Specific.Nim
public import CombinatorialGames.Nimber.Basic

/-!
# Grundy value

The Grundy value of an impartial game is recursively defined as the least nimber not among the
Grundy values of either its left or right options. This map respects addition and multiplication.

We provide two definitions for the Grundy value. `grundyAux` is computed using either the left or
right options of the game, and is defined for all games. To make the API symmetric, we also provide
`Impartial.grundy`, which enforces that the game is impartial, and is thus equal to either of
`grundyAux left` or `grundyAux right`.

The **Sprague-Grundy** theorem `Impartial.nim_grundy_equiv` shows that any impartial game is
equivalent to a game of Nim, namely that corresponding to its Grundy value.
-/

universe u

open Nimber Set

public noncomputable section

namespace IGame

/-! ### Grundy value -/

/-- The left or right Grundy value of a game is recursively defined as the minimum excluded value
(the infimum of the complement) of the left or right Grundy values of its left or right options.

This is an auxiliary definition for reasoning about games not yet known to be impartial. Use
`Impartial.grundy` for an impartial game. -/
def grundyAux (p : Player) (x : IGame.{u}) : Nimber.{u} :=
  sInf (Set.range fun y : x.moves p ↦ grundyAux p y.1)ᶜ
termination_by x
decreasing_by igame_wf

theorem grundyAux_def (p) (x : IGame) : grundyAux p x = sInf (grundyAux p '' x.moves p)ᶜ := by
  sorry

theorem le_grundyAux_iff {p : Player} {x : IGame} {o : Nimber} :
    o ≤ grundyAux p x ↔ Iio o ⊆ grundyAux p '' x.moves p := by
  sorry

theorem lt_grundyAux_iff {p : Player} {x : IGame} {o : Nimber} :
    o < grundyAux p x ↔ Iic o ⊆ grundyAux p '' x.moves p := by
  sorry

theorem mem_grundyAux_image_of_lt {p : Player} {x : IGame} {o : Nimber} (h : o < grundyAux p x) :
    o ∈ grundyAux p '' x.moves p := by
  sorry

theorem grundyAux_le_of_notMem {p : Player} {x : IGame} {o : Nimber}
    (h : o ∉ grundyAux p '' x.moves p) :
    grundyAux p x ≤ o := by
  sorry

theorem grundyAux_ne {p : Player} {x y : IGame} (hy : y ∈ x.moves p) :
    grundyAux p y ≠ grundyAux p x := by
  sorry

@[simp]
theorem grundyAux_add (p : Player) (x y : IGame) :
    (x + y).grundyAux p = x.grundyAux p + y.grundyAux p := by
  sorry

@[simp]
theorem grundyAux_neg (p : Player) (x : IGame) : grundyAux p (-x) = grundyAux (-p) x := by
  sorry

@[simp]
theorem grundyAux_image_neg (p : Player) (s : Set IGame) :
    grundyAux p '' (-s) = grundyAux (-p) '' s := by
  sorry

@[simp]
theorem grundyAux_sub (p : Player) (x y : IGame) :
    (x - y).grundyAux p = x.grundyAux p + y.grundyAux (-p) := by
  sorry

namespace Impartial

/-- The Grundy value of an impartial game is recursively defined as the minimum excluded value
(the infimum of the complement) of the Grundy values of its options.

This definition enforces that `x` is impartial. If you want to talk about the left or right Grundy
values of a game (e.g. if you don't yet know it to be impartial), use `grundyAux`.
The lemma `grundyAux_eq_grundy` shows that both definitions match in
the case of an impartial game. -/
@[nolint unusedArguments]
def grundy (x : IGame) [Impartial x] : Nimber :=
  x.grundyAux right

/-- The **Sprague-Grundy theorem** states that every impartial game is equivalent to a game of nim,
namely the game of nim for the game's Grundy value. -/
theorem nim_grundy_equiv (x : IGame) [Impartial x] : nim (grundy x) ≈ x := by
  sorry

theorem grundy_eq_iff_equiv_nim {x : IGame} [Impartial x] {o : Nimber} :
    grundy x = o ↔ x ≈ nim o := by
  sorry

alias ⟨_, grundy_eq⟩ := grundy_eq_iff_equiv_nim

theorem grundy_eq_zero_iff {x : IGame} [Impartial x] : grundy x = 0 ↔ x ≈ 0 := by
  sorry

@[simp]
theorem grundy_eq_iff_equiv {x y : IGame} [Impartial x] [Impartial y] :
    grundy x = grundy y ↔ x ≈ y := by
  sorry

@[simp] theorem grundy_nim (o : Nimber) : grundy (nim o) = o := by
  sorry
@[simp] theorem grundy_zero : grundy 0 = 0 := by
  sorry
@[simp] theorem grundy_star : grundy ⋆ = 1 := by
  sorry

@[simp]
theorem grundy_neg (x : IGame) [Impartial x] : grundy (-x) = grundy x := by
  sorry

@[simp]
theorem grundyAux_eq_grundy (p) (x : IGame) [Impartial x] : grundyAux p x = grundy x := by
  sorry

@[simp]
theorem grundy_add (x y : IGame) [Impartial x] [Impartial y] :
    grundy (x + y) = grundy x + grundy y := by
  sorry

theorem _root_.IGame.nim_add_equiv (a b : Nimber) : nim a + nim b ≈ nim (a + b) := by
  sorry

theorem grundy_moves_ne {p : Player} {x y : IGame} [Impartial x] (hy : y ∈ x.moves p) :
    have := Impartial.of_mem_moves hy; grundy y ≠ grundy x := by
  sorry

private theorem of_grundyAux_left_eq_grundyAux_right' {x : IGame}
    (h : ∀ p, ∀ y ∈ x.moves p, Impartial y)
    (H : grundyAux left x = grundyAux right x) : nim (grundyAux right x) ≈ x := by
  sorry

/-- If a game `x` has only impartial options, and its left Grundy value equals its right Grundy
value, then it's impartial. -/
theorem of_grundyAux_left_eq_grundyAux_right {x : IGame}
    (h : ∀ p, ∀ y ∈ x.moves p, Impartial y)
    (H : grundyAux left x = grundyAux right x) : Impartial x := by
  sorry

end Impartial
end IGame
end
