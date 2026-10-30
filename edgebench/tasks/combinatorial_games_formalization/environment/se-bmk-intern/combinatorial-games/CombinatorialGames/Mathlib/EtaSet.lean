/-
Copyright (c) 2026 Yan Yablonovskiy. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Yan Yablonovskiy
-/
module

public import Mathlib.Algebra.Field.Rat
public import Mathlib.Algebra.Order.Field.Basic
public import Mathlib.Algebra.Order.Ring.Rat
public import Mathlib.Data.Finset.DenselyOrdered
public import Mathlib.Order.Interval.Set.Infinite
public import Mathlib.Order.Types.Defs
public import Mathlib.SetTheory.Ordinal.Basic

public section

namespace Order
open Cardinal

universe u v

/--
If `α` is a type with a `LinearOrder`, and `c` is some `Cardinal` in the same universe, then
`IsEta c α` states that for any two subsets `X Y : Set α` of cardinality less than `c`, if every
element of `X` is less than every element of `Y`, then there is some `(z : α)` greater than all
elements of `X` and less than all elements of `Y`.

In the literature, an η_o ordered set would be a `IsEta ℵ_o` order, but this definition is more
general.
-/
@[expose]
def IsEta (c : Cardinal.{u}) (α : Type u) [LinearOrder α] : Prop :=
  ∀ ⦃s t : Set α⦄, #s < c → #t < c →
    (∀ x ∈ s, ∀ y ∈ t, x < y) → ∃ z, (∀ x ∈ s, x < z) ∧ (∀ y ∈ t, z < y)

namespace IsEta

open Order OrderType

variable {α β γ : Type u} [LinearOrder α] [LinearOrder β] [LinearOrder γ] {c c' : Cardinal.{u}}

/-- `IsEta` is unchanged under the order dual. -/
theorem dual_iff : IsEta c α ↔ IsEta c αᵒᵈ := by
  sorry

protected alias ⟨_, dual⟩ := dual_iff

to_dual_insert_cast IsEta := propext dual_iff

@[to_dual none]
theorem exists_between (h : IsEta c α) {s t : Set α} (hs : #s < c) (ht : #t < c)
    (hB : ∀ x ∈ s, ∀ y ∈ t, x < y) : ∃ z, (∀ x ∈ s, x < z) ∧ (∀ y ∈ t, z < y) := by
  sorry

protected theorem zero : IsEta 0 α := by
  sorry

protected theorem mono (h : IsEta c α) (hc : c' ≤ c) : IsEta c' α := by
  sorry

protected theorem one [Nonempty α] : IsEta 1 α := by
  sorry

protected theorem nonempty (hc : c ≠ 0) (h : IsEta c α) : Nonempty α := by
  sorry

protected theorem denselyOrdered (hc : 1 < c) (h : IsEta c α) : DenselyOrdered α := by
  sorry

@[to_dual]
protected theorem noMinOrder (hc : 1 < c) (h : IsEta c α) : NoMinOrder α := by
  sorry

protected theorem infinite (hc : 1 < c) (h : IsEta c α) [Nonempty α] : Infinite α := by
  sorry

private theorem of_isEta_iso (e : α ≃o β) : IsEta c α → IsEta c β := by
  sorry

/-- Order-isomorphic linear orders satisfy `IsEta` for the same cardinal. -/
protected theorem congr (e : α ≃o β) : IsEta c α ↔ IsEta c β := by
  sorry

theorem orderType_eq (h : type α = type β) : IsEta c α = IsEta c β := by
  sorry

protected theorem aleph0 [Nonempty α] [DenselyOrdered α] [NoMaxOrder α] [NoMinOrder α] :
    IsEta aleph0 α := by
  sorry

theorem Rat.isEta_aleph0 : IsEta aleph0 ℚ := by
  sorry

end IsEta

end Order
