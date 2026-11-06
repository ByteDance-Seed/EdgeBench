module

public import Carleson.MetricCarleson.Basic
public import Carleson.MetricCarleson.Truncation

@[expose] public section

open scoped NNReal
open MeasureTheory Set
open ENNReal hiding one_lt_two

noncomputable section

variable {X : Type*} {a : ℕ} [MetricSpace X] {q q' : ℝ≥0} {F G : Set X} {K : X → X → ℂ}
variable [KernelProofData a K] {Q : SimpleFunc X (Θ X)} {f : X → ℂ}

variable (K Q f) in
/-- A monotone sequence of functions converging to `linearizedCarlesonOperator`. -/
def lcoConvergent (n : ℕ) (x : X) : ℝ≥0∞ :=
  ⨆ R₁ ∈ Ioo (2 ^ n)⁻¹ (2 ^ n), ⨆ R₂ ∈ Ioo R₁ (2 ^ n), ‖T_R K Q R₁ R₂ (2 ^ n) f x‖ₑ

lemma monotone_lcoConvergent : Monotone (lcoConvergent K Q f) := by
  sorry

lemma iSup_lcoConvergent : ⨆ n, lcoConvergent K Q f n = linearizedCarlesonOperator Q K f := by
  sorry

lemma measurable_lcoConvergent {n : ℕ} (mf : Measurable f) (nf : (‖f ·‖) ≤ 1) :
    Measurable (lcoConvergent K Q f n) := by
  sorry

/-- Theorem 1.1.2 -/
theorem linearized_metric_carleson [IsCancellative X (defaultτ a)]
    (hq : q ∈ Ioc 1 2) (hqq' : q.HolderConjugate q') (mF : MeasurableSet F) (mG : MeasurableSet G)
    (mf : Measurable f) (nf : (‖f ·‖) ≤ F.indicator 1)
    (hT : ∀ θ : Θ X, HasBoundedStrongType (linearizedNontangentialOperator Q θ K · ·)
      2 2 volume volume (C_Ts a)) :
    ∫⁻ x in G, linearizedCarlesonOperator Q K f x ≤
    C1_0_2 a q * volume G ^ (q' : ℝ)⁻¹ * volume F ^ (q : ℝ)⁻¹ := by
  sorry

theorem linearized_metric_carleson_check : LinearizedMetricCarleson := by
  sorry

end
