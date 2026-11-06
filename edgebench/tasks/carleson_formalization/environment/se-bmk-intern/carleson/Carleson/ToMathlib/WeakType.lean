module

public import Carleson.ToMathlib.MeasureTheory.Function.LpSeminorm.Basic
public import Carleson.ToMathlib.Rearrangement

@[expose] public section

-- Upstreaming status: all of this should go into mathlib, eventually.
-- Most lemmas have the right form, but proofs can often be golfed.
-- Some enorm lemmas require some mathlib refactoring first, so they can be unified with their
-- analogue in current mathlib. Such refactorings include (1) adding a Weak(Pseudo)EMetricSpace
-- class, (2) generalising all lemmas about enorms and • to this setting.

noncomputable section

open NNReal ENNReal NormedSpace MeasureTheory Set Filter Topology Function

namespace MeasureTheory

variable {α α' ε ε₁ ε₂ ε₃ 𝕜 E E₁ E₂ E₃ : Type*} {m : MeasurableSpace α} {m : MeasurableSpace α'}
  {p p' q : ℝ≥0∞} {c : ℝ≥0∞}
  {μ : Measure α} {ν : Measure α'} [NontriviallyNormedField 𝕜]
  {t s x y : ℝ≥0∞} {T : (α → ε₁) → (α' → ε₂)}

section ENorm

variable [ENorm ε] {f g g₁ g₂ : α → ε}

/- Proofs for this file can be found in
Folland, Real Analysis. Modern Techniques and Their Applications, section 6.3. -/

/-- The weak L^p norm of a function, for `p < ∞` -/
def wnorm' (f : α → ε) (p : ℝ) (μ : Measure α) : ℝ≥0∞ :=
  ⨆ t : ℝ≥0, t * distribution f t μ ^ (p : ℝ)⁻¹

lemma wnorm'_zero (f : α → ε) (μ : Measure α) : wnorm' f 0 μ = ∞ := by
  sorry

lemma wnorm'_toReal_le {f : α → ℝ≥0∞} {p : ℝ} (hp : 0 ≤ p) :
    wnorm' (ENNReal.toReal ∘ f) p μ ≤ wnorm' f p μ := by
  sorry

lemma wnorm'_toReal_eq {f : α → ℝ≥0∞} {p : ℝ} (hf : ∀ᵐ x ∂μ, f x ≠ ∞) :
    wnorm' (ENNReal.toReal ∘ f) p μ = wnorm' f p μ := by
  sorry

theorem wnorm'_eq_iSup_rpow_mul_rearrangement {p : ℝ} (hp : 0 < p) {f : α → ε} {μ : Measure α} :
    wnorm' f p μ = ⨆ t : ℝ≥0, t ^ p⁻¹ * rearrangement f t μ := by
  sorry

/-- The weak L^p norm of a function. -/
def wnorm (f : α → ε) (p : ℝ≥0∞) (μ : Measure α) : ℝ≥0∞ :=
  if p = ∞ then eLpNormEssSup f μ else wnorm' f (p.toReal) μ

@[simp]
lemma wnorm_zero : wnorm f 0 μ = ∞ := by
  sorry

@[simp]
lemma wnorm_top : wnorm f ⊤ μ = eLpNormEssSup f μ := by
  sorry

lemma wnorm_ne_top (h : p ≠ ⊤) : wnorm f p μ = wnorm' f p.toReal μ := by
  sorry

lemma wnorm_coe {p : ℝ≥0} : wnorm f p μ = wnorm' f p μ := by
  sorry

lemma wnorm_ofReal {p : ℝ} (hp : 0 ≤ p) : wnorm f (.ofReal p) μ = wnorm' f p μ := by
  sorry

lemma wnorm_toReal_le {f : α → ℝ≥0∞} {p : ℝ≥0∞} :
    wnorm (ENNReal.toReal ∘ f) p μ ≤ wnorm f p μ := by
  sorry

lemma wnorm_toReal_eq {f : α → ℝ≥0∞} {p : ℝ≥0∞} (hf : ∀ᵐ x ∂μ, f x ≠ ∞) :
    wnorm (ENNReal.toReal ∘ f) p μ = wnorm f p μ := by
  sorry

theorem wnorm_eq_iSup_rpow_mul_rearrangement {p : ℝ≥0∞} (p_nonzero : p ≠ 0) (p_ne_top : p ≠ ⊤)
  {f : α → ε} {μ : Measure α} :
    wnorm f p μ = ⨆ t : ℝ≥0, t ^ p.toReal⁻¹ * rearrangement f t μ := by
  sorry

lemma wnorm'_mono_enorm_ae {ε' : Type*} [ENorm ε'] {f : α → ε} {g : α → ε'} {p : ℝ} (hp : 0 ≤ p)
  (h : ∀ᵐ (x : α) ∂μ, ‖f x‖ₑ ≤ ‖g x‖ₑ) :
    wnorm' f p μ ≤ wnorm' g p μ := by
  sorry

lemma wnorm_mono_enorm_ae {ε' : Type*} [ENorm ε'] {f : α → ε} {g : α → ε'}
  (h : ∀ᵐ (x : α) ∂μ, ‖f x‖ₑ ≤ ‖g x‖ₑ) :
    wnorm f p μ ≤ wnorm g p μ := by
  sorry

theorem wnorm_indicator_const {ε} [TopologicalSpace ε] [ESeminormedAddMonoid ε]
  {a : ε} {s : Set α} {p : ℝ≥0∞}
  (h₀ : ¬p = 0) (h₁ : ¬p = ⊤) :
    wnorm (s.indicator (Function.const α a)) p μ = μ s ^ p.toReal⁻¹ * ‖a‖ₑ := by
  sorry

lemma wnorm_iSup_of_monotone {α : Type*} [MeasurableSpace α] {p : ℝ≥0∞} (hp : p ≠ 0) (f : ℕ → α → ℝ≥0∞)
    (hf : Monotone f) (μ : Measure α) : wnorm (fun x => ⨆ n, f n x) p μ = ⨆ n, wnorm (f n) p μ := by
  sorry

/-- A function is in weak-L^p if it is (strongly a.e.)-measurable and has finite weak L^p norm. -/
def MemWLp [TopologicalSpace ε] (f : α → ε) (p : ℝ≥0∞) (μ : Measure α) : Prop :=
  AEStronglyMeasurable f μ ∧ wnorm f p μ < ∞

lemma MemWLp_zero [TopologicalSpace ε] : ¬ MemWLp f 0 μ := by
  sorry

lemma MemWLp.aeStronglyMeasurable [TopologicalSpace ε] (hf : MemWLp f p μ) : AEStronglyMeasurable f μ := by
  sorry

lemma MemWLp.wnorm_lt_top [TopologicalSpace ε] (hf : MemWLp f p μ) : wnorm f p μ < ⊤ := by
  sorry

lemma MemWLp.ennreal_toReal {f : α → ℝ≥0∞} (hf : MemWLp f p μ) :
    MemWLp (ENNReal.toReal ∘ f) p μ := by
  sorry

/-- If a function `f` is `MemWLp`, then its norm is almost everywhere finite. -/
-- XXX: is this a good finiteness rule, given that `p` might be hard to infer?
@[aesop (rule_sets := [finiteness]) unsafe apply]
theorem MemWLp.ae_ne_top [TopologicalSpace ε] (hf : MemWLp f p μ) : ∀ᵐ x ∂μ, ‖f x‖ₑ ≠ ∞ := by
  sorry

end ENorm

section ContinuousENorm

variable [TopologicalSpace ε] [ContinuousENorm ε] {f : α → ε}

lemma distribution_le [MeasurableSpace ε] [OpensMeasurableSpace ε]
    {c : ℝ≥0∞} (hc : c ≠ 0) {μ : Measure α} (hf : AEMeasurable f μ) :
    distribution f c μ ≤ c⁻¹ * (∫⁻ y, ‖f y‖ₑ ∂μ) := by
  sorry

lemma wnorm'_le_eLpNorm' (hf : AEStronglyMeasurable f μ) {p : ℝ} (p0 : 0 < p) :
    wnorm' f p μ ≤ eLpNorm' f p μ := by
  sorry

lemma distribution_lt_top (hf : MemLp f p μ) (p_pos : 0 < p) (p_ne_top : p ≠ ∞)
    {t : ℝ≥0} (ht : 0 < t) :
    distribution f t μ < ∞ := by
  sorry

lemma wnorm_le_eLpNorm (hf : AEStronglyMeasurable f μ) {p : ℝ≥0∞} (hp : 0 < p) :
    wnorm f p μ ≤ eLpNorm f p μ := by
  sorry

lemma MemLp.memWLp (hp : 0 < p) (hf : MemLp f p μ) : MemWLp f p μ := by
  sorry

end ContinuousENorm

section Defs

variable [ENorm ε₁] [ENorm ε₂] [TopologicalSpace ε₁] [TopologicalSpace ε₂]
/- Todo: define `MeasureTheory.WLp` as a subgroup, similar to `MeasureTheory.Lp` -/

/-- An operator has weak type `(p, q)` if it is bounded as a map from `L^p` to weak `L^q`.
`HasWeakType T p p' μ ν c` means that `T` has weak type `(p, p')` w.r.t. measures `μ`, `ν`
and constant `c`. -/
def HasWeakType (T : (α → ε₁) → (α' → ε₂)) (p p' : ℝ≥0∞) (μ : Measure α) (ν : Measure α')
    (c : ℝ≥0∞) : Prop :=
  ∀ f : α → ε₁, MemLp f p μ → AEStronglyMeasurable (T f) ν ∧ wnorm (T f) p' ν ≤ c * eLpNorm f p μ

/-- A weaker version of `HasWeakType`. -/
def HasBoundedWeakType {α α' : Type*} [Zero ε₁]
    {_x : MeasurableSpace α} {_x' : MeasurableSpace α'} (T : (α → ε₁) → (α' → ε₂))
    (p p' : ℝ≥0∞) (μ : Measure α) (ν : Measure α') (c : ℝ≥0∞) : Prop :=
  ∀ f : α → ε₁, BoundedFiniteSupport f μ →
  AEStronglyMeasurable (T f) ν ∧ wnorm (T f) p' ν ≤ c * eLpNorm f p μ

/-- An operator has strong type `(p, q)` if it is bounded as an operator on `L^p → L^q`.
`HasStrongType T p p' μ ν c` means that `T` has strong type (p, p') w.r.t. measures `μ`, `ν`
and constant `c`. -/
def HasStrongType {α α' : Type*}
    {_x : MeasurableSpace α} {_x' : MeasurableSpace α'} (T : (α → ε₁) → (α' → ε₂))
    (p p' : ℝ≥0∞) (μ : Measure α) (ν : Measure α') (c : ℝ≥0∞) : Prop :=
  ∀ f : α → ε₁, MemLp f p μ → AEStronglyMeasurable (T f) ν ∧ eLpNorm (T f) p' ν ≤ c * eLpNorm f p μ

/-- A weaker version of `HasStrongType`. This is the same as `HasStrongType` if `T` is continuous
w.r.t. the L^2 norm, but weaker in general. -/
def HasBoundedStrongType {α α' : Type*} [Zero ε₁]
    {_x : MeasurableSpace α} {_x' : MeasurableSpace α'} (T : (α → ε₁) → (α' → ε₂))
    (p p' : ℝ≥0∞) (μ : Measure α) (ν : Measure α') (c : ℝ≥0∞) : Prop :=
  ∀ f : α → ε₁, BoundedFiniteSupport f μ →
  AEStronglyMeasurable (T f) ν ∧ eLpNorm (T f) p' ν ≤ c * eLpNorm f p μ

end Defs

/-! ### Lemmas about `HasWeakType` -/

section HasWeakType

variable [TopologicalSpace ε₁] [ContinuousENorm ε₁] [TopologicalSpace ε₂] [ContinuousENorm ε₂]
    {f₁ : α → ε₁}

lemma HasWeakType.memWLp (h : HasWeakType T p p' μ ν c) (hf₁ : MemLp f₁ p μ)
    (hc : c < ⊤ := by finiteness) : MemWLp (T f₁) p' ν :=
  ⟨(h f₁ hf₁).1, h f₁ hf₁ |>.2.trans_lt <| mul_lt_top hc hf₁.2⟩

lemma HasWeakType.toReal {T : (α → ε₁) → (α' → ℝ≥0∞)} (h : HasWeakType T p p' μ ν c) :
    HasWeakType (T · · |>.toReal) p p' μ ν c := by
  sorry

-- unused, probably delete
open Classical in
lemma toReal_ofReal_preimage' {s : Set ℝ≥0∞} : ENNReal.toReal ⁻¹' (ENNReal.ofReal ⁻¹' s) =
    if ∞ ∈ s ↔ 0 ∈ s then s else if 0 ∈ s then s ∪ {∞} else s \ {∞} := by
  sorry

-- move
open Classical in
lemma toReal_ofReal_preimage {s : Set ℝ≥0∞} : letI t := ENNReal.toReal ⁻¹' (ENNReal.ofReal ⁻¹' s)
  s = if ∞ ∈ s ↔ 0 ∈ s then t else if 0 ∈ s then t \ {∞} else t ∪ {∞} := by
  sorry

-- move
lemma aestronglyMeasurable_ennreal_toReal_iff {f : α → ℝ≥0∞}
    (hf : NullMeasurableSet (f ⁻¹' {∞}) μ) :
    AEStronglyMeasurable (ENNReal.toReal ∘ f) μ ↔ AEStronglyMeasurable f μ := by
  sorry

lemma hasWeakType_toReal_iff {T : (α → ε₁) → (α' → ℝ≥0∞)}
    (hT : ∀ f, MemLp f p μ → ∀ᵐ x ∂ν, T f x ≠ ⊤) :
    HasWeakType (T · · |>.toReal) p p' μ ν c ↔ HasWeakType T p p' μ ν c := by
  sorry

lemma hasWeakType_iSup_of_monotone {f : ℕ → (α → ε₁) → (α' → ℝ≥0∞)} (hf : Monotone f)
    (hp' : p' ≠ 0) (hwtf : ∀ n, HasWeakType (f n) p p' μ ν c) :
    HasWeakType (fun u x => ⨆ n, f n u x) p p' μ ν c := by
  sorry

-- lemma comp_left [MeasurableSpace ε₂] {ν' : Measure ε₂} {f : ε₂ → ε₃} (h : HasWeakType T p p' μ ν c)
--     (hf : MemLp f p' ν') :
--     HasWeakType (f ∘ T ·) p p' μ ν c := by
--   intro u hu
--   refine ⟨h u hu |>.1.comp_measurable hf.1, ?_⟩

end HasWeakType

/-! ### Lemmas about `HasBoundedWeakType` -/

section HasBoundedWeakType

variable [TopologicalSpace ε₁] [ESeminormedAddMonoid ε₁] [TopologicalSpace ε₂] [ENorm ε₂]
    {f₁ : α → ε₁}

lemma HasBoundedWeakType.memWLp (h : HasBoundedWeakType T p p' μ ν c)
    (hf₁ : BoundedFiniteSupport f₁ μ) (hc : c < ⊤ := by finiteness) :
    MemWLp (T f₁) p' ν :=
  ⟨(h f₁ hf₁).1, h f₁ hf₁ |>.2.trans_lt <| mul_lt_top hc (hf₁.memLp p).2⟩

lemma HasWeakType.hasBoundedWeakType (h : HasWeakType T p p' μ ν c) :
    HasBoundedWeakType T p p' μ ν c := by
  sorry

end HasBoundedWeakType

/-! ### Lemmas about `HasStrongType` -/

section HasStrongType

variable [TopologicalSpace ε₁] [ContinuousENorm ε₁] [TopologicalSpace ε₂] [ContinuousENorm ε₂]
    {f₁ : α → ε₁}

lemma HasStrongType.memLp (h : HasStrongType T p p' μ ν c) (hf₁ : MemLp f₁ p μ)
    (hc : c < ⊤ := by finiteness) : MemLp (T f₁) p' ν :=
  ⟨(h f₁ hf₁).1, h f₁ hf₁ |>.2.trans_lt <| mul_lt_top hc hf₁.2⟩

lemma HasStrongType.hasWeakType (hp' : 0 < p')
    (h : HasStrongType T p p' μ ν c) : HasWeakType T p p' μ ν c := by
  sorry

lemma HasStrongType.toReal {T : (α → ε₁) → (α' → ℝ≥0∞)} (h : HasStrongType T p p' μ ν c) :
    HasStrongType (T · · |>.toReal) p p' μ ν c := by
  sorry

lemma hasStrongType_toReal_iff {T : (α → ε₁) → (α' → ℝ≥0∞)}
    (hT : ∀ f, MemLp f p μ → ∀ᵐ x ∂ν, T f x ≠ ⊤) :
    HasStrongType (T · · |>.toReal) p p' μ ν c ↔ HasStrongType T p p' μ ν c := by
  sorry

lemma hasStrongType_iSup_of_monotone {f : ℕ → (α → ε₁) → (α' → ℝ≥0∞)} (hf : Monotone f)
    (hstf : ∀ n, HasStrongType (f n) p p' μ ν c) :
    HasStrongType (fun u x => ⨆ n, f n u x) p p' μ ν c := by
  sorry

end HasStrongType

/-! ### Lemmas about `HasBoundedStrongType` -/

section HasBoundedStrongType

variable [TopologicalSpace ε₁] [ESeminormedAddMonoid ε₁] [TopologicalSpace ε₂] [ContinuousENorm ε₂]
    {f₁ : α → ε₁}

lemma HasBoundedStrongType.memLp (h : HasBoundedStrongType T p p' μ ν c)
    (hf₁ : BoundedFiniteSupport f₁ μ) (hc : c < ⊤ := by finiteness) :
    MemLp (T f₁) p' ν :=
  ⟨(h f₁ hf₁).1, h f₁ hf₁ |>.2.trans_lt <| mul_lt_top hc (hf₁.memLp _).2⟩

lemma HasStrongType.hasBoundedStrongType (h : HasStrongType T p p' μ ν c) :
    HasBoundedStrongType T p p' μ ν c := by
  sorry

lemma HasBoundedStrongType.hasBoundedWeakType (hp' : 0 < p')
    (h : HasBoundedStrongType T p p' μ ν c) :
    HasBoundedWeakType T p p' μ ν c := by
  sorry

set_option backward.isDefEq.respectTransparency false in
lemma HasBoundedStrongType.const_smul {T : (α → ε₁) → α' → ℝ≥0∞}
    (h : HasBoundedStrongType T p p' μ ν c) (r : ℝ≥0) :
    HasBoundedStrongType (r • T) p p' μ ν (r • c) := by
  sorry

end HasBoundedStrongType

variable {f g : α → ε}

section

variable {ε ε' : Type*} [TopologicalSpace ε] [ENorm ε]
variable [TopologicalSpace ε'] [ENormedSpace ε']

-- TODO: this lemma and its primed version could be unified using a `NormedSemifield` typeclass
-- (which includes NNReal and normed fields like ℝ and ℂ), i.e. assuming 𝕜 is a normed semifield.
-- Investigate if this is worthwhile when upstreaming this to mathlib.
lemma distribution_smul_left {f : α → ε'} {c : ℝ≥0} (hc : c ≠ 0) :
    distribution (c • f) t μ = distribution f (t / ‖c‖ₑ) μ := by
  sorry

variable [NormedAddCommGroup E] [MulActionWithZero 𝕜 E] [NormSMulClass 𝕜 E]
  {E' : Type*} [NormedAddCommGroup E'] [MulActionWithZero 𝕜 E'] [NormSMulClass 𝕜 E']

lemma distribution_smul_left' {f : α → E} {c : 𝕜} (hc : c ≠ 0) :
    distribution (c • f) t μ = distribution f (t / ‖c‖ₑ) μ := by
  sorry

lemma HasStrongType.const_smul [ContinuousConstSMul ℝ≥0 ε']
    {T : (α → ε) → (α' → ε')} {c : ℝ≥0∞} (h : HasStrongType T p p' μ ν c) (k : ℝ≥0) :
    HasStrongType (k • T) p p' μ ν (‖k‖ₑ * c) := by
  sorry

-- TODO: do we want to unify this lemma with its unprimed version, perhaps using an
-- `ENormedSemiring` class?
variable {𝕜 E' : Type*} [NormedRing 𝕜] [NormedAddCommGroup E'] [MulActionWithZero 𝕜 E'] [IsBoundedSMul 𝕜 E'] in
lemma HasStrongType.const_smul'
    {T : (α → ε) → (α' → E')} {c : ℝ≥0∞} (h : HasStrongType T p p' μ ν c) (k : 𝕜) :
    HasStrongType (k • T) p p' μ ν (‖k‖ₑ * c) := by
  sorry

lemma HasStrongType.const_mul
    {T : (α → ε) → (α' → ℝ≥0∞)} {c : ℝ≥0∞} (h : HasStrongType T p p' μ ν c) (e : ℝ≥0) :
    HasStrongType (fun f x ↦ e * T f x) p p' μ ν (‖e‖ₑ * c) := by
  sorry

-- TODO: do we want to unify this lemma with its unprimed version, perhaps using an
-- `ENormedSemiring` class?
variable {E' : Type*} [NormedRing E'] in
lemma HasStrongType.const_mul'
    {T : (α → ε) → (α' → E')} {c : ℝ≥0∞} (h : HasStrongType T p p' μ ν c) (e : E') :
    HasStrongType (fun f x ↦ e * T f x) p p' μ ν (‖e‖ₑ * c) := by
  sorry

lemma wnorm_const_smul_le (hp : p ≠ 0) {f : α → ε'} (k : ℝ≥0) :
    wnorm (k • f) p μ ≤ ‖k‖ₑ * wnorm f p μ := by
  sorry

lemma wnorm_const_smul_le' [IsBoundedSMul 𝕜 E] (hp : p ≠ 0) {f : α → E} (k : 𝕜) :
    wnorm (k • f) p μ ≤ ‖k‖ₑ * wnorm f p μ := by
  sorry

lemma HasWeakType.const_smul [ContinuousConstSMul ℝ≥0 ε']
    {T : (α → ε) → (α' → ε')} (hp' : p' ≠ 0) {c : ℝ≥0∞} (h : HasWeakType T p p' μ ν c) (k : ℝ≥0) :
    HasWeakType (k • T) p p' μ ν (k * c) := by
  sorry

-- TODO: do we want to unify this lemma with its unprimed version, perhaps using an
-- `ENormedSemiring` class?
lemma HasWeakType.const_smul' [IsBoundedSMul 𝕜 E'] {T : (α → ε) → (α' → E')} (hp' : p' ≠ 0)
    {c : ℝ≥0∞} (h : HasWeakType T p p' μ ν c) (k : 𝕜) :
    HasWeakType (k • T) p p' μ ν (‖k‖ₑ * c) := by
  sorry

lemma HasWeakType.const_mul {T : (α → ε) → (α' → ℝ≥0∞)} (hp' : p' ≠ 0)
    {c : ℝ≥0∞} (h : HasWeakType T p p' μ ν c) (e : ℝ≥0) :
    HasWeakType (fun f x ↦ e * T f x) p p' μ ν (e * c) := by
  sorry

-- TODO: do we want to unify this lemma with its unprimed version, perhaps using an
-- `ENormedSemiring` class?
lemma HasWeakType.const_mul' {T : (α → ε) → (α' → 𝕜)} (hp' : p' ≠ 0)
    {c : ℝ≥0∞} (h : HasWeakType T p p' μ ν c) (e : 𝕜) :
    HasWeakType (fun f x ↦ e * T f x) p p' μ ν (‖e‖ₑ * c) := by
  sorry

end

section NormedGroup

variable [NormedAddCommGroup E₁] [NormedSpace 𝕜 E₁] [NormedAddCommGroup E₂] [NormedSpace 𝕜 E₂]
  [NormedAddCommGroup E₃] [NormedSpace 𝕜 E₃]

lemma _root_.ContinuousLinearMap.distribution_le {f : α → E₁} {g : α → E₂} (L : E₁ →L[𝕜] E₂ →L[𝕜] E₃) :
    distribution (fun x ↦ L (f x) (g x)) (‖L‖ₑ * t * s) μ ≤
    distribution f t μ + distribution g s μ := by
  sorry

end NormedGroup

section Layercake

variable [TopologicalSpace ε] [ContinuousENorm ε]

/-- The layer-cake theorem, or Cavalieri's principle for functions into a space with a continuous
enorm. -/
lemma lintegral_norm_pow_eq_distribution {f : α → ε} (hf : AEStronglyMeasurable f μ) {p : ℝ} (hp : 0 < p) :
    ∫⁻ x, ‖f x‖ₑ ^ p ∂μ =
    ∫⁻ t in Ioi (0 : ℝ), ENNReal.ofReal (p * t ^ (p - 1)) * distribution f (.ofReal t) μ := by
  sorry

/-- The layer-cake theorem, or Cavalieri's principle, written using `eLpNorm`. -/
lemma eLpNorm_pow_eq_distribution {f : α → ε} (hf : AEStronglyMeasurable f μ) {p : ℝ≥0} (hp : 0 < p) :
    eLpNorm f p μ ^ (p : ℝ) =
    ∫⁻ t in Ioi (0 : ℝ), p * ENNReal.ofReal (t ^ ((p : ℝ) - 1)) * distribution f (.ofReal t) μ := by
  sorry

/-- The layer-cake theorem, or Cavalieri's principle, written using `eLpNorm`, without
    taking powers. -/
lemma eLpNorm_eq_distribution {f : α → ε} (hf : AEStronglyMeasurable f μ) {p : ℝ} (hp : 0 < p) :
    eLpNorm f (.ofReal p) μ =
    (ENNReal.ofReal p  * ∫⁻ t in Ioi (0 : ℝ), distribution f (.ofReal t) μ *
        ENNReal.ofReal (t ^ (p - 1)) ) ^ p⁻¹ := by
  sorry

lemma lintegral_pow_mul_distribution {f : α → ε} (hf : AEStronglyMeasurable f μ) {p : ℝ} (hp : -1 < p) :
    ∫⁻ t in Ioi (0 : ℝ), ENNReal.ofReal (t ^ p) * distribution f (.ofReal t) μ =
    ENNReal.ofReal (p + 1)⁻¹ * ∫⁻ x, ‖f x‖ₑ ^ (p + 1) ∂μ := by
  sorry

end Layercake

end MeasureTheory
