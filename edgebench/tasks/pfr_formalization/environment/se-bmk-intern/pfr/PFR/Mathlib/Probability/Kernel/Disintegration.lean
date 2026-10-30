module

public import Mathlib.Probability.Independence.Basic
public import Mathlib.Probability.Kernel.Composition.Prod
public import Mathlib.Probability.Kernel.CondDistrib
public import PFR.Mathlib.MeasureTheory.Integral.Lebesgue.Basic
public import PFR.Mathlib.MeasureTheory.Integral.Lebesgue.Countable

/-!
# Disintegration of kernels in finite spaces

We can write `κ : Kernel S (T × U)` as a composition-product `(fst κ) ⊗ₖ (condKernel κ)` where
`fst κ : Kernel S T` and `condKernel : Kernel (S × T) U` is defined in this file.

-/

@[expose] public section

open Real MeasureTheory Measure ProbabilityTheory
open scoped ENNReal NNReal Topology ProbabilityTheory

namespace ProbabilityTheory

variable {Ω S T U : Type*} [mΩ : MeasurableSpace Ω]
  [Countable S] [MeasurableSpace S] [DiscreteMeasurableSpace S]
  [MeasurableSpace T] [MeasurableSpace U]

namespace Kernel

section condKernel

variable [Countable U] [Nonempty U] [DiscreteMeasurableSpace U]

/-
/-- Kernel such that `κ : Kernel T (S × U)` is equal to `(fst κ) ⊗ₖ (condKernel κ)`. -/
noncomputable
def condKernel (κ : Kernel T (S × U)) [IsFiniteKernel κ] :
    kernel (T × S) U where
  val := fun ts ↦ (κ ts.1).condKernel ts.2
  property := .of_discrete
-/

variable [Countable T] [MeasurableSingletonClass S] [MeasurableSingletonClass T]

lemma compProd_swapLeft_prodMkLeft {α β γ : Type*} {mα : MeasurableSpace α} {mβ : MeasurableSpace β}
    {mγ : MeasurableSpace γ} (κ : Kernel α β) [IsSFiniteKernel κ]
    (η : Kernel α γ) [IsSFiniteKernel η] :
    κ ⊗ₖ swapLeft (prodMkLeft β η) = κ ×ₖ η := by
  sorry

lemma ae_eq_condKernel_of_compProd_eq (κ : Kernel T (S × U)) [IsFiniteKernel κ] {μ}
    (η : Kernel (T × S) U) [IsMarkovKernel η] (h : fst κ ⊗ₖ η = κ) :
    η =ᵐ[μ ⊗ₘ fst κ] condKernel κ := by
  sorry

end condKernel

end Kernel

section condDistrib

variable [MeasurableSingletonClass T]
variable [Countable U] [DiscreteMeasurableSpace U]

variable {X : Ω → S} {Y : Ω → T} {Z : Ω → U}

variable [Countable T]

variable [Nonempty T]

lemma condDistrib_fst_ae_eq [Nonempty S] (hX : Measurable X) (hY : Measurable Y) (hZ : Measurable Z)
    (μ : Measure Ω) [IsFiniteMeasure μ] :
    Kernel.fst (condDistrib (fun a ↦ (X a, Y a)) Z μ)
      =ᵐ[μ.map Z] condDistrib X Z μ := by
  sorry

lemma condDistrib_snd_ae_eq [Nonempty S] (hX : Measurable X) (hY : Measurable Y) (hZ : Measurable Z)
    (μ : Measure Ω) [IsFiniteMeasure μ] :
    Kernel.snd (condDistrib (fun a ↦ (X a, Y a)) Z μ)
      =ᵐ[μ.map Z] condDistrib Y Z μ := by
  sorry

section Independence

variable {V : Type*} [Countable V] [MeasurableSpace V] [MeasurableSingletonClass V]
  {W : Ω → V}

end Independence

end condDistrib

end ProbabilityTheory

open Real MeasureTheory

open scoped ENNReal NNReal Topology ProbabilityTheory

namespace ProbabilityTheory.Kernel

variable {Ω S T U V : Type*} [mΩ : MeasurableSpace Ω]
  [MeasurableSpace S] [MeasurableSpace T] [MeasurableSpace U] [MeasurableSpace V]

/-- The analogue of FiniteSupport for probability kernels. -/
noncomputable def FiniteKernelSupport (κ : Kernel T S) : Prop :=
  ∀ t, ∃ A : Finset S, κ t Aᶜ = 0

/-- A kernel `κ` has almost everywhere finite support wrt a measure `μ` if, for almost every
point `t`, then `κ t` has finite support. Note that we don't require any uniformity wrt `t`. -/
noncomputable def AEFiniteKernelSupport (κ : Kernel T S) (μ : Measure T) : Prop :=
  ∀ᵐ t ∂μ, ∃ A : Finset S, κ t Aᶜ = 0

@[simp] lemma finiteKernelSupport_zero : FiniteKernelSupport (0 : Kernel T S) := by
  sorry

@[simp] lemma aefiniteKernelSupport_zero {μ} : AEFiniteKernelSupport (0 : Kernel T S) μ := by
  sorry

section

variable [Countable T] [MeasurableSingletonClass T] {μ : Measure T}

/-- The definition doesn't use `_hκ`, but we keep it here still as it doesn't give anything
interesting otherwise. -/
@[nolint unusedArguments]
noncomputable
def AEFiniteKernelSupport.mk {μ} {κ : Kernel T S} (_hκ : AEFiniteKernelSupport κ μ) :
    Kernel T S := by
  classical
  exact if hS : Nonempty S then
    κ.piecewise (s := {t | ∃ A : Finset S, κ t Aᶜ = 0}) (by rw [Set.setOf_exists]; measurability)
       (.const _ <| .dirac hS.some)
  else 0

@[simp] lemma AEFiniteKernelSupport.mk_zero
    {h : AEFiniteKernelSupport (0 : Kernel T S) μ} : h.mk = 0 := by
  sorry

@[simp] lemma AEFiniteKernelSupport.mk_eq_zero_of_isEmpty
    [IsEmpty S] {κ : Kernel T S} (hκ : AEFiniteKernelSupport κ μ) :
    hκ.mk = 0 := by
  sorry

open Classical in
lemma AEFiniteKernelSupport.mk_eq
    [hS : Nonempty S] {κ : Kernel T S} (hκ : AEFiniteKernelSupport κ μ) :
    hκ.mk = κ.piecewise (s := {t | ∃ A : Finset S, κ t Aᶜ = 0})
      (by rw [Set.setOf_exists]; measurability) (.const _ <| .dirac hS.some) := by
  sorry

instance AEFiniteKernelSupport.isMarkovKernel_mk
    {κ : Kernel T S} [IsMarkovKernel κ] (hκ : AEFiniteKernelSupport κ μ) :
    IsMarkovKernel hκ.mk := by
  rcases isEmpty_or_nonempty T with hT | hT
  · exact ⟨fun x ↦ (IsEmpty.false x).elim⟩
  inhabit T
  have : Nonempty S := (κ default).nonempty_of_neZero
  rw [AEFiniteKernelSupport.mk_eq]
  infer_instance

instance AEFiniteKernelSupport.isZeroOrMarkovKernel_mk
    {κ : Kernel T S} [IsZeroOrMarkovKernel κ] (hκ : AEFiniteKernelSupport κ μ) :
    IsZeroOrMarkovKernel hκ.mk := by
  rcases eq_zero_or_isMarkovKernel κ with rfl | hκ'
  · simp only [mk_zero]
    infer_instance
  · infer_instance

instance AEFiniteKernelSupport.isSFiniteKernel_mk
    {κ : Kernel T S} [IsSFiniteKernel κ] (hκ : AEFiniteKernelSupport κ μ) :
    IsSFiniteKernel hκ.mk := by
  rcases isEmpty_or_nonempty S with hS | hS
  · simp only [mk_eq_zero_of_isEmpty]; infer_instance
  rw [AEFiniteKernelSupport.mk_eq]
  infer_instance

end

/-- Finite range implies finite kernel support. -/
lemma finiteKernelSupport_of_finite_range [Finite S] (κ : Kernel T S) : FiniteKernelSupport κ := by
  sorry

/-- Projecting a kernel to first coordinate preserves finite kernel support. -/
lemma FiniteKernelSupport.fst [MeasurableSingletonClass S]
   {κ : Kernel T (S × U)} (hκ : FiniteKernelSupport κ) :
    FiniteKernelSupport (fst κ) := by
  sorry

/-- Projecting a kernel to second coordinate preserves finite kernel support. -/
lemma FiniteKernelSupport.snd [MeasurableSingletonClass U]
    {κ : Kernel T (S × U)} (hκ : FiniteKernelSupport κ) :
    FiniteKernelSupport (snd κ) := by
  sorry

/-- Swapping a kernel right preserves finite kernel support. -/
lemma FiniteKernelSupport.swapRight
    [MeasurableSingletonClass S] [MeasurableSingletonClass U]
    {κ : Kernel T (S × U)} (hκ : FiniteKernelSupport κ) :
    FiniteKernelSupport (swapRight κ) := by
  sorry

lemma AEFiniteKernelSupport.swapRight {κ : Kernel T (S × U)} {μ : Measure T}
    [MeasurableSingletonClass S] [MeasurableSingletonClass U]
    (hκ : AEFiniteKernelSupport κ μ) :
    AEFiniteKernelSupport (swapRight κ) μ := by
  sorry

lemma AEFiniteKernelSupport.prod {κ : Kernel T S} {η : Kernel T U}
    [IsMarkovKernel κ] [IsMarkovKernel η] {μ : Measure T}
    (hκ : AEFiniteKernelSupport κ μ) (hη : AEFiniteKernelSupport η μ) :
    AEFiniteKernelSupport (κ ×ₖ η) μ := by
  sorry

end ProbabilityTheory.Kernel
