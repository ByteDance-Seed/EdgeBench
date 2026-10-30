module

public import Mathlib.MeasureTheory.Constructions.Pi
public import Mathlib.Probability.Independence.Basic
public import PFR.Mathlib.Probability.Independence.Kernel.IndepFun

public section

open Function MeasureTheory MeasurableSpace Measure Set
open scoped MeasureTheory ENNReal

namespace ProbabilityTheory
variable {Ω ι β β' γ : Type*} {κ : ι → Type*} {mΩ : MeasurableSpace Ω} {μ : Measure Ω} {f : Ω → β}
  {g : Ω → β'}

end ProbabilityTheory

namespace ProbabilityTheory
variable {Ω ι β γ : Type*} {κ : ι → Type*}

section IndepFun
variable {β β' γ γ' : Type*} {mΩ : MeasurableSpace Ω} {μ : Measure Ω} {f : Ω → β} {g : Ω → β'}

section iIndepFun

variable {Ω ι ι' : Type*} [MeasurableSpace Ω] {α β : ι → Type*}
  [n : ∀ i, MeasurableSpace (α i)]
  [m : ∀ i, MeasurableSpace (β i)] {f : ∀ i, Ω → α i}
  {μ : Measure Ω}

variable (i : ι) [Inv (α i)] [MeasurableInv (α i)] [DecidableEq ι] in
@[to_additive]
lemma iIndepFun.inv (h : iIndepFun f μ) : iIndepFun (update f i (f i)⁻¹) μ := by
  sorry

/-- If `f` is a family of mutually independent random variables, `(S j)ⱼ` are pairwise disjoint
finite index sets, then the tuples formed by `f i` for `i ∈ S j` are mutually independent,
when seen as a family indexed by `J`. -/
lemma iIndepFun.finsets {f : ∀ i, Ω → β i} {J : Type*} [Finite J]
    (S : J → Finset ι) (h_disjoint : Set.PairwiseDisjoint Set.univ S)
    (hf_Indep : iIndepFun f μ) (hf_meas : ∀ i, Measurable (f i)) :
    iIndepFun (fun (j : J) ↦ fun a (i : S j) ↦ f i a) μ := by
  sorry

universe u

end iIndepFun

variable {Ω' α : Type*} [MeasurableSpace Ω'] [MeasurableSpace α] [MeasurableSpace β]

@[simp] lemma indepFun_zero_measure {f : Ω → α} {g : Ω → β} : IndepFun f g (0 : Measure Ω) := by
  sorry

variable {f : Ω → α} {g : Ω → β}

-- Same as `iIndepFun_iff` except that the function `f'` returns measurable sets even on junk values
lemma iIndepFun_iff' [MeasurableSpace Ω] {β : ι → Type*}
    (m : ∀ i, MeasurableSpace (β i)) (f : ∀ i, Ω → β i) (μ : Measure Ω) :
    iIndepFun f μ ↔ ∀ (s : Finset ι) ⦃f' : ι → Set Ω⦄
      (_hf' : ∀ i, MeasurableSet[(m i).comap (f i)] (f' i)),
      μ (⋂ i ∈ s, f' i) = ∏ i ∈ s, μ (f' i) := by
  sorry

end IndepFun
end ProbabilityTheory

namespace ProbabilityTheory
variable {ι Ω : Type*} {κ : ι → Type*} {α : ∀ i, κ i → Type*} [MeasurableSpace Ω] {μ : Measure Ω}
  [m : ∀ i j, MeasurableSpace (α i j)] {f : ∀ i j, Ω → α i j}

lemma measurable_sigmaCurry :
    Measurable (Sigma.curry : (∀ ij : Σ i, κ i, α ij.1 ij.2) → ∀ i j, α i j) := by
  sorry

variable [Fintype ι] [∀ i, Fintype (κ i)]

@[to_additive]
lemma _root_.Finset.prod_univ_prod {β : Type*} [CommMonoid β] (f : ∀ i, κ i → β) :
    (∏ ij : (i : ι) × κ i, f ij.1 ij.2) = (∏ i : ι, ∏ j : κ i, f i j) := by
  sorry

@[to_additive]
lemma _root_.Finset.prod_univ_prod' {β : Type*} [CommMonoid β] (f : ((i : ι) × κ i) → β) :
    (∏ ij : (i : ι) × κ i, f ij) = (∏ i : ι, ∏ j : κ i, f ⟨i, j⟩) := by
  sorry

variable {ι : Type*} {κ : ι → Type*} [∀ i, Finite (κ i)]
  {α : ∀ i, κ i → Type*} {f : ∀ i j, Ω → α i j} [m : ∀ i j, MeasurableSpace (α i j)]

variable {ι ι' : Type*} {α : ι → Type*}
    {n : (i : ι) → MeasurableSpace (α i)} {f : (i : ι) → Ω → α i}

lemma iIndepFun.prod {hf : ∀ (i : ι), Measurable (f i)} {ST : ι' → Finset ι}
    (hS : Pairwise (Disjoint on ST)) (h : iIndepFun f μ) :
    let β := fun k ↦ Π i : ST k, α i
    iIndepFun (β := β) (fun (k : ι') (x : Ω) (i : ST k) ↦ f i x) μ := by
  sorry

variable {β β' Ω : Type*} {mΩ : MeasurableSpace Ω} {μ : Measure Ω}

end ProbabilityTheory
