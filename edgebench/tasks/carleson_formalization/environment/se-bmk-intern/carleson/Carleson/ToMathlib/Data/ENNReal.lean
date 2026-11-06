module

public import Mathlib.Analysis.Normed.Group.Bounded
public import Mathlib.Analysis.Normed.Group.Uniform
public import Mathlib.Analysis.Normed.Ring.Basic
public import Mathlib.Order.CompletePartialOrder

-- Upstreaming status: lemmas seem useful; proofs may need some polish.
-- At least three or four distinct PRs.

/-! ## `ENNReal` manipulation lemmas -/

public section

open Function Set Bornology
open scoped NNReal

variable {α ι : Type*} {s : Set ι} {t : Finset α}

namespace ENNReal

attribute [simp] ofReal_of_nonpos
-- protect ENNReal.mul_le_mul_left

theorem coe_lt_iff_lt_toNNReal {a : ℝ≥0∞} {t : ℝ≥0} (ha : a ≠ ⊤) :
    t < a ↔ t < a.toNNReal := by
  sorry

theorem le_mul_top_self {x : ℝ≥0∞} : x ≤ ⊤ * x := by
  sorry

lemma coe_biSup {f : ι → ℝ≥0} (hf : BddAbove (range f)) :
    ⨆ x ∈ s, f x = ⨆ x ∈ s, (f x : ℝ≥0∞) := by
  sorry

-- unused
lemma biSup_add_biSup {f g : ι → ℝ≥0∞} (h : ∀ i ∈ s, ∀ j ∈ s, ∃ k ∈ s, f i + g j ≤ f k + g k) :
    (⨆ i ∈ s, f i) + ⨆ i ∈ s, g i = ⨆ i ∈ s, f i + g i := by
  sorry

-- unused
lemma finsetSum_biSup {f : α → ι → ℝ≥0∞}
    (hf : ∀ i ∈ s, ∀ j ∈ s, ∃ k ∈ s, ∀ a, f a i ≤ f a k ∧ f a j ≤ f a k) :
    ∑ a ∈ t, ⨆ i ∈ s, f a i = ⨆ i ∈ s, ∑ a ∈ t, f a i := by
  sorry

lemma biSup_add_le_add_biSup {f g : ι → ℝ≥0∞} :
    ⨆ i ∈ s, f i + g i ≤ (⨆ i ∈ s, f i) + ⨆ i ∈ s, g i := by
  sorry

lemma biSup_finsetSum_le_finsetSum_biSup {f : α → ι → ℝ≥0∞} :
    ⨆ i ∈ s, ∑ a ∈ t, f a i ≤ ∑ a ∈ t, ⨆ i ∈ s, f a i := by
  sorry

variable {E : Type*} [SeminormedAddCommGroup E]

lemma edist_sum_le_sum_edist {f g : α → E} : edist (∑ i ∈ t, f i) (∑ i ∈ t, g i) ≤
    ∑ i ∈ t, edist (f i) (g i) := by
  sorry

lemma enorm_sum_eq_sum_enorm {f : α → ℝ} (hf : ∀ i ∈ t, 0 ≤ f i) :
    ‖∑ i ∈ t, f i‖ₑ = ∑ i ∈ t, ‖f i‖ₑ := by
  sorry

/-- The reverse triangle inequality for `enorm`. -/
-- TODO: does a seminormed abelian additive group also have an ENormedAddMonoid structure?
lemma enorm_enorm_sub_enorm_le {E} [NormedAddCommGroup E] {x y : E} : ‖‖x‖ₑ - ‖y‖ₑ‖ₑ ≤ ‖x - y‖ₑ := by
  sorry

lemma exists_biSup_le_enorm_add_eps
    {f : ι → E} {ε : ℝ≥0} (εpos : 0 < ε) (hs : s.Nonempty) (hf : IsBounded (f '' s)) :
    ∃ x ∈ s, ⨆ z ∈ s, ‖f z‖ₑ ≤ ‖f x‖ₑ + ε := by
  sorry

lemma exists_enorm_sub_eps_le_biInf
    {f : ι → E} {ε : ℝ≥0} (εpos : 0 < ε) (hs : s.Nonempty) :
    ∃ x ∈ s, ‖f x‖ₑ - ε ≤ ⨅ z ∈ s, ‖f z‖ₑ := by
  sorry

lemma biInf_enorm_sub_le {f g : ι → E} :
    ⨅ x ∈ s, ‖f x - g x‖ₑ ≤ (⨅ x ∈ s, ‖f x‖ₑ) + (⨆ x ∈ s, ‖g x‖ₑ) := by
  sorry

end ENNReal

/-- Transfer an inequality over `ℝ` to one of `ENorm`s over `ℝ≥0∞`. -/
lemma Real.enorm_le_enorm {x y : ℝ} (hx : 0 ≤ x) (hy : x ≤ y) : ‖x‖ₑ ≤ ‖y‖ₑ := by
  sorry
