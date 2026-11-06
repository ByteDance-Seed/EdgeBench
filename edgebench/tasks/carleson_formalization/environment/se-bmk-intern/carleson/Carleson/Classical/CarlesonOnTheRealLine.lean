module

public import Carleson.Classical.CarlesonOperatorReal
public import Carleson.Classical.HilbertStrongType
public import Carleson.Classical.VanDerCorput
public import Carleson.TwoSidedCarleson.MainTheorem

@[expose] public section

/-
This file contains the proof of Lemma 11.1.4 (real Carleson), from section 11.7.
We need to verify the assumptions of the two-sided metric Carleson theorem.
All smaller ones are done but the estimate for the truncated Hilbert transform is still missing.
-/

noncomputable section

open MeasureTheory Function Metric Bornology Real

lemma localOscillation_on_emptyset {X : Type} [PseudoMetricSpace X] {f g : C(X, ℝ)} :
    localOscillation ∅ f g = 0 := by
  sorry

lemma localOscillation_on_empty_ball {X : Type} [PseudoMetricSpace X] {x : X} {f g : C(X, ℝ)}
    {R : ℝ} (R_nonpos : R ≤ 0) : localOscillation (Metric.ball x R) f g = 0 := by
  sorry

section

open ENNReal MeasureTheory

section

def integer_linear (n : ℤ) : C(ℝ, ℝ) := ⟨fun (x : ℝ) ↦ n * x, by fun_prop⟩

local notation "θ" => integer_linear

set_option quotPrecheck false in
local notation "Θ" => {(θ n) | n : ℤ}

/-
/-Stronger version of oscillation_control based on earlier version of the blueprint -/
lemma localOscillation_of_integer_linear {x R : ℝ} (R_nonneg : 0 ≤ R) : ∀ n m : ℤ, localOscillation (Metric.ball x R) (θ n) (θ m) = 2 * R * |(n : ℝ) - m| := by
  intro n m
  by_cases n_ne_m : n = m
  · simp [n_ne_m, sub_self, abs_zero, mul_zero, localOscillation_of_same]
  push_neg at n_ne_m
  have norm_n_sub_m_pos : 0 < |(n : ℝ) - m| := by
    simp only [abs_pos, ne_eq]
    rwa [sub_eq_zero, Int.cast_inj]
  /- Rewrite to a more convenient form for the following steps. -/
  have norm_integer_linear_eq {n m : ℤ} {z : ℝ × ℝ} : ‖(θ n) z.1 - (θ m) z.1 - (θ n) z.2 + (θ m) z.2‖ = ‖(↑n - ↑m) * (z.1 - x) - (↑n - ↑m) * (z.2 - x)‖ := by
    simp only [integer_linear, ContinuousMap.coe_mk, Real.norm_eq_abs]
    ring_nf
  have localOscillation_eq : localOscillation (Metric.ball x R) (θ n) (θ m) = ⨆ z ∈ (Metric.ball x R) ×ˢ (Metric.ball x R), ‖(n - m) * (z.1 - x) - (n - m) * (z.2 - x)‖ := by
      rw [localOscillation]
      congr with z
      rw [norm_integer_linear_eq]
  rw [localOscillation_eq]
  /- Show inequalities in both directions. -/
  apply le_antisymm
  · calc ⨆ z ∈ (Metric.ball x R) ×ˢ (Metric.ball x R), ‖(n - m) * (z.1 - x) - (n - m) * (z.2 - x)‖
      _ ≤ 2 * R * |↑n - ↑m| := by
        apply Real.iSup_le
        --TODO: investigate strange (delaborator) behavior - why is there still a sup?
        intro z
        apply Real.iSup_le
        · intro hz
          simp at hz
          rw [Real.dist_eq, Real.dist_eq] at hz
          rw [Real.norm_eq_abs]
          calc |(n - m) * (z.1 - x) - (n - m) * (z.2 - x)|
          _ ≤ |(n - m) * (z.1 - x)| + |(n - m) * (z.2 - x)| := abs_sub _ _
          _ = |↑n - ↑m| * |z.1 - x| + |↑n - ↑m| * |z.2 - x| := by congr <;> apply abs_mul
          _ ≤ |↑n - ↑m| * R + |↑n - ↑m| * R := by gcongr; linarith [hz.1]; linarith [hz.2]
          _ = 2 * R * |↑n - ↑m| := by ring
        repeat
          apply mul_nonneg
          linarith
          apply abs_nonneg
  · apply le_of_forall_lt
    intro c hc
    have := fact_isCompact_ball x R
    by_cases c_nonneg : 0 > c
    · calc c
        _ < 0 := c_nonneg
        _ ≤ @dist (withLocalOscillation ℝ (Metric.ball x R)) PseudoMetricSpace.toDist (θ n) (θ m) := dist_nonneg
        _ = localOscillation (Metric.ball x R) (θ n) (θ m) := rfl
        _ = ⨆ z ∈ Metric.ball x R ×ˢ Metric.ball x R, ‖(↑n - ↑m) * (z.1 - x) - (↑n - ↑m) * (z.2 - x)‖ := by
          rw [localOscillation]
          congr with z
          rw [norm_integer_linear_eq]
    push_neg at c_nonneg
    set R' := (c + 2 * R * |(n : ℝ) - m|) / (4 * |(n : ℝ) - m|) with R'def
    have hR' : 0 ≤ R' ∧ R' < R := by
      rw [R'def]
      constructor
      · positivity
      calc (c + 2 * R * |↑n - ↑m|) / (4 * |↑n - ↑m|)
        _ < (2 * R * |↑n - ↑m| + 2 * R * |↑n - ↑m|) / (4 * |↑n - ↑m|) := by gcongr
        _ = R := by
          ring_nf
          rw [mul_assoc, mul_inv_cancel norm_n_sub_m_pos.ne.symm, mul_one]
    let y := (x - R', x + R')
    calc c
      _ = c / 2 + c / 2 := by ring
      _ < c / 2 + (2 * R * |↑n - ↑m|) / 2 := by gcongr
      _ = 2 * R' * |↑n - ↑m| := by
        rw [R'def]
        ring_nf
        rw [pow_two, ←mul_assoc, mul_assoc c, mul_inv_cancel norm_n_sub_m_pos.ne.symm,
          mul_assoc (R * _), mul_inv_cancel norm_n_sub_m_pos.ne.symm]
        ring
      _ ≤ ‖(↑n - ↑m) * (y.1 - x) - (↑n - ↑m) * (y.2 - x)‖ := by
        simp only [mul_assoc, sub_sub_cancel_left, mul_neg, add_sub_cancel_left,
          sub_eq_add_neg (-((n - m) * R')), ← two_mul, norm_neg, norm_mul, RCLike.norm_ofNat,
          Real.norm_eq_abs, mul_comm |(n : ℝ) - m|, gt_iff_lt, Nat.ofNat_pos,
          _root_.mul_le_mul_left]
        gcongr
        exact le_abs_self _
      _ ≤ ⨆ z ∈ Metric.ball x R ×ˢ Metric.ball x R, ‖(↑n - ↑m) * (z.1 - x) - (↑n - ↑m) * (z.2 - x)‖ := by
        apply ConditionallyCompleteLattice.le_biSup
        · convert bddAbove_localOscillation (Metric.ball x R) (θ n) (θ m) using 2
          exact norm_integer_linear_eq.symm
        · use y
          simp [abs_of_nonneg, hR'.1, hR'.2]
-/

end

instance instFunctionDistancesReal : FunctionDistances ℝ ℝ where
  Θ := ℤ
  coeΘ := integer_linear
  coeΘ_injective {n m} hnm := by simpa [integer_linear] using hnm 1
  metric := fun _ R ↦ {
      dist := fun n m ↦ 2 * max R 0 * |n - m|
      dist_self := by simp
      dist_comm := by
        simp only [Int.cast_abs, Int.cast_sub, mul_eq_mul_left_iff]
        exact fun _ _ ↦  Or.inl (abs_sub_comm ..)
      dist_triangle := by
        simp only [Int.cast_abs, Int.cast_sub]
        intro x y z
        rw [← mul_add]
        gcongr
        apply abs_sub_le
  }

lemma dist_integer_linear_eq {n m : Θ ℝ} {x R : ℝ} :
    dist_{x, R} n m = 2 * max R 0 * |(n : ℝ) - m| := by
  sorry

lemma coeΘ_R (n : Θ ℝ) (x : ℝ) : n x = n * x := by
  sorry

lemma coeΘ_R_C (n : Θ ℝ) (x : ℝ) : (n x : ℂ) = n * x := by
  sorry

lemma oscillation_control {x : ℝ} {r : ℝ} {f g : Θ ℝ} :
    localOscillation (ball x r) (coeΘ f) (coeΘ g) ≤ ENNReal.ofReal (dist_{x, r} f g) := by
  sorry

lemma frequency_monotone {x₁ x₂ r R : ℝ} {f g : Θ ℝ} (h : ball x₁ r ⊆ ball x₂ R) : dist_{x₁,r} f g ≤ dist_{x₂,R} f g := by
  sorry

lemma frequency_ball_doubling {x₁ x₂ r : ℝ} {f g : Θ ℝ} :
    dist_{x₂, 2 * r} f g ≤ 2 * dist_{x₁, r} f g := by
  sorry

theorem frequency_ball_growth {x₁ x₂ r : ℝ} {f g : Θ ℝ} :
    2 * dist_{x₁, r} f g ≤ dist_{x₂, 2 * r} f g := by
  sorry

lemma integer_ball_cover {x : ℝ} {R R' : ℝ} {f : WithFunctionDistance x R} :
    CoveredByBalls (ball f (2 * R')) 3 R' := by
  sorry

instance compatibleFunctions_R : CompatibleFunctions ℝ ℝ (2 ^ 4) where
  eq_zero := by
    use 0
    intro f
    change f 0 = 0
    rw [coeΘ_R, mul_zero]
  localOscillation_le_cdist := oscillation_control
  cdist_mono := frequency_monotone
  cdist_le := by
    intro x₁ x₂ r f g _
    apply le_trans frequency_ball_doubling
    gcongr; norm_num
  le_cdist := by
    intro x₁ x₂ r f g _
    apply le_trans (@frequency_ball_growth x₁ x₂ r _ _)
    rw [dist_integer_linear_eq, dist_integer_linear_eq]
    by_cases! r_nonneg : 0 ≤ r
    · gcongr; norm_num
    · rw [max_eq_right (by linarith), max_eq_right (by norm_num; linarith)]
  allBallsCoverBalls := by
    intro x R R' f
    exact integer_ball_cover.mono_nat (by norm_num)

open scoped NNReal

instance real_van_der_Corput : IsCancellative ℝ (defaultτ 4) := by
  apply isCancellative_of_norm_integral_exp_le
  intro x r φ r_pos hK hφ f g
  rw [defaultτ, ← one_div, measureReal_def, Real.volume_ball,
    ENNReal.toReal_ofReal (by linarith [r_pos]), Real.ball_eq_Ioo, ← integral_Ioc_eq_integral_Ioo,
    ← intervalIntegral.integral_of_le (by linarith [r_pos]), dist_integer_linear_eq,
    max_eq_left r_pos.le]
  calc ‖∫ (x : ℝ) in x - r..x + r, (Complex.I * (↑(f x) - ↑(g x))).exp * φ x‖
    _ = ‖∫ (x : ℝ) in x - r..x + r, (Complex.I * ((↑f - ↑g) : ℤ) * x).exp * φ x‖ := by
      congr with x
      rw [mul_assoc]
      congr
      push_cast
      rw [_root_.sub_mul]
      norm_cast
    _ ≤ 2 * π * ((x + r) - (x - r)) * (iLipNNNorm φ x r +
          (iLipNNNorm φ x r / r.toNNReal : ℝ≥0) * ((x + r) - (x - r)) / 2) *
      (1 + |((↑f - ↑g) : ℤ)| * ((x + r) - (x - r)))⁻¹ := by
      apply van_der_Corput (by linarith)
      · rw [Ioo_eq_ball]
        simp only [sub_add_add_cancel, add_self_div_two, add_sub_sub_cancel]
        apply LipschitzOnWith.of_iLipENorm_ne_top hK
      · intro y hy
        apply norm_le_iLipNNNorm_of_mem hK
        rwa [Real.ball_eq_Ioo]
    _ = 2 * π * (2 * r) * (iLipNNNorm φ x r + r * (iLipNNNorm φ x r / r.toNNReal : ℝ≥0))
          * (1 + 2 * r * |((↑f - ↑g) : ℤ)|)⁻¹ := by
      ring
    _ = 2 * π * (2 * r) * (iLipNNNorm φ x r + iLipNNNorm φ x r)
          * (1 + 2 * r * |((↑f - ↑g) : ℤ)|)⁻¹ := by
      congr
      rw [NNReal.coe_div, Real.coe_toNNReal _ r_pos.le, mul_div_cancel₀ _ r_pos.ne']
    _ = 4 * π * (2 * r) * iLipNNNorm φ x r * (1 + 2 * r * ↑|(↑f - ↑g : ℤ)|)⁻¹ := by ring
    _ ≤ (2 ^ 4 : ℕ) * (2 * r) * iLipNNNorm φ x r *
      (1 + 2 * r * ↑|(↑f - ↑g : ℤ)|) ^ (- (1 / (4 : ℝ))) := by
      gcongr
      · norm_num
        linarith [pi_le_four]
      · rw [← Real.rpow_neg_one]
        apply Real.rpow_le_rpow_of_exponent_le _ (by norm_num)
        simp only [Int.cast_abs, Int.cast_sub, le_add_iff_nonneg_right]
        exact mul_nonneg (by linarith) (abs_nonneg _)
  norm_cast

-- remove?
lemma Real.vol_real_eq {x y : ℝ} : Real.vol x y = 2 * |x - y| := by
  sorry

-- proof can be simplified with enorm lemma
lemma Real.vol_eq {x y : ℝ} : vol x y = 2 * ‖x - y‖ₑ := by
  sorry

-- remove?
lemma Real.vol_real_symm {x y : ℝ} : Real.vol x y = Real.vol y x := by
  sorry

-- proof can be simplified with enorm lemma
lemma Real.vol_symm {x y : ℝ} : vol x y = vol y x := by
  sorry

instance isOneSidedKernelHilbert : IsOneSidedKernel 4 K where
  /- uses Hilbert_kernel_bound -/
  norm_K_le_vol_inv := by
    intro x y
    rw [Real.vol, measureReal_def, Real.dist_eq, Real.volume_ball, ENNReal.toReal_ofReal (by linarith [abs_nonneg (x-y)])]
    calc ‖K x y‖
    _ ≤ 2 ^ (2 : ℝ) / (2 * |x - y|) := Hilbert_kernel_bound
    _ ≤ 2 ^ (4 : ℝ) ^ 3 / (2 * |x - y|) := by gcongr <;> norm_num
  /- uses Hilbert_kernel_regularity -/
  norm_K_sub_le := by
    intro x y y' h
    rw [Real.dist_eq, Real.dist_eq] at *
    calc ‖K x y - K x y'‖
    _ ≤ 2 ^ 8 * (1 / |x - y|) * (|y - y'| / |x - y|) := by
      apply Hilbert_kernel_regularity
      linarith [abs_nonneg (x-y)]
    _ ≤ (|y - y'| / |x - y|) ^ (4 : ℝ)⁻¹ * (2 ^ (4 : ℝ) ^ 3 / Real.vol x y) := by
      rw [Real.vol_real_eq]
      ring_nf
      rw [pow_two, mul_assoc |x - y|⁻¹]
      gcongr
      · conv =>
          lhs
          rw [← Real.rpow_one (|x - y|⁻¹ * |y - y'|)]
        apply Real.rpow_le_rpow_of_exponent_ge'
        · field_simp
          exact div_nonneg (abs_nonneg (y - y')) (abs_nonneg (x - y))
        · field_simp
          apply div_le_one_of_le₀ <;> linarith [abs_nonneg (x - y)]
        · norm_num
        · norm_num
      · norm_num
  measurable_K := Hilbert_kernel_measurable

instance isTwoSidedKernelHilbert : IsTwoSidedKernel 4 K where
  enorm_K_sub_le' := by
    intro x x' y h
    rw [dist_comm x y] at h
    rw [Hilbert_kernel_conj_symm, @Hilbert_kernel_conj_symm y x', ← map_sub, ← ofReal_norm,
      Complex.norm_conj, edist_comm x y, Real.vol_symm, ofReal_norm_eq_enorm]
    exact enorm_K_sub_le (K := K) h

local notation "T" => carlesonOperatorReal K

--TODO : change name to reflect that this only holds for a specific instance of CarlesonOperaterReal?
lemma carlesonOperatorReal_le_carlesonOperator : T ≤ carlesonOperator K := by
  sorry

/- Version of Lemma 11.1.5 for general exponents -/
lemma rcarleson_general {q q' : ℝ≥0} (hq : q ∈ Set.Ioc 1 2) (hqq' : q.HolderConjugate q')
    {F G : Set ℝ} (hF : MeasurableSet F) (hG : MeasurableSet G)
    (f : ℝ → ℂ) (hmf : Measurable f) (hf : ∀ x, ‖f x‖ ≤ F.indicator 1 x) :
    ∫⁻ x in G, T f x ≤ C10_0_1 4 q * (volume G) ^ (q' : ℝ)⁻¹ * (volume F) ^ (q : ℝ)⁻¹ := by
  sorry

/- Lemma 11.1.5 -/
lemma rcarleson {F G : Set ℝ} (hF : MeasurableSet F) (hG : MeasurableSet G)
    (f : ℝ → ℂ) (hmf : Measurable f) (hf : ∀ x, ‖f x‖ ≤ F.indicator 1 x) :
    ∫⁻ x in G, T f x ≤ C10_0_1 4 2 * (volume G) ^ (2 : ℝ)⁻¹ * (volume F) ^ (2 : ℝ)⁻¹ := by
  sorry

end
