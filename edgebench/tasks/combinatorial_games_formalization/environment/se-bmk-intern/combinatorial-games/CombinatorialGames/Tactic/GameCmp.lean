/-
Copyright (c) 2025 Violeta Hernández Palacios. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Violeta Hernández Palacios
-/
module

public import CombinatorialGames.Game.IGame

meta import CombinatorialGames.Tactic.Register

/-!
# Tactic for game inequalities

This file defines the `game_cmp` tactic, capable of proving inequalities between games. See its
docstring for more info.

Tests for the tactic are found in the `CombinatorialGames.Test` file.
-/

/-- Proves simple inequalities on concrete games.

This tactic works by repeatedly unfolding the definition of `≤` and applying `simp` lemmas tagged
with `game_cmp` until the goal is solved. It is effective on any game whose moves can be
"enumerated" by `simp`, in the sense that a quantifier over its moves can be written in a
quantifier-less way. For instance, `∀ y ∈ leftMoves !{{0, 1} | {2, 3}}, P y` can be simplified into
`P 0 ∧ P 1`.

## Which lemmas to tag

Lemmas which are safe to tag with `game_cmp` are the following:

* Lemmas of the form `(∀ y ∈ leftMoves (f x), P y) ↔ _` and analogous, as long as any quantifiers
  in the simplified form are over left or right moves of simpler games.
* Lemmas of the form `leftMoves (f x) = _` and analogous, as long as the simplified set is of the
  form `{x₁, x₂, …}`, listing out all elements explicitly.
* Lemmas which directly replace games by other simpler games.

Tagging any other lemmas might lead to `simp` failing to eliminate all quantifiers, and getting
stuck in a goal that it can't solve.
-/
macro "game_cmp" : tactic =>
  `(tactic| {
    try simp only [lt_iff_le_not_ge, ge_iff_le, gt_iff_lt, AntisymmRel, Relation.SymmGen, IncompRel]
    repeat
      rw [IGame.le_iff_forall_lf]
      simp only [game_cmp]})

/-! ### Extra tagged lemmas -/

public section

variable {α : Type*} {P : α → Prop}

attribute [game_cmp] Set.forall_mem_empty
@[game_cmp] theorem Set.exists_mem_empty : (∃ x ∈ (∅ : Set α), P x) ↔ False := by
  sorry

@[game_cmp] theorem Set.forall_singleton {x : α} : (∀ y ∈ ({x} : Set α), P y) ↔ P x := by
  sorry
@[game_cmp] theorem Set.exists_singleton {x : α} : (∃ y ∈ ({x} : Set α), P y) ↔ P x := by
  sorry

@[game_cmp] theorem forall_lt_zero {P : ℕ → Prop} : (∀ n < 0, P n) ↔ True := by
  sorry
@[game_cmp] theorem exists_lt_zero {P : ℕ → Prop} : (∃ n < 0, P n) ↔ False := by
  sorry
@[game_cmp] theorem forall_lt_one {P : ℕ → Prop} : (∀ n < 1, P n) ↔ P 0 := by
  sorry
@[game_cmp] theorem exists_lt_one {P : ℕ → Prop} : (∃ n < 1, P n) ↔ P 0 := by
  sorry

attribute [game_cmp] le_rfl
  zero_add add_zero zero_mul mul_zero one_mul mul_one neg_zero sub_eq_add_neg
  Nat.cast_zero Nat.cast_one Nat.forall_lt_succ_left Nat.exists_lt_succ_left
  not_not not_true not_false_eq_true not_forall true_and and_true false_and and_false
  false_implies implies_true forall_const and_imp forall_exists_index
  Player.neg_left Player.neg_right Player.left_mul Player.right_mul Player.forall Player.exists
  Set.forall_mem_image Set.exists_mem_image Set.forall_mem_insert Set.exists_mem_insert Set.mem_Iio

end
