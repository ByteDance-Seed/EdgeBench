module

public import Carleson.ToMathlib.Data.Real.ConjExponents
public import Carleson.ToMathlib.MeasureTheory.Function.LpSeminorm.Basic
public import Carleson.ToMathlib.MeasureTheory.Integral.Periodic
public import Carleson.ToMathlib.MeasureTheory.Measure.Haar.Unique

public section

-- Upstreaming status: results seems useful; proofs may need polish
-- Needs dependencies to be upstreamed first.

open NNReal ENNReal MeasureTheory Finset

variable {α : Type*} [MeasurableSpace α] {μ : Measure α}

namespace ENNReal

/-- **Minkowski inequality** for finite sums of `ENNReal`-valued functions. -/
theorem Lp_add_le_sum
    {ι κ : Type*} {s : Finset ι} {t : Finset κ} {f : ι → κ → ℝ≥0∞} {p : ℝ} (hp : 1 ≤ p) :
    (∑ i ∈ s, (∑ j ∈ t, f i j) ^ p) ^ (1 / p) ≤ ∑ j ∈ t, (∑ i ∈ s, f i j ^ p) ^ (1 / p) := by
  sorry

-- Add after `lintegral_prod_norm_pow_le`
/-- A version of Hölder with multiple arguments, allowing `∞` as an exponent. -/
theorem lintegral_prod_norm_pow_le' {α ι : Type*} [MeasurableSpace α] {μ : Measure α}
    {s : Finset ι} {f : ι → α → ℝ≥0∞} (hf : ∀ i ∈ s, AEMeasurable (f i) μ)
    {p : ι → ℝ≥0∞} (hp : ∑ i ∈ s, (p i)⁻¹ = 1) :
    ∫⁻ (a : α), ∏ i ∈ s, f i a ∂μ ≤ ∏ i ∈ s, eLpNorm (f i) (p i) μ := by
  sorry

/-- **Hölder's inequality** for functions `α → ℝ≥0∞`, using exponents in `ℝ≥0∞` -/
theorem lintegral_mul_le_eLpNorm_mul_eLqNorm {p q : ℝ≥0∞} (hpq : p.HolderConjugate q)
    {f g : α → ENNReal} (hf : AEMeasurable f μ) (hg : AEMeasurable g μ) :
    ∫⁻ (a : α), (f * g) a ∂μ ≤ eLpNorm f p μ * eLpNorm g q μ := by
  sorry

/-- **Cauchy–Schwarz inequality** for functions `α → ℝ≥0∞` (Hölder's inequality squared). -/
theorem sq_lintegral_mul_le_mul_lintegral_sq {f g : α → ℝ≥0∞}
    (hf : AEMeasurable f μ) (hg : AEMeasurable g μ) :
    (∫⁻ a, f a * g a ∂μ) ^ 2 ≤ (∫⁻ a, f a ^ 2 ∂μ) * ∫⁻ a, g a ^ 2 ∂μ := by
  sorry

end ENNReal

section Convolution

open scoped Convolution

-- Used in the proof of Young's convolution inequality
private lemma r_sub_p_nonneg {p q r : ℝ} (p0 : 0 < p) (hq : 1 ≤ q) (r0 : 0 < r)
    (hpqr : p⁻¹ + q⁻¹ = r⁻¹ + 1) : 0 ≤ r - p := by
  sorry

namespace ENNReal

universe u𝕜 uG uE uE' uF

variable {𝕜 : Type u𝕜} {G : Type uG} [MeasurableSpace G] {μ : Measure G}
  {E : Type uE} {E' : Type uE'} {F : Type uF}

variable [NormedAddCommGroup E] [NormedAddCommGroup E'] [NormedAddCommGroup F]
  {f : G → E} {g : G → E'}

-- Used in the proof of `enorm_convolution_le_eLpNorm_mul_eLpNorm_mul_eLpNorm`
open ENNReal in
private lemma eLpNorm_eq_eLpNorm_rpow (h : G → E) {r e : ℝ} (r0 : 0 < r) (e0 : 0 < e)
    (re0 : 0 ≤ r - e) (μ0 : μ ≠ 0) :
    eLpNorm (‖h ·‖ₑ ^ ((r - e) / r)) (ENNReal.ofReal (e * r) / ENNReal.ofReal (r - e)) μ =
    eLpNorm h (ENNReal.ofReal e) μ ^ ((r - e) / r) := by
  sorry

variable [NontriviallyNormedField 𝕜]

variable [NormedSpace 𝕜 E] [NormedSpace 𝕜 E'] [NormedSpace 𝕜 F] [NormedSpace ℝ F]
variable {L : E →L[𝕜] E' →L[𝕜] F}

-- Used to handle trivial case `c ≤ 0` when proving versions of Young's convolution inequality
-- assuming `∀ (x y : G), ‖L (f x) (g y)‖ ≤ c * ‖f x‖ * ‖g y‖)`
private theorem convolution_zero_of_c_nonpos [AddGroup G] {f : G → E} {g : G → E'} {c : ℝ}
    (hL : ∀ (x y : G), ‖L (f x) (g y)‖ ≤ c * ‖f x‖ * ‖g y‖) (hc : c ≤ 0) : f ⋆[L, μ] g = 0 := by
  sorry

-- Auxiliary inequality used to prove inequalities with simpler conditions on f and g.
private theorem eLpNorm_top_convolution_le_aux [AddGroup G] {p q : ℝ≥0∞}
    (hpq : p.HolderConjugate q) {f : G → E} {g : G → E'} (hf : AEMeasurable (‖f ·‖ₑ) μ)
    (hg : ∀ x : G, AEMeasurable (‖g <| x - ·‖ₑ) μ)
    (hg' : ∀ x : G, eLpNorm (‖g <| x - ·‖ₑ) q μ = eLpNorm (‖g ·‖ₑ) q μ)
    (c : ℝ) (hL : ∀ (x y : G), ‖L (f x) (g y)‖ ≤ c * ‖f x‖ * ‖g y‖) :
    eLpNorm (f ⋆[L, μ] g) ∞ μ ≤ ENNReal.ofReal c * eLpNorm f p μ * eLpNorm g q μ := by
  sorry

variable [AddGroup G] [TopologicalSpace G] [IsTopologicalAddGroup G] [BorelSpace G]
  [μ.IsAddHaarMeasure] [LocallyCompactSpace G] [SecondCountableTopology G]

/-- Special case of **Young's convolution inequality** when `r = ∞`. -/
theorem eLpNorm_top_convolution_le [MeasurableSpace E] [OpensMeasurableSpace E]
    [MeasurableSpace E'] [OpensMeasurableSpace E'] [μ.IsNegInvariant] {p q : ℝ≥0∞}
    (hpq : p.HolderConjugate q) {f : G → E} {g : G → E'} (hf : AEMeasurable f μ)
    (hg : AEMeasurable g μ) (c : ℝ) (hL : ∀ (x y : G), ‖L (f x) (g y)‖ ≤ c * ‖f x‖ * ‖g y‖) :
    eLpNorm (f ⋆[L, μ] g) ∞ μ ≤ ENNReal.ofReal c * eLpNorm f p μ * eLpNorm g q μ := by
  sorry

/-- Special case of **Young's convolution inequality** when `r = ∞`. -/
theorem eLpNorm_top_convolution_le' [μ.IsNegInvariant] {p q : ℝ≥0∞} (hpq : p.HolderConjugate q) {f : G → E} {g : G → E'}
    (hf : AEStronglyMeasurable f μ) (hg : AEStronglyMeasurable g μ) (c : ℝ)
    (hL : ∀ (x y : G), ‖L (f x) (g y)‖ ≤ c * ‖f x‖ * ‖g y‖) :
    eLpNorm (f ⋆[L, μ] g) ∞ μ ≤ ENNReal.ofReal c * eLpNorm f p μ * eLpNorm g q μ := by
  sorry

-- Auxiliary inequality used to prove versions with simpler conditions on `f` and `g`
open ENNReal in
omit [LocallyCompactSpace G] [SecondCountableTopology G] in
private theorem enorm_convolution_le_eLpNorm_mul_eLpNorm_mul_eLpNorm_aux
    [μ.IsNegInvariant] {p q r : ℝ}
    (hp : 1 ≤ p) (hq : 1 ≤ q) (hr : 1 ≤ r) (hpqr : p⁻¹ + q⁻¹ = r⁻¹ + 1) {f : G → E} {g : G → E'}
    (hf : AEMeasurable (‖f ·‖ₑ) μ) (hg : ∀ x : G, AEMeasurable (‖g <| x - ·‖ₑ) μ)
    (c : ℝ) (hL : ∀ (x y : G), ‖L (f x) (g y)‖ ≤ c * ‖f x‖ * ‖g y‖) (x : G) :
    ‖(f ⋆[L, μ] g) x‖ₑ ≤
      .ofReal c * eLpNorm (fun y ↦ (‖f y‖ₑ ^ p * ‖g (x - y)‖ₑ ^ q) ^ (1 / r)) (.ofReal r) μ *
      ((eLpNorm f (.ofReal p) μ) ^ ((r - p) / r) *
      (eLpNorm g (.ofReal q) μ) ^ ((r - q) / r)) := by
  sorry

open ENNReal in
/-- This inequality is used in the proof of Young's convolution inequality
`eLpNorm_convolution_le_ofReal`. See `enorm_convolution_le_eLpNorm_mul_eLpNorm_mul_eLpNorm'` for
a version assuming a.e. strong measurability instead. -/
theorem enorm_convolution_le_eLpNorm_mul_eLpNorm_mul_eLpNorm [MeasurableSpace E]
    [OpensMeasurableSpace E] [MeasurableSpace E'] [OpensMeasurableSpace E']
    [μ.IsNegInvariant] {p q r : ℝ}
    (hp : 1 ≤ p) (hq : 1 ≤ q) (hr : 1 ≤ r) (hpqr : p⁻¹ + q⁻¹ = r⁻¹ + 1)
    {f : G → E} {g : G → E'} (hf : AEMeasurable f μ) (hg : AEMeasurable g μ)
    (c : ℝ) (hL : ∀ (x y : G), ‖L (f x) (g y)‖ ≤ c * ‖f x‖ * ‖g y‖) (x : G) :
    ‖(f ⋆[L, μ] g) x‖ₑ ≤
      .ofReal c * eLpNorm (fun y ↦ (‖f y‖ₑ ^ p * ‖g (x - y)‖ₑ ^ q) ^ (1 / r)) (.ofReal r) μ *
      ((eLpNorm f (.ofReal p) μ) ^ ((r - p) / r) *
      (eLpNorm g (.ofReal q) μ) ^ ((r - q) / r)) := by
  sorry

open ENNReal in
/-- This inequality is used in the proof of Young's convolution inequality
`eLpNorm_convolution_le_ofReal'`. -/
theorem enorm_convolution_le_eLpNorm_mul_eLpNorm_mul_eLpNorm'
    [μ.IsNegInvariant] {p q r : ℝ}
    (hp : 1 ≤ p) (hq : 1 ≤ q) (hr : 1 ≤ r) (hpqr : p⁻¹ + q⁻¹ = r⁻¹ + 1)
    {f : G → E} {g : G → E'} (hf : AEStronglyMeasurable f μ) (hg : AEStronglyMeasurable g μ)
    (c : ℝ) (hL : ∀ (x y : G), ‖L (f x) (g y)‖ ≤ c * ‖f x‖ * ‖g y‖) (x : G) :
    ‖(f ⋆[L, μ] g) x‖ₑ ≤
      .ofReal c * eLpNorm (fun y ↦ (‖f y‖ₑ ^ p * ‖g (x - y)‖ₑ ^ q) ^ (1 / r)) (.ofReal r) μ *
      ((eLpNorm f (.ofReal p) μ) ^ ((r - p) / r) *
      (eLpNorm g (.ofReal q) μ) ^ ((r - q) / r)) := by
  sorry

-- Auxiliary inequality used to prove versions with simpler conditions on `f` and `g`
private theorem eLpNorm_convolution_le_ofReal_aux
    [μ.IsAddRightInvariant] {p q r : ℝ}
    (hp : 1 ≤ p) (hq : 1 ≤ q) (hr : 1 ≤ r) (hpqr : p⁻¹ + q⁻¹ = r⁻¹ + 1) {f : G → E} {g : G → E'}
    (hf : AEMeasurable (‖f ·‖ₑ) μ) (hg : ∀ x : G, AEMeasurable (‖g <| x - ·‖ₑ) μ)
    (hg' : AEMeasurable (fun (x : G × G) ↦ ‖(g ∘ fun p ↦ p.1 - p.2) x‖ₑ ^ q) (μ.prod μ))
    (c : ℝ) (hL : ∀ (x y : G), ‖L (f x) (g y)‖ ≤ c * ‖f x‖ * ‖g y‖) :
    eLpNorm (f ⋆[L, μ] g) (.ofReal r) μ ≤
    .ofReal c * eLpNorm f (.ofReal p) μ * eLpNorm g (.ofReal q) μ := by
  sorry

theorem eLpNorm_convolution_le_ofReal [MeasurableSpace E] [OpensMeasurableSpace E]
    [MeasurableSpace E'] [OpensMeasurableSpace E']
    [μ.IsAddRightInvariant] {p q r : ℝ}
    (hp : 1 ≤ p) (hq : 1 ≤ q) (hr : 1 ≤ r) (hpqr : p⁻¹ + q⁻¹ = r⁻¹ + 1)
    {f : G → E} {g : G → E'} (hf : AEMeasurable f μ) (hg : AEMeasurable g μ)
    (c : ℝ) (hL : ∀ (x y : G), ‖L (f x) (g y)‖ ≤ c * ‖f x‖ * ‖g y‖) :
    eLpNorm (f ⋆[L, μ] g) (.ofReal r) μ ≤
    .ofReal c * eLpNorm f (.ofReal p) μ * eLpNorm g (.ofReal q) μ := by
  sorry

theorem eLpNorm_convolution_le_ofReal'
    [μ.IsAddRightInvariant] {p q r : ℝ}
    (hp : 1 ≤ p) (hq : 1 ≤ q) (hr : 1 ≤ r) (hpqr : p⁻¹ + q⁻¹ = r⁻¹ + 1)
    {f : G → E} {g : G → E'} (hf : AEStronglyMeasurable f μ) (hg : AEStronglyMeasurable g μ)
    (c : ℝ) (hL : ∀ (x y : G), ‖L (f x) (g y)‖ ≤ c * ‖f x‖ * ‖g y‖) :
    eLpNorm (f ⋆[L, μ] g) (.ofReal r) μ ≤
    .ofReal c * eLpNorm f (.ofReal p) μ * eLpNorm g (.ofReal q) μ := by
  sorry

-- Auxiliary result to prove the following versions with simpler assumptions on `f` and `g`
private theorem eLpNorm_convolution_le_of_norm_le_mul_aux
    [μ.IsAddRightInvariant] {p q r : ℝ≥0∞}
    (hp : 1 ≤ p) (hq : 1 ≤ q) (hr : 1 ≤ r) (hpqr : p⁻¹ + q⁻¹ = r⁻¹ + 1)
    {f : G → E} {g : G → E'} (hf : AEMeasurable (‖f ·‖ₑ) μ)
    (hg : ∀ (x : G), AEMeasurable (‖g <| x - ·‖ₑ) μ)
    (hg' : ∀ (x : G), eLpNorm (‖g <| x - ·‖ₑ) q μ = eLpNorm (‖g ·‖ₑ) q μ)
    (hg'' : AEMeasurable (fun x ↦ ‖(g ∘ fun p ↦ p.1 - p.2) x‖ₑ ^ q.toReal) (μ.prod μ))
    (c : ℝ) (hL : ∀ (x y : G), ‖L (f x) (g y)‖ ≤ c * ‖f x‖ * ‖g y‖) :
    eLpNorm (f ⋆[L, μ] g) r μ ≤ .ofReal c * eLpNorm f p μ * eLpNorm g q μ := by
  sorry

variable (L)

/-- **Young's convolution inequality**: the `L^r` seminorm of a convolution `(f ⋆[L, μ] g)` is
bounded by `‖L‖ₑ` times the product of the `L^p` and `L^q` seminorms, where
`1 / p + 1 / q = 1 / r + 1`. Here `‖L‖ₑ` is replaced with a bound for `L` restricted to the ranges
of `f` and `g`; see `eLpNorm_convolution_le_enorm_mul` for a version using `‖L‖ₑ` explicitly. -/
theorem eLpNorm_convolution_le_of_norm_le_mul [MeasurableSpace E] [OpensMeasurableSpace E]
    [MeasurableSpace E'] [OpensMeasurableSpace E']
    [μ.IsAddRightInvariant] {p q r : ℝ≥0∞}
    (hp : 1 ≤ p) (hq : 1 ≤ q) (hr : 1 ≤ r) (hpqr : p⁻¹ + q⁻¹ = r⁻¹ + 1)
    {f : G → E} {g : G → E'} (hf : AEMeasurable f μ) (hg : AEMeasurable g μ)
    (c : ℝ) (hL : ∀ (x y : G), ‖L (f x) (g y)‖ ≤ c * ‖f x‖ * ‖g y‖) :
    eLpNorm (f ⋆[L, μ] g) r μ ≤ .ofReal c * eLpNorm f p μ * eLpNorm g q μ := by
  sorry

/-- **Young's convolution inequality**: the `L^r` seminorm of a convolution `(f ⋆[L, μ] g)` is
bounded by `‖L‖ₑ` times the product of the `L^p` and `L^q` seminorms, where
`1 / p + 1 / q = 1 / r + 1`. Here `‖L‖ₑ` is replaced with a bound for `L` restricted to the ranges
of `f` and `g`; see `eLpNorm_convolution_le_enorm_mul` for a version using `‖L‖ₑ` explicitly. -/
theorem eLpNorm_convolution_le_of_norm_le_mul'
    [μ.IsAddRightInvariant] {p q r : ℝ≥0∞}
    (hp : 1 ≤ p) (hq : 1 ≤ q) (hr : 1 ≤ r) (hpqr : p⁻¹ + q⁻¹ = r⁻¹ + 1)
    {f : G → E} {g : G → E'} (hf : AEStronglyMeasurable f μ) (hg : AEStronglyMeasurable g μ)
    (c : ℝ) (hL : ∀ (x y : G), ‖L (f x) (g y)‖ ≤ c * ‖f x‖ * ‖g y‖) :
    eLpNorm (f ⋆[L, μ] g) r μ ≤ .ofReal c * eLpNorm f p μ * eLpNorm g q μ := by
  sorry

/-- **Young's convolution inequality**: the `L^r` seminorm of a convolution `(f ⋆[L, μ] g)` is
bounded by `‖L‖ₑ` times the product of the `L^p` and `L^q` seminorms, where
`1 / p + 1 / q = 1 / r + 1`. -/
theorem eLpNorm_convolution_le_enorm_mul [MeasurableSpace E] [OpensMeasurableSpace E]
    [MeasurableSpace E'] [OpensMeasurableSpace E']
    [μ.IsAddRightInvariant] {p q r : ℝ≥0∞}
    (hp : 1 ≤ p) (hq : 1 ≤ q) (hr : 1 ≤ r) (hpqr : p⁻¹ + q⁻¹ = r⁻¹ + 1)
    {f : G → E} {g : G → E'} (hf : AEMeasurable f μ) (hg : AEMeasurable g μ) :
    eLpNorm (f ⋆[L, μ] g) r μ ≤ ‖L‖ₑ * eLpNorm f p μ * eLpNorm g q μ := by
  sorry

/-- **Young's convolution inequality**: the `L^r` seminorm of a convolution `(f ⋆[L, μ] g)` is
bounded by `‖L‖ₑ` times the product of the `L^p` and `L^q` seminorms, where
`1 / p + 1 / q = 1 / r + 1`. -/
theorem eLpNorm_convolution_le_enorm_mul' [μ.IsAddRightInvariant] {p q r : ℝ≥0∞}
    (hp : 1 ≤ p) (hq : 1 ≤ q) (hr : 1 ≤ r) (hpqr : p⁻¹ + q⁻¹ = r⁻¹ + 1)
    {f : G → E} {g : G → E'} (hf : AEStronglyMeasurable f μ) (hg : AEStronglyMeasurable g μ) :
    eLpNorm (f ⋆[L, μ] g) r μ ≤ ‖L‖ₑ * eLpNorm f p μ * eLpNorm g q μ := by
  sorry

open Set AddCircle in
lemma eLpNorm_Ioc_convolution_le_of_norm_le_mul_aux (a : ℝ) {T : ℝ} [hT : Fact (0 < T)]
    {p q r : ℝ≥0∞} (hp : 1 ≤ p) (hq : 1 ≤ q) (hr : 1 ≤ r) (hpqr : p⁻¹ + q⁻¹ = r⁻¹ + 1)
    {f : ℝ → E} {g : ℝ → E'} (hfT : f.Periodic T) (hgT : g.Periodic T)
    (hf : AEStronglyMeasurable f) (hg : AEStronglyMeasurable g)
    (c : ℝ) (hL : ∀ (x y : ℝ), ‖L (f x) (g y)‖ ≤ c * ‖f x‖ * ‖g y‖) :
    eLpNorm (fun x ↦ ∫ y in a..a+T, L (f y) (g (x - y))) r (volume.restrict (Ioc a (a + T))) ≤
    .ofReal c * eLpNorm f p (volume.restrict (Ioc a (a + T))) *
      eLpNorm g q (volume.restrict (Ioc a (a + T))) := by
  sorry

open Set AddCircle in
/-- **Young's convolution inequality** on (a, a + T]: the `L^r` seminorm of the convolution
of `T`-periodic functions over (a, a + T] is bounded by `‖L‖ₑ` times the product of
the `L^p` and `L^q` seminorms on that interval, where `1 / p + 1 / q = 1 / r + 1`. Here `‖L‖ₑ`
is replaced with a bound for `L` restricted to the ranges of `f` and `g`; see
`eLpNorm_Ioc_convolution_le_enorm_mul` for a version using `‖L‖ₑ` explicitly. -/
theorem eLpNorm_Ioc_convolution_le_of_norm_le_mul (a : ℝ) {T : ℝ} [hT : Fact (0 < T)]
    {p q r : ℝ≥0∞} (hp : 1 ≤ p) (hq : 1 ≤ q) (hr : 1 ≤ r) (hpqr : p⁻¹ + q⁻¹ = r⁻¹ + 1)
    {f : ℝ → E} {g : ℝ → E'} (hgT : g.Periodic T)
    (hf : AEStronglyMeasurable f) (hg : AEStronglyMeasurable g)
    (c : ℝ) (hL : ∀ (x y : ℝ), ‖L (f x) (g y)‖ ≤ c * ‖f x‖ * ‖g y‖) :
    eLpNorm (fun x ↦ ∫ y in a..a+T, L (f y) (g (x - y))) r (volume.restrict (Ioc a (a + T))) ≤
    .ofReal c * eLpNorm f p (volume.restrict (Ioc a (a + T))) *
      eLpNorm g q (volume.restrict (Ioc a (a + T))) := by
  sorry

open Set in
/-- **Young's convolution inequality** on (a, a + T]: the `L^r` seminorm of the convolution
of `T`-periodic functions over (a, a + T] is bounded by `‖L‖ₑ` times the product of
the `L^p` and `L^q` seminorms on that interval, where `1 / p + 1 / q = 1 / r + 1`. -/
theorem eLpNorm_Ioc_convolution_le_enorm_mul (a : ℝ) {T : ℝ} [hT : Fact (0 < T)]
    {p q r : ℝ≥0∞} (hp : 1 ≤ p) (hq : 1 ≤ q) (hr : 1 ≤ r) (hpqr : p⁻¹ + q⁻¹ = r⁻¹ + 1)
    {f : ℝ → E} {g : ℝ → E'} (hgT : g.Periodic T)
    (hf : AEStronglyMeasurable f) (hg : AEStronglyMeasurable g) :
    eLpNorm (fun x ↦ ∫ y in a..a+T, L (f y) (g (x - y))) r (volume.restrict (Ioc a (a + T))) ≤
    ‖L‖ₑ * eLpNorm f p (volume.restrict (Ioc a (a + T)))
      * eLpNorm g q (volume.restrict (Ioc a (a + T))) := by
  sorry

end ENNReal

end Convolution
