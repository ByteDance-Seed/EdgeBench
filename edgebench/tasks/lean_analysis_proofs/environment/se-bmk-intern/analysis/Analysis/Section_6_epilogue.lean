import Mathlib.Tactic
import Analysis.Section_6_7

/-!
# Analysis I, Chapter 6 epilogue: Connections with Mathlib limits

In this (technical) epilogue, we show that various operations and properties we have defined for
"Chapter 6" sequences `Chapter6.Sequence` are equivalent to Mathlib operations.  Note however
that Mathlib's operations are defined in far greater generality than the setting of real-valued
sequences, in particular using the language of filters.

-/

open Filter

/-- Identification with the Cauchy sequence support in Mathlib/Algebra/Order/CauSeq/Basic -/
theorem Chapter6.Sequence.isCauchy_iff_isCauSeq (a: ℕ → ℝ) :
    (a:Sequence).IsCauchy ↔ IsCauSeq _root_.abs a := by
  sorry

/-- Identification with the Cauchy sequence support in Mathlib/Topology/UniformSpace/Cauchy -/
theorem Chapter6.Sequence.Cauchy_iff_CauchySeq (a: ℕ → ℝ) :
    (a:Sequence).IsCauchy ↔ CauchySeq a := by
  sorry

/-- Identification with `Filter.Tendsto` -/
theorem Chapter6.Sequence.tendsto_iff_Tendsto (a: ℕ → ℝ) (L:ℝ) :
    (a:Sequence).TendsTo L ↔ atTop.Tendsto a (nhds L) := by
  sorry

theorem Chapter6.Sequence.tendsto_iff_Tendsto' (a: Sequence) (L:ℝ) : a.TendsTo L ↔ atTop.Tendsto a.seq (nhds L) := by
  sorry

theorem Chapter6.Sequence.converges_iff_Tendsto (a: ℕ → ℝ) :
    (a:Sequence).Convergent ↔ ∃ L, atTop.Tendsto a (nhds L) := by
  sorry

/-- A technicality: `CauSeq.IsComplete` {lean}`ℝ` was established for `_root_.abs` but not for `norm`. -/
instance inst_real_complete : CauSeq.IsComplete ℝ norm := by convert Real.instIsCompleteAbs

/-- Identification with `CauSeq.lim` -/
theorem Chapter6.Sequence.lim_eq_CauSeq_lim (a:ℕ → ℝ) (ha: (a:Sequence).IsCauchy) :
    Chapter6.lim (a:Sequence) = CauSeq.lim  ⟨ a, (isCauchy_iff_isCauSeq a).mp ha⟩ := by
  sorry

/-- Identification with `limUnder` -/
theorem Chapter6.Sequence.lim_eq_limUnder (a:ℕ → ℝ) (ha: (a:Sequence).Convergent) :
    Chapter6.lim (a:Sequence) = limUnder Filter.atTop a := by
  sorry

/-- Identification with `Bornology.IsBounded` -/
theorem Chapter6.Sequence.isBounded_iff_isBounded_range (a:ℕ → ℝ):
    (a:Sequence).IsBounded ↔ Bornology.IsBounded (Set.range a) := by
  sorry

theorem Chapter6.Sequence.sup_eq_sSup (a:ℕ → ℝ):
    (a:Sequence).sup = sSup (Set.range (fun n ↦ (a n:EReal))) := by
  sorry

theorem Chapter6.Sequence.inf_eq_sInf (a:ℕ → ℝ):
    (a:Sequence).inf = sInf (Set.range (fun n ↦ (a n:EReal))) := by
  sorry

theorem Chapter6.Sequence.bddAbove_iff (a:ℕ → ℝ):
    (a:Sequence).BddAbove ↔ _root_.BddAbove (Set.range a) := by
  sorry

theorem Chapter6.Sequence.bddBelow_iff (a:ℕ → ℝ):
    (a:Sequence).BddBelow ↔ _root_.BddBelow (Set.range a) := by
  sorry

theorem Chapter6.Sequence.Monotone_iff (a:ℕ → ℝ): (a:Sequence).IsMonotone ↔ Monotone a := by
  sorry

theorem Chapter6.Sequence.Antitone_iff (a:ℕ → ℝ): (a:Sequence).IsAntitone ↔ Antitone a := by
  sorry

/-- Identification with `MapClusterPt` -/
theorem Chapter6.Sequence.limit_point_iff (a:ℕ → ℝ) (L:ℝ) :
    (a:Sequence).LimitPoint L ↔ MapClusterPt L .atTop a := by
  sorry

/-- Identification with `Filter.limsup` -/
theorem Chapter6.Sequence.limsup_eq (a:ℕ → ℝ) :
    (a:Sequence).limsup = atTop.limsup (fun n ↦ (a n:EReal)) := by
  sorry

/-- Identification with `Filter.liminf` -/
theorem Chapter6.Sequence.liminf_eq (a:ℕ → ℝ) :
    (a:Sequence).liminf = atTop.liminf (fun n ↦ (a n:EReal)) := by
  sorry

/-- Identification of `Chapter6.Real.rpow` and Mathlib exponentiation -/
theorem Chapter6.Real.rpow_eq_rpow {x:ℝ} (hx: x > 0) (α:ℝ) : rpow x α = x^α := by
  sorry
