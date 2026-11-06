module

public import Carleson.ToMathlib.Misc
public import Carleson.ToMathlib.MeasureTheory.Function.AEEqFun

public section

open MeasureTheory

-- Upstreaming status: seems ready to go; need dependencies merged first

lemma MemLp.toLp_sum {α E : Type*} {m0 : MeasurableSpace α} {p : ENNReal}
    {μ : Measure α} [NormedAddCommGroup E] {ι : Type*} (s : Finset ι)
    {f : ι → α → E} (hf : ∀ i ∈ s, MemLp (f i) p μ) :
    MemLp.toLp (∑ i ∈ s, f i) (memLp_finsetSum' s hf) =
      ∑ i : ↑s, (MemLp.toLp (f i) (hf i (Finset.coe_mem i))) := by
  sorry

namespace MeasureTheory

open ENNReal in
theorem one_le_LpAddConst {p : ENNReal} : 1 ≤ LpAddConst p := by
  sorry

end MeasureTheory
