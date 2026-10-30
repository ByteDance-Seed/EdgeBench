module

public import Mathlib.Topology.MetricSpace.Holder

@[expose] public section

open Set Metric Function ENNReal
open scoped NNReal

/-!
# L^∞-normalized t-Hölder norm

This file defines the L^∞-normalized t-Hölder norm, which probably in some form should end up in Mathlib.
Lemmas about this norm that are proven in Carleson are collected here.

TODO: Assess Mathlib-readiness, complete basic results, optimize imports.
-/

noncomputable section

section Def

variable {𝕜 X : Type*} [PseudoMetricSpace X] [NormedField 𝕜]

/-- the L^∞-normalized t-Hölder norm. Defined in ℝ≥0∞ to avoid sup-related issues. -/
def iHolENorm (φ : X → 𝕜) (x₀ : X) (R : ℝ) (t : ℝ) : ℝ≥0∞ :=
  (⨆ (x ∈ ball x₀ R), ‖φ x‖ₑ) + (ENNReal.ofReal R) ^ t *
    ⨆ (x ∈ ball x₀ R) (y ∈ ball x₀ R) (_ : x ≠ y), (‖φ x - φ y‖ₑ / (edist x y) ^ t)

/-- The `NNReal` version of the L^∞-normalized t-Hölder norm, `iHolENorm`. -/
def iHolNNNorm (φ : X → 𝕜) (x₀ : X) (R : ℝ) (t : ℝ) : ℝ≥0 :=
  (iHolENorm φ x₀ R t).toNNReal

end Def

section iHolENorm

variable {X 𝕜 : Type*} {x z : X} {R t : ℝ} {φ : X → 𝕜}
variable [MetricSpace X] [NormedField 𝕜]

lemma enorm_le_iHolENorm_of_mem (hx : x ∈ ball z R) : ‖φ x‖ₑ ≤ iHolENorm φ z R t := by
  sorry

lemma HolderOnWith.of_iHolENorm_ne_top (ht : 0 ≤ t) (hφ : iHolENorm φ z R t ≠ ⊤) :
    HolderOnWith (iHolNNNorm φ z R t / R.toNNReal ^ t) t.toNNReal φ (ball z R) := by
  sorry

lemma continuous_of_iHolENorm_ne_top (ht : 0 < t) (hφ : tsupport φ ⊆ ball z R)
    (h'φ : iHolENorm φ z R t ≠ ∞) :
    Continuous φ := by
  sorry

lemma continuous_of_iHolENorm_ne_top' (ht : 0 < t) (hφ : support φ ⊆ ball z R)
    (h'φ : iHolENorm φ z (2 * R) t ≠ ∞) :
    Continuous φ := by
  sorry

section iHolNNNorm

lemma norm_le_iHolNNNorm_of_mem (hφ : iHolENorm φ z R t ≠ ⊤) (hx : x ∈ ball z R) :
    ‖φ x‖ ≤ iHolNNNorm φ z R t := by
  sorry

lemma norm_le_iHolNNNorm_of_subset (hφ : iHolENorm φ z R t ≠ ⊤) (h : support φ ⊆ ball z R) :
    ‖φ x‖ ≤ iHolNNNorm φ z R t := by
  sorry

end iHolNNNorm

end iHolENorm
