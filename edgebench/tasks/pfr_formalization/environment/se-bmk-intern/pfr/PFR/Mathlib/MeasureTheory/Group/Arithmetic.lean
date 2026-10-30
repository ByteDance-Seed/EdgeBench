module

public import Mathlib.MeasureTheory.Group.Arithmetic

public section

variable {ι α β M : Type*} {mα : MeasurableSpace α} {mβ : MeasurableSpace β}
  {mM : MeasurableSpace M} [CommMonoid M] [MeasurableMul₂ M]

set_option linter.flexible false in
-- TODO: Replace `Finset.measurable_prod'`
/-- Compositional version of `Finset.measurable_prod` for use by `fun_prop`. -/
@[to_additive (attr := measurability, fun_prop)
/-- Compositional version of `Finset.measurable_sum` for use by `fun_prop`. -/]
lemma Finset.measurable_prod'' {f : ι → α → β → M} {g : α → β} {s : Finset ι}
    (hf : ∀ i ∈ s, Measurable ↿(f i)) (hg : Measurable g) :
    Measurable fun a ↦ (∏ i ∈ s, f i a) (g a) := by
  sorry
