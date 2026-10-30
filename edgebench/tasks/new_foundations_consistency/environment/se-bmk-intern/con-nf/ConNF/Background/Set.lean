import Mathlib.Algebra.Group.Action.Pointwise.Set.Basic
import Mathlib.Order.ConditionallyCompleteLattice.Basic

open scoped symmDiff Pointwise

theorem Set.smul_set_def {α β : Type _} {x : α} {s : Set β} [SMul α β] :
    x • s = (x • ·) '' s := by
  sorry

theorem Set.subset_smul_set {α β : Type _} {x : α} {s t : Set β} [Group α] [MulAction α β] :
    t ⊆ x • s ↔ x⁻¹ • t ⊆ s := by
  sorry

theorem Set.symmDiff_smul_set {α β : Type _} {x : α} {s t : Set β} [Group α] [MulAction α β] :
    x • s ∆ t = (x • s) ∆ (x • t) := by
  sorry

theorem Set.bounded_lt_union {α : Type _} [LinearOrder α] {s t : Set α}
    (hs : s.Bounded (· < ·)) (ht : t.Bounded (· < ·)) :
    (s ∪ t).Bounded (· < ·) := by
  sorry
