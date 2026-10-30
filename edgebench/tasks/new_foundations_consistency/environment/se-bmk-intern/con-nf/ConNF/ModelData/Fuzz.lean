import ConNF.Position.BasePositions
import ConNF.ModelData.ModelData

/-!
# The fuzz map

In this file, we define the `fuzz` map.

## Main declarations

* `ConNF.fuzz`: The `fuzz` map.
-/

noncomputable section
universe u

open Cardinal Ordinal

namespace ConNF

variable [Params.{u}]

section fuzz

variable {β : TypeIndex} [ModelData β] [Position (Tangle β)] {γ : Λ}

def fuzz (hβγ : β ≠ γ) : Tangle β → Litter :=
  (⟨·, β, γ, hβγ⟩) ∘ funOfDeny card_le_of_position (λ t ↦ {pos t})
    (λ _ ↦ (mk_singleton _).trans_lt (one_lt_aleph0.trans aleph0_lt_μ_ord_cof))

theorem fuzz_γ_eq {β' : TypeIndex} [ModelData β'] [Position (Tangle β')] {γ' : Λ}
    {hβγ : β ≠ γ} {hβγ' : β' ≠ γ'} {t : Tangle β} {t' : Tangle β'}
    (h : fuzz hβγ t = fuzz hβγ' t') :
    γ = γ' := by
  sorry

end fuzz

end ConNF
