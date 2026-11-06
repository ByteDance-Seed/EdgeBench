module

public import Mathlib.Data.Set.Card
public import PFR.Mathlib.Data.Set.Basic
public import PFR.Mathlib.Data.Set.Insert

public section

namespace Set
variable {α : Type*}

-- TODO: Rename `ncard_singleton_inter` to `ncard_singleton_inter_le_one`

lemma ncard_singleton_inter' (a : α) (s : Set α) [Decidable (a ∈ s)] :
    ({a} ∩ s).ncard = if a ∈ s then 1 else 0 := by
  sorry

end Set
