import ConNF.FOA.StrAction
import ConNF.FOA.StrApproxFOA

/-!
# Freedom of action for structural actions

In this file, we state and prove the freedom of action theorem for structural actions.

## Main declarations

* `ConNF.StrAction.freedomOfAction`: Freedom of action for structural actions.
-/

noncomputable section
universe u

open Cardinal Ordinal

namespace ConNF

variable [Params.{u}] [Level] [CoherentData] {β : TypeIndex} [LeLevel β]

namespace StrAction

def FreedomOfAction (β : TypeIndex) [LeLevel β] : Prop :=
  ∀ ξ : StrAction β, ξ.Coherent → ∃ ρ, ξ.Approximates ρ

theorem approximates_of_flexApprox_exactlyApproximates {ξ : StrAction β} (hξ : ξ.Coherent)
    {ρ : AllPerm β} (hρ : ξ.flexApprox.ExactlyApproximates ρ) :
    ξ.Approximates ρ := by
  sorry

theorem freedomOfAction : FreedomOfAction β := by
  sorry

end StrAction
end ConNF
