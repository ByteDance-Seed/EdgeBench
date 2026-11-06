module

public import Mathlib.MeasureTheory.Measure.Lebesgue.Basic

public section

-- Upstreaming status: ready to go
-- Remaining lemmas: shift/scaling aliases, `lintegral_set_mono_fn`
-- (already `setLIntegral_mono'` in mathlib).

open NNReal ENNReal MeasureTheory Set

variable {α α' : Type*} {m : MeasurableSpace α} {m' : MeasurableSpace α'}
  {p p' q p₀ q₀ p₁ q₁ : ℝ≥0∞} {c : ℝ≥0} {μ : Measure α}

/-! ## Some tools for measure theory computations
    A collection of small lemmas to help with integral manipulations.
-/
namespace MeasureTheory

lemma measure_preserving_shift {a : ℝ} :
    MeasurePreserving (fun x ↦ a + x) volume volume := by
  sorry

lemma measureable_embedding_shift {a : ℝ} : MeasurableEmbedding (fun x ↦ a + x) := by
  sorry

lemma measure_preserving_scaling {a : ℝ} (ha : a ≠ 0) :
    MeasurePreserving (fun x ↦ a * x) volume ((ENNReal.ofReal |a⁻¹|) • volume) := by
  sorry

lemma lintegral_shift (f : ℝ → ENNReal) {a : ℝ} :
    ∫⁻ x : ℝ, (f (x + a)) = ∫⁻ x : ℝ, f x := by
  sorry

lemma lintegral_shift' (f : ℝ → ENNReal) {a : ℝ} {s : Set ℝ} :
    ∫⁻ (x : ℝ) in (fun z : ℝ ↦ z + a)⁻¹' s, f (x + a) = ∫⁻ (x : ℝ) in s, f x := by
  sorry

lemma lintegral_add_right_Ioi (f : ℝ → ENNReal) {a b : ℝ} :
    ∫⁻ (x : ℝ) in Ioi (b - a), f (x + a) = ∫⁻ (x : ℝ) in Ioi b, f x := by
  sorry

lemma lintegral_scale_constant (f : ℝ → ENNReal) {a : ℝ} (h : a ≠ 0) :
    ∫⁻ x : ℝ, f (a*x) = ENNReal.ofReal |a⁻¹| * ∫⁻ x, f x := by
  sorry

lemma lintegral_scale_constant_preimage (f : ℝ → ENNReal) {a : ℝ} (h : a ≠ 0) {s : Set ℝ} :
    ∫⁻ x : ℝ in (fun z : ℝ ↦ a * z)⁻¹' s, f (a*x) = ENNReal.ofReal |a⁻¹| * ∫⁻ x : ℝ in s, f x := by
  sorry

lemma lintegral_scale_constant_halfspace (f : ℝ → ENNReal) {a : ℝ} (h : 0 < a) :
    ∫⁻ x : ℝ in Ioi 0, f (a*x) = ENNReal.ofReal |a⁻¹| * ∫⁻ x : ℝ in Ioi 0, f x := by
  sorry

lemma lintegral_scale_constant_halfspace' {f : ℝ → ENNReal} {a : ℝ} (h : 0 < a) :
    ENNReal.ofReal |a| * ∫⁻ x : ℝ in Ioi 0, f (a*x) = ∫⁻ x : ℝ in Ioi 0, f x := by
  sorry

lemma lintegral_scale_constant' {f : ℝ → ENNReal} {a : ℝ} (h : a ≠ 0) :
    ENNReal.ofReal |a| * ∫⁻ x : ℝ, f (a*x) = ∫⁻ x, f x := by
  sorry

open SimpleFunc

lemma lintegral_set_mono_fn {α : Type*} {m : MeasurableSpace α} {μ : Measure α} {s : Set α}
    (hs : MeasurableSet s) ⦃f g : α → ℝ≥0∞⦄ (hfg : ∀ x ∈ s, f x ≤ g x) :
    ∫⁻ (a : α) in s, f a ∂μ ≤ ∫⁻ (a : α) in s, g a ∂μ := by
  sorry

end MeasureTheory
