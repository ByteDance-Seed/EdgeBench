module

public import Mathlib.MeasureTheory.Integral.IntervalIntegral.Periodic
public import Mathlib.Analysis.Convolution
public import Carleson.ToMathlib.Topology.Instances.AddCircle.Defs
import Mathlib.Algebra.Order.Interval.Set.Group

@[expose] public section

-- Upstreaming status: looks nice and clean
-- First lemmas augment mathlib ones (or replace some proofs),
-- remaining ones are new (and can perhaps be a new file indeed).

open Set Function MeasureTheory MeasureTheory.Measure TopologicalSpace AddSubgroup intervalIntegral

open scoped MeasureTheory NNReal ENNReal

open scoped Convolution

section AE

variable (T : ℝ) [hT : Fact (0 < T)]

instance AddCircle.noAtoms_volume : NoAtoms (volume : Measure (AddCircle T)) where
  measure_singleton x := by simpa [hT.out.le] using AddCircle.volume_closedBall T (x := x) 0

variable {B : Type*} {T a : ℝ} [hT : Fact (0 < T)] (f : ℝ → B)

theorem AddCircle.liftIoc_ae_eq_liftIco : liftIoc T a f =ᵐ[volume] liftIco T a f := by
  sorry

end AE

namespace AddCircle

variable (T : ℝ) [hT : Fact (0 < T)]

-- Add before `measurableEquivIoc`
theorem measurable_equivIoc (a : ℝ) : Measurable (equivIoc T a) := by
  sorry

theorem measurable_equivIco (a : ℝ) : Measurable (equivIco T a) := by
  sorry

-- Replacement for existing proof of `measurableEquivIoc` now that the proof of `measurable_toFun`
-- is extracted as a separate lemma. The name is primed here only to avoid a collision.
noncomputable def measurableEquivIoc' (a : ℝ) : AddCircle T ≃ᵐ Ioc a (a + T) where
  toEquiv := equivIoc T a
  measurable_toFun := measurable_equivIoc T a
  measurable_invFun := AddCircle.measurable_mk'.comp measurable_subtype_coe

-- Replacement for existing proof of `measurableEquivIco` now that the proof of `measurable_toFun`
-- is extracted as a separate lemma. The name is primed here only to avoid a collision.
noncomputable def measurableEquivIco' (a : ℝ) : AddCircle T ≃ᵐ Ico a (a + T) where
  toEquiv := equivIco T a
  measurable_toFun := measurable_equivIco T a
  measurable_invFun := AddCircle.measurable_mk'.comp measurable_subtype_coe

variable {E : Type*} (T a : ℝ) [hT : Fact (0 < T)] {f : ℝ → E}

lemma map_subtypeVal_map_equivIoc_volume :
    (volume.map (equivIoc T a)).map Subtype.val = volume.restrict (Ioc a (a + T)) := by
  sorry

end AddCircle

namespace MeasureTheory

open AddCircle

variable {E : Type*} (T a : ℝ) [hT : Fact (0 < T)] {f : ℝ → E}

@[fun_prop] protected theorem AEStronglyMeasurable.liftIoc [TopologicalSpace E]
    (hf : AEStronglyMeasurable f) : AEStronglyMeasurable (liftIoc T a f) := by
  sorry

@[fun_prop] protected theorem AEStronglyMeasurable.liftIco [TopologicalSpace E]
    (hf : AEStronglyMeasurable f) : AEStronglyMeasurable (liftIco T a f) := by
  sorry

@[fun_prop] protected theorem AEMeasurable.liftIoc [MeasurableSpace E] (hf : AEMeasurable f) :
    AEMeasurable (liftIoc T a f) := by
  sorry

@[fun_prop] protected theorem AEMeasurable.liftIco [MeasurableSpace E] (hf : AEMeasurable f) :
    AEMeasurable (liftIco T a f) := by
  sorry

theorem map_coe_addCircle_volume_eq :
    Measure.map (fun (x : ℝ) ↦ (x : AddCircle T)) volume =
      (⊤ : ℝ≥0∞) • (volume : Measure (AddCircle T)) := by
  sorry

theorem quasiMeasurePreserving_coe_addCircle :
    QuasiMeasurePreserving (fun (x : ℝ) ↦ (x : AddCircle T)) := by
  sorry

end MeasureTheory

namespace AddCircle

section Convolution

variable {𝕜 E E' F : Type*} [NormedAddCommGroup E] [NormedAddCommGroup E'] [NormedAddCommGroup F]
  [NontriviallyNormedField 𝕜] [NormedSpace 𝕜 E] [NormedSpace 𝕜 E'] [NormedSpace 𝕜 F]
  [NormedSpace ℝ F] (L : E →L[𝕜] E' →L[𝕜] F) {f : ℝ → E} {g : ℝ → E'}

variable {T : ℝ} [hT : Fact (0 < T)] (a : ℝ)

theorem liftIco_convolution_liftIco (hf : f.Periodic T) (hg : g.Periodic T) :
    liftIco T a f ⋆[L] liftIco T a g = liftIco T a fun x ↦ ∫ y in a..a+T, L (f y) (g (x - y)) := by
  sorry

theorem liftIoc_convolution_liftIoc (hf : f.Periodic T) (hg : g.Periodic T) :
    liftIoc T a f ⋆[L] liftIoc T a g = liftIoc T a fun x ↦ ∫ y in a..a+T, L (f y) (g (x - y)) := by
  sorry

end Convolution

section eLpNorm

variable {𝕜 B : Type*} [NormedAddCommGroup B]

variable (T : ℝ) [hT : Fact (0 < T)] (a a' : ℝ) {f : ℝ → B} (hf : AEStronglyMeasurable f)
include hf

/-- The norm of the lift of a function `f` is equal to the norm of `f` on that period. -/
theorem eLpNorm_liftIoc (p : ℝ≥0∞) :
    eLpNorm (AddCircle.liftIoc T a f) p = eLpNorm ((Set.Ioc a (a + T)).indicator f) p := by
  sorry

/-- The norm of the lift of a function `f` is equal to the norm of `f` on that period. -/
theorem eLpNorm_liftIoc' (p : ℝ≥0∞) :
    eLpNorm (AddCircle.liftIoc T a f) p = eLpNorm f p (volume.restrict ((Set.Ioc a (a + T)))) := by
  sorry

/-- The norm of the lift of a function `f` is equal to the norm of `f` on that period. -/
theorem eLpNorm_liftIco (p : ℝ≥0∞) :
    eLpNorm (AddCircle.liftIco T a f) p = eLpNorm ((Set.Ico a (a + T)).indicator f) p := by
  sorry

/-- The norm of the lift of a function `f` is equal to the norm of `f` on that period. -/
theorem eLpNorm_liftIco' (p : ℝ≥0∞) :
    eLpNorm (AddCircle.liftIco T a f) p = eLpNorm f p (volume.restrict (Set.Ico a (a + T))) := by
  sorry

/-- The norm of the lift of a periodic function `f` is equal to the norm of `f` on any period. -/
theorem eLpNorm_liftIoc_of_periodic (hfT : Periodic f T) (p : ℝ≥0∞) :
    eLpNorm (AddCircle.liftIoc T a f) p = eLpNorm ((Set.Ioc a' (a' + T)).indicator f) p := by
  sorry

/-- The norm of the lift of a periodic function `f` is equal to the norm of `f` on any period. -/
theorem eLpNorm_liftIoc_of_periodic' (hfT : Periodic f T) (p : ℝ≥0∞) :
    eLpNorm (AddCircle.liftIoc T a f) p = eLpNorm f p (volume.restrict (Set.Ioc a' (a' + T))) := by
  sorry

/-- The norm of the lift of a periodic function `f` is equal to the norm of `f` on any period. -/
theorem eLpNorm_liftIco_of_periodic (hfT : Periodic f T) (p : ℝ≥0∞) :
    eLpNorm (AddCircle.liftIco T a f) p = eLpNorm ((Set.Ico a' (a' + T)).indicator f) p := by
  sorry

/-- The norm of the lift of a periodic function `f` is equal to the norm of `f` on any period. -/
theorem eLpNorm_liftIco_of_periodic' (hfT : Periodic f T) (p : ℝ≥0∞) :
    eLpNorm (AddCircle.liftIco T a f) p = eLpNorm f p (volume.restrict (Set.Ico a' (a' + T))) := by
  sorry

end eLpNorm

end AddCircle
