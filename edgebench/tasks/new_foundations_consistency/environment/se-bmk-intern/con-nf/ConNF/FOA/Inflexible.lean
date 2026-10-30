import ConNF.ModelData.CoherentData

/-!
# New file

In this file...

## Main declarations

* `ConNF.foo`: Something new.
-/

noncomputable section
universe u

open Cardinal Ordinal

namespace ConNF

variable [Params.{u}] {β : TypeIndex}

@[ext]
structure InflexiblePath (β : TypeIndex) where
  γ : Λ
  δ : TypeIndex
  ε : Λ
  hδ : δ < γ
  hε : (ε : TypeIndex) < γ
  hδε : δ ≠ ε
  A : β ↝ γ

instance {β β' : TypeIndex} : Coderivative (InflexiblePath β) (InflexiblePath β') β' β where
  coderiv P B := ⟨P.γ, P.δ, P.ε, P.hδ, P.hε, P.hδε, B ⇘ P.A⟩

variable [Level] [CoherentData]

instance [LeLevel β] (P : InflexiblePath β) : LeLevel P.γ :=
  ⟨P.A.le.trans LeLevel.elim⟩

instance [LeLevel β] (P : InflexiblePath β) : LtLevel P.δ :=
  ⟨P.hδ.trans_le LeLevel.elim⟩

instance [LeLevel β] (P : InflexiblePath β) : LtLevel P.ε :=
  ⟨P.hε.trans_le LeLevel.elim⟩

def Inflexible [LeLevel β] (A : β ↝ ⊥) (L : Litter) : Prop :=
  ∃ P : InflexiblePath β, ∃ t, A = P.A ↘ P.hε ↘. ∧ L = fuzz P.hδε t

theorem not_inflexible_iff [LeLevel β] (A : β ↝ ⊥) (L : Litter) :
    ¬Inflexible A L ↔ ∀ P : InflexiblePath β, ∀ t, A = P.A ↘ P.hε ↘. → L ≠ fuzz P.hδε t := by
  sorry

def inflexiblePathEmbedding :
    InflexiblePath β ↪ Set.Iic β × Set.Iic β × (γ : TypeIndex) × β ↝ γ where
  toFun P := ⟨⟨P.δ, P.hδ.le.trans P.A.le⟩, ⟨P.ε, P.hε.le.trans P.A.le⟩, P.γ, P.A⟩
  inj' := by
    rintro ⟨⟩ ⟨⟩ h
    cases h
    rfl

end ConNF
