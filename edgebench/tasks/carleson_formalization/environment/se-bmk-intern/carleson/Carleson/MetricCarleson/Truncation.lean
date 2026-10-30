module

public import Carleson.FinitaryCarleson

@[expose] public section

open scoped NNReal
open MeasureTheory Set ENNReal Filter Topology ShortVariables Bornology Metric Complex

noncomputable section

variable {X : Type*} {a : ℕ} [MetricSpace X] {q q' : ℝ≥0} {F G : Set X} {K : X → X → ℂ}
variable [KernelProofData a K] {Q : SimpleFunc X (Θ X)} {f : X → ℂ} {σ₁ σ₂ : X → ℤ}

/-- The operator T_{s₁, s₂} introduced in Lemma 3.0.3. -/
def T_S (Q : SimpleFunc X (Θ X)) (s₁ s₂ : ℤ) (f : X → ℂ) (x : X) : ℂ :=
  ∑ s ∈ Finset.Icc s₁ s₂, ∫ y, Ks s x y * f y * exp (I * Q x y)

lemma measurable_T_inner_integral {s : ℤ} (mf : Measurable f) :
    Measurable fun x ↦ ∫ y, Ks s x y * f y * exp (I * Q x y) := by
  sorry

lemma measurable_T_S {s₁ s₂} (mf : Measurable f) : Measurable (T_S Q s₁ s₂ f ·) := by
  sorry

/-- The operator T_{2, σ₁, σ₂} introduced in Lemma 3.0.4. -/
def T_lin (Q : SimpleFunc X (Θ X)) (σ₁ σ₂ : X → ℤ) (f : X → ℂ) (x : X) : ℂ :=
  T_S Q (σ₁ x) (σ₂ x) f x

lemma measurable_T_lin (mf : Measurable f) (mσ₁ : Measurable σ₁) (mσ₂ : Measurable σ₂)
    (rσ₁ : (range σ₁).Finite) (rσ₂ : (range σ₂).Finite) : Measurable (T_lin Q σ₁ σ₂ f ·) := by
  sorry

section Linearised

variable [IsCancellative X (defaultτ a)]

variable (q q' F f σ₁ σ₂) in
/-- Convenience structure for the parameters that stay constant throughout the recursive calls to
finitary Carleson in the proof of Lemma 3.0.4. -/
structure CP304 where
  /-- `Q` is the only non-`Prop` field of `CP304`. -/
  Q : SimpleFunc X (Θ X)
  BST_T_Q (θ : Θ X) : HasBoundedStrongType (linearizedNontangentialOperator Q θ K · ·)
    2 2 volume volume (C_Ts a)
  hq : q ∈ Ioc 1 2
  hqq' : q.HolderConjugate q'
  bF : IsBounded F
  mF : MeasurableSet F
  mf : Measurable f
  nf : (‖f ·‖) ≤ F.indicator 1
  mσ₁ : Measurable σ₁
  mσ₂ : Measurable σ₂
  rσ₁ : (range σ₁).Finite
  rσ₂ : (range σ₂).Finite
  lσ : σ₁ ≤ σ₂

theorem finitary_carleson_step
    (CP : CP304 q q' F f σ₁ σ₂) (bG : IsBounded G) (mG : MeasurableSet G) :
    ∃ G' ⊆ G, IsBounded G' ∧ MeasurableSet G' ∧ 2 * volume G' ≤ volume G ∧
    ∫⁻ x in G \ G', ‖T_lin CP.Q σ₁ σ₂ f x‖ₑ ≤
    C2_0_1 a q * (volume G) ^ (q' : ℝ)⁻¹ * (volume F) ^ (q : ℝ)⁻¹ := by
  sorry

variable (q q' F f σ₁ σ₂) in
/-- All the parameters needed to apply the recursion of Lemma 3.0.4. -/
structure P304 where
  /-- `CP` holds all constant parameters. -/
  CP : CP304 q q' F f σ₁ σ₂
  /-- `G` is the set being recursed on. -/
  G : Set X
  bG : IsBounded G
  mG : MeasurableSet G

/-- Construct `G_{n+1}` given `G_n`. -/
def P304.succ (P : P304 q q' F f σ₁ σ₂) : P304 q q' F f σ₁ σ₂ where
  CP := P.CP
  G := (finitary_carleson_step P.CP P.bG P.mG).choose
  bG := (finitary_carleson_step P.CP P.bG P.mG).choose_spec.2.1
  mG := (finitary_carleson_step P.CP P.bG P.mG).choose_spec.2.2.1

variable (CP : CP304 q q' F f σ₁ σ₂) (bG : IsBounded G) (mG : MeasurableSet G)

/-- `slice CP bG mG n` contains `G_n` and its associated data. -/
def slice (n : ℕ) : P304 q q' F f σ₁ σ₂ := P304.succ^[n] ⟨CP, G, bG, mG⟩

variable {CP bG mG n}

@[simp]
lemma slice_CP : (slice CP bG mG n).CP = CP := by
  sorry

lemma slice_G_subset : (slice CP bG mG (n + 1)).G ⊆ (slice CP bG mG n).G := by
  sorry

lemma antitone_slice_G : Antitone fun n ↦ (slice CP bG mG n).G := by
  sorry

lemma volume_slice : 2 * volume (slice CP bG mG (n + 1)).G ≤ volume (slice CP bG mG n).G := by
  sorry

lemma volume_slice_le_inv_two_pow_mul : volume (slice CP bG mG n).G ≤ 2⁻¹ ^ n * volume G := by
  sorry

/-- The sets `G_n` become arbitrarily small. -/
lemma exists_volume_slice_lt_eps {ε : ℝ≥0∞} (εpos : 0 < ε) :
    ∃ n, volume (slice CP bG mG (n + 1)).G < ε := by
  sorry

lemma slice_integral_bound :
    ∫⁻ x in (slice CP bG mG n).G \ (slice CP bG mG (n + 1)).G, ‖T_lin CP.Q σ₁ σ₂ f x‖ₑ ≤
    C2_0_1 a q * volume (slice CP bG mG n).G ^ (q' : ℝ)⁻¹ * volume F ^ (q : ℝ)⁻¹ := by
  sorry

/-- The slightly unusual way of writing the integrand is to facilitate applying the
monotone convergence theorem. -/
lemma slice_integral_bound_sum :
    ∫⁻ x, (G \ (slice CP bG mG (n + 1)).G).indicator (‖T_lin CP.Q σ₁ σ₂ f ·‖ₑ) x ≤
    C2_0_1 a q * (∑ i ∈ Finset.range (n + 1), (2⁻¹ ^ i) ^ (q' : ℝ)⁻¹) *
    volume G ^ (q' : ℝ)⁻¹ * volume F ^ (q : ℝ)⁻¹ := by
  sorry

end Linearised

lemma sum_le_four_div_q_sub_one (hq : q ∈ Ioc 1 2) (hqq' : q.HolderConjugate q') {n : ℕ} :
    ∑ i ∈ Finset.range n, ((2 : ℝ≥0∞)⁻¹ ^ i) ^ (q' : ℝ)⁻¹ ≤ (2 ^ 2 / (q - 1) : ℝ≥0) := by
  sorry

/-- The constant used in `linearized_truncation` and `S_truncation`.
Has value `2 ^ (442 * a ^ 3 + 2)` in the blueprint. -/
def C3_0_4 (a : ℕ) (q : ℝ≥0) : ℝ≥0 :=
  2 ^ ((3 * 𝕔 + 17 + 5 * (𝕔 / 4)) * a ^ 3 + 2) / (q - 1) ^ 6

lemma eq_C3_0_4 : C2_0_1 a q * (2 ^ 2 / (q - 1)) = C3_0_4 a q := by
  sorry

/-- Lemma 3.0.4. -/
lemma linearized_truncation
    [IsCancellative X (defaultτ a)] (hq : q ∈ Ioc 1 2) (hqq' : q.HolderConjugate q')
    (bF : IsBounded F) (bG : IsBounded G) (mF : MeasurableSet F) (mG : MeasurableSet G)
    (mf : Measurable f) (nf : (‖f ·‖) ≤ F.indicator 1) (mσ₁ : Measurable σ₁) (mσ₂ : Measurable σ₂)
    (rσ₁ : (range σ₁).Finite) (rσ₂ : (range σ₂).Finite) (lσ : σ₁ ≤ σ₂)
    (BST_T_Q : ∀ θ : Θ X, HasBoundedStrongType (linearizedNontangentialOperator Q θ K · ·)
      2 2 volume volume (C_Ts a)) :
    ∫⁻ x in G, ‖T_lin Q σ₁ σ₂ f x‖ₑ ≤
    C3_0_4 a q * volume G ^ (q' : ℝ)⁻¹ * volume F ^ (q : ℝ)⁻¹ := by
  sorry

/-- Lemma 3.0.3. `B` is the blueprint's `S`. -/
lemma S_truncation
    [IsCancellative X (defaultτ a)] {B : ℕ} (hq : q ∈ Ioc 1 2) (hqq' : q.HolderConjugate q')
    (bF : IsBounded F) (bG : IsBounded G) (mF : MeasurableSet F) (mG : MeasurableSet G)
    (mf : Measurable f) (nf : (‖f ·‖) ≤ F.indicator 1)
    (BST_T_Q : ∀ θ : Θ X, HasBoundedStrongType (linearizedNontangentialOperator Q θ K · ·)
      2 2 volume volume (C_Ts a)) :
    ∫⁻ x in G, ⨆ s₁ ∈ Finset.Icc (-B : ℤ) B, ⨆ s₂ ∈ Finset.Icc s₁ B, ‖T_S Q s₁ s₂ f x‖ₑ ≤
    C3_0_4 a q * volume G ^ (q' : ℝ)⁻¹ * volume F ^ (q : ℝ)⁻¹ := by
  sorry

section RTruncation

/-- The largest integer `s₁` satisfying `D ^ (-(s₁ - 2)) * R₁ > 1 / 2`. -/
def L302 (a : ℕ) (R₁ : ℝ) : ℤ := ⌊Real.logb D (2 * R₁)⌋ + 3

/-- The smallest integer `s₂` satisfying `D ^ (-(s₂ + 2)) * R₂ < 1 / (4 * D)`. -/
def U302 (a : ℕ) (R₂ : ℝ) : ℤ := ⌈Real.logb D (4 * R₂)⌉ - 2

include K in
lemma R₁_le_D_zpow_div_four {R₁ : ℝ} : R₁ ≤ D ^ (L302 a R₁ - 1) / 4 := by
  sorry

include K in
lemma D_zpow_div_two_le_R₂ {R₂ : ℝ} (hR₂ : 0 < R₂) : D ^ (U302 a R₂) / 2 ≤ R₂ := by
  sorry

include K in
lemma monotoneOn_L302 : MonotoneOn (L302 a) {r | 0 < r} := by
  sorry

include K in
lemma monotoneOn_U302 : MonotoneOn (U302 a) {r | 0 < r} := by
  sorry

include K in
/-- There exists a uniform bound for all possible values of `L302` and `U302` over the annulus in
`R_truncation`. -/
lemma exists_uniform_annulus_bound {R : ℝ} (hR : 0 < R) :
    ∃ B : ℕ, ∀ R₁ ∈ Ioo R⁻¹ R, ∀ R₂ ∈ Ioo R₁ R,
      L302 a R₁ ∈ Finset.Icc (-B : ℤ) B ∧ U302 a R₂ ∈ Finset.Icc (-B : ℤ) B := by
  sorry

lemma enorm_setIntegral_annulus_le {x : X} {R₁ R₂ : ℝ} {s : ℤ} (nf : (‖f ·‖) ≤ F.indicator 1) :
    ‖∫ y in Annulus.oo x R₁ R₂, Ks s x y * f y * exp (I * Q x y)‖ₑ ≤
    C2_1_3 a * globalMaximalFunction volume 1 (F.indicator (1 : X → ℝ)) x := by
  sorry

/-- The fringes of the scale interval in Lemma 3.0.2's proof that require separate handling. -/
def edgeScales (a : ℕ) (R₁ R₂ : ℝ) : Finset ℤ :=
  {L302 a R₁ - 1, L302 a R₁ - 2, U302 a R₂ + 1, U302 a R₂ + 2}

lemma diff_subset_edgeScales {a : ℕ} {R₁ R₂ : ℝ} :
    Finset.Icc (L302 a R₁ - 2) (U302 a R₂ + 2) \ Finset.Icc (L302 a R₁) (U302 a R₂) ⊆
    edgeScales a R₁ R₂ := by
  sorry

lemma enorm_carlesonOperatorIntegrand_le_T_S {R₁ R₂ : ℝ} (hR₁ : 0 < R₁) (hR₂ : R₁ < R₂)
    (mf : Measurable f) (nf : (‖f ·‖) ≤ F.indicator 1) {x : X} :
    ‖carlesonOperatorIntegrand K (Q x) R₁ R₂ f x‖ₑ ≤
    ‖T_S Q (L302 a R₁) (U302 a R₂) f x‖ₑ +
    4 * C2_1_3 a * globalMaximalFunction volume 1 (F.indicator (1 : X → ℝ)) x := by
  sorry

lemma lintegral_globalMaximalFunction_le (hq : q ∈ Ioc 1 2) (hqq' : q.HolderConjugate q')
    (bF : IsBounded F) (mF : MeasurableSet F) (mG : MeasurableSet G) :
    ∫⁻ x in G, globalMaximalFunction volume 1 (F.indicator (1 : X → ℝ)) x ≤
    C2_0_6' (defaultA a) 1 q * volume G ^ (q' : ℝ)⁻¹ * volume F ^ (q : ℝ)⁻¹ := by
  sorry

/-- The operator T_{R₁, R₂, R} introduced in Lemma 3.0.2. -/
def T_R (K : X → X → ℂ) (Q : SimpleFunc X (Θ X)) (R₁ R₂ R : ℝ) (f : X → ℂ) (x : X) : ℂ :=
  (ball o R).indicator (fun x ↦ carlesonOperatorIntegrand K (Q x) R₁ R₂ f x) x

lemma C1_0_2_pos {a : ℕ} {q : ℝ≥0} (hq : 1 < q) : 0 < C1_0_2 a q := by
  sorry

lemma le_C1_0_2 (a4 : 4 ≤ a) (hq : q ∈ Ioc 1 2) :
    C3_0_4 a q + 4 * C2_1_3 a * C2_0_6' (defaultA a) 1 q ≤ C1_0_2 a q := by
  sorry

variable [IsCancellative X (defaultτ a)]

lemma R_truncation' (hq : q ∈ Ioc 1 2) (hqq' : q.HolderConjugate q')
    (mF : MeasurableSet F) (mG : MeasurableSet G) (mf : Measurable f) (nf : (‖f ·‖) ≤ F.indicator 1)
    {n : ℕ} {R : ℝ} (hR : R = 2 ^ n) (sF : F ⊆ ball o (2 * R)) (sG : G ⊆ ball o R)
    (BST_T_Q : ∀ θ : Θ X, HasBoundedStrongType (linearizedNontangentialOperator Q θ K · ·)
      2 2 volume volume (C_Ts a)) :
    ∫⁻ x in G, ⨆ R₁ ∈ Ioo R⁻¹ R, ⨆ R₂ ∈ Ioo R₁ R, ‖T_R K Q R₁ R₂ R f x‖ₑ ≤
    C1_0_2 a q * volume G ^ (q' : ℝ)⁻¹ * volume F ^ (q : ℝ)⁻¹ := by
  sorry

/-- Lemma 3.0.2. -/
lemma R_truncation (hq : q ∈ Ioc 1 2) (hqq' : q.HolderConjugate q')
    (mF : MeasurableSet F) (mG : MeasurableSet G) (mf : Measurable f) (nf : (‖f ·‖) ≤ F.indicator 1)
    {n : ℕ} {R : ℝ} (hR : R = 2 ^ n)
    (BST_T_Q : ∀ θ : Θ X, HasBoundedStrongType (linearizedNontangentialOperator Q θ K · ·)
      2 2 volume volume (C_Ts a)) :
    ∫⁻ x in G, ⨆ R₁ ∈ Ioo R⁻¹ R, ⨆ R₂ ∈ Ioo R₁ R, ‖T_R K Q R₁ R₂ R f x‖ₑ ≤
    C1_0_2 a q * volume G ^ (q' : ℝ)⁻¹ * volume F ^ (q : ℝ)⁻¹ := by
  sorry

end RTruncation
