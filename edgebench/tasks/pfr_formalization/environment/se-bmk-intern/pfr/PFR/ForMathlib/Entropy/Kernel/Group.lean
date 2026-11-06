module

public import PFR.ForMathlib.Entropy.Kernel.MutualInfo
public import Mathlib.MeasureTheory.Group.Arithmetic

/-!
# Kernel entropy and mutual information in a commutative group

## Main definitions

## Main results

-/

public section

open MeasureTheory ProbabilityTheory

variable {Ω Ω' Ω'' Ω''' G T : Type*}
  [MeasurableSpace T]
  [MeasurableSpace G] [MeasurableSingletonClass G] [Group G] [Countable G]
  {κ : Kernel T G} {μ : Measure T}

@[to_additive]
lemma measureEntropy_div_comm (μ : Measure (G × G)) :
    Hm[μ.map fun p ↦ p.1 / p.2] = Hm[μ.map fun p ↦ p.2 / p.1] := by
  sorry

namespace ProbabilityTheory.Kernel

variable [Countable T] [MeasurableSingletonClass T]

@[to_additive]
lemma entropy_fst_sub_mutualInfo_le_entropy_map_mul'
    (κ : Kernel T (G × G)) [IsZeroOrMarkovKernel κ] (μ : Measure T) [IsZeroOrProbabilityMeasure μ]
    [FiniteSupport μ] (hκ : AEFiniteKernelSupport κ μ) :
    Hk[fst κ, μ] - Ik[κ, μ] ≤ Hk[map κ (fun p ↦ p.2 * p.1), μ] := by
  sorry

@[to_additive]
lemma entropy_fst_sub_mutualInfo_le_entropy_map_div
    (κ : Kernel T (G × G)) [IsZeroOrMarkovKernel κ] (μ : Measure T) [IsZeroOrProbabilityMeasure μ]
    [FiniteSupport μ] (hκ : AEFiniteKernelSupport κ μ) :
    Hk[fst κ, μ] - Ik[κ, μ] ≤ Hk[map κ (fun p ↦ p.1 / p.2), μ] := by
  sorry

@[to_additive]
lemma max_entropy_sub_mutualInfo_le_entropy_mul
    (κ : Kernel T (G × G)) [IsZeroOrMarkovKernel κ] (μ : Measure T) [IsZeroOrProbabilityMeasure μ]
    [FiniteSupport μ] (hκ : AEFiniteKernelSupport κ μ) :
    max (Hk[fst κ, μ]) (Hk[snd κ, μ]) - Ik[κ, μ]
      ≤ Hk[map κ (fun p ↦ p.1 * p.2), μ] := by
  sorry

@[to_additive]
lemma max_entropy_sub_mutualInfo_le_entropy_mul'
    (κ : Kernel T (G × G)) [IsZeroOrMarkovKernel κ] (μ : Measure T) [IsZeroOrProbabilityMeasure μ]
    [FiniteSupport μ] (hκ : AEFiniteKernelSupport κ μ) :
    max (Hk[fst κ, μ]) (Hk[snd κ, μ]) - Ik[κ, μ]
      ≤ Hk[map κ (fun p ↦ p.2 * p.1), μ] := by
  sorry

@[to_additive]
lemma max_entropy_sub_mutualInfo_le_entropy_div
    (κ : Kernel T (G × G)) [IsZeroOrMarkovKernel κ] (μ : Measure T) [IsZeroOrProbabilityMeasure μ]
    [FiniteSupport μ] (hκ : AEFiniteKernelSupport κ μ) :
    max (Hk[fst κ, μ]) (Hk[snd κ, μ]) - Ik[κ, μ]
      ≤ Hk[map κ (fun p ↦ p.1 / p.2), μ] := by
  sorry

@[to_additive]
lemma max_entropy_le_entropy_mul_prod
    (κ : Kernel T G) [IsMarkovKernel κ] (η : Kernel T G) [IsMarkovKernel η]
    (μ : Measure T) [IsZeroOrProbabilityMeasure μ] [FiniteSupport μ]
    (hκ : AEFiniteKernelSupport κ μ) (hη : AEFiniteKernelSupport η μ) :
    max (Hk[κ, μ]) (Hk[η, μ]) ≤ Hk[map (κ ×ₖ η) (fun p ↦ p.1 * p.2), μ] := by
  sorry

@[to_additive max_entropy_le_entropy_sub_prod]
lemma max_entropy_le_entropy_div_prod
    (κ : Kernel T G) [IsMarkovKernel κ] (η : Kernel T G) [IsMarkovKernel η]
    (μ : Measure T) [IsZeroOrProbabilityMeasure μ] [FiniteSupport μ]
    (hκ : AEFiniteKernelSupport κ μ) (hη : AEFiniteKernelSupport η μ) :
    max (Hk[κ, μ]) (Hk[η, μ]) ≤ Hk[map (κ ×ₖ η) (fun p ↦ p.1 / p.2), μ] := by
  sorry

end ProbabilityTheory.Kernel
