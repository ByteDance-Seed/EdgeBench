/- This file contains the proof of Lemma 11.1.10 (spectral projection bound).
   At the moment, its results are not used as the section about truncated Hilbert transforms
   is still missing.
   Thus, the result here might not yet have the exact form needed later.
-/
module

public import Carleson.Classical.Basic

@[expose] public section

open MeasureTheory AddCircle
open scoped InnerProductSpace

--TODO: move somewhere else?
lemma L2norm_sq_eq {T : ℝ} [hT : Fact (0 < T)] (f : Lp ℂ 2 <| @haarAddCircle T hT) :
    ‖f‖ ^ 2 = ∫ (x : AddCircle T), ‖f x‖ ^ 2 ∂haarAddCircle := by
  sorry

lemma fourierCoeff_eq_innerProduct {T : ℝ} [hT : Fact (0 < T)] [h2 : Fact (1 ≤ 2)] {f : ↥(Lp ℂ 2 haarAddCircle)} {n : ℤ} :
    fourierCoeff f n = ⟪@fourierLp T hT 2 h2 n, f⟫_ℂ := by
  sorry

lemma partialFourierSumL2_norm {T : ℝ} [hT : Fact (0 < T)] [h2 : Fact (1 ≤ (2 : ENNReal))] {f : ↥(Lp ℂ 2 haarAddCircle)} {N : ℕ} :
    ‖partialFourierSumLp 2 N f‖ ^ 2 = ∑ n ∈ Finset.Icc (-Int.ofNat N) N, ‖@fourierCoeff T hT _ _ _ f n‖ ^ 2 := by
  sorry

lemma spectral_projection_bound_sq {T : ℝ} [hT : Fact (0 < T)] (N : ℕ) (f : Lp ℂ 2 <| @haarAddCircle T hT) :
    ‖partialFourierSumLp 2 N f‖ ^ 2 ≤ ‖f‖ ^ 2 := by
  sorry

lemma spectral_projection_bound_sq_integral {N : ℕ} {T : ℝ} [hT : Fact (0 < T)] (f : Lp ℂ 2 <| @haarAddCircle T hT) :
    ∫ t : AddCircle T, ‖partialFourierSumLp 2 N f t‖ ^ 2 ∂haarAddCircle ≤ ∫ t : AddCircle T, ‖f t‖ ^ 2 ∂haarAddCircle := by
  sorry

lemma spectral_projection_bound_lp {N : ℕ} {T : ℝ} [hT : Fact (0 < T)] (f : Lp ℂ 2 <| @haarAddCircle T hT) :
    ‖partialFourierSumLp 2 N f‖ ≤ ‖f‖ := by
  sorry
