module

public import Mathlib.Data.Set.Basic

public section

namespace Set
variable {α : Type*} {s t : Set α}

-- TODO: Rename `inter_eq_left` to `inter_eq_left_iff`
@[simp] alias ⟨_, inter_eq_left'⟩ := inter_eq_left
@[simp] alias ⟨_, inter_eq_right'⟩ := inter_eq_right

end Set
