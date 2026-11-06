import ConNF.ModelData.CoherentData
import ConNF.FOA.Inflexible

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

class BaseActionClass (X : Type _) where
  atoms : X → Rel Atom Atom
  atoms_oneOne : ∀ ξ, (atoms ξ).OneOne
  nearLitters : X → Rel NearLitter NearLitter
  nearLitters_oneOne : ∀ ξ, (nearLitters ξ).OneOne

instance {X : Type _} [BaseActionClass X] : SuperA X (Rel Atom Atom) where
  superA := BaseActionClass.atoms

instance {X : Type _} [BaseActionClass X] : SuperN X (Rel NearLitter NearLitter) where
  superN := BaseActionClass.nearLitters

instance {X : Type _} [BaseActionClass X] : SMul X BaseSupport where
  smul ξ S := ⟨Sᴬ.comp ξᴬ (BaseActionClass.atoms_oneOne ξ).toCoinjective,
    Sᴺ.comp ξᴺ (BaseActionClass.nearLitters_oneOne ξ).toCoinjective⟩

instance {X : Type _} [BaseActionClass X] {β : TypeIndex} :
    SMul (Tree X β) (Support β) where
  smul ξ S := ⟨Sᴬ.comp (Enumeration.relWithPath λ A ↦ (ξ A)ᴬ)
      (Enumeration.relWithPath_coinjective
        λ A ↦ (BaseActionClass.atoms_oneOne (ξ A)).toCoinjective),
    Sᴺ.comp (Enumeration.relWithPath λ A ↦ (ξ A)ᴺ)
      (Enumeration.relWithPath_coinjective
        λ A ↦ (BaseActionClass.nearLitters_oneOne (ξ A)).toCoinjective)⟩

theorem smul_baseSupport_eq_smul_iff {X : Type _} [BaseActionClass X]
    (ξ : X) (S : BaseSupport) (π : BasePerm) :
    ξ • S = π • S ↔ (∀ a ∈ Sᴬ, ξᴬ a (π • a)) ∧ (∀ N ∈ Sᴺ, ξᴺ N (π • N)) := by
  sorry

theorem smul_support_eq_smul_iff {X : Type _} [BaseActionClass X]
    (ξ : Tree X β) (S : Support β) (π : StrPerm β) :
    ξ • S = π • S ↔ ∀ A,
      (∀ a ∈ (S ⇘. A)ᴬ, (ξ A)ᴬ a (π A • a)) ∧ (∀ N ∈ (S ⇘. A)ᴺ, (ξ A)ᴺ N (π A • N)) := by
  sorry

variable [Level] [CoherentData]

/-- `ξ` is defined coherently at `(A, L₁, L₂)` (or could be defined coherently at this triple). -/
structure CoherentAt [LeLevel β] {X : Type _} [BaseActionClass X]
    (ξ : Tree X β) (A : β ↝ ⊥) (L₁ L₂ : Litter) : Prop where
  inflexible (P : InflexiblePath β) (t : Tangle P.δ)
    (hA : A = P.A ↘ P.hε ↘.) (ht : L₁ = fuzz P.hδε t) :
    ∃ ρ : AllPerm P.δ, ξ ⇘ P.A ↘ P.hδ • t.support = ρᵁ • t.support ∧ L₂ = fuzz P.hδε (ρ • t)
  flexible (h : ¬Inflexible A L₁) : ¬Inflexible A L₂

theorem coherentAt_inflexible [LeLevel β] {X : Type _} [BaseActionClass X]
    {ξ : Tree X β} {A : β ↝ ⊥} {L₁ L₂ : Litter}
    {P : InflexiblePath β} {t : Tangle P.δ} (hA : A = P.A ↘ P.hε ↘.) (ht : L₁ = fuzz P.hδε t) :
    CoherentAt ξ A L₁ L₂ ↔ ∃ ρ : AllPerm P.δ,
      ξ ⇘ P.A ↘ P.hδ • t.support = ρᵁ • t.support ∧ L₂ = fuzz P.hδε (ρ • t) := by
  sorry

theorem smul_eq_of_coherentAt_inflexible [LeLevel β] {X : Type _} [BaseActionClass X]
    {ξ : Tree X β} {A : β ↝ ⊥} {L₁ L₂ : Litter}
    {P : InflexiblePath β} {t : Tangle P.δ} (hA : A = P.A ↘ P.hε ↘.) (ht : L₁ = fuzz P.hδε t)
    (h : CoherentAt ξ A L₁ L₂) :
    ∀ ρ : AllPerm P.δ, ξ ⇘ P.A ↘ P.hδ • t.support = ρᵁ • t.support → L₂ = fuzz P.hδε (ρ • t) := by
  sorry

theorem coherentAt_inflexible' [LeLevel β] {X : Type _} [BaseActionClass X]
    {ξ : Tree X β} {A : β ↝ ⊥} {L₁ L₂ : Litter}
    {P : InflexiblePath β} {t : Tangle P.δ} (hA : A = P.A ↘ P.hε ↘.) (ht : L₂ = fuzz P.hδε t) :
    CoherentAt ξ A L₁ L₂ ↔ ∃ ρ : AllPerm P.δ,
      ξ ⇘ P.A ↘ P.hδ • ρᵁ • t.support = t.support ∧ L₁ = fuzz P.hδε (ρ • t) := by
  sorry

theorem smul_eq_of_coherentAt_inflexible' [LeLevel β] {X : Type _} [BaseActionClass X]
    {ξ : Tree X β} {A : β ↝ ⊥} {L₁ L₂ : Litter}
    {P : InflexiblePath β} {t : Tangle P.δ} (hA : A = P.A ↘ P.hε ↘.) (ht : L₂ = fuzz P.hδε t)
    (h : CoherentAt ξ A L₁ L₂) :
    ∀ ρ : AllPerm P.δ, ξ ⇘ P.A ↘ P.hδ • ρᵁ • t.support = t.support → L₁ = fuzz P.hδε (ρ • t) := by
  sorry

theorem CoherentAt.deriv [LeLevel β] {γ : TypeIndex} [LeLevel γ] {X : Type _} [BaseActionClass X]
    {ξ : Tree X β} {L₁ L₂ : Litter} (A : β ↝ γ) (B : γ ↝ ⊥) (h : CoherentAt ξ (A ⇘ B) L₁ L₂) :
    CoherentAt (ξ ⇘ A) B L₁ L₂ := by
  sorry

end ConNF
