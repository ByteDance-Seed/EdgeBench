/-
Copyright (c) 2025 Violeta Hernández Palacios. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Violeta Hernández Palacios
-/
module

public import Mathlib.Logic.Small.Defs

import Mathlib.Logic.Small.Set
import Mathlib.Logic.Relation
import Mathlib.Order.SetNotation

/-!
# Tree with small sets of branches is small
-/

universe u

public section

open Set

variable {α : Type*} (r : α → α → Prop) [H : ∀ x, Small.{u} {y // r x y}]

private def level [∀ x, Small.{u} {y // r x y}] (x : α) : ℕ → Set α
  | 0 => {x}
  | n + 1 => ⋃₀ ((fun x ↦ {y | r x y}) '' level x n)

private theorem small_level (x : α) : ∀ n, Small.{u} (level r x n)
  := by
  sorry

private theorem small_sUnion_level (x : α) : Small.{u} (⋃₀ range (level r x)) := by
  sorry

instance small_transGen (x : α) : Small.{u} {y // Relation.TransGen r x y} := by
  refine @small_subset _ _ _ (fun y hy ↦ ?_) (small_sUnion_level r x)
  simp_rw [mem_sUnion, mem_range, exists_exists_eq_and]
  induction hy with
  | single =>
    use 1
    simpa [level]
  | tail hy hr IH =>
    obtain ⟨n, hn⟩ := IH
    use n + 1
    simpa [level] using ⟨_, hn, hr⟩

instance small_transGen' [∀ x, Small.{u} {y // r y x}] (x : α) :
    Small.{u} {y // Relation.TransGen r y x} := by
  simp_rw [← Relation.transGen_swap (r := r)]
  infer_instance

instance small_reflTransGen (x : α) : Small.{u} {y // Relation.ReflTransGen r x y} := by
  simp_rw [Relation.reflTransGen_iff_eq_or_transGen]
  exact @small_insert _ _ _ (small_transGen ..)

instance small_reflTransGen' [∀ x, Small.{u} {y // r y x}] (x : α) :
    Small.{u} {y // Relation.ReflTransGen r y x} := by
  simp_rw [← Relation.reflTransGen_swap (r := r)]
  infer_instance
