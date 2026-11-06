import ConNF.FOA.FlexApprox

/-!
# Structural actions

In this file, we define structural actions, and prove the freedom of action theorem for actions.

## Main declarations

* `ConNF.StrAction`: Structural actions.
-/

noncomputable section
universe u

open Cardinal Ordinal

namespace ConNF

variable [Params.{u}]

abbrev StrAction : TypeIndex → Type u :=
  Tree BaseAction

namespace StrAction

variable [Level] [CoherentData] {β : TypeIndex} [LeLevel β] {A : β ↝ ⊥}

def Coherent (ξ : StrAction β) : Prop :=
  ∀ A L₁ L₂, (ξ A)ᴸ L₁ L₂ → CoherentAt ξ A L₁ L₂

theorem Coherent.deriv {ξ : StrAction β} (hξ : ξ.Coherent)
    {γ : TypeIndex} [LeLevel γ] (A : β ↝ γ) :
    Coherent (ξ ⇘ A) := by
  sorry

end StrAction

/-- TODO: Maybe move this to `BaseActionClass`? -/
structure BaseAction.Approximates (ξ : BaseAction) (π : BasePerm) : Prop where
  atoms : ∀ a₁ a₂, ξᴬ a₁ a₂ → a₂ = π • a₁
  nearLitters : ∀ N₁ N₂, ξᴺ N₁ N₂ → N₂ = π • N₁

theorem BaseAction.Approximates.litters {ξ : BaseAction} {π : BasePerm} (h : ξ.Approximates π)
    (L₁ L₂ : Litter) : ξᴸ L₁ L₂ → π • L₁ = L₂ := by
  sorry

theorem BaseAction.Approximates.mono {ψ χ : BaseAction} {π : BasePerm}
    (hχ : χ.Approximates π) (h : ψ ≤ χ) :
    ψ.Approximates π := by
  sorry

def StrAction.Approximates {β : TypeIndex} [ModelData β]
    (ξ : StrAction β) (ρ : AllPerm β) : Prop :=
  ∀ A, (ξ A).Approximates (ρᵁ A)

def StrAction.flexApprox [Level] {β : TypeIndex} [LeLevel β] [CoherentData]
    (ξ : StrAction β) : StrApprox β :=
  λ A ↦ (ξ A).flexApprox A

/-- TODO: Put this in the blueprint. -/
theorem StrAction.flexApprox_coherent [Level] {β : TypeIndex} [LeLevel β] [CoherentData]
    (ξ : StrAction β) (hξ : ∀ A, (ξ A).MapFlexible A) :
    StrApprox.Coherent ξ.flexApprox := by
  sorry

end ConNF
