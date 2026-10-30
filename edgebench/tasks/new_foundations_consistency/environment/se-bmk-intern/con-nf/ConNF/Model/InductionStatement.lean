import ConNF.ModelData.CoherentData
import ConNF.Construction.Code

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

structure Motive (α : Λ) where
  data : ModelData α
  pos : Position (Tangle α)
  typed : TypedNearLitters α

theorem card_tangle_bot_le [ModelData ⊥] : #(Tangle ⊥) ≤ #μ := by
  sorry

def botPosition [ModelData ⊥] : Position (Tangle ⊥) where
  pos := ⟨funOfDeny card_tangle_bot_le (λ t ↦ pos '' (t.supportᴬ.image Prod.snd : Set Atom))
      λ _ ↦ mk_image_le.trans_lt ((Enumeration.coe_small _).trans_le κ_le_μ_ord_cof),
    funOfDeny_injective _ _ _⟩

theorem pos_tangle_bot {D : ModelData ⊥} (t : Tangle ⊥) (a : Atom) (A : ⊥ ↝ ⊥)
    (ha : a ∈ (t.support ⇘. A)ᴬ) :
    letI := botPosition
    pos a < pos t := by
  sorry

structure Hypothesis {α : Λ} (M : Motive α) (N : (β : Λ) → (β : TypeIndex) < α → Motive β) where
  allPermSderiv {β : Λ} (h : (β : TypeIndex) < α) : M.data.AllPerm → (N β h).data.AllPerm
  allPermBotSderiv : M.data.AllPerm → botModelData.AllPerm
  singleton {β : Λ} (h : (β : TypeIndex) < α) : (N β h).data.TSet → M.data.TSet
  allPermSderiv_forget {β : Λ} (h : (β : TypeIndex) < α) (ρ : M.data.AllPerm) :
    (N β h).data.allPermForget (allPermSderiv h ρ) = M.data.allPermForget ρ ↘ h
  allPermBotSderiv_forget (ρ : M.data.AllPerm) :
    botModelData.allPermForget (allPermBotSderiv ρ) = M.data.allPermForget ρ ↘ bot_lt_coe _
  pos_atom_lt_pos :
    letI := M.data; letI := M.pos
    ∀ (t : Tangle α) (A : α ↝ ⊥) (a : Atom), a ∈ (t.support ⇘. A)ᴬ → pos a < pos t
  pos_nearLitter_lt_pos :
    letI := M.data; letI := M.pos
    ∀ (t : Tangle α) (A : α ↝ ⊥) (N : NearLitter), N ∈ (t.support ⇘. A)ᴺ → pos N < pos t
  smul_fuzz {β γ : Λ} (hβ : (β : TypeIndex) < α)
      (hγ : (γ : TypeIndex) < α) (hβγ : (β : TypeIndex) ≠ γ) :
    letI := (N β hβ).data; letI := (N β hβ).pos
    ∀ (ρ : M.data.AllPerm) (t : Tangle β),
    M.data.allPermForget ρ ↘ hγ ↘. • fuzz hβγ t = fuzz hβγ (allPermSderiv hβ ρ • t)
  smul_fuzz_bot {γ : Λ} (hγ : (γ : TypeIndex) < α) :
    letI := botModelData; letI := botPosition
    ∀ (ρ : M.data.AllPerm) (t : Tangle ⊥),
    M.data.allPermForget ρ ↘ hγ ↘. • fuzz (bot_ne_coe (a := γ)) t =
      fuzz (bot_ne_coe (a := γ)) (allPermBotSderiv ρ • t)
  allPerm_of_smul_fuzz :
    ∀ (ρs : {β : Λ} → (hβ : (β : TypeIndex) < α) → (N β hβ).data.AllPerm)
    (π : letI := botModelData; AllPerm ⊥),
    (∀ {β γ : Λ} (hβ : (β : TypeIndex) < α) (hγ : (γ : TypeIndex) < α),
      letI := (N β hβ).data; letI := (N β hβ).pos
      ∀ (hδε : (β : TypeIndex) ≠ γ) (t : Tangle β),
      (ρs hγ)ᵁ ↘. • fuzz hδε t = fuzz hδε (ρs hβ • t)) →
    (∀ {γ : Λ} (hγ : (γ : TypeIndex) < α) (t : letI := botModelData; Tangle ⊥),
      letI := botModelData; letI := botPosition
      (ρs hγ)ᵁ ↘. • fuzz (bot_ne_coe (a := γ)) t = fuzz (bot_ne_coe (a := γ)) (π • t)) →
    ∃ ρ : M.data.AllPerm,
      (∀ (β : Λ) (hβ : (β : TypeIndex) < α), allPermSderiv hβ ρ = ρs hβ) ∧
      allPermBotSderiv ρ = π
  tSet_ext (β : Λ) (hβ : (β : TypeIndex) < α) (x y : M.data.TSet) :
    (∀ z : (N β hβ).data.TSet, z ∈[hβ] x ↔ z ∈[hβ] y) → x = y
  typedMem_singleton_iff {β : Λ} (hβ : (β : TypeIndex) < α) (x y : (N β hβ).data.TSet) :
    y ∈[hβ] singleton hβ x ↔ y = x

def castTSet {α β : TypeIndex} {D₁ : ModelData α} {D₂ : ModelData β}
    (h₁ : α = β) (h₂ : HEq D₁ D₂) :
    D₁.TSet ≃ D₂.TSet := by cases h₁; rw [eq_of_heq h₂]

def castAllPerm {α β : TypeIndex} {D₁ : ModelData α} {D₂ : ModelData β}
    (h₁ : α = β) (h₂ : HEq D₁ D₂) :
    D₁.AllPerm ≃ D₂.AllPerm := by cases h₁; rw [eq_of_heq h₂]

def castTangle {α β : TypeIndex} {D₁ : ModelData α} {D₂ : ModelData β}
    (h₁ : α = β) (h₂ : HEq D₁ D₂) :
    (letI := D₁; Tangle α) ≃ (letI := D₂; Tangle β) := by cases h₁; rw [eq_of_heq h₂]

end ConNF
