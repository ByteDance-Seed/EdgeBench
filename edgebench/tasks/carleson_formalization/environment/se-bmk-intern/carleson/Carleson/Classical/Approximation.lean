module

public import Carleson.Classical.Basic
public import Mathlib.Analysis.Calculus.BumpFunction.Convolution
public import Mathlib.Analysis.PSeries

public section

/- This file contains the arguments from section 11.2 (smooth functions) from the blueprint. -/

noncomputable section

open Finset Real

local notation "S_" => partialFourierSum

open scoped ContDiff

lemma close_smooth_approx_periodic {f : ℝ → ℂ} (unicontf : UniformContinuous f)
  (periodicf : f.Periodic (2 * π)) {ε : ℝ} (εpos : ε > 0) :
    ∃ (f₀ : ℝ → ℂ), ContDiff ℝ ∞ f₀ ∧ f₀.Periodic (2 * π) ∧
      ∀ x, ‖f x - f₀ x‖ ≤ ε := by
  sorry

-- local lemma
lemma summable_of_le_on_nonzero {f g : ℤ → ℝ} (hgpos : 0 ≤ g) (hgf : ∀ i ≠ 0, g i ≤ f i)
    (summablef : Summable f) : Summable g := by
  sorry

lemma continuous_bounded {f : ℝ → ℂ} (hf : ContinuousOn f (Set.Icc 0 (2 * π))) :
    ∃ C, ∀ x ∈ Set.Icc 0 (2 * π), ‖f x‖ ≤ C := by
  sorry

/-TODO: might be generalized assumptions might be weakened, and constant given explicitely -/
lemma fourierCoeffOn_bound {f : ℝ → ℂ} (f_continuous : Continuous f) :
    ∃ C, ∀ n, ‖fourierCoeffOn Real.two_pi_pos f n‖ ≤ C := by
  sorry

/-TODO: Assumptions might be weakened. -/
lemma periodic_deriv {𝕜 : Type} [NontriviallyNormedField 𝕜] {F : Type} [NormedAddCommGroup F] [NormedSpace 𝕜 F]
    {f : 𝕜 → F} {T : 𝕜} (diff_f : ContDiff 𝕜 1 f) (periodic_f : f.Periodic T) : (deriv f).Periodic T := by
  sorry

/-TODO: might be generalized. -/
/-TODO: The assumption periodicf is probably not needed actually. -/
lemma fourierCoeffOn_ContDiff_two_bound {f : ℝ → ℂ} (periodicf : f.Periodic (2 * π)) (fdiff : ContDiff ℝ 2 f) :
    ∃ C, ∀ n ≠ 0, ‖fourierCoeffOn Real.two_pi_pos f n‖ ≤ C / n ^ 2 := by
  sorry

open Topology Filter

/-TODO : Assumptions might be weakened-/
lemma int_sum_nat {β : Type*} [AddCommGroup β] [TopologicalSpace β] [ContinuousAdd β] {f : ℤ → β} {a : β} (hfa : HasSum f a) :
    Filter.Tendsto (fun N ↦ ∑ n ∈ Icc (-Int.ofNat ↑N) N, f n) Filter.atTop (𝓝 a) := by
  sorry

lemma fourierConv_ofTwiceDifferentiable {f : ℝ → ℂ} (periodicf : f.Periodic (2 * π))
    (fdiff : ContDiff ℝ 2 f) {ε : ℝ} (εpos : ε > 0) :
    ∃ N₀, ∀ N > N₀, ∀ x ∈ Set.Icc 0 (2 * π), ‖f x - S_ N f x‖ ≤ ε := by
  sorry
