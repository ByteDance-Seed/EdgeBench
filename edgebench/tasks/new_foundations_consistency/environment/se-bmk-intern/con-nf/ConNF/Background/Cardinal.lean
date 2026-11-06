import Mathlib.SetTheory.Cardinal.Regular
import ConNF.Background.Rel

universe u v

namespace Function

open Cardinal

/-- An alternate spelling of `Function.graph`, useful in proving inequalities of cardinals. -/
def graph' {α β : Type _} (f : α → β) : Set (α × β) :=
  {(x, y) | y = f x}

end Function

namespace Cardinal

theorem mk_iUnion_le_of_le {α β : Type _} {f : α → Set β}
    (c : Cardinal) (h : ∀ (x : α), #(f x) ≤ c) :
    #(⋃ (x : α), f x) ≤ #α * c := by
  sorry

theorem lift_isRegular (c : Cardinal.{u}) (h : IsRegular c) : IsRegular (lift.{v} c) := by
  sorry

theorem compl_nonempty_of_mk_lt {α : Type _} {s : Set α} (h : #s < #α) : sᶜ.Nonempty := by
  sorry

theorem card_codom_le_of_coinjective {α β : Type _} {r : Rel α β} (hr : r.Coinjective) :
    #r.codom ≤ #r.dom := by
  sorry

end Cardinal
