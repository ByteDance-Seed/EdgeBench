module

public import Mathlib.Analysis.RCLike.Basic
public import Mathlib.MeasureTheory.Function.StronglyMeasurable.AEStronglyMeasurable
public import Carleson.ToMathlib.ENorm

--Upstreaming status: ready but not sure if this should go to mathlib

public section

namespace RCLike

open NNReal

theorem enorm_eq_enorm_embedRCLike {α : Type*} {𝕂 : Type*} [RCLike 𝕂] {f : α → ℝ≥0} (x : α) :
    ‖(⇑(algebraMap ℝ 𝕂) ∘ toReal ∘ f) x‖ₑ = ‖f x‖ₑ := by
  sorry

open Topology MeasureTheory in
theorem aestronglyMeasurable_iff_aestronglyMeasurable_embedRCLike {α : Type*}
  {m : MeasurableSpace α} {μ : Measure α} {𝕂 : Type*} [RCLike 𝕂] {f : α → ℝ≥0} :
    AEStronglyMeasurable (⇑(algebraMap ℝ 𝕂) ∘ toReal ∘ f) μ ↔ AEStronglyMeasurable f μ := by
  sorry

end RCLike
