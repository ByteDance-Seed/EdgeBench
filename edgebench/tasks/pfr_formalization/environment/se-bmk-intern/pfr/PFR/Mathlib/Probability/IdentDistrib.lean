module

public import Mathlib.Probability.IdentDistrib
public import PFR.Mathlib.MeasureTheory.Constructions.Pi
public import PFR.Mathlib.Probability.Independence.Basic

public section

-- TODO: Change `ae_snd` to assume `Measurable p`

noncomputable section

open MeasureTheory Measure Filter Set
open scoped Topology MeasureTheory ENNReal NNReal

attribute [symm] ProbabilityTheory.IdentDistrib.symm

variable {α β γ δ : Type*} [MeasurableSpace α] [MeasurableSpace β] [MeasurableSpace γ]
  [MeasurableSpace δ]

namespace ProbabilityTheory
variable {μ : Measure α} {ν : Measure β} {f f' : α → γ} {g g' : β → γ} {s : Set γ}

attribute [mk_iff] IdentDistrib

@[simp] lemma identDistrib_id {μ ν : Measure α} : IdentDistrib id id μ ν ↔ μ = ν := by
  sorry

-- TODO: Can we get rid of the measurability assumption in the following two?
-- https://leanprover.zulipchat.com/#narrow/stream/217875-Is-there-code-for-X.3F/topic/docs.23MeasureTheory.2EMeasure.2Emap_map

/-- Composing identically distributed functions with a measurable embedding of conull range
gives identically distributed functions. -/
lemma IdentDistrib.comp_right {i : δ → β} (hi : MeasurableEmbedding i) (hi' : ∀ᵐ a ∂ν, a ∈ range i)
    (hg : Measurable g) (hfg : IdentDistrib f g μ ν) : IdentDistrib f (g ∘ i) μ (ν.comap i) := by
  sorry

end ProbabilityTheory

open MeasureTheory ProbabilityTheory Function Set

namespace ProbabilityTheory
section IdentDistrib
universe u u' v
variable {Ω Ω' α ι β β' T : Type*} {mΩ : MeasurableSpace Ω} {mΩ' : MeasurableSpace Ω'}
  {mβ : MeasurableSpace β} {μ : Measure Ω} {ν : Measure Ω'} {f g : Ω → β} {f' g' : Ω' → β}

variable [IsFiniteMeasure μ] [IsFiniteMeasure ν] in
theorem IdentDistrib.prodMk (hff' : IdentDistrib f f' μ ν) (hgg' : IdentDistrib g g' μ ν)
    (h : IndepFun f g μ) (h' : IndepFun f' g' ν) :
    IdentDistrib (fun x ↦ (f x, g x)) (fun x ↦ (f' x, g' x)) μ ν := by
  sorry

variable [Mul β] [MeasurableMul₂ β] [IsFiniteMeasure μ] [IsFiniteMeasure ν] in
@[to_additive]
theorem IdentDistrib.mul
    (hff' : IdentDistrib f f' μ ν) (hgg' : IdentDistrib g g' μ ν)
    (h : IndepFun f g μ) (h' : IndepFun f' g' ν) :
    IdentDistrib (f * g) (f' * g') μ ν := by
  sorry

variable [MeasurableSpace α] [MeasurableSpace β]

end IdentDistrib
end ProbabilityTheory
