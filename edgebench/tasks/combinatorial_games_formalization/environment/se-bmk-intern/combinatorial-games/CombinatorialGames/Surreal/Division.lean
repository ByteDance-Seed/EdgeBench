/-
Copyright (c) 2025 Violeta Hernández Palacios. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Violeta Hernández Palacios, Theodore Hwa
-/
module

public import CombinatorialGames.Surreal.Multiplication
public import Mathlib.Algebra.Field.Defs
public import Mathlib.Algebra.Order.Ring.Unbundled.Rat

import Mathlib.Algebra.Order.Field.Basic
import Mathlib.Data.Rat.Cast.Order
import Mathlib.Tactic.Abel
import Mathlib.Tactic.Ring

/-!
# Surreal division

In this file, we prove that if `x` is a positive numeric game, then `x⁻¹` (defined in
`Mathlib.SetTheory.Game.IGame`) is a number and is a multiplicative inverse for `x`. We use that
to define the field structure on `Surreal`.

This is Theorem 1.10 in ONAG, and we follow the broad strokes of the proof. We prove
by simultaneous induction that if `x` is positive and numeric, then (ii) `x⁻¹` is numeric, and (iv)
`x * x⁻¹ ≈ 1`. We do this by showing the inductive hypothesis implies that (i) `x * y < 1` for
`y ∈ x⁻¹ᴸ` and `1 < x * y` for `y ∈ x⁻¹ᴿ`, and that (iv) `y < 1` for
`y ∈ (x * x⁻¹)ᴸ` and `1 < y` for `y ∈ (x * x⁻¹ᴿ)`.

An important difference is that Conway assumes that `x` has no negative left options, while we don't
make use of this assumption. This is because our definition of the inverse is tweaked to ensure that
only positive left options of `x` generate the options for `x⁻¹`. To make sure the induction checks
out, we require two small extra arithmetic lemmas `mulOption_le` and `le_mulOption`.

Once we have defined the inverse for positive `x`, it is extended in the obvious way to negative
numbers.
-/

universe u

open IGame

instance {x y : IGame} [Numeric x] [Numeric y⁻¹] : Numeric (x / y) := .mul ..

instance {x y a : IGame} [Numeric x] [Numeric y] [Numeric y⁻¹] [Numeric a] :
    Numeric (invOption x y a) :=
  .mul ..

theorem inv_pos' {x : IGame} [Numeric x⁻¹] (hx : 0 < x) : 0 < x⁻¹ := by
  sorry

theorem mk_div' (x y : IGame) [Numeric x] [Numeric y⁻¹] :
    Surreal.mk (x / y) = Surreal.mk x * Surreal.mk y⁻¹ := by
  sorry

/-! ### Arithmetic lemmas -/

lemma one_neg_mul_invOption (x : IGame) {y : IGame} (hy : y * y⁻¹ ≈ 1) (a : IGame)
    [Numeric x] [Numeric y] [Numeric y⁻¹] [Numeric a] :
    1 - x * invOption x y a ≈ (1 - x * a) * (y - x) / y := by
  sorry

lemma mulOption_self_inv (x : IGame) {y : IGame} (hy : y * y⁻¹ ≈ 1) (a : IGame)
    [Numeric x] [Numeric x⁻¹] [Numeric y] [Numeric y⁻¹] [Numeric a] :
    mulOption x x⁻¹ y a ≈ 1 + (x⁻¹ - invOption x y a) * y := by
  sorry

lemma mulOption_le (x y : IGame) {a b : IGame} [Numeric y] [Numeric a] [Numeric b]
    (ha : a ≤ 0) (hb : b ≤ y) : mulOption x y a b ≤ x * b := by
  sorry

theorem le_mulOption (x y : IGame) {a b : IGame} [Numeric y] [Numeric a] [Numeric b]
    (ha : a ≤ 0) (hb : y ≤ b) : x * b ≤ mulOption x y a b := by
  sorry

/-! ### Inductive proof -/

lemma numeric_option_inv {x : IGame} [Numeric x] (hx : 0 < x)
    (hl : ∀ y ∈ xᴸ, 0 < y → Numeric y⁻¹) (hr : ∀ y ∈ xᴿ, Numeric y⁻¹) :
    (∀ p, ∀ y ∈ x⁻¹.moves p, Numeric y) := by
  sorry

lemma mul_inv_option_mem {x : IGame} [Numeric x] (hx : 0 < x)
    (hl : ∀ y ∈ xᴸ, 0 < y → Numeric y⁻¹) (hr : ∀ y ∈ xᴿ, Numeric y⁻¹)
    (hl' : ∀ y ∈ xᴸ, 0 < y → y * y⁻¹ ≈ 1) (hr' : ∀ y ∈ xᴿ, y * y⁻¹ ≈ 1) :
    (∀ y ∈ x⁻¹ᴸ, x * y < 1) ∧ (∀ y ∈ x⁻¹ᴿ, 1 < x * y) := by
  sorry

lemma numeric_inv {x : IGame} [Numeric x] (hx : 0 < x)
    (hl : ∀ y ∈ xᴸ, 0 < y → Numeric y⁻¹) (hr : ∀ y ∈ xᴿ, Numeric y⁻¹)
    (hl' : ∀ y ∈ xᴸ, 0 < y → y * y⁻¹ ≈ 1) (hr' : ∀ y ∈ xᴿ, y * y⁻¹ ≈ 1) :
    Numeric x⁻¹ := by
  sorry

lemma option_mul_inv_lt {x : IGame} [Numeric x] (hx : 0 < x)
    (hl : ∀ y ∈ xᴸ, 0 < y → Numeric y⁻¹) (hr : ∀ y ∈ xᴿ, Numeric y⁻¹)
    (hl' : ∀ y ∈ xᴸ, 0 < y → y * y⁻¹ ≈ 1) (hr' : ∀ y ∈ xᴿ, y * y⁻¹ ≈ 1) :
    (∀ y ∈ (x * x⁻¹)ᴸ, y < 1) ∧ (∀ y ∈ (x * x⁻¹)ᴿ, 1 < y) := by
  sorry

lemma mul_inv_self {x : IGame} [Numeric x] (hx : 0 < x)
    (hl : ∀ y ∈ xᴸ, 0 < y → Numeric y⁻¹) (hr : ∀ y ∈ xᴿ, Numeric y⁻¹)
    (hl' : ∀ y ∈ xᴸ, 0 < y → y * y⁻¹ ≈ 1) (hr' : ∀ y ∈ xᴿ, y * y⁻¹ ≈ 1) :
    x * x⁻¹ ≈ 1 := by
  sorry

theorem main {x : IGame} [Numeric x] (hx : 0 < x) : Numeric x⁻¹ ∧ x * x⁻¹ ≈ 1 := by
  sorry

/-! ### Instances and corollaries -/

public section

namespace IGame.Numeric

protected instance inv (x : IGame) [Numeric x] : Numeric x⁻¹ := by
  obtain h | h | h := Numeric.lt_or_equiv_or_gt x 0
  · rw [← IGame.zero_lt_neg] at h
    simpa using (main h).1
  · simp [inv_of_equiv_zero h]
  · exact (main h).1

protected instance div (x y : IGame) [Numeric x] [Numeric y] : Numeric (x / y) := .mul ..
protected instance ratCast (q : ℚ) : Numeric q := .div ..

protected instance invOption (x y a : IGame) [Numeric x] [Numeric y] [Numeric a] :
    Numeric (invOption x y a) :=
  .div ..

protected theorem mul_inv_cancel {x : IGame} [Numeric x] (hx : ¬ x ≈ 0) : x * x⁻¹ ≈ 1 := by
  sorry

protected theorem inv_mul_cancel {x : IGame} [Numeric x] (hx : ¬ x ≈ 0) : x⁻¹ * x ≈ 1 := by
  sorry

theorem inv_congr {x y : IGame} [Numeric x] [Numeric y] (he : x ≈ y) : x⁻¹ ≈ y⁻¹ := by
  sorry

theorem div_congr_left {x₁ x₂ y : IGame} [Numeric x₁] [Numeric x₂] [Numeric y] (he : x₁ ≈ x₂) :
    x₁ / y ≈ x₂ / y := by
  sorry

theorem div_congr_right {x y₁ y₂ : IGame} [Numeric x] [Numeric y₁] [Numeric y₂] (he : y₁ ≈ y₂) :
    x / y₁ ≈ x / y₂ := by
  sorry

theorem div_congr {x₁ x₂ y₁ y₂ : IGame} [Numeric x₁] [Numeric x₂] [Numeric y₁] [Numeric y₂]
    (hx : x₁ ≈ x₂) (hy : y₁ ≈ y₂) : x₁ / y₁ ≈ x₂ / y₂ := by
  sorry

end IGame.Numeric

namespace Surreal

noncomputable instance : Field Surreal where
  inv := Quotient.map (fun x ↦ ⟨x⁻¹, by infer_instance⟩) fun _ _ ↦ Numeric.inv_congr
  mul_inv_cancel := by rintro ⟨a⟩ h; exact mk_eq (Numeric.mul_inv_cancel (mk_eq_mk.not.1 h))
  inv_zero := by change mk 0⁻¹ = _; simp
  qsmul := _
  nnqsmul := _

@[simp] theorem mk_inv (x : IGame) [Numeric x] : mk x⁻¹ = (mk x)⁻¹ := by
  sorry
@[simp] theorem mk_div (x y : IGame) [Numeric x] [Numeric y] : mk (x / y) = mk x / mk y := by
  sorry

@[simp]
theorem mk_ratCast (q : ℚ) : mk q = q := by
  sorry

@[simp]
theorem toGame_ratCast (q : ℚ) : toGame q = q := by
  sorry

end Surreal

namespace IGame
namespace Numeric

@[simp]
protected theorem inv_pos {x : IGame} [Numeric x] : 0 < x⁻¹ ↔ 0 < x := by
  sorry

@[simp]
protected theorem inv_neg {x : IGame} [Numeric x] : x⁻¹ < 0 ↔ x < 0 := by
  sorry

@[simp]
protected theorem inv_nonneg {x : IGame} [Numeric x] : 0 ≤ x⁻¹ ↔ 0 ≤ x := by
  sorry

@[simp]
protected theorem inv_nonpos {x : IGame} [Numeric x] : x⁻¹ ≤ 0 ↔ x ≤ 0 := by
  sorry

theorem inv_equiv_of_mul_eq_one {x y : IGame} [Numeric x] [Numeric y]
    (he : x * y ≈ 1) : x⁻¹ ≈ y := by
  sorry

theorem equiv_inv_of_mul_eq_one {x y : IGame} [Numeric x] [Numeric y]
    (he : x * y ≈ 1) : x ≈ y⁻¹ := by
  sorry

protected theorem lt_div_iff {x y z : IGame} [Numeric x] [Numeric y] [Numeric z] (hz : 0 < z) :
    x < y / z ↔ x * z < y := by
  sorry

protected theorem lt_div_iff' {x y z : IGame} [Numeric x] [Numeric y] [Numeric z] (hz : 0 < z) :
    x < y / z ↔ z * x < y := by
  sorry

protected theorem div_lt_iff {x y z : IGame} [Numeric x] [Numeric y] [Numeric z] (hy : 0 < y) :
    x / y < z ↔ x < z * y := by
  sorry

protected theorem div_lt_iff' {x y z : IGame} [Numeric x] [Numeric y] [Numeric z] (hz : 0 < y) :
    x / y < z ↔ x < y * z := by
  sorry

protected theorem lt_div_iff_of_neg {x y z : IGame} [Numeric x] [Numeric y] [Numeric z]
    (hz : z < 0) : x < y / z ↔ y < x * z := by
  sorry

protected theorem div_lt_iff_of_neg {x y z : IGame} [Numeric x] [Numeric y] [Numeric z]
    (hy : y < 0) : x / y < z ↔ z * y < x := by
  sorry

end Numeric

@[simp, norm_cast]
theorem ratCast_le {m n : ℚ} : (m : IGame) ≤ n ↔ m ≤ n := by
  sorry

@[simp, norm_cast]
theorem ratCast_lt {m n : ℚ} : (m : IGame) < n ↔ m < n := by
  sorry

theorem ratCast_strictMono : StrictMono ((↑) : ℚ → IGame) := by
  sorry

@[simp, norm_cast]
theorem ratCast_inj {m n : ℚ} : (m : IGame) = n ↔ m = n := by
  sorry

@[simp, norm_cast]
theorem ratCast_equiv {m n : ℚ} : (m : IGame) ≈ n ↔ m = n := by
  sorry

theorem ratCast_natCast_equiv (n : ℕ) : ((n : ℚ) : IGame) ≈ n := by
  sorry

theorem ratCast_intCast_equiv (n : ℤ) : ((n : ℚ) : IGame) ≈ n := by
  sorry

theorem ratCast_add_equiv (m n : ℚ) : ((m + n : ℚ) : IGame) ≈ m + n := by
  sorry

theorem ratCast_sub_equiv (m n : ℚ) : ((m - n : ℚ) : IGame) ≈ m - n := by
  sorry

theorem ratCast_mul_equiv (m n : ℚ) : ((m * n : ℚ) : IGame) ≈ m * n := by
  sorry

theorem ratCast_inv_equiv (m : ℚ) : ((m⁻¹ : ℚ) : IGame) ≈ m⁻¹ := by
  sorry

theorem ratCast_div_equiv (m n : ℚ) : ((m / n : ℚ) : IGame) ≈ m / n := by
  sorry

@[simp, norm_cast]
theorem zero_lt_ratCast {q : ℚ} : 0 < (q : IGame) ↔ 0 < q := by
  sorry

@[simp, norm_cast]
theorem ratCast_lt_zero {q : ℚ} : (q : IGame) < 0 ↔ q < 0 := by
  sorry

@[simp, norm_cast]
theorem zero_le_ratCast {q : ℚ} : 0 ≤ (q : IGame) ↔ 0 ≤ q := by
  sorry

@[simp, norm_cast]
theorem ratCast_le_zero {q : ℚ} : (q : IGame) ≤ 0 ↔ q ≤ 0 := by
  sorry

private theorem equiv_ratCast_of_mem_move_inv_natCast {n : ℕ} :
    (∀ p, ∀ x ∈ moves.{u} p n⁻¹, ∃ q : ℚ, x ≈ q) := by
  sorry

private theorem equiv_ratCast_of_mem_move_ratCast {q : ℚ} :
    (∀ x ∈ (q : IGame.{u})ᴸ, ∃ r : ℚ, x ≈ r) ∧ (∀ x ∈ (q : IGame.{u})ᴿ, ∃ r : ℚ, x ≈ r) := by
  sorry

/-- Every left option of a rational number is equivalent to a smaller rational number. -/
theorem equiv_ratCast_of_mem_leftMoves_ratCast {q : ℚ} {x : IGame} (hx : x ∈ qᴸ) :
    ∃ r : ℚ, r < q ∧ x ≈ r := by
  sorry

/-- Every right option of a rational number is equivalent to a larger rational number. -/
theorem equiv_ratCast_of_mem_rightMoves_ratCast {q : ℚ} {x : IGame} (hx : x ∈ qᴿ) :
    ∃ r : ℚ, q < r ∧ x ≈ r := by
  sorry

@[simp]
theorem mk_half : Surreal.mk ½ = 2⁻¹ := by
  sorry

end IGame

namespace Game

@[simp, norm_cast]
theorem ratCast_le {m n : ℚ} : (m : Game) ≤ n ↔ m ≤ n := by
  sorry

@[simp, norm_cast]
theorem ratCast_lt {m n : ℚ} : (m : Game) < n ↔ m < n := by
  sorry

theorem ratCast_strictMono : StrictMono ((↑) : ℚ → Game) := by
  sorry

@[simp, norm_cast]
theorem ratCast_inj {m n : ℚ} : (m : Game) = n ↔ m = n := by
  sorry

@[simp, norm_cast]
theorem ratCast_natCast (n : ℕ) : ((n : ℚ) : Game) = n := by
  sorry

@[simp, norm_cast]
theorem ratCast_intCast (n : ℤ) : ((n : ℚ) : Game) = n := by
  sorry

@[simp, norm_cast]
theorem ratCast_add (m n : ℚ) : ((m + n : ℚ) : Game) = m + n := by
  sorry

@[simp, norm_cast]
theorem ratCast_sub (m n : ℚ) : ((m - n : ℚ) : Game) = m - n := by
  sorry

@[simp, norm_cast]
theorem zero_lt_ratCast {q : ℚ} : 0 < (q : Game) ↔ 0 < q := by
  sorry

@[simp, norm_cast]
theorem ratCast_lt_zero {q : ℚ} : (q : Game) < 0 ↔ q < 0 := by
  sorry

@[simp, norm_cast]
theorem zero_le_ratCast {q : ℚ} : 0 ≤ (q : Game) ↔ 0 ≤ q := by
  sorry

@[simp, norm_cast]
theorem ratCast_le_zero {q : ℚ} : (q : Game) ≤ 0 ↔ q ≤ 0 := by
  sorry

end Game
