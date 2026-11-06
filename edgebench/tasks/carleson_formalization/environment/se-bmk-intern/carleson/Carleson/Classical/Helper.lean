module

public import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic

public section

/- This file contains helper lemmas. Either they should be replaced by a mathlib version if there is
   one or they might be candidates to go there, possibly in a generalized form. -/

open MeasureTheory

lemma intervalIntegral.integral_conj' {μ : Measure ℝ} {𝕜 : Type*} [RCLike 𝕜] {f : ℝ → 𝕜} {a b : ℝ} :
    ∫ x in a..b, (starRingEnd 𝕜) (f x) ∂μ = (starRingEnd 𝕜) (∫ x in a..b, f x ∂μ) := by
  sorry

lemma intervalIntegrable_of_bdd {a b : ℝ} {δ : ℝ} {g : ℝ → ℂ} (measurable_g : Measurable g)
    (bddg : ∀ x, ‖g x‖ ≤ δ) : IntervalIntegrable g volume a b := by
  sorry

lemma IntervalIntegrable.bdd_mul {F : Type*} [NormedDivisionRing F] {f g : ℝ → F} {a b : ℝ}
    {μ : Measure ℝ} (hg : IntervalIntegrable g μ a b) (hm : AEStronglyMeasurable f μ)
    (hfbdd : ∃ C, ∀ x, ‖f x‖ ≤ C) : IntervalIntegrable (fun x ↦ f x * g x) μ a b := by
  sorry

lemma IntervalIntegrable.mul_bdd {F : Type*} [NormedField F] {f g : ℝ → F} {a b : ℝ}
    {μ : Measure ℝ} (hf : IntervalIntegrable f μ a b) (hm : AEStronglyMeasurable g μ)
    (hgbdd : ∃ C, ∀ x, ‖g x‖ ≤ C) : IntervalIntegrable (fun x ↦ f x * g x) μ a b := by
  sorry

lemma IntegrableOn.sub {α : Type*} {β : Type*} {m : MeasurableSpace α} {μ : Measure α}
    [NormedAddCommGroup β] {s : Set α} {f g : α → β}
    (hf : IntegrableOn f s μ) (hg : IntegrableOn g s μ) : IntegrableOn (f - g) s μ := by
  sorry

lemma ConditionallyCompleteLattice.le_biSup {α : Type*} [ConditionallyCompleteLinearOrder α]
    {ι : Type*} {f : ι → α} {s : Set ι} {a : α} (hfs : BddAbove (f '' s)) (ha : ∃ i ∈ s, f i = a) :
    a ≤ ⨆ i ∈ s, f i := by
  sorry

/- Adapted from mathlib Function.Periodic.exists_mem_Ico₀ -/
theorem Function.Periodic.exists_mem_Ico₀' {α β : Type*} {f : α → β} {c : α}
    [AddCommGroup α] [LinearOrder α] [IsOrderedAddMonoid α] [Archimedean α]
    (h : Periodic f c) (hc : 0 < c) (x : α) :
    ∃ (n : ℤ), (x - n • c) ∈ Set.Ico 0 c ∧ f x = f (x - n • c) := by
  sorry

/- Adapted from mathlib Function.Periodic.exists_mem_Ico₀ -/
theorem Function.Periodic.exists_mem_Ico' {α β : Type*} {f : α → β} {c : α}
    [AddCommGroup α] [LinearOrder α] [IsOrderedAddMonoid α] [Archimedean α]
    (h : Periodic f c) (hc : 0 < c) (x a : α) :
    ∃ (n : ℤ), (x - n • c) ∈ Set.Ico a (a + c) ∧ f x = f (x - n • c) := by
  sorry
