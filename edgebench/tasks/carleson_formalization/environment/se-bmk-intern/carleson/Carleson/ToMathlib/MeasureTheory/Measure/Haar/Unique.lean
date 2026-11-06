module

public import Mathlib.MeasureTheory.Measure.Haar.Unique

@[expose] public section

open MeasureTheory Measure
open scoped ENNReal

-- Upstreaming status: ready to be PRed, perhaps after golfing the proof a bit

variable {G : Type*} [TopologicalSpace G] [Group G] [IsTopologicalGroup G]
  [MeasurableSpace G] [BorelSpace G]

namespace MeasureTheory.Measure

-- This is a generalization of `IsHaarMeasure.isInvInvariant_of_regular`, using the same proof.
-- Now `IsHaarMeasure.isInvInvariant_of_regular` can be proven as a special case.
/-- Any regular bi-invariant Haar measure is invariant under inversion. -/
@[to_additive /-- Any regular bi-invariant additive Haar measure is invariant under negation. -/]
instance (priority := 100) IsHaarMeasure.isInvInvariant_of_isMulRightInvariant (μ : Measure G)
    [μ.IsHaarMeasure] [LocallyCompactSpace G] [μ.IsMulRightInvariant] [μ.Regular] :
    IsInvInvariant μ := by
  constructor
  let c : ℝ≥0∞ := haarScalarFactor μ.inv μ
  have hc : μ.inv = c • μ := isMulLeftInvariant_eq_smul_of_regular μ.inv μ
  have : map Inv.inv (map Inv.inv μ) = c ^ 2 • μ := by
    rw [← inv_def μ, hc, Measure.map_smul, ← inv_def μ, hc, smul_smul, pow_two]
  have μeq : μ = c ^ 2 • μ := by
    simpa [map_map continuous_inv.measurable continuous_inv.measurable] using this
  have K : TopologicalSpace.PositiveCompacts G := Classical.arbitrary _
  have : c ^ 2 * μ K = 1 ^ 2 * μ K := by
    conv_rhs => rw [μeq]
    simp
  have : c ^ 2 = 1 ^ 2 :=
    (ENNReal.mul_left_inj (measure_pos_of_nonempty_interior _ K.interior_nonempty).ne'
      K.isCompact.measure_lt_top.ne).1 this
  have : c = 1 := (ENNReal.pow_right_strictMono two_ne_zero).injective this
  rw [hc, this, one_smul]

section CommGroup

variable {G : Type*} [CommGroup G] [TopologicalSpace G] [IsTopologicalGroup G]
  [MeasurableSpace G] [BorelSpace G] (μ : Measure G) [IsHaarMeasure μ]

-- This is the new proof of `IsHaarMeasure.isInvInvariant_of_regular`; the prime is only used on
-- the name temporarily to avoid a collision.
/-- Any regular Haar measure is invariant under inversion in an abelian group. -/
@[to_additive /-- Any regular additive Haar measure is invariant under negation
  in an abelian group. -/]
instance (priority := 100) IsHaarMeasure.isInvInvariant_of_regular'
    [LocallyCompactSpace G] [μ.Regular] : μ.IsInvInvariant :=
  IsHaarMeasure.isInvInvariant_of_isMulRightInvariant μ

end CommGroup

end MeasureTheory.Measure
