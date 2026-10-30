import ConNF.Strong.Spec

/-!
# Action on specifications

In this file, we prove that the specification of a support is invariant under the action
of allowable permutations.

## Main declarations

* `ConNF.Support.smul_spec`: The specification of a support is invariant under the action
of allowable permutations.
-/

noncomputable section
universe u

open Cardinal Ordinal

namespace ConNF

variable [Params.{u}] [Level] [CoherentData] {β : TypeIndex} [LeLevel β]
  (S : Support β) (ρ : AllPerm β)

namespace Support

theorem convNearLitters_fuzz (A : β ↝ ⊥) (N₁ N₂ : NearLitter)
    (P : InflexiblePath β) (t : Tangle P.δ) (ρ' : AllPerm P.δ)
    (hA : A = P.A ↘ P.hε ↘.) (hN₁ : N₁ᴸ = fuzz P.hδε t) (hN₂ : N₂ᴸ = fuzz P.hδε (ρ' • t))
    (hN : convNearLitters S (ρᵁ • S) A N₁ N₂) :
    ρ' • t = ρ ⇘ P.A ↘ P.hδ • t := by
  sorry

theorem atoms_of_inflexible_smul (A : β ↝ ⊥) (N₁ N₂ : NearLitter)
    (P : InflexiblePath β) (t : Tangle P.δ) (ρ' : AllPerm P.δ)
    (hA : A = P.A ↘ P.hε ↘.) (hN₁ : N₁ᴸ = fuzz P.hδε t) (hN₂ : N₂ᴸ = fuzz P.hδε (ρ' • t))
    (hN : convNearLitters S (ρᵁ • S) A N₁ N₂) (B : P.δ ↝ ⊥)
    (a : Atom) (ha : a ∈ (t.support ⇘. B)ᴬ)
    (i : κ) (hiS : (S ⇘. (P.A ↘ P.hδ ⇘ B))ᴬ.rel i a) :
    ((ρᵁ • S) ⇘. (P.A ↘ P.hδ ⇘ B))ᴬ.rel i (ρ'ᵁ B • a) := by
  sorry

theorem nearLitters_of_inflexible_smul (A : β ↝ ⊥) (N₁ N₂ : NearLitter)
    (P : InflexiblePath β) (t : Tangle P.δ) (ρ' : AllPerm P.δ)
    (hA : A = P.A ↘ P.hε ↘.) (hN₁ : N₁ᴸ = fuzz P.hδε t) (hN₂ : N₂ᴸ = fuzz P.hδε (ρ' • t))
    (hN : convNearLitters S (ρᵁ • S) A N₁ N₂) (B : P.δ ↝ ⊥)
    (N : NearLitter) (ha : N ∈ (t.support ⇘. B)ᴺ)
    (i : κ) (hiS : (S ⇘. (P.A ↘ P.hδ ⇘ B))ᴺ.rel i N) :
    ((ρᵁ • S) ⇘. (P.A ↘ P.hδ ⇘ B))ᴺ.rel i (ρ'ᵁ B • N) := by
  sorry

@[simp]
theorem sameSpecLe_smul :
    SameSpecLE S (ρᵁ • S) := by
  sorry

@[simp]
theorem smul_spec :
    (ρᵁ • S).spec = S.spec := by
  sorry

end Support

end ConNF
