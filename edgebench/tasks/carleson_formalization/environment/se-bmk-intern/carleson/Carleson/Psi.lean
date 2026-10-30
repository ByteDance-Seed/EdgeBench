module

public import Carleson.ProofData
public import Mathlib.Tactic.Field

@[expose] public section

open MeasureTheory Measure NNReal Metric Set TopologicalSpace Function DoublingMeasure Bornology
open scoped ENNReal
noncomputable section

/-! The function `ψ` -/

/- Note: In this section, `D` is an arbitrary real and not equal to `defaultD`
Instead, hypothesis `hD` is used.
-/
section D
variable {D : ℕ} {x : ℝ} {s : ℤ} (hD : 1 < (D : ℝ))

open Real

section -- We record here some trivial inequalities that are used repeatedly below.
include hD
private lemma D0 : 0 < (D : ℝ) := by
  sorry
private lemma D2 : 2 ≤ (D : ℝ) := by
  sorry
private lemma cDx0 {c x : ℝ} (hc : c > 0) (hx : 0 < x) : c * D * x > 0 := by
  sorry
end

/-- The function `ψ` used as a basis for a dyadic partition of unity. -/
def ψ (D : ℕ) (x : ℝ) : ℝ :=
  max 0 <| min 1 <| min (4 * D * x - 1) (2 - 4 * x)

set_option hygiene false in
@[inherit_doc]
scoped[ShortVariables] notation "ψ" => ψ (defaultD a)

lemma zero_le_ψ (D : ℕ) (x : ℝ) : 0 ≤ ψ D x := by
  sorry

lemma ψ_le_one (D : ℕ) (x : ℝ) : ψ D x ≤ 1 := by
  sorry

lemma abs_ψ_le_one (D : ℕ) (x : ℝ) : |ψ D x| ≤ 1 := by
  sorry

lemma enorm_ψ_le_one (D : ℕ) (x : ℝ) : ‖ψ D x‖ₑ ≤ 1 := by
  sorry

---------------------------------------------
/- `ψ_formula₀` through `ψ_formula₄` establish the piecewise formula for `ψ`. -/

lemma ψ_formula₀ {x : ℝ} (hx : x ≤ 1 / (4 * D : ℝ)) : ψ D x = 0 := by
  sorry

include hD in
lemma ψ_formula₁ {x : ℝ} (hx : 1 / (4 * D) ≤ x ∧ x ≤ 1 / (2 * D)) :
    ψ D x = 4 * D * x - 1 := by
  sorry

include hD in
lemma ψ_formula₂ {x : ℝ} (hx : 1 / (2 * D) ≤ x ∧ x ≤ 1 / 4) : ψ D x = 1 := by
  sorry

include hD in
lemma ψ_formula₃ {x : ℝ} (hx : 1 / 4 ≤ x ∧ x ≤ 1 / 2) : ψ D x = 2 - 4 * x := by
  sorry

lemma ψ_formula₄ {x : ℝ} (hx : x ≥ 1 / 2) : ψ D x = 0 := by
  sorry
---------------------------------------------

lemma psi_zero : ψ D 0 = 0 := by
  sorry

lemma continuous_ψ : Continuous (ψ D) := by
  sorry

include hD in
lemma support_ψ : support (ψ D) = Ioo (4 * D : ℝ)⁻¹ 2⁻¹ := by
  sorry

lemma lipschitzWith_ψ (hD : 1 ≤ D) : LipschitzWith (4 * D) (ψ D) := by
  sorry

-- Alternate version of `lipschitzWith_ψ` that avoids using `ENNReal`.
lemma lipschitzWith_ψ' (hD : 1 ≤ D) (a b : ℝ) : ‖ψ D a - ψ D b‖ ≤ 4 * D * dist a b := by
  sorry

variable (D) in
/-- the one or two numbers `s` where `ψ (D ^ (-s) * x)` is possibly nonzero -/
def nonzeroS (x : ℝ) : Finset ℤ :=
  Finset.Icc ⌊(1 + logb D (2 * x))⌋ ⌈logb D (4 * x)⌉

---------------------------------------------

section include_hD

/- The goal of the next several lemmas is to prove `sum_ψ`, which says that
`∑ s ∈ nonzeroS D x, ψ D (D ^ (-s) * x) = 1`.

The first four lemmas prove some properties of the endpoints of `nonzeroS D x`, and in particular
show that `nonzeroS D x` has either 1 or 2 elements. The next two lemmas prove `sum_ψ` in the
1-element and 2-element cases, respectively, and then `sum_ψ` follows immediately.
-/

include hD

private lemma le_div_ceil_mul (hx : 0 < x) : 1 / (4 * D) ≤ D ^ (-⌈logb D (4 * x)⌉) * x := by
  sorry

private lemma one_add_logb (hx : x > 0) : 1 + logb D (2 * x) = logb D (2 * D * x) := by
  sorry

-- If `D ^ (-⌈logb D (4 * x)⌉) ≥ 1 / (2 * D * x)`, then the endpoints of `nonzeroS x` are equal.
private lemma eq_endpoints (hx : 0 < x) (h : D ^ (-⌈logb D (4 * x)⌉) ≥ 1 / (2 * D * x)) :
    ⌊(1 + logb D (2 * x))⌋ = ⌈logb D (4 * x)⌉ := by
  sorry

-- If `D ^ (-⌈logb D (4 * x)⌉) < 1 / (2 * D * x)`, then the endpoints of `nonzeroS x` differ by 1.
private lemma endpoint_sub_one (hx : 0 < x) (h : D ^ (-⌈logb D (4 * x)⌉) < 1 / (2 * D * x)) :
    ⌊1 + logb D (2 * x)⌋ = ⌈logb D (4 * x)⌉ - 1 := by
  sorry

-- Special case of `sum_ψ`, for the case where `nonzeroS D x` has one element.
private lemma sum_ψ₁ (hx : 0 < x) (h : D ^ (-⌈logb D (4 * x)⌉) ≥ 1 / (2 * D * x)) :
    ∑ s ∈ nonzeroS D x, ψ D (D ^ (-s) * x) = 1 := by
  sorry

-- Special case of `sum_ψ`, for the case where `nonzeroS D x` has two elements.
private lemma sum_ψ₂ (hx : 0 < x)
    (h : D ^ (-⌈logb D (4 * x)⌉) < 1 / (2 * D * x)) :
    ∑ s ∈ nonzeroS D x, ψ D (D ^ (-s) * x) = 1 := by
  sorry

-- See `finsum_ψ` for the version that doesn't explicitly restrict to the support.
lemma sum_ψ (hx : 0 < x) : ∑ s ∈ nonzeroS D x, ψ D (D ^ (-s) * x) = 1 := by
  sorry

--------------------------------------------------
/- Now we prove that `nonzeroS D x` is the support of `s ↦ ψ D (D ^ (-s) * x)`. This converts
`sum_ψ` into `finsum_ψ`, which states that `∑ᶠ s : ℤ, ψ D (D ^ (-s) * x) = 1`. -/

lemma mem_nonzeroS_iff {i : ℤ} {x : ℝ} (hx : 0 < x) :
    i ∈ nonzeroS D x ↔ (D ^ (-i) * x) ∈ Ioo (4 * D : ℝ)⁻¹ 2⁻¹ := by
  sorry

lemma psi_ne_zero_iff {x : ℝ} (hx : 0 < x) :
    ψ D (D ^ (-s) * x) ≠ 0 ↔ s ∈ nonzeroS D x := by
  sorry

lemma psi_eq_zero_iff {x : ℝ} (hx : 0 < x) : ψ D (D ^ (-s) * x) = 0 ↔ s ∉ nonzeroS D x := by
  sorry

lemma support_ψS (hx : 0 < x) : support (fun (s : ℤ) ↦ ψ D (D ^ (-s) * x)) = nonzeroS D x := by
  sorry

lemma support_ψS_subset_Icc {b c : ℤ} {x : ℝ}
    (h : x ∈ Icc ((D : ℝ) ^ (b - 1) / 2) (D ^ c / 4)) :
    support (fun (s : ℤ) ↦ ψ D (D ^ (-s) * x)) ⊆ Icc b c := by
  sorry

lemma finsum_ψ (hx : 0 < x) : ∑ᶠ s : ℤ, ψ D (D ^ (-s) * x) = 1 := by
  sorry

lemma sum_ψ_le (S : Finset ℤ) (hx : 0 < x) : ∑ s ∈ S, ψ D (D ^ (-s) * x) ≤ 1 := by
  sorry

end include_hD

end D

open Complex

open scoped ShortVariables

section PseudoMetricSpace

variable (X : Type*) {a : ℕ} {K : X → X → ℂ} [PseudoMetricSpace X]
variable {s : ℤ} {x y : X}

private lemma zpow_realD_pos (s : ℤ) : 0 < (D : ℝ) ^ s := by
  sorry

variable {X} [KernelProofData a K]

/-- K_s in the blueprint -/
@[nolint unusedArguments]
def Ks [KernelProofData a K] (s : ℤ) (x y : X) : ℂ :=
  K x y * ψ (D ^ (-s) * dist x y)

lemma Ks_def (s : ℤ) (x y : X) : Ks s x y = K x y * ψ (D ^ (-s) * dist x y) := by
  sorry

lemma sum_Ks {t : Finset ℤ} (hs : nonzeroS D (dist x y) ⊆ t) (hD : 1 < (D : ℝ)) (h : 0 < dist x y) :
    ∑ i ∈ t, Ks i x y = K x y := by
  sorry

lemma dist_mem_Ioo_of_Ks_ne_zero {s : ℤ} {x y : X} (h : Ks s x y ≠ 0) :
    dist x y ∈ Ioo ((D ^ (s - 1) : ℝ) / 4) (D ^ s / 2) := by
  sorry

/-- Lemma 2.1.3 part 1, equation (2.1.2) -/
lemma dist_mem_Icc_of_Ks_ne_zero {s : ℤ} {x y : X} (h : Ks s x y ≠ 0) :
    dist x y ∈ Icc ((D ^ (s - 1) : ℝ) / 4) (D ^ s / 2) := by
  sorry

lemma dist_mem_Icc_of_mem_tsupport_Ks {s : ℤ} {x : X × X}
    (h : x ∈ tsupport fun x ↦ (Ks s x.1 x.2)) :
    dist x.1 x.2 ∈ Icc ((D ^ (s - 1) : ℝ) / 4) (D ^ s / 2) := by
  sorry

private lemma lowerBound_edist_of_Ks_ne_zero {s : ℤ} {x y : X} (h : Ks s x y ≠ 0) :
    D ^ (s - 1) / 4 ≤ edist x y := by
  sorry

/-- The constant appearing in part 2 of Lemma 2.1.3.
Equal to `2 ^ (102 * a ^ 3)` in the blueprint. -/
def C2_1_3 (a : ℕ) : ℝ≥0 := 2 ^ ((𝕔 + 2) * a ^ 3)

/-- The constant appearing in part 3 of Lemma 2.1.3.
Equal to `2 ^ (127 * a ^ 3)` in the blueprint. -/
def D2_1_3 (a : ℕ) : ℝ≥0 := 2 ^ ((𝕔 + 2 + 𝕔 / 4) * a ^ 3)

/-- Equation (1.1.11) in the blueprint -/
lemma kernel_bound {s : ℤ} {x y : X} : ‖Ks s x y‖ₑ ≤ C_K a / vol x y := by
  sorry

variable (s)

/-- Apply `volume_ball_two_le_same` `n` times. -/
private lemma DoublingMeasure.volume_real_ball_two_le_same_repeat (x : X) (r : ℝ) (n : ℕ) :
    volume.real (ball x (2 ^ n * r)) ≤ (defaultA a) ^ n * volume.real (ball x r) := by
  sorry

-- Special case of `DoublingMeasure.volume_ball_two_le_same_repeat` used to prove `div_vol_le`
private lemma DoublingMeasure.volume_real_ball_two_le_same_repeat' (x : X) (n : ℕ) :
    volume.real (ball x (2 ^ n * D ^ s)) ≤
    (defaultA a) ^ (2 + n + 𝕔 * a ^ 2) * volume.real (ball x (D ^ (s - 1) / 4)) := by
  sorry

/-- Apply `volume_ball_two_le_same` `n` times. -/
lemma DoublingMeasure.volume_ball_two_le_same_repeat (x : X) (r : ℝ) (n : ℕ) :
    volume (ball x (2 ^ n * r)) ≤ (defaultA a) ^ n * volume (ball x r) := by
  sorry

-- Special case of `DoublingMeasure.volume_ball_two_le_same_repeat` used to prove `div_vol_le'`
private lemma DoublingMeasure.volume_ball_two_le_same_repeat' (x : X) (n : ℕ) :
    volume (ball x (2 ^ n * D ^ s)) ≤
    (defaultA a) ^ (2 + n + 𝕔 * a ^ 2) * volume (ball x (D ^ (s - 1) / 4)) := by
  sorry

lemma Metric.measure_ball_pos_nnreal (x : X) (r : ℝ) (hr : r > 0) :
    (volume (ball x r)).toNNReal > 0 := by
  sorry

lemma Metric.measure_ball_pos_real (x : X) (r : ℝ) (hr : r > 0) : volume.real (ball x r) > 0 := by
  sorry

variable {s}

private lemma div_vol_le {x y : X} {c : ℝ} (hc : c > 0) (hxy : dist x y ≥ D ^ (s - 1) / 4) (n : ℕ) :
     c / Real.vol x y ≤
      (2 ^ ((2 + n) * a + 𝕔 * a ^ 3)) * c / volume.real (ball x (2 ^ n * D ^ s)) := by
  sorry

private lemma div_vol_le' {x y : X} {c : ℝ≥0∞} (hxy : dist x y ≥ D ^ (s - 1) / 4) (n : ℕ) :
    c / vol x y ≤ (2 ^ ((2 + n) * a + 𝕔 * a ^ 3)) * c / volume (ball x (2 ^ n * D ^ s)) := by
  sorry

-- Useful special case of `div_vol_le`
private lemma div_vol_le₀ {x y : X} {c : ℝ≥0∞} (hK : Ks s x y ≠ 0) :
    c / vol x y ≤ (2 ^ (2 * a + 𝕔 * a ^ 3)) * c / volume (ball x (D ^ s)) := by
  sorry

-- preferably use `enorm_K_le`
private lemma norm_K_le {s : ℤ} {x y : X} (n : ℕ) (hxy : dist x y ≥ D ^ (s - 1) / 4) :
    ‖K x y‖ ≤ 2 ^ ((2 + n) * a + (𝕔 + 1) * a ^ 3) / volume.real (ball x (2 ^ n * D ^ s)) := by
  sorry

lemma enorm_K_le {s : ℤ} {x y : X} (n : ℕ) (hxy : dist x y ≥ D ^ (s - 1) / 4) :
    ‖K x y‖ₑ ≤ 2 ^ ((2 + n) * a + (𝕔 + 1) * a ^ 3) / volume (ball x (2 ^ n * D ^ s)) := by
  sorry

/-- Lemma 2.1.3 part 2 (Real version). Prefer `enorm_Ks_le` -/
private lemma norm_Ks_le {s : ℤ} {x y : X} :
    ‖Ks s x y‖ ≤ C2_1_3 a / volume.real (ball x (D ^ s)) := by
  sorry

/-- Lemma 2.1.3 part 2, equation (2.1.3) -/
lemma enorm_Ks_le {s : ℤ} {x y : X} :
    ‖Ks s x y‖ₑ ≤ C2_1_3 a / volume (ball x (D ^ s)) := by
  sorry

/-- Needed for Lemma 7.5.5. -/
lemma enorm_Ks_le' {s : ℤ} {x y : X} :
    ‖Ks s x y‖ₑ ≤ C2_1_3 a / volume (ball x (D ^ s)) * ‖ψ (D ^ (-s) * dist x y)‖ₑ := by
  sorry

/-- `Ks` is bounded uniformly in `x`, `y` assuming `x` is in a fixed closed ball. -/
private lemma norm_Ks_le_of_dist_le {x y x₀ : X} {r₀ : ℝ} (hr₀ : 0 < r₀) (hx : dist x x₀ ≤ r₀) (s : ℤ) :
    ‖Ks s x y‖ ≤ C2_1_3 a * (As (defaultA a) (2 * r₀ / D ^ s)) / volume.real (ball x₀ r₀) := by
  sorry

/-- `‖Ks x y‖` is bounded if `x` is in a bounded set -/
lemma _root_.Bornology.IsBounded.exists_bound_of_norm_Ks
    {A : Set X} (hA : IsBounded A) (s : ℤ) :
    ∃ C, 0 ≤ C ∧ ∀ x y, x ∈ A → ‖Ks s x y‖ ≤ C := by
  sorry

-- Needed to prove `ψ_ineq`
private lemma enorm_ψ_sub_ψ_le_two {r s : ℝ} : ‖ψ r - ψ s‖ₑ ≤ 2 := by
  sorry

-- Needed to prove `enorm_Ks_sub_Ks_le`
include K in
private lemma ψ_ineq {x y y' : X} :
    ‖ψ (D ^ (-s) * dist x y) - ψ (D ^ (-s) * dist x y')‖ₑ ≤
    4 * D * (edist y y' / D ^ s) ^ (a : ℝ)⁻¹ := by
  sorry

private lemma D_pow_a_inv : (D : ℝ) ^ (a : ℝ)⁻¹ = 2 ^ (𝕔 * a) := by
  sorry

include K in
private lemma four_D_rpow_a_inv : (4 * D : ℝ) ^ (a : ℝ)⁻¹ ≤ 2 ^ (1 + 𝕔 * a) := by
  sorry

/-
The proof of `norm_Ks_sub_Ks_le` is divided into two cases `norm_Ks_sub_Ks_le_y'close` and
`norm_Ks_sub_Ks_le_y'far`, depending if `2 * dist y y' ≤ dist x y` or `2 * dist y y' > dist x y`.

To prepare for the proof of `norm_Ks_sub_Ks_le_y'close`, we separate the main inequality into two
subgoals `_pt1` and `_pt2`.
-/

private lemma enorm_Ks_sub_Ks_le_close_pt1 {s : ℤ} {x y y' : X} (hK : Ks s x y ≠ 0)
     (hyy' : 2 * edist y y' ≤ edist x y) : ‖K x y - K x y'‖ₑ * ‖ψ (D ^ (-s) * dist x y')‖ₑ ≤
    2 ^ (1 + (𝕔 + 2) * a + (𝕔 + 1) * a ^ 3) / volume (ball x (D ^ s)) *
    (edist y y' / D ^ s) ^ (a : ℝ)⁻¹ := by
  sorry

private lemma enorm_Ks_sub_Ks_le_close_pt2 {s : ℤ} {x y y' : X} (hK : Ks s x y ≠ 0) :
    ‖K x y‖ₑ * ‖(ψ (D ^ (-s) * dist x y)) - (ψ (D ^ (-s) * dist x y'))‖ₑ ≤
    2 ^ (2 + 2 * a + 𝕔 * a ^ 2 + (𝕔 + 1) * a ^ 3) / volume (ball x (D ^ s)) *
    (edist y y' / D ^ s) ^ (a : ℝ)⁻¹ := by
  sorry

-- Second case of `norm_Ks_sub_Ks_le` in blueprint
private lemma enorm_Ks_sub_Ks_le_close {s : ℤ} {x y y' : X} (hK : Ks s x y ≠ 0)
    (h : 2 * edist y y' ≤ edist x y) : ‖Ks s x y - Ks s x y'‖ₑ ≤
    D2_1_3 a / volume (ball x (D ^ s)) * (edist y y' / D ^ s) ^ (a : ℝ)⁻¹ := by
  sorry

-- First case of `norm_Ks_sub_Ks_le` in blueprint
private lemma enorm_Ks_sub_Ks_le_far {s : ℤ} {x y y' : X} (hK : Ks s x y ≠ 0)
    (h : ¬ 2 * edist y y' ≤ edist x y) : ‖Ks s x y - Ks s x y'‖ₑ ≤
      D2_1_3 a / volume (ball x (D ^ s)) * (edist y y' / D ^ s) ^ (a : ℝ)⁻¹ := by
  sorry

lemma enorm_Ks_sub_Ks_le_of_nonzero {s : ℤ} {x y y' : X} (hK : Ks s x y ≠ 0) :
    ‖Ks s x y - Ks s x y'‖ₑ ≤
      D2_1_3 a / volume (ball x (D ^ s)) * (edist y y' / D ^ s) ^ (a : ℝ)⁻¹ := by
  sorry

/-- Lemma 2.1.3 part 3, equation (2.1.4) -/
lemma enorm_Ks_sub_Ks_le {s : ℤ} {x y y' : X} :
    ‖Ks s x y - Ks s x y'‖ₑ ≤
      D2_1_3 a / volume (ball x (D ^ s)) * (edist y y' / D ^ s) ^ (a : ℝ)⁻¹ := by
  sorry

lemma stronglyMeasurable_Ks {s : ℤ} : StronglyMeasurable (fun x : X × X ↦ Ks s x.1 x.2) := by
  sorry

@[fun_prop]
lemma measurable_Ks {s : ℤ} : Measurable (fun x : X × X ↦ Ks s x.1 x.2) := by
  sorry

@[fun_prop]
lemma aestronglyMeasurable_Ks {s : ℤ} : AEStronglyMeasurable (fun x : X × X ↦ Ks s x.1 x.2) := by
  sorry

/-- The function `y ↦ Ks s x y` is integrable. -/
lemma integrable_Ks_x {s : ℤ} {x : X} (hD : 1 < (D : ℝ)) : Integrable (Ks s x) := by
  sorry

end PseudoMetricSpace

section MetricSpace

variable (X : Type*) {a : ℕ} {q : ℝ} {K : X → X → ℂ} {σ₁ σ₂ : X → ℤ} {F G : Set X}
  [MetricSpace X] [ProofData a q K σ₁ σ₂ F G] {s : ℤ} {x y : X}

lemma Ks_eq_zero_of_dist_le {s : ℤ} {x y : X} (hxy : x ≠ y)
    (h : dist x y ≤ defaultD a ^ (s - 1) / 4) :
    Ks s x y = 0 := by
  sorry

lemma Ks_eq_zero_of_le_dist {s : ℤ} {x y : X} (h : D ^ s / 2 ≤ dist x y) : Ks s x y = 0 := by
  sorry

end MetricSpace
