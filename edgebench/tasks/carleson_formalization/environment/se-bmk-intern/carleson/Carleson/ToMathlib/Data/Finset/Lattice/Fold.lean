module

public import Mathlib.Data.Finset.Lattice.Fold
public import Mathlib.Order.ConditionallyCompleteLattice.Defs
public import Mathlib.Order.ConditionallyCompleteLattice.Indexed
public import Mathlib.Data.Set.Finite.Lattice

public section

-- Upstreaming status: proof could probably be simplified, otherwise ready

-- currently unused
-- proof could probably be simplified if there were more mathlib lemmas about `ciSup` (in `ConditionallyCompleteLinearOrderBot`)
theorem Finset.sup_eq_iSup' {α : Type*} {β : Type*} [ConditionallyCompleteLinearOrderBot β]
  (s : Finset α) (f : α → β) :
    s.sup f = ⨆ a ∈ s, f a := by
  sorry
