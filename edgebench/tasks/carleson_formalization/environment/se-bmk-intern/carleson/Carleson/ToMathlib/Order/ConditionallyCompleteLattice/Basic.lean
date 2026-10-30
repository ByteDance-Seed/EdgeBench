module

public import Mathlib.Order.ConditionallyCompleteLattice.Basic
public import Mathlib.Order.ConditionallyCompleteLattice.Indexed

public section

-- Upstreaming status: ready

theorem ciSup_le_ciSup {α : Type*} {ι ι' : Sort*} [Nonempty ι] [ConditionallyCompleteLattice α]
  {f : ι → α} {g : ι' → α} (h₀ : ∀ i, ∃ j, f i ≤ g j) (hg : BddAbove (Set.range g)) :
    ⨆ i, f i ≤ ⨆ j, g j := by
  sorry

--currently unused
theorem ciSup_eq_ciSup {α : Type*} {ι ι' : Sort*} [ConditionallyCompleteLinearOrder α]
  {f : ι → α} {g : ι' → α} (h₀ : ∀ i, ∃ j, f i ≤ g j) (h₁ : ∀ j, ∃ i, g j ≤ f i) :
    ⨆ i, f i = ⨆ j, g j := by
  sorry

@[simp]
theorem WithTop.iSup_coe_eq_top' {α : Type*} [ConditionallyCompleteLinearOrderBot α] [NoTopOrder α] :
  ⨆ (i : α), ↑i = (⊤ : WithTop α) := by
  sorry
