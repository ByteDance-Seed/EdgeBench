module

public import Mathlib.Algebra.Group.Action.Pointwise.Set.Basic

public section

open scoped Pointwise

namespace Set
variable {α : Type*}

section Mul
variable [Mul α]

@[to_additive] lemma singleton_mul' (a : α) (s : Set α) : {a} * s = a • s := by
  sorry

open scoped RightActions in
@[to_additive] lemma mul_singleton' (s : Set α) (a : α) : s * {a} = s <• a := by
  sorry

end Mul
end Set
