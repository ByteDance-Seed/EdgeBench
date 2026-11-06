import Mathlib.Tactic
import Mathlib.Topology.Instances.Irrational
import Analysis.Section_11_4

/-!
# Analysis I, Section 11.7: A non-Riemann integrable function

I have attempted to make the translation as faithful a paraphrasing as possible of the original
text. When there is a choice between a more idiomatic Lean solution and a more faithful
translation, I have generally chosen the latter. In particular, there will be places where the
Lean code could be "golfed" to be more elegant and idiomatic, but I have consciously avoided
doing so.

Main constructions and results of this section:
- An example of a bounded function on a compact interval that is not Riemann integrable.

-/

namespace Chapter11
open BoundedInterval Chapter9

/-- Proposition 11.7.1 -/
theorem not_integrable : BddOn f_9_3_21 (Icc 0 1) ∧ ¬ IntegrableOn f_9_3_21 (Icc 0 1) := by
  sorry

end Chapter11
