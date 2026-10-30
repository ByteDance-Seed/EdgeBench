module

public import PFR.ForMathlib.Entropy.Kernel.Group

/-!
# Ruzsa distance between kernels

## Notations

* `dk[κ ; μ # η ; ν] = `
-/

@[expose] public section

open Real MeasureTheory
open scoped ENNReal NNReal Topology ProbabilityTheory

namespace ProbabilityTheory.Kernel

variable {T T' T'' G : Type*} [MeasurableSpace T] [MeasurableSpace T'] [MeasurableSpace T'']
  [MeasurableSpace G] [AddCommGroup G]

/-- The Rusza distance between two measures, defined as `H[X - Y] - H[X]/2 - H[Y]/2` where `X`
and `Y` are independent variables distributed according to the two measures. -/
noncomputable
def rdistm (μ ν : Measure G) : ℝ := Hm[(μ.prod ν).map (fun x ↦ x.1 - x.2)] - Hm[μ]/2 - Hm[ν]/2

/-- The Rusza distance between two kernels taking values in the same space, defined as the average
Rusza distance between the image measures. -/
noncomputable
def rdist (κ : Kernel T G) (η : Kernel T' G) (μ : Measure T) (ν : Measure T') : ℝ :=
  (μ.prod ν)[fun p ↦ rdistm (κ p.1) (η p.2)]

/-- The Rusza distance between two kernels taking values in the same space, defined as the average
Rusza distance between the image measures. -/
notation3:max "dk[" κ " ; " μ " # " η " ; " μ' "]" => rdist κ η μ μ'

section

variable [Countable T] [MeasurableSingletonClass T] [Countable T'] [MeasurableSingletonClass T']

variable [MeasurableSingletonClass G] [Countable G]

@[simp] lemma rdist_zero_kernel_left {η : Kernel T' G} [IsFiniteKernel η]
    {μ : Measure T} {ν : Measure T'} [IsProbabilityMeasure μ] [IsProbabilityMeasure ν]
    [FiniteSupport μ] [FiniteSupport ν] :
    dk[0 ; μ # η ; ν] = - Hk[η, ν] / 2 := by
  sorry

@[simp] lemma rdist_dirac_zero_left {η : Kernel T' G} [IsFiniteKernel η]
    {μ : Measure T} {ν : Measure T'} [IsProbabilityMeasure μ] [IsProbabilityMeasure ν]
    [FiniteSupport μ] [FiniteSupport ν] :
    dk[const T (Measure.dirac 0) ; μ # η ; ν] = Hk[η, ν] / 2 := by
  sorry

lemma abs_sub_entropy_le_rdist {κ : Kernel T G} {η : Kernel T' G}
    [IsMarkovKernel κ] [IsMarkovKernel η]
    {μ : Measure T} {ν : Measure T'} [IsProbabilityMeasure μ] [IsProbabilityMeasure ν]
    [FiniteSupport μ] [FiniteSupport ν]
    (hκ : AEFiniteKernelSupport κ μ) (hη : AEFiniteKernelSupport η ν) :
    |Hk[κ, μ] - Hk[η, ν]| ≤ 2 * dk[κ ; μ # η ; ν] := by
  sorry

lemma rdist_nonneg {κ : Kernel T G} {η : Kernel T' G}
    [IsMarkovKernel κ] [IsMarkovKernel η]
    {μ : Measure T} {ν : Measure T'} [IsProbabilityMeasure μ] [IsProbabilityMeasure ν]
    [FiniteSupport μ] [FiniteSupport ν]
    (hκ : AEFiniteKernelSupport κ μ) (hη : AEFiniteKernelSupport η ν) :
    0 ≤ dk[κ ; μ # η ; ν] := by
  sorry

-- Kernel equivalent of `H[X - Y; μ] ≤ H[X - Z; μ] + H[Z - Y; μ] - H[Z; μ]`
-- `κ` is `⟨X,Y⟩`, `η` is `Z`. Independence is expressed through the product `×ₖ`.
/-- The **improved entropic Ruzsa triangle inequality**. -/
lemma ent_of_diff_le (κ : Kernel T (G × G)) (η : Kernel T G) [IsMarkovKernel κ] [IsMarkovKernel η]
    (μ : Measure T) [IsProbabilityMeasure μ] [FiniteSupport μ]
    (hκ : FiniteKernelSupport κ) (hη : FiniteKernelSupport η) :
    Hk[map κ (fun p : G × G ↦ p.1 - p.2), μ]
      ≤ Hk[map ((fst κ) ×ₖ η) (fun p : G × G ↦ p.1 - p.2), μ]
        + Hk[map (η ×ₖ (snd κ)) (fun p : G × G ↦ p.1 - p.2), μ]
        - Hk[η, μ] := by
  sorry

end

-- note : Measure.prod should be made to use dot notation in the infoview

variable [MeasurableSingletonClass T] [MeasurableSingletonClass T'] [MeasurableSingletonClass T'']
variable [MeasurableSingletonClass G] [Countable G]

variable [Countable T] [Countable T'] [Countable T'']

lemma rdist_triangle (κ : Kernel T G) (η : Kernel T' G) (ξ : Kernel T'' G)
    [IsMarkovKernel κ] [IsMarkovKernel η] [IsMarkovKernel ξ]
    (μ : Measure T) (μ' : Measure T') (μ'' : Measure T'')
    [IsProbabilityMeasure μ] [IsProbabilityMeasure μ'] [IsProbabilityMeasure μ'']
    [FiniteSupport μ] [FiniteSupport μ'] [FiniteSupport μ'']
    (hκ : FiniteKernelSupport κ) (hη : FiniteKernelSupport η) (hξ : FiniteKernelSupport ξ) :
    dk[κ ; μ # ξ ; μ''] ≤ dk[κ ; μ # η ; μ'] + dk[η ; μ' # ξ ; μ''] := by
  sorry

end ProbabilityTheory.Kernel
