/-
Copyright (c) 2025 Violeta Hernández Palacios. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Violeta Hernández Palacios
-/
module

public import CombinatorialGames.Game.Classes
public import CombinatorialGames.Mathlib.Dyadic
public import CombinatorialGames.Surreal.Division

import Mathlib.Data.Finset.DenselyOrdered

/-!
# Dyadic games

A combinatorial game that is both `Short` and `Numeric` is called dyadic. We show that the dyadic
games are in correspondence with the `Dyadic` rationals, in the sense that there exists a map
`Dyadic.toIGame` such that:

- `Dyadic.toIGame x` is always a dyadic game.
- For any dyadic game `y`, there exists `x` with `Dyadic.toIGame x ≈ y`.
- The game `Dyadic.toGame x` is equivalent to the `RatCast` of `x`.

## Future projects

Since dyadic rationals are easy to do computations with, there are some projects we could pursue in
the future:

- Define the birthday of a dyadic number computably, prove that `x.birthday = x.toIGame.birthday`.
- Define the simplest dyadic number between two others computably, use that to define
  `IGame.toDyadic`.
-/

universe u
open IGame

@[expose] public section

namespace Dyadic

/-! ### Upper and lower dyadic fractions -/

/-- For a dyadic number `m / n`, returns `(m - 1) / n`. -/
def lower (x : Dyadic) : Dyadic :=
  .mkRat (x.num - 1) x.den_mem_powers

/-- For a dyadic number `m / n`, returns `(m + 1) / n`. -/
def upper (x : Dyadic) : Dyadic :=
  .mkRat (x.num + 1) x.den_mem_powers

theorem den_lower_lt {x : Dyadic} (h : x.den ≠ 1) : (lower x).den < x.den := by
  sorry

theorem den_upper_lt {x : Dyadic} (h : x.den ≠ 1) : (upper x).den < x.den := by
  sorry

/-- An auxiliary tactic for inducting on the denominator of a `Dyadic`. -/
macro "dyadic_wf" : tactic =>
  `(tactic| all_goals first | solve_by_elim
    [Prod.Lex.left, Prod.Lex.right, den_lower_lt, den_upper_lt] | decreasing_tactic)

@[simp]
theorem lower_neg (x : Dyadic) : lower (-x) = -upper x := by
  sorry

@[simp]
theorem upper_neg (x : Dyadic) : upper (-x) = -lower x := by
  sorry

theorem le_lower_of_lt {x y : Dyadic} (hd : x.den ≤ y.den) (h : x < y) : x ≤ y.lower := by
  sorry

theorem upper_le_of_lt {x y : Dyadic} (hd : y.den ≤ x.den) (h : x < y) : x.upper ≤ y := by
  sorry

theorem lower_eq_of_den_eq_one {x : Dyadic} (h : x.den = 1) : lower x = x.num - 1 := by
  sorry

theorem upper_eq_of_den_eq_one {x : Dyadic} (h : x.den = 1) : upper x = x.num + 1 := by
  sorry

@[simp]
theorem lower_lt (x : Dyadic) : lower x < x := by
  sorry

@[simp]
theorem lt_upper (x : Dyadic) : x < upper x := by
  sorry

theorem lower_lt_upper (x : Dyadic) : lower x < upper x := by
  sorry

theorem coe_lower (x : Dyadic) : lower x = x - (x.den : ℚ)⁻¹ := by
  sorry

theorem coe_upper (x : Dyadic) : upper x = x + (x.den : ℚ)⁻¹ := by
  sorry

theorem lower_add_le_of_den_le {x y : Dyadic} (h : x.den ≤ y.den) :
    lower (x + y) ≤ x + lower y := by
  sorry

theorem lower_add_le_of_den_ge {x y : Dyadic} (h : y.den ≤ x.den) :
    lower (x + y) ≤ lower x + y := by
  sorry

theorem le_upper_add_of_den_le {x y : Dyadic} (h : x.den ≤ y.den) :
    x + upper y ≤ upper (x + y) := by
  sorry

theorem le_upper_add_of_den_ge {x y : Dyadic} (h : y.den ≤ x.den) :
    upper x + y ≤ upper (x + y) := by
  sorry

/-! ### Dyadic numbers to games -/

/-- Converts a dyadic rational into an `IGame`. This map is defined so that:

* If `x : ℤ`, then `toIGame x = ↑x`.
* Otherwise, if `x = m / n` with `n` even, then `toIGame x = !{(m - 1) / n | (m + 1) / n}`. Note
  that both options will have smaller denominators. -/
@[coe]
noncomputable def toIGame (x : Dyadic) : IGame :=
  if _ : x.den = 1 then x.num else !{{toIGame (lower x)} | {toIGame (upper x)}}
termination_by x.den
decreasing_by dyadic_wf

noncomputable instance : Coe Dyadic IGame := ⟨toIGame⟩

theorem toIGame_of_den_eq_one {x : Dyadic} (hx : x.den = 1) : (x : IGame) = x.num := by
  sorry

@[simp] theorem toIGame_intCast (n : ℤ) : ((n : Dyadic) : IGame) = n := by
  sorry
@[simp] theorem toIGame_natCast (n : ℕ) : ((n : Dyadic) : IGame) = n := by
  sorry

@[simp] theorem toIGame_zero : ((0 : Dyadic) : IGame) = 0 := by
  sorry
@[simp] theorem toIGame_one :  ((1 : Dyadic) : IGame) = 1 := by
  sorry

theorem toIGame_of_den_ne_one {x : Dyadic} (hx : x.den ≠ 1) :
    x = !{{(lower x : IGame)} | {(upper x : IGame)}} := by
  sorry

@[simp]
theorem toIGame_half : half = ½ := by
  sorry

@[simp]
theorem toIGame_neg (x : Dyadic) : (-x : Dyadic) = -(x : IGame) := by
  sorry

theorem eq_lower_of_mem_leftMoves_toIGame {x : Dyadic} {y : IGame} (h : y ∈ xᴸ) :
    y = lower x := by
  sorry

theorem eq_upper_of_mem_rightMoves_toIGame {x : Dyadic} {y : IGame} (h : y ∈ xᴿ) :
    y = upper x := by
  sorry

/-- A dyadic number `x` is always equivalent to `!{lower x | upper x}`, though this may not
necessarily be the canonical form. -/
theorem toIGame_equiv_lower_upper (x : Dyadic) :
    (x : IGame) ≈ !{{(lower x : IGame)} | {(upper x : IGame)}} := by
  sorry

instance _root_.IGame.Short.dyadic (x : Dyadic) : Short x := by
  rw [toIGame]
  split_ifs with h
  · exact .intCast _
  · rw [short_def]
    simpa using ⟨.dyadic _, .dyadic _⟩
termination_by x.den
decreasing_by dyadic_wf

private theorem numeric_lower (x : Dyadic) [hx : Numeric (x : IGame.{u})] :
    Numeric (lower x : IGame.{u}) := by
  sorry

private theorem numeric_upper (x : Dyadic) [hx : Numeric (x : IGame.{u})] :
    Numeric (toIGame.{u} (upper x)) := by
  sorry

private theorem lower_lt_aux (x : Dyadic) [hx : Numeric (x : IGame.{u})] :
    (lower x : IGame.{u}) < x := by
  sorry

private theorem lt_upper_aux (x : Dyadic) [hx : Numeric (x : IGame.{u})] :
    x < (upper x : IGame.{u}) := by
  sorry

private theorem toIGame_lt_toIGame_aux {x y : Dyadic}
    [Numeric (x : IGame.{u})] [Numeric (toIGame.{u} y)] (h : x < y) : (x : IGame.{u}) < y := by
  sorry

instance _root_.IGame.Numeric.dyadic (x : Dyadic) : Numeric x := by
  by_cases h : x.den = 1
  · rw [toIGame_of_den_eq_one h]
    infer_instance
  · rw [numeric_def, toIGame_of_den_ne_one h]
    have := IGame.Numeric.dyadic (lower x)
    have := IGame.Numeric.dyadic (upper x)
    have := toIGame_lt_toIGame_aux (lower_lt_upper x)
    simp_all
termination_by x.den
decreasing_by dyadic_wf

/-- `Dyadic.toIGame` as an `OrderEmbedding`. -/
@[simps!]
noncomputable def toIGameEmbedding : Dyadic ↪o IGame :=
  .ofStrictMono toIGame fun _ _ ↦ by exact toIGame_lt_toIGame_aux

@[simp, norm_cast]
theorem toIGame_le_toIGame {x y : Dyadic} : (x : IGame) ≤ y ↔ x ≤ y := by
  sorry

@[simp, norm_cast]
theorem toIGame_lt_toIGame {x y : Dyadic} : (x : IGame) < y ↔ x < y := by
  sorry

@[simp, norm_cast]
theorem toIGame_equiv_toIGame {x y : Dyadic} :  (x : IGame) ≈ y ↔ x = y := by
  sorry

@[simp, norm_cast]
theorem toIGame_inj {x y : Dyadic} : (x : IGame) = y ↔ x = y := by
  sorry

theorem toIGame_add_equiv (x y : Dyadic) : ((x + y : Dyadic) : IGame.{u}) ≈ x + y := by
  sorry

theorem toIGame_sub_equiv (x y : Dyadic) : ((x - y : Dyadic) : IGame) ≈ x - y := by
  sorry

theorem toIGame_equiv (x : Dyadic) : (x : IGame) ≈ (x : ℚ) := by
  sorry

@[simp]
theorem _root_.Game.mk_dyadic (x : Dyadic) : Game.mk x = x := by
  sorry

@[simp]
theorem _root_.Surreal.mk_dyadic (x : Dyadic) : Surreal.mk x = x := by
  sorry

theorem toIGame_mul_equiv (x y : Dyadic) : ((x * y : Dyadic) : IGame) ≈ x * y := by
  sorry

/-! ### Simp lemmas -/

/-! #### ℚ -/

@[simp, norm_cast]
theorem toIGame_lt_ratCast {x : Dyadic} {y : ℚ} : (x : IGame) < y ↔ x < y := by
  sorry
@[simp, norm_cast]
theorem toIGame_le_ratCast {x : Dyadic} {y : ℚ} : (x : IGame) ≤ y ↔ x ≤ y := by
  sorry

@[simp, norm_cast]
theorem ratCast_lt_toIGame {x : ℚ} {y : Dyadic} : (x : IGame) < y ↔ x < y := by
  sorry
@[simp, norm_cast]
theorem ratCast_le_toIGame {x : ℚ} {y : Dyadic} : (x : IGame) ≤ y ↔ x ≤ y := by
  sorry

@[simp, norm_cast]
theorem toIGame_equiv_ratCast {x : Dyadic} {y : ℚ} : (x : IGame) ≈ y ↔ x = y := by
  sorry
@[simp, norm_cast]
theorem ratCast_equiv_toIGame {x : ℚ} {y : Dyadic} : (x : IGame) ≈ y ↔ x = y := by
  sorry

/-! #### ℤ -/

@[simp, norm_cast]
theorem toIGame_lt_intCast {x : Dyadic} {y : ℤ} : (x : IGame) < y ↔ x < y := by
  sorry
@[simp, norm_cast]
theorem toIGame_le_intCast {x : Dyadic} {y : ℤ} : (x : IGame) ≤ y ↔ x ≤ y := by
  sorry

@[simp, norm_cast]
theorem intCast_lt_toIGame {x : ℤ} {y : Dyadic} : (x : IGame) < y ↔ x < y := by
  sorry
@[simp, norm_cast]
theorem intCast_le_toIGame {x : ℤ} {y : Dyadic} : (x : IGame) ≤ y ↔ x ≤ y := by
  sorry

@[simp, norm_cast]
theorem toIGame_equiv_intCast {x : Dyadic} {y : ℤ} : (x : IGame) ≈ y ↔ x = y := by
  sorry
@[simp, norm_cast]
theorem intCast_equiv_toIGame {x : ℤ} {y : Dyadic} : (x : IGame) ≈ y ↔ x = y := by
  sorry

@[simp, norm_cast]
theorem toIGame_eq_intCast {x : Dyadic} {y : ℤ} : (x : IGame) = y ↔ x = y := by
  sorry
@[simp, norm_cast]
theorem intCast_eq_toIGame {x : ℤ} {y : Dyadic} : (x : IGame) = y ↔ x = y := by
  sorry

/-! #### ℕ -/

@[simp, norm_cast]
theorem toIGame_lt_natCast {x : Dyadic} {y : ℕ} : (x : IGame) < y ↔ x < y := by
  sorry
@[simp, norm_cast]
theorem toIGame_le_natCast {x : Dyadic} {y : ℕ} : (x : IGame) ≤ y ↔ x ≤ y := by
  sorry

@[simp, norm_cast]
theorem natCast_lt_toIGame {x : ℕ} {y : Dyadic} : (x : IGame) < y ↔ x < y := by
  sorry
@[simp, norm_cast]
theorem natCast_le_toIGame {x : ℕ} {y : Dyadic} : (x : IGame) ≤ y ↔ x ≤ y := by
  sorry

@[simp, norm_cast]
theorem toIGame_equiv_natCast {x : Dyadic} {y : ℕ} : (x : IGame) ≈ y ↔ x = y := by
  sorry
@[simp, norm_cast]
theorem natCast_equiv_toIGame {x : ℕ} {y : Dyadic} : (x : IGame) ≈ y ↔ x = y := by
  sorry

@[simp, norm_cast]
theorem toIGame_eq_natCast {x : Dyadic} {y : ℕ} : (x : IGame) = y ↔ x = y := by
  sorry
@[simp, norm_cast]
theorem natCast_eq_toIGame {x : ℕ} {y : Dyadic} : (x : IGame) = y ↔ x = y := by
  sorry

/-! #### 0 -/

@[simp, norm_cast]
theorem toIGame_lt_zero {x : Dyadic} : (x : IGame) < 0 ↔ x < 0 := by
  sorry
@[simp, norm_cast]
theorem toIGame_le_zero {x : Dyadic} : (x : IGame) ≤ 0 ↔ x ≤ 0 := by
  sorry

@[simp, norm_cast]
theorem zero_lt_toIGame {x : Dyadic} : 0 < (x : IGame) ↔ 0 < x := by
  sorry
@[simp, norm_cast]
theorem zero_le_toIGame {x : Dyadic} : 0 ≤ (x : IGame) ↔ 0 ≤ x := by
  sorry

@[simp, norm_cast]
theorem toIGame_equiv_zero {x : Dyadic} : (x : IGame) ≈ 0 ↔ x = 0 := by
  sorry
@[simp, norm_cast]
theorem zero_equiv_toIGame {x : Dyadic} : 0 ≈ (x : IGame) ↔ 0 = x := by
  sorry

@[simp, norm_cast]
theorem toIGame_eq_zero {x : Dyadic} : (x : IGame) = 0 ↔ x = 0 := by
  sorry
@[simp, norm_cast]
theorem zero_eq_toIGame {x : Dyadic} : 0 = (x : IGame) ↔ 0 = x := by
  sorry

/-! #### 1 -/

@[simp, norm_cast]
theorem toIGame_lt_one {x : Dyadic} : (x : IGame) < 1 ↔ x < 1 := by
  sorry
@[simp, norm_cast]
theorem toIGame_le_one {x : Dyadic} : (x : IGame) ≤ 1 ↔ x ≤ 1 := by
  sorry

@[simp, norm_cast]
theorem one_lt_toIGame {x : Dyadic} : 1 < (x : IGame) ↔ 1 < x := by
  sorry
@[simp, norm_cast]
theorem one_le_toIGame {x : Dyadic} : 1 ≤ (x : IGame) ↔ 1 ≤ x := by
  sorry

@[simp, norm_cast]
theorem toIGame_equiv_one {x : Dyadic} : (x : IGame) ≈ 1 ↔ x = 1 := by
  sorry
@[simp, norm_cast]
theorem one_equiv_toIGame {x : Dyadic} : 1 ≈ (x : IGame) ↔ 1 = x := by
  sorry

@[simp, norm_cast]
theorem toIGame_eq_one {x : Dyadic} : (x : IGame) = 1 ↔ x = 1 := by
  sorry
@[simp, norm_cast]
theorem one_eq_toIGame {x : Dyadic} : 1 = (x : IGame) ↔ 1 = x := by
  sorry

end Dyadic

/-! ### Dyadic games as numbers -/

namespace IGame

private theorem equiv_dyadic (x : IGame) [Short x] [Numeric x] : ∃ y : Dyadic, x ≈ y.toIGame := by
  sorry

/-- Any dyadic game (meaning a game that is `Short` and `Numeric`) is equivalent to a `Dyadic`
rational number.

TODO: it should be possible to compute this value explicitly, given the finsets of `Dyadic`
rationals corresponding to the left and right moves. -/
@[no_expose]
noncomputable def toDyadic (x : IGame) [Short x] [Numeric x] : Dyadic :=
  Classical.choose x.equiv_dyadic

@[simp]
theorem equiv_toIGame_toDyadic (x : IGame) [Short x] [Numeric x] : x ≈ x.toDyadic := by
  sorry

@[simp]
theorem toIGame_toDyadic_equiv (x : IGame) [Short x] [Numeric x] : (x.toDyadic : IGame) ≈ x := by
  sorry

@[simp]
theorem _root_.Game.ratCast_toDyadic (x : IGame) [Short x] [Numeric x] :
    x.toDyadic = Game.mk x := by
  sorry

@[simp]
theorem _root_.Surreal.ratCast_toDyadic (x : IGame) [Short x] [Numeric x] :
    x.toDyadic = Surreal.mk x := by
  sorry

theorem equiv_toIGame_iff_toDyadic_eq {x : IGame} [Short x] [Numeric x] {y : Dyadic} :
    x ≈ y ↔ x.toDyadic = y := by
  sorry

theorem toIGame_equiv_iff_eq_toDyadic {x : IGame} [Short x] [Numeric x] {y : Dyadic} :
    (y : IGame) ≈ x ↔ y = x.toDyadic := by
  sorry

@[simp]
theorem toDyadic_toIGame (x : Dyadic) : toDyadic x = x := by
  sorry

@[simp]
theorem toDyadic_zero : toDyadic 0 = 0 := by
  sorry

@[simp]
theorem toDyadic_one : toDyadic 1 = 1 := by
  sorry

@[simp]
theorem toDyadic_half : toDyadic ½ = .half := by
  sorry

@[simp]
theorem toDyadic_natCast (n : ℕ) : toDyadic n = n := by
  sorry

@[simp]
theorem toDyadic_ofNat (n : ℕ) [n.AtLeastTwo] : toDyadic ofNat(n) = n := by
  sorry

@[simp]
theorem toDyadic_intCast (n : ℤ) : toDyadic n = n := by
  sorry

@[simp]
theorem toDyadic_neg (x : IGame) [Short x] [Numeric x] : toDyadic (-x) = -toDyadic x := by
  sorry

@[simp]
theorem toDyadic_add (x y : IGame) [Short x] [Numeric x] [Short y] [Numeric y] :
    toDyadic (x + y) = toDyadic x + toDyadic y := by
  sorry

@[simp]
theorem toDyadic_sub (x y : IGame) [Short x] [Numeric x] [Short y] [Numeric y] :
    toDyadic (x - y) = toDyadic x - toDyadic y := by
  sorry

@[simp]
theorem toDyadic_mul (x y : IGame) [Short x] [Numeric x] [Short y] [Numeric y] :
    toDyadic (x * y) = toDyadic x * toDyadic y := by
  sorry

end IGame
end
