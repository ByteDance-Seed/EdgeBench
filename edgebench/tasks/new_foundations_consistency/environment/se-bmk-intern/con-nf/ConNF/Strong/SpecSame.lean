import ConNF.FOA.StrActionFOA
import ConNF.Strong.Strong
import ConNF.Strong.Spec

/-!
# Supports with the same specification

In this file, we show that two strong supports with the same specification are related by
an allowable permutation.

## Main declarations

* `ConNF.exists_conv`: Two strong supports with the same specification are related by an allowable
  permutation.
-/

noncomputable section
universe u

open Cardinal Ordinal

namespace ConNF

variable [Params.{u}] [Level] [CoherentData] {β : TypeIndex} [LeLevel β] {S T : Support β}

namespace Support

theorem atom_mem_of_mem_of_spec_eq_spec (hST : S.spec = T.spec)
    {a₁ a₂ : Atom} {N₁ N₂ : NearLitter} {A : β ↝ ⊥}
    (ha : convAtoms S T A a₁ a₂) (hN : convNearLitters S T A N₁ N₂) (haN : a₁ ∈ N₁ᴬ) :
    a₂ ∈ N₂ᴬ := by
  sorry

theorem atom_mem_iff_mem_of_spec_eq_spec (hST : S.spec = T.spec)
    {a₁ a₂ : Atom} {N₁ N₂ : NearLitter} {A : β ↝ ⊥}
    (ha : convAtoms S T A a₁ a₂) (hN : convNearLitters S T A N₁ N₂) :
    a₁ ∈ N₁ᴬ ↔ a₂ ∈ N₂ᴬ := by
  sorry

theorem litter_eq_litter_of_convNearLitters_of_spec_eq_spec (hST : S.spec = T.spec) (hT : T.Strong)
    {N₁ N₂ N₃ N₄ : NearLitter} {A : β ↝ ⊥}
    (hN₁₃ : convNearLitters S T A N₁ N₃) (hN₂₄ : convNearLitters S T A N₂ N₄) (hN₁₂ : N₁ᴸ = N₂ᴸ) :
    N₃ᴸ = N₄ᴸ := by
  sorry

-- TODO: Fix blueprint: we need both that T is strong and that S is strong.
theorem litter_eq_litter_iff_of_convNearLitters_of_spec_eq_spec (hST : S.spec = T.spec)
    (hS : S.Strong) (hT : T.Strong) {N₁ N₂ N₃ N₄ : NearLitter} {A : β ↝ ⊥}
    (hN₁₃ : convNearLitters S T A N₁ N₃) (hN₂₄ : convNearLitters S T A N₂ N₄) :
    N₁ᴸ = N₂ᴸ ↔ N₃ᴸ = N₄ᴸ := by
  sorry

theorem interference_subset_convAtoms_dom (hST : S.spec = T.spec) (hS : S.Strong)
    {N₁ N₂ : NearLitter} {A : β ↝ ⊥}
    (hN₁ : N₁ ∈ (convNearLitters S T A).dom) (hN₂ : N₂ ∈ (convNearLitters S T A).dom) :
    interference N₁ N₂ ⊆ (convAtoms S T A).dom := by
  sorry

theorem interference_subset_convAtoms_codom (hST : S.spec = T.spec) (hT : T.Strong)
    {N₁ N₂ : NearLitter} {A : β ↝ ⊥}
    (hN₁ : N₁ ∈ (convNearLitters S T A).codom) (hN₂ : N₂ ∈ (convNearLitters S T A).codom) :
    interference N₁ N₂ ⊆ (convAtoms S T A).codom := by
  sorry

def convDeriv (hST : S.spec = T.spec) (hS : S.Strong) (hT : T.Strong) (A : β ↝ ⊥) :
    BaseAction where
  atoms := convAtoms S T A
  nearLitters := convNearLitters S T A
  atoms_dom_small' := by
    apply Small.mono (convAtoms_dom_subset S T A)
    exact (S ⇘. A)ᴬ.coe_small
  nearLitters_dom_small' := by
    apply Small.mono (convNearLitters_dom_subset S T A)
    exact (S ⇘. A)ᴺ.coe_small
  atoms_oneOne' := by
    rw [spec_eq_spec_iff] at hST
    exact hST.convAtoms_oneOne A
  mem_iff_mem' := by
    rintro a₁ a₂ N₁ N₂ ⟨i, hiS, hiT⟩ ⟨j, hjS, hjT⟩
    rw [spec_eq_spec_iff] at hST
    constructor
    · intro ha
      obtain ⟨N₃, hN₃T, a₃, haN₃, ha₃T⟩ := (iff_of_eq (congr_fun₂ (hST.atomMemRel_eq A) j i)).mp
        ⟨N₁, hjS, a₁, ha, hiS⟩
      cases (T ⇘. A)ᴬ.rel_coinjective.coinjective hiT ha₃T
      cases (T ⇘. A)ᴺ.rel_coinjective.coinjective hjT hN₃T
      exact haN₃
    · intro ha
      obtain ⟨N₃, hN₃S, a₃, haN₃, ha₃S⟩ := (iff_of_eq (congr_fun₂ (hST.atomMemRel_eq A) j i)).mpr
        ⟨N₂, hjT, a₂, ha, hiT⟩
      cases (S ⇘. A)ᴬ.rel_coinjective.coinjective hiS ha₃S
      cases (S ⇘. A)ᴺ.rel_coinjective.coinjective hjS hN₃S
      exact haN₃
  litter_eq_litter_iff' := litter_eq_litter_iff_of_convNearLitters_of_spec_eq_spec hST hS hT
  interference_subset_dom' := interference_subset_convAtoms_dom hST hS
  interference_subset_codom' := interference_subset_convAtoms_codom hST hT

abbrev conv (hST : S.spec = T.spec) (hS : S.Strong) (hT : T.Strong) : StrAction β :=
  convDeriv hST hS hT

theorem conv_coherentAt (hST : S.spec = T.spec) (hS : S.Strong) (hT : T.Strong)
    {A : β ↝ ⊥} {N₁ N₂ : NearLitter} (hN : convNearLitters S T A N₁ N₂) :
    CoherentAt (conv hST hS hT) A N₁ᴸ N₂ᴸ := by
  sorry

theorem conv_coherent (hST : S.spec = T.spec) (hS : S.Strong) (hT : T.Strong) :
    (conv hST hS hT).Coherent := by
  sorry

theorem exists_conv (hST : S.spec = T.spec) (hS : S.Strong) (hT : T.Strong) :
    ∃ ρ : AllPerm β, ρᵁ • S = T := by
  sorry

end Support

end ConNF
