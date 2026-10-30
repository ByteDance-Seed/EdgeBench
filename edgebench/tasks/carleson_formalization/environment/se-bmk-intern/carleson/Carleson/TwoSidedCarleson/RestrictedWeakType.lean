module

public import Carleson.ToMathlib.RealInterpolation.LorentzInterpolation
public import Carleson.ToMathlib.MeasureTheory.Function.LocallyIntegrable
public import Carleson.TwoSidedCarleson.MainTheorem

/-! This file contains a reformulation of Theorem 10.0.1.
It is not officially part of the blueprint. -/

@[expose] public section

open MeasureTheory Set Bornology Function ENNReal Metric
open scoped NNReal

noncomputable section

variable {X : Type*} {a : ℕ} [MetricSpace X] [d : DoublingMeasure X (defaultA a : ℕ)]
variable {τ C r R : ℝ} {q q' : ℝ≥0}
variable {F G : Set X}
variable {K : X → X → ℂ} {x x' : X} [IsTwoSidedKernel a K]
variable [CompatibleFunctions ℝ X (defaultA a)] [IsCancellative X (defaultτ a)]

/-! ## Reformulations of Theorem 10.0.1 -/

/- Theorem 10.0.1, reformulation -/
theorem two_sided_metric_carleson_hasRestrictedWeakType [Countable (Θ X)] (ha : 4 ≤ a) (hq : q ∈ Ioc 1 2)
  (hqq' : q.HolderConjugate q')
  (hT : ∀ r > 0, HasBoundedStrongType (czOperator K r) 2 2 volume volume (C_Ts a)) :
      HasRestrictedWeakType (carlesonOperator K) q q' volume volume (C10_0_1 a q) := by
  sorry

theorem two_sided_metric_carleson_hasLorentzType [Countable (Θ X)] (ha : 4 ≤ a)
  (hq : q ∈ Ioo 1 2)
  (hT : ∀ r > 0, HasBoundedStrongType (czOperator K r) 2 2 volume volume (C_Ts a)) :
    HasLorentzType (carlesonOperator K) q 1 q ⊤ volume volume (4 * (C10_0_1 a q) / q) := by
  sorry

--TODO: move
/-- The parameter where linear interpolation between `t₀` and `t₁` results in `t`. -/
def interpolation_param (t₀ t₁ t : ℝ) := (t - t₀) / (t₁ - t₀)

--TODO: move
lemma interpolation_param_interpolation {t₀ t₁ t : ℝ} (h : t₀ ≠ t₁) :
    t = (1 - interpolation_param t₀ t₁ t) * t₀ + interpolation_param t₀ t₁ t * t₁ := by
  sorry

--TODO: move
lemma interpolation_param_mem_Ioo {t₀ t₁ t : ℝ} (h : t ∈ Ioo t₀ t₁) :
    interpolation_param t₀ t₁ t ∈ Ioo 0 1 := by
  sorry

/-- The constant used in `two_sided_metric_carleson_hasStrongType`. -/
def C_carleson_hasStrongType (a : ℕ) (q : ℝ≥0) :=
  let q₀ := (q + 2) / 2;
  let q₁ := (q + 1) / 2;
  let t := (interpolation_param q₀⁻¹ q₁⁻¹ q⁻¹).toNNReal;
  (C_LorentzInterpolation q₀ q₁ q₀ q₁ q (4 * C10_0_1 a q₀ / q₀) (4 * C10_0_1 a q₁ / q₁) 1 t)

/- Theorem 10.0.1, reformulation -/
theorem two_sided_metric_carleson_hasStrongType
  [Countable (Θ X)] (ha : 4 ≤ a) (hq : q ∈ Ioo 1 2)
    (hT : ∀ r > 0, HasBoundedStrongType (czOperator K r) 2 2 volume volume (C_Ts a)) :
      HasStrongType (carlesonOperator K) q q volume volume
        (C_carleson_hasStrongType a q) := by
  sorry

end
