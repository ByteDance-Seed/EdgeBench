module

public import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic

public section

/- This file formalizes section 11.4 (The proof of the van der Corput Lemma) from the paper. -/

noncomputable section

open scoped Real NNReal
open Complex MeasureTheory Set Bornology

lemma ContinuousOn.intervalIntegrable_Ioo_of_bound
    {a b : ℝ} {C : ℝ} {f : ℝ → ℂ} (hf : ContinuousOn f (Ioo a b))
    (hab : a ≤ b) (h'f : ∀ x ∈ Ioo a b, ‖f x‖ ≤ C) :
    IntervalIntegrable f volume a b := by
  sorry

lemma intervalIntegrable_continuous_mul_lipschitzOnWith
    {a b : ℝ} {K : ℝ≥0} {f g : ℝ → ℂ} (hab : a ≤ b) (hf : Continuous f)
    (hg : LipschitzOnWith K g (Set.Ioo a b)) :
    IntervalIntegrable (fun x ↦ f x * g x) volume a b := by
  sorry

set_option backward.isDefEq.respectTransparency false in
lemma van_der_Corput {a b : ℝ} (hab : a ≤ b) {n : ℤ} {φ : ℝ → ℂ} {B K : ℝ≥0}
    (h1 : LipschitzOnWith K φ (Ioo a b)) (h2 : ∀ x ∈ Ioo a b, ‖φ x‖ ≤ B) :
    ‖∫ x in a..b, exp (I * n * x) * φ x‖ ≤
     2 * π * (b - a) * (B + K * (b - a) / 2) * (1 + |n| * (b - a))⁻¹ := by
  sorry
