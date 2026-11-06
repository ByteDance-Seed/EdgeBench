/-
Copyright (c) 2022 Violeta Hernández Palacios. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Violeta Hernández Palacios, Tristan Figueroa Reid
-/
module

public import CombinatorialGames.Game.Classes

import CombinatorialGames.Tactic.GameCmp
import Mathlib.Data.Set.Finite.Basic

/-!
# Special games

This file defines some simple yet notable combinatorial games:

* `⋆ = {0 | 0}`
* `½ = {0 | 1}`
* `↑ = {0 | ⋆}`
* `↓ = {⋆ | 0}`.
-/

universe u

@[expose] public noncomputable section

namespace IGame

/-! ### Star -/

/-- The game `⋆ = {0 | 0}`, which is fuzzy with zero. -/
def star : IGame :=
  !{fun _ ↦ {0}}

@[inherit_doc] notation "⋆" => star
recommended_spelling "star" for "⋆" in [«term⋆»]

@[simp, game_cmp] theorem moves_star (p : Player) : moves p ⋆ = {0} := by
  sorry

theorem zero_lf_star : 0 ⧏ ⋆ := by
  sorry
theorem star_lf_zero : ⋆ ⧏ 0 := by
  sorry

theorem star_fuzzy_zero : ⋆ ‖ 0 := by
  sorry
theorem zero_fuzzy_star : 0 ‖ ⋆ := by
  sorry

@[simp] theorem not_star_equiv_zero : ¬⋆ ≈ 0 := by
  sorry
@[simp] theorem not_zero_equiv_star : ¬0 ≈ ⋆ := by
  sorry

@[simp, game_cmp] theorem neg_star : -⋆ = ⋆ := by
  sorry

@[simp] theorem star_mul_star : ⋆ * ⋆ = ⋆ := by
  sorry

@[simp] protected instance Dicotic.star : Dicotic ⋆ := by rw [dicotic_def]; simp
protected instance Impartial.star : Impartial ⋆ := by rw [impartial_def]; simp
@[simp] protected instance Short.star : Short ⋆ := by rw [short_def]; simp

/-! ### Half -/

/-- The game `½ = {0 | 1}`, which we prove satisfies `½ + ½ = 1`. -/
def half : IGame :=
  !{{0} | {1}}

@[inherit_doc] notation "½" => half
recommended_spelling "half" for "½" in [«term½»]

@[simp, game_cmp] theorem leftMoves_half : ½ᴸ = {0} := by
  sorry
@[simp, game_cmp] theorem rightMoves_half : ½ᴿ = {1} := by
  sorry

theorem zero_lt_half : 0 < ½ := by
  sorry
theorem half_lt_one : ½ < 1 := by
  sorry
theorem half_add_half_equiv_one : ½ + ½ ≈ 1 := by
  sorry

@[simp] protected instance Numeric.half : Numeric ½ := by rw [numeric_def]; simp
protected instance Short.half : Short ½ := by rw [short_def]; simp

/-! ### Up and down -/

/-- The game `↑ = {0 | ⋆}`. -/
def up : IGame :=
  !{{0} | {⋆}}

@[inherit_doc] notation "↑" => up
recommended_spelling "up" for "↑" in [«term↑»]

@[simp, game_cmp] theorem leftMoves_up : ↑ᴸ = {0} := by
  sorry
@[simp, game_cmp] theorem rightMoves_up : ↑ᴿ = {⋆} := by
  sorry

@[simp] theorem up_pos : 0 < ↑ := by
  sorry
theorem up_fuzzy_star : ↑ ‖ ⋆ := by
  sorry
theorem star_fuzzy_up : ⋆ ‖ ↑ := by
  sorry

protected instance Dicotic.up : Dicotic ↑ := by rw [dicotic_def]; simp
protected instance Short.up : Short ↑ := by rw [short_def]; simp

/-- The game `↓ = {⋆ | 0}`. -/
def down : IGame :=
  !{{⋆} | {0}}

@[inherit_doc] notation "↓" => down
recommended_spelling "down" for "↓" in [«term↓»]

@[simp, game_cmp] theorem leftMoves_down : ↓ᴸ = {⋆} := by
  sorry
@[simp, game_cmp] theorem rightMoves_down : ↓ᴿ = {0} := by
  sorry

@[simp, game_cmp] theorem neg_down : -↓ = ↑ := by
  sorry
@[simp, game_cmp] theorem neg_up : -↑ = ↓ := by
  sorry

@[simp] theorem down_neg : ↓ < 0 := by
  sorry
theorem down_fuzzy_star : ↓ ‖ ⋆ := by
  sorry
theorem star_fuzzy_down : ⋆ ‖ ↓ := by
  sorry

protected instance Dicotic.down : Dicotic ↓ := by rw [dicotic_def]; simp
protected instance Short.down : Short ↓ := by rw [short_def]; simp

/-! ### Tiny and miny -/

/-- A tiny game `⧾x` is defined as `{0 | {0 | -x}}`, and is amongst the smallest of the
infinitesimals. -/
def tiny (x : IGame) : IGame :=
  !{{0} | {!{{0} | {-x}}}}

@[inherit_doc] prefix:75 "⧾" => tiny
recommended_spelling "tiny" for "⧾" in [«term⧾_»]

@[simp, game_cmp]
theorem leftMoves_tiny (x : IGame) : (⧾x)ᴸ = {0} := by
  sorry

@[simp, game_cmp]
theorem rightMoves_tiny (x : IGame) : (⧾x)ᴿ = {!{{0} | {-x}}} := by
  sorry

@[simp]
theorem dicotic_tiny_iff {x : IGame} : Dicotic (⧾x) ↔ Dicotic x := by
  sorry

instance (x : IGame) [Dicotic x] : Dicotic (⧾x) := by rwa [dicotic_tiny_iff]

@[simp]
theorem short_tiny_iff {x : IGame} : Short (⧾x) ↔ Short x := by
  sorry

instance (x : IGame) [Short x] : Short (⧾x) := by rwa [short_tiny_iff]

/-- A miny game `⧿x` is defined as `{{x | 0} | 0}`. -/
def miny (x : IGame) : IGame :=
  !{{!{{x} | {0}}} | {0}}

@[inherit_doc] prefix:75 "⧿" => miny
recommended_spelling "miny" for "⧿" in [«term⧿_»]

@[simp, game_cmp]
theorem leftMoves_miny (x : IGame) : (⧿x)ᴸ = {!{{x} | {0}}} := by
  sorry

@[simp, game_cmp]
theorem rightMoves_miny (x : IGame) : (⧿x)ᴿ = {0} := by
  sorry

@[simp, game_cmp]
theorem neg_tiny (x : IGame) : -(⧾x) = ⧿x := by
  sorry

@[simp, game_cmp]
theorem neg_miny (x : IGame) : -(⧿x) = ⧾x := by
  sorry

@[simp]
theorem dicotic_miny_iff {x : IGame} : Dicotic (⧿x) ↔ Dicotic x := by
  sorry

instance (x : IGame) [Dicotic x] : Dicotic (⧿x) := by
  rwa [dicotic_miny_iff]

@[simp]
theorem short_miny_iff {x : IGame} : Short (⧿x) ↔ Short x := by
  sorry

instance (x : IGame) [Short x] : Short (⧿x) := by
  rwa [short_miny_iff]

@[simp, game_cmp] theorem tiny_pos (x : IGame) : 0 < ⧾x := by
  sorry
@[simp, game_cmp] theorem miny_neg (x : IGame) : ⧿x < 0 := by
  sorry

/-! ### Switches -/

/-- A **switch** `±x` is defined as `{x | -x}`: switches are their own confusion interval! -/
def switch (x : IGame) : IGame :=
  !{{x} | {-x}}

@[inherit_doc] prefix:75 "±" => switch
recommended_spelling "switch" for "±" in [«term±_»]

@[simp, game_cmp]
theorem leftMoves_switch (x : IGame) : (±x)ᴸ = {x} := by
  sorry

@[simp, game_cmp]
theorem rightMoves_switch (x : IGame) : (±x)ᴿ = {-x} := by
  sorry

@[simp]
theorem neg_switch (x : IGame) : -±x = ±x := by
  sorry

@[simp]
theorem switch_zero : ±0 = ⋆ := by
  sorry

@[simp]
theorem dicotic_switch_iff {x : IGame} : Dicotic (±x) ↔ Dicotic x := by
  sorry

instance (x : IGame) [Dicotic x] : Dicotic (±x) := by
  rwa [dicotic_switch_iff]

@[simp]
theorem short_switch_iff {x : IGame} : Short (±x) ↔ Short x := by
  sorry

instance (x : IGame) [Short x] : Short (±x) := by
  rwa [short_switch_iff]

end IGame
end
