/-
Copyright (c) 2022 Violeta Hernández Palacios. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Violeta Hernández Palacios
-/
module

public import CombinatorialGames.Game.Basic
public import CombinatorialGames.NatOrdinal.Basic
public import Mathlib.Algebra.Order.Hom.Monoid

import CombinatorialGames.Tactic.GameCmp
import Mathlib.Algebra.Order.Hom.Monoid
import Mathlib.Data.Set.Finite.Lattice

/-!
# Ordinals as games

We define the canonical map `NatOrdinal → IGame`, where every ordinal is mapped to the game whose
left set consists of all previous ordinals. We make use of the type alias `NatOrdinal` rather than
`Ordinal`, as this map also preserves addition, and in the case of surreals, multiplication. The map
to surreals is defined in `CombinatorialGames.Surreal.Ordinal`.

We also prove some properties about `NatCast`, which is related to the previous construction by
`toIGame (↑n) ≈ ↑n`.

# Main declarations

- `NatOrdinal.toIGame`: The canonical map between `NatOrdinal` and `IGame`.
- `NatOrdinal.toGame`: The canonical map between `NatOrdinal` and `Game`.
-/

universe u

open Set IGame

@[expose] public noncomputable section

/-! ### Lemmas to upstream -/

@[simp]
theorem OrderEmbedding.antisymmRel_iff_antisymmRel {α β : Type*} [Preorder α] [Preorder β]
    {a b : α} (f : α ↪o β) : f a ≈ f b ↔ a ≈ b := by
  sorry

theorem OrderEmbedding.antisymmRel_iff_eq {α β : Type*} [Preorder α] [PartialOrder β]
    {a b : α} (f : α ↪o β) : f a ≈ f b ↔ a = b := by
  sorry

namespace NatOrdinal

/-! ### `NatOrdinal` to `IGame` -/

/-- We make this private until we can build the `OrderEmbedding`. -/
private def toIGame' (o : NatOrdinal.{u}) : IGame.{u} :=
  !{.range fun (⟨x, _⟩ : Iio o) ↦ toIGame' x | ∅}
termination_by o

private theorem toIGame'_def (o : NatOrdinal) : o.toIGame' = !{toIGame' '' Iio o | ∅} := by
  sorry

private theorem leftMoves_toIGame' (o : NatOrdinal) : o.toIGame'ᴸ = toIGame' '' Iio o := by
  sorry

private theorem rightMoves_toIGame' (o : NatOrdinal) : o.toIGame'ᴿ = ∅ := by
  sorry

private theorem toIGame'_strictMono : StrictMono toIGame' := by
  sorry

/-- The canonical map from `NatOrdinal` to `IGame`, sending `o` to `{Iio o | ∅}`. -/
@[no_expose]
def toIGame : NatOrdinal.{u} ↪o IGame.{u} :=
  .ofStrictMono NatOrdinal.toIGame' toIGame'_strictMono

instance : Coe NatOrdinal IGame where
  coe x := toIGame x

theorem toIGame_def (o : NatOrdinal) : o.toIGame = !{toIGame '' Iio o | ∅} := by
  sorry

@[simp]
theorem leftMoves_toIGame (o : NatOrdinal) : o.toIGameᴸ = toIGame '' Iio o := by
  sorry

@[simp, game_cmp]
theorem rightMoves_toIGame (o : NatOrdinal) : o.toIGameᴿ = ∅ := by
  sorry

theorem forall_leftMoves_toIGame {P : IGame → Prop} {o : NatOrdinal} :
    (∀ x ∈ (toIGame o)ᴸ, P x) ↔ ∀ a < o, P (toIGame a) := by
  sorry

theorem exists_leftMoves_toIGame {P : IGame → Prop} {o : NatOrdinal} :
    (∃ x ∈ (toIGame o)ᴸ, P x) ↔ ∃ a < o, P (toIGame a) := by
  sorry

@[game_cmp]
theorem forall_leftMoves_toIGame_natCast {P : IGame → Prop} {n : ℕ} :
    (∀ x ∈ (toIGame n)ᴸ, P x) ↔ ∀ m < n, P (toIGame m) := by
  sorry

@[game_cmp]
theorem exists_leftMoves_toIGame_natCast {P : IGame → Prop} {n : ℕ} :
    (∃ x ∈ (toIGame n)ᴸ, P x) ↔ (∃ m < n, P (toIGame m)) := by
  sorry

@[game_cmp]
theorem forall_leftMoves_toIGame_ofNat {P : IGame → Prop} {n : ℕ} [n.AtLeastTwo] :
    (∀ x ∈ (toIGame ofNat(n))ᴸ, P x) ↔ ∀ m < n, P (toIGame m) := by
  sorry

@[game_cmp]
theorem exists_leftMoves_toIGame_ofNat {P : IGame → Prop} {n : ℕ} [n.AtLeastTwo] :
    (∃ x ∈ (toIGame ofNat(n))ᴸ, P x) ↔ ∃ m < n, P (toIGame m) := by
  sorry

theorem mem_leftMoves_toIGame_of_lt {a b : NatOrdinal} (h : a < b) :
    a.toIGame ∈ b.toIGameᴸ := by
  sorry

@[simp, game_cmp] theorem toIGame_zero : toIGame 0 = 0 := by
  sorry
@[simp, game_cmp] theorem toIGame_one : toIGame 1 = 1 := by
  sorry

@[simp]
theorem not_toIGame_fuzzy (a b : NatOrdinal) : ¬ toIGame a ‖ toIGame b := by
  sorry

@[simp]
theorem toIGame_nonneg (a : NatOrdinal) : 0 ≤ a.toIGame := by
  sorry

/-! ### `NatOrdinal` to `Game` -/

/-- Converts an ordinal into the corresponding game. -/
noncomputable def toGame : NatOrdinal.{u} ↪o Game.{u} :=
  .ofStrictMono (fun o ↦ .mk o.toIGame) fun _ _ h ↦ toIGame.strictMono h

instance : Coe NatOrdinal Game where
  coe x := toGame x

@[simp] theorem _root_.Game.mk_natOrdinal_toIGame (o : NatOrdinal) : .mk o.toIGame = o.toGame := by
  sorry

theorem toGame_def (o : NatOrdinal) : o.toGame = !{toGame '' Iio o | ∅} := by
  sorry

@[simp] theorem toGame_zero : toGame 0 = 0 := by
  sorry
@[simp] theorem toGame_one : toGame 1 = 1 := by
  sorry

@[simp]
theorem not_toGame_fuzzy (a b : NatOrdinal) : ¬ toGame a ‖ toGame b := by
  sorry

@[simp]
theorem toGame_nonneg (a : NatOrdinal) : 0 ≤ a.toGame := by
  sorry

/-- The natural addition of ordinals corresponds to their sum as games. -/
theorem toIGame_add (a b : NatOrdinal) : (a + b).toIGame ≈ a.toIGame + b.toIGame := by
  sorry

@[simp]
theorem toGame_add (a b : NatOrdinal) : (a + b).toGame = a.toGame + b.toGame := by
  sorry

/-- The natural multiplication of ordinals corresponds to their product as games. -/
theorem toIGame_mul (a b : NatOrdinal) : (a * b).toIGame ≈ a.toIGame * b.toIGame := by
  sorry

@[simp]
theorem toGame_mul (a b : NatOrdinal) : (a * b).toGame = .mk (a.toIGame * b.toIGame) := by
  sorry

/-- `NatOrdinal.toGame` as an `OrderAddMonoidHom`. -/
@[simps]
def toGameAddHom : NatOrdinal →+o Game where
  toFun := toGame
  map_zero' := toGame_zero
  map_add' := toGame_add
  monotone' := toGame.monotone

/-! ### `NatCast` properties -/

@[simp]
theorem toGame_natCast : ∀ n : ℕ, toGame n = n := by
  sorry

/-- Note that the equality doesn't hold, as e.g. `↑2 = {1 | }`, while `toIGame 2 = {0, 1 | }`. -/
theorem toIGame_natCast_equiv (n : ℕ) : toIGame n ≈ n := by
  sorry

end NatOrdinal

namespace IGame
open NatOrdinal

theorem Short.exists_lt_natCast (x : IGame) [Short x] : ∃ n : ℕ, x < n := by
  sorry

theorem Short.exists_neg_natCast_lt (x : IGame) [Short x] : ∃ n : ℕ, -n < x := by
  sorry

local notation "ω" => toIGame (NatOrdinal.of Ordinal.omega0)

theorem Short.lt_omega0 (x : IGame) [Short x] : x < ω := by
  sorry

theorem Short.neg_omega0_lt (x : IGame) [Short x] : -ω < x := by
  sorry

end IGame
end
