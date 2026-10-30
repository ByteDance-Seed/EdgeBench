module

public import Carleson.ToMathlib.RealInterpolation.Minkowski

/-!
# The Marcinkiewisz real interpolation theorem

This file contains a proof of the Marcinkiewisz real interpolation theorem.
The proof roughly follows Folland, Real Analysis. Modern Techniques and Their Applications,
section 6.4, theorem 6.28, but a different truncation is used, and some estimates instead
follow the technique as e.g. described in [Duoandikoetxea, Fourier Analysis, 2000].

This file has the definitions for the main proof, and the final proof of the theorem.
A few other files contain the necessary pre-requisites:
- (in `InterpolateExponents.lean`) Convenience results for working with (interpolated) exponents
- (in `InterpolateExponents.lean`) Results about the particular choice of exponent
- (in `Misc.lean`) Interface for using cutoff functions
- (in `Misc.lean`) Results about the particular choice of scale
- (in `Misc.lean`) Some tools for measure theory computations
- (in `Misc.lean`) Results about truncations of a function
- (in `Misc.lean`) Measurability properties of truncations
- (in `Misc.lean`) Truncations and Lp spaces
- (in `Misc.lean`) Some results about the integrals of truncations
- (in `Minkowski.lean`) Minkowski's integral inequality
- (in `Minkowski.lean`) Apply Minkowski's integral inequality to truncations
- (in `Minkowski.lean`) Weaktype estimates applied to truncations

Upstreaming status: the result is highly desirable; the ideal proof strategy is not yet clear.
It may be nicer to generalise this to Lorentz spaces first, and then upstream the proof there.
(Useful ingredients for this proof also belong into mathlib.)
Prioritise other files first (e.g., about weak type or the prerequisites files).

-/

@[expose] public section

noncomputable section

open NNReal ENNReal MeasureTheory Set Pointwise

variable {α α' ε E E₁ E₂ E₃ : Type*} {m : MeasurableSpace α} {m' : MeasurableSpace α'}
  {p p' q p₀ q₀ p₁ q₁ : ℝ≥0∞}
  {C₀ C₁ : ℝ≥0} {μ : Measure α} {ν : Measure α'}
  [TopologicalSpace E] [TopologicalSpace E₁] [TopologicalSpace E₂] [TopologicalSpace E₃]
  [ESeminormedAddCommMonoid E]
  [ESeminormedAddCommMonoid E₁] [ESeminormedAddCommMonoid E₂] [ESeminormedAddCommMonoid E₃]
  [MeasurableSpace E] [BorelSpace E]
  [MeasurableSpace E₃] [BorelSpace E₃]
  {f : α → E₁} {t : ℝ≥0∞}
  {T : (α → E₁) → (α' → E₂)}

/-! # The real interpolation theorem

## Definitions -/
namespace MeasureTheory

variable {ε₁ ε₂ : Type*} [TopologicalSpace ε₁] [ESeminormedAddMonoid ε₁] [TopologicalSpace ε₂] [ESeminormedAddMonoid ε₂]

/-- The operator is subadditive on functions satisfying `P` with constant `A`. -/
def SubadditiveOn [ENorm ε] (T : (α → ε₁) → α' → ε) (P : (α → ε₁) → Prop) (A : ℝ≥0∞) : Prop :=
  ∀ (f g : α → ε₁), P f → P g → ∀ (x : α'), ‖T (f + g) x‖ₑ ≤ A * (‖T f x‖ₑ + ‖T g x‖ₑ)

def Subadditive_trunc [ENorm ε] (T : (α → ε₁) → α' → ε) (A : ℝ≥0∞) (f : α → ε₁) (ν : Measure α') :
    Prop :=
  ∀ a : ℝ≥0∞, 0 < a → ∀ᵐ y ∂ν,
  ‖T (trunc f a + truncCompl f a) y‖ₑ ≤ A * (‖T (trunc f a) y‖ₑ + ‖T (truncCompl f a) y‖ₑ)

/-- The operator is subadditive on functions satisfying `P` with constant `A`
(this is almost vacuous if `A = ⊤`). -/
def AESubadditiveOn [ENorm ε] (T : (α → ε₁) → α' → ε) (P : (α → ε₁) → Prop) (A : ℝ≥0∞)
    (ν : Measure α') : Prop :=
  ∀ (f g : α → ε₁), P f → P g → ∀ᵐ x ∂ν, ‖T (f + g) x‖ₑ ≤ A * (‖T f x‖ₑ + ‖T g x‖ₑ)

namespace SubadditiveOn

variable {P : (α → ε₁) → Prop} {A : ℝ≥0∞} {T : (α → ε₁) → α' → ε}
  [TopologicalSpace ε] [ESeminormedAddMonoid ε]

lemma aeSubadditiveOn (h : SubadditiveOn T P A) {μ : Measure α'} :
    AESubadditiveOn T P A μ := by
  sorry

lemma biSup {ι : Type*} {𝓑 : Set ι} {T : ι → (α → ε₁) → α' → ℝ≥0∞}
    (h : ∀ i ∈ 𝓑, SubadditiveOn (T i) P A) : SubadditiveOn (fun u x ↦ ⨆ i ∈ 𝓑, T i u x) P A := by
  sorry

lemma indicator (sa : SubadditiveOn T P A) (s : Set α') :
    SubadditiveOn (fun u x ↦ (s.indicator (fun y ↦ T u y) x)) P A := by
  sorry

/- If `T` is constant in the second argument (but not necessarily the first) and satisfies
a subadditivity criterion, then `SubadditiveOn T P 1` -/
lemma const {T : (α → ε₁) → ℝ≥0∞} (h_add : ∀ {f g}, P f → P g → T (f + g) ≤ T f + T g) :
    SubadditiveOn (fun u (_ : α') ↦ T u) P 1 := by
  sorry

end SubadditiveOn

namespace AESubadditiveOn

variable [TopologicalSpace ε] [ESeminormedAddMonoid ε] {ν : Measure α'}
  {u : α → ε₁} {T : (α → ε₁) → α' → ε₂}

lemma antitone {T : (α → ε₁) → α' → ε} {P P' : (α → ε₁) → Prop}
    (h : ∀ {u : α → ε₁}, P u → P' u) {A : ℝ≥0∞} (sa : AESubadditiveOn T P' A ν) :
    AESubadditiveOn T P A ν := by
  sorry

lemma zero {P : (α → ε₁) → Prop} (hP : ∀ {f g : α → ε₁}, P f → P g → P (f + g))
    (A : ℝ≥0∞) (h : ∀ u, P u → T u =ᵐ[ν] 0) : AESubadditiveOn T P A ν := by
  sorry

lemma forall_le {ι : Type*} {𝓑 : Set ι} (h𝓑 : 𝓑.Countable) {T : ι → (α → ε₁) → α' → ε}
    {P : (α → ε₁) → Prop} {A : ℝ≥0∞}
    (h : ∀ i ∈ 𝓑, AESubadditiveOn (T i) P A ν)
    {f g : α → ε₁} (hf : P f) (hg : P g) :
    ∀ᵐ x ∂ν, ∀ i ∈ 𝓑, ‖T i (f + g) x‖ₑ ≤ A * (‖T i f x‖ₑ + ‖T i g x‖ₑ) := by
  sorry

lemma biSup {ι : Type*} {𝓑 : Set ι} (h𝓑 : 𝓑.Countable) {T : ι → (α → ε₁) → α' → ℝ≥0∞}
    {P : (α → ε₁) → Prop} (hT : ∀ (u : α → ε₁), P u → ∀ᵐ x ∂ν, ⨆ i ∈ 𝓑, T i u x ≠ ∞)
    (hP : ∀ {f g : α → ε₁}, P f → P g → P (f + g))
    {A : ℝ≥0∞} (h : ∀ i ∈ 𝓑, AESubadditiveOn (T i) P A ν) :
    AESubadditiveOn (fun u x ↦ ⨆ i ∈ 𝓑, T i u x) P A ν := by
  sorry

lemma indicator {T : (α → ε₁) → α' → ε} {P : (α → ε₁) → Prop} {A : ℝ≥0∞}
    (sa : AESubadditiveOn T P A ν) (S : Set α') :
    AESubadditiveOn (fun u x ↦ (S.indicator (fun y ↦ T u y) x)) P A ν := by
  sorry

-- If `T` is constant in the second argument (but not necessarily the first) and satisfies
-- a subadditivity criterion, then `AESubadditiveOn T P 1`
lemma const (T : (α → ε₁) → ε) (P : (α → ε₁) → Prop)
    (h_add : ∀ {f g}, P f → P g → ‖T (f + g)‖ₑ ≤ ‖T f‖ₑ + ‖T g‖ₑ) :
    AESubadditiveOn (fun u (_ : α') ↦ T u) P 1 ν := by
  sorry

end AESubadditiveOn

--[NormedSpace ℝ E₁] [NormedSpace ℝ E₂]
variable [TopologicalSpace ε] [ENormedSpace ε]

variable {ε₁ ε₂ : Type*} [TopologicalSpace ε₁] [ENormedSpace ε₁]

/-- The operator is sublinear on functions satisfying `P` with constant `A`. -/
def SublinearOn (T : (α → ε₁) → α' → ε) (P : (α → ε₁) → Prop) (A : ℝ≥0∞) :
    Prop :=
  SubadditiveOn T P A ∧ ∀ (f : α → ε₁) (c : ℝ≥0), P f → T (c • f) = c • T f

/-- The operator is almost everywhere sublinear on functions satisfying `P` with constant `A`. -/
def AESublinearOn (T : (α → ε₁) → α' → ε) (P : (α → ε₁) → Prop) (A : ℝ≥0∞) (ν : Measure α') :
    Prop :=
  AESubadditiveOn T P A ν ∧ ∀ (f : α → ε₁) (c : ℝ≥0), P f → T (c • f) =ᵐ[ν] c • T f

namespace SublinearOn

variable {P : (α → ε₁) → Prop} {A : ℝ≥0∞}

lemma aeSublinearOn {T : (α → ε₁) → α' → ℝ≥0∞} (h : SublinearOn T P A) {μ : Measure α'} :
    AESublinearOn T P A μ := by
  sorry

lemma biSup {ι : Type*} {𝓑 : Set ι} {T : ι → (α → ε₁) → α' → ℝ≥0∞}
    {P : (α → ε₁) → Prop}
    {A : ℝ≥0∞} (h : ∀ i ∈ 𝓑, SublinearOn (T i) P A) :
    SublinearOn (fun u x ↦ ⨆ i ∈ 𝓑, T i u x) P A := by
  sorry

end SublinearOn

namespace AESublinearOn

variable {ν : Measure α'}

lemma antitone {T : (α → ε₁) → α' → ε} {P P' : (α → ε₁) → Prop}
    (h : ∀ {u : α → ε₁}, P u → P' u) {A : ℝ≥0∞} (sl : AESublinearOn T P' A ν) :
    AESublinearOn T P A ν := by
  sorry

lemma biSup {ι : Type*} {𝓑 : Set ι} (h𝓑 : 𝓑.Countable) {T : ι → (α → ε₁) → α' → ℝ≥0∞}
    {P : (α → ε₁) → Prop} (hT : ∀ (u : α → ε₁), P u → ∀ᵐ x ∂ν, ⨆ i ∈ 𝓑, T i u x ≠ ∞)
    (h_add : ∀ {f g : α → ε₁}, P f → P g → P (f + g))
    (h_smul : ∀ {f : α → ε₁} {c : ℝ≥0}, P f → P (c • f))
    {A : ℝ≥0∞} (h : ∀ i ∈ 𝓑, AESublinearOn (T i) P A ν) :
    AESublinearOn (fun u x ↦ ⨆ i ∈ 𝓑, T i u x) P A ν := by
  sorry

lemma biSup2 {ι : Type*} {𝓑 : Set ι} (h𝓑 : 𝓑.Countable) {T : ι → (α → ε₁) → α' → ℝ≥0∞}
    {P : (α → ε₁) → Prop} {Q : (α → ε₁) → Prop}
    (hPT : ∀ (u : α → ε₁), P u → ∀ᵐ x ∂ν, ⨆ i ∈ 𝓑, T i u x ≠ ∞)
    (hQT : ∀ (u : α → ε₁), Q u → ∀ᵐ x ∂ν, ⨆ i ∈ 𝓑, T i u x ≠ ∞)
    (P0 : P 0)
    (Q0 : Q 0)
    (haP : ∀ {f g : α → ε₁}, P f → P g → P (f + g))
    (haQ : ∀ {f g : α → ε₁}, Q f → Q g → Q (f + g))
    (hsP : ∀ {f : α → ε₁} {c : ℝ≥0}, P f → P (c • f))
    (hsQ : ∀ {f : α → ε₁} {c : ℝ≥0}, Q f → Q (c • f))
    {A : ℝ≥0} -- todo, here and elsewhere: probably better to have {A : ℝ≥0∞} (hA : A ≠ ⊤)
    (hAP : ∀ i ∈ 𝓑,
      AESublinearOn (T i) (fun g ↦ g ∈ {f | P f} + {f | Q f}) A ν) :
    AESublinearOn (fun u x ↦ ⨆ i ∈ 𝓑, T i u x) (fun f ↦ P f ∨ Q f) A ν := by
  sorry

lemma indicator {T : (α → ε₁) → α' → ε} {P : (α → ε₁) → Prop} {A : ℝ≥0∞} (S : Set α')
    (sl : AESublinearOn T P A ν) :
    AESublinearOn (fun u x ↦ (S.indicator (fun y ↦ T u y) x)) P A ν := by
  sorry

-- If `T` is constant in the second argument (but not necessarily the first) and satisfies
-- certain requirements, then `AESublinearOn T P 1`
lemma const (T : (α → ε₁) → ε) (P : (α → ε₁) → Prop)
    (h_add : ∀ {f g}, P f → P g → ‖T (f + g)‖ₑ ≤ ‖T f‖ₑ + ‖T g‖ₑ)
    (h_smul : ∀ f {c : ℝ≥0}, P f → T (c • f) = c • T f) :
    AESublinearOn (fun u (_ : α') ↦ T u) P 1 ν := by
  sorry

lemma toReal {T : (α → ε₁) → α' → ℝ≥0∞}
    {P : (α → ε₁) → Prop}
    {A : ℝ≥0∞} (h : AESublinearOn T P A ν)
    (hP : ∀ (u : α → ε₁), P u → ∀ᵐ x ∂ν, T u x ≠ ∞) :
    AESublinearOn (T · · |>.toReal) P A ν := by
  sorry

end AESublinearOn

end MeasureTheory

end

noncomputable section

open NNReal ENNReal MeasureTheory Set ComputationsChoiceExponent
    ComputationsInterpolatedExponents ChoiceScale

variable {α α' E E₁ E₂ E₃ : Type*} {m : MeasurableSpace α} {m' : MeasurableSpace α'}
  {p p' q p₀ q₀ p₁ q₁ : ℝ≥0∞}
  {C₀ C₁ : ℝ≥0} {μ : Measure α} {ν : Measure α'}
  {f : α → E₁} {t : ℝ≥0∞}
  {T : (α → E₁) → (α' → E₂)}

/-! ## Proof of the real interpolation theorem

    In this section the estimates are combined to finally give a proof of the
    real interpolation theorem.
-/
namespace MeasureTheory

variable {ε₁ ε₂ : Type*} [TopologicalSpace ε₁] [ESeminormedAddMonoid ε₁] [TopologicalSpace ε₂] [ESeminormedAddMonoid ε₂]

/-- Proposition that expresses that the map `T` map between function spaces preserves
    AE strong measurability on L^p. -/
def PreservesAEStrongMeasurability (T : (α → ε₁) → α' → ε₂) (p : ℝ≥0∞) : Prop :=
    ∀ ⦃f : α → ε₁⦄, MemLp f p μ → AEStronglyMeasurable (T f) ν

lemma estimate_distribution_Subadditive_trunc {f : α → ε₁} {T : (α → ε₁) → (α' → ε₂)}
    {a : ℝ≥0∞} (ha : 0 < a) {A : ℝ≥0∞} (h : Subadditive_trunc T A f ν) :
    distribution (T f) (2 * A * t) ν ≤
    distribution (T (trunc f a)) t ν +
    distribution (T (truncCompl f a)) t ν := by
  sorry

lemma rewrite_norm_func {q : ℝ} {g : α' → E}
    [TopologicalSpace E] [ESeminormedAddCommMonoid E] (hq : 0 < q) {A : ℝ≥0} (hA : 0 < A)
    (hg : AEStronglyMeasurable g ν) :
    ∫⁻ x, ‖g x‖ₑ ^ q ∂ν =
    ENNReal.ofReal ((2 * A) ^ q * q) * ∫⁻ s,
    distribution g ((ENNReal.ofReal (2 * A) * s))  ν * s ^ (q - 1) := by
  sorry

lemma estimate_norm_rpow_range_operator {q : ℝ} {f : α → E₁}
    [TopologicalSpace E₁] [ESeminormedAddCommMonoid E₁] [TopologicalSpace E₂] [ESeminormedAddCommMonoid E₂]
    (hq : 0 < q) (tc : StrictRangeToneCouple) {A : ℝ≥0} (hA : 0 < A)
    (ht : Subadditive_trunc T A f ν) (hTf : AEStronglyMeasurable (T f) ν) :
  ∫⁻ x : α', ‖T f x‖ₑ ^ q ∂ν ≤
  ENNReal.ofReal ((2 * A)^q * q) * ∫⁻ s, distribution (T (trunc f (tc.ton s))) s ν * s^(q - 1) +
  distribution (T (truncCompl f (tc.ton s))) s ν * s ^ (q - 1) := by
  sorry

-- TODO: the infrastructure can perhaps be improved here
@[measurability, fun_prop]
theorem ton_measurable_eLpNorm_trunc [TopologicalSpace E₁] [ESeminormedAddCommMonoid E₁] (tc : ToneCouple) :
    Measurable (fun x ↦ eLpNorm (trunc f (tc.ton x)) p₁ μ) := by
  sorry

lemma estimate_norm_rpow_range_operator'
    [TopologicalSpace E₁] [ENormedAddCommMonoid E₁]
    [TopologicalSpace E₂] [ENormedAddCommMonoid E₂]
    (hp₀ : 0 < p₀) (hq₀ : 0 < q₀) (hq₁ : 0 < q₁) (hp₁p : p < p₁) (hp₀p : p₀ < p)
    (tc : StrictRangeToneCouple)
    (hq₀' : q₀ = ⊤ → ∀ s > 0, distribution (T (truncCompl f (tc.ton s))) s ν = 0)
    (hq₁' : q₁ = ⊤ → ∀ s > 0, distribution (T (trunc f (tc.ton s))) s ν = 0)
    (hf : MemLp f p μ) (hT₁ : HasWeakType T p₁ q₁ μ ν C₁) (hT₀ : HasWeakType T p₀ q₀ μ ν C₀) :
    ∫⁻ s : ℝ≥0∞, distribution (T (trunc f (tc.ton s))) s ν *
    s ^ (q.toReal - 1) +
    distribution (T (truncCompl f (tc.ton s))) s ν *
    s ^ (q.toReal - 1) ≤
    (if q₁ < ⊤ then 1 else 0) * (C₁ ^ q₁.toReal * (∫⁻ s : ℝ≥0∞,
        eLpNorm (trunc f (tc.ton s)) p₁ μ ^ q₁.toReal *
        s ^ (q.toReal - q₁.toReal - 1))) +
    (if q₀ < ⊤ then 1 else 0) * (C₀ ^ q₀.toReal * ∫⁻ s : ℝ≥0∞,
        eLpNorm (truncCompl f (tc.ton s)) (p₀) μ ^ q₀.toReal *
        s ^ (q.toReal - q₀.toReal - 1)) := by
  sorry

lemma simplify_factor_rw_aux₀ (a b c d e f : ℝ≥0∞) :
    a * b * c * d * e * f = a * c * e * (b * d * f) := by
  sorry
lemma simplify_factor_rw_aux₁ (a b c d e f : ℝ≥0∞) :
    a * b * c * d * e * f = c * (a * e) * (b * f * d) := by
  sorry

lemma simplify_factor₀ {D : ℝ≥0∞}
    [TopologicalSpace E₁] [ESeminormedAddCommMonoid E₁] (hq₀' : q₀ ≠ ⊤)
    (hp₀ : p₀ ∈ Ioc 0 q₀) (hp₁ : p₁ ∈ Ioc 0 q₁)
    (ht : t ∈ Ioo 0 1)
    (hq₀q₁ : q₀ ≠ q₁) (hp : p⁻¹ = (1 - t) * p₀⁻¹ + t * p₁⁻¹)
    (hq : q⁻¹ = (1 - t) * q₀⁻¹ + t * q₁⁻¹)
    (hC₀ : 0 < C₀) (hC₁ : 0 < C₁)
    (hF : eLpNorm f p μ ∈ Ioo 0 ⊤)
    (hD : D = @d _ E₁ _ p p₀ q₀ p₁ q₁ C₀ C₁ μ _ _ f) :
    C₀ ^ q₀.toReal * (eLpNorm f p μ ^ p.toReal) ^ (q₀.toReal / p₀.toReal) *
    (D ^ (q.toReal - q₀.toReal)) =
    C₀ ^ ((1 - t).toReal * q.toReal) * C₁ ^ (t.toReal * q.toReal) * eLpNorm f p μ ^ q.toReal := by
  sorry

lemma simplify_factor₁ {D : ℝ≥0∞}
    [TopologicalSpace E₁] [ESeminormedAddCommMonoid E₁] (hq₁' : q₁ ≠ ⊤)
    (hp₀ : p₀ ∈ Ioc 0 q₀) (hp₁ : p₁ ∈ Ioc 0 q₁)
    (ht : t ∈ Ioo 0 1)
    (hq₀q₁ : q₀ ≠ q₁) (hp : p⁻¹ = (1 - t) * p₀⁻¹ + t * p₁⁻¹)
    (hq : q⁻¹ = (1 - t) * q₀⁻¹ + t * q₁⁻¹)
    (hC₀ : 0 < C₀) (hC₁ : 0 < C₁)
    (hF : eLpNorm f p μ ∈ Ioo 0 ⊤)
    (hD : D = @d _ E₁ _ p p₀ q₀ p₁ q₁ C₀ C₁ μ _ _ f) :
    C₁ ^ q₁.toReal * (eLpNorm f p μ ^ p.toReal) ^ (q₁.toReal / p₁.toReal) *
    (D ^ (q.toReal - q₁.toReal)) =
    C₀ ^ ((1 - t).toReal * q.toReal) * C₁ ^ (t.toReal * q.toReal) * eLpNorm f p μ ^ q.toReal := by
  sorry

def finite_spanning_sets_from_lintegrable {g : α → ℝ≥0∞} (hg : AEMeasurable g μ)
    (hg_int : ∫⁻ x, g x ∂μ < ⊤) : Measure.FiniteSpanningSetsIn
      (μ.restrict g.support) Set.univ where
  set := fun n ↦ if n = 0 then {x | g x = 0} else { x | 1 / (n + 1) ≤ g x }
  set_mem := fun _ ↦ trivial
  finite := by
    intro n
    split_ifs
    · rw [Measure.restrict_apply₀']
      · rw [measure_mono_null _ measure_empty]
        · exact zero_lt_top
        · intro x; simp
      · exact (aestronglyMeasurable_iff_aemeasurable.mpr hg).nullMeasurableSet_support
    · have one_div_ne_zero : (1 : ℝ≥0∞) / (n + 1) ≠ 0 := by
        apply ne_of_gt
        rw [one_div]
        exact ENNReal.inv_pos.mpr (by finiteness)
      calc
      _ ≤ (∫⁻ x : α in g.support, g x ∂μ) / (1 / (n + 1)) :=
        meas_ge_le_lintegral_div hg.restrict one_div_ne_zero (by finiteness)
      _ ≤ (∫⁻ x : α, g x ∂μ) / (1 / (n + 1)) := by
        gcongr
        exact Measure.restrict_le_self
      _ < ⊤ := by finiteness
  spanning := by
    ext x
    constructor
    · simp
    · intro _
      rcases (eq_zero_or_pos (g x)) with gx_zero | gx_pos
      · simp only [mem_iUnion]; use 0; simpa
      · simp only [mem_iUnion]
        have : ∃ n : ℕ, (g x)⁻¹ < n := ENNReal.exists_nat_gt (inv_lt_top.mpr gx_pos).ne
        obtain ⟨n, wn⟩ := ENNReal.exists_nat_gt (inv_lt_top.mpr gx_pos).ne
        use n
        simp only [one_div]
        split_ifs with is_n_zero
        · simp [is_n_zero] at wn
        · simp only [mem_setOf_eq]
          refine inv_le_iff_inv_le.mpr ?_
          apply le_of_lt
          refine lt_trans wn ?_
          nth_rw 1 [← add_zero (n : ℝ≥0∞)]
          exact (ENNReal.add_lt_add_iff_left coe_ne_top).mpr zero_lt_one

lemma support_sigma_finite_of_lintegrable {g : α → ℝ≥0∞} (hg : AEMeasurable g μ)
    (hg_int : ∫⁻ x, g x ∂μ < ⊤) :
    SigmaFinite (μ.restrict g.support) := by
  sorry

lemma support_sigma_finite_from_MemLp
    [TopologicalSpace E₁] [ENormedAddCommMonoid E₁]
    (hf : MemLp f p μ) (hp : p ≠ ⊤) (hp' : p ≠ 0) :
    SigmaFinite (μ.restrict f.support) := by
  sorry

-- lemma support_sfinite_from_MemLp
--     [MeasurableSpace E₁] [NormedAddCommGroup E₁] [BorelSpace E₁] (hf : MemLp f p μ)
--     (hp : p ≠ ⊤) (hp' : p ≠ 0) :
--     SFinite (μ.restrict f.support) := by
--   have : SigmaFinite (μ.restrict f.support) := support_sigma_finite_from_MemLp hf hp hp'
--   exact instSFiniteOfSigmaFinite

lemma combine_estimates₀ {A : ℝ≥0} (hA : 0 < A)
  [TopologicalSpace E₁] [ENormedAddCommMonoid E₁] [MeasurableSpace E₁] [BorelSpace E₁]
  [TopologicalSpace.PseudoMetrizableSpace E₁]
  [TopologicalSpace E₂] [ENormedAddCommMonoid E₂] --[BorelSpace E₂]
  {spf : ScaledPowerFunction}
  (hp₀ : p₀ ∈ Ioc 0 q₀) (hp₁ : p₁ ∈ Ioc 0 q₁) (ht : t ∈ Ioo 0 1)
  (hp₀p₁ : p₀ < p₁) (hq₀q₁ : q₀ ≠ q₁)
  (hp : p⁻¹ = (1 - t) * p₀⁻¹ + t * p₁⁻¹)
  (hq : q⁻¹ = (1 - t) * q₀⁻¹ + t * q₁⁻¹)
  (hf : MemLp f p μ) (hT : Subadditive_trunc T A f ν)
  (hC₀ : 0 < C₀) (hC₁ : 0 < C₁)
  (hF : eLpNorm f p μ ∈ Ioo 0 ⊤)
  (hspf : spf = spf_ch (toReal_mem_Ioo ht) hq₀q₁ hp₀.1 (lt_of_lt_of_le hp₀.1 hp₀.2) hp₁.1
      (lt_of_lt_of_le hp₁.1 hp₁.2) hp₀p₁.ne hC₀ hC₁ hF)
  (h₁T : HasWeakType T p₁ q₁ μ ν C₁)
  (h₀T : HasWeakType T p₀ q₀ μ ν C₀)
  (h₂T : PreservesAEStrongMeasurability T p (ν := ν) (μ := μ)) :
    ∫⁻ x , ‖T f x‖ₑ ^ q.toReal ∂ν ≤
    ENNReal.ofReal ((2 * A) ^ q.toReal * q.toReal) *
    ((if q₁ < ⊤ then 1 else 0) * ENNReal.ofReal |q.toReal - q₁.toReal|⁻¹ +
    (if q₀ < ⊤ then 1 else 0) * ENNReal.ofReal |q.toReal - q₀.toReal|⁻¹) *
    C₀ ^ ((1 - t).toReal * q.toReal) * C₁ ^ (t.toReal * q.toReal) * eLpNorm f p μ ^ q.toReal := by
  sorry

lemma combine_estimates₁ {A : ℝ≥0} (hA : 0 < A)
    [TopologicalSpace E₁] [ENormedAddCommMonoid E₁] [MeasurableSpace E₁] [BorelSpace E₁]
    [TopologicalSpace.PseudoMetrizableSpace E₁]
    [TopologicalSpace E₂] [ENormedAddCommMonoid E₂]
    {spf : ScaledPowerFunction}
    (hp₀ : p₀ ∈ Ioc 0 q₀) (hp₁ : p₁ ∈ Ioc 0 q₁) (ht : t ∈ Ioo 0 1)
    (hp₀p₁ : p₀ < p₁) (hq₀q₁ : q₀ ≠ q₁)
    (hp : p⁻¹ = (1 - t) * p₀⁻¹ + t * p₁⁻¹)
    (hq : q⁻¹ = (1 - t) * q₀⁻¹ + t * q₁⁻¹)
    (hf : MemLp f p μ) (hT : Subadditive_trunc T A f ν)
    (h₁T : HasWeakType T p₁ q₁ μ ν C₁)
    (h₀T : HasWeakType T p₀ q₀ μ ν C₀)
    (h₂T : PreservesAEStrongMeasurability T p (ν := ν) (μ := μ))
    (hC₀ : 0 < C₀) (hC₁ : 0 < C₁)
    (hF : eLpNorm f p μ ∈ Ioo 0 ⊤)
    (hspf : spf = spf_ch (toReal_mem_Ioo ht) hq₀q₁ hp₀.1 (lt_of_lt_of_le hp₀.1 hp₀.2) hp₁.1
        (lt_of_lt_of_le hp₁.1 hp₁.2) hp₀p₁.ne hC₀ hC₁ hF) :
    eLpNorm (T f) q ν ≤
    ENNReal.ofReal (2 * A) * q ^ q⁻¹.toReal *
    (((if q₁ < ⊤ then 1 else 0) * ENNReal.ofReal |q.toReal - q₁.toReal|⁻¹ +
    (if q₀ < ⊤ then 1 else 0) * ENNReal.ofReal |q.toReal - q₀.toReal|⁻¹)) ^ q⁻¹.toReal *
    C₀ ^ (1 - t).toReal * C₁ ^ t.toReal * eLpNorm f p μ := by
  sorry

lemma simplify_factor₃ [TopologicalSpace E₁] [ESeminormedAddCommMonoid E₁] (hp₀ : 0 < p₀) (hp₀' : p₀ ≠ ⊤) (ht : t ∈ Ioo 0 1)
    (hp : p⁻¹ = (1 - t) * p₀⁻¹ + t * p₁⁻¹) (hp₀p₁ : p₀ = p₁) :
    C₀ ^ q₀.toReal * (eLpNorm f p μ ^ p.toReal) ^ (q₀.toReal / p₀.toReal) =
    (↑C₀ * eLpNorm f p μ) ^ q₀.toReal := by
  sorry

lemma simplify_factor_aux₄ [TopologicalSpace E₁] [ESeminormedAddCommMonoid E₁] (hq₀' : q₀ ≠ ⊤)
    (hp₀ : p₀ ∈ Ioc 0 q₀) (ht : t ∈ Ioo 0 1)
    (hp₀p₁ : p₀ = p₁) (hp : p⁻¹ = (1 - t) * p₀⁻¹ + t * p₁⁻¹)
    (hF : eLpNorm f p μ ∈ Ioo 0 ⊤) :
    ↑C₀ ^ ((1 - t).toReal * q.toReal) * (eLpNorm f p μ ^ p.toReal) ^ ((1 - t).toReal * p₀⁻¹.toReal * q.toReal) *
      ↑C₁ ^ (t.toReal * q.toReal) *
    (eLpNorm f p μ ^ p.toReal) ^ (t.toReal * p₁⁻¹.toReal * q.toReal) = C₀ ^ ((1 - t).toReal * q.toReal) *
    C₁ ^ (t.toReal * q.toReal) * eLpNorm f p μ ^ q.toReal := by
  sorry

lemma simplify_factor₄ {D : ℝ≥0∞} [TopologicalSpace E₁] [ESeminormedAddCommMonoid E₁] (hq₀' : q₀ ≠ ⊤)
    (hp₀ : p₀ ∈ Ioc 0 q₀) (hp₁ : p₁ ∈ Ioc 0 q₁) (ht : t ∈ Ioo 0 1)
    (hp₀p₁ : p₀ = p₁)
    (hq₀q₁ : q₀ ≠ q₁) (hp : p⁻¹ = (1 - t) * p₀⁻¹ + t * p₁⁻¹)
    (hq : q⁻¹ = (1 - t) * q₀⁻¹ + t * q₁⁻¹)
    (hC₀ : 0 < C₀) (hC₁ : 0 < C₁)
    (hF : eLpNorm f p μ ∈ Ioo 0 ⊤)
    (hD : D = @d _ E₁ _ p p₀ q₀ p₁ q₁ C₀ C₁ μ _ _ f) :
    (↑C₀ * eLpNorm f p μ) ^ q₀.toReal * (D ^ (q.toReal - q₀.toReal)) =
    C₀ ^ ((1 - t).toReal * q.toReal) * C₁ ^ (t.toReal * q.toReal) * eLpNorm f p μ ^ q.toReal := by
  sorry

lemma simplify_factor₅ {D : ℝ≥0∞} [TopologicalSpace E₁] [ESeminormedAddCommMonoid E₁] (hq₁' : q₁ ≠ ⊤)
    (hp₀ : p₀ ∈ Ioc 0 q₀) (hp₁ : p₁ ∈ Ioc 0 q₁)
    (ht : t ∈ Ioo 0 1)
    (hp₀p₁ : p₀ = p₁)
    (hq₀q₁ : q₀ ≠ q₁) (hp : p⁻¹ = (1 - t) * p₀⁻¹ + t * p₁⁻¹)
    (hq : q⁻¹ = (1 - t) * q₀⁻¹ + t * q₁⁻¹)
    (hC₀ : 0 < C₀) (hC₁ : 0 < C₁)
    (hF : eLpNorm f p μ ∈ Ioo 0 ⊤)
    (hD : D = @d _ E₁ _ p p₀ q₀ p₁ q₁ C₀ C₁ μ _ _ f) :
    (↑C₁ * eLpNorm f p μ) ^ q₁.toReal * (D ^ (q.toReal - q₁.toReal)) =
    C₀ ^ ((1 - t).toReal * q.toReal) * C₁ ^ (t.toReal * q.toReal) * eLpNorm f p μ ^ q.toReal := by
  sorry

/-- The trivial case for the estimate in the real interpolation theorem
when the `L^p` norm of `f` vanishes. -/
lemma exists_hasStrongType_real_interpolation_aux₀ {p₀ p₁ q₀ q₁ p q : ℝ≥0∞}
    [TopologicalSpace E₁] [ENormedAddCommMonoid E₁] [TopologicalSpace E₂] [ENormedAddCommMonoid E₂]
    (hp₀ : p₀ ∈ Ioc 0 q₀) (hp₁ : p₁ ∈ Ioc 0 q₁) (ht : t ∈ Ioo 0 1)
    {C₀ : ℝ≥0}
    (hp : p⁻¹ = (1 - t) / p₀ + t / p₁)
    (hq : q⁻¹ = (1 - t) / q₀ + t / q₁)
    (h₀T : HasWeakType T p₀ q₀ μ ν C₀)
    (h₂T : PreservesAEStrongMeasurability (μ := μ) (ν := ν) T p) (hf : MemLp f p μ)
    (hF : eLpNorm f p μ = 0) :
    eLpNorm (T f) q ν = 0 := by
  sorry

/-- The estimate for the real interpolation theorem in case `p₀ < p₁`. -/
lemma exists_hasStrongType_real_interpolation_aux {p₀ p₁ q₀ q₁ p q : ℝ≥0∞} {A : ℝ≥0}
    [TopologicalSpace E₁] [ENormedAddCommMonoid E₁] [MeasurableSpace E₁] [BorelSpace E₁]
    [TopologicalSpace.PseudoMetrizableSpace E₁]
    [TopologicalSpace E₂] [ENormedAddCommMonoid E₂] (hA : 0 < A)
    (hp₀ : p₀ ∈ Ioc 0 q₀) (hp₁ : p₁ ∈ Ioc 0 q₁) (hp₀p₁ : p₀ < p₁) (hq₀q₁ : q₀ ≠ q₁)
    {C₀ C₁ : ℝ≥0} (ht : t ∈ Ioo 0 1) (hC₀ : 0 < C₀) (hC₁ : 0 < C₁)
    (hp : p⁻¹ = (1 - t) / p₀ + t / p₁)
    (hq : q⁻¹ = (1 - t) / q₀ + t / q₁)
    (hT : Subadditive_trunc T A f ν) (h₀T : HasWeakType T p₀ q₀ μ ν C₀)
    (h₁T : HasWeakType T p₁ q₁ μ ν C₁)
    (h₂T : PreservesAEStrongMeasurability (μ := μ) (ν := ν) T p) (hf : MemLp f p μ) :
    eLpNorm (T f) q ν ≤
    ENNReal.ofReal (2 * A) * q ^ q⁻¹.toReal *
    (((if q₁ < ⊤ then 1 else 0) * ENNReal.ofReal |q.toReal - q₁.toReal|⁻¹ +
    (if q₀ < ⊤ then 1 else 0) * ENNReal.ofReal |q.toReal - q₀.toReal|⁻¹)) ^ q⁻¹.toReal *
    C₀ ^ (1 - t).toReal * C₁ ^ t.toReal * eLpNorm f p μ := by
  sorry

-- TODO: the below lemmas were split because otherwise the lean server would crash
-- (seems to be related to the linter?) (after the merge)
lemma exists_hasStrongType_real_interpolation_aux₁ {f : α → E₁}
    [TopologicalSpace E₁] [ENormedAddCommMonoid E₁]
    (hp₀ : p₀ ∈ Ioc 0 q₀) (hp₁ : p₁ ∈ Ioc 0 q₁) (hp₀p₁ : p₀ = p₁) (hq₀q₁ : q₀ < q₁)
    {C₀ C₁ : ℝ≥0} (ht : t ∈ Ioo 0 1) (hC₀ : 0 < C₀) (hC₁ : 0 < C₁)
    (hp : p⁻¹ = (1 - t) / p₀ + t / p₁)
    (hq : q⁻¹ = (1 - t) / q₀ + t / q₁)
    (hF : eLpNorm f p μ ∈ Ioo 0 ⊤) :
    (ENNReal.ofReal q.toReal *
        ((C₀ * eLpNorm f p μ )^ q₀.toReal *
        (∫⁻ (t : ℝ) in Ioo 0 (@d _ E₁ _ p p₀ q₀ p₁ q₁ C₀ C₁ μ _ _ f).toReal,
        ENNReal.ofReal (t ^ (q.toReal - q₀.toReal - 1))) * (if q₀ = ⊤ then 0 else 1) +
        ((C₁ * eLpNorm f p μ) ^ q₁.toReal *
        ∫⁻ (t : ℝ) in Ici (@d _ E₁ _ p p₀ q₀ p₁ q₁ C₀ C₁ μ _ _ f).toReal,
        ENNReal.ofReal (t ^ (q.toReal - q₁.toReal - 1))) * if q₁ = ⊤ then 0 else 1)) ^
        q.toReal⁻¹ =
    q ^ q.toReal⁻¹ * (ENNReal.ofReal |q.toReal - q₀.toReal|⁻¹ * (if q₀ = ⊤ then 0 else 1) +
      ENNReal.ofReal |q.toReal - q₁.toReal|⁻¹ * (if q₁ = ⊤ then 0 else 1)) ^ q.toReal⁻¹ *
    ↑C₀ ^ ((1 - t).toReal) * ↑C₁ ^ t.toReal * eLpNorm f p μ := by
  sorry

/-- The main estimate in the real interpolation theorem for `p₀ = p₁`, before taking roots,
    for the case `q₀ < q₁`. -/
lemma exists_hasStrongType_real_interpolation_aux₂ {f : α → E₁}
    [TopologicalSpace E₁] [ENormedAddCommMonoid E₁]
    [TopologicalSpace E₂] [ENormedAddCommMonoid E₂]
    (hp₀ : p₀ ∈ Ioc 0 q₀) (hp₁ : p₁ ∈ Ioc 0 q₁) (hp₀p₁ : p₀ = p₁) (hq₀q₁ : q₀ < q₁)
    {C₀ C₁ : ℝ≥0} (ht : t ∈ Ioo 0 1) (hC₀ : 0 < C₀) (hC₁ : 0 < C₁)
    (hp : p⁻¹ = (1 - t) / p₀ + t / p₁)
    (hq : q⁻¹ = (1 - t) / q₀ + t / q₁)
    (h₀T : HasWeakType T p₀ q₀ μ ν C₀) (h₁T : HasWeakType T p₁ q₁ μ ν C₁)
    (h₂T : PreservesAEStrongMeasurability (μ := μ) (ν := ν) T p)
    (hf : MemLp f p μ) :
    eLpNorm (T f) q ν ≤
    q ^ q.toReal⁻¹ * (ENNReal.ofReal |q.toReal - q₀.toReal|⁻¹ * (if q₀ = ⊤ then 0 else 1) +
      ENNReal.ofReal |q.toReal - q₁.toReal|⁻¹ * (if q₁ = ⊤ then 0 else 1)) ^ q.toReal⁻¹ *
    ↑C₀ ^ ((1 - t).toReal) * ↑C₁ ^ t.toReal * eLpNorm f p μ := by
  sorry

/-- The main estimate for the real interpolation theorem for `p₀ = p₁`, requiring `q₀ ≠ q₁`,
before taking roots. -/
lemma exists_hasStrongType_real_interpolation_aux₃ {p₀ p₁ q₀ q₁ p q : ℝ≥0∞}
    [TopologicalSpace E₁] [ENormedAddCommMonoid E₁]
    [TopologicalSpace E₂] [ENormedAddCommMonoid E₂]
    (hp₀ : p₀ ∈ Ioc 0 q₀) (hp₁ : p₁ ∈ Ioc 0 q₁) (hp₀p₁ : p₀ = p₁) (hq₀q₁ : q₀ ≠ q₁)
    {C₀ C₁ : ℝ≥0} (ht : t ∈ Ioo 0 1) (hC₀ : 0 < C₀) (hC₁ : 0 < C₁)
    (hp : p⁻¹ = (1 - t) / p₀ + t / p₁)
    (hq : q⁻¹ = (1 - t) / q₀ + t / q₁)
    (h₀T : HasWeakType T p₀ q₀ μ ν C₀) (h₁T : HasWeakType T p₁ q₁ μ ν C₁)
    (h₂T : PreservesAEStrongMeasurability (μ := μ) (ν := ν) T p)
    (hf : MemLp f p μ) :
    eLpNorm (T f) q ν ≤
    q ^ q.toReal⁻¹ * (ENNReal.ofReal |q.toReal - q₀.toReal|⁻¹ * (if q₀ = ⊤ then 0 else 1) +
      ENNReal.ofReal |q.toReal - q₁.toReal|⁻¹ * (if q₁ = ⊤ then 0 else 1)) ^ q.toReal⁻¹ *
    ↑C₀ ^ ((1 - t).toReal) * ↑C₁ ^ t.toReal * eLpNorm f p μ := by
  sorry

/-- The main estimate for the real interpolation theorem, before taking roots, combining
the cases `p₀ ≠ p₁` and `p₀ = p₁`. -/
lemma exists_hasStrongType_real_interpolation_aux₄ {p₀ p₁ q₀ q₁ p q : ℝ≥0∞} {A : ℝ≥0} (hA : 0 < A)
    [TopologicalSpace E₁] [ENormedAddCommMonoid E₁] [MeasurableSpace E₁] [BorelSpace E₁]
    [TopologicalSpace.PseudoMetrizableSpace E₁]
    [TopologicalSpace E₂] [ENormedAddCommMonoid E₂]
    (hp₀ : p₀ ∈ Ioc 0 q₀) (hp₁ : p₁ ∈ Ioc 0 q₁) (hq₀q₁ : q₀ ≠ q₁)
    {C₀ C₁ : ℝ≥0} (ht : t ∈ Ioo 0 1) (hC₀ : 0 < C₀) (hC₁ : 0 < C₁)
    (hp : p⁻¹ = (1 - t) / p₀ + t / p₁)
    (hq : q⁻¹ = (1 - t) / q₀ + t / q₁)
    (hT : Subadditive_trunc T A f ν) (h₀T : HasWeakType T p₀ q₀ μ ν C₀)
    (h₁T : HasWeakType T p₁ q₁ μ ν C₁)
    (h₂T : PreservesAEStrongMeasurability (μ := μ) (ν := ν) T p) (hf : MemLp f p μ) :
    eLpNorm (T f) q ν ≤
    (if p₀ = p₁ then 1 else ENNReal.ofReal (2 * A)) * q ^ q⁻¹.toReal *
    (((if q₁ < ⊤ then 1 else 0) * ENNReal.ofReal |q.toReal - q₁.toReal|⁻¹ +
    (if q₀ < ⊤ then 1 else 0) * ENNReal.ofReal |q.toReal - q₀.toReal|⁻¹)) ^ q⁻¹.toReal *
    C₀ ^ (1 - t).toReal * C₁ ^ t.toReal * eLpNorm f p μ := by
  sorry

/-- The definition of the constant in the real interpolation theorem, when viewed as
    an element of `ℝ≥0∞`. -/
def C_realInterpolation_ENNReal (p₀ p₁ q₀ q₁ q : ℝ≥0∞) (C₀ C₁ : ℝ≥0) (A : ℝ≥0) (t : ℝ≥0∞) :=
    (if p₀ = p₁ then 1 else ENNReal.ofReal (2 * A)) * q ^ q⁻¹.toReal *
    (((if q₁ < ⊤ then 1 else 0) * ENNReal.ofReal |q.toReal - q₁.toReal|⁻¹ +
    (if q₀ < ⊤ then 1 else 0) * ENNReal.ofReal |q.toReal - q₀.toReal|⁻¹)) ^ q⁻¹.toReal *
    C₀ ^ (1 - t).toReal * C₁ ^ t.toReal

lemma C_realInterpolation_ENNReal_ne_top {p₀ p₁ q₀ q₁ q : ℝ≥0∞} {A : ℝ≥0}
    (hp₀ : p₀ ∈ Ioc 0 q₀) (hp₁ : p₁ ∈ Ioc 0 q₁) (hq₀q₁ : q₀ ≠ q₁)
    {C₀ C₁ : ℝ≥0} (ht : t ∈ Ioo 0 1) (hC₀ : 0 < C₀) (hC₁ : 0 < C₁)
    (hq : q⁻¹ = (1 - t) / q₀ + t / q₁) :
    C_realInterpolation_ENNReal p₀ p₁ q₀ q₁ q C₀ C₁ A t ≠ ⊤ := by
  sorry

lemma C_realInterpolation_ENNReal_pos {p₀ p₁ q₀ q₁ q : ℝ≥0∞} {A : ℝ≥0} (hA : 0 < A)
    (hp₀ : p₀ ∈ Ioc 0 q₀) (hp₁ : p₁ ∈ Ioc 0 q₁) (hq₀q₁ : q₀ ≠ q₁)
    {C₀ C₁ : ℝ≥0} (ht : t ∈ Ioo 0 1) (hC₀ : 0 < C₀) (hC₁ : 0 < C₁)
    (hq : q⁻¹ = (1 - t) / q₀ + t / q₁) :
    0 < C_realInterpolation_ENNReal p₀ p₁ q₀ q₁ q C₀ C₁ A t := by
  sorry

/-- The constant occurring in the real interpolation theorem -/
-- todo: check order of arguments
def C_realInterpolation (p₀ p₁ q₀ q₁ q : ℝ≥0∞) (C₀ C₁ A : ℝ≥0) (t : ℝ≥0∞) : ℝ≥0 :=
    C_realInterpolation_ENNReal p₀ p₁ q₀ q₁ q C₀ C₁ A t |>.toNNReal

lemma C_realInterpolation_pos {p₀ p₁ q₀ q₁ q : ℝ≥0∞} {A : ℝ≥0} (hA : 0 < A)
    (hp₀ : p₀ ∈ Ioc 0 q₀) (hp₁ : p₁ ∈ Ioc 0 q₁) (hq₀q₁ : q₀ ≠ q₁)
    {C₀ C₁ : ℝ≥0} (ht : t ∈ Ioo 0 1) (hC₀ : 0 < C₀) (hC₁ : 0 < C₁)
    (hq : q⁻¹ = (1 - t) / q₀ + t / q₁) :
    0 < C_realInterpolation p₀ p₁ q₀ q₁ q C₀ C₁ A t := by
  sorry

lemma coe_C_realInterpolation {p₀ p₁ q₀ q₁ q : ℝ≥0∞} {A : ℝ≥0}
    (hp₀ : p₀ ∈ Ioc 0 q₀) (hp₁ : p₁ ∈ Ioc 0 q₁) (hq₀q₁ : q₀ ≠ q₁)
    {C₀ C₁ : ℝ≥0} (ht : t ∈ Ioo 0 1) (hC₀ : 0 < C₀) (hC₁ : 0 < C₁)
    (hq : q⁻¹ = (1 - t) / q₀ + t / q₁) :
  ENNReal.ofNNReal (C_realInterpolation p₀ p₁ q₀ q₁ q C₀ C₁ A t) =
     C_realInterpolation_ENNReal p₀ p₁ q₀ q₁ q C₀ C₁ A t := by
  sorry

lemma Subadditive_trunc_from_SubadditiveOn_Lp₀p₁ {p₀ p₁ p : ℝ≥0∞}
    [TopologicalSpace E₁] [ENormedAddCommMonoid E₁]
    [TopologicalSpace E₂] [ENormedAddCommMonoid E₂]
    (hp₀ : 0 < p₀) (hp₁ : 0 < p₁)
    {A : ℝ≥0} (hA : 1 ≤ A) (ht : t ∈ Ioo 0 1)
    (hp : p⁻¹ = (1 - t) / p₀ + t / p₁)
    (hT : AESubadditiveOn T (fun f ↦ MemLp f p₀ μ ∨ MemLp f p₁ μ) A ν)
    (hf : MemLp f p μ) :
    Subadditive_trunc T A f ν := by
  sorry

/-- Marcinkiewicz real interpolation theorem -/
theorem exists_hasStrongType_real_interpolation {p₀ p₁ q₀ q₁ p q : ℝ≥0∞}
    [TopologicalSpace E₁] [ENormedAddCommMonoid E₁] [MeasurableSpace E₁] [BorelSpace E₁]
    [TopologicalSpace.PseudoMetrizableSpace E₁]
    [TopologicalSpace E₂] [ENormedAddCommMonoid E₂]
    (hp₀ : p₀ ∈ Ioc 0 q₀) (hp₁ : p₁ ∈ Ioc 0 q₁) (hq₀q₁ : q₀ ≠ q₁)
    {C₀ C₁ A : ℝ≥0} (hA : 1 ≤ A) (ht : t ∈ Ioo 0 1) (hC₀ : 0 < C₀) (hC₁ : 0 < C₁)
    (hp : p⁻¹ = (1 - t) / p₀ + t / p₁) (hq : q⁻¹ = (1 - t) / q₀ + t / q₁)
    (hmT : ∀ f, MemLp f p μ → AEStronglyMeasurable (T f) ν)
    (hT : AESubadditiveOn T (fun f ↦ MemLp f p₀ μ ∨ MemLp f p₁ μ) A ν)
    (h₀T : HasWeakType T p₀ q₀ μ ν C₀) (h₁T : HasWeakType T p₁ q₁ μ ν C₁) :
    HasStrongType T p q μ ν (C_realInterpolation p₀ p₁ q₀ q₁ q C₀ C₁ A t) := by
  sorry

end MeasureTheory

end
