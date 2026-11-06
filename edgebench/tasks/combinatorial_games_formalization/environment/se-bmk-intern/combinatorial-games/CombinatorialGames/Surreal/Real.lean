/-
Copyright (c) 2025 Violeta Hernández Palacios. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Violeta Hernández Palacios
-/
module

public import CombinatorialGames.Surreal.Dyadic
public import Mathlib.Algebra.Order.Hom.Ring
public import Mathlib.Data.Real.Archimedean

/-!
# Real numbers as games

We define the function `Real.toIGame`, casting a real number to its Dedekind cut, and prove that
it's an order embedding. We then define the `Game` and `Surreal` versions of this map, and prove
that they are ring and field homomorphisms respectively.

## TODO

Prove that every real number has birthday at most `ω`.
-/

universe u

open IGame

@[expose] public noncomputable section

theorem exists_dyadic_btwn {K : Type*} [Field K] [LinearOrder K] [IsStrictOrderedRing K]
    [Archimedean K] {x y : K} (h : x < y) : ∃ q : Dyadic, x < q.toRat ∧ q.toRat < y := by
  sorry

namespace Real

/-! ### `ℝ` to `IGame` -/

/-- The canonical map from `ℝ` to `IGame`, sending a real number to its Dedekind cut of dyadic
rationals. -/
@[coe, match_pattern] def toIGame (x : ℝ) : IGame.{u} :=
  !{(↑) '' {q : Dyadic | q.toRat < x} | (↑) '' {q : Dyadic | x < q.toRat}}

instance : Coe ℝ IGame := ⟨toIGame⟩

instance Numeric.toIGame (x : ℝ) : Numeric x := by
  rw [Real.toIGame]
  apply Numeric.mk
  · simp only [leftMoves_ofSets, rightMoves_ofSets, Set.forall_mem_image, Set.mem_setOf]
    intro x hx y hy
    simpa using hx.trans hy
  · aesop (add simp [Numeric.dyadic])

@[simp]
theorem leftMoves_toIGame (x : ℝ) : xᴸ = (↑) '' {q : Dyadic | q.toRat < x} := by
  sorry

@[simp]
theorem rightMoves_toIGame (x : ℝ) : xᴿ = (↑) '' {q : Dyadic | x < q.toRat} := by
  sorry

theorem forall_leftMoves_toIGame {P : IGame → Prop} {x : ℝ} :
    (∀ y ∈ xᴸ, P y) ↔ ∀ q : Dyadic, q.toRat < x → P q := by
  sorry

theorem exists_leftMoves_toIGame {P : IGame → Prop} {x : ℝ} :
    (∃ y ∈ xᴸ, P y) ↔ ∃ q : Dyadic, q.toRat < x ∧ P q := by
  sorry

theorem forall_rightMoves_toIGame {P : IGame → Prop} {x : ℝ} :
    (∀ y ∈ xᴿ, P y) ↔ ∀ q : Dyadic, x < q.toRat → P q := by
  sorry

theorem exists_rightMoves_toIGame {P : IGame → Prop} {x : ℝ} :
    (∃ y ∈ xᴿ, P y) ↔ ∃ q : Dyadic, x < q.toRat ∧ P q := by
  sorry

theorem mem_leftMoves_toIGame_of_lt {q : Dyadic} {x : ℝ} (h : q.toRat < x) :
    (q : IGame) ∈ xᴸ := by
  sorry

theorem mem_rightMoves_toIGame_of_lt {q : Dyadic} {x : ℝ} (h : x < q.toRat) :
    (q : IGame) ∈ xᴿ := by
  sorry

/-- `Real.toIGame` as an `OrderEmbedding`. -/
@[simps!]
def toIGameEmbedding : ℝ ↪o IGame := by
  refine .ofStrictMono toIGame fun x y h ↦ ?_
  obtain ⟨q, hx, hy⟩ := exists_dyadic_btwn h
  trans (q : IGame)
  · apply Numeric.lt_right
    simpa [toIGame]
  · apply Numeric.left_lt
    simpa [toIGame]

@[simp, norm_cast]
theorem toIGame_le_iff {x y : ℝ} : (x : IGame) ≤ y ↔ x ≤ y := by
  sorry

@[simp, norm_cast]
theorem toIGame_lt_iff {x y : ℝ} : (x : IGame) < y ↔ x < y := by
  sorry

@[simp, norm_cast]
theorem toIGame_equiv_iff {x y : ℝ} : (x : IGame) ≈ y ↔ x = y := by
  sorry

@[simp, norm_cast]
theorem toIGame_inj {x y : ℝ} : (x : IGame) = y ↔ x = y := by
  sorry

@[simp, norm_cast]
theorem toIGame_neg (x : ℝ) : toIGame (-x) = -toIGame x := by
  sorry

theorem toIGame_ratCast_equiv (q : ℚ) : toIGame q ≈ q := by
  sorry

theorem toIGame_dyadic_equiv (q : Dyadic) : toIGame q.toRat ≈ q := by
  sorry

theorem toIGame_natCast_equiv (n : ℕ) : toIGame n ≈ n := by
  sorry

theorem toIGame_intCast_equiv (n : ℤ) : toIGame n ≈ n := by
  sorry

theorem toIGame_zero_equiv : toIGame 0 ≈ 0 := by
  sorry
theorem toIGame_one_equiv : toIGame 1 ≈ 1 := by
  sorry

@[simp, norm_cast]
theorem ratCast_lt_toIGame {q : ℚ} {x : ℝ} : q < (x : IGame) ↔ q < x := by
  sorry
@[simp, norm_cast]
theorem toIGame_lt_ratCast {q : ℚ} {x : ℝ} : (x : IGame) < q ↔ x < q := by
  sorry

@[simp, norm_cast]
theorem ratCast_le_toIGame {q : ℚ} {x : ℝ} : q ≤ (x : IGame) ↔ q ≤ x := by
  sorry
@[simp, norm_cast]
theorem toIGame_le_ratCast {q : ℚ} {x : ℝ} : (x : IGame) ≤ q ↔ x ≤ q := by
  sorry

@[simp, norm_cast]
theorem ratCast_equiv_toIGame {q : ℚ} {x : ℝ} : (q : IGame) ≈ (x : IGame) ↔ q = x := by
  sorry
@[simp, norm_cast]
theorem toIGame_equiv_ratCast {q : ℚ} {x : ℝ} : (x : IGame) ≈ q ↔ x = q := by
  sorry

theorem toIGame_add_ratCast_equiv (x : ℝ) (q : ℚ) : toIGame (x + q) ≈ x + q := by
  sorry

theorem toIGame_ratCast_add_equiv (q : ℚ) (x : ℝ) : toIGame (q + x) ≈ q + x := by
  sorry

theorem toIGame_add_dyadic_equiv (x : ℝ) (q : Dyadic) : toIGame (x + q.toRat) ≈ x + q := by
  sorry

theorem toIGame_dyadic_add_equiv (q : Dyadic) (x : ℝ) : toIGame (q.toRat + x) ≈ q + x := by
  sorry

theorem toIGame_add_equiv (x y : ℝ) : toIGame (x + y) ≈ x + y := by
  sorry

theorem toIGame_sub_ratCast_equiv (x : ℝ) (q : ℚ) : toIGame (x - q) ≈ x - q := by
  sorry

theorem toIGame_ratCast_sub_equiv (q : ℚ) (x : ℝ) : toIGame (q - x) ≈ q - x := by
  sorry

theorem toIGame_sub_dyadic_equiv (x : ℝ) (q : Dyadic) : toIGame (x - q.toRat) ≈ x - q := by
  sorry

theorem toIGame_dyadic_sub_equiv (q : Dyadic) (x : ℝ) : toIGame (q.toRat - x) ≈ q - x := by
  sorry

theorem toIGame_sub_equiv (x y : ℝ) : toIGame (x - y) ≈ x - y := by
  sorry

/-! ### `ℝ` to `Game` -/

/-- The canonical map from `ℝ` to `Game`, sending a real number to its Dedekind cut. -/
@[coe, match_pattern] def toGame (x : ℝ) : Game := .mk x

instance : Coe ℝ Game := ⟨toGame⟩

@[simp] theorem _root_.Game.mk_real_toIGame (x : ℝ) : .mk x.toIGame = x.toGame := by
  sorry

theorem toGame_def (x : ℝ) :
    toGame x = !{(fun q => q.toRat) '' {q : Dyadic | q.toRat < x} |
      (fun q => q.toRat) '' {q : Dyadic | x < q.toRat}} := by
  sorry

/-- `Real.toGame` as an `OrderEmbedding`. -/
@[simps!]
def toGameEmbedding : ℝ ↪o Game :=
  .ofStrictMono toGame fun _ _ h ↦ toIGameEmbedding.strictMono h

@[simp, norm_cast]
theorem toGame_le_iff {x y : ℝ} : (x : Game) ≤ y ↔ x ≤ y := by
  sorry

@[simp, norm_cast]
theorem toGame_lt_iff {x y : ℝ} : (x : Game) < y ↔ x < y := by
  sorry

@[norm_cast]
theorem toGame_equiv_iff {x y : ℝ} : (x : Game) ≈ y ↔ x = y := by
  sorry

@[simp, norm_cast]
theorem toGame_inj {x y : ℝ} : (x : Game) = y ↔ x = y := by
  sorry

@[simp, norm_cast]
theorem toGame_ratCast (q : ℚ) : toGame q = q := by
  sorry

@[simp, norm_cast]
theorem toGame_natCast (n : ℕ) : toGame n = n := by
  sorry

@[simp, norm_cast]
theorem toGame_intCast (n : ℤ) : toGame n = n := by
  sorry

@[simp] theorem toGame_zero : toGame 0 = 0 := by
  sorry
@[simp] theorem toGame_one : toGame 1 = 1 := by
  sorry

@[simp]
theorem toGame_add (x y : ℝ) : toGame (x + y) = toGame x + toGame y := by
  sorry

@[simp]
theorem toGame_sub (x y : ℝ) : toGame (x - y) = toGame x - toGame y := by
  sorry

/-- `Real.toGame` as an `OrderAddMonoidHom`. -/
@[simps]
def toGameAddHom : ℝ →+o Game where
  toFun := toGame
  map_zero' := toGame_zero
  map_add' := toGame_add
  monotone' := toGameEmbedding.monotone

/-! ### `ℝ` to `Surreal` -/

/-- The canonical map from `ℝ` to `Surreal`, sending a real number to its Dedekind cut. -/
@[coe, match_pattern] def toSurreal (x : ℝ) : Surreal := .mk x

instance : Coe ℝ Surreal := ⟨toSurreal⟩

@[simp] theorem _root_.Surreal.mk_real_toIGame (x : ℝ) : .mk x.toIGame = x.toSurreal := by
  sorry

private theorem toSurreal_def_aux {x : ℝ} :
    ∀ y ∈ ((fun q => q.toRat) '' {q : Dyadic | q.toRat < x} : Set Surreal),
    ∀ z ∈ (fun q => q.toRat) '' {q : Dyadic | x < q.toRat}, y < z := by
  sorry

@[simp] theorem toGame_toSurreal (x : ℝ) : x.toSurreal.toGame = x.toGame := by
  sorry

theorem toSurreal_def (x : ℝ) : toSurreal x =
    !{(fun q => q.toRat) '' {q : Dyadic | q.toRat < x} |
      ((fun q => q.toRat) '' {q : Dyadic | x < q.toRat})}'(by exact toSurreal_def_aux) := by
  sorry

/-- `Real.toSurreal` as an `OrderEmbedding`. -/
@[simps!]
def toSurrealEmbedding : ℝ ↪o Surreal :=
  .ofStrictMono toSurreal fun _ _ h ↦ toIGameEmbedding.strictMono h

@[simp, norm_cast]
theorem toSurreal_le_iff {x y : ℝ} : (x : Surreal) ≤ y ↔ x ≤ y := by
  sorry

@[simp, norm_cast]
theorem toSurreal_lt_iff {x y : ℝ} : (x : Surreal) < y ↔ x < y := by
  sorry

@[norm_cast]
theorem toSurreal_equiv_iff {x y : ℝ} : (x : Surreal) ≈ y ↔ x = y := by
  sorry

@[simp, norm_cast]
theorem toSurreal_inj {x y : ℝ} : (x : Surreal) = y ↔ x = y := by
  sorry

@[simp, norm_cast]
theorem toSurreal_ratCast (q : ℚ) : toSurreal q = q := by
  sorry

@[simp, norm_cast] theorem toSurreal_natCast (n : ℕ) : toSurreal n = n := by
  sorry
@[simp] theorem toSurreal_ofNat (n : ℕ) [n.AtLeastTwo] : toSurreal ofNat(n) = n := by
  sorry
@[simp, norm_cast] theorem toSurreal_intCast (n : ℤ) : toSurreal n = n := by
  sorry

@[simp, norm_cast] theorem toSurreal_zero : toSurreal 0 = 0 := by
  sorry
@[simp, norm_cast] theorem toSurreal_one : toSurreal 1 = 1 := by
  sorry

@[simp] theorem toSurreal_eq_zero_iff {x : ℝ} : (x : Surreal) = 0 ↔ x = 0 := by
  sorry
@[simp] theorem zero_eq_toSurreal_iff {x : ℝ} : 0 = (x : Surreal) ↔ 0 = x := by
  sorry

@[simp] theorem toSurreal_eq_one_iff {x : ℝ} : (x : Surreal) = 1 ↔ x = 1 := by
  sorry
@[simp] theorem one_eq_toSurreal_iff {x : ℝ} : 1 = (x : Surreal) ↔ 1 = x := by
  sorry

@[simp] theorem toSurreal_nonneg_iff {x : ℝ} : 0 ≤ (x : Surreal) ↔ 0 ≤ x := by
  sorry
@[simp] theorem toSurreal_nonpos_iff {x : ℝ} : (x : Surreal) ≤ 0 ↔ x ≤ 0 := by
  sorry

@[simp] theorem toSurreal_pos_iff {x : ℝ} : 0 < (x : Surreal) ↔ 0 < x := by
  sorry
@[simp] theorem toSurreal_neg_iff {x : ℝ} : (x : Surreal) < 0 ↔ x < 0 := by
  sorry

@[simp]
theorem toSurreal_neg (x : ℝ) : toSurreal (-x) = -toSurreal x := by
  sorry

@[simp]
theorem toSurreal_add (x y : ℝ) : toSurreal (x + y) = x + y := by
  sorry

@[simp]
theorem toSurreal_sub (x y : ℝ) : toSurreal (x - y) = x - y := by
  sorry

@[simp]
theorem toSurreal_max (x y : ℝ) : max x y = max (toSurreal x) (toSurreal y) := by
  sorry

@[simp]
theorem toSurreal_min (x y : ℝ) : min x y = min (toSurreal x) (toSurreal y) := by
  sorry

@[simp, norm_cast]
theorem toSurreal_abs (x : ℝ) : |x| = |toSurreal x| := by
  sorry

/-! For convenience, we deal with multiplication after defining `Real.toSurreal`. -/

private theorem exists_rat_mul_btwn {a b x : ℝ} (h : a * x < b) :
    ∃ q : ℚ, a * x ≤ q * x ∧ q * x < b := by
  sorry

private theorem exists_rat_mul_btwn' {a b x : ℝ} (h : a < b * x) :
    ∃ q : ℚ, a < q * x ∧ q * x ≤ b * x := by
  sorry

private theorem toIGame_mul_le_mul {x : ℝ} {q r : ℚ} (h : x * r ≤ q * r) :
    toIGame x * r ≤ q * r := by
  sorry

private theorem toIGame_mul_le_mul' {x : ℝ} {q r : ℚ} (h : q * r ≤ x * r) :
    q * r ≤ toIGame x * r := by
  sorry

private theorem mulOption_lt_toIGame {x : ℝ} {q r s : ℚ} (h : x * s < x * q - r * q + r * s) :
    mulOption (toIGame x) q r s < toIGame.{u} (x * q) := by
  sorry

private theorem toIGame_lt_mulOption {x : ℝ} {q r s : ℚ} (h : x * q - r * q + r * s < x * s) :
    toIGame.{u} (x * q) < mulOption (toIGame x) q r s := by
  sorry

theorem toIGame_mul_ratCast_equiv (x : ℝ) (q : ℚ) : (x * q).toIGame ≈ x * q := by
  sorry

theorem toIGame_ratCast_mul_equiv (q : ℚ) (x : ℝ) : (q * x).toIGame ≈ q * x := by
  sorry

private theorem dyadic_lt_mul_toIGame' {x y : ℝ} {q : Dyadic}
    (hx : 0 < x) (hy : 0 < y) (h : q.toRat < x * y) : (q : IGame) < x * y := by
  sorry

private theorem mul_toIGame_lt_dyadic' {x y : ℝ} {q : Dyadic}
    (hx : 0 < x) (hy : 0 < y) (h : x * y < q.toRat) : x * y < (q : IGame) := by
  sorry

private theorem dyadic_lt_mul_toIGame {x y : ℝ} (q : Dyadic) (h : q.toRat < x * y) :
    (q : IGame.{u}) < x * y := by
  sorry

private theorem mul_toIGame_lt_dyadic {x y : ℝ} (q : Dyadic) (h : x * y < q.toRat) :
    x * y < (q : IGame.{u}) := by
  sorry

private theorem toSurreal_mul_ratCast (x : ℝ) (q : ℚ) : toSurreal (x * q) = x * q := by
  sorry

private theorem mulOption_toIGame_equiv {x y : ℝ} {q r : Dyadic} :
    mulOption (toIGame x) (toIGame y) q r ≈
      toIGame (q.toRat * y + x * r.toRat - q.toRat * r.toRat) := by
  sorry

theorem toIGame_mul_equiv (x y : ℝ) : (x * y).toIGame ≈ x * y := by
  sorry

@[simp, norm_cast]
theorem toSurreal_mul (x y : ℝ) : (x * y).toSurreal = x * y := by
  sorry

/-- `Real.toSurreal` as an `OrderRingHom`. -/
@[simps]
def toSurrealRingHom : ℝ →+*o Surreal where
  toFun := toSurreal
  map_zero' := toSurreal_zero
  map_one' := toSurreal_one
  map_add' := toSurreal_add
  map_mul' := toSurreal_mul
  monotone' := toSurrealEmbedding.monotone

@[simp, norm_cast]
theorem toSurreal_inv (x : ℝ) : x⁻¹.toSurreal = x.toSurreal⁻¹ := by
  sorry

@[simp, norm_cast]
theorem toSurreal_div (x y : ℝ) : (x / y).toSurreal = x / y := by
  sorry

theorem toIGame_inv_equiv (x : ℝ) : x⁻¹.toIGame ≈ x.toIGame⁻¹ := by
  sorry

theorem toIGame_div_equiv (x y : ℝ) : (x / y).toIGame ≈ x / y := by
  sorry

/-! ### Simp lemmas -/

/-! #### Dyadic -/

@[simp, norm_cast]
theorem dyadic_lt_toIGame {q : Dyadic} {x : ℝ} : q < (x : IGame) ↔ q.toRat < x := by
  sorry
@[simp, norm_cast]
theorem toIGame_lt_dyadic {q : Dyadic} {x : ℝ} : (x : IGame) < q ↔ x < q.toRat := by
  sorry

@[simp, norm_cast]
theorem dyadic_le_toIGame {q : Dyadic} {x : ℝ} : q ≤ (x : IGame) ↔ q.toRat ≤ x := by
  sorry
@[simp, norm_cast]
theorem toIGame_le_dyadic {q : Dyadic} {x : ℝ} : (x : IGame) ≤ q ↔ x ≤ q.toRat := by
  sorry

@[simp, norm_cast]
theorem dyadic_equiv_toIGame {q : Dyadic} {x : ℝ} : (q : IGame) ≈ x ↔ q.toRat = x := by
  sorry
@[simp, norm_cast]
theorem toIGame_equiv_dyadic {q : Dyadic} {x : ℝ} : (x : IGame) ≈ q ↔ x = q.toRat := by
  sorry

/-! #### ℤ -/

@[simp, norm_cast]
theorem toIGame_lt_intCast {x : ℝ} {y : ℤ} : (x : IGame) < y ↔ x < y := by
  sorry
@[simp, norm_cast]
theorem toIGame_le_intCast {x : ℝ} {y : ℤ} : (x : IGame) ≤ y ↔ x ≤ y := by
  sorry

@[simp, norm_cast]
theorem intCast_lt_toIGame {x : ℤ} {y : ℝ} : (x : IGame) < y ↔ x < y := by
  sorry
@[simp, norm_cast]
theorem intCast_le_toIGame {x : ℤ} {y : ℝ} : (x : IGame) ≤ y ↔ x ≤ y := by
  sorry

@[simp, norm_cast]
theorem toIGame_equiv_intCast {x : ℝ} {y : ℤ} : (x : IGame) ≈ y ↔ x = y := by
  sorry
@[simp, norm_cast]
theorem intCast_equiv_toIGame {x : ℤ} {y : ℝ} : (x : IGame) ≈ y ↔ x = y := by
  sorry

/-! #### ℕ -/

@[simp, norm_cast]
theorem toIGame_lt_natCast {x : ℝ} {y : ℕ} : (x : IGame) < y ↔ x < y := by
  sorry
@[simp, norm_cast]
theorem toIGame_le_natCast {x : ℝ} {y : ℕ} : (x : IGame) ≤ y ↔ x ≤ y := by
  sorry

@[simp, norm_cast]
theorem natCast_lt_toIGame {x : ℕ} {y : ℝ} : (x : IGame) < y ↔ x < y := by
  sorry
@[simp, norm_cast]
theorem natCast_le_toIGame {x : ℕ} {y : ℝ} : (x : IGame) ≤ y ↔ x ≤ y := by
  sorry

@[simp, norm_cast]
theorem toIGame_equiv_natCast {x : ℝ} {y : ℕ} : (x : IGame) ≈ y ↔ x = y := by
  sorry
@[simp, norm_cast]
theorem natCast_equiv_toIGame {x : ℕ} {y : ℝ} : (x : IGame) ≈ y ↔ x = y := by
  sorry

/-! #### 0 -/

@[simp] theorem toIGame_lt_zero {x : ℝ} : (x : IGame) < 0 ↔ x < 0 := by
  sorry
@[simp] theorem toIGame_le_zero {x : ℝ} : (x : IGame) ≤ 0 ↔ x ≤ 0 := by
  sorry

@[simp] theorem zero_lt_toIGame {x : ℝ} : 0 < (x : IGame) ↔ 0 < x := by
  sorry
@[simp] theorem zero_le_toIGame {x : ℝ} : 0 ≤ (x : IGame) ↔ 0 ≤ x := by
  sorry

@[simp] theorem toIGame_equiv_zero {x : ℝ} : (x : IGame) ≈ 0 ↔ x = 0 := by
  sorry
@[simp] theorem zero_equiv_toIGame {x : ℝ} : 0 ≈ (x : IGame) ↔ 0 = x := by
  sorry

/-! #### 1 -/

@[simp] theorem toIGame_lt_one {x : ℝ} : (x : IGame) < 1 ↔ x < 1 := by
  sorry
@[simp] theorem toIGame_le_one {x : ℝ} : (x : IGame) ≤ 1 ↔ x ≤ 1 := by
  sorry

@[simp] theorem one_lt_toIGame {x : ℝ} : 1 < (x : IGame) ↔ 1 < x := by
  sorry
@[simp] theorem one_le_toIGame {x : ℝ} : 1 ≤ (x : IGame) ↔ 1 ≤ x := by
  sorry

@[simp] theorem toIGame_equiv_one {x : ℝ} : (x : IGame) ≈ 1 ↔ x = 1 := by
  sorry
@[simp] theorem one_equiv_toIGame {x : ℝ} : 1 ≈ (x : IGame) ↔ 1 = x := by
  sorry

end Real
end
