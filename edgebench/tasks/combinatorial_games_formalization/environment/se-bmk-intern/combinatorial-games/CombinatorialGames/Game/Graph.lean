/-
Copyright (c) 2025 Violeta Hernández Palacios. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Violeta Hernández Palacios, Junyan Xu
-/
module

public import CombinatorialGames.Game.Classes
public import CombinatorialGames.Game.Loopy.IGame

/-!
# Combinatorial games from a type of states

In the literature, mathematicians often describe games as graphs, consisting of a set of states, as
well as move relations for the left and right players. We define a structure `GameGraph` which
facilitates this construction, bundling the left and right set functions along with the type, as
well as functions `GameGraph.toLGame` and `GameGraph.toIGame` which turn them into the appropriate
type of game.

Mathematically, `GameGraph.toLGame` is nothing but the corecursor on loopy games, while
`GameGraph.toIGame` is defined inductively.

## Design notes

When working with any "specific" game (nim, domineering, etc.) you can use  `GameGraph` to set up
the basic theorems and definitions, but the intent is that you're not working with `GameGraph`
directly most of the time.
-/

universe u v

public noncomputable section

open IGame Set

variable {α : Type v}

/-- A game graph is a type of states endowed with move sets for the left and right players.

You can use `GameGraph.toLGame` and `GameGraph.toIGame` to turn this structure into the
appropriate game type. -/
structure GameGraph (α : Type v) : Type v where
  /-- The sets of options for the players. -/
  moves : Player → α → Set α

namespace GameGraph
variable {c : GameGraph.{v} α} {p : Player}

variable [Hl : ∀ a, Small.{u} (c.moves left a)] [Hr : ∀ a, Small.{u} (c.moves right a)]

/-! ### Loopy games -/

variable (c) in
/-- Turns a state of a `GameGraph` into an `LGame`. -/
def toLGame (a : α) : LGame.{u} :=
  .corec c.moves a

variable (c p) in
@[simp]
theorem moves_toLGame (a : α) : (c.toLGame a).moves p = c.toLGame '' c.moves p a := by
  sorry

theorem toLGame_def' (a : α) : c.toLGame a =
    !{fun p ↦ c.toLGame '' c.moves p a} := by
  sorry

theorem toLGame_def (a : α) : c.toLGame a =
    !{c.toLGame '' c.moves left a | c.toLGame '' c.moves right a} := by
  sorry

theorem mem_moves_toLGame_of_mem {a b : α} (hab : b ∈ c.moves p a) :
    c.toLGame b ∈ (c.toLGame a).moves p := by
  sorry

theorem neg_toLGame (h : c.moves left = c.moves right) (a : α) : -c.toLGame a = c.toLGame a := by
  sorry

/-! ### Well-founded games -/

/-- A game graph is well-founded if from every position
there is no infinite sequence of (not necessarily alternating) left and right moves. -/
protected class IsWellFounded (c : GameGraph α) where
  wf (c) : IsWellFounded α fun a b => ∃ p, a ∈ c.moves p b

omit Hl Hr in
theorem IsWellFounded.of_subrelation (r : α → α → Prop) [IsWellFounded α r]
    (hr : ∀ a b p, a ∈ c.moves p b → r a b) : c.IsWellFounded := by
  sorry

variable [c.IsWellFounded]

variable (c) in
/-- **Conway recursion**: build data for a game by recursively building it on its
left and right sets. -/
@[elab_as_elim]
def moveRecOn {motive : α → Sort*} (x)
    (ind : Π x : α, (∀ p, Π y ∈ c.moves p x, motive y) → motive x) :
    motive x :=
  (IsWellFounded.wf c).fix _ (fun x IH ↦ ind x fun _ _ h ↦ IH _ ⟨_, h⟩) x

omit Hl Hr in
theorem moveRecOn_eq {motive : α → Sort*} (x)
    (ind : Π x : α, (∀ p, Π y ∈ c.moves p x, motive y) → motive x) :
    c.moveRecOn x ind = ind x fun _ y _ ↦ c.moveRecOn y ind := by
  sorry

variable (c) in
/-- Turns a state of a `GameGraph` into an `IGame`. -/
def toIGame (a : α) : IGame.{u} :=
  c.moveRecOn a fun x IH ↦ !{fun p ↦ .range fun b : c.moves p x ↦ IH p b b.2}

theorem toIGame_def' (a : α) : c.toIGame a =
    !{fun p ↦ c.toIGame '' c.moves p a} := by
  sorry

theorem toIGame_def (a : α) : c.toIGame a =
    !{c.toIGame '' c.moves left a | c.toIGame '' c.moves right a} := by
  sorry

variable (c p) in
@[simp]
theorem moves_toIGame (a : α) : (c.toIGame a).moves p = c.toIGame '' c.moves p a := by
  sorry

theorem mem_moves_toIGame_of_mem {a b : α} (hab : b ∈ c.moves p a) :
    c.toIGame b ∈ (c.toIGame a).moves p := by
  sorry

variable (c) in
@[simp]
theorem toLGame_toIGame (a : α) : (c.toIGame a).toLGame = c.toLGame a := by
  sorry

theorem neg_toIGame (h : c.moves left = c.moves right) (a : α) : -c.toIGame a = c.toIGame a := by
  sorry

theorem impartial_toIGame (h : c.moves left = c.moves right) (a : α) : Impartial (c.toIGame a) := by
  sorry

end GameGraph
end
