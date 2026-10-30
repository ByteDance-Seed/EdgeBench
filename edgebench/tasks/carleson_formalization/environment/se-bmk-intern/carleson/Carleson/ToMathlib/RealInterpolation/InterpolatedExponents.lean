module

public import Mathlib.Analysis.SpecialFunctions.Pow.NNReal

/-!
# Results about working with (interpolated) exponents

This files contains convenience results for working with interpolated exponents,
as well as results about a particular choice of exponent that we will use for the proof
of the real interpolation theorem.

Upstreaming status: mixed; some requires more design discussions
- the ENNReal section is ready to go
- the ComputationsInterpolatedExponents sections is also generally useful;
  need to find a better naming scheme for the lemmas (and address a few TODOs)
- the ComputationsChoiceExponent section is specific to this particular proof of real interpolation.
  If we prefer a proof about Lorentz spaces, using a different approach,
  it may not be worth upstreaming.
-/

@[expose] public section
noncomputable section

open ENNReal Real Set

variable {p₀ q₀ p₁ q₁ p q t : ℝ≥0∞}

namespace ENNReal

-- the Ioc version is true for r = ∞ also
theorem mem_sub_Ioo {q r : ℝ≥0∞} (hr : r ≠ ⊤) (hq : q ∈ Ioo 0 r) : r - q ∈ Ioo 0 r := by
  sorry

lemma sub_toReal_of_le {t : ℝ≥0∞} (ht : t ≤ 1) : 1 - t.toReal = (1 - t).toReal := by
  sorry

lemma sub_sub_toReal_of_le {t : ℝ≥0∞} (ht : t ≤ 1) : t.toReal = 1 - (1 - t).toReal := by
  sorry

lemma one_sub_one_sub_eq {t : ℝ≥0∞} (ht : t ∈ Ioo 0 1) : 1 - (1 - t) = t := by
  sorry

lemma one_le_toReal {a : ℝ≥0∞} (ha₁ : 1 ≤ a) (ha₂ : a < ⊤) : 1 ≤ a.toReal := by
  sorry

lemma coe_rpow_ne_top {a : ℝ} {q : ℝ} (hq : 0 ≤ q) : ENNReal.ofReal a ^ q ≠ ⊤ := by
  sorry

-- Note this lemma can directly be applied to elements of `ℝ≥0` as well
lemma coe_rpow_ne_top' {a : ℝ} {q : ℝ} (hq : 0 < q) : ENNReal.ofReal a ^ q ≠ ⊤ := by
  sorry

lemma coe_pow_pos {a : ℝ} {q : ℝ} (ha : 0 < a) : 0 < ENNReal.ofReal a ^ q := by
  sorry

lemma rpow_ne_top' {a : ℝ≥0∞} {q : ℝ} (ha : a ≠ 0) (ha' : a ≠ ⊤) : a ^ q ≠ ⊤ := by
  sorry

-- unused (one reference in an also-unused lemma)
lemma exp_toReal_pos' {q : ℝ≥0∞} (hq : 1 ≤ q) (hq' : q < ⊤) : 0 < q.toReal := by
  sorry

@[aesop (rule_sets := [finiteness]) unsafe apply]
lemma ne_top_of_Ico {p q r : ℝ≥0∞} (hq : q ∈ Ico p r) : q ≠ ⊤ := by
  sorry

lemma lt_top_of_Ico {p q r : ℝ≥0∞} (hq : q ∈ Ico p r) : q < ⊤ := by
  sorry

@[aesop (rule_sets := [finiteness]) unsafe apply]
lemma ne_top_of_Ioo {p q r : ℝ≥0∞} (hq : q ∈ Ioo p r) : q ≠ ⊤ := by
  sorry

lemma lt_top_of_Ioo {p q r : ℝ≥0∞} (hq : q ∈ Ioo p r) : q < ⊤ := by
  sorry

-- XXX: generalise interval bounds!
lemma toReal_mem_Ioo {t : ℝ≥0∞} (ht : t ∈ Ioo 0 1) : t.toReal ∈ Ioo 0 1 := by
  sorry

-- XXX: generalise interval bounds!
lemma ofReal_mem_Ioo_0_1 (t : ℝ) (h : t ∈ Ioo 0 1) : ENNReal.ofReal t ∈ Ioo 0 1 := by
  sorry

lemma ne_top_of_Ioc {p q r : ℝ≥0∞} (hq : q ∈ Ioc p r) (hr : r < ⊤) : q ≠ ⊤ := by
  sorry

lemma pos_of_rb_Ioc {p q r : ℝ≥0∞} (hr : q ∈ Ioc p r) : 0 < r := by
  sorry

lemma ne_zero_of_Ioo {p q r : ℝ≥0∞} (hq : q ∈ Ioo p r) : q ≠ 0 := by
  sorry

lemma pos_of_Icc_1 {p q : ℝ≥0∞} (hp : p ∈ Icc 1 q) : 0 < p := by
  sorry

lemma pos_of_ge_1 {p : ℝ≥0∞} (hp : 1 ≤ p) : 0 < p := by
  sorry

lemma pos_rb_of_Icc_1_inh {p q : ℝ≥0∞} (hp : p ∈ Icc 1 q) : 0 < q := by
  sorry

lemma toReal_pos_of_Ioo {q p r : ℝ≥0∞} (hp : p ∈ Ioo q r) : 0 < p.toReal := by
  sorry

lemma toReal_ne_zero_of_Ioo {q p r : ℝ≥0∞} (hp : p ∈ Ioo q r) : p.toReal ≠ 0 := by
  sorry

-- TODO: check which ones are actually used
lemma eq_of_rpow_eq (a b : ℝ≥0∞) (c : ℝ) (hc : c ≠ 0) (h : a ^ c = b ^ c) : a = b := by
  sorry

lemma le_of_rpow_le {a b : ℝ≥0∞} {c : ℝ} (hc : 0 < c) (h : a ^ c ≤ b ^ c) : a ≤ b := by
  sorry

lemma coe_inv_exponent (hp₀ : 0 < p₀) : ENNReal.ofReal (p₀⁻¹.toReal) = p₀⁻¹ := by
  sorry

-- TODO: find a better name for the next three lemmas!
lemma preservation_positivity₀ (ht : t ∈ Ioo 0 1) (hpq : p ≠ ⊤ ∨ q ≠ ⊤) :
    0 < (1 - t) * p⁻¹ + t * q⁻¹ := by
  sorry

lemma preservation_positivity (ht : t ∈ Ioo 0 1) (hpq : p ≠ q) :
    0 < (1 - t) * p⁻¹ + t * q⁻¹ := by
  sorry

lemma preservation_positivity' (hp₀ : 0 < p₀) (hp₁ : 0 < p₁) (ht : t ≠ ⊤)
    (hp : p⁻¹ = (1 - t) * p₀⁻¹ + t * p₁⁻¹) : 0 < p := by
  sorry

lemma rpow_add_of_pos (a : ℝ≥0∞) (c d : ℝ) (hc : 0 < c) (hd : 0 < d) :
    a ^ (c + d) = a ^ c * a ^ d := by
  sorry

lemma eq_of_le_of_le (a b : ℝ≥0∞) (hab : a ≤ b) (hab' : b ≤ a) : a = b := by
  sorry

open scoped NNReal

-- TODO: should some of the following lemmas be tagged with finiteness?
lemma rpow_apply_coe {x : ℝ≥0} {y : ℝ} :
    ENNReal.ofNNReal x ^ y = if x = 0 ∧ y < 0 then ∞ else (x ^ y : ℝ≥0) := by
  sorry

lemma rpow_apply_coe' {x : ℝ≥0∞} {y : ℝ} (hx : x ≠ ⊤) :
    x ^ y = if x = 0 ∧ y < 0 then ∞ else (x.toNNReal ^ y : ℝ≥0) := by
  sorry

lemma rpow_lt_rpow_iff_neg {x y : ℝ≥0∞} (hx : x ≠ 0) (hy : y ≠ ∞) (hxy : x < y) {z : ℝ} (hz : z < 0) :
    y ^ z < x ^ z := by
  sorry

lemma div_lt_div {a b c : ℝ≥0∞} (hc : 0 < c) (hc' : c ≠ ∞) : a / c < b / c ↔ a < b := by
  sorry

lemma rpow_lt_top_of_neg {x : ℝ≥0∞} {y : ℝ} (hx : 0 < x) (hy : y < 0) : x ^ y < ⊤ := by
  sorry

lemma rpow_lt_top_of_pos_ne_top_ne_zero {x : ℝ≥0∞} {y : ℝ} (hx : x ≠ 0) (hx' : x ≠ ⊤) (hy : y ≠ 0) :
    x ^ y < ⊤ := by
  sorry

lemma rpow_pos_of_pos_ne_top_ne_zero {x : ℝ≥0∞} {y : ℝ} (hx : x ≠ 0) (hx' : x ≠ ⊤) (hy : y ≠ 0) :
    0 < x ^ y := by
  sorry

-- TODO: better name!
lemma power_estimate {a b t γ : ℝ} (hγ : 0 < γ) (htγ : γ ≤ t) (hab : a ≤ b) :
    (t / γ) ^ a ≤ (t / γ) ^ b := by
  sorry

-- TODO: better name!
lemma power_estimate' {a b t γ : ℝ} (ht : 0 < t) (htγ : t ≤ γ) (hab : a ≤ b) :
    (t / γ) ^ b ≤ (t / γ) ^ a := by
  sorry

lemma rpow_le_rpow_of_exponent_le_base_le {a b t γ : ℝ} (ht : 0 < t) (htγ : t ≤ γ) (hab : a ≤ b) :
    ENNReal.ofReal (t ^ b) ≤ ENNReal.ofReal (t ^ a) * ENNReal.ofReal (γ ^ (b - a)) := by
  sorry

-- Note: this lemma is false if t = γ = ∞ and a < 0 ≤ b, as then t ^ a = ∞ ^ a = 0 and
-- the statement becomes ∞ ≤ 0 * ∞ = 0.
lemma rpow_le_rpow_of_exponent_le_base_le_enorm {a b : ℝ} {t γ : ℝ≥0∞} (ht : 0 < t) (ht' : t ≠ ∞) (htγ : t ≤ γ) (hab : a ≤ b) :
    t ^ b ≤ t ^ a * γ ^ (b - a) := by
  sorry

-- TODO: there is a lot of overlap between above proof and below
lemma rpow_le_rpow_of_exponent_le_base_ge {a b t γ : ℝ} (hγ : 0 < γ) (htγ : γ ≤ t) (hab : a ≤ b) :
    ENNReal.ofReal (t ^ a) ≤ ENNReal.ofReal (t ^ b) * ENNReal.ofReal (γ ^ (a - b)) := by
  sorry

lemma rpow_le_rpow_of_exponent_le_base_ge_enorm {a b : ℝ} {t γ : ℝ≥0∞} (hγ : 0 < γ) (hγ' : γ ≠ ∞) (htγ : γ ≤ t) (hab : a ≤ b) :
    t ^ a ≤ (t ^ b) * (γ ^ (a - b)) := by
  sorry

end ENNReal

/-! ## Convenience results for working with (interpolated) exponents -/
namespace ComputationsInterpolatedExponents

lemma interp_exp_ne_top (hp₀p₁ : p₀ ≠ p₁) (ht : t ∈ Ioo 0 1)
    (hp : p⁻¹ = (1 - t) * p₀⁻¹ + t * p₁⁻¹) : p ≠ ⊤ := by
  sorry

lemma interp_exp_ne_top' (hp₀p₁ : p₀ ≠ ⊤ ∨ p₁ ≠ ⊤) (ht : t ∈ Ioo 0 1)
    (hp : p⁻¹ = (1 - t) * p₀⁻¹ + t * p₁⁻¹) : p ≠ ⊤ := by
  sorry

lemma interp_exp_eq (hp₀p₁ : p₀ = p₁)
    (ht : t ∈ Ioo 0 1) (hp : p⁻¹ = (1 - t) * p₀⁻¹ + t * p₁⁻¹) :
    p₀ = p := by
  sorry

lemma interp_exp_lt_top (hp₀p₁ : p₀ ≠ p₁)
    (ht : t ∈ Ioo 0 1)
    (hp : p⁻¹ = (1 - t) * p₀⁻¹ + t * p₁⁻¹) : p < ⊤ := by
  sorry

lemma interp_exp_lt_top' (hp₀p₁ : p₀ ≠ ⊤ ∨ p₁ ≠ ⊤)
    (ht : t ∈ Ioo 0 1)
    (hp : p⁻¹ = (1 - t) * p₀⁻¹ + t * p₁⁻¹) : p < ⊤ := by
  sorry

lemma interp_exp_between (hp₀ : 0 < p₀) (hp₁ : 0 < p₁)
    (hp₀p₁ : p₀ < p₁) (ht : t ∈ Ioo 0 1)
    (hp : p⁻¹ = (1 - t) * p₀⁻¹ + t * p₁⁻¹) : p ∈ Ioo p₀ p₁ := by
  sorry

lemma one_le_interp_exp_aux (hp₀ : 1 ≤ p₀) (hp₁ : 1 ≤ p₁) (hp₀p₁ : p₀ < p₁) (ht : t ∈ Ioo 0 1)
    (hp : p⁻¹ = (1 - t) * p₀⁻¹ + t * p₁⁻¹) : 1 ≤ p := by
  sorry

lemma switch_exponents (ht : t ∈ Ioo 0 1) (hp : p⁻¹ = (1 - t) * p₀⁻¹ + t * p₁⁻¹) :
    p⁻¹ = (1 - (1 - t)) * p₁⁻¹ + (1 - t) * p₀⁻¹ := by
  sorry

lemma one_le_interp (hp₀ : 1 ≤ p₀) (hp₁ : 1 ≤ p₁)
    (hp₀p₁ : p₀ ≠ p₁) (ht : t ∈ Ioo 0 1)
    (hp : p⁻¹ = (1 - t) * p₀⁻¹ + t * p₁⁻¹) : 1 ≤ p := by
  sorry

lemma one_le_interp_toReal (hp₀ : 1 ≤ p₀) (hp₁ : 1 ≤ p₁)
    (hp₀p₁ : p₀ ≠ p₁) (ht : t ∈ Ioo 0 1)
    (hp : p⁻¹ = (1 - t) * p₀⁻¹ + t * p₁⁻¹) : 1 ≤ p.toReal := by
  sorry

-- unused
lemma exp_toReal_ne_zero_of_Ico {q p : ℝ≥0∞} (hq : q ∈ Ico 1 p) : q.toReal ≠ 0 := by
  sorry

-- TODO : decide if this is wanted
-- local instance : Coe ℝ ℝ≥0∞ where
--   coe x := ENNReal.ofReal x

lemma inv_of_interpolated_pos' (hp₀p₁ : p₀ ≠ p₁) (ht : t ∈ Ioo 0 1)
    (hp : p⁻¹ = (1 - t) * p₀⁻¹ + t * p₁⁻¹) : 0 < p⁻¹ := by
  sorry

-- TODO: remove, this is redundant, but for now mirror the development for reals...
lemma interpolated_pos' (hp₀ : 0 < p₀) (hp₁ : 0 < p₁) (ht : t ≠ ∞)
    (hp : p⁻¹ = (1 - t) * p₀⁻¹ + t * p₁⁻¹) : 0 < p := by
  sorry

lemma exp_toReal_pos (hp₀ : 0 < p₀) (hp₀' : p₀ ≠ ⊤) : 0 < p₀.toReal := by
  sorry

lemma interp_exp_in_Ioo_zero_top (ht : t ∈ Ioo 0 1) (hp₀ : 0 < p₀) (hp₁ : 0 < p₁)
    (hp₀p₁ : p₀ ≠ ⊤ ∨ p₁ ≠ ⊤)
    (hp : p⁻¹ = (1 - t) * p₀⁻¹ + t * p₁⁻¹) : p ∈ Ioo 0 ⊤ := by
  sorry

lemma inv_toReal_pos_of_ne_top (hp₀ : 0 < p₀) (hp' : p₀ ≠ ⊤) : 0 < p₀⁻¹.toReal := by
  sorry

lemma inv_toReal_ne_zero_of_ne_top (hp₀ : 0 < p₀) (hp' : p₀ ≠ ⊤) : p₀⁻¹.toReal ≠ 0 := by
  sorry

lemma interp_exp_toReal_pos (ht : t ∈ Ioo 0 1) (hp₀ : 0 < p₀) (hp₁ : 0 < p₁) (hp₀p₁ : p₀ ≠ p₁)
    (hp : p⁻¹ = (1 - t) * p₀⁻¹ + t * p₁⁻¹) : 0 < p.toReal := by
  sorry

lemma interp_exp_toReal_pos' (ht : t ∈ Ioo 0 1) (hp₀ : 0 < p₀) (hp₁ : 0 < p₁)
    (hp : p⁻¹ = (1 - t) * p₀⁻¹ + t * p₁⁻¹)
    (hp₀p₁ : p₀ ≠ ⊤ ∨ p₁ ≠ ⊤) : 0 < p.toReal := by
  sorry

lemma interp_exp_inv_pos (ht : t ∈ Ioo 0 1) (hp₀ : 0 < p₀)
    (hp₁ : 0 < p₁) (hp₀p₁ : p₀ ≠ p₁) (hp : p⁻¹ = (1 - t) * p₀⁻¹ + t * p₁⁻¹) :
    0 < p⁻¹.toReal := by
  sorry

lemma interp_exp_inv_ne_zero (ht : t ∈ Ioo 0 1) (hp₀ : 0 < p₀)
    (hp₁ : 0 < p₁) (hp₀p₁ : p₀ ≠ p₁)
    (hp : p⁻¹ = (1 - t) * p₀⁻¹ + t * p₁⁻¹) : p⁻¹.toReal ≠ 0 := by
  sorry

lemma preservation_interpolation (ht : t ∈ Ioo 0 1) (hp₀ : 0 < p₀)
    (hp₁ : 0 < p₁) (hp : p⁻¹ = (1 - t) * p₀⁻¹ + t * p₁⁻¹) :
    p⁻¹.toReal = (1 - t).toReal * (p₀⁻¹).toReal + t.toReal * (p₁⁻¹).toReal := by
  sorry

lemma preservation_positivity_inv_toReal (ht : t ∈ Ioo 0 1) (hp₀ : 0 < p₀) (hp₁ : 0 < p₁)
    (hp₀p₁ : p₀ ≠ p₁) :
    0 < (1 - t.toReal) * (p₀⁻¹).toReal + t.toReal * (p₁⁻¹).toReal := by
  sorry

lemma ne_inv_toReal_exponents (hp₀ : 0 < p₀) (hp₁ : 0 < p₁) (hp₀p₁ : p₀ ≠ p₁) :
    p₀⁻¹.toReal ≠ p₁⁻¹.toReal := by
  sorry

lemma ne_inv_toReal_exp_interp_exp (ht : t ∈ Ioo 0 1) (hp₀ : 0 < p₀) (hp₁ : 0 < p₁) (hp₀p₁ : p₀ ≠ p₁)
    (hp : p⁻¹ = (1 - t) * p₀⁻¹ + t * p₁⁻¹) : p₀⁻¹.toReal ≠ p⁻¹.toReal := by
  sorry

lemma ne_sub_toReal_exp (hp₀ : 0 < p₀) (hp₁ : 0 < p₁) (hp₀p₁ : p₀ ≠ p₁) :
    p₁⁻¹.toReal - p₀⁻¹.toReal ≠ 0 := by
  sorry

lemma ne_toReal_exp_interp_exp (ht : t ∈ Ioo 0 1) (hp₀ : 0 < p₀) (hp₁ : 0 < p₁) (hp₀p₁ : p₀ ≠ p₁)
    (hp : p⁻¹ = (1 - t) * p₀⁻¹ + t * p₁⁻¹) : p₀.toReal ≠ p.toReal := by
  sorry

lemma ne_toReal_exp_interp_exp₁ (ht : t ∈ Ioo 0 1) (hp₀ : 0 < p₀) (hp₁ : 0 < p₁) (hp₀p₁ : p₀ ≠ p₁)
    (hp : p⁻¹ = (1 - t) * p₀⁻¹ + t * p₁⁻¹) :
    p.toReal ≠ p₁.toReal := by
  sorry

lemma ofReal_inv_interp_sub_exp_pos₁ (ht : t ∈ Ioo 0 1) (hq₀ : 0 < q₀) (hq₁ : 0 < q₁)
    (hq₀q₁ : q₀ ≠ q₁)
    (hq : q⁻¹ = (1 - t) * q₀⁻¹ + t * q₁⁻¹) :
    ENNReal.ofReal |q.toReal - q₁.toReal|⁻¹ > 0 := by
  sorry

lemma ofReal_inv_interp_sub_exp_pos₀ (ht : t ∈ Ioo 0 1) (hq₀ : 0 < q₀) (hq₁ : 0 < q₁)
    (hq₀q₁ : q₀ ≠ q₁) (hq : q⁻¹ = (1 - t) * q₀⁻¹ + t * q₁⁻¹) :
    ENNReal.ofReal |q.toReal - q₀.toReal|⁻¹ > 0 := by
  sorry

lemma exp_lt_iff (ht : t ∈ Ioo 0 1) (hp₀ : 0 < p₀) (hp₁ : 0 < p₁) (hp₀p₁ : p₀ ≠ p₁)
    (hp : p⁻¹ = (1 - t) * p₀⁻¹ + t * p₁⁻¹) :
    p < p₀ ↔ p₁ < p₀ := by
  sorry

lemma exp_gt_iff (ht : t ∈ Ioo 0 1) (hp₀ : 0 < p₀) (hp₁ : 0 < p₁) (hp₀p₁ : p₀ ≠ p₁)
    (hp : p⁻¹ = (1 - t) * p₀⁻¹ + t * p₁⁻¹) :
    p₀ < p ↔ p₀ < p₁ := by
  sorry

lemma exp_lt_exp_gt_iff (ht : t ∈ Ioo 0 1) (hp₀ : 0 < p₀) (hp₁ : 0 < p₁) (hp₀p₁ : p₀ ≠ p₁)
    (hp : p⁻¹ = (1 - t) * p₀⁻¹ + t * p₁⁻¹) :
    p < p₀ ↔ p₁ < p := by
  sorry

lemma exp_gt_exp_lt_iff (ht : t ∈ Ioo 0 1) (hp₀ : 0 < p₀) (hp₁ : 0 < p₁) (hp₀p₁ : p₀ ≠ p₁)
    (hp : p⁻¹ = (1 - t) * p₀⁻¹ + t * p₁⁻¹) :
    p₀ < p ↔ p < p₁ := by
  sorry

lemma exp_lt_iff₁ (ht : t ∈ Ioo 0 1) (hp₀ : 0 < p₀) (hp₁ : 0 < p₁) (hp₀p₁ : p₀ ≠ p₁)
    (hp : p⁻¹ = (1 - t) * p₀⁻¹ + t * p₁⁻¹) :
    p < p₁ ↔ p₀ < p₁ := by
  sorry

lemma exp_gt_iff₁ (ht : t ∈ Ioo 0 1) (hp₀ : 0 < p₀) (hp₁ : 0 < p₁) (hp₀p₁ : p₀ ≠ p₁)
    (hp : p⁻¹ = (1 - t) * p₀⁻¹ + t * p₁⁻¹) :
    p₁ < p ↔ p₁ < p₀ := by
  sorry

end ComputationsInterpolatedExponents

/-! ## Results about the particular choice of exponent

    The proof of the real interpolation theorem will estimate
    `distribution (trunc f A(t)) t` and `distribution (truncCompl f A(t)) t` for a
    function `A`. The function `A` can be given a closed-form expression that works for
    _all_ cases in the real interpolation theorem, because of the computation rules available
    for elements in `ℝ≥0∞` that avoid the need for a limiting procedure, e.g. `⊤⁻¹ = 0`.

    The function `A` will be of the form `A(t) = (t / d) ^ σ` for particular choices of `d` and
    `σ`. This section contatins results about the exponents `σ`.
-/
namespace ComputationsChoiceExponent

open ENNReal Real Set ComputationsInterpolatedExponents

variable {p₀ q₀ p₁ q₁ p q t : ℝ≥0∞}

def ζ (p₀ q₀ p₁ q₁ : ℝ≥0∞) (t : ℝ) : ℝ :=
  (((1 - t) * (p₀⁻¹).toReal + t * (p₁⁻¹).toReal) * ((q₁⁻¹).toReal - (q₀⁻¹).toReal)) /
  (((1 - t) * (q₀⁻¹).toReal + t * (q₁⁻¹).toReal) * ((p₁⁻¹).toReal - (p₀⁻¹).toReal))

lemma ζ_equality₁ (ht : t ∈ Ioo 0 1) :
    ζ p₀ q₀ p₁ q₁ t.toReal =
    (((1 - t).toReal * p₀⁻¹.toReal + t.toReal * p₁⁻¹.toReal) *
    ((1 - t).toReal * q₀⁻¹.toReal + t.toReal * q₁⁻¹.toReal - q₀⁻¹.toReal)) /
    (((1 - t).toReal * q₀⁻¹.toReal + t.toReal * q₁⁻¹.toReal) *
    ((1 - t).toReal * p₀⁻¹.toReal + t.toReal * p₁⁻¹.toReal - p₀⁻¹.toReal)) := by
  sorry

lemma ζ_equality₂ (ht : t ∈ Ioo 0 1) :
    ζ p₀ q₀ p₁ q₁ t.toReal =
    (((1 - t).toReal * p₀⁻¹.toReal + t.toReal * p₁⁻¹.toReal) *
    ((1 - t).toReal * q₀⁻¹.toReal + t.toReal * q₁⁻¹.toReal - q₁⁻¹.toReal)) /
    (((1 - t).toReal * q₀⁻¹.toReal + t.toReal * q₁⁻¹.toReal) *
    ((1 - t).toReal * p₀⁻¹.toReal + t.toReal * p₁⁻¹.toReal - p₁⁻¹.toReal)) := by
  sorry

lemma ζ_symm (ht : t ∈ Ioo 0 1) : ζ p₀ q₀ p₁ q₁ t.toReal = ζ p₁ q₁ p₀ q₀ (1 - t).toReal := by
  sorry

set_option linter.style.multiGoal false in
set_option linter.flexible false in
lemma ζ_equality₃ (ht : t ∈ Ioo 0 1) (hp₀ : 0 < p₀) (hq₀ : 0 < q₀) (hp₁ : 0 < p₁) (hq₁ : 0 < q₁)
    (hp₀p₁ : p₀ ≠ p₁) (hq₀q₁ : q₀ ≠ q₁)
    (hp : p⁻¹ = (1 - t) * p₀⁻¹ + t * p₁⁻¹)
    (hq : q⁻¹ = (1 - t) * q₀⁻¹ + t * q₁⁻¹) (hp₀' : p₀ ≠ ⊤)
    (hq₀' : q₀ ≠ ⊤) :
    ζ p₀ q₀ p₁ q₁ t.toReal = (p₀.toReal * (q₀.toReal - q.toReal))  / (q₀.toReal * (p₀.toReal - p.toReal)) := by
  sorry

lemma ζ_equality₄ (ht : t ∈ Ioo 0 1) (hp₀ : 0 < p₀) (hq₀ : 0 < q₀) (hp₁ : 0 < p₁) (hq₁ : 0 < q₁)
    (hp₀p₁ : p₀ ≠ p₁) (hq₀q₁ : q₀ ≠ q₁)
    (hp : p⁻¹ = (1 - t) * p₀⁻¹ + t * p₁⁻¹)
    (hq : q⁻¹ = (1 - t) * q₀⁻¹ + t * q₁⁻¹) (hp₁' : p₁ ≠ ⊤)
    (hq₁' : q₁ ≠ ⊤) :
    ζ p₀ q₀ p₁ q₁ t.toReal =
    (p₁.toReal * (q₁.toReal - q.toReal)) / (q₁.toReal * (p₁.toReal - p.toReal)) := by
  sorry

lemma ζ_equality₅ {t : ℝ≥0∞} (ht : t ∈ Ioo 0 1) (hp₀ : 0 < p₀) (hq₀ : 0 < q₀) (hp₁ : 0 < p₁) (hq₁ : 0 < q₁)
    (hp₀p₁ : p₀ ≠ p₁) (hq₀q₁ : q₀ ≠ q₁)
    (hp : p⁻¹ = (1 - t) * p₀⁻¹ + t * p₁⁻¹)
    (hq : q⁻¹ = (1 - t) * q₀⁻¹ + t * q₁⁻¹) (hp₀' : p₀ ≠ ⊤)
    (hq₀' : q₀ ≠ ⊤) :
    p₀.toReal + (ζ p₀ q₀ p₁ q₁ t.toReal)⁻¹ * (q.toReal - q₀.toReal) * (p₀.toReal / q₀.toReal) = p.toReal := by
  sorry

lemma ζ_equality₆ {t : ℝ≥0∞} (ht : t ∈ Ioo 0 1) (hp₀ : 0 < p₀) (hq₀ : 0 < q₀) (hp₁ : 0 < p₁) (hq₁ : 0 < q₁)
    (hp₀p₁ : p₀ ≠ p₁) (hq₀q₁ : q₀ ≠ q₁)
    (hp : p⁻¹ = (1 - t) * p₀⁻¹ + t * p₁⁻¹)
    (hq : q⁻¹ = (1 - t) * q₀⁻¹ + t * q₁⁻¹) (hp₁' : p₁ ≠ ⊤)
    (hq₁' : q₁ ≠ ⊤) :
    p₁.toReal + (ζ p₀ q₀ p₁ q₁ t.toReal)⁻¹ * (q.toReal - q₁.toReal) * (p₁.toReal / q₁.toReal) = p.toReal := by
  sorry

lemma ζ_equality₇ (ht : t ∈ Ioo 0 1) (hp₀ : 0 < p₀) (hq₀ : 0 < q₀) (hp₁ : 0 < p₁) (hq₁ : 0 < q₁)
    (hp₀p₁ : p₀ ≠ p₁) (hq₀q₁ : q₀ ≠ q₁)
    (hp : p⁻¹ = (1 - t) * p₀⁻¹ + t * p₁⁻¹)
    (hq : q⁻¹ = (1 - t) * q₀⁻¹ + t * q₁⁻¹) (hp₀' : p₀ ≠ ⊤)
    (hq₀' : q₀ = ⊤) :
    ζ p₀ q₀ p₁ q₁ t.toReal = p₀.toReal / (p₀.toReal - p.toReal) := by
  sorry

lemma ζ_equality₈ (ht : t ∈ Ioo 0 1) (hp₀ : 0 < p₀) (hq₀ : 0 < q₀) (hp₁ : 0 < p₁) (hq₁ : 0 < q₁)
    (hp₀p₁ : p₀ ≠ p₁) (hq₀q₁ : q₀ ≠ q₁)
    (hp : p⁻¹ = (1 - t) * p₀⁻¹ + t * p₁⁻¹)
    (hq : q⁻¹ = (1 - t) * q₀⁻¹ + t * q₁⁻¹) (hp₁' : p₁ ≠ ⊤)
    (hq₁' : q₁ = ⊤) :
    ζ p₀ q₀ p₁ q₁ t.toReal = p₁.toReal / (p₁.toReal - p.toReal) := by
  sorry

lemma ζ_eq_top_top (ht : t ∈ Ioo 0 1) (hp₀ : 0 < p₀) (hq₀ : 0 < q₀)
    (hp₁ : 0 < p₁) (hq₁ : 0 < q₁) (hp₀p₁ : p₀ ≠ p₁) (hq₀q₁ : q₀ ≠ q₁)
    (hp : p⁻¹ = (1 - t) * p₀⁻¹ + t * p₁⁻¹)
    (hq : q⁻¹ = (1 - t) * q₀⁻¹ + t * q₁⁻¹) (hp₁' : p₁ = ⊤)
    (hq₁' : q₁ = ⊤) :
    ζ p₀ q₀ p₁ q₁ t.toReal = 1 := by
  sorry

lemma ζ_pos_iff_aux (hp₀ : 0 < p₀) (hq₀ : 0 < q₀) (hp₀' : p₀ ≠ ⊤) (hq₀' : q₀ ≠ ⊤) :
    ( 0 < p₀.toReal * (q₀.toReal - q.toReal) / (q₀.toReal * (p₀.toReal - p.toReal))) ↔
    ((q.toReal < q₀.toReal) ∧ (p.toReal < p₀.toReal)) ∨
    ((q₀.toReal < q.toReal) ∧ (p₀.toReal < p.toReal)) := by
  sorry

lemma preservation_inequality (ht : t ∈ Ioo 0 1) (hp₀p₁ : p₀ ≠ p₁)
    (hp : p⁻¹ = (1 - t) * p₀⁻¹ + t * p₁⁻¹) (hp₀' : p₀ ≠ ⊤) :
    p.toReal < p₀.toReal ↔ p < p₀ := by
  sorry

lemma preservation_inequality' (ht : t ∈ Ioo 0 1) (hp₀p₁ : p₀ ≠ p₁)
    (hp : p⁻¹ = (1 - t) * p₀⁻¹ + t * p₁⁻¹) (hp₀' : p₀ ≠ ⊤) :
    p₀.toReal < p.toReal ↔ p₀ < p := by
  sorry

lemma preservation_inequality_of_lt₀ (ht : t ∈ Ioo 0 1) (hq₀ : 0 < q₀) (hq₁ : 0 < q₁)
    (hq : q⁻¹ = (1 - t) * q₀⁻¹ + t * q₁⁻¹) (hq₀q₁ : q₀ < q₁) :
    q₀.toReal < q.toReal := by
  sorry

lemma preservation_inequality_of_lt₁ (ht : t ∈ Ioo 0 1) (hq₀ : 0 < q₀) (hq₁ : 0 < q₁)
    (hq : q⁻¹ = (1 - t) * q₀⁻¹ + t * q₁⁻¹) (hq₀q₁ : q₀ < q₁)
    (hq₁' : q₁ ≠ ⊤) :
    q.toReal < q₁.toReal := by
  sorry

lemma ζ_pos_toReal_iff₀ (ht : t ∈ Ioo 0 1) (hp₀ : 0 < p₀) (hq₀ : 0 < q₀) (hp₁ : 0 < p₁)
    (hq₁ : 0 < q₁) (hp₀p₁ : p₀ ≠ p₁) (hq₀q₁ : q₀ ≠ q₁)
    (hp : p⁻¹ = (1 - t) * p₀⁻¹ + t * p₁⁻¹)
    (hq : q⁻¹ = (1 - t) * q₀⁻¹ + t * q₁⁻¹) (hp₀' : p₀ ≠ ⊤)
    (hq₀' : q₀ ≠ ⊤) : (0 < ζ p₀ q₀ p₁ q₁ t.toReal) ↔
    ((q.toReal < q₀.toReal) ∧ (p.toReal < p₀.toReal)) ∨
    ((q₀.toReal < q.toReal) ∧ (p₀.toReal < p.toReal)) := by
  sorry

lemma ζ_pos_toReal_iff₁ (ht : t ∈ Ioo 0 1) (hp₀ : 0 < p₀) (hq₀ : 0 < q₀) (hp₁ : 0 < p₁)
    (hq₁ : 0 < q₁) (hp₀p₁ : p₀ ≠ p₁) (hq₀q₁ : q₀ ≠ q₁)
    (hp : p⁻¹ = (1 - t) * p₀⁻¹ + t * p₁⁻¹)
    (hq : q⁻¹ = (1 - t) * q₀⁻¹ + t * q₁⁻¹) (hp₁' : p₁ ≠ ⊤)
    (hq₁' : q₁ ≠ ⊤) :
    (0 < ζ p₀ q₀ p₁ q₁ t.toReal) ↔
    ((q.toReal < q₁.toReal) ∧ (p.toReal < p₁.toReal)) ∨
    ((q₁.toReal < q.toReal) ∧ (p₁.toReal < p.toReal)) := by
  sorry

lemma ζ_pos_iff_aux₀ (ht : t ∈ Ioo 0 1) (hp₀ : 0 < p₀) (hq₀ : 0 < q₀)
    (hp₁ : 0 < p₁) (hq₁ : 0 < q₁) (hp₀p₁ : p₀ ≠ p₁) (hq₀q₁ : q₀ ≠ q₁) :
    (0 < ζ p₀ q₀ p₁ q₁ t.toReal) ↔
    q₀⁻¹.toReal < q₁⁻¹.toReal ∧ p₀⁻¹.toReal < p₁⁻¹.toReal ∨
    q₁⁻¹.toReal < q₀⁻¹.toReal ∧ p₁⁻¹.toReal < p₀⁻¹.toReal := by
  sorry

lemma inv_toReal_iff (hp₀ : 0 < p₀) (hp₁ : 0 < p₁) :
    p₀⁻¹.toReal < p₁⁻¹.toReal ↔ p₁ < p₀ := by
  sorry

lemma ζ_pos_iff (ht : t ∈ Ioo 0 1) (hp₀ : 0 < p₀) (hq₀ : 0 < q₀) (hp₁ : 0 < p₁) (hq₁ : 0 < q₁)
    (hp₀p₁ : p₀ ≠ p₁) (hq₀q₁ : q₀ ≠ q₁) :
    (0 < ζ p₀ q₀ p₁ q₁ t.toReal) ↔
    ((q₁ < q₀) ∧ (p₁ < p₀)) ∨ ((q₀ < q₁) ∧ (p₀ < p₁)) := by
  sorry

lemma ζ_pos_iff' (ht : t ∈ Ioo 0 1) (hp₀ : 0 < p₀) (hq₀ : 0 < q₀)
    (hp₁ : 0 < p₁) (hq₁ : 0 < q₁) (hp₀p₁ : p₀ ≠ p₁) (hq₀q₁ : q₀ ≠ q₁)
    (hp : p⁻¹ = (1 - t) * p₀⁻¹ + t * p₁⁻¹)
    (hq : q⁻¹ = (1 - t) * q₀⁻¹ + t * q₁⁻¹) :
    0 < ζ p₀ q₀ p₁ q₁ t.toReal ↔ (q < q₀ ∧ p < p₀) ∨ (q₀ < q ∧ p₀ < p) := by
  sorry

lemma ζ_pos_iff_of_lt₀ (ht : t ∈ Ioo 0 1) (hp₀ : 0 < p₀) (hq₀ : 0 < q₀)
    (hp₁ : 0 < p₁) (hq₁ : 0 < q₁) (hq₀q₁ : q₀ ≠ q₁)
    (hp : p⁻¹ = (1 - t) * p₀⁻¹ + t * p₁⁻¹)
    (hq : q⁻¹ = (1 - t) * q₀⁻¹ + t * q₁⁻¹) (hp₀p₁' : p₀ < p₁) :
    0 < ζ p₀ q₀ p₁ q₁ t.toReal ↔ q₀ < q := by
  sorry

lemma ζ_pos_iff_of_lt₁ {t : ℝ≥0∞} (ht : t ∈ Ioo 0 1) (hp₀ : 0 < p₀) (hq₀ : 0 < q₀)
  (hp₁ : 0 < p₁) (hq₁ : 0 < q₁) (hq₀q₁ : q₀ ≠ q₁)
    (hp : p⁻¹ = (1 - t) * p₀⁻¹ + t * p₁⁻¹)
    (hq : q⁻¹ = (1 - t) * q₀⁻¹ + t * q₁⁻¹) (hp₀p₁' : p₀ < p₁) :
    0 < ζ p₀ q₀ p₁ q₁ t.toReal ↔ q < q₁ := by
  sorry

lemma ζ_neg_iff_aux₀ (ht : t ∈ Ioo 0 1) (hp₀ : 0 < p₀) (hq₀ : 0 < q₀) (hp₁ : 0 < p₁) (hq₁ : 0 < q₁)
    (hp₀p₁ : p₀ ≠ p₁) (hq₀q₁ : q₀ ≠ q₁) :
    (ζ p₀ q₀ p₁ q₁ t.toReal) < 0 ↔
      q₀⁻¹.toReal < q₁⁻¹.toReal ∧ p₁⁻¹.toReal < p₀⁻¹.toReal ∨
      q₁⁻¹.toReal < q₀⁻¹.toReal ∧ p₀⁻¹.toReal < p₁⁻¹.toReal := by
  sorry

lemma ζ_neg_iff (ht : t ∈ Ioo 0 1) (hp₀ : 0 < p₀) (hq₀ : 0 < q₀) (hp₁ : 0 < p₁) (hq₁ : 0 < q₁)
    (hp₀p₁ : p₀ ≠ p₁) (hq₀q₁ : q₀ ≠ q₁) :
    ζ p₀ q₀ p₁ q₁ t.toReal < 0 ↔ q₁ < q₀ ∧ p₀ < p₁ ∨ q₀ < q₁ ∧ p₁ < p₀ := by
  sorry

lemma ζ_neg_iff' (ht : t ∈ Ioo 0 1) (hp₀ : 0 < p₀) (hq₀ : 0 < q₀) (hp₁ : 0 < p₁) (hq₁ : 0 < q₁)
    (hp₀p₁ : p₀ ≠ p₁) (hq₀q₁ : q₀ ≠ q₁)
    (hp : p⁻¹ = (1 - t) * p₀⁻¹ + t * p₁⁻¹)
    (hq : q⁻¹ = (1 - t) * q₀⁻¹ + t * q₁⁻¹) :
    ζ p₀ q₀ p₁ q₁ t.toReal < 0 ↔ (q < q₀ ∧ p₀ < p) ∨ (q₀ < q ∧ p < p₀) := by
  sorry

lemma ζ_neg_iff_of_lt₀ (ht : t ∈ Ioo 0 1) (hp₀ : 0 < p₀) (hq₀ : 0 < q₀) (hp₁ : 0 < p₁)
    (hq₁ : 0 < q₁) (hq₀q₁ : q₀ ≠ q₁)
    (hp : p⁻¹ = (1 - t) * p₀⁻¹ + t * p₁⁻¹)
    (hq : q⁻¹ = (1 - t) * q₀⁻¹ + t * q₁⁻¹) (hp₀p₁' : p₀ < p₁) :
    ζ p₀ q₀ p₁ q₁ t.toReal < 0 ↔ q < q₀ := by
  sorry

lemma ζ_neg_iff_of_lt₁ (ht : t ∈ Ioo 0 1) (hp₀ : 0 < p₀) (hq₀ : 0 < q₀) (hp₁ : 0 < p₁)
    (hq₁ : 0 < q₁) (hq₀q₁ : q₀ ≠ q₁)
    (hp : p⁻¹ = (1 - t) * p₀⁻¹ + t * p₁⁻¹)
    (hq : q⁻¹ = (1 - t) * q₀⁻¹ + t * q₁⁻¹) (hp₀p₁' : p₀ < p₁) :
    ζ p₀ q₀ p₁ q₁ t.toReal < 0 ↔ q₁ < q := by
  sorry

lemma ζ_neg_iff_aux (hp₀ : 0 < p₀) (hq₀ : 0 < q₀) (hp₀' : p₀ ≠ ⊤)
    (hq₀' : q₀ ≠ ⊤) :
    (p₀.toReal * (q₀.toReal - q.toReal) / (q₀.toReal * (p₀.toReal - p.toReal)) < 0) ↔
    (q.toReal < q₀.toReal) ∧ (p₀.toReal < p.toReal) ∨
    (q₀.toReal < q.toReal) ∧ (p.toReal < p₀.toReal) := by
  sorry

lemma ζ_neg_toReal_iff₀ (ht : t ∈ Ioo 0 1) (hp₀ : 0 < p₀) (hq₀ : 0 < q₀) (hp₁ : 0 < p₁)
    (hq₁ : 0 < q₁) (hp₀p₁ : p₀ ≠ p₁) (hq₀q₁ : q₀ ≠ q₁)
    (hp : p⁻¹ = (1 - t) * p₀⁻¹ + t * p₁⁻¹)
    (hq : q⁻¹ = (1 - t) * q₀⁻¹ + t * q₁⁻¹) (hp₀' : p₀ ≠ ⊤)
    (hq₀' : q₀ ≠ ⊤) :
    ζ p₀ q₀ p₁ q₁ t.toReal < 0 ↔
      (q.toReal < q₀.toReal ∧ p₀.toReal < p.toReal) ∨
      (q₀.toReal < q.toReal ∧ p.toReal < p₀.toReal) := by
  sorry

lemma ζ_neg_toReal_iff₁ (ht : t ∈ Ioo 0 1) (hp₀ : 0 < p₀) (hq₀ : 0 < q₀) (hp₁ : 0 < p₁)
    (hq₁ : 0 < q₁) (hp₀p₁ : p₀ ≠ p₁) (hq₀q₁ : q₀ ≠ q₁)
    (hp : p⁻¹ = (1 - t) * p₀⁻¹ + t * p₁⁻¹)
    (hq : q⁻¹ = (1 - t) * q₀⁻¹ + t * q₁⁻¹) (hp₁' : p₁ ≠ ⊤)
    (hq₁' : q₁ ≠ ⊤) :
    ζ p₀ q₀ p₁ q₁ t.toReal < 0 ↔
      (q.toReal < q₁.toReal ∧ p₁.toReal < p.toReal) ∨
      (q₁.toReal < q.toReal ∧ p.toReal < p₁.toReal) := by
  sorry

lemma ζ_neg_iff₀ (ht : t ∈ Ioo 0 1) (hp₀ : 0 < p₀) (hq₀ : 0 < q₀) (hp₁ : 0 < p₁) (hq₁ : 0 < q₁)
    (hp₀p₁ : p₀ ≠ p₁) (hq₀q₁ : q₀ ≠ q₁)
    (hp : p⁻¹ = (1 - t) * p₀⁻¹ + t * p₁⁻¹)
    (hq : q⁻¹ = (1 - t) * q₀⁻¹ + t * q₁⁻¹) (hp₀' : p₀ ≠ ⊤)
    (hq₀' : q₀ ≠ ⊤) :
    ζ p₀ q₀ p₁ q₁ t.toReal < 0 ↔ (q < q₀ ∧ p₀ < p) ∨ (q₀ < q ∧ p < p₀) := by
  sorry

lemma ζ_ne_zero (ht : t ∈ Ioo 0 1) (hp₀ : 0 < p₀) (hq₀ : 0 < q₀) (hp₁ : 0 < p₁) (hq₁ : 0 < q₁)
    (hp₀p₁ : p₀ ≠ p₁) (hq₀q₁ : q₀ ≠ q₁) :
    ζ p₀ q₀ p₁ q₁ t.toReal ≠ 0 := by
  sorry

lemma ζ_le_zero_iff_of_lt₀ (ht : t ∈ Ioo 0 1) (hp₀ : 0 < p₀) (hq₀ : 0 < q₀) (hp₁ : 0 < p₁)
    (hq₁ : 0 < q₁) (hq₀q₁ : q₀ ≠ q₁)
    (hp : p⁻¹ = (1 - t) * p₀⁻¹ + t * p₁⁻¹)
    (hq : q⁻¹ = (1 - t) * q₀⁻¹ + t * q₁⁻¹) (hp₀p₁' : p₀ < p₁) :
    ζ p₀ q₀ p₁ q₁ t.toReal ≤ 0 ↔ q < q₀ := by
  sorry

lemma ζ_le_zero_iff_of_lt₁ (ht : t ∈ Ioo 0 1) (hp₀ : 0 < p₀) (hq₀ : 0 < q₀) (hp₁ : 0 < p₁)
    (hq₁ : 0 < q₁) (hq₀q₁ : q₀ ≠ q₁)
    (hp : p⁻¹ = (1 - t) * p₀⁻¹ + t * p₁⁻¹)
    (hq : q⁻¹ = (1 - t) * q₀⁻¹ + t * q₁⁻¹) (hp₀p₁' : p₀ < p₁) :
    ζ p₀ q₀ p₁ q₁ t.toReal ≤ 0 ↔ q₁ < q := by
  sorry

private lemma one_sub_ioo_toReal {t : ℝ≥0∞} (ht : t ∈ Ioo 0 1) :
    (1 - t).toReal = 1 - t.toReal := by
  sorry

lemma eq_exponents₀ (ht : t ∈ Ioo 0 1) (hq₀ : 0 < q₀) (hq₁ : 0 < q₁) (hq₀q₁ : q₀ ≠ q₁)
    (hq : q⁻¹ = (1 - t) * q₀⁻¹ + t * q₁⁻¹) (hq₀' : q₀ ≠ ⊤) :
    (q₀.toReal + q₁⁻¹.toReal / (q₁⁻¹.toReal - q₀⁻¹.toReal) *
      (q.toReal - q₀.toReal)) = (1 - t).toReal * q.toReal := by
  sorry

lemma eq_exponents₂ (ht : t ∈ Ioo 0 1) (hq₀ : 0 < q₀) (hq₁ : 0 < q₁) (hq₀q₁ : q₀ ≠ q₁)
    (hq : q⁻¹ = (1 - t) * q₀⁻¹ + t * q₁⁻¹) (hq₀' : q₀ ≠ ⊤) :
    (q₀.toReal / p₀.toReal + p₀⁻¹.toReal * q₁⁻¹.toReal / (q₁⁻¹.toReal - q₀⁻¹.toReal) *
      (q.toReal - q₀.toReal)) = (1 - t).toReal * p₀⁻¹.toReal * q.toReal := by
  sorry

lemma eq_exponents₁ (ht : t ∈ Ioo 0 1) (hq₀ : 0 < q₀) (hq₁ : 0 < q₁) (hq₀q₁ : q₀ ≠ q₁)
    (hq : q⁻¹ = (1 - t) * q₀⁻¹ + t * q₁⁻¹) (hq₀' : q₀ ≠ ⊤) :
    (q₀⁻¹.toReal / (q₁⁻¹.toReal - q₀⁻¹.toReal)) * (q.toReal - q₀.toReal) = - t.toReal * q.toReal := by
  sorry

-- TODO: simplify these proofs with statements above
lemma eq_exponents₃ (ht : t ∈ Ioo 0 1) (hq₀ : 0 < q₀) (hq₁ : 0 < q₁) (hq₀q₁ : q₀ ≠ q₁)
    (hq : q⁻¹ = (1 - t) * q₀⁻¹ + t * q₁⁻¹) (hq₀' : q₀ ≠ ⊤) :
    (p₁⁻¹.toReal * q₀⁻¹.toReal / (q₁⁻¹.toReal - q₀⁻¹.toReal)) * (q.toReal - q₀.toReal) =
      - t.toReal * p₁⁻¹.toReal * q.toReal := by
  sorry

lemma eq_exponents₄ :
    q₀⁻¹.toReal / (q₁⁻¹.toReal - q₀⁻¹.toReal) = - (q₀⁻¹.toReal / (q₀⁻¹.toReal - q₁⁻¹.toReal)) := by
  sorry

lemma eq_exponents₅ (ht : t ∈ Ioo 0 1) (hq₀ : 0 < q₀) (hq₁ : 0 < q₁) (hq₀q₁ : q₀ ≠ q₁)
    (hq : q⁻¹ = (1 - t) * q₀⁻¹ + t * q₁⁻¹) (hq₁' : q₁ ≠ ⊤) :
    (q₁.toReal + -(q₀⁻¹.toReal / (q₁⁻¹.toReal - q₀⁻¹.toReal) * (q.toReal - q₁.toReal)))
      = t.toReal * q.toReal := by
  sorry

lemma eq_exponents₆ (ht : t ∈ Ioo 0 1) (hq₀ : 0 < q₀) (hq₁ : 0 < q₁) (hq₀q₁ : q₀ ≠ q₁)
    (hq : q⁻¹ = (1 - t) * q₀⁻¹ + t * q₁⁻¹) (hq₁' : q₁ ≠ ⊤) :
    q₁⁻¹.toReal / (q₁⁻¹.toReal - q₀⁻¹.toReal) * (q.toReal - q₁.toReal) = (1 - t).toReal * q.toReal := by
  sorry

lemma eq_exponents₇ (ht : t ∈ Ioo 0 1) (hq₀ : 0 < q₀) (hq₁ : 0 < q₁) (hq₀q₁ : q₀ ≠ q₁)
    (hq : q⁻¹ = (1 - t) * q₀⁻¹ + t * q₁⁻¹) (hq₁' : q₁ ≠ ⊤) :
    q₁.toReal / p₁.toReal + -(p₁⁻¹.toReal * q₀⁻¹.toReal / (q₁⁻¹.toReal - q₀⁻¹.toReal) *
    (q.toReal - q₁.toReal)) =
    t.toReal * p₁⁻¹.toReal * q.toReal := by
  sorry

lemma eq_exponents₈ (ht : t ∈ Ioo 0 1) (hq₀ : 0 < q₀) (hq₁ : 0 < q₁) (hq₀q₁ : q₀ ≠ q₁)
    (hq : q⁻¹ = (1 - t) * q₀⁻¹ + t * q₁⁻¹) (hq₁' : q₁ ≠ ⊤) :
    p₀⁻¹.toReal * q₁⁻¹.toReal / (q₁⁻¹.toReal - q₀⁻¹.toReal) * (q.toReal - q₁.toReal) =
    (1 - t).toReal * p₀⁻¹.toReal * q.toReal := by
  sorry

end ComputationsChoiceExponent
