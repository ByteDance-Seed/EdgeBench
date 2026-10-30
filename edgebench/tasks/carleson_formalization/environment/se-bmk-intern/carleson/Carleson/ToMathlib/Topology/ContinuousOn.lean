module

public import Mathlib.Analysis.SpecialFunctions.Pow.Continuity
public import Mathlib.MeasureTheory.Measure.OpenPos
public import Mathlib.MeasureTheory.Function.LpSeminorm.Defs
public import Carleson.ToMathlib.MeasureTheory.Function.EssSup
public import Carleson.ToMathlib.MeasureTheory.Measure.NNReal

--Upstreaming status: some results should probably be generalized, see TODOs

public section

open NNReal ENNReal

theorem ContinuousWithinAt.ennreal_mul {X : Type*}
  [TopologicalSpace X] {f g : X → ℝ≥0∞} {s : Set X} {t : X} (hf : ContinuousWithinAt f s t)
  (hg : ContinuousWithinAt g s t) (h₁ : f t ≠ 0 ∨ g t ≠ ∞) (h₂ : g t ≠ 0 ∨ f t ≠ ∞) :
    ContinuousWithinAt (fun x ↦ f x * g x) s t := by
  sorry

open MeasureTheory

--TODO: generalize?
lemma ContinuousWithinAt.measure_lt_ne_zero {α : Type*} {m : MeasurableSpace α} {μ : Measure α}
  [TopologicalSpace α] [LinearOrder α] [DenselyOrdered α]
  [OrderTopology α] [ClosedIicTopology α] [μ.IsOpenPosMeasure] {f : α → ℝ≥0∞} {x : α}
  (hx : ¬IsMax x) (hf : ContinuousWithinAt f (Set.Ioi x) x)
  {a : ℝ≥0∞} (ha : a < f x) :
    μ {y | a < f y} ≠ 0 := by
  sorry

--TODO: generalize?
--currently unused
lemma eLpNormEssSup_eq_iSup' {f : ℝ≥0∞ → ℝ≥0∞}
  (hf : ∀ (a : ℝ≥0∞) (x : ℝ≥0∞), a < f x → ContinuousWithinAt f (Set.Ioi x) x) (f_top : f ⊤ = ⊥) :
    eLpNormEssSup f volume = ⨆ x, f x := by
  sorry

--TODO: generalize?
lemma eLpNormEssSup_nnreal_eq_iSup_nnreal {f : ℝ≥0∞ → ℝ≥0∞}
  (hf : ∀ (a : ℝ≥0∞) (x : ℝ≥0), a < f x → ContinuousWithinAt f (Set.Ioi ↑x) ↑x) :
    eLpNormEssSup (fun t : ℝ≥0 ↦ f t) volume = ⨆ (x : ℝ≥0), f x := by
  sorry
