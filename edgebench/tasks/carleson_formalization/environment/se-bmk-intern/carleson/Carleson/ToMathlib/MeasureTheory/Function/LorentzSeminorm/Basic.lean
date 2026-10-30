module

public import Carleson.ToMathlib.MeasureTheory.Function.EssSup
public import Carleson.ToMathlib.MeasureTheory.Function.LpSeminorm.Basic
public import Carleson.ToMathlib.MeasureTheory.Function.LorentzSeminorm.Defs
public import Carleson.ToMathlib.RealInterpolation.Misc
public import Carleson.ToMathlib.Topology.ContinuousOn
public import Carleson.ToMathlib.Analysis.SpecialFunctions.ImproperIntegrals
public import Carleson.ToMathlib.Analysis.SpecialFunctions.Integrals.Basic

/- Upstreaming status: still needs some cleanup, and more analogues to mathlib lemmas about eLpNorm
could be added -/

public section

noncomputable section

open TopologicalSpace MeasureTheory Filter

open scoped NNReal ENNReal Topology

variable {α ε ε' : Type*} {m m0 : MeasurableSpace α} {p q : ℝ≥0∞} {μ : Measure α} [ENorm ε]
  [ENorm ε']

namespace MeasureTheory

lemma eLorentzNorm'_mono_enorm_ae {f : α → ε'} {g : α → ε} (h : ∀ᵐ (x : α) ∂μ, ‖f x‖ₑ ≤ ‖g x‖ₑ) :
    eLorentzNorm' f p q μ ≤ eLorentzNorm' g p q μ := by
  sorry

lemma eLorentzNorm_mono_enorm_ae {f : α → ε'} {g : α → ε} (h : ∀ᵐ (x : α) ∂μ, ‖f x‖ₑ ≤ ‖g x‖ₑ) :
    eLorentzNorm f p q μ ≤ eLorentzNorm g p q μ := by
  sorry

--Proof analogous to eLpNorm_congr_enorm_ae
theorem eLorentzNorm_congr_enorm_ae {f : α → ε'} {g : α → ε} (hfg : ∀ᵐ x ∂μ, ‖f x‖ₑ = ‖g x‖ₑ) :
    eLorentzNorm f p q μ = eLorentzNorm g p q μ := by
  sorry

--Proof analogous to eLpNorm_congr_ae
theorem eLorentzNorm_congr_ae {f g : α → ε'} (hfg : f =ᵐ[μ] g) :
    eLorentzNorm f p q μ = eLorentzNorm g p q μ := by
  sorry

@[simp]
theorem eLorentzNorm_enorm (f : α → ε) : eLorentzNorm (fun x ↦ ‖f x‖ₑ) p q μ = eLorentzNorm f p q μ := by
  sorry

variable {ε : Type*} [TopologicalSpace ε]

lemma eLorentzNorm'_eq_zero_of_ae_enorm_zero [ESeminormedAddMonoid ε] {f : α → ε}
  (h : enorm ∘ f =ᵐ[μ] 0) (p_ne_zero : p ≠ 0) (p_ne_top : p ≠ ⊤) :
    eLorentzNorm' f p q μ = 0 := by
  sorry

lemma eLorentzNorm_eq_zero_of_ae_enorm_zero [ESeminormedAddMonoid ε] {f : α → ε} (h : enorm ∘ f =ᵐ[μ] 0) :
    eLorentzNorm f p q μ = 0 := by
  sorry

lemma eLorentzNorm'_eq_zero_of_ae_zero [ESeminormedAddMonoid ε] {f : α → ε}
    (p_ne_zero : p ≠ 0) (p_ne_top : p ≠ ⊤) (h : f =ᵐ[μ] 0) :
    eLorentzNorm' f p q μ = 0 := by
  sorry

lemma eLorentzNorm_eq_zero_of_ae_zero [ESeminormedAddMonoid ε] {f : α → ε} (h : f =ᵐ[μ] 0) :
    eLorentzNorm f p q μ = 0 := by
  sorry

section ENormedAddMonoid -- TODO: do all of these results require positive definiteness?

variable {ε : Type*} [TopologicalSpace ε] [ENormedAddMonoid ε]

theorem ae_eq_zero_of_eLorentzNorm'_eq_zero {f : α → ε} (p_ne_zero : p ≠ 0) (p_ne_top : p ≠ ⊤)
  (q_ne_zero : q ≠ 0) (h : eLorentzNorm' f p q μ = 0) :
    f =ᵐ[μ] 0 := by
  sorry

theorem eLorentzNorm'_eq_zero_iff {f : α → ε}
  (p_ne_zero : p ≠ 0) (p_ne_top : p ≠ ⊤) (q_ne_zero : q ≠ 0) :
    eLorentzNorm' f p q μ = 0 ↔ f =ᵐ[μ] 0 := by
  sorry

theorem eLorentzNorm_eq_zero_iff {f : α → ε}
  (p_ne_zero : p ≠ 0) (q_ne_zero : q ≠ 0) :
    eLorentzNorm f p q μ = 0 ↔ f =ᵐ[μ] 0 := by
  sorry

end ENormedAddMonoid

variable [ESeminormedAddMonoid ε]

@[simp]
lemma eLorentzNorm_zero : eLorentzNorm (0 : α → ε) p q μ = 0 := by
  sorry

@[simp]
lemma eLorentzNorm_zero' : eLorentzNorm (fun _ : α ↦  (0 : ε)) p q μ = 0 := by
  sorry

lemma eLorentzNorm_eq_eLpNorm {f : α → ε} (hf : AEStronglyMeasurable f μ) :
  eLorentzNorm f p p μ = eLpNorm f p μ := by
  sorry

lemma eLorentzNorm'_eq_wnorm (p_ne_top : p ≠ ∞) {f : α → ε} {μ : Measure α} :
    eLorentzNorm' f p ∞ μ = wnorm f p μ := by
  sorry

lemma eLorentzNorm_eq_wnorm (p_ne_zero : p ≠ 0) {f : α → ε} {μ : Measure α} :
    eLorentzNorm f p ∞ μ = wnorm f p μ := by
  sorry

--Theorem 6.6 in https://doi.org/10.1007/978-3-319-30034-4
lemma eLorentzNorm'_eq (p_nonzero : p ≠ 0) (p_ne_top : p ≠ ⊤) {f : α → ε} {μ : Measure α} :
  eLorentzNorm' f p q μ
    = eLpNorm (fun (t : ℝ≥0) ↦ t ^ p⁻¹.toReal * rearrangement f t μ) q
        (volume.withDensity (fun (t : ℝ≥0) ↦ t⁻¹)) := by
  sorry

lemma eLorentzNorm'_eq' (p_nonzero : p ≠ 0) (p_ne_top : p ≠ ⊤) {f : α → ε} {μ : Measure α} :
  eLorentzNorm' f p q μ
    = eLpNorm (fun (t : ℝ≥0) ↦ t ^ (p⁻¹.toReal - q⁻¹.toReal) * rearrangement f t μ) q := by
  sorry

--TODO: remove this?
lemma eLorentzNorm_eq (p_nonzero : p ≠ 0) (p_ne_top : p ≠ ⊤) {f : α → ε} :
  eLorentzNorm f p q μ
    = eLpNorm (fun (t : ℝ≥0) ↦ t ^ p⁻¹.toReal * rearrangement f t μ) q
        (volume.withDensity (fun (t : ℝ≥0) ↦ t⁻¹)) := by
  sorry

lemma eLorentzNorm'_indicator_const {a : ε} (ha : ‖a‖ₑ ≠ ⊤)
  {s : Set α} (p_ne_zero : p ≠ 0) (p_ne_top : p ≠ ⊤) :
    eLorentzNorm' (s.indicator (Function.const α a)) p 1 μ = p * (‖a‖ₑ * μ s ^ p⁻¹.toReal) := by
  sorry

lemma eLorentzNorm'_indicator_const' {a : ε} {s : Set α} (p_ne_zero : p ≠ 0) (p_ne_top : p ≠ ⊤)
  (q_ne_zero : q ≠ 0) (q_ne_top : q ≠ ⊤) :
    eLorentzNorm' (s.indicator (Function.const α a)) p q μ
      = (p / q) ^ q.toReal⁻¹ * μ s ^ p.toReal⁻¹ * ‖a‖ₑ := by
  sorry

@[simp]
lemma eLorentzNorm_indicator_const {a : ε} {s : Set α} :
  eLorentzNorm (s.indicator (Function.const α a)) p q μ
    = if p = 0 then 0
      else if q = 0 then 0
      else if p = ∞ then
        (if μ s = 0 then 0 else if q = ∞ then ‖a‖ₑ else ∞ * ‖a‖ₑ)
      else if q = ∞ then
        μ s ^ p.toReal⁻¹ * ‖a‖ₑ
      else
        (p / q) ^ q.toReal⁻¹ * μ s ^ p.toReal⁻¹ * ‖a‖ₑ := by
  sorry

lemma MemLorentz_iff_MemLp {f : α → ε} :
    MemLorentz f p p μ ↔ MemLp f p μ := by
  sorry

-- TODO: could maybe be strengthened to ↔
lemma MemLorentz_of_MemLorentz_ge {r₁ r₂ : ℝ≥0∞} (r₁_pos : 0 < r₁) (r₁_le_r₂ : r₁ ≤ r₂) {f : α → ε}
  (hf : MemLorentz f p r₁ μ) :
    MemLorentz f p r₂ μ := by
  sorry

lemma MemLorentz.memLp {f : α → ε} (hf : MemLorentz f p q μ) (h : q ∈ Set.Ioc 0 p) :
    MemLp f p μ := by
  sorry

end MeasureTheory
