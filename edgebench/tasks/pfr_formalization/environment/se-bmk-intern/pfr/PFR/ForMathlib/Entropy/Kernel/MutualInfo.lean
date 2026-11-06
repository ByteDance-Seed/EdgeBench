module

public import PFR.Mathlib.Probability.Kernel.Composition.Comp
public import PFR.ForMathlib.Entropy.Kernel.Basic

/-!
# Mutual Information of kernels

## Main definitions

* `mutualInfo`: Mutual information of a kernel `κ` into a product space with respect to a
  measure `μ`. This is denoted by `Ik[κ, μ]` and is equal to
  `Hk[fst κ, μ] + Hk[snd κ, μ] - Hk[κ, μ]`.

## Main statements

* `mutualInfo_nonneg`: `Ik[κ, μ]` is nonnegative
* `entropy_condKernel_le_entropy_fst` and `entropy_condKernel_le_entropy_snd`: conditioning
  reduces entropy.

## Notations

* `Ik[κ, μ] = Kernel.entropy κ μ`

-/

@[expose] public section

open Function MeasureTheory Real
open scoped ENNReal NNReal Topology ProbabilityTheory

namespace ProbabilityTheory.Kernel

variable {Ω S T U V : Type*} [mΩ : MeasurableSpace Ω]
  [MeasurableSpace S] [MeasurableSpace T] [MeasurableSpace U] [MeasurableSpace V]
  {κ : Kernel T S} {μ : Measure T} {X : Ω → S} {Y : Ω → U}

/-- Mutual information of a kernel into a product space with respect to a measure. -/
noncomputable
def mutualInfo (κ : Kernel T (S × U)) (μ : Measure T) : ℝ :=
  Hk[fst κ, μ] + Hk[snd κ, μ] - Hk[κ, μ]

/-- Mutual information of a kernel into a product space with respect to a measure. -/
notation3:100 "Ik[" κ " , " μ "]" => Kernel.mutualInfo κ μ

lemma mutualInfo_def (κ : Kernel T (S × U)) (μ : Measure T) :
    Ik[κ, μ] = Hk[fst κ, μ] + Hk[snd κ, μ] - Hk[κ, μ] := by
  sorry

lemma Measure.compProd_compProd' (μ : Measure T)
    (ξ : Kernel T S) [IsSFiniteKernel ξ] (κ : Kernel (T × S) U) [IsSFiniteKernel κ] :
    μ ⊗ₘ (ξ ⊗ₖ κ) = (μ ⊗ₘ ξ ⊗ₘ κ).comap
      (MeasurableEquiv.prodAssoc.symm : T × S × U ≃ᵐ (T × S) × U) := by
  sorry

section

variable [MeasurableSingletonClass S] [MeasurableSingletonClass U]

@[simp]
lemma mutualInfo_swapRight
    (κ : Kernel T (S × U)) (μ : Measure T) :
    Ik[swapRight κ, μ] = Ik[κ, μ] := by
  sorry

variable [MeasurableSingletonClass T]

variable [Countable S] [Countable T]

lemma mutualInfo_compProd
    {κ : Kernel T S} [IsZeroOrMarkovKernel κ]
    {η : Kernel (T × S) U} [IsMarkovKernel η] {μ : Measure T} [IsZeroOrProbabilityMeasure μ]
    [FiniteSupport μ] (hκ : AEFiniteKernelSupport κ μ) (hη : AEFiniteKernelSupport η (μ ⊗ₘ κ)) :
    Ik[κ ⊗ₖ η, μ] = Hk[κ, μ] + Hk[snd (κ ⊗ₖ η), μ] - Hk[κ ⊗ₖ η, μ] := by
  sorry

variable [Countable U]

@[simp]
lemma mutualInfo_prod {κ : Kernel T S} {η : Kernel T U}
    [IsZeroOrMarkovKernel κ] [IsZeroOrMarkovKernel η]
    (μ : Measure T) [IsZeroOrProbabilityMeasure μ] [FiniteSupport μ]
    (hκ : AEFiniteKernelSupport κ μ) (hη : AEFiniteKernelSupport η μ) :
    Ik[κ ×ₖ η, μ] = 0 := by
  sorry

lemma entropy_condKernel_le_entropy_fst [Nonempty S]
    (κ : Kernel T (S × U)) [IsZeroOrMarkovKernel κ]
    (μ : Measure T) [IsZeroOrProbabilityMeasure μ] [FiniteSupport μ]
    (hκ : AEFiniteKernelSupport κ μ) :
    Hk[condKernel (swapRight κ), μ ⊗ₘ (snd κ)] ≤ Hk[fst κ, μ] := by
  sorry

-- TODO: extract lemma(s) from this:
lemma entropy_snd_sub_mutualInfo_le_entropy_map_of_injective {V : Type*} [Countable V]
    [MeasurableSpace V] [MeasurableSingletonClass V]
    (κ : Kernel T (S × U)) [IsZeroOrMarkovKernel κ] (μ : Measure T) [IsZeroOrProbabilityMeasure μ]
    (f : S × U → V) (hfi : ∀ x, Injective (fun y ↦ f (x, y))) [FiniteSupport μ]
    (hκ : AEFiniteKernelSupport κ μ) :
    Hk[snd κ, μ] - Ik[κ, μ] ≤ Hk[map κ f, μ] := by
  sorry

end

section

variable [Countable S] [MeasurableSingletonClass S]
  [Countable T] [MeasurableSingletonClass T]
  [Countable U] [MeasurableSingletonClass U]
  [Countable V] [MeasurableSingletonClass V]

instance IsZeroOrProbabilityMeasure.compProd
    {α β : Type*} {mα : MeasurableSpace α} {mβ : MeasurableSpace β}
    (μ : Measure α) [IsZeroOrProbabilityMeasure μ] (κ : Kernel α β)
    [IsZeroOrMarkovKernel κ] : IsZeroOrProbabilityMeasure (μ ⊗ₘ κ) := by
  rcases eq_zero_or_isMarkovKernel κ with rfl | hκ
  · simp only [Measure.compProd_zero_right]; infer_instance
  rcases eq_zero_or_isProbabilityMeasure μ with rfl | hμ
  · simp only [Measure.compProd_zero_left]; infer_instance
  infer_instance

-- from kernel (T × S × U) V ; Measure (T × S × U)
-- to kernel (T × S) V ; Measure (T × S)
lemma entropy_submodular_compProd {ξ : Kernel T S} [IsZeroOrMarkovKernel ξ]
    {κ : Kernel (T × S) U} [IsZeroOrMarkovKernel κ] {η : Kernel (T × S × U) V} [IsMarkovKernel η]
    {μ : Measure T} [IsZeroOrProbabilityMeasure μ] [FiniteSupport μ]
    (hκ : AEFiniteKernelSupport κ (μ ⊗ₘ ξ))
    (hη : AEFiniteKernelSupport η (μ ⊗ₘ (ξ ⊗ₖ κ))) (hξ : AEFiniteKernelSupport ξ μ) :
    Hk[η, μ ⊗ₘ (ξ ⊗ₖ κ)]
      ≤ Hk[snd (κ ⊗ₖ (comap η MeasurableEquiv.prodAssoc MeasurableEquiv.prodAssoc.measurable)),
            μ ⊗ₘ ξ] := by
  sorry

/- $$ H[X,Y,Z] + H[X] \leq H[Z,X] + H[Y,X].$$ -/
lemma entropy_compProd_triple_add_entropy_le {ξ : Kernel T S} [IsZeroOrMarkovKernel ξ]
    {κ : Kernel (T × S) U} [IsMarkovKernel κ]
    {η : Kernel (T × S × U) V} [IsMarkovKernel η]
    {μ : Measure T} [IsZeroOrProbabilityMeasure μ] [FiniteSupport μ]
    (hκ : AEFiniteKernelSupport κ (μ ⊗ₘ ξ))
    (hη : AEFiniteKernelSupport η (μ ⊗ₘ (ξ ⊗ₖ κ))) (hξ : AEFiniteKernelSupport ξ μ) :
    Hk[(ξ ⊗ₖ κ) ⊗ₖ η, μ] + Hk[ξ, μ]
      ≤ Hk[ξ ⊗ₖ snd (κ ⊗ₖ comap η MeasurableEquiv.prodAssoc MeasurableEquiv.prodAssoc.measurable),
          μ] + Hk[ξ ⊗ₖ κ, μ] := by
  sorry

/-- The submodularity inequality:
$$ H[X,Y,Z] + H[X] \leq H[X,Z] + H[X,Y].$$ -/
lemma entropy_triple_add_entropy_le' {κ : Kernel T (S × U × V)} [IsZeroOrMarkovKernel κ]
    {μ : Measure T} [IsZeroOrProbabilityMeasure μ] [FiniteSupport μ]
    (hκ : AEFiniteKernelSupport κ μ) :
    Hk[κ, μ] + Hk[fst κ, μ] ≤ Hk[deleteMiddle κ, μ] + Hk[deleteRight κ, μ] := by
  sorry

/-- The submodularity inequality:
$$ H[X,Y,Z] + H[Z] \leq H[X,Z] + H[Y,Z].$$ -/
lemma entropy_triple_add_entropy_le (κ : Kernel T (S × U × V)) [IsZeroOrMarkovKernel κ]
    (μ : Measure T) [IsZeroOrProbabilityMeasure μ] [FiniteSupport μ]
    (hκ : AEFiniteKernelSupport κ μ) :
    Hk[κ, μ] + Hk[snd (snd κ), μ] ≤ Hk[deleteMiddle κ, μ] + Hk[snd κ, μ] := by
  sorry

end

end ProbabilityTheory.Kernel
