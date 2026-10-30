/-
Copyright (c) 2025 Aaron Liu. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Aaron Liu
-/
module

public import CombinatorialGames.Game.Loopy.Basic
public import CombinatorialGames.NatOrdinal.Basic

import CombinatorialGames.Mathlib.WithTop

/-!
# Stopping time

For `p q : Player` and `x : LGame`, `stoppingTime p q x : WithTop NatOrdinal` is called
the stopping time of `x`, and represents how long it will take with optimal play
for `p` for force a win if it is `q`'s turn to move on `x`.
No move by `p` can strictly decrease the stopping time, and
no move by `-p` can strictly increase the stopping time.
If `p` cannot force a win then it takes the value `⊤`, and `-p` can survive forever by
only moving to other positions whose stopping time is also `⊤`.
Otherwise it is an ordinal that strictly decreases whenever `-p` moves.
Then `p` can force a win by moving to positions with an equal stopping time.
The stopping times of the positions for `-p` will then spell out a
strictly decreasing sequence of ordinals, which must eventually reach `0`,
at which point `-p` will have no moves left.
The lemma `stoppingTime_of_eq` characterizes the behavior of `stoppingTime`
when it is `p`'s turn to move, and
the lemma `stoppingTime_of_ne` characterizes the behavior of `stoppingTime`
when it is `-p`'s turn to move.

`stoppingTime p : Player → LGame.{u} → WithTop NatOrdinal.{u}` is the unique fixed point of the map
`val ↦ fun q x ↦ if p = q then ⨅ y ∈ x.moves q, val (-q) y else ⨆ y ∈ x.moves q, val (-q) y + 1`.
It therefore satisfies both an induction and a coinduction principle,
given by `stoppingTime_induction` and `stoppingTime_coinduction`.
`stoppingTime_induction` says that any other `val : Player → LGame → WithTop NatOrdinal`
decreased by this map must be bigger than `stoppingTime`, and
`stoppingTime_coinduction` says that any other `val : Player → LGame → WithTop NatOrdinal`
increased by this map must be smaller than `stoppingTime`.

-/

universe u v

/-! ### For Mathlib -/

theorem Monotone.iInf' {α β : Type*} {ι : Sort*} [Preorder α] [CompleteLattice β] {f : ι → α → β}
    (hf : ∀ (i : ι), Monotone (f i)) : Monotone (fun x => ⨅ i, f i x) := by
  sorry

theorem Monotone.iSup' {α β : Type*} {ι : Sort*} [Preorder α] [CompleteLattice β] {f : ι → α → β}
    (hf : ∀ (i : ι), Monotone (f i)) : Monotone (fun x => ⨆ i, f i x) := by
  sorry

theorem Order.lt_add_one_iff_not_isMax {α : Type*} [Preorder α] [Add α] [One α] [SuccAddOrder α]
    (x : α) : x < x + 1 ↔ ¬IsMax x := by
  sorry

theorem Order.le_add_one {α : Type*} [Preorder α] [Add α] [One α] [SuccAddOrder α]
    (x : α) : x ≤ x + 1 := by
  sorry

public noncomputable section
namespace LGame
open Order

/-- Refines the approximations for the stopping times. -/
private def stoppingTimeApprox (p : Player) : (LGame.{u} → WithTop NatOrdinal.{u}) →o
    (LGame.{u} → WithTop NatOrdinal.{u}) where
  toFun f x := ⨅ y ∈ x.moves p, ⨆ i ∈ y.moves (-p), f i + 1
  monotone' := monotone_lam fun _ =>
    Monotone.iInf' fun _ => Monotone.iInf' fun _ => Monotone.iSup' fun i => Monotone.iSup' fun _ =>
      add_left_mono.comp (Function.monotone_eval i)

private theorem le_of_finite (p : Player) {x y}
    (hx : stoppingTimeApprox p x = x) (hy : stoppingTimeApprox p y = y)
    {i : LGame.{u}} (hi : y i ≠ ⊤) : x i ≤ y i := by
  sorry

private theorem lfp_eq_gfp (p : Player) :
    (stoppingTimeApprox p).lfp = (stoppingTimeApprox p).gfp := by
  sorry

/-- `stoppingTime p q x` is the time it takes for `p` to force a win if `q` goes first on `x`,
counted in moves made by `-p`. -/
@[irreducible]
def stoppingTime (p q : Player) (x : LGame.{u}) : WithTop NatOrdinal.{u} :=
  if p = q then (stoppingTimeApprox p).lfp x
  else ⨆ i ∈ x.moves q, (stoppingTimeApprox p).lfp i + 1

theorem stoppingTime_of_eq {p q : Player} (h : p = q) (x : LGame.{u}) :
    stoppingTime p q x = ⨅ y ∈ x.moves q, stoppingTime p (-q) y := by
  sorry

theorem stoppingTime_of_ne {p q : Player} (h : p ≠ q) (x : LGame.{u}) :
    stoppingTime p q x = ⨆ y ∈ x.moves q, stoppingTime p (-q) y + 1 := by
  sorry

theorem stoppingTime_induction (p : Player)
    (val : Player → LGame.{u} → WithTop NatOrdinal.{u})
    (hp : ∀ x, ⨅ y ∈ x.moves p, val (-p) y ≤ val p x)
    (hnp : ∀ x, ⨆ y ∈ x.moves (-p), val p y + 1 ≤ val (-p) x) :
    stoppingTime p ≤ val := by
  sorry

theorem stoppingTime_coinduction (p : Player)
    (val : Player → LGame.{u} → WithTop NatOrdinal.{u})
    (hp : ∀ x, val p x ≤ ⨅ y ∈ x.moves p, val (-p) y)
    (hnp : ∀ x, val (-p) x ≤ ⨆ y ∈ x.moves (-p), val p y + 1) :
    val ≤ stoppingTime p := by
  sorry

end LGame
