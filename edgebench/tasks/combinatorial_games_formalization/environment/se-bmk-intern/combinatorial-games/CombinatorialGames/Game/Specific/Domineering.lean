/-
Copyright (c) 2019 Kim Morrison. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Kim Morrison, Violeta Hernández Palacios
-/
module

public import CombinatorialGames.Game.Graph
public import Mathlib.Algebra.Group.Int.Defs
public import Mathlib.Algebra.Group.Units.Equiv
public import Mathlib.Algebra.Order.Group.Nat
public import Mathlib.Data.Finset.Sort

import Mathlib.Algebra.Order.Sub.Unbundled.Basic
import Mathlib.Algebra.Ring.Basic
import Mathlib.Algebra.Ring.Int.Defs

/-!
# Domineering as a combinatorial game.

We define the game of Domineering, played on a chessboard of arbitrary shape
(possibly even disconnected).
Left moves by placing a domino vertically, while Right moves by placing a domino horizontally.

This is only a fragment of a full development;
in order to successfully analyse positions we would need some more theorems.
Most importantly, we need a general statement that allows us to discard irrelevant moves.
Specifically to domineering, we need the fact that
disjoint parts of the chessboard give sums of games.

## Todo

Refactor this file to adhere to the design notes specified in `CombinatorialGames.Game.Graph`.
-/

@[expose] public section

namespace IGame

open Function

/-- A Domineering board is an arbitrary finite subset of `ℤ × ℤ`. -/
def Domineering := Finset (ℤ × ℤ) deriving DecidableEq

/-- Cast a finset to a domineering position. -/
@[match_pattern] def toDomineering : Finset (ℤ × ℤ) ≃ Domineering := Equiv.refl _

/-- Cast a domineering position to a finset. -/
@[match_pattern] def ofDomineering : Domineering ≃ Finset (ℤ × ℤ) := Equiv.refl _

@[simp] theorem toDomineering_ofDomineering (a : Domineering) :
  toDomineering (ofDomineering a) = a := by
  sorry
@[simp] theorem ofDomineering_toDomineering (s : Finset (ℤ × ℤ)) :
  ofDomineering (toDomineering s) = s := by
  sorry

namespace Domineering

unsafe instance : Repr Domineering := Finset.instRepr

/-- Left can play anywhere that a square and the square below it are open. -/
def left (b : Domineering) : Finset (ℤ × ℤ) :=
  ofDomineering b ∩ (ofDomineering b).map ((Equiv.refl ℤ).prodCongr (Equiv.addRight (1 : ℤ)))

/-- Right can play anywhere that a square and the square to the left are open. -/
def right (b : Domineering) : Finset (ℤ × ℤ) :=
  ofDomineering b ∩ (ofDomineering b).map ((Equiv.addRight (1 : ℤ)).prodCongr (Equiv.refl ℤ))

@[aesop simp]
theorem mem_left {b : Domineering} {m : ℤ × ℤ} :
    m ∈ left b ↔ m ∈ ofDomineering b ∧ (m.1, m.2 - 1) ∈ ofDomineering b := by
  sorry

@[aesop simp]
theorem mem_right {b : Domineering} {m : ℤ × ℤ} :
    m ∈ right b ↔ m ∈ ofDomineering b ∧ (m.1 - 1, m.2) ∈ ofDomineering b := by
  sorry

theorem subset_of_mem_left {b : Domineering} {m : ℤ × ℤ} (h : m ∈ left b) :
    {m, (m.1, m.2 - 1)} ⊆ ofDomineering b := by
  sorry

theorem subset_of_mem_right {b : Domineering} {m : ℤ × ℤ} (h : m ∈ right b) :
    {m, (m.1 - 1, m.2)} ⊆ ofDomineering b := by
  sorry

/-- After Left moves, two vertically adjacent squares are removed from the Domineering. -/
def moveLeft (b : Domineering) (m : ℤ × ℤ) : Domineering :=
  toDomineering <| ((ofDomineering b).erase m).erase (m.1, m.2 - 1)

/-- After Left moves, two horizontally adjacent squares are removed from the Domineering. -/
def moveRight (b : Domineering) (m : ℤ × ℤ) : Domineering :=
  toDomineering <| ((ofDomineering b).erase m).erase (m.1 - 1, m.2)

theorem moveLeft_subset (b : Domineering) (m : ℤ × ℤ) :
    ofDomineering (b.moveLeft m) ⊆ ofDomineering b := by
  sorry

theorem moveRight_subset (b : Domineering) (m : ℤ × ℤ) :
    ofDomineering (b.moveRight m) ⊆ ofDomineering b := by
  sorry

-- TODO: these should be functions `Domineering → Finset Domineering` rather than relations.

/-- Left can move from `b` to `a` when there exists some `m ∈ left b` with `a = b.moveLeft m`. -/
def relLeft (a b : Domineering) : Prop :=
  ∃ m ∈ left b, a = b.moveLeft m

/-- Right can move from `b` to `a` when there exists some `m ∈ right b` with `a = b.moveRight m`. -/
def relRight (a b : Domineering) : Prop :=
  ∃ m ∈ right b, a = b.moveRight m

@[inherit_doc] local infixl:50 " ≺ₗ " => relLeft
@[inherit_doc] local infixr:50 " ≺ᵣ " => relRight

instance : DecidableRel relLeft := fun _ _ ↦ inferInstanceAs (Decidable (∃ _, _))
instance : DecidableRel relRight := fun _ _ ↦ inferInstanceAs (Decidable (∃ _, _))

theorem card_of_mem_left {b : Domineering} {m : ℤ × ℤ} (h : m ∈ left b) :
    2 ≤ (ofDomineering b).card := by
  sorry

theorem card_of_mem_right {b : Domineering} {m : ℤ × ℤ} (h : m ∈ right b) :
    2 ≤ (ofDomineering b).card := by
  sorry

theorem moveLeft_card {b : Domineering} {m : ℤ × ℤ} (h : m ∈ left b) :
    (ofDomineering (moveLeft b m)).card + 2 = (ofDomineering b).card := by
  sorry

theorem moveRight_card {b : Domineering} {m : ℤ × ℤ} (h : m ∈ right b) :
    (ofDomineering (moveRight b m)).card + 2 = (ofDomineering b).card := by
  sorry

theorem card_of_relLeft {a b : Domineering} (h : a ≺ₗ b) :
    (ofDomineering a).card + 2 = (ofDomineering b).card := by
  sorry

theorem card_of_relRight {a b : Domineering} (h : a ≺ᵣ b) :
    (ofDomineering a).card + 2 = (ofDomineering b).card := by
  sorry

theorem subrelation_relLeft :
    Subrelation relLeft (InvImage (· < ·) fun b ↦ (ofDomineering b).card) := by
  sorry

theorem subrelation_relRight :
    Subrelation relRight (InvImage (· < ·) fun b ↦ (ofDomineering b).card) := by
  sorry

instance : IsWellFounded _ relLeft := subrelation_relLeft.isWellFounded
instance : IsWellFounded _ relRight := subrelation_relRight.isWellFounded

end Domineering

end IGame

open IGame Domineering

-- TODO: this should probably go much earlier in the file.

/-- The game of domineering. -/
def GameGraph.domineering : GameGraph Domineering where
  moves p x := p.cases {y | relLeft y x} {y | relRight y x}

end
