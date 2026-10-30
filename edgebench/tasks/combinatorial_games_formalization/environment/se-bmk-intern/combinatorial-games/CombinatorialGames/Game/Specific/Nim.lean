/-
Copyright (c) 2020 Fox Thomson. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Fox Thomson, Julia Markus Himmel, Violeta Hernández Palacios
-/
module

public import CombinatorialGames.Game.Birthday
public import CombinatorialGames.Game.Classes
public import CombinatorialGames.Game.Graph
public import CombinatorialGames.Nimber.Basic

import CombinatorialGames.Tactic.OrdinalAlias
import Mathlib.Order.Interval.Set.OrderIso

/-!
# Nim

In the game of `nim o`, for `o` an ordinal number, both players may move to `nim a` for any `a < o`.

This is an impartial game; in fact, in a strong sense, it's the simplest impartial game, as by the
Sprague-Grundy theorem, any other impartial game is equivalent to some game of nim. As such, many
results on Nim are proven in `Game.Impartial.Grundy`.

We define `nim` in terms of a `Nimber` rather than an `Ordinal`, as this makes the results
`nim (a + b) ≈ nim a + nim b` and `nim (a * b) ≈ nim a * nim b` much easier to state.
-/

universe u

@[expose] public section

open Nimber Set

namespace GameGraph

/-- The game of nim as a `GameGraph`. -/
abbrev nim : GameGraph Nimber where
  moves _ := Iio

instance : nim.IsWellFounded :=
  .of_subrelation (· < ·) <| by simp

end GameGraph

namespace IGame

/-! ### Nim game -/

/-- The definition of single-heap nim, which can be viewed as a pile of stones where each player can
take a positive number of stones from it on their turn. -/
noncomputable def nim : Nimber.{u} → IGame.{u} :=
  GameGraph.nim.toIGame

theorem nim_def (o : Nimber) : nim o = !{fun _ ↦ nim '' Iio o} := by
  sorry

@[simp]
theorem moves_nim (p : Player) (o : Nimber) : (nim o).moves p = nim '' Iio o := by
  sorry

theorem forall_moves_nim {p : Player} {P : IGame → Prop} {o : Nimber} :
    (∀ x ∈ (nim o).moves p, P x) ↔ (∀ a < o, P (nim a)) := by
  sorry

theorem exists_moves_nim {p : Player} {P : IGame → Prop} {o : Nimber} :
    (∃ x ∈ (nim o).moves p, P x) ↔ (∃ a < o, P (nim a)) := by
  sorry

@[game_cmp]
theorem forall_moves_nim_natCast {p : Player} {P : IGame → Prop} {n : ℕ} :
    (∀ x ∈ (nim (∗n)).moves p, P x) ↔ ∀ m < n, P (nim (∗m)) := by
  sorry

@[game_cmp]
theorem exists_moves_nim_natCast {p : Player} {P : IGame → Prop} {n : ℕ} :
    (∃ x ∈ (nim (∗n)).moves p, P x) ↔ (∃ m < n, P (nim (∗m))) := by
  sorry

@[game_cmp]
theorem forall_moves_nim_ofNat {p : Player} {P : IGame → Prop} {n : ℕ} [n.AtLeastTwo] :
    (∀ x ∈ (nim (∗ofNat(n))).moves p, P x) ↔ ∀ m < n, P (nim (∗m)) := by
  sorry

@[game_cmp]
theorem exists_moves_nim_ofNat {p : Player} {P : IGame → Prop} {n : ℕ} [n.AtLeastTwo] :
    (∃ x ∈ (nim (∗ofNat(n))).moves p, P x) ↔ ∃ m < n, P (nim (∗m)) := by
  sorry

theorem mem_moves_nim_of_lt {a b : Nimber} (p : Player) (h : a < b) :
    (nim a) ∈ (nim b).moves p := by
  sorry

theorem nim_injective : Function.Injective nim := by
  sorry

@[simp] theorem nim_inj {a b : Nimber} : nim a = nim b ↔ a = b := by
  sorry

@[simp, game_cmp] theorem nim_zero : nim 0 = 0 := by
  sorry
@[simp, game_cmp] theorem nim_one : nim 1 = ⋆ := by
  sorry

@[simp]
theorem birthday_nim (o : Nimber) : (nim o).birthday = .of o.val := by
  sorry

@[simp, game_cmp]
theorem neg_nim (o : Nimber) : -nim o = nim o := by
  sorry

protected instance Impartial.nim (o : Nimber) : Impartial (nim o) :=
  GameGraph.impartial_toIGame rfl ..

protected instance Dicotic.nim (o : Nimber) : Dicotic (nim o) := by
  rw [dicotic_def]
  simpa using fun a ha ↦ .nim a
termination_by o

private theorem nim_fuzzy_of_lt {a b : Nimber} (h : a < b) : nim a ‖ nim b := by
  sorry

@[simp]
theorem nim_equiv_iff {a b : Nimber} : nim a ≈ nim b ↔ a = b := by
  sorry

@[simp]
theorem nim_fuzzy_iff {a b : Nimber} : nim a ‖ nim b ↔ a ≠ b := by
  sorry

theorem _root_.Game.birthday_nim (o : Nimber) : Game.birthday (.mk (nim o)) = .of o.val := by
  sorry

end IGame
end
