module

public import PFR.Mathlib.Probability.IdentDistrib
public import PFR.ForMathlib.FiniteRange.Defs

public section

-- TODO: Change `ae_snd` to assume `Measurable p`

noncomputable section

open MeasureTheory Measure Filter Set
open scoped Topology MeasureTheory ENNReal NNReal

namespace ProbabilityTheory
section IdentDistrib
universe u u' v
variable {Ω Ω' α ι β β' T : Type*} {mΩ : MeasurableSpace Ω} {mΩ' : MeasurableSpace Ω'}
  {mα : MeasurableSpace α} {mβ : MeasurableSpace β} {μ : Measure Ω} {ν : Measure Ω'} {f g : Ω → β}
  {f' g' : Ω' → β}

/-- A version of `independent_copies` that guarantees that the copies have `FiniteRange` if the
original variables do. -/
lemma independent_copies_finiteRange {X : Ω → α} {Y : Ω' → β}
    (hX : Measurable X) (hY : Measurable Y) [FiniteRange X] [FiniteRange Y]
    [MeasurableSingletonClass α] [MeasurableSingletonClass β]
    (μ : Measure Ω) (μ' : Measure Ω') [IsProbabilityMeasure μ] [IsProbabilityMeasure μ'] :
    ∃ ν : Measure (α × β), ∃ X' : α × β → α, ∃
    Y' : α × β → β, IsProbabilityMeasure ν
      ∧ Measurable X' ∧ Measurable Y' ∧ IndepFun X' Y' ν
      ∧ IdentDistrib X' X ν μ ∧ IdentDistrib Y' Y ν μ' ∧ FiniteRange X' ∧ FiniteRange Y' := by
  sorry

/-- A version of `independent_copies4_nondep` that guarantees that the copies have `FiniteRange`
if the original variables do. -/
lemma independent_copies4_nondep_finiteRange {α : Type u}
    [mS : MeasurableSpace α] [MeasurableSingletonClass α]
    {Ω₁ : Type u_1} {Ω₂ : Type u_2} {Ω₃ : Type u_3} {Ω₄ : Type u_4}
    [MeasurableSpace Ω₁] [MeasurableSpace Ω₂] [MeasurableSpace Ω₃] [MeasurableSpace Ω₄]
    {X₁ : Ω₁ → α} {X₂ : Ω₂ → α} {X₃ : Ω₃ → α} {X₄ : Ω₄ → α}
    (hX₁ : Measurable X₁) (hX₂ : Measurable X₂) (hX₃ : Measurable X₃) (hX₄ : Measurable X₄)
    [FiniteRange X₁] [FiniteRange X₂] [FiniteRange X₃] [FiniteRange X₄]
    (μ₁ : Measure Ω₁) (μ₂ : Measure Ω₂) (μ₃ : Measure Ω₃) (μ₄ : Measure Ω₄)
    [hμ₁ : IsProbabilityMeasure μ₁] [hμ₂ : IsProbabilityMeasure μ₂] [hμ₃ : IsProbabilityMeasure μ₃]
    [hμ₄ : IsProbabilityMeasure μ₄] :
    ∃ (A : Type (max u_1 u_2 u_3 u_4)) (_ : MeasurableSpace A) (μA : Measure A)
      (X₁' X₂' X₃' X₄' : A → α),
    IsProbabilityMeasure μA ∧
    iIndepFun ![X₁', X₂', X₃', X₄'] μA ∧
      Measurable X₁' ∧ Measurable X₂' ∧ Measurable X₃' ∧ Measurable X₄'
      ∧ IdentDistrib X₁' X₁ μA μ₁ ∧ IdentDistrib X₂' X₂ μA μ₂ ∧ IdentDistrib X₃' X₃ μA μ₃
      ∧ IdentDistrib X₄' X₄ μA μ₄ ∧ FiniteRange X₁' ∧ FiniteRange X₂'
      ∧ FiniteRange X₃' ∧ FiniteRange X₄' := by
  sorry

/-
  have : Nonempty α := μ.nonempty_of_neZero.map X
  have : Nonempty β := μ'.nonempty_of_neZero.map Y
  obtain ⟨ν, X', Y', hν, hX', hY', hind, hIdX, hIdY⟩ := independent_copies hX hY μ μ'
  rcases identDistrib_of_finiteRange hX' hIdX.symm with ⟨X'', hX'', hX''_finite, hX''_eq⟩
  rcases identDistrib_of_finiteRange hY' hIdY.symm with ⟨Y'', hY'', hY''_finite, hY''_eq⟩
  use ν, X'', Y''
  refine ⟨hν, hX'', hY'', ?_, ?_, ?_, hX''_finite, hY''_finite⟩
  · exact hind.congr hX''_eq.symm hY''_eq.symm
  · convert IdentDistrib.trans _ hIdX
    exact IdentDistrib.of_ae_eq (Measurable.aemeasurable hX'') hX''_eq
  · convert IdentDistrib.trans _ hIdY
    exact IdentDistrib.of_ae_eq (Measurable.aemeasurable hY'') hY''_eq
-/

end IdentDistrib
end ProbabilityTheory
