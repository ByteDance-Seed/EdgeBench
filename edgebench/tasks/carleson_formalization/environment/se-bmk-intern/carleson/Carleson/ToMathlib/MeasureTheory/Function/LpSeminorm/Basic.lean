module

public import Mathlib.MeasureTheory.Function.LpSeminorm.Basic
public import Mathlib.MeasureTheory.Constructions.BorelSpace.Basic
public import Mathlib.Analysis.Normed.Group.Basic
public import Carleson.ToMathlib.Misc

public section -- for iSup_rpow

-- Upstreaming status: lemmas seem useful (mostly minor modifications of mathlib),
-- a lot is ready to go already

open MeasureTheory Set
open scoped ENNReal

variable {α ε E F G : Type*} {m m0 : MeasurableSpace α} {p : ℝ≥0∞} {q : ℝ} {μ ν : Measure α}
  [NormedAddCommGroup E] [NormedAddCommGroup F] [NormedAddCommGroup G] [ENorm ε]

namespace MeasureTheory

section Zero

variable {ε : Type*} [TopologicalSpace ε]

lemma eLpNorm_zero_of_ae_zero' [ESeminormedAddMonoid ε] {f : α → ε} (h : enorm ∘ f =ᵐ[μ] 0) :
    eLpNorm f p μ = 0 := by
  sorry

lemma eLpNorm_zero_of_ae_zero [ENormedAddMonoid ε] {f : α → ε} (h : f =ᵐ[μ] 0) :
    eLpNorm f p μ = 0 := by
  sorry

end Zero

section MapMeasure

variable {β : Type*} {mβ : MeasurableSpace β} {f : α → β} {g : β → E}

-- replace the unprimed mathlib version
theorem eLpNormEssSup_map_measure' [MeasurableSpace E] [OpensMeasurableSpace E]
    (hg : AEMeasurable g (Measure.map f μ)) (hf : AEMeasurable f μ) :
    eLpNormEssSup g (Measure.map f μ) = eLpNormEssSup (g ∘ f) μ := by
  sorry

-- replace the unprimed mathlib version
theorem eLpNorm_map_measure' [MeasurableSpace E] [OpensMeasurableSpace E]
    (hg : AEMeasurable g (Measure.map f μ)) (hf : AEMeasurable f μ) :
    eLpNorm g p (Measure.map f μ) = eLpNorm (g ∘ f) p μ := by
  sorry

-- replace the unprimed version
theorem eLpNorm_comp_measurePreserving' {ν : Measure β} [MeasurableSpace E]
    [OpensMeasurableSpace E] (hg : AEMeasurable g ν) (hf : MeasurePreserving f μ ν) :
    eLpNorm (g ∘ f) p μ = eLpNorm g p ν := by
  sorry

end MapMeasure

section Suprema

theorem eLpNormEssSup_iSup {α : Type*} {ι : Type*} [Countable ι] [MeasurableSpace α]
    {μ : Measure α} (f : ι → α → ℝ≥0∞) :
    eLpNormEssSup (fun x => ⨆ n, f n x) μ = ⨆ n, eLpNormEssSup (f n) μ := by
  sorry

-- XXX: why does the lemma before assume a countable indexing type and this work with ℕ?
-- make consistent!
/-- Monotone convergence applied to eLpNorms. AEMeasurable variant.
  Possibly imperfect hypotheses, particularly on `p`. Note that for `p = ∞` the stronger
  statement in `eLpNormEssSup_iSup` holds. -/
theorem eLpNorm_iSup' {α : Type*} [MeasurableSpace α] {μ : Measure α} {p : ℝ≥0∞}
    {f : ℕ → α → ℝ≥0∞} (hf : ∀ n, AEMeasurable (f n) μ) (h_mono : ∀ᵐ x ∂μ, Monotone fun n => f n x) :
    eLpNorm (fun x => ⨆ n, f n x) p μ = ⨆ n, eLpNorm (f n) p μ := by
  sorry

end Suprema

section Indicator

variable {ε : Type*} [TopologicalSpace ε] [ESeminormedAddMonoid ε]
  {c : ε} {s : Set α}
  {ε' : Type*} [TopologicalSpace ε'] [ContinuousENorm ε']

--complements the mathlib lemma eLpNormEssSup_indicator_const_eq
lemma eLpNormEssSup_indicator_const_eq' {s : Set α} {c : ε} (hμs : μ s = 0) :
    eLpNormEssSup (s.indicator fun _ : α => c) μ = 0 := by
  sorry

end Indicator

section ENormSMulClass

open Filter

variable {𝕜 : Type*} --[NormedRing 𝕜]
  {ε : Type*} [TopologicalSpace ε] [ESeminormedAddMonoid ε] [SMul NNReal ε] [ENorm 𝕜]
  [ENormSMulClass NNReal ε]
  {c : NNReal} {f : α → ε}

theorem eLpNorm'_const_smul_le'' (hq : 0 < q) : eLpNorm' (c • f) q μ ≤ ‖c‖ₑ * eLpNorm' f q μ := by
  sorry

theorem eLpNormEssSup_const_smul_le'' : eLpNormEssSup (c • f) μ ≤ ‖c‖ₑ * eLpNormEssSup f μ := by
  sorry

theorem eLpNorm_const_smul_le'' : eLpNorm (c • f) p μ ≤ ‖c‖ₑ * eLpNorm f p μ := by
  sorry

theorem MemLp.const_smul'' [ContinuousConstSMul NNReal ε] (hf : MemLp f p μ) :
    MemLp (c • f) p μ := by
  sorry

theorem MemLp.const_mul'' [ContinuousConstSMul NNReal ε] (hf : MemLp f p μ) :
    MemLp (fun x => c • f x) p μ := by
  sorry

end ENormSMulClass

end MeasureTheory
