import ConNF.Background.InductiveConstruction
import ConNF.Model.ConstructHypothesis

/-!
# New file

In this file...

## Main declarations

* `ConNF.foo`: Something new.
-/

noncomputable section
universe u

open Cardinal Ordinal WithBot

namespace ConNF

variable [Params.{u}]

instance : IsTrans Λ λ β γ ↦ (β : TypeIndex) < (γ : TypeIndex) :=
  ⟨λ _ _ _ ↦ lt_trans⟩

instance : IsWellFounded Λ λ β γ ↦ (β : TypeIndex) < (γ : TypeIndex) :=
  ⟨InvImage.wf _ (wellFounded_lt)⟩

def motive : (α : Λ) → Motive α :=
  ICT.fix constructMotive constructHypothesis

def hypothesis : (α : Λ) → Hypothesis (motive α) (λ β _ ↦ motive β) :=
  ICT.fix_prop constructMotive constructHypothesis

theorem motive_eq : (α : Λ) →
    motive α = constructMotive α (λ β _ ↦ motive β) (λ β _ ↦ hypothesis β) := by
  sorry

end ConNF
