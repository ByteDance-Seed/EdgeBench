module

public import Carleson.ToMathlib.MeasureTheory.Measure.NNReal
public import Carleson.ToMathlib.Order.Interval.Set.Disjoint
public import Mathlib.MeasureTheory.Function.AEEqOfLIntegral

public section

-- Upstreaming status: useful and ready to go
namespace MeasureTheory

-- TODO: generalize this to other measures and density functions?
lemma aeMeasurable_withDensity_inv {f : NNReal → ENNReal} (hf : AEMeasurable f) :
    AEMeasurable f (volume.withDensity (fun t ↦ t⁻¹)) := by
  sorry

-- analogous to `aemeasurable_Ioi_of_forall_Ioc` in mathlib
open MeasureTheory MeasureTheory.Measure Filter Set Function ENNReal in
theorem aemeasurable_Ici_of_forall_Icc {α : Type*} {m0 : MeasurableSpace α} {μ : Measure α} {β : Type*}
  {mβ : MeasurableSpace β} [LinearOrder α] [(atTop : Filter α).IsCountablyGenerated] {x : α} {g : α → β}
  (g_meas : ∀ t ≥ x, AEMeasurable g (μ.restrict (Set.Icc x t))) : AEMeasurable g (μ.restrict (Set.Ici x)) := by
  sorry

open MeasureTheory MeasureTheory.Measure Filter Set Function ENNReal in
theorem aemeasurable_Ici_of_forall_Icc' {α : Type*} {m0 : MeasurableSpace α} [MeasurableSingletonClass α]
  {μ : Measure α} {β : Type*}
  {mβ : MeasurableSpace β} [LinearOrder α] [(atTop : Filter α).IsCountablyGenerated] {x : α} {g : α → β}
  (g_meas : ∀ t > x, AEMeasurable g (μ.restrict (Set.Icc x t))) : AEMeasurable g (μ.restrict (Set.Ici x)) := by
  sorry

@[fun_prop, measurability]
lemma AEMeasurable.withDensity {α β : Type*} {m0 : MeasurableSpace α} {μ : Measure α}
  {mβ : MeasurableSpace β} {f : α → β} {d : α → ENNReal} (hf : AEMeasurable f μ) :
    AEMeasurable f (μ.withDensity d) := by
  sorry

@[fun_prop, measurability]
lemma AEStronglyMeasurable.withDensity {α β : Type*} {m0 : MeasurableSpace α} {μ : Measure α}
  [TopologicalSpace β] {f : α → β} {d : α → ENNReal} (hf : AEStronglyMeasurable f μ) :
    AEStronglyMeasurable f (μ.withDensity d) := by
  sorry

end MeasureTheory
