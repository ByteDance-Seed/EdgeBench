module

public import Mathlib.Order.ConditionallyCompleteLattice.Indexed

-- Upstreaming status: ready

public section ConditionallyCompleteLinearOrderBot

variable {α : Type*} {ι : Sort*} {κ : ι → Sort*}
variable [ConditionallyCompleteLinearOrderBot α] {a : α}

theorem ciSup₂_le' {f : ∀ i, κ i → α} (h : ∀ i j, f i j ≤ a) : ⨆ (i) (j), f i j ≤ a := by
  sorry

theorem exists_lt_of_lt_ciSup₂' {f : ∀ i, κ i → α} (h : a < ⨆ (i) (j), f i j) :
    ∃ i j, a < f i j := by
  sorry

end ConditionallyCompleteLinearOrderBot
