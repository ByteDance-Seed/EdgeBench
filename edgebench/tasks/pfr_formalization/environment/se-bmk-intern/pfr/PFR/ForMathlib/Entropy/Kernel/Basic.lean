module

public import Mathlib.MeasureTheory.Integral.Prod
public import PFR.ForMathlib.Entropy.Measure
public import PFR.Mathlib.Probability.Kernel.Disintegration

/-!
# Entropy of a kernel with respect to a measure

## Main definitions

* `Kernel.entropy`: entropy of a kernel `κ` with respect to a measure `μ`,
  `μ[fun t ↦ measureEntropy (κ t)]`. We use the notation `Hk[κ, μ]`.

## Main statements

* `chain_rule`: `Hk[κ, μ] = Hk[fst κ, μ] + Hk[condKernel κ, μ ⊗ₘ (fst κ)]`.
* `entropy_map_le`: data-processing inequality for the kernel entropy

## Notations

* `Hk[κ, μ] = Kernel.entropy κ μ`

-/

@[expose] public section

open Real MeasureTheory

open scoped ENNReal NNReal Topology ProbabilityTheory

namespace ProbabilityTheory.Kernel

variable {Ω S T U : Type*} [mΩ : MeasurableSpace Ω]
  [MeasurableSpace S] [MeasurableSpace T] [MeasurableSpace U]

/-- Entropy of a kernel with respect to a measure. -/
noncomputable
def entropy (κ : Kernel T S) (μ : Measure T) := μ[fun y ↦ Hm[κ y]]

/-- Entropy of a kernel with respect to a measure. -/
notation3:100 "Hk[" κ " , " μ "]" => ProbabilityTheory.Kernel.entropy κ μ

lemma entropy_congr {μ} {κ η : Kernel T S} (h : κ =ᵐ[μ] η) : Hk[κ, μ] = Hk[η, μ] := by
  sorry

lemma aefiniteKernelSupport_condDistrib
    [Nonempty S] [Countable S] [MeasurableSingletonClass S]
    [Countable T] [MeasurableSingletonClass T]
    (X : Ω → S) (Y : Ω → T) (μ : Measure Ω) [IsFiniteMeasure μ]
    (hX : Measurable X) (hY : Measurable Y) [FiniteRange X] :
    AEFiniteKernelSupport (condDistrib X Y μ) (μ.map Y) := by
  sorry

lemma entropy_le_log_card
   [MeasurableSingletonClass S]
   (κ : Kernel T S) (μ : Measure T) [Fintype S] [IsProbabilityMeasure μ] :
    Hk[κ, μ] ≤ log (Fintype.card S) := by
  sorry

lemma entropy_eq_integral_sum (κ : Kernel T S) [IsZeroOrMarkovKernel κ] (μ : Measure T) :
    Hk[κ, μ] = μ[fun y ↦ ∑' x, negMulLog ((κ y).real {x})] := by
  sorry

-- entropy_map_of_injective is a special case of this (see def of map)

lemma entropy_map_of_injective [MeasurableSingletonClass U]
    (κ : Kernel T S) (μ : Measure T) {f : S → U} (hf : Function.Injective f) (hmes : Measurable f) :
    Hk[map κ f, μ] = Hk[κ, μ] := by
  sorry

@[simp]
lemma entropy_compProd_deterministic [Countable S] [MeasurableSingletonClass S]
    [Countable T] [MeasurableSingletonClass T] [MeasurableSingletonClass U]
    (κ : Kernel T S) [IsZeroOrMarkovKernel κ] (μ : Measure T) [IsFiniteMeasure μ] (f : T × S → U)
    [FiniteSupport μ] (hκ : AEFiniteKernelSupport κ μ) :
    Hk[κ ⊗ₖ (deterministic f .of_discrete), μ] = Hk[κ, μ] := by
  sorry

variable [Countable S] [MeasurableSingletonClass S] [Countable T]
    [MeasurableSingletonClass T] [Countable U] [MeasurableSingletonClass U]

lemma entropy_snd_le {κ : Kernel T (S × U)} [IsZeroOrMarkovKernel κ]
    {μ : Measure T} [IsZeroOrProbabilityMeasure μ]
    [FiniteSupport μ] (hκ : AEFiniteKernelSupport κ μ) :
    Hk[snd κ, μ] ≤ Hk[κ, μ] := by
  sorry

lemma entropy_fst_le (κ : Kernel T (S × U)) [IsZeroOrMarkovKernel κ]
    (μ : Measure T) [IsZeroOrProbabilityMeasure μ]
    [FiniteSupport μ] (hκ : AEFiniteKernelSupport κ μ) :
    Hk[fst κ, μ] ≤ Hk[κ, μ] := by
  sorry

end ProbabilityTheory.Kernel
