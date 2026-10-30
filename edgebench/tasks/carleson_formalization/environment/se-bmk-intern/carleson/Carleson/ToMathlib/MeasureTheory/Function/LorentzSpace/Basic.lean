module

public import Carleson.ToMathlib.MeasureTheory.Function.LorentzSeminorm.Basic
public import Carleson.ToMathlib.MeasureTheory.Function.LorentzSeminorm.TriangleInequality

@[expose] public section

-- Upstreaming status: would need basic lemmas to be useful (currently the definition is unused)

noncomputable section

open MeasureTheory Filter
open scoped NNReal ENNReal

namespace MeasureTheory


/-- TODO: basic results -/
def Lorentz {α ε : Type*} (p q : ℝ≥0∞) {m0 : MeasurableSpace α} (μ : Measure α)
  [TopologicalSpace ε] [ESeminormedAddMonoid ε] [ContinuousAdd ε] :
    AddSubmonoid (α →ₘ[μ] ε) where
  carrier := {f | eLorentzNorm f p q μ < ⊤}
  zero_mem' := by simp [eLorentzNorm_congr_ae AEEqFun.coeFn_zero, eLorentzNorm_zero]
  add_mem' {f g} hf hg := by
    simp [eLorentzNorm_congr_ae (AEEqFun.coeFn_add f g),
      eLorentzNorm_add_lt_top ⟨f.aestronglyMeasurable, hf⟩ ⟨g.aestronglyMeasurable, hg⟩]

end MeasureTheory
