/-
Copyright (c) 2024 Jeremy Tan. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jeremy Tan, Joachim Breitner
-/
module

public import Mathlib.Order.KrullDimension

/-!
# Minimal and maximal layers of a set

This file defines `Set.minLayer` and `Set.maxLayer` as the sets obtained from iterated application
of `Minimal`/`Maximal` on a set, excluding earlier layers.

## Main declarations

* `Set.minLayer` (`Set.maxLayer`): the `n`th minimal (maximal) layer of the given set `A`.
* `Set.pairwiseDisjoint_minLayer` (`Set.pairwiseDisjoint_maxLayer`),
  `Set.isAntichain_minLayer` (`Set.isAntichain_maxLayer`):
  minimal (maximal) layers are pairwise disjoint antichains.
* `Set.iUnion_minLayer_iff_bounded_series`: if the length of `LTSeries` in `A` is bounded,
  `A` equals the union of its `minLayer`s up to `n`.
-/

@[expose] public section

-- Upstreaming status: the file generally looks useful and should go into mathlib;
-- the code can probably be polished and golfed more

namespace Set

variable {α : Type*} [PartialOrder α]

/-- The `n`th minimal layer of `A`. -/
def minLayer (A : Set α) (n : ℕ) : Set α :=
  {a | Minimal (· ∈ A \ ⋃ (k < n), A.minLayer k) a}

/-- The `n`th maximal layer of `A`. -/
def maxLayer (A : Set α) (n : ℕ) : Set α :=
  A.minLayer (α := αᵒᵈ) n

/-- The elements above `A`'s `n` minimal layers. -/
def layersAbove (A : Set α) (n : ℕ) : Set α :=
  A \ ⋃ (k ≤ n), A.minLayer k

/-- The elements below `A`'s `n` maximal layers. -/
def layersBelow (A : Set α) (n : ℕ) : Set α :=
  A \ ⋃ (k ≤ n), A.maxLayer k

variable {A : Set α} {m n : ℕ} {a : α}

lemma maxLayer_def : A.maxLayer n = {a | Maximal (· ∈ A \ ⋃ (k < n), A.maxLayer k) a} := by
  sorry

lemma minLayer_subset : A.minLayer n ⊆ A := by
  sorry

lemma maxLayer_subset : A.maxLayer n ⊆ A := by
  sorry

lemma layersAbove_subset : A.layersAbove n ⊆ A := by
  sorry

lemma layersBelow_subset : A.layersBelow n ⊆ A := by
  sorry

-- XXX(MR): should this and `maxLayer_zero` be simp?
lemma minLayer_zero : A.minLayer 0 = {a | Minimal (· ∈ A) a} := by
  sorry

lemma maxLayer_zero : A.maxLayer 0 = {a | Maximal (· ∈ A) a} := by
  sorry

lemma disjoint_minLayer_of_ne (h : m ≠ n) : Disjoint (A.minLayer m) (A.minLayer n) := by
  sorry

lemma disjoint_maxLayer_of_ne (h : m ≠ n) : Disjoint (A.maxLayer m) (A.maxLayer n) := by
  sorry

lemma pairwiseDisjoint_minLayer : univ.PairwiseDisjoint A.minLayer := by
  sorry

lemma pairwiseDisjoint_maxLayer : univ.PairwiseDisjoint A.maxLayer := by
  sorry

lemma isAntichain_minLayer : IsAntichain (· ≤ ·) (A.minLayer n) := by
  sorry

lemma isAntichain_maxLayer : IsAntichain (· ≤ ·) (A.maxLayer n) := by
  sorry

lemma exists_le_in_minLayer_of_le (ha : a ∈ A.minLayer n) (hm : m ≤ n) :
    ∃ c ∈ A.minLayer m, c ≤ a := by
  sorry

lemma exists_le_in_maxLayer_of_le (ha : a ∈ A.maxLayer n) (hm : m ≤ n) :
    ∃ c ∈ A.maxLayer m, a ≤ c := by
  sorry

open Order

-- XXX: is this in mathlib already/can it also be removed?
lemma subtype_mk_minimal_iff (α : Type*) [Preorder α]
    (s : Set α) (t : Set s) (x : α) (hx : x ∈ s) :
    Minimal (· ∈ t) (⟨x, hx⟩ : s) ↔ Minimal (fun y ↦ ∃ h, y ∈ s ∧ ⟨y, h⟩ ∈ t) x := by
  sorry

/-- `A.minLayer n` comprises exactly `A`'s elements of height `n`. -/
lemma minLayer_eq_setOf_height : A.minLayer n = {x | ∃ hx : x ∈ A, height (⟨x, hx⟩ : A) = n} := by
  sorry

lemma iUnion_lt_minLayer_iff_bounded_series :
    ⋃ (k < n), A.minLayer k = A ↔ ∀ p : LTSeries A, p.length < n := by
  sorry

/-- `A` equals the union of its `minLayer`s up to `n` iff
all `LTSeries` in `A` have length at most `n`. -/
lemma iUnion_minLayer_iff_bounded_series :
    ⋃ (k ≤ n), A.minLayer k = A ↔ ∀ p : LTSeries A, p.length ≤ n := by
  sorry

lemma exists_le_in_layersAbove_of_le [Finite α] (ha : a ∈ A.layersAbove n) (hm : m ≤ n) :
    ∃ c ∈ A.minLayer m, c ≤ a := by
  sorry

lemma exists_le_in_layersBelow_of_le [Finite α] (ha : a ∈ A.layersBelow n) (hm : m ≤ n) :
    ∃ c ∈ A.maxLayer m, a ≤ c := by
  sorry

end Set
