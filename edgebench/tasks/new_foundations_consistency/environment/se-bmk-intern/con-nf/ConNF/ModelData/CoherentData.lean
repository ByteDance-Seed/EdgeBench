import ConNF.ModelData.Fuzz
import ConNF.ModelData.Level
import ConNF.ModelData.ModelData

/-!
# Coherent data

In this file, we define the type of coherent data below a particular proper type index.

## Main declarations

* `ConNF.ModelDataData`: Coherent data below a given level `α`.
-/

noncomputable section
universe u

open Cardinal Ordinal

namespace ConNF

/-!
TODO: We're going to try allowing model data at level `⊥` to vary. That is, we use
`(β : TypeIndex) → [LeLevel β] → ModelData β` instead of `(β : Λ) → [LeLevel β] → ModelData β`.
-/

variable [Params.{u}] [Level]

/-- A convenience typeclass to hold data below the current level. -/
@[ext]
class LeData where
  [data : (β : TypeIndex) → [LeLevel β] → ModelData β]
  [positions : (β : TypeIndex) → [LtLevel β] → Position (Tangle β)]

instance [LeData] : (β : TypeIndex) → [LeLevel β] → ModelData β :=
  LeData.data

instance [LeData] : (β : TypeIndex) → [LtLevel β] → Position (Tangle β) :=
  LeData.positions

@[ext]
class PreCoherentData extends LeData where
  allPermSderiv {β γ : TypeIndex} [LeLevel β] [LeLevel γ] (h : γ < β) : AllPerm β → AllPerm γ
  singleton {β γ : Λ} [LeLevel β] [LeLevel γ] (h : (γ : TypeIndex) < β) : TSet γ → TSet β

export PreCoherentData (singleton)

instance [PreCoherentData] {β γ : TypeIndex} [LeLevel β] [LeLevel γ] :
    Derivative (AllPerm β) (AllPerm γ) β γ where
  deriv ρ A := A.recSderiv
    (motive := λ (δ : TypeIndex) (A : β ↝ δ) ↦
      letI : LeLevel δ := ⟨A.le.trans LeLevel.elim⟩; AllPerm δ)
    ρ (λ δ ε A h ρ ↦
      letI : LeLevel δ := ⟨A.le.trans LeLevel.elim⟩
      letI : LeLevel ε := ⟨h.le.trans LeLevel.elim⟩
      PreCoherentData.allPermSderiv h ρ)

/--
Note that in earlier versions of the proof we additionally used the following assumption.
```
typedMem_tSetForget {β : Λ} {γ : TypeIndex} [LeLevel β] [LeLevel γ]
  (hγ : γ < β) (x : TSet β) (y : StrSet γ) :
  y ∈[hγ] xᵁ → ∃ z : TSet γ, y = zᵁ
```
-/
@[ext]
class CoherentData extends PreCoherentData where
  allPermSderiv_forget {β γ : TypeIndex} [LeLevel β] [LeLevel γ] (h : γ < β) (ρ : AllPerm β) :
    (ρ ↘ h)ᵁ = ρᵁ ↘ h
  pos_atom_lt_pos {β : TypeIndex} [LtLevel β] (t : Tangle β) (A : β ↝ ⊥) (a : Atom) :
    a ∈ (t.support ⇘. A)ᴬ → pos a < pos t
  pos_nearLitter_lt_pos {β : TypeIndex} [LtLevel β] (t : Tangle β) (A : β ↝ ⊥) (N : NearLitter) :
    N ∈ (t.support ⇘. A)ᴺ → pos N < pos t
  smul_fuzz {γ : Λ} {δ : TypeIndex} {ε : Λ} [LeLevel γ] [LtLevel δ] [LtLevel ε]
    (hδ : δ < γ) (hε : (ε : TypeIndex) < γ) (hδε : δ ≠ ε) (ρ : AllPerm γ) (t : Tangle δ) :
    ρᵁ ↘ hε ↘. • fuzz hδε t = fuzz hδε (ρ ↘ hδ • t)
  allPerm_of_basePerm (π : BasePerm) : ∃ ρ : AllPerm ⊥, ρᵁ Path.nil = π
  allPerm_of_smulFuzz {γ : Λ} [LeLevel γ]
    (ρs : {δ : TypeIndex} → [LtLevel δ] → δ < γ → AllPerm δ)
    (h : ∀ {δ : TypeIndex} {ε : Λ} [LtLevel δ] [LtLevel ε]
      (hδ : δ < γ) (hε : (ε : TypeIndex) < γ) (hδε : δ ≠ ε) (t : Tangle δ),
      (ρs hε)ᵁ ↘. • fuzz hδε t = fuzz hδε (ρs hδ • t)) :
    ∃ ρ : AllPerm γ, ∀ δ : TypeIndex, [LtLevel δ] → ∀ hδ : δ < γ, ρ ↘ hδ = ρs hδ
  tSet_ext {β γ : Λ} [LeLevel β] [LeLevel γ] (hγ : (γ : TypeIndex) < β) (x y : TSet β)
    (h : ∀ z : TSet γ, z ∈[hγ] x ↔ z ∈[hγ] y) : x = y
  typedMem_singleton_iff {β γ : Λ} [LeLevel β] [LeLevel γ]
    (hγ : (γ : TypeIndex) < β) (x y : TSet γ) :
    y ∈[hγ] singleton hγ x ↔ y = x

export CoherentData (allPermSderiv_forget pos_atom_lt_pos pos_nearLitter_lt_pos smul_fuzz
  allPerm_of_basePerm allPerm_of_smulFuzz tSet_ext typedMem_singleton_iff)

attribute [simp] allPermSderiv_forget typedMem_singleton_iff

end ConNF
