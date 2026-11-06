module

public import Mathlib.MeasureTheory.Function.EssSup

--Upstreaming status: proofs might be shortened, otherwiseready

public section

open MeasureTheory ENNReal

lemma essSup_le_iSup {α : Type*} {β : Type*} {m : MeasurableSpace α} {μ : Measure α}
  [CompleteLattice β] {f : α → β} :
    essSup f μ ≤ ⨆ i, f i := by
  sorry

lemma iSup_le_essSup {α : Type*} {β : Type*} {m : MeasurableSpace α} {μ : Measure α}
  [CompleteLinearOrder β] {f : α → β} (h : ∀ ⦃x⦄, ∀ ⦃a⦄, a < f x → μ {y | a < f y} ≠ 0) :
    ⨆ x, f x ≤ essSup f μ := by
  sorry
