module

public import Mathlib.Probability.Kernel.Composition.Comp
public import PFR.Mathlib.Probability.Kernel.Disintegration

public section

open Function MeasureTheory Real
open scoped ENNReal NNReal Topology ProbabilityTheory

namespace ProbabilityTheory.Kernel

section
variable {α β γ δ ε : Type*} {_ : MeasurableSpace α} {_ : MeasurableSpace β}
    {_ : MeasurableSpace γ} {_ : MeasurableSpace δ} {_ : MeasurableSpace ε}

variable {Ω S T : Type*} [mΩ : MeasurableSpace Ω]
  [MeasurableSpace S] [MeasurableSpace T] [MeasurableSpace γ]
  {κ : Kernel T S} {μ : Measure T} {X : Ω → S} {Y : Ω → β}

lemma map_map (κ : Kernel α β) {f : β → γ} (hf : Measurable f) {g : γ → δ} (hg : Measurable g) :
    map (map κ f) g = map κ (g ∘ f) := by
  sorry

lemma map_swapRight (κ : Kernel α (β × γ)) {f : (γ × β) → δ} :
    map (swapRight κ) f = map κ (f ∘ Prod.swap) := by
  sorry

/-- Given a kernel taking values in a product of three spaces, forget the middle one. -/
noncomputable
def deleteMiddle (κ : Kernel α (β × γ × δ)) :
    Kernel α (β × δ) :=
  mapOfMeasurable κ (fun p ↦ (p.1, p.2.2))
    (measurable_fst.prodMk (measurable_snd.comp measurable_snd))

lemma deleteMiddle_eq (κ : Kernel α (β × γ × δ)) :
    deleteMiddle κ = map κ (fun p ↦ (p.1, p.2.2)) := by
  sorry

instance (κ : Kernel α (β × γ × δ)) [IsMarkovKernel κ] : IsMarkovKernel (deleteMiddle κ) := by
  rw [deleteMiddle_eq]; apply IsMarkovKernel.map _ (by fun_prop)

instance (κ : Kernel α (β × γ × δ)) [IsZeroOrMarkovKernel κ] :
    IsZeroOrMarkovKernel (deleteMiddle κ) := by
  rw [deleteMiddle_eq]; infer_instance

@[simp]
lemma fst_deleteMiddle (κ : Kernel α (β × γ × δ)) : fst (deleteMiddle κ) = fst κ := by
  sorry

@[simp]
lemma snd_deleteMiddle (κ : Kernel α (β × γ × δ)) : snd (deleteMiddle κ) = snd (snd κ) := by
  sorry

/-- Given a kernel taking values in a product of three spaces, forget the last variable. -/
noncomputable
def deleteRight (κ : Kernel α (β × γ × δ)) : Kernel α (β × γ) :=
  mapOfMeasurable κ (fun p ↦ (p.1, p.2.1))
    (measurable_fst.prodMk (measurable_fst.comp measurable_snd))

lemma deleteRight_eq (κ : Kernel α (β × γ × δ)) :
    deleteRight κ = map κ (fun p ↦ (p.1, p.2.1)) := by
  sorry

instance (κ : Kernel α (β × γ × δ)) [IsMarkovKernel κ] : IsMarkovKernel (deleteRight κ) := by
  rw [deleteRight_eq]; apply IsMarkovKernel.map _ (by fun_prop)

instance (κ : Kernel α (β × γ × δ)) [IsZeroOrMarkovKernel κ] :
    IsZeroOrMarkovKernel (deleteRight κ) := by
  rw [deleteRight_eq]; infer_instance

@[simp]
lemma fst_deleteRight (κ : Kernel α (β × γ × δ)) : fst (deleteRight κ) = fst κ := by
  sorry

@[simp]
lemma snd_deleteRight (κ : Kernel α (β × γ × δ)) : snd (deleteRight κ) = fst (snd κ) := by
  sorry

@[simp, nolint simpNF]
lemma deleteRight_map_prod (κ : Kernel α β) {f : β → γ} {g : β → δ} {g' : β → ε}
    (hg' : Measurable g') :
    deleteRight (map κ (fun b ↦ (f b, g b, g' b)))
      = map κ (fun b ↦ (f b, g b)) := by
  sorry

/-- Given a kernel taking values in a product of three spaces, reverse the order of the spaces. -/
noncomputable
def reverse (κ : Kernel α (β × γ × δ)) : Kernel α (δ × γ × β) :=
  mapOfMeasurable κ (fun p ↦ (p.2.2, p.2.1, p.1))
    ((measurable_snd.comp measurable_snd).prodMk
      ((measurable_fst.comp measurable_snd).prodMk measurable_fst))

lemma reverse_eq (κ : Kernel α (β × γ × δ)) : reverse κ = map κ (fun p ↦ (p.2.2, p.2.1, p.1)) := by
  sorry

lemma reverse_zero : reverse (0 : Kernel α (β × γ × δ)) = 0 := by
  sorry

instance (κ : Kernel α (β × γ × δ)) [IsMarkovKernel κ] : IsMarkovKernel (reverse κ) := by
  rw [reverse_eq]; apply IsMarkovKernel.map _ (by fun_prop)

instance (κ : Kernel α (β × γ × δ)) [IsZeroOrMarkovKernel κ] :
    IsZeroOrMarkovKernel (reverse κ) := by
  rw [reverse_eq]; infer_instance

@[simp]
lemma swapRight_snd_reverse (κ : Kernel α (β × γ × δ)) :
    swapRight (snd (reverse κ)) = deleteRight κ := by
  sorry

/-- Reversing preserves finite kernel support -/
lemma FiniteKernelSupport.reverse
    [MeasurableSingletonClass α] [MeasurableSingletonClass β] [MeasurableSingletonClass γ]
    {κ : Kernel T (α × β × γ)} (hκ : FiniteKernelSupport κ) :
    FiniteKernelSupport (reverse κ) := by
  sorry

end
end ProbabilityTheory.Kernel
