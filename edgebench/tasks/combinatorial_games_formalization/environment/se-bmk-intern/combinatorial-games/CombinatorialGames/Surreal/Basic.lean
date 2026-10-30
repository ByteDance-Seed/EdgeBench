/-
Copyright (c) 2019 Mario Carneiro. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Mario Carneiro, Kim Morrison, Violeta Hernández Palacios
-/
module

public import CombinatorialGames.Game.Birthday

import CombinatorialGames.Tactic.AddInstances
import Mathlib.Data.Int.Cast.Lemmas

/-!
# Surreal numbers

The basic theory of surreal numbers, built on top of the theory of combinatorial (pre-)games. A
surreal number is defined as an equivalence class of numeric games.

Surreal numbers inherit the relations `≤` and `<` from games, and these relations satisfy the axioms
of a linear order. In fact, the surreals form a complete ordered field, containing a copy of the
reals, and much else besides!

## Algebraic operations

In this file, we show that the surreals form a linear ordered commutative group.

In `CombinatorialGames.Surreal.Multiplication`, we define multiplication and show that the surreals
form a linear ordered commutative ring. In `CombinatorialGames.Surreal.Division` we further show the
surreals are a field.
-/

universe u

@[expose] public noncomputable section

/-! ### Simplicity theorem -/

namespace IGame

/-- `x` fits within `y` when `z ⧏ x` for every `z ∈ yᴸ`, and `x ⧏ z` for every
`z ∈ yᴿ`.

The simplicity theorem states that if a game fits a numeric game, but none of its options do, then
the games are equivalent. In particular, a numeric game is equivalent to the game of the least
birthday that fits in it -/
def Fits (x y : IGame) : Prop :=
  (∀ z ∈ yᴸ, z ⧏ x) ∧ (∀ z ∈ yᴿ, x ⧏ z)

theorem fits_of_equiv {x y : IGame} (h : x ≈ y) : Fits x y := by
  sorry

alias AntisymmRel.Fits := fits_of_equiv

theorem Fits.refl (x : IGame) : x.Fits x := by
  sorry

instance : Std.Refl Fits where
  refl := Fits.refl

theorem Fits.antisymm {x y : IGame} (h₁ : Fits x y) (h₂ : Fits y x) : x ≈ y := by
  sorry

@[simp]
theorem fits_neg_iff {x y : IGame} : Fits (-x) (-y) ↔ Fits x y := by
  sorry

alias ⟨_, Fits.neg⟩ := fits_neg_iff

theorem not_fits_iff {x y : IGame} :
    ¬ Fits x y ↔ (∃ z ∈ yᴸ, x ≤ z) ∨ (∃ z ∈ yᴿ, z ≤ x) := by
  sorry

theorem Fits.congr {x y z : IGame} (h : x ≈ y) (hx : x.Fits z) : y.Fits z := by
  sorry

theorem fits_congr {x y z : IGame} (h : x ≈ y) : x.Fits z ↔ y.Fits z := by
  sorry

/-- A variant of the **simplicity theorem** with hypotheses that are easier to show. -/
theorem Fits.equiv_of_forall_moves {x y : IGame} (hx : x.Fits y)
    (hl : ∀ z ∈ xᴸ, ∃ w ∈ yᴸ, z ≤ w) (hr : ∀ z ∈ xᴿ, ∃ w ∈ yᴿ, w ≤ z) : x ≈ y := by
  sorry

/-- A variant of the **simplicity theorem**: if a numeric game `x` fits within a game `y`, but none
of its options do, then `x ≈ y`.

Note that under most circumstances, `Fits.equiv_of_forall_moves` is easier to use. -/
theorem Fits.equiv_of_forall_not_fits {x y : IGame} [Numeric x] (hx : x.Fits y)
    (h : ∀ p, ∀ z ∈ x.moves p, ¬ z.Fits y) : x ≈ y := by
  sorry

/-- A variant of the **simplicity theorem**: if `x` is the numeric game with the least birthday that
fits within `y`, then `x ≈ y`. -/
theorem Fits.equiv_of_forall_birthday_le {x y : IGame} [Numeric x] (hx : x.Fits y)
    (H : ∀ z, Numeric z → z.Fits y → x.birthday ≤ z.birthday) : x ≈ y := by
  sorry

/-- A specialization of the simplicity theorem to `0`. -/
@[simp]
theorem fits_zero_iff_equiv {x : IGame} : Fits 0 x ↔ x ≈ 0 := by
  sorry

/-- A specialization of the simplicity theorem to `1`. -/
theorem equiv_one_of_fits {x : IGame} (hx : Fits 1 x) (h : ¬ x ≈ 0) : x ≈ 1 := by
  sorry

end IGame

/-! ### Surreal numbers -/

open IGame

/-- The type of surreal numbers. These are the numeric games quotiented by the antisymmetrization
relation `x ≈ y ↔ x ≤ y ∧ y ≤ x`. In the quotient, the order becomes a total order. -/
def Surreal : Type (u + 1) :=
  Antisymmetrization (Subtype Numeric) (· ≤ ·)

namespace Surreal

/-- The quotient map from the subtype of numeric `IGame`s into `Game`. -/
def mk (x : IGame) [h : Numeric x] : Surreal := Quotient.mk _ ⟨x, h⟩
theorem mk_eq_mk {x y : IGame} [Numeric x] [Numeric y] : mk x = mk y ↔ x ≈ y := by
  sorry

alias ⟨_, mk_eq⟩ := mk_eq_mk

@[cases_eliminator]
theorem ind {motive : Surreal → Prop} (mk : ∀ y [Numeric y], motive (mk y)) (x : Surreal) :
    motive x := by
  sorry

/-- Choose an element of the equivalence class using the axiom of choice. -/
@[no_expose] def out (x : Surreal) : IGame := (Quotient.out x).1
@[simp] instance (x : Surreal) : Numeric x.out := (Quotient.out x).2
@[simp] theorem out_eq (x : Surreal) : mk x.out = x := by
  sorry

theorem mk_out_equiv (x : IGame) [h : Numeric x] : (mk x).out ≈ x := by
  sorry

theorem equiv_mk_out (x : IGame) [Numeric x] : x ≈ (mk x).out := by
  sorry

instance : Zero Surreal := ⟨mk 0⟩
instance : One Surreal := ⟨mk 1⟩
instance : Inhabited Surreal := ⟨0⟩

instance : Add Surreal where
  add := Quotient.map₂ (fun a b ↦ ⟨a.1 + b.1, inferInstance⟩) fun _ _ h₁ _ _ h₂ ↦ add_congr h₁ h₂

instance : Neg Surreal where
  neg := Quotient.map (fun a ↦ ⟨-a.1, inferInstance⟩) fun _ _ ↦ neg_congr

instance : PartialOrder Surreal :=
  inferInstanceAs (PartialOrder (Antisymmetrization ..))

instance : LinearOrder Surreal where
  le_total := by rintro ⟨x⟩ ⟨y⟩; exact Numeric.le_total x y
  toDecidableLE := Classical.decRel _

instance : AddCommGroup Surreal where
  zero_add := by rintro ⟨x⟩; change mk (0 + x) = mk x; simp_rw [zero_add]
  add_zero := by rintro ⟨x⟩; change mk (x + 0) = mk x; simp_rw [add_zero]
  add_comm := by rintro ⟨x⟩ ⟨y⟩; change mk (x + y) = mk (y + x); simp_rw [add_comm]
  add_assoc := by rintro ⟨x⟩ ⟨y⟩ ⟨z⟩; change mk (x + y + z) = mk (x + (y + z)); simp_rw [add_assoc]
  neg_add_cancel := by rintro ⟨a⟩; exact mk_eq (neg_add_equiv _)
  nsmul := nsmulRec
  zsmul := zsmulRec

instance : AddGroupWithOne Surreal where

instance : IsOrderedAddMonoid Surreal where
  add_le_add_left := by rintro ⟨a⟩ ⟨b⟩ h ⟨c⟩; exact add_le_add_left (α := IGame) h _

@[simp] theorem mk_zero : mk 0 = 0 := by
  sorry
@[simp] theorem mk_one : mk 1 = 1 := by
  sorry
@[simp] theorem mk_add (x y : IGame) [Numeric x] [Numeric y] : mk (x + y) = mk x + mk y := by
  sorry
@[simp] theorem mk_neg (x : IGame) [Numeric x] : mk (-x) = -mk x := by
  sorry
@[simp] theorem mk_sub (x y : IGame) [Numeric x] [Numeric y] : mk (x - y) = mk x - mk y := by
  sorry

@[simp] theorem mk_le_mk {x y : IGame} [Numeric x] [Numeric y] : mk x ≤ mk y ↔ x ≤ y := by
  sorry
@[simp] theorem mk_lt_mk {x y : IGame} [Numeric x] [Numeric y] : mk x < mk y ↔ x < y := by
  sorry

@[simp]
theorem mk_natCast : ∀ n : ℕ, mk n = n
  := by
  sorry

@[simp]
theorem mk_intCast (n : ℤ) : mk n = n := by
  sorry

instance : ZeroLEOneClass Surreal where
  zero_le_one := zero_le_one (α := IGame)

instance : NeZero (1 : Surreal) where
  out := by apply ne_of_gt; exact IGame.zero_lt_one

instance : Nontrivial Surreal :=
  ⟨_, _, zero_ne_one⟩

/-- Casts a `Surreal` number into a `Game`. -/
def toGame : Surreal ↪o Game where
  toFun := Quotient.lift (fun x ↦ .mk x) fun _ _ ↦ Game.mk_eq
  inj' x y := by
    cases x; cases y;
    change Game.mk _ = Game.mk _ → _
    simp [Game.mk_eq_mk, mk_eq_mk]
  map_rel_iff' := by rintro ⟨_⟩ ⟨_⟩; rfl

@[simp] theorem toGame_mk (x : IGame) [Numeric x] : toGame (mk x) = .mk x := by
  sorry
@[simp] theorem toGame_zero : toGame 0 = 0 := by
  sorry
@[simp] theorem toGame_one : toGame 1 = 1 := by
  sorry

@[simp]
theorem gameMk_out (x : Surreal) : Game.mk x.out = x.toGame := by
  sorry

theorem toGame_le_iff {a b : Surreal} : toGame a ≤ toGame b ↔ a ≤ b := by
  sorry
theorem toGame_lt_iff {a b : Surreal} : toGame a < toGame b ↔ a < b := by
  sorry
theorem toGame_inj {a b : Surreal} : toGame a = toGame b ↔ a = b := by
  sorry

/-- `Surreal.toGame` as an `OrderAddMonoidHom` -/
@[simps]
def toGameAddHom : Surreal →+o Game where
  toFun := toGame
  map_zero' := rfl
  map_add' := by rintro ⟨_⟩ ⟨_⟩; rfl
  monotone' := toGame.monotone

@[simp]
theorem toGame_add (x y : Surreal) : toGame (x + y) = toGame x + toGame y := by
  sorry

@[simp]
theorem toGame_neg (x : Surreal) : toGame (-x) = -toGame x := by
  sorry

@[simp]
theorem toGame_sub (x y : Surreal) : toGame (x - y) = toGame x - toGame y := by
  sorry

@[simp] theorem toGame_natCast (n : ℕ) : toGame n = n := by
  sorry
@[simp] theorem toGame_intCast (n : ℤ) : toGame n = n := by
  sorry

/-- Construct a `Surreal` from its left and right sets, and a proof that all elements from the left
set are less than all the elements of the right set.

Note that although this function is well-defined, this function isn't injective, nor do equivalence
classes in Surreal have a canonical representative. (Note however that every short numeric game has
a unique "canonical" form!) -/
instance : OfSets Surreal.{u} (fun st ↦ ∀ x ∈ st left, ∀ y ∈ st right, x < y) where
  ofSets st H _ _ := by
    refine @mk !{fun p ↦ out '' st p} (.mk ?_ (by simp))
    rw [moves_ofSets, moves_ofSets]
    rintro - ⟨x, hx, rfl⟩ - ⟨y, hy, rfl⟩
    rw [← Surreal.mk_lt_mk, out_eq, out_eq]
    exact H x hx y hy

theorem toGame_ofSets' (st : Player → Set Surreal.{u}) [Small.{u} (st left)] [Small.{u} (st right)]
    {H : ∀ x ∈ st left, ∀ y ∈ st right, x < y} :
    toGame !{st} = !{fun p ↦ toGame '' st p} := by
  sorry

@[simp]
theorem toGame_ofSets (s t : Set Surreal.{u}) [Small.{u} s] [Small.{u} t]
    {H : ∀ x ∈ s, ∀ y ∈ t, x < y} :
    toGame !{s | t} = !{toGame '' s | toGame '' t} := by
  sorry

theorem mk_ofSets' {st : Player → Set IGame.{u}}
    [Small.{u} (st left)] [Small.{u} (st right)] {H : Numeric !{st}} :
    mk !{st} =
      !{fun p ↦ .range fun x : st p ↦ mk x (h := H.of_mem_moves (p := p) (by simp))}'
      (by have := @H.left_lt_right; aesop) := by
  sorry

theorem mk_ofSets {s t : Set IGame.{u}} [Small.{u} s] [Small.{u} t] {H : Numeric !{s | t}} :
    mk !{s | t} =
      !{.range fun x : s ↦ mk x (h := H.of_mem_moves (p := left) (by simp)) |
        .range fun x : t ↦ mk x (h := H.of_mem_moves (p := right) (by simp))}'
      (by have := @H.left_lt_right; aesop) := by
  sorry

@[aesop apply unsafe]
theorem lt_ofSets_of_mem_left {s t : Set Surreal.{u}} [Small.{u} s] [Small.{u} t]
    {H : ∀ x ∈ s, ∀ y ∈ t, x < y} {x : Surreal} (hx : x ∈ s) :
    x < !{s | t} := by
  sorry

@[aesop apply unsafe]
theorem ofSets_lt_of_mem_right {s t : Set Surreal.{u}} [Small.{u} s] [Small.{u} t]
    {H : ∀ x ∈ s, ∀ y ∈ t, x < y} {x : Surreal} (hx : x ∈ t) :
    !{s | t} < x := by
  sorry

theorem zero_def : (0 : Surreal) = !{fun _ ↦ ∅} := by
  sorry
theorem one_def : (1 : Surreal) = !{{0} | ∅} := by
  sorry

instance : DenselyOrdered Surreal where
  dense a b hab := ⟨!{{a} | {b}},
    lt_ofSets_of_mem_left (Set.mem_singleton a), ofSets_lt_of_mem_right (Set.mem_singleton b)⟩

end Surreal
end
