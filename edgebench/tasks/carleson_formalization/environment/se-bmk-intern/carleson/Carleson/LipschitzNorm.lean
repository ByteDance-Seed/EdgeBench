module

public import Mathlib.Analysis.Normed.Field.Basic
public import Mathlib.Topology.EMetricSpace.Lipschitz
public import Carleson.Defs

@[expose] public section

open Metric Function ENNReal
open scoped NNReal

/-!
# Inhomogeneous Lipschitz norm

This file defines the Lipschitz norm, which probably in some form should end up in Mathlib.
Lemmas about this norm that are proven in Carleson are collected here.

TODO: Assess Mathlib-readiness, complete basic results, optimize imports.
-/

noncomputable section

section Def

variable {𝕜 X : Type*} [NormedField 𝕜] [PseudoMetricSpace X]

/-!
TODO The iLipENorm should be properly generalized to Mathlib standards.
Until then, it is defined in `Defs.lean` instead. See PR #493.

/-- The inhomogeneous Lipschitz norm on a ball. -/
def iLipENorm (φ : X → 𝕜) (x₀ : X) (R : ℝ) : ℝ≥0∞ :=
  (⨆ x ∈ ball x₀ R, ‖φ x‖ₑ) +
  ENNReal.ofReal R * ⨆ (x ∈ ball x₀ R) (y ∈ ball x₀ R) (_ : x ≠ y), ‖φ x - φ y‖ₑ / edist x y
-/

/-- The `NNReal` version of the inhomogeneous Lipschitz norm on a ball, `iLipENorm`. -/
def iLipNNNorm (φ : X → 𝕜) (x₀ : X) (R : ℝ) : ℝ≥0 :=
  (iLipENorm φ x₀ R).toNNReal

end Def

section iLipENorm

variable {𝕜 X : Type*} {x z : X} {R : ℝ} {C C' : ℝ≥0} {φ : X → 𝕜}
variable [MetricSpace X] [NormedField 𝕜]

lemma iLipENorm_le_add (h : ∀ x ∈ ball z R, ‖φ x‖ ≤ C)
    (h' : ∀ x ∈ ball z R, ∀ x' ∈ ball z R, x ≠ x' → ‖φ x - φ x'‖ ≤ C' * dist x x' / R) :
    iLipENorm φ z R ≤ C + C' := by
  sorry

lemma iLipENorm_le (h : ∀ x ∈ ball z R, ‖φ x‖ ≤ 2⁻¹ * C)
    (h' : ∀ x ∈ ball z R, ∀ x' ∈ ball z R, x ≠ x' → ‖φ x - φ x'‖ ≤ 2⁻¹ * C * dist x x' / R) :
    iLipENorm φ z R ≤ C := by
  sorry

lemma enorm_le_iLipENorm_of_mem (hx : x ∈ ball z R) :
    ‖φ x‖ₑ ≤ iLipENorm φ z R := by
  sorry

lemma LipschitzOnWith.of_iLipENorm_ne_top (hφ : iLipENorm φ z R ≠ ⊤) :
    LipschitzOnWith (iLipNNNorm φ z R / R.toNNReal) φ (ball z R) := by
  sorry

lemma continuous_of_iLipENorm_ne_top {z : X} {R : ℝ}
    {φ : X → 𝕜} (hφ : tsupport φ ⊆ ball z R) (h'φ : iLipENorm φ z R ≠ ⊤) :
    Continuous φ := by
  sorry

section iLipNNNorm

lemma norm_le_iLipNNNorm_of_mem (hφ : iLipENorm φ z R ≠ ⊤) (hx : x ∈ ball z R) :
    ‖φ x‖ ≤ iLipNNNorm φ z R := by
  sorry

lemma norm_le_iLipNNNorm_of_subset (hφ : iLipENorm φ z R ≠ ⊤) (h : support φ ⊆ ball z R) :
    ‖φ x‖ ≤ iLipNNNorm φ z R := by
  sorry

end iLipNNNorm

end iLipENorm
