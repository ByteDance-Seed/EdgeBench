/-
Copyright (c) 2025 Violeta Hernández Palacios, Aaron Liu, and Junyan Xu. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Violeta Hernández Palacios, Aaron Liu, Junyan Xu
-/
module

public import CombinatorialGames.Game.Loopy.IGame

/-!
# Outcomes of loopy games

We define when a loopy game is a win, a draw, or a loss with each player going first
(under the normal play convention).
-/

public section

namespace LGame
variable {p : Player} {x y : LGame}

mutual
  /-- `IsWin p x` means that player `p` wins `x` going first. -/
  inductive IsWin : Player → LGame → Prop where
    | intro {p : Player} {x y : LGame} : y ∈ x.moves p → IsLoss (-p) y → IsWin p x
  /-- `IsLoss p x` means that player `p` loses `x` going first. -/
  inductive IsLoss : Player → LGame → Prop where
    | intro {p : Player} {x : LGame} : (∀ y ∈ x.moves p, IsWin (-p) y) → IsLoss p x
end

theorem isWin_iff_exists : IsWin p x ↔ ∃ y ∈ x.moves p, IsLoss (-p) y := by
  sorry

theorem isLoss_iff_forall : IsLoss p x ↔ ∀ y ∈ x.moves p, IsWin (-p) y := by
  sorry

theorem IsLoss.isWin_of_mem_moves (h : IsLoss p x) (hy : y ∈ x.moves p) : IsWin (-p) y := by
  sorry

theorem not_isWin_iff_forall : ¬ IsWin p x ↔ ∀ y ∈ x.moves p, ¬ IsLoss (-p) y := by
  sorry

theorem not_isLoss_iff_exists : ¬ IsLoss p x ↔ ∃ y ∈ x.moves p, ¬ IsWin (-p) y := by
  sorry

/-- A surviving strategy for player `p`, going second.

This is a set of states, such that for every move the opposite player makes, `p` can bring it back
to the set.

You can think of this as a nonconstructive version of the more common definition of a strategy,
which gives an explicit answer for every reachable state. -/
def IsStrategy (p : Player) (s : Set LGame) : Prop :=
  ∀ y ∈ s, ∀ z ∈ y.moves (-p), ∃ r ∈ z.moves p, r ∈ s

theorem IsStrategy.neg {s : Set LGame} (h : IsStrategy p s) : IsStrategy (-p) (-s) := by
  sorry

@[simp]
theorem isStrategy_neg {s : Set LGame} : IsStrategy p (-s) ↔ IsStrategy (-p) s := by
  sorry

theorem IsStrategy.iUnion {ι} {s : ι → Set LGame} (h : ∀ i, IsStrategy p (s i)) :
    IsStrategy p (⋃ i, s i) := by
  sorry

theorem IsStrategy.sUnion {S : Set (Set LGame)} (h : ∀ s ∈ S, IsStrategy p s) :
    IsStrategy p (⋃₀ S) := by
  sorry

theorem isStrategy_setOf_isLoss (p : Player) : IsStrategy p {x | IsLoss (-p) x} := by
  sorry

theorem isStrategy_setOf_not_isWin (p : Player) : IsStrategy p {x | ¬ IsWin (-p) x} := by
  sorry

theorem not_isWin_iff_mem_Strategy : ¬ IsWin p x ↔ ∃ s, x ∈ s ∧ IsStrategy (-p) s := by
  sorry

@[simp]
theorem not_isLoss_of_isWin (h : IsWin p x) : ¬ IsLoss p x := by
  sorry

@[simp]
theorem not_isWin_of_isLoss (h : IsLoss p x) : ¬ IsWin p x := by
  sorry

/-- `IsDraw p x` means that `p` draws `x` going first. -/
def IsDraw (p : Player) (x : LGame) : Prop := ¬ IsWin p x ∧ ¬ IsLoss p x

@[simp] theorem IsDraw.not_isWin (h : IsDraw p x) : ¬ IsWin p x := by
  sorry
@[simp] theorem IsDraw.not_isLoss (h : IsDraw p x) : ¬ IsLoss p x := by
  sorry
theorem not_isDraw_iff : ¬ IsDraw p x ↔ IsWin p x ∨ IsLoss p x := by
  sorry

/-- The three possible outcomes of a game. -/
inductive Outcome : Type | win | draw | loss

/-- `outcomeFor p x` is the outcome of `x` with `p` going first. -/
noncomputable def outcomeFor (p : Player) (x : LGame) : Outcome := by classical
  exact if IsWin p x then .win else if IsLoss p x then .loss else .draw

@[simp]
theorem outcomeFor_eq_win_iff : outcomeFor p x = .win ↔ IsWin p x := by
  sorry

@[simp]
theorem outcomeFor_eq_loss_iff : outcomeFor p x = .loss ↔ IsLoss p x := by
  sorry

@[simp]
theorem outcomeFor_eq_draw_iff : outcomeFor p x = .draw ↔ IsDraw p x := by
  sorry

theorem StopperFor.not_isDraw (h : StopperFor p x) : ¬ IsDraw p x := by
  sorry

theorem Stopper.not_isDraw (p : Player) (h : Stopper x) : ¬ IsDraw p x := by
  sorry

end LGame

namespace IGame
variable {x : IGame}

open LGame

@[simp]
theorem not_isDraw (p : Player) (x : IGame) : ¬ IsDraw p x := by
  sorry

private theorem win_loss_iff :
    ((IsWin left x ↔ 0 ⧏ x) ∧ (IsLoss left x ↔ x ≤ 0)) ∧
    ((IsWin right x ↔ x ⧏ 0) ∧ (IsLoss right x ↔ 0 ≤ x)) := by
  sorry

@[simp] theorem isWin_left_iff_zero_lf : IsWin left x ↔ 0 ⧏ x := by
  sorry
@[simp] theorem isLoss_left_iff_le_zero : IsLoss left x ↔ x ≤ 0 := by
  sorry
@[simp] theorem isWin_right_iff_lf_zero : IsWin right x ↔ x ⧏ 0 := by
  sorry
@[simp] theorem isLoss_right_iff_zero_le : IsLoss right x ↔ 0 ≤ x := by
  sorry

theorem fuzzy_zero_iff_isWin : x ‖ 0 ↔ ∀ p, IsWin p x := by
  sorry
theorem equiv_zero_iff_isLoss : x ≈ 0 ↔ ∀ p, IsLoss p x := by
  sorry

theorem lt_zero_iff_isLoss_and_isWin : x < 0 ↔ IsLoss left x ∧ IsWin right x := by
  sorry

theorem zero_lt_iff_isWin_and_isLoss : 0 < x ↔ IsWin left x ∧ IsLoss right x := by
  sorry

end IGame
end
