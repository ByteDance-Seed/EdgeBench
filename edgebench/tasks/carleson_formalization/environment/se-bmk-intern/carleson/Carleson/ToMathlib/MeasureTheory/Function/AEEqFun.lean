module

public import Mathlib.MeasureTheory.Function.AEEqFun
public import Carleson.ToMathlib.Misc

public section

open MeasureTheory Finset

-- Upstreaming status: seems ready for upstreaming

theorem AEEqFun.mk_sum {α E ι : Type*} {m0 : MeasurableSpace α}
    {μ : Measure α} [inst : NormedAddCommGroup E] {s : Finset ι} {f : ι → α → E}
    (hf : ∀ i ∈ s, AEStronglyMeasurable (f i) μ) :
      AEEqFun.mk (∑ i ∈ s, f i) (Finset.aestronglyMeasurable_sum s hf) =
      ∑ i ∈ s.attach, AEEqFun.mk (f ↑i) (hf i (Finset.coe_mem i)) := by
  sorry
