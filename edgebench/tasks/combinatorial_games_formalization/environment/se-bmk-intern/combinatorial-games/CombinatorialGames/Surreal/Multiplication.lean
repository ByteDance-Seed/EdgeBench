/-
Copyright (c) 2024 Theodore Hwa. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Mario Carneiro, Kim Morrison, Violeta Hernández Palacios, Junyan Xu, Theodore Hwa
-/
module

public import CombinatorialGames.Surreal.Basic

import Mathlib.Logic.Hydra
import Mathlib.Tactic.Abel

/-!
# Surreal multiplication

In this file, we show that multiplication of surreal numbers is well-defined, and thus the surreal
numbers form a linear ordered commutative ring. This is Theorem 8 in [Conway2001], or Theorem 3.8 in
[SchleicherStoll].

An inductive argument proves the following three main theorems:

* P1: being numeric is closed under multiplication,
* P2: multiplying a numeric pregame by equivalent numeric pregames results in equivalent pregames,
* P3: the product of two positive numeric pregames is positive (`mul_pos`).

P1 allows us to define multiplication as an operation on numeric pregames, P2 says that this is
well-defined as an operation on the quotient by `IGame.Equiv`, namely the surreal numbers, and P3 is
an axiom that needs to be satisfied for the surreals to be a `OrderedRing`.

We follow the proof in [SchleicherStoll], except that we use the well-foundedness of the hydra
relation `CutExpand` on `Multiset IGame` instead of the argument based on a depth function in the
paper. As in said argument, P3 is proven by proxy of an auxiliary P4, which states that for
`x₁ < x₂` and `y`, then `x₁ * y + x₂ * a < x₁ * a + x₂ * y` when `a ∈ yᴸ`, and
`x₁ * b + x₂ * y < x₁ * y + x₂ * b` when `b ∈ yᴿ`.

## Reducing casework

This argument is very casework heavy in a way that's difficult to automate. For instance, in P1, we
have to prove four different inequalities of the form
`a ∈ (x * y)ᴸ → b ∈ (x * y)ᴿ → a < b`, and depending on what form the options of
`x * y` take, we have to apply different instantiations of the inductive hypothesis.

To greatly simplify things, we work uniquely in terms of left options, which we achieve by rewriting
`a ∈ xᴿ` as `-a ∈ (-x)ᴸ`. We then show that our distinct lemmas and inductive
hypotheses are invariant under the appropriate sign changes. In the P1 example, this makes it so
that one case (`mulOption_lt_of_lt`) is enough to conclude the others (`mulOption_lt`), and the same
goes for the other parts of the proof.

Note also that we express all inequalities in terms of `Game` instead of `IGame`; this allows us to
make use of `abel` and all of the theorems on `OrderedAddCommGroup`.
-/

universe u

open Game IGame Relation WellFounded

/-- A characterization of left moves of `x * y` in terms only of left moves. -/
lemma forall_leftMoves_mul' {P : IGame → Prop} {x y : IGame} :
    (∀ a ∈ (x * y)ᴸ, P a) ↔
      (∀ a ∈ xᴸ, ∀ b ∈ yᴸ, P (mulOption x y a b)) ∧
      (∀ a ∈ (-x)ᴸ, ∀ b ∈ (-y)ᴸ, P (mulOption (-x) (-y) a b)) := by
  sorry

/-- A characterization of right moves of `x * y` in terms only of left moves. -/
lemma forall_rightMoves_mul' {P : IGame → Prop} {x y : IGame} :
    (∀ a ∈ (x * y)ᴿ, P a) ↔
      (∀ a ∈ xᴸ, ∀ b ∈ (-y)ᴸ, P (-mulOption x (-y) a b)) ∧
      (∀ a ∈ (-x)ᴸ, ∀ b ∈ yᴸ, P (-mulOption (-x) y a b)) := by
  sorry

/-! ### Predicates P1 – P4 -/

/-- `P1 x y a b c d` means that `mulOption x y a b < mulOption x y c d`. This is the general form
of the statements needed to prove that `x * y` is numeric. -/
def P1 (x y a b c d : IGame) := Game.mk (mulOption x y a b) < Game.mk (mulOption x y c d)

/-- `P2 x₁ x₂ y` states that if `x₁ ≈ x₂`, then `x₁ * y ≈ x₂ * y`. The RHS is stated in terms of
`Game.mk` for rewriting convenience. -/
def P2 (x₁ x₂ y : IGame) := x₁ ≈ x₂ → Game.mk (x₁ * y) = Game.mk (x₂ * y)

/-- `P3 x₁ x₂ y₁ y₂` states that `x₁ * y₂ + x₂ * y₁ < x₁ * y₁ + x₂ * y₂`. Using distributivity, this
is equivalent to `(x₁ - x₂) * (y₁ - y₂) > 0`. -/
def P3 (x₁ x₂ y₁ y₂ : IGame) :=
  Game.mk (x₁ * y₂) + Game.mk (x₂ * y₁) < Game.mk (x₁ * y₁) + Game.mk (x₂ * y₂)

/-- `P4 x₁ x₂ y` states that if `x₁ < x₂`, then `P3 x₁ x₂ a y` when `a ∈ yᴸ`, and
`P3 x₁ x₂ b y` when `b ∈ yᴿ`.

Note that we instead write this second part as `P3 x₁ x₂ b (-y)` when `b ∈ (-y)ᴸ`. See the
module docstring for an explanation. -/
def P4 (x₁ x₂ y : IGame) :=
  x₁ < x₂ → (∀ a ∈ yᴸ, P3 x₁ x₂ a y) ∧ (∀ b ∈ (-y)ᴸ, P3 x₁ x₂ b (-y))

/-- The conjunction of `P2` and `P4`. Both statements have the same amount of arguments and satisfy
similar symmetry properties, so we can slightly simplify the argument by merging them. -/
def P24 (x₁ x₂ y : IGame) : Prop := P2 x₁ x₂ y ∧ P4 x₁ x₂ y

variable {x x₁ x₂ x₃ x' y y₁ y₂ y₃ y' a b c d : IGame.{u}}

/-! #### Symmetry properties of P1 – P4 -/

lemma P3_comm : P3 x₁ x₂ y₁ y₂ ↔ P3 y₁ y₂ x₁ x₂ := by
  sorry

lemma P3.trans (h₁ : P3 x₁ x₂ y₁ y₂) (h₂ : P3 x₂ x₃ y₁ y₂) : P3 x₁ x₃ y₁ y₂ := by
  sorry

lemma P3_neg : P3 (-x₂) (-x₁) y₁ y₂ ↔ P3 x₁ x₂ y₁ y₂ := by
  sorry

lemma P2_neg_left : P2 (-x₂) (-x₁) y ↔ P2 x₁ x₂ y := by
  sorry

lemma P2_neg_right : P2 x₁ x₂ (-y) ↔ P2 x₁ x₂ y := by
  sorry

lemma P4_neg_left : P4 (-x₂) (-x₁) y ↔P4 x₁ x₂ y  := by
  sorry

lemma P4_neg_right : P4 x₁ x₂ (-y) ↔ P4 x₁ x₂ y := by
  sorry

lemma P24_neg_left : P24 (-x₂) (-x₁) y ↔ P24 x₁ x₂ y := by
  sorry
lemma P24_neg_right : P24 x₁ x₂ (-y) ↔ P24 x₁ x₂ y := by
  sorry

/-! ### Inductive setup -/

/-- The type of lists of arguments for `P1`, `P2`, and `P4`. -/
inductive Args : Type (u + 1)
  | P1 (x y : IGame.{u}) : Args
  | P24 (x₁ x₂ y : IGame.{u}) : Args

/-- The multiset associated to a list of arguments. -/
def Args.toMultiset : Args → Multiset IGame
  | (Args.P1 x y) => {x, y}
  | (Args.P24 x₁ x₂ y) => {x₁, x₂, y}

@[simp] lemma Args.toMultiset_P1 {x y} : (Args.P1 x y).toMultiset = {x, y} := by
  sorry
@[simp] lemma Args.toMultiset_P24 {x₁ x₂ y} : (Args.P24 x₁ x₂ y).toMultiset = {x₁, x₂, y} := by
  sorry

/-- A list of arguments is numeric if all the arguments are. -/
def Args.Numeric (a : Args) := ∀ x ∈ a.toMultiset, x.Numeric

lemma Args.numeric_P1 {x y} : (Args.P1 x y).Numeric ↔ x.Numeric ∧ y.Numeric := by
  sorry

lemma Args.numeric_P24 {x₁ x₂ y} :
    (Args.P24 x₁ x₂ y).Numeric ↔ x₁.Numeric ∧ x₂.Numeric ∧ y.Numeric := by
  sorry

/-- The well-founded relation specifying when a list of game arguments is considered simpler than
another: `ArgsRel a₁ a₂` is true if `a₁`, considered as a multiset, can be obtained from `a₂` by
repeatedly removing a game from `a₂` and adding back one or two options of the game.

See also `WellFounded.CutExpand`. -/
def ArgsRel := InvImage (TransGen <| CutExpand fun x y => ∃ p, x ∈ y.moves p) Args.toMultiset

/-- `ArgsRel` is well-founded. -/
lemma argsRel_wf : WellFounded ArgsRel := by
  sorry
instance : IsWellFounded _ ArgsRel := ⟨argsRel_wf⟩

/-- The property that all arguments are numeric is leftward-closed under `ArgsRel`. -/
lemma ArgsRel.numeric_closed {a' a} : ArgsRel a' a → a.Numeric → a'.Numeric := by
  sorry

/-- The statement that we will show by induction for all `Numeric` args, using the well-founded
relation `ArgsRel`.

The inductive hypothesis in the proof will be `∀ a', ArgsRel a' a → P124 a`. -/
def P124 : Args → Prop
  | (Args.P1 x y) => Numeric (x * y)
  | (Args.P24 x₁ x₂ y) => P24 x₁ x₂ y

/-! ### P1 follows from the inductive hypothesis -/

lemma numeric_move_mul_of_IH {p : Player} (IH : ∀ a, ArgsRel a (Args.P1 x y) → P124 a)
    (h : x' ∈ x.moves p) : (x' * y).Numeric := by
  sorry

lemma numeric_mul_move_of_IH {p : Player} (IH : ∀ a, ArgsRel a (Args.P1 x y) → P124 a)
    (h : y' ∈ y.moves p) : (x * y').Numeric := by
  sorry

lemma numeric_move_mul_move_of_IH {p q : Player} (IH : ∀ a, ArgsRel a (Args.P1 x y) → P124 a)
    (hx : x' ∈ x.moves p) (hy : y' ∈ y.moves q) : (x' * y').Numeric := by
  sorry

/-- A specialization of the inductive hypothesis used to prove `P1`. -/
def IH1 (x y : IGame) : Prop :=
  ∀ ⦃p q x₁ x₂ y'⦄, x₁ ∈ x.moves p → x₂ ∈ x.moves q → (y' = y ∨ ∃ u, y' ∈ y.moves u) → P24 x₁ x₂ y'

/-- `IH1 x y` follows from the inductive hypothesis for `P1 x y`. -/
lemma IH1_of_IH (IH : ∀ a, ArgsRel a (Args.P1 x y) → P124 a) : IH1 x y := by
  sorry

/-- `IH1 y x` follows from the inductive hypothesis for `P1 x y`. -/
lemma IH1_swap_of_IH (IH : ∀ a, ArgsRel a (Args.P1 x y) → P124 a) : IH1 y x := by
  sorry

lemma IH1_neg_left : IH1 x y → IH1 (-x) y := by
  sorry

lemma IH1_neg_right : IH1 x y → IH1 x (-y) := by
  sorry

lemma P1_of_equiv (he : x₁ ≈ x₃) (h₁ : P2 x₁ x₃ y₁) (h₃ : P2 x₁ x₃ y₃) (h3 : P3 x₁ x₂ y₂ y₃) :
    P1 x₂ y₁ x₁ y₂ x₃ y₃ := by
  sorry

lemma P1_of_P3 (h₁ : P3 x₃ x₂ y₂ y₃) (h₂ : P3 x₁ x₃ y₂ y₁) : P1 x₂ y₁ x₁ y₂ x₃ y₃ := by
  sorry

lemma P3_of_IH1 [Numeric y] (ihyx : IH1 y x)
    (ha : a ∈ xᴸ) (hb : b ∈ yᴸ) (hd : d ∈ (-y)ᴸ) : P3 a x b (-d) := by
  sorry

lemma P24_of_IH1 (ihxy : IH1 x y) (ha : a ∈ xᴸ) (hb : b ∈ xᴸ) : P24 a b y := by
  sorry

lemma mulOption_lt_iff_P1 :
    Game.mk (mulOption x y a b) < -Game.mk (mulOption x (-y) c d) ↔ P1 x y a b c (-d) := by
  sorry

lemma mulOption_lt_of_lt [Numeric y] (ihxy : IH1 x y) (ihyx : IH1 y x) {a b c d} (h : a < c)
    (ha : a ∈ xᴸ) (hb : b ∈ yᴸ) (hc : c ∈ xᴸ) (hd : d ∈ (-y)ᴸ) :
    Game.mk (mulOption x y a b) < -Game.mk (mulOption x (-y) c d) := by
  sorry

lemma mulOption_lt [Numeric x] [Numeric y] (ihxy : IH1 x y) (ihyx : IH1 y x) {a b c d}
    (ha : a ∈ xᴸ) (hb : b ∈ yᴸ) (hc : c ∈ xᴸ) (hd : d ∈ (-y)ᴸ) :
    Game.mk (mulOption x y a b) < -Game.mk (mulOption x (-y) c d) := by
  sorry

/-- `P1` follows from the induction hypothesis. -/
lemma P1_of_IH (IH : ∀ a, ArgsRel a (Args.P1 x y) → P124 a) [Numeric x] [Numeric y] :
    (x * y).Numeric := by
  sorry

/-! ### P2 follows from the inductive hypothesis -/

lemma numeric_of_IH (IH : ∀ a, ArgsRel a (Args.P24 x₁ x₂ y) → P124 a) :
    (x₁ * y).Numeric ∧ (x₂ * y).Numeric := by
  sorry

/-- A specialization of the inductive hypothesis used to prove `P2` and `P4`. -/
def IH24 (x₁ x₂ y : IGame) : Prop :=
  ∀ ⦃p z⦄,
    (z ∈ x₁.moves p → P24 z x₂ y) ∧
    (z ∈ x₂.moves p → P24 x₁ z y) ∧
    (z ∈ y.moves p → P24 x₁ x₂ z)

/-- A specialization of the induction hypothesis used to prove `P4`. -/
def IH4 (x₁ x₂ y : IGame) : Prop :=
  ∀ ⦃p q z w⦄, w ∈ y.moves p → (z ∈ x₁.moves q → P2 z x₂ w) ∧ (z ∈ x₂.moves q → P2 x₁ z w)

/-- `IH24 x₁ x₂ y` follows from the inductive hypothesis for `P24 x₁ x₂ y`. -/
lemma IH24_of_IH (IH : ∀ a, ArgsRel a (Args.P24 x₁ x₂ y) → P124 a) : IH24 x₁ x₂ y := by
  sorry

/-- `IH24 x₂ x₁ y` follows from the inductive hypothesis for `P24 x₁ x₂ y`. -/
lemma IH24_swap_of_IH (IH : ∀ a, ArgsRel a (Args.P24 x₁ x₂ y) → P124 a) : IH24 x₂ x₁ y := by
  sorry

/-- `IH4 x₁ x₂ y` follows from the inductive hypothesis for `P24 x₁ x₂ y`. -/
lemma IH4_of_IH (IH : ∀ a, ArgsRel a (Args.P24 x₁ x₂ y) → P124 a) : IH4 x₁ x₂ y := by
  sorry

lemma IH24_neg : IH24 x₁ x₂ y → IH24 (-x₂) (-x₁) y ∧ IH24 x₁ x₂ (-y) := by
  sorry

lemma IH4_neg : IH4 x₁ x₂ y → IH4 (-x₂) (-x₁) y ∧ IH4 x₁ x₂ (-y) := by
  sorry

lemma mulOption_lt_mul_of_equiv [Numeric x₁] (h : IH24 x₁ x₂ y) (he : x₁ ≈ x₂)
    (hi : a ∈ x₁ᴸ) (hj : b ∈ yᴸ) :
    Game.mk (mulOption x₁ y a b) < Game.mk (x₂ * y) := by
  sorry

lemma mul_right_le_of_equiv [Numeric x₁] [Numeric x₂]
    (ih₁₂ : IH24 x₁ x₂ y) (ih₂₁ : IH24 x₂ x₁ y) (he : x₁ ≈ x₂) : x₁ * y ≤ x₂ * y := by
  sorry

/-- `P2` follows from the induction hypothesis. -/
lemma P2_of_IH (IH : ∀ a, ArgsRel a (Args.P24 x₁ x₂ y) → P124 a) [Numeric x₁] [Numeric x₂]
    (he : x₁ ≈ x₂) : x₁ * y ≈ x₂ * y := by
  sorry

/-! ### P4 follows from the inductive hypothesis -/

lemma mulOption_lt_mul_iff_P3 : mulOption x y a b < x * y ↔ P3 a x b y := by
  sorry

/-- A specialization of the induction hypothesis used to prove `P3`. -/
def IH3 (x₁ x' x₂ y₁ y₂ : IGame) : Prop :=
  P2 x₁ x' y₁ ∧ P2 x₁ x' y₂ ∧ P3 x' x₂ y₁ y₂ ∧ (x₁ < x' → P3 x₁ x' y₁ y₂)

/-- `IH3` follows from the induction hypothesis for `P24 x₁ x₂ y`. -/
lemma IH3_of_IH (ih24 : IH24 x₁ x₂ y) (ih4 : IH4 x₁ x₂ y)
    (hi : a ∈ x₂ᴸ) (hb : b ∈ yᴸ) (hl : mulOption x₂ y a b < x₂ * y) :
    IH3 x₁ a x₂ b y := by
  sorry

lemma P3_of_le_left {y₁ y₂} (i) (h : IH3 x₁ i x₂ y₁ y₂) (hl : x₁ ≤ i) : P3 x₁ x₂ y₁ y₂ := by
  sorry

/-- P3 follows from `IH3`, so P4 (with `y₁` a left option of `y₂`) follows from the induction
hypothesis. -/
lemma P3_of_IH3 {y₁ y₂} (h : ∀ i ∈ x₂ᴸ, IH3 x₁ i x₂ y₁ y₂)
    (hs : ∀ i ∈ (-x₁)ᴸ, IH3 (-x₂) i (-x₁) y₁ y₂) (hl : x₁ < x₂) : P3 x₁ x₂ y₁ y₂ := by
  sorry

/-- `P4` follows from the induction hypothesis. -/
lemma P4_of_IH (IH : ∀ a, ArgsRel a (.P24 x₁ x₂ y) → P124 a) : P4 x₁ x₂ y := by
  sorry

/-- We tie everything together to complete the induction. -/
theorem main (a : Args) : a.Numeric → P124 a := by
  sorry

lemma main_P24 (x₁ x₂ y : IGame) [hx₁ : Numeric x₁] [hx₂ : Numeric x₂] [hy : Numeric y] :
    P24 x₁ x₂ y := by
  sorry

/-- One additional inductive argument proves `P3`. -/
lemma P3_of_lt_of_lt {x₁ x₂ y₁ y₂} [Numeric x₁] [Numeric x₂] [Numeric y₁] [Numeric y₂]
    (hx : x₁ < x₂) (hy : y₁ < y₂) : P3 x₁ x₂ y₁ y₂ := by
  sorry

/-! ### Instances and corollaries -/

public section

namespace IGame.Numeric

variable {x x₁ x₂ y y₁ y₂ : IGame}

instance mul (x y : IGame) [hx : Numeric x] [hy : Numeric y] : Numeric (x * y) :=
  main _ <| Args.numeric_P1.mpr ⟨hx, hy⟩

protected instance mulOption (x y a b : IGame) [Numeric x] [Numeric y] [Numeric a] [Numeric b] :
    Numeric (mulOption x y a b) :=
  .sub ..

theorem mul_congr_left [Numeric x₁] [Numeric x₂] [Numeric y] (he : x₁ ≈ x₂) : x₁ * y ≈ x₂ * y := by
  sorry

theorem mul_congr_right [Numeric x] [Numeric y₁] [Numeric y₂] (he : y₁ ≈ y₂) : x * y₁ ≈ x * y₂ := by
  sorry

theorem mul_congr [Numeric x₁] [Numeric x₂] [Numeric y₁] [Numeric y₂]
    (hx : x₁ ≈ x₂) (hy : y₁ ≈ y₂) : x₁ * y₁ ≈ x₂ * y₂ := by
  sorry

protected theorem mul_pos [Numeric x₁] [Numeric x₂] (h₁ : 0 < x₁) (h₂ : 0 < x₂) : 0 < x₁ * x₂ := by
  sorry

end IGame.Numeric

namespace Surreal

noncomputable instance : CommRing Surreal where
  mul := Quotient.map₂ (fun a b ↦ ⟨a.1 * b.1, inferInstance⟩) fun _ _ h _ _ ↦ Numeric.mul_congr h
  zero_mul := by rintro ⟨x⟩; change mk (0 * x) = mk 0; simp_rw [zero_mul]
  mul_zero := by rintro ⟨x⟩; change mk (x * 0) = mk 0; simp_rw [mul_zero]
  one_mul := by rintro ⟨x⟩; change mk (1 * x) = mk x; simp_rw [one_mul]
  mul_one := by rintro ⟨x⟩; change mk (x * 1) = mk x; simp_rw [mul_one]
  left_distrib := by rintro ⟨x⟩ ⟨y⟩ ⟨z⟩; exact mk_eq (mul_add_equiv ..)
  right_distrib := by rintro ⟨x⟩ ⟨y⟩ ⟨z⟩; exact mk_eq (add_mul_equiv ..)
  mul_comm := by rintro ⟨x⟩ ⟨y⟩; change mk (x * y) = mk (y * x); simp_rw [mul_comm]
  mul_assoc := by rintro ⟨x⟩ ⟨y⟩ ⟨z⟩; exact mk_eq (mul_assoc_equiv ..)

instance : IsStrictOrderedRing Surreal :=
  .of_mul_pos (by rintro ⟨x⟩ ⟨y⟩; exact Numeric.mul_pos)

@[simp]
theorem mk_mul (x y : IGame) [Numeric x] [Numeric y] :
    Surreal.mk (x * y) = Surreal.mk x * Surreal.mk y := by
  sorry

end Surreal

namespace IGame.Numeric

protected theorem mul_neg_of_pos_of_neg {x y : IGame} [Numeric x] [Numeric y]
    (hx : 0 < x) (hy : y < 0) : x * y < 0 := by
  sorry

protected theorem mul_neg_of_neg_of_pos {x y : IGame} [Numeric x] [Numeric y]
    (hx : x < 0) (hy : 0 < y) : x * y < 0 := by
  sorry

protected theorem mul_pos_of_neg_of_neg {x y : IGame} [Numeric x] [Numeric y]
    (hx : x < 0) (hy : y < 0) : 0 < x * y := by
  sorry

protected theorem mul_nonneg {x y : IGame} [Numeric x] [Numeric y]
    (hx : 0 ≤ x) (hy : 0 ≤ y) : 0 ≤ x * y := by
  sorry

protected theorem mul_nonpos_of_nonneg_of_nonpos {x y : IGame} [Numeric x] [Numeric y]
    (hx : 0 ≤ x) (hy : y ≤ 0) : x * y ≤ 0 := by
  sorry

protected theorem mul_nonpos_of_nonpos_of_nonneg {x y : IGame} [Numeric x] [Numeric y]
    (hx : x ≤ 0) (hy : 0 ≤ y) : x * y ≤ 0 := by
  sorry

protected theorem mul_nonneg_of_nonpos_of_nonpos {x y : IGame} [Numeric x] [Numeric y]
    (hx : x ≤ 0) (hy : y ≤ 0) : 0 ≤ x * y := by
  sorry

protected theorem mul_left_cancel {x y z : IGame} [Numeric x] [Numeric y] [Numeric z]
    (hx : ¬ x ≈ 0) (h : x * y ≈ x * z) : y ≈ z := by
  sorry

protected theorem mul_right_cancel {x y z : IGame} [Numeric x] [Numeric y] [Numeric z]
    (hx : ¬ x ≈ 0) (h : y * x ≈ z * x) : y ≈ z := by
  sorry

@[simp]
protected theorem mul_le_mul_iff_left {x y z : IGame} [Numeric x] [Numeric y] [Numeric z]
    (hx : 0 < x) : y * x ≤ z * x ↔ y ≤ z := by
  sorry

@[simp]
protected theorem mul_le_mul_iff_right {x y z : IGame} [Numeric x] [Numeric y] [Numeric z]
    (hx : 0 < x) : x * y ≤ x * z ↔ y ≤ z := by
  sorry

@[simp]
protected theorem mul_lt_mul_iff_left {x y z : IGame} [Numeric x] [Numeric y] [Numeric z]
    (hx : 0 < x) : y * x < z * x ↔ y < z := by
  sorry

@[simp]
protected theorem mul_lt_mul_iff_right {x y z : IGame} [Numeric x] [Numeric y] [Numeric z]
    (hx : 0 < x) : x * y < x * z ↔ y < z := by
  sorry

@[simp]
protected theorem mul_le_mul_left_of_neg {x y z : IGame} [Numeric x] [Numeric y] [Numeric z]
    (hz : z < 0) : z * x ≤ z * y ↔ y ≤ x := by
  sorry

@[simp]
protected theorem mul_le_mul_right_of_neg {x y z : IGame} [Numeric x] [Numeric y] [Numeric z]
    (hz : z < 0) : x * z ≤ y * z ↔ y ≤ x := by
  sorry

@[simp]
protected theorem mul_lt_mul_left_of_neg {x y z : IGame} [Numeric x] [Numeric y] [Numeric z]
    (hz : z < 0) : z * x < z * y ↔ y < x := by
  sorry

@[simp]
protected theorem mul_lt_mul_right_of_neg {x y z : IGame} [Numeric x] [Numeric y] [Numeric z]
    (hz : z < 0) : x * z < y * z ↔ y < x := by
  sorry

protected theorem mul_le_mul {a b c d : IGame} [Numeric a] [Numeric b] [Numeric c] [Numeric d] :
    a ≤ b → c ≤ d → 0 ≤ c → 0 ≤ b → a * c ≤ b * d := by
  sorry

protected theorem mul_lt_mul {a b c d : IGame} [Numeric a] [Numeric b] [Numeric c] [Numeric d] :
    a < b → c ≤ d → 0 < c → 0 ≤ b → a * c < b * d := by
  sorry

@[simp]
protected theorem mul_pos_iff_of_pos_left {a b : IGame} [Numeric a] [Numeric b] :
    0 < a → (0 < a * b ↔ 0 < b) := by
  sorry

@[simp]
protected theorem mul_pos_iff_of_pos_right {a b : IGame} [Numeric a] [Numeric b] :
    0 < b → (0 < a * b ↔ 0 < a) := by
  sorry

theorem mul_equiv_zero {x y : IGame} [Numeric x] [Numeric y] : x * y ≈ 0 ↔ x ≈ 0 ∨ y ≈ 0 := by
  sorry

theorem mulOption_congr₁ {x₁ x₂ y a b : IGame}
    [Numeric x₁] [Numeric x₂] [Numeric y] [Numeric a] [Numeric b] (he : x₁ ≈ x₂) :
    mulOption x₁ y a b ≈ mulOption x₂ y a b := by
  sorry

theorem mulOption_congr₂ {x y₁ y₂ a b : IGame}
    [Numeric x] [Numeric y₁] [Numeric y₂] [Numeric a] [Numeric b] (he : y₁ ≈ y₂) :
    mulOption x y₁ a b ≈ mulOption x y₂ a b := by
  sorry

theorem mulOption_congr₃ {x y a₁ a₂ b : IGame}
    [Numeric x] [Numeric y] [Numeric a₁] [Numeric a₂] [Numeric b] (he : a₁ ≈ a₂) :
    mulOption x y a₁ b ≈ mulOption x y a₂ b := by
  sorry

theorem mulOption_congr₄ {x y a b₁ b₂ : IGame}
    [Numeric x] [Numeric y] [Numeric a] [Numeric b₁] [Numeric b₂] (he : b₁ ≈ b₂) :
    mulOption x y a b₁ ≈ mulOption x y a b₂ := by
  sorry

end IGame.Numeric
end
