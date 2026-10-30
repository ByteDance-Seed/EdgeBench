/-
Copyright (c) 2025 Violeta Hernández Palacios. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Violeta Hernández Palacios, Reid Barton, Mario Carneiro, Isabel Longbottom, Kim Morrison,
Apurva Nakade, Yuyang Zhao
-/
module

public import CombinatorialGames.Game.Classes
public import Mathlib.Algebra.CharZero.Defs
public import Mathlib.Algebra.Order.Monoid.Defs

import Mathlib.Algebra.Order.Ring.Cast
import Mathlib.Tactic.Abel

/-!
# Combinatorial games

In this file we construct the quotient of games `IGame` under equivalence, and prove that it forms
an `OrderedAddCommGroup`. We take advantage of this structure to prove two particularly tedious
theorems on `IGame`, namely `IGame.mul_add_equiv` and `IGame.mul_assoc_equiv`.

It might be tempting to write `mk (x * y)` as `mk x * mk y`, but the latter is not well-defined, as
there exist `x₁ ≈ x₂` and `y₁ ≈ y₂` with `x₁ * y₁ ≉ x₂ * y₂`. See
`CombinatorialGames.Counterexamples.Multiplication` for a proof.
-/

universe u

@[expose] public noncomputable section

open IGame Set Pointwise

/-- Games up to equivalence.

If `x` and `y` are combinatorial games (`IGame`), we say that `x ≈ y` when both `x ≤ y` and `y ≤ x`.
Broadly, this means neither player has a preference in playing either game, as a component of a
larger game. This is the standard meaning of `x = y` in the literature, though it is not a strict
equality, e.g. `{0, 1 | 0}` and `{1 | 0}` are equivalent, but not identical as the former has an
extra move for Left.

In particular, note that a `Game` has no well-defined notion of left and right options. This means
you should prefer `IGame` when analyzing specific games. -/
def Game : Type (u + 1) :=
  Antisymmetrization IGame (· ≤ ·)

namespace Game

/-- The quotient map from `IGame` into `Game`. -/
def mk (x : IGame) : Game := Quotient.mk _ x
theorem mk_eq_mk {x y : IGame} : mk x = mk y ↔ x ≈ y := by
  sorry

alias ⟨_, mk_eq⟩ := mk_eq_mk

@[cases_eliminator]
theorem ind {motive : Game → Prop} (mk : ∀ y, motive (mk y)) (x : Game) : motive x := by
  sorry

/-- Choose an element of the equivalence class using the axiom of choice. -/
@[no_expose] def out (x : Game) : IGame := Quotient.out x
@[simp] theorem out_eq (x : Game) : mk x.out = x := by
  sorry

theorem mk_out_equiv (x : IGame) : (mk x).out ≈ x := by
  sorry
theorem equiv_mk_out (x : IGame) : x ≈ (mk x).out := by
  sorry

/-- Construct a `Game` from its left and right sets.

Note that although this function is well-defined, this function isn't injective, nor do equivalence
classes in `Game` have a canonical representative. -/
instance : OfSets Game.{u} fun _ ↦ True where
  ofSets st _ := mk !{fun p ↦ out '' (st p)}

theorem mk_ofSets' (st : Player → Set IGame.{u}) [Small.{u} (st left)] [Small.{u} (st right)] :
    mk !{st} = !{fun p ↦ mk '' st p} := by
  sorry

@[simp]
theorem mk_ofSets (s t : Set IGame.{u}) [Small.{u} s] [Small.{u} t] :
    mk !{s | t} = !{mk '' s | mk '' t} := by
  sorry

private theorem ofSets_cases (s t : Set Game.{u}) [Small.{u} s] [Small.{u} t] :
    !{s | t} = mk !{out '' s | out '' t} := by
  sorry

instance : Zero Game := ⟨mk 0⟩
instance : One Game := ⟨mk 1⟩
instance : Add Game := ⟨Quotient.map₂ _ @add_congr⟩
instance : Neg Game := ⟨Quotient.map _ @neg_congr⟩
instance : PartialOrder Game := inferInstanceAs (PartialOrder (Antisymmetrization ..))
instance : Inhabited Game := ⟨0⟩

instance : AddCommGroupWithOne Game where
  zero_add := by rintro ⟨x⟩; exact congr(mk $(zero_add _))
  add_zero := by rintro ⟨x⟩; exact congr(mk $(add_zero _))
  add_comm := by rintro ⟨x⟩ ⟨y⟩; exact congr(mk $(add_comm _ _))
  add_assoc := by rintro ⟨x⟩ ⟨y⟩ ⟨z⟩; exact congr(mk $(add_assoc _ _ _))
  neg_add_cancel := by rintro ⟨a⟩; exact mk_eq (neg_add_equiv _)
  nsmul := nsmulRec
  zsmul := zsmulRec

instance : IsOrderedAddMonoid Game where
  add_le_add_left := by rintro ⟨a⟩ ⟨b⟩ h ⟨c⟩; exact add_le_add_left (α := IGame) h _

instance : RatCast Game where
  ratCast q := mk q

@[simp] theorem mk_zero : mk 0 = 0 := by
  sorry
@[simp] theorem mk_one : mk 1 = 1 := by
  sorry
@[simp] theorem mk_add (x y : IGame) : mk (x + y) = mk x + mk y := by
  sorry
@[simp] theorem mk_neg (x : IGame) : mk (-x) = -mk x := by
  sorry
@[simp] theorem mk_sub (x y : IGame) : mk (x - y) = mk x - mk y := by
  sorry

theorem mk_mulOption (x y a b : IGame) :
    mk (mulOption x y a b) = mk (a * y) + mk (x * b) - mk (a * b) := by
  sorry

@[simp] theorem mk_le_mk {x y : IGame} : mk x ≤ mk y ↔ x ≤ y := by
  sorry
@[simp] theorem mk_lt_mk {x y : IGame} : mk x < mk y ↔ x < y := by
  sorry
@[simp] theorem mk_fuzzy_mk {x y : IGame} : mk x ‖ mk y ↔ x ‖ y := by
  sorry

@[simp, norm_cast]
theorem mk_natCast : ∀ n : ℕ, mk n = n
  := by
  sorry

@[simp, norm_cast]
theorem mk_intCast (n : ℤ) : mk n = n := by
  sorry

@[simp, norm_cast] theorem mk_ratCast (q : ℚ) : mk q = q := by
  sorry
@[simp, norm_cast] theorem ratCast_neg (q : ℚ) : ((-q : ℚ) : Game) = -q := by
  sorry

theorem zero_def : (0 : Game) = !{fun _ ↦ ∅} := by
  sorry
theorem one_def : (1 : Game) = !{{0} | ∅} := by
  sorry

instance : ZeroLEOneClass Game where
  zero_le_one := zero_le_one (α := IGame)

instance : NeZero (1 : Game) where
  out := by apply ne_of_gt; exact IGame.zero_lt_one

instance : Nontrivial Game := ⟨_, _, zero_ne_one⟩
instance : CharZero Game := AddMonoidWithOne.toCharZero

theorem mk_mul_add (x y z : IGame) : mk (x * (y + z)) = mk (x * y) + mk (x * z) := by
  sorry

theorem mk_mul_sub (x y z : IGame) : mk (x * (y - z)) = mk (x * y) - mk (x * z) := by
  sorry

theorem mk_add_mul (x y z : IGame) : mk ((x + y) * z) = mk (x * z) + mk (y * z) := by
  sorry

theorem mk_sub_mul (x y z : IGame) : mk ((x - y) * z) = mk (x * z) - mk (y * z) := by
  sorry

theorem mk_mul_assoc (x y z : IGame) : mk (x * y * z) = mk (x * (y * z)) := by
  sorry

theorem lf_ofSets_of_mem_left {s t : Set Game.{u}} [Small.{u} s] [Small.{u} t] {x : Game.{u}}
    (h : x ∈ s) : x ⧏ !{s | t} := by
  sorry

theorem ofSets_lf_of_mem_right {s t : Set Game.{u}} [Small.{u} s] [Small.{u} t] {x : Game.{u}}
    (h : x ∈ t) : !{s | t} ⧏ x := by
  sorry

end Game

namespace IGame

protected theorem sub_le_iff_le_add {x y z : IGame} : x - z ≤ y ↔ x ≤ y + z := by
  sorry

protected theorem le_sub_iff_add_le {x y z : IGame} : x ≤ z - y ↔ x + y ≤ z := by
  sorry

protected theorem sub_lt_iff_lt_add {x y z : IGame} : x - z < y ↔ x < y + z := by
  sorry

protected theorem lt_sub_iff_add_lt {x y z : IGame} : x < z - y ↔ x + y < z := by
  sorry

protected theorem sub_nonneg {x y : IGame} : 0 ≤ x - y ↔ y ≤ x := by
  sorry

protected theorem sub_nonpos {x y : IGame} : x - y ≤ 0 ↔ x ≤ y := by
  sorry

protected theorem sub_pos {x y : IGame} : 0 < x - y ↔ y < x := by
  sorry

protected theorem sub_neg {x y : IGame} : x - y < 0 ↔ x < y := by
  sorry

theorem mul_add_equiv (x y z : IGame) : x * (y + z) ≈ x * y + x * z := by
  sorry

theorem mul_sub_equiv (x y z : IGame) : x * (y - z) ≈ x * y - x * z := by
  sorry

theorem add_mul_equiv (x y z : IGame) : (x + y) * z ≈ x * z + y * z := by
  sorry

theorem sub_mul_equiv (x y z : IGame) : (x - y) * z ≈ x * z - y * z := by
  sorry

theorem mul_assoc_equiv (x y z : IGame) : x * y * z ≈ x * (y * z) := by
  sorry

@[simp, norm_cast]
theorem natCast_le {m n : ℕ} : (m : IGame) ≤ n ↔ m ≤ n := by
  sorry

@[simp, norm_cast]
theorem natCast_lt {m n : ℕ} : (m : IGame) < n ↔ m < n := by
  sorry

@[simp]
theorem natCast_nonneg (n : ℕ) : 0 ≤ (n : IGame) := by
  sorry

theorem natCast_strictMono : StrictMono ((↑) : ℕ → IGame) := by
  sorry

instance : CharZero IGame where
  cast_injective := natCast_strictMono.injective

@[simp, norm_cast]
theorem natCast_equiv {m n : ℕ} : (m : IGame) ≈ n ↔ m = n := by
  sorry

@[simp, norm_cast]
theorem intCast_le {m n : ℤ} : (m : IGame) ≤ n ↔ m ≤ n := by
  sorry

@[simp, norm_cast]
theorem intCast_lt {m n : ℤ} : (m : IGame) < n ↔ m < n := by
  sorry

theorem intCast_strictMono : StrictMono ((↑) : ℤ → IGame) := by
  sorry

@[simp, norm_cast]
theorem intCast_inj {m n : ℤ} : (m : IGame) = n ↔ m = n := by
  sorry

@[simp, norm_cast]
theorem intCast_equiv {m n : ℤ} : (m : IGame) ≈ n ↔ m = n := by
  sorry

theorem intCast_add_equiv (m n : ℤ) : ((m + n : ℤ) : IGame) ≈ m + n := by
  sorry

theorem intCast_sub_equiv (m n : ℤ) : ((m - n : ℤ) : IGame) ≈ m - n := by
  sorry

@[simp, norm_cast]
theorem zero_lt_intCast {n : ℤ} : 0 < (n : IGame) ↔ 0 < n := by
  sorry

@[simp, norm_cast]
theorem intCast_lt_zero {n : ℤ} : (n : IGame) < 0 ↔ n < 0 := by
  sorry

@[simp, norm_cast]
theorem zero_le_intCast {n : ℤ} : 0 ≤ (n : IGame) ↔ 0 ≤ n := by
  sorry

@[simp, norm_cast]
theorem intCast_le_zero {n : ℤ} : (n : IGame) ≤ 0 ↔ n ≤ 0 := by
  sorry

namespace Impartial
variable (x y : IGame) [hx : Impartial x] [hy : Impartial y]

@[simp]
theorem neg_mk : -Game.mk x = Game.mk x := by
  sorry

@[simp]
theorem sub_mk (x : Game) : x - Game.mk y = x + Game.mk y := by
  sorry

@[simp]
theorem mk_add_self : Game.mk x + Game.mk x = 0 := by
  sorry

-- TODO: move these four lemmas earlier:

theorem add_self_equiv (x : IGame) [Impartial x] : x + x ≈ 0 := by
  sorry

variable {x y}

omit hx in
/-- This lemma doesn't require `x` to be impartial. -/
theorem equiv_iff_add_equiv_zero : x ≈ y ↔ x + y ≈ 0 := by
  sorry

omit hy in
/-- This lemma doesn't require `y` to be impartial. -/
theorem equiv_iff_add_equiv_zero' : x ≈ y ↔ x + y ≈ 0 := by
  sorry

theorem fuzzy_iff_add_fuzzy_zero : x ‖ y ↔ x + y ‖ 0 := by
  sorry

end Impartial
end IGame
end
