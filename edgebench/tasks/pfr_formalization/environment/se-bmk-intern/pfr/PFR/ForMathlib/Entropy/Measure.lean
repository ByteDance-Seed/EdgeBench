module

public import Mathlib.Analysis.SpecialFunctions.Log.NegMulLog
public import Mathlib.MeasureTheory.Integral.Bochner.Basic
public import PFR.ForMathlib.FiniteRange.Defs
public import PFR.Mathlib.MeasureTheory.Measure.Dirac
public import PFR.Mathlib.MeasureTheory.Measure.Real
public import PFR.Mathlib.Probability.UniformOn

/-!
# Entropy of a measure

## Main definitions

* `measureEntropy`: entropy of a measure `μ`, denoted by `Hm[μ]`
* `measureMutualInfo`: mutual information of a measure over a product space, denoted by `Im[μ]`,
  equal to `Hm[μ.map Prod.fst] + Hm[μ.map Prod.snd] - Hm[μ]`

## Notations

* `Hm[μ] = measureEntropy μ`
* `Im[μ] = measureMutualInfo μ`

-/

@[expose] public section

open MeasureTheory Real Set
open scoped ENNReal NNReal Topology

namespace ProbabilityTheory
variable {Ω S T U : Type*} [mΩ : MeasurableSpace Ω]
  [MeasurableSpace S] --[MeasurableSingletonClass S]
  [MeasurableSpace T] --[MeasurableSingletonClass T]
  [MeasurableSpace U] --[MeasurableSingletonClass U]

section measureEntropy
variable {μ : Measure S}

/-- Entropy of a measure on a measurable space.

We normalize the measure by `(μ Set.univ)⁻¹` to extend the entropy definition to finite measures.
What we really want to do is deal with `μ=0` or `IsProbabilityMeasure μ`, but we don't have
a typeclass for that (we could create one though).
The added complexity ∈ the expression is not an issue because if `μ` is a probability measure,
a call to `simp` will simplify `(μ Set.univ)⁻¹ • μ` to `μ`. -/
noncomputable
def measureEntropy (μ : Measure S := by volume_tac) : ℝ :=
  ∑' s, negMulLog (((μ Set.univ)⁻¹ • μ).real {s})

@[inherit_doc measureEntropy] notation:100 "Hm[" μ "]" => measureEntropy μ

/-- A measure has finite support if there exists a finite set whose complement has zero measure. -/
class FiniteSupport (μ : Measure S := by volume_tac) : Prop where
  finite : ∃ A : Finset S, ∀ᵐ x ∂μ, x ∈ A

/-- A set on which a measure with finite support is supported. -/
noncomputable
def _root_.MeasureTheory.Measure.support (μ : Measure S) [hμ : FiniteSupport μ] : Finset S :=
  hμ.finite.choose.filter (μ {·} ≠ 0)

lemma measure_compl_support (μ : Measure S) [hμ : FiniteSupport μ] : μ μ.supportᶜ = 0 := by
  sorry

lemma ae_mem_support (μ : Measure S) [FiniteSupport μ] : ∀ᵐ x ∂μ, x ∈ μ.support := by
  sorry

@[simp] lemma mem_support {μ : Measure S} [hμ : FiniteSupport μ] {x : S} :
    x ∈ μ.support ↔ μ {x} ≠ 0 := by
  sorry

instance finiteSupport_zero : FiniteSupport (0 : Measure S) where
  finite := ⟨(∅ : Finset S), by simp⟩

/-- TODO: replace FiniteSupport hypotheses ∈ these files with FiniteEntropy hypotheses. -/
noncomputable def FiniteEntropy (μ : Measure S := by volume_tac) : Prop :=
  Summable (fun s ↦ negMulLog (((μ Set.univ)⁻¹ • μ) {s}).toReal) ∧
  ∃ A : Set S, Countable A ∧ μ Aᶜ = 0

instance finiteSupport_of_fintype {μ : Measure S} [Finite S] : FiniteSupport μ := by
  cases nonempty_fintype S
  use Finset.univ
  simp

instance finiteSupport_of_mul {μ : Measure S} [FiniteSupport μ] (c : ℝ≥0∞) :
    FiniteSupport (c • μ) := ⟨μ.support, Measure.ae_smul_measure (ae_mem_support _) _⟩

section

variable [MeasurableSingletonClass S]

lemma finiteSupport_of_comp
    {μ : Measure Ω} [FiniteSupport μ] {X : Ω → S} (hX : Measurable X) :
    FiniteSupport (μ.map X) := by
  sorry

instance finiteSupport_of_dirac (x : S) : FiniteSupport (Measure.dirac x) := ⟨{x}, by simp⟩

instance finiteSupport_of_finiteRange {μ : Measure Ω} {X : Ω → S} [hX' : FiniteRange X] :
    FiniteSupport (μ.map X) := by
  use hX'.toFinset
  exact FiniteRange.null_of_compl μ X

instance finiteSupport_of_prod {μ : Measure S} [FiniteSupport μ] {ν : Measure T} [SigmaFinite ν]
    [FiniteSupport ν] :
    FiniteSupport (μ.prod ν) := by
  use μ.support ×ˢ ν.support
  exact Measure.prod_of_full_measure_finset (measure_compl_support μ) (measure_compl_support ν)

/-- The countability hypothesis can probably be dropped here. Proof is unwieldy and can probably
be golfed. -/
lemma integrable_of_finiteSupport (μ : Measure S) [FiniteSupport μ]
    {β : Type*} [NormedAddCommGroup β] [IsFiniteMeasure μ] [Countable S]
    {f : S → β} :
    Integrable f μ := by
  sorry

end

lemma measureEntropy_of_isProbabilityMeasure' (μ : Measure S) [IsZeroOrProbabilityMeasure μ] :
    Hm[μ] = ∑' s, negMulLog (μ.real {s}) := by
  sorry

variable [MeasurableSingletonClass S]

lemma measureEntropy_eq_card_iff_measure_eq_aux
    (μ : Measure S) [Fintype S] [IsProbabilityMeasure μ] :
    Hm[μ] = log (Fintype.card S) ↔ (∀ s : S, μ {s} = (Fintype.card S : ℝ≥0)⁻¹) := by
  sorry

set_option linter.flexible false in

lemma measureEntropy_map_of_injective
    (μ : Measure T) (f : T → S) (hf_m : Measurable f) (hf : Function.Injective f) :
    Hm[μ.map f] = Hm[μ] := by
  sorry

lemma measureEntropy_comap_equiv (μ : Measure T) (f : S ≃ᵐ T) : Hm[μ.comap f] = Hm[μ] := by
  sorry

end measureEntropy

section measureMutualInfo

/-- The mutual information between the marginals of a measure on a product space. -/
noncomputable
def measureMutualInfo (μ : Measure (S × T) := by volume_tac) : ℝ :=
  Hm[μ.map Prod.fst] + Hm[μ.map Prod.snd] - Hm[μ]

/-- The mutual information between the marginals of a measure on a product space. -/
notation:100 "Im[" μ "]" => measureMutualInfo μ

variable [MeasurableSingletonClass S] [MeasurableSingletonClass T] [MeasurableSingletonClass U]

lemma measureMutualInfo_swap (μ : Measure (S × T)) :
    Im[μ.map Prod.swap] = Im[μ] := by
  sorry

@[simp]
lemma measureMutualInfo_prod {μ : Measure S} {ν : Measure T} [FiniteSupport μ] [FiniteSupport ν]
    [IsProbabilityMeasure μ] [IsProbabilityMeasure ν] :
    Im[μ.prod ν] = 0 := by
  sorry

lemma measureMutualInfo_nonneg {μ : Measure (S × U)} [FiniteSupport μ] :
    0 ≤ Im[μ] := by
  sorry

end measureMutualInfo

end ProbabilityTheory

namespace Mathlib.Meta.Positivity
open Lean Meta Qq Function ProbabilityTheory

/-- Extension for `measureMutualInfo`. -/
@[positivity measureMutualInfo _]
meta def evalMeasureMutualInfo : PositivityExt where eval {u α} _ _ e := do
  match u, α, e with
  | 0, ~q(ℝ), ~q(@measureMutualInfo $S $T $measS $measT $μ) =>
    assertInstancesCommute
    let _ ← synthInstanceQ q(MeasurableSingletonClass $S)
    let _ ← synthInstanceQ q(MeasurableSingletonClass $T)
    let _ ← synthInstanceQ q(FiniteSupport $μ)
    pure <| .nonnegative q(measureMutualInfo_nonneg)
  | _, _, _ => throwError "failed to match ProbabilityTheory.measureMutualInfo"

example {S T : Type*} [MeasurableSpace S] [MeasurableSpace T] [MeasurableSingletonClass S]
    [MeasurableSingletonClass T] {μ : Measure (S × T)} [FiniteSupport μ] : 0 ≤ Im[μ] := by
  sorry

end Mathlib.Meta.Positivity
