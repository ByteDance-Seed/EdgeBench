/-
Copyright (c) 2024 James Sundstrom. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: James Sundstrom
-/
module

public import Mathlib.MeasureTheory.Constructions.BorelSpace.Metric
public import Mathlib.Order.SuccPred.IntervalSucc

/-!
# Annulus

In this file we define an annulus in a pseudometric space `X` to be a set consisting of all `y`
such that `dist x y` lies in an interval between `r` and `R`. An annulus is defined for each type
of interval (`Ioo`, `Ioc`, etc.) with a parallel naming scheme, except that we do not define annuli
for `Iio` and `Iic`, as they would be balls.

We also define `EAnnulus` similarly using `edist` instead of `dist`.

Upstreaming status: ready;
two style questions should be answered in the process (see below).

## Tags

annulus, eannulus
-/

@[expose] public section

open Set Metric ENNReal

variable {X : Type*} [PseudoMetricSpace X]

namespace Set

namespace Annulus

/-! ### Annulus -/

def oo (x : X) (r R : ℝ) := {y | dist x y ∈ Ioo r R}
def oc (x : X) (r R : ℝ) := {y | dist x y ∈ Ioc r R}
def co (x : X) (r R : ℝ) := {y | dist x y ∈ Ico r R}
def cc (x : X) (r R : ℝ) := {y | dist x y ∈ Icc r R}
def oi (x : X) (r : ℝ) := {y | dist x y ∈ Ioi r}
def ci (x : X) (r : ℝ) := {y | dist x y ∈ Ici r}

lemma oo_eq {x : X} {r R : ℝ} : oo x r R = ball x R ∩ (closedBall x r)ᶜ := by
  sorry

lemma oc_eq {x : X} {r R : ℝ} : oc x r R = closedBall x R ∩ (closedBall x r)ᶜ := by
  sorry

lemma co_eq {x : X} {r R : ℝ} : co x r R = ball x R ∩ (ball x r)ᶜ := by
  sorry

lemma cc_eq {x : X} {r R : ℝ} : cc x r R = closedBall x R ∩ (ball x r)ᶜ := by
  sorry

lemma oi_eq {x : X} {r : ℝ} : oi x r = (closedBall x r)ᶜ := by
  sorry

lemma ci_eq {x : X} {r : ℝ} : ci x r = (ball x r)ᶜ := by
  sorry

@[simp]
lemma oo_eq_empty {x : X} {r R : ℝ} (h : R ≤ r) : oo x r R = ∅ := by
  sorry

@[simp]
lemma oc_eq_empty {x : X} {r R : ℝ} (h : R ≤ r) : oc x r R = ∅ := by
  sorry

@[simp]
lemma co_eq_empty {x : X} {r R : ℝ} (h : R ≤ r) : co x r R = ∅ := by
  sorry

@[simp]
lemma cc_eq_empty {x : X} {r R : ℝ} (h : R < r) : cc x r R = ∅ := by
  sorry

@[gcongr]
lemma oo_subset_oo {x : X} {r₁ R₁ r₂ R₂ : ℝ} (hr : r₂ ≤ r₁) (hR : R₁ ≤ R₂) :
    oo x r₁ R₁ ⊆ oo x r₂ R₂ := by
  sorry

lemma oo_subset_oc {x : X} {r₁ R₁ r₂ R₂ : ℝ} (hr : r₂ ≤ r₁) (hR : R₁ ≤ R₂) :
    oo x r₁ R₁ ⊆ oc x r₂ R₂ := by
  sorry

lemma oo_subset_co {x : X} {r₁ R₁ r₂ R₂ : ℝ} (hr : r₂ ≤ r₁) (hR : R₁ ≤ R₂) :
    oo x r₁ R₁ ⊆ co x r₂ R₂ := by
  sorry

lemma oo_subset_cc {x : X} {r₁ R₁ r₂ R₂ : ℝ} (hr : r₂ ≤ r₁) (hR : R₁ ≤ R₂) :
    oo x r₁ R₁ ⊆ cc x r₂ R₂ := by
  sorry

lemma oo_subset_oi {x : X} {r₁ R₁ r₂ : ℝ} (hr : r₂ ≤ r₁) : oo x r₁ R₁ ⊆ oi x r₂ := by
  sorry

lemma oo_subset_ci {x : X} {r₁ R₁ r₂ : ℝ} (hr : r₂ ≤ r₁) : oo x r₁ R₁ ⊆ ci x r₂ := by
  sorry

lemma oc_subset_oo {x : X} {r₁ R₁ r₂ R₂ : ℝ} (hr : r₂ ≤ r₁) (hR : R₁ < R₂) :
    oc x r₁ R₁ ⊆ oo x r₂ R₂ := by
  sorry

@[gcongr]
lemma oc_subset_oc {x : X} {r₁ R₁ r₂ R₂ : ℝ} (hr : r₂ ≤ r₁) (hR : R₁ ≤ R₂) :
    oc x r₁ R₁ ⊆ oc x r₂ R₂ := by
  sorry

lemma oc_subset_co {x : X} {r₁ R₁ r₂ R₂ : ℝ} (hr : r₂ ≤ r₁) (hR : R₁ < R₂) :
    oc x r₁ R₁ ⊆ co x r₂ R₂ := by
  sorry

lemma oc_subset_cc {x : X} {r₁ R₁ r₂ R₂ : ℝ} (hr : r₂ ≤ r₁) (hR : R₁ ≤ R₂) :
    oc x r₁ R₁ ⊆ cc x r₂ R₂ := by
  sorry

lemma oc_subset_oi {x : X} {r₁ R₁ r₂ : ℝ} (hr : r₂ ≤ r₁) : oo x r₁ R₁ ⊆ oi x r₂ := by
  sorry

lemma oc_subset_ci {x : X} {r₁ R₁ r₂ : ℝ} (hr : r₂ ≤ r₁) : oc x r₁ R₁ ⊆ ci x r₂ := by
  sorry

lemma co_subset_oo {x : X} {r₁ R₁ r₂ R₂ : ℝ} (hr : r₂ < r₁) (hR : R₁ ≤ R₂) :
    co x r₁ R₁ ⊆ oo x r₂ R₂ := by
  sorry

lemma co_subset_oc {x : X} {r₁ R₁ r₂ R₂ : ℝ} (hr : r₂ < r₁) (hR : R₁ ≤ R₂) :
    co x r₁ R₁ ⊆ oc x r₂ R₂ := by
  sorry

@[gcongr]
lemma co_subset_co {x : X} {r₁ R₁ r₂ R₂ : ℝ} (hr : r₂ ≤ r₁) (hR : R₁ ≤ R₂) :
    co x r₁ R₁ ⊆ co x r₂ R₂ := by
  sorry

lemma co_subset_cc {x : X} {r₁ R₁ r₂ R₂ : ℝ} (hr : r₂ ≤ r₁) (hR : R₁ ≤ R₂) :
    co x r₁ R₁ ⊆ cc x r₂ R₂ := by
  sorry

lemma co_subset_oi {x : X} {r₁ R₁ r₂ : ℝ} (hr : r₂ < r₁) : co x r₁ R₁ ⊆ oi x r₂ := by
  sorry

lemma co_subset_ci {x : X} {r₁ R₁ r₂ : ℝ} (hr : r₂ ≤ r₁) : co x r₁ R₁ ⊆ ci x r₂ := by
  sorry

lemma cc_subset_oo {x : X} {r₁ R₁ r₂ R₂ : ℝ} (hr : r₂ < r₁) (hR : R₁ < R₂) :
    cc x r₁ R₁ ⊆ oo x r₂ R₂ := by
  sorry

lemma cc_subset_oc {x : X} {r₁ R₁ r₂ R₂ : ℝ} (hr : r₂ < r₁) (hR : R₁ ≤ R₂) :
    cc x r₁ R₁ ⊆ oc x r₂ R₂ := by
  sorry

lemma cc_subset_co {x : X} {r₁ R₁ r₂ R₂ : ℝ} (hr : r₂ ≤ r₁) (hR : R₁ < R₂) :
    cc x r₁ R₁ ⊆ co x r₂ R₂ := by
  sorry

@[gcongr]
lemma cc_subset_cc {x : X} {r₁ R₁ r₂ R₂ : ℝ} (hr : r₂ ≤ r₁) (hR : R₁ ≤ R₂) :
    cc x r₁ R₁ ⊆ cc x r₂ R₂ := by
  sorry

lemma cc_subset_oi {x : X} {r₁ R₁ r₂ : ℝ} (hr : r₂ < r₁) : cc x r₁ R₁ ⊆ oi x r₂ := by
  sorry

lemma cc_subset_ci {x : X} {r₁ R₁ r₂ : ℝ} (hr : r₂ ≤ r₁) : cc x r₁ R₁ ⊆ ci x r₂ := by
  sorry

lemma oo_subset_ball {x : X} {r R : ℝ} : oo x r R ⊆ ball x R := by
  sorry

lemma oc_subset_closedBall {x : X} {r R : ℝ} : oc x r R ⊆ closedBall x R := by
  sorry

lemma co_subset_ball {x : X} {r R : ℝ} : co x r R ⊆ ball x R := by
  sorry

lemma cc_subset_closedBall {x : X} {r R : ℝ} : cc x r R ⊆ closedBall x R := by
  sorry

@[simp]
lemma oc_union_oo {x : X} {r r' R : ℝ} (h₁ : r ≤ r') (h₂ : r' < R) :
    oc x r r' ∪ oo x r' R = oo x r R := by
  sorry

@[simp]
lemma oc_union_oc {x : X} {r r' R : ℝ} (h₁ : r ≤ r') (h₂ : r' ≤ R) :
    oc x r r' ∪ oc x r' R = oc x r R := by
  sorry

@[simp]
lemma oo_union_co {x : X} {r r' R : ℝ} (h₁ : r < r') (h₂ : r' ≤ R) :
    oo x r r' ∪ co x r' R = oo x r R := by
  sorry

@[simp]
lemma oo_union_cc {x : X} {r r' R : ℝ} (h₁ : r < r') (h₂ : r' ≤ R) :
    oo x r r' ∪ cc x r' R = oc x r R := by
  sorry

@[simp]
lemma cc_union_oo {x : X} {r r' R : ℝ} (h₁ : r ≤ r') (h₂ : r' < R) :
    cc x r r' ∪ oo x r' R = co x r R := by
  sorry

@[simp]
lemma cc_union_oc {x : X} {r r' R : ℝ} (h₁ : r ≤ r') (h₂ : r' ≤ R) :
    cc x r r' ∪ oc x r' R = cc x r R := by
  sorry

@[simp]
lemma co_union_co {x : X} {r r' R : ℝ} (h₁ : r ≤ r') (h₂ : r' ≤ R) :
    co x r r' ∪ co x r' R = co x r R := by
  sorry

@[simp]
lemma co_union_cc {x : X} {r r' R : ℝ} (h₁ : r ≤ r') (h₂ : r' ≤ R) :
    co x r r' ∪ cc x r' R = cc x r R := by
  sorry

@[simp]
lemma oc_union_oi {x : X} {r R : ℝ} (h : r ≤ R) : oc x r R ∪ oi x R = oi x r := by
  sorry

@[simp]
lemma oo_union_ci {x : X} {r R : ℝ} (h : r < R) :
    oo x r R ∪ ci x R = oi x r := by
  sorry

@[simp]
lemma cc_union_oi {x : X} {r R : ℝ} (h : r ≤ R) : cc x r R ∪ oi x R = ci x r := by
  sorry

@[simp]
lemma co_union_ci {x : X} {r R : ℝ} (h : r ≤ R) : co x r R ∪ ci x R = ci x r := by
  sorry

variable {α : Type*} [LinearOrder α]
open Order
/-- Union formula for `Set.Annulus.co x (f i) (f (Order.succ i))` over `i ∈ Ici a`. See also
`iUnion_co_map_succ_eq_ci` for the specialization `a = ⊥`. -/
theorem biUnion_Ici_co_map_succ [SuccOrder α] [IsSuccArchimedean α] {x : X} {f : α → ℝ}
    {a : α} (hf : ∀ i ∈ Ici a, f a ≤ f i) (h2f : ¬BddAbove (f '' Ici a)) :
    ⋃ i ∈ Ici a, co x (f i) (f (succ i)) = ci x (f a) := by
  sorry

/-- Union formula for `Set.Annulus.oc x (f i) (f (Order.succ i))` over `i ∈ Ici a`. See also
`iUnion_oc_map_succ_eq_oi` for the specialization `a = ⊥`. -/
theorem biUnion_Ici_oc_map_succ [SuccOrder α] [IsSuccArchimedean α] {x : X} {f : α → ℝ}
    {a : α} (hf : ∀ i ∈ Ici a, f a ≤ f i) (h2f : ¬BddAbove (f '' Ici a)) :
    ⋃ i ∈ Ici a, oc x (f i) (f (succ i)) = oi x (f a) := by
  sorry

/-- Special case `a = ⊥` of `biUnion_Ici_co_map_succ`. -/
theorem iUnion_co_map_succ_eq_ci [OrderBot α] [SuccOrder α] [IsSuccArchimedean α] {x : X}
    {f : α → ℝ} (hf : ∀ a, f ⊥ ≤ f a) (h2f : ¬BddAbove (range f)) :
    (⋃ a : α, co x (f a) (f (succ a))) = ci x (f ⊥) := by
  sorry

/-- Special case `a = ⊥` of `biUnion_Ici_oc_map_succ`. -/
theorem iUnion_oc_map_succ_eq_oi [OrderBot α] [SuccOrder α] [IsSuccArchimedean α] {x : X}
    {f : α → ℝ} (hf : ∀ a, f ⊥ ≤ f a) (h2f : ¬BddAbove (range f)) :
    (⋃ a : α, oc x (f a) (f (succ a))) = oi x (f ⊥) := by
  sorry

-- theorem iUnion_co_eq_ci {x : X} {f : ℕ → ℝ} (hf : ∀ n, f 0 ≤ f n) (h2f : ¬BddAbove (range f)) :
--     ⋃ (i : Nat), co x (f i) (f (i+1)) = ci x (f 0) := by
--   simp_rw [← Nat.bot_eq_zero, ← Nat.succ_eq_add_one]
--   exact iUnion_Ico_map_succ_eq_ci hf h2f

-- theorem iUnion_oc_eq_oi {x : X} {f : ℕ → ℝ} (hf : ∀ n, f 0 ≤ f n) (h2f : ¬BddAbove (range f)) :
--     ⋃ (i : Nat), oc x (f i) (f (i+1)) = oi x (f 0) := by
--   simp_rw [← Nat.bot_eq_zero, ← Nat.succ_eq_add_one]
--   exact iUnion_oc_map_succ_eq_oi hf h2f

variable {ι : Type*} [LinearOrder ι] [SuccOrder ι]

theorem pairwise_disjoint_on_co_succ {x : X} {f : ι → ℝ} (hf : Monotone f) :
    Pairwise (Function.onFun Disjoint fun (i : ι) => co x (f i) (f (Order.succ i))) := by
  sorry

theorem pairwise_disjoint_on_oc_succ {x : X} {f : ι → ℝ} (hf : Monotone f) :
    Pairwise (Function.onFun Disjoint fun (i : ι) => oc x (f i) (f (Order.succ i))) := by
  sorry

variable [MeasurableSpace X] [OpensMeasurableSpace X]

@[measurability]
lemma measurableSet_oo {x : X} {r R : ℝ} : MeasurableSet (oo x r R) := by
  sorry

@[measurability]
lemma measurableSet_oc {x : X} {r R : ℝ} : MeasurableSet (oc x r R) := by
  sorry

@[measurability]
lemma measurableSet_co {x : X} {r R : ℝ} : MeasurableSet (co x r R) := by
  sorry

@[measurability]
lemma measurableSet_cc {x : X} {r R : ℝ} : MeasurableSet (cc x r R) := by
  sorry

@[measurability]
lemma measurableSet_oi {x : X} {r : ℝ} : MeasurableSet (oi x r) := by
  sorry

@[measurability]
lemma measurableSet_ci {x : X} {r : ℝ} : MeasurableSet (ci x r) := by
  sorry

end Annulus

namespace EAnnulus

/-! ### EAnnulus -/

def oo (x : X) (r R : ℝ≥0∞) := {y | edist x y ∈ Ioo r R}
def oc (x : X) (r R : ℝ≥0∞) := {y | edist x y ∈ Ioc r R}
def co (x : X) (r R : ℝ≥0∞) := {y | edist x y ∈ Ico r R}
def cc (x : X) (r R : ℝ≥0∞) := {y | edist x y ∈ Icc r R}
def oi (x : X) (r : ℝ≥0∞) := {y | edist x y ∈ Ioi r}
def ci (x : X) (r : ℝ≥0∞) := {y | edist x y ∈ Ici r}

lemma oo_eq_annulus {x : X} {r R : ℝ} (hr : 0 ≤ r) :
    oo x (ENNReal.ofReal r) (ENNReal.ofReal R) = Annulus.oo x r R := by
  sorry

lemma oc_eq_annulus {x : X} {r R : ℝ} (hr : 0 ≤ r) :
    oc x (ENNReal.ofReal r) (ENNReal.ofReal R) = Annulus.oc x r R := by
  sorry

lemma co_eq_annulus {x : X} {r R : ℝ} :
    co x (ENNReal.ofReal r) (ENNReal.ofReal R) = Annulus.co x r R := by
  sorry

lemma cc_eq_annulus {x : X} {r R : ℝ} (h : 0 < r ∨ 0 ≤ R) :
    cc x (ENNReal.ofReal r) (ENNReal.ofReal R) = Annulus.cc x r R := by
  sorry

lemma oi_eq_annulus {x : X} {r : ℝ} (hr : 0 ≤ r) : oi x (ENNReal.ofReal r) = Annulus.oi x r := by
  sorry

lemma ci_eq_annulus {x : X} {r : ℝ} : ci x (ENNReal.ofReal r) = Annulus.ci x r := by
  sorry

lemma oo_eq_of_lt_top {x : X} {r R : ℝ≥0∞} (hr : r < ∞) (hR : R < ∞) :
    oo x r R = ball x R.toReal ∩ (closedBall x r.toReal)ᶜ := by
  sorry

lemma oc_eq_of_lt_top {x : X} {r R : ℝ≥0∞} (hr : r < ∞) (hR : R < ∞) :
    oc x r R = closedBall x R.toReal ∩ (closedBall x r.toReal)ᶜ := by
  sorry

lemma co_eq_of_lt_top {x : X} {r R : ℝ≥0∞} (hr : r < ∞) (hR : R < ∞) :
    co x r R = ball x R.toReal ∩ (ball x r.toReal)ᶜ := by
  sorry

lemma cc_eq_of_lt_top {x : X} {r R : ℝ≥0∞} (hr : r < ∞) (hR : R < ∞) :
    cc x r R = closedBall x R.toReal ∩ (ball x r.toReal)ᶜ := by
  sorry

lemma oi_eq_of_lt_top {x : X} {r : ℝ≥0∞} (hr : r < ∞) : oi x r = (closedBall x r.toReal)ᶜ := by
  sorry

lemma ci_eq_of_lt_top {x : X} {r : ℝ≥0∞} (hr : r < ∞) : ci x r = (ball x r.toReal)ᶜ := by
  sorry

@[simp]
lemma oo_eq_empty {x : X} {r R : ℝ≥0∞} (h : R ≤ r) : oo x r R = ∅ := by
  sorry

@[simp]
lemma oc_eq_empty {x : X} {r R : ℝ≥0∞} (h : R ≤ r) : oc x r R = ∅ := by
  sorry

@[simp]
lemma co_eq_empty {x : X} {r R : ℝ≥0∞} (h : R ≤ r) : co x r R = ∅ := by
  sorry

@[simp]
lemma cc_eq_empty {x : X} {r R : ℝ≥0∞} (h : R < r) : cc x r R = ∅ := by
  sorry

@[simp]
lemma cc_top_eq_empty {x : X} {R : ℝ≥0∞} : cc x ∞ R = ∅ := by
  sorry

@[simp]
lemma oi_eq_empty {x : X} : oi x ∞ = ∅ := by
  sorry

@[simp]
lemma ci_eq_empty {x : X} : ci x ∞ = ∅ := by
  sorry

lemma oo_eq_of_top {x : X} {r : ℝ≥0∞} (hr : r < ∞) :
    oo x r ∞ = (closedBall x r.toReal)ᶜ := by
  sorry

lemma oc_eq_of_top {x : X} {r : ℝ≥0∞} (hr : r < ∞) :
    oc x r ∞ = (closedBall x r.toReal)ᶜ := by
  sorry

lemma co_eq_of_top {x : X} {r : ℝ≥0∞} (hr : r < ∞) : co x r ∞ = (ball x r.toReal)ᶜ := by
  sorry

lemma cc_eq_of_top {x : X} {r : ℝ≥0∞} (hr : r < ∞) : cc x r ∞ = (ball x r.toReal)ᶜ := by
  sorry

@[gcongr]
lemma oo_subset_oo {x : X} {r₁ R₁ r₂ R₂ : ℝ≥0∞} (hr : r₂ ≤ r₁) (hR : R₁ ≤ R₂) :
    oo x r₁ R₁ ⊆ oo x r₂ R₂ := by
  sorry

lemma oo_subset_oc {x : X} {r₁ R₁ r₂ R₂ : ℝ≥0∞} (hr : r₂ ≤ r₁) (hR : R₁ ≤ R₂) :
    oo x r₁ R₁ ⊆ oc x r₂ R₂ := by
  sorry

lemma oo_subset_co {x : X} {r₁ R₁ r₂ R₂ : ℝ≥0∞} (hr : r₂ ≤ r₁) (hR : R₁ ≤ R₂) :
    oo x r₁ R₁ ⊆ co x r₂ R₂ := by
  sorry

lemma oo_subset_cc {x : X} {r₁ R₁ r₂ R₂ : ℝ≥0∞} (hr : r₂ ≤ r₁) (hR : R₁ ≤ R₂) :
    oo x r₁ R₁ ⊆ cc x r₂ R₂ := by
  sorry

lemma oo_subset_oi {x : X} {r₁ R₁ r₂ : ℝ≥0∞} (hr : r₂ ≤ r₁) : oo x r₁ R₁ ⊆ oi x r₂ := by
  sorry

lemma oo_subset_ci {x : X} {r₁ R₁ r₂ : ℝ≥0∞} (hr : r₂ ≤ r₁) : oo x r₁ R₁ ⊆ ci x r₂ := by
  sorry

lemma oc_subset_oo {x : X} {r₁ R₁ r₂ R₂ : ℝ≥0∞} (hr : r₂ ≤ r₁) (hR : R₁ < R₂) :
    oc x r₁ R₁ ⊆ oo x r₂ R₂ := by
  sorry

@[gcongr]
lemma oc_subset_oc {x : X} {r₁ R₁ r₂ R₂ : ℝ≥0∞} (hr : r₂ ≤ r₁) (hR : R₁ ≤ R₂) :
    oc x r₁ R₁ ⊆ oc x r₂ R₂ := by
  sorry

lemma oc_subset_co {x : X} {r₁ R₁ r₂ R₂ : ℝ≥0∞} (hr : r₂ ≤ r₁) (hR : R₁ < R₂) :
    oc x r₁ R₁ ⊆ co x r₂ R₂ := by
  sorry

lemma oc_subset_cc {x : X} {r₁ R₁ r₂ R₂ : ℝ≥0∞} (hr : r₂ ≤ r₁) (hR : R₁ ≤ R₂) :
    oc x r₁ R₁ ⊆ cc x r₂ R₂ := by
  sorry

lemma oc_subset_oi {x : X} {r₁ R₁ r₂ : ℝ≥0∞} (hr : r₂ ≤ r₁) : oo x r₁ R₁ ⊆ oi x r₂ := by
  sorry

lemma oc_subset_ci {x : X} {r₁ R₁ r₂ : ℝ≥0∞} (hr : r₂ ≤ r₁) : oc x r₁ R₁ ⊆ ci x r₂ := by
  sorry

lemma co_subset_oo {x : X} {r₁ R₁ r₂ R₂ : ℝ≥0∞} (hr : r₂ < r₁) (hR : R₁ ≤ R₂) :
    co x r₁ R₁ ⊆ oo x r₂ R₂ := by
  sorry

lemma co_subset_oc {x : X} {r₁ R₁ r₂ R₂ : ℝ≥0∞} (hr : r₂ < r₁) (hR : R₁ ≤ R₂) :
    co x r₁ R₁ ⊆ oc x r₂ R₂ := by
  sorry

@[gcongr]
lemma co_subset_co {x : X} {r₁ R₁ r₂ R₂ : ℝ≥0∞} (hr : r₂ ≤ r₁) (hR : R₁ ≤ R₂) :
    co x r₁ R₁ ⊆ co x r₂ R₂ := by
  sorry

lemma co_subset_cc {x : X} {r₁ R₁ r₂ R₂ : ℝ≥0∞} (hr : r₂ ≤ r₁) (hR : R₁ ≤ R₂) :
    co x r₁ R₁ ⊆ cc x r₂ R₂ := by
  sorry

lemma co_subset_oi {x : X} {r₁ R₁ r₂ : ℝ≥0∞} (hr : r₂ < r₁) : co x r₁ R₁ ⊆ oi x r₂ := by
  sorry

lemma co_subset_ci {x : X} {r₁ R₁ r₂ : ℝ≥0∞} (hr : r₂ ≤ r₁) : co x r₁ R₁ ⊆ ci x r₂ := by
  sorry

lemma cc_subset_oo {x : X} {r₁ R₁ r₂ R₂ : ℝ≥0∞} (hr : r₂ < r₁) (hR : R₁ < R₂) :
    cc x r₁ R₁ ⊆ oo x r₂ R₂ := by
  sorry

lemma cc_subset_oc {x : X} {r₁ R₁ r₂ R₂ : ℝ≥0∞} (hr : r₂ < r₁) (hR : R₁ ≤ R₂) :
    cc x r₁ R₁ ⊆ oc x r₂ R₂ := by
  sorry

lemma cc_subset_co {x : X} {r₁ R₁ r₂ R₂ : ℝ≥0∞} (hr : r₂ ≤ r₁) (hR : R₁ < R₂) :
    cc x r₁ R₁ ⊆ co x r₂ R₂ := by
  sorry

@[gcongr]
lemma cc_subset_cc {x : X} {r₁ R₁ r₂ R₂ : ℝ≥0∞} (hr : r₂ ≤ r₁) (hR : R₁ ≤ R₂) :
    cc x r₁ R₁ ⊆ cc x r₂ R₂ := by
  sorry

lemma cc_subset_oi {x : X} {r₁ R₁ r₂ : ℝ≥0∞} (hr : r₂ < r₁) : cc x r₁ R₁ ⊆ oi x r₂ := by
  sorry

lemma cc_subset_ci {x : X} {r₁ R₁ r₂ : ℝ≥0∞} (hr : r₂ ≤ r₁) : cc x r₁ R₁ ⊆ ci x r₂ := by
  sorry

@[simp]
lemma oc_union_oo {x : X} {r r' R : ℝ≥0∞} (h₁ : r ≤ r') (h₂ : r' < R) :
    oc x r r' ∪ oo x r' R = oo x r R := by
  sorry

@[simp]
lemma oc_union_oc {x : X} {r r' R : ℝ≥0∞} (h₁ : r ≤ r') (h₂ : r' ≤ R) :
    oc x r r' ∪ oc x r' R = oc x r R := by
  sorry

@[simp]
lemma oo_union_co {x : X} {r r' R : ℝ≥0∞} (h₁ : r < r') (h₂ : r' ≤ R) :
    oo x r r' ∪ co x r' R = oo x r R := by
  sorry

@[simp]
lemma oo_union_cc {x : X} {r r' R : ℝ≥0∞} (h₁ : r < r') (h₂ : r' ≤ R) :
    oo x r r' ∪ cc x r' R = oc x r R := by
  sorry

@[simp]
lemma cc_union_oo {x : X} {r r' R : ℝ≥0∞} (h₁ : r ≤ r') (h₂ : r' < R) :
    cc x r r' ∪ oo x r' R = co x r R := by
  sorry

@[simp]
lemma cc_union_oc {x : X} {r r' R : ℝ≥0∞} (h₁ : r ≤ r') (h₂ : r' ≤ R) :
    cc x r r' ∪ oc x r' R = cc x r R := by
  sorry

@[simp]
lemma co_union_co {x : X} {r r' R : ℝ≥0∞} (h₁ : r ≤ r') (h₂ : r' ≤ R) :
    co x r r' ∪ co x r' R = co x r R := by
  sorry

@[simp]
lemma co_union_cc {x : X} {r r' R : ℝ≥0∞} (h₁ : r ≤ r') (h₂ : r' ≤ R) :
    co x r r' ∪ cc x r' R = cc x r R := by
  sorry

@[simp]
lemma oc_union_oi {x : X} {r R : ℝ≥0∞} (h : r ≤ R) : oc x r R ∪ oi x R = oi x r := by
  sorry

@[simp]
lemma oo_union_ci {x : X} {r R : ℝ≥0∞} (h : r < R) :
    oo x r R ∪ ci x R = oi x r := by
  sorry

@[simp]
lemma cc_union_oi {x : X} {r R : ℝ≥0∞} (h : r ≤ R) : cc x r R ∪ oi x R = ci x r := by
  sorry

@[simp]
lemma co_union_ci {x : X} {r R : ℝ≥0∞} (h : r ≤ R) : co x r R ∪ ci x R = ci x r := by
  sorry

variable [MeasurableSpace X] [OpensMeasurableSpace X]

@[measurability]
lemma measurableSet_oo {x : X} {r R : ℝ≥0∞} : MeasurableSet (oo x r R) := by
  sorry

@[measurability]
lemma measurableSet_oc {x : X} {r R : ℝ≥0∞} : MeasurableSet (oc x r R) := by
  sorry

@[measurability]
lemma measurableSet_co {x : X} {r R : ℝ≥0∞} : MeasurableSet (co x r R) := by
  sorry

@[measurability]
lemma measurableSet_cc {x : X} {r R : ℝ≥0∞} : MeasurableSet (cc x r R) := by
  sorry

@[measurability]
lemma measurableSet_oi {x : X} {r : ℝ≥0∞} : MeasurableSet (oi x r) := by
  sorry

@[measurability]
lemma measurableSet_ci {x : X} {r : ℝ≥0∞} : MeasurableSet (ci x r) := by
  sorry

end EAnnulus

end Set
