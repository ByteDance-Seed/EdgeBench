module

public import Mathlib.Order.CompleteLattice.Basic
public import Carleson.ToMathlib.Order.ConditionallyCompleteLattice.Basic

public section

-- Upstreaming status: ready but maybe unnecessary

--currently unused
theorem iSup_eq_iSup {α : Type*} {ι ι' : Sort*} [CompleteLattice α] {f : ι → α} {g : ι' → α}
  (h₀ : ∀ i, ∃ j, f i ≤ g j) (h₁ : ∀ j, ∃ i, g j ≤ f i) :
    ⨆ i, f i = ⨆ j, g j := by
  sorry
