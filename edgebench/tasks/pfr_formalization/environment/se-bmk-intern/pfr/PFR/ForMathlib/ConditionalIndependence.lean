module

public import Mathlib.Tactic.Finiteness
public import PFR.Mathlib.Probability.IdentDistrib
public import PFR.ForMathlib.FiniteRange.ConditionalProbability
public import PFR.ForMathlib.Pair

@[expose] public section

open MeasureTheory Measure Set
open scoped ENNReal

namespace ProbabilityTheory

section

variable {Ω α β : Type*} {_ : MeasurableSpace Ω} {_ : MeasurableSpace α} {_ : MeasurableSpace β}
  {μ : Measure Ω} {A : Ω → α} {B : Ω → β}

/-- If `A` is independent of `B`, then they remain independent when conditioning on an event
of the form `B ∈ t` of positive probability. -/
lemma IndepFun.cond_right (h : IndepFun A B μ) {t : Set β}
    (ht : MeasurableSet t) (hB : Measurable B) :
    IndepFun A B (μ[| B⁻¹' t]) := by
  sorry

end

section defs
variable {Ω Ω' α β γ : Type*} [MeasurableSpace Ω] [MeasurableSpace Ω'] [MeasurableSpace α]
  [MeasurableSpace β] [MeasurableSpace γ] {μ : Measure Ω} {f : Ω → α} {g : Ω → β} {h : Ω → γ}

/-- The assertion that `f` and `g` are conditionally independent relative to `h`. -/
def CondIndepFun (f : Ω → α) (g : Ω → β) (h : Ω → γ) (μ : Measure Ω := by volume_tac) : Prop :=
  ∀ᵐ z ∂ (μ.map h), IndepFun f g (μ[|h ← z])

variable [MeasurableSingletonClass γ]

end defs

section copy
universe u
variable {Ω : Type*} {α β : Type u} [MeasurableSpace Ω] [MeasurableSpace α] [MeasurableSpace β]
    [MeasurableSingletonClass β]

variable [Countable β] -- can we remove this hp?

open Function Set Measure

end copy
end ProbabilityTheory
