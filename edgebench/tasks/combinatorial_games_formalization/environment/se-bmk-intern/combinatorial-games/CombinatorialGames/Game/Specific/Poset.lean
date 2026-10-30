/-
Copyright (c) 2025 Violeta Hernández Palacios. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Violeta Hernández Palacios
-/
module

public import CombinatorialGames.Game.Classes
public import CombinatorialGames.Game.Graph
public import Mathlib.Order.WellQuasiOrder

/-!
# Poset games

Let `α` be a partially ordered type (in fact, a preorder suffices). One can define the following
impartial game: two players alternate turns choosing an element `a : α`, and "removing" the entire
interval `Ici a` from the poset. As usual, whoever runs out of moves loses.

In a general poset, this game need not terminate. Adding the condition that `α` is well
quasi-ordered (well-founded with no infinite antichains) is both sufficient and necessary to
guarantee a finite game.

This setup generalizes other well-known games within CGT, most notably Chomp, which is simply the
poset game on `(Fin m × Fin n) \ {⊥}`.

## Main results

* `GameGraph.Poset.impartial_toIGame`: poset games are impartial
* `GameGraph.Poset.univ_fuzzy_zero`: any poset game with a top element is won by the second
  player, shown via a strategy stealing argument
-/

variable {α : Type*} [Preorder α]

public section

open Set

namespace GameGraph.Poset

/-! ### Poset relation -/

/-- A valid move in the poset game is to change set `t` to set `s`, whenever `s = t \ Ici a` for
some `a ∈ t`.

In a WQO, this relation is well-founded. -/
def Rel (s t : Set α) : Prop :=
  ∃ a ∈ t, s = t \ Ici a

@[inherit_doc]
local infixl:50 " ≺ " => Rel

theorem subrelation_rel : @Subrelation (Set α) (· ≺ ·) (· ⊂ ·) := by
  sorry

theorem not_rel_empty (s : Set α) : ¬ s ≺ ∅ := by
  sorry

theorem rel_irrefl (s : Set α) : ¬ s ≺ s := by
  sorry

instance : @Std.Irrefl (Set α) (· ≺ ·) where
  irrefl := rel_irrefl

theorem top_compl_rel_univ {α : Type*} [PartialOrder α] [OrderTop α] : {⊤}ᶜ ≺ @univ α := by
  sorry

theorem rel_univ_of_rel_top_compl {α : Type*} [PartialOrder α] [OrderTop α] {s : Set α}
    (h : s ≺ {⊤}ᶜ) : s ≺ univ := by
  sorry

theorem wellFounded_rel [WellQuasiOrderedLE α] : @WellFounded (Set α) (· ≺ ·) := by
  sorry

instance isWellFounded_rel [WellQuasiOrderedLE α] : IsWellFounded (Set α) (· ≺ ·) :=
  ⟨wellFounded_rel⟩

/-! ### Poset game -/

-- TODO: add stuff on `LGame`

section IGame
variable [WellQuasiOrderedLE α]

variable (α) in
/-- The poset game, played on a poset `α`. -/
abbrev _root_.GameGraph.poset : GameGraph (Set α) where
  moves _ x := {y | Poset.Rel y x}

instance : (poset α).IsWellFounded :=
  .of_subrelation Poset.Rel <| by simp

/-- A state of the poset game on `α`. -/
noncomputable def toIGame (s : Set α) : IGame :=
  (poset α).toIGame s

@[simp]
theorem moves_toIGame (p) (s : Set α) : (toIGame s).moves p = toIGame '' {t | Rel t s} := by
  sorry

theorem mem_moves_toIGame_of_rel (p) {s t : Set α} (h : Rel t s) :
    toIGame t ∈ (toIGame s).moves p := by
  sorry

@[simp]
protected theorem neg_toIGame (s : Set α) : -toIGame s = toIGame s := by
  sorry

protected instance impartial_toIGame (s : Set α) : (toIGame s).Impartial :=
  impartial_toIGame rfl ..

-- TODO: this should generalize to a `Preorder`.
-- A game should be equal to its antisymmetrization.

/-- Any poset game on a toIGame with a top element is won by the first player. This is proven by
a strategy stealing argument with `{⊤}ᶜ`. -/
theorem univ_fuzzy_zero {α : Type*} [PartialOrder α] [WellQuasiOrderedLE α] [OrderTop α] :
    toIGame (@univ α) ‖ 0 := by
  sorry

end IGame
end GameGraph.Poset
end
