module

public import Carleson.ToMathlib.MeasureTheory.Function.LorentzSeminorm.Basic
public import Carleson.ToMathlib.MeasureTheory.Function.LorentzSeminorm.TriangleInequality
public import Mathlib.MeasureTheory.Function.SpecialFunctions.RCLike
public import Carleson.Defs
public import Carleson.ToMathlib.Data.ENNReal
public import Carleson.ToMathlib.MeasureTheory.Measure.NNReal
public import Carleson.ToMathlib.MeasureTheory.Measure.AEMeasurable
public import Carleson.ToMathlib.MeasureTheory.Function.SimpleFunc
public import Carleson.ToMathlib.MeasureTheory.Function.LocallyIntegrable
public import Carleson.ToMathlib.Rearrangement
public import Carleson.ToMathlib.RealInterpolation.Misc
public import Carleson.ToMathlib.Order.Filter.ENNReal
public import Carleson.ToMathlib.Analysis.RCLike.Components
public import Carleson.ToMathlib.Analysis.RCLike.Misc

@[expose] public section

-- Upstreaming status: proofs need cleanup

noncomputable section

open NNReal ENNReal NormedSpace MeasureTheory Set Filter Topology Function

namespace MeasureTheory

variable {α α' ε₁ ε₂ : Type*} {m0 : MeasurableSpace α} {m : MeasurableSpace α'}
  {μ : Measure α} {ν : Measure α'} [TopologicalSpace ε₁] [TopologicalSpace ε₂] {p q : ℝ≥0∞}

/-- An operator has Lorentz type `(p, r, q, s)` if it is bounded as a map
from `L^{q, s}` to `L^{p, r}`. `HasLorentzType T p r q s μ ν c` means that
`T` has Lorentz type `(p, r, q, s)` w.r.t. measures `μ`, `ν` and constant `c`. -/
def HasLorentzType [ENorm ε₁] [ENorm ε₂] (T : (α → ε₁) → (α' → ε₂))
    (p r q s : ℝ≥0∞) (μ : Measure α) (ν : Measure α') (c : ℝ≥0∞) : Prop :=
  ∀ f : α → ε₁, MemLorentz f p r μ → AEStronglyMeasurable (T f) ν ∧
    eLorentzNorm (T f) q s ν ≤ c * eLorentzNorm f p r μ

lemma hasStrongType_iff_hasLorentzType [ESeminormedAddMonoid ε₁] [ESeminormedAddMonoid ε₂]
  {T : (α → ε₁) → (α' → ε₂)} {c : ℝ≥0∞} :
    HasStrongType T p q μ ν c ↔ HasLorentzType T p p q q μ ν c := by
  sorry

variable {β : Type*} [Zero β] [One β]

/-- Defines when an operator "has restricted weak type". This is an even weaker version
of `HasBoundedWeakType`. -/
def HasRestrictedWeakType [ENorm ε₂] (T : (α → β) → (α' → ε₂)) (p q : ℝ≥0∞)
  (μ : Measure α) (ν : Measure α')
    (c : ℝ≥0∞) : Prop :=
  ∀ (F : Set α) (G : Set α'), (MeasurableSet F) → (μ F < ∞) → (MeasurableSet G) → (ν G < ∞) →
    AEStronglyMeasurable (T (F.indicator (fun _ ↦ 1))) ν ∧
      eLpNorm (T (F.indicator (fun _ ↦ 1))) 1 (ν.restrict G)
        ≤ c * (μ F) ^ p⁻¹.toReal * (ν G) ^ q⁻¹.toReal

lemma HasRestrictedWeakType.without_finiteness [ESeminormedAddMonoid ε₂] {T : (α → β) → (α' → ε₂)}
    (p_ne_zero : p ≠ 0) (p_ne_top : p ≠ ⊤) (q_ne_zero : q ≠ 0) (q_ne_top : q ≠ ⊤)
    {c : ℝ≥0} (c_pos : 0 < c) (hT : HasRestrictedWeakType T p q μ ν c)
    (T_zero_of_ae_zero : ∀ {f : α → β} (_ : f =ᶠ[ae μ] 0), enorm ∘ T f =ᶠ[ae ν] 0) :
  ∀ (F : Set α) (G : Set α'), (MeasurableSet F) → (MeasurableSet G) →
    eLpNorm (T (F.indicator (fun _ ↦ 1))) 1 (ν.restrict G)
      ≤ c * (μ F) ^ p⁻¹.toReal * (ν G) ^ q⁻¹.toReal := by
  sorry

/-- An enhanced version of `HasRestrictedWeakType` -/
def HasRestrictedWeakType' [TopologicalSpace β] [ENorm β] [ENorm ε₂] (T : (α → β) → (α' → ε₂)) (p q : ℝ≥0∞)
  (μ : Measure α) (ν : Measure α')
    (c : ℝ≥0∞) : Prop :=
  ∀ (f : α → β) (_ : MemLorentz f p 1 μ) (G : Set α') (_ : MeasurableSet G),
    AEStronglyMeasurable (T f) ν ∧
      eLpNorm (T f) 1 (ν.restrict G)
        ≤ c * eLorentzNorm f p 1 μ * (ν G) ^ q⁻¹.toReal

variable {ε ε' : Type*}

/-- The weak continuity assumption needed for `HasRestrictedWeakType.hasLorentzType_helper`. -/
def WeaklyContinuous [TopologicalSpace ε] [ENorm ε] [SupSet ε]
  [Preorder ε] [ENorm ε'] (T : (α → ε) → (α' → ε')) (p : ℝ≥0∞) (μ : Measure α) (ν : Measure α') : Prop :=
  ∀ {fs : ℕ → SimpleFunc α ε} (_ : Monotone fs) (_ : BddAbove (range (fun n ↦ ⇑(fs n)))),
  let f := fun x ↦ ⨆ n, (fs n) x;
  ∀ (_ : MemLorentz f p 1 μ) (G : Set α'),
    eLpNorm (T f) 1 (ν.restrict G) ≤ Filter.limsup (fun n ↦ eLpNorm (T ⇑(fs n)) 1 (ν.restrict G)) Filter.atTop

theorem HasRestrictedWeakType.hasRestrictedWeakType'_nnreal [TopologicalSpace ε'] [ENormedSpace ε']
    {c : ℝ≥0} (c_pos : 0 < c) {T : (α → ℝ≥0) → α' → ε'} (p_ne_top : p ≠ ⊤) (q_ne_top : q ≠ ⊤)
    (hpq : p.HolderConjugate q)
    (T_meas : ∀ {f : α → ℝ≥0}, (MemLorentz f p 1 μ) → AEStronglyMeasurable (T f) ν)
    (T_subadd : ∀ {f g : α → ℝ≥0}, (MemLorentz f p 1 μ) → (MemLorentz g p 1 μ) →
      ∀ᵐ x ∂ν, ‖T (f + g) x‖ₑ ≤ ‖T f x‖ₑ + ‖T g x‖ₑ)
    (T_submul : ∀ (a : ℝ≥0) (f : α → ℝ≥0), ∀ᵐ x ∂ν, ‖T (a • f) x‖ₑ ≤ ‖a‖ₑ * ‖T f x‖ₑ)
    (T_ae_eq_of_ae_eq : ∀ {f g : α → ℝ≥0}, (f =ᶠ[ae μ] g) → T f =ᶠ[ae ν] T g)
    (T_zero : T 0 =ᶠ[ae ν] 0)
    (hT : HasRestrictedWeakType T p q μ ν c)
    (weakly_cont_T : WeaklyContinuous T p μ ν) :
      HasRestrictedWeakType' T p q μ ν (c / p) := by
  sorry

lemma HasRestrictedWeakType'.hasLorentzType [SigmaFinite ν]
  {𝕂 : Type*} [RCLike 𝕂] [TopologicalSpace ε'] [ENormedSpace ε']
  {T : (α → 𝕂) → (α' → ε')} (hpq : p.HolderConjugate q) (hp : p ≠ ⊤) (hq : q ≠ ⊤)
  {c : ℝ≥0∞} (hc : c ≠ ⊤) (hT : HasRestrictedWeakType' T p q μ ν c) :
    HasLorentzType T p 1 p ∞ μ ν c := by
  sorry

open RCLike in
theorem memLorentz_iff_memLorentz_embedRCLike {𝕂 : Type*} [RCLike 𝕂] {f : α → ℝ≥0} :
    MemLorentz (⇑(algebraMap ℝ 𝕂) ∘ toReal ∘ f) p q μ ↔ MemLorentz f p q μ := by
  sorry

lemma HasRestrictedWeakType'.of_hasRestrictedWeakType'_nnreal
  {𝕂 : Type*} [RCLike 𝕂] [TopologicalSpace ε'] [ENormedSpace ε']
  {T : (α → 𝕂) → (α' → ε')}
  (T_meas : ∀ {f : α → 𝕂}, (MemLorentz f p 1 μ) → AEStronglyMeasurable (T f) ν)
  (T_zero : T 0 =ᶠ[ae ν] 0)
  (T_subadd : ∀ {f g : α → 𝕂}, (MemLorentz f p 1 μ) → (MemLorentz g p 1 μ) →
    ∀ᵐ x ∂ν, ‖T (f + g) x‖ₑ ≤ ‖T f x‖ₑ + ‖T g x‖ₑ)
  (T_submul : ∀ (a : 𝕂) (f : α → 𝕂), ∀ᵐ x ∂ν, ‖T (a • f) x‖ₑ ≤ ‖a‖ₑ * ‖T f x‖ₑ)
  {c : ℝ≥0∞} (hT_nnreal : HasRestrictedWeakType' (fun f ↦ T (⇑(algebraMap ℝ 𝕂) ∘ toReal ∘ f)) p q μ ν c) :
    HasRestrictedWeakType' T p q μ ν (4 * c) := by
  sorry

lemma HasRestrictedWeakType.hasLorentzType {𝕂 : Type*}
  [RCLike 𝕂] [TopologicalSpace ε'] [ENormedSpace ε']
  {T : (α → 𝕂) → (α' → ε')} {p q : ℝ≥0∞} (hpq : p.HolderConjugate q) (p_ne_top : p ≠ ⊤) (q_ne_top : q ≠ ⊤)
  [SigmaFinite ν] {c : ℝ≥0} (c_pos : 0 < c)
  (hT : HasRestrictedWeakType T p q μ ν c)
  (T_meas : ∀ {f : α → 𝕂}, (MemLorentz f p 1 μ) → AEStronglyMeasurable (T f) ν)
  (T_subadd : ∀ {f g : α → 𝕂}, (MemLorentz f p 1 μ) → (MemLorentz g p 1 μ) →
    ∀ᵐ x ∂ν, ‖T (f + g) x‖ₑ ≤ ‖T f x‖ₑ + ‖T g x‖ₑ)
  (T_submul : ∀ (a : 𝕂) (f : α → 𝕂), ∀ᵐ (x : α') ∂ν, ‖T (a • f) x‖ₑ ≤ ‖a‖ₑ * ‖T f x‖ₑ)
  (weakly_cont_T : ∀ {f : α → 𝕂} {fs : ℕ → α → 𝕂},
                     (MemLorentz f p 1 μ) →
                     (∀ (n : ℕ), AEStronglyMeasurable (fs n) μ) →
                     (∀ (a : α), Monotone (fun n ↦ ‖fs n a‖)) →
                     (∀ (a : α), Filter.Tendsto (fun (n : ℕ) => fs n a) Filter.atTop (nhds (f a))) →
                     (G : Set α') →
    eLpNorm (T f) 1 (ν.restrict G) ≤ Filter.limsup (fun n ↦ eLpNorm (T (fs n)) 1 (ν.restrict G)) Filter.atTop)
  (T_zero : T 0 =ᶠ[ae ν] 0)
  (T_ae_eq_of_ae_eq : ∀ {f g : α → 𝕂} (_ : f =ᶠ[ae μ] g), T f =ᶠ[ae ν] T g) --TODO: incorporate into weakly_cont_T?
    :
    HasLorentzType T p 1 p ∞ μ ν (4 * c / p) := by
  sorry

end MeasureTheory
