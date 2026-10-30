import ConNF.Background.PermutativeExtension
import ConNF.FOA.BaseAction
import ConNF.FOA.StrApprox

/-!
# Flexible approximations

In this file, we define flexible approximations.

## Main declarations

* `ConNF.FlexApprox`: Flexible approximations.
-/

noncomputable section
universe u

open Cardinal Ordinal
open scoped symmDiff Pointwise

namespace ConNF
namespace BaseAction

variable [Params.{u}]

/-- TODO: Fix definition in blueprint to this. -/
structure FlexApprox [Level] [CoherentData] {β : TypeIndex} [LeLevel β]
    (A : β ↝ ⊥) (ξ : BaseAction) (ψ : BaseApprox) : Prop where
  atoms_le_atoms : ξᴬ ≤ ψ.exceptions
  flexible_of_mem_dom {L : Litter} : L ∈ ψᴸ.dom → ¬Inflexible A L
  litters_of_flexible {L₁ L₂ : Litter} : ¬Inflexible A L₁ → ξᴸ L₁ L₂ → ψᴸ L₁ L₂
  symmDiff_subset_dom {N : NearLitter} : N ∈ ξᴺ.dom → Nᴬ ∆ Nᴸᴬ ⊆ ψ.exceptions.dom
  symmDiff_subset_codom {N : NearLitter} : N ∈ ξᴺ.codom → Nᴬ ∆ Nᴸᴬ ⊆ ψ.exceptions.codom
  mem_iff_mem {N₁ N₂ : NearLitter} : ξᴺ N₁ N₂ → ∀ a₂,
    a₂ ∈ N₂ᴬ ↔ (∃ a₁ ∈ N₁ᴬ, ψ.exceptions a₁ a₂) ∨ (a₂ ∉ ψ.exceptions.dom ∧ a₂ᴸ = N₂ᴸ)

theorem card_litter_dom_compl {ξ : BaseAction} : #((ξᴸ.dom ∪ ξᴸ.codom)ᶜ : Set Litter) = #μ := by
  sorry

theorem litter_dom_compl_infinite {ξ : BaseAction} : (ξᴸ.dom ∪ ξᴸ.codom)ᶜ.Infinite := by
  sorry

def littersExtension' (ξ : BaseAction) : Rel Litter Litter :=
  ξᴸ.permutativeExtension' ξ.litters_oneOne (ξᴸ.dom ∪ ξᴸ.codom)ᶜ litter_dom_compl_infinite
    (ξ.litters_dom_small.le.trans (κ_le_μ.trans card_litter_dom_compl.symm.le))
    disjoint_compl_right

theorem littersExtension'_permutative (ξ : BaseAction) :
    ξ.littersExtension'.Permutative := by
  sorry

def littersExtension (ξ : BaseAction) : Rel Litter Litter :=
  ξ.littersExtension' ⊔ (λ L₁ L₂ ↦ L₁ = L₂ ∧ L₁ ∉ ξ.littersExtension'.dom)

theorem littersExtension_bijective (ξ : BaseAction) :
    ξ.littersExtension.Bijective := by
  sorry

/-- TODO: Move this to `PermutativeExtension` and do it abstractly. -/
def litterPerm (ξ : BaseAction) : Equiv.Perm Litter :=
  ξ.littersExtension.toEquiv ξ.littersExtension_bijective

theorem litterPerm_eq {ξ : BaseAction} {L₁ L₂ : Litter} (h : ξᴸ L₁ L₂) :
    ξ.litterPerm L₁ = L₂ := by
  sorry

def insideAll (ξ : BaseAction) : Set Atom :=
  {a | ∀ N, (N ∈ ξᴺ.dom ∨ N ∈ ξᴺ.codom) → Nᴸ = aᴸ → a ∈ Nᴬ}

theorem card_insideAll_inter (ξ : BaseAction) (L : Litter) :
    #(ξ.insideAll \ (ξᴬ.dom ∪ ξᴬ.codom) ∩ Lᴬ : Set Atom) = #κ := by
  sorry

def orbitRestriction (ξ : BaseAction) : Rel.OrbitRestriction (ξᴬ.dom ∪ ξᴬ.codom) Litter where
  sandbox := ξ.insideAll \ (ξᴬ.dom ∪ ξᴬ.codom)
  sandbox_disjoint := Set.disjoint_sdiff_left.symm
  categorise a := aᴸ
  catPerm := ξ.litterPerm
  le_card_categorise L := by
    change _ ≤ #(ξ.insideAll \ (ξᴬ.dom ∪ ξᴬ.codom) ∩ Lᴬ : Set Atom)
    rw [card_insideAll_inter, max_le_iff]
    constructor
    · exact κ_isRegular.aleph0_le
    · apply (mk_union_le _ _).trans
      apply add_le_of_le κ_isRegular.aleph0_le
      · exact ξ.atoms_dom_small.le
      · exact ξ.atoms_codom_small.le

def atomPerm (ξ : BaseAction) : Rel Atom Atom :=
  ξᴬ.permutativeExtension ξ.orbitRestriction

theorem le_atomPerm (ξ : BaseAction) :
    ξᴬ ≤ ξ.atomPerm := by
  sorry

theorem dom_subset_dom_atomPerm (ξ : BaseAction) :
    ξᴬ.dom ⊆ ξ.atomPerm.dom := by
  sorry

theorem codom_subset_codom_atomPerm (ξ : BaseAction) :
    ξᴬ.codom ⊆ ξ.atomPerm.codom := by
  sorry

theorem atomPerm_permutative (ξ : BaseAction) :
    ξ.atomPerm.Permutative := by
  sorry

theorem litter_of_atomPerm {ξ : BaseAction} {a₁ a₂ : Atom} :
    ξ.atomPerm a₁ a₂ → ξᴬ a₁ a₂ ∨ (a₁ ∉ ξᴬ.dom ∧ a₂ ∉ ξᴬ.codom ∧ a₂ᴸ = ξ.litterPerm a₁ᴸ) := by
  sorry

theorem atomPerm_dom_subset (ξ : BaseAction) :
    ξ.atomPerm.dom ⊆ ξᴬ.dom ∪ ξᴬ.codom ∪ ξ.insideAll := by
  sorry

theorem atomPerm_small (ξ : BaseAction) :
    Small ξ.atomPerm.dom := by
  sorry

theorem atomPerm_mem_iff_mem {ξ : BaseAction} (hξ : ξ.Nice) {a₁ a₂ : Atom} {N₁ N₂ : NearLitter}
    (ha : ξ.atomPerm a₁ a₂) (hN : ξᴺ N₁ N₂) :
    a₁ ∈ N₁ᴬ ↔ a₂ ∈ N₂ᴬ := by
  sorry

theorem atomPerm_mem_iff {ξ : BaseAction} (hξ : ξ.Nice)
    {N₁ N₂ : NearLitter} (hN : ξᴺ N₁ N₂) (a₂ : Atom) :
    a₂ ∈ N₂ᴬ ↔ (∃ a₁ ∈ N₁ᴬ, ξ.atomPerm a₁ a₂) ∨ a₂ ∉ ξ.atomPerm.dom ∧ a₂ᴸ = N₂ᴸ := by
  sorry

variable [Level] [CoherentData] {β : TypeIndex} [LeLevel β] {A : β ↝ ⊥} {ξ : BaseAction}

def flexLitterRel (ξ : BaseAction) (A : β ↝ ⊥) : Rel Litter Litter :=
  ξᴸ ⊓ (λ L₁ L₂ ↦ ¬Inflexible A L₁ ∧ ¬Inflexible A L₂)

theorem flexLitterRel_dom_small (ξ : BaseAction) (A : β ↝ ⊥) :
    Small (ξ.flexLitterRel A).dom := by
  sorry

theorem card_inflexible_diff_dom (ξ : BaseAction) (A : β ↝ ⊥) :
    #({L | ¬Inflexible A L} \ (ξᴸ.dom ∪ ξᴸ.codom) : Set Litter) = #μ := by
  sorry

def flexLitterPerm (ξ : BaseAction) (A : β ↝ ⊥) : Rel Litter Litter :=
  (ξ.flexLitterRel A).permutativeExtension' (ξ.litters_oneOne.mono inf_le_left)
    ({L | ¬Inflexible A L} \ (ξᴸ.dom ∪ ξᴸ.codom))
    (by
      rw [← Set.infinite_coe_iff, infinite_iff, card_inflexible_diff_dom]
      exact aleph0_lt_κ.le.trans κ_le_μ)
    ((ξ.flexLitterRel_dom_small A).le.trans (κ_le_μ.trans_eq (ξ.card_inflexible_diff_dom A).symm))
    (by
      rw [Set.disjoint_iff_inter_eq_empty, Set.eq_empty_iff_forall_notMem]
      rintro L₁ ⟨⟨L₂, h₁⟩ | ⟨L₂, h₁⟩, h₂⟩
      · exact h₂.2 (Or.inl ⟨L₂, h₁.1⟩)
      · exact h₂.2 (Or.inr ⟨L₂, h₁.1⟩))

theorem le_flexLitterPerm (ξ : BaseAction) (A : β ↝ ⊥) :
    ξ.flexLitterRel A ≤ ξ.flexLitterPerm A := by
  sorry

theorem flexLitterPerm_permutative (ξ : BaseAction) (A : β ↝ ⊥) :
    (ξ.flexLitterPerm A).Permutative := by
  sorry

theorem dom_flexLitterPerm_subset (ξ : BaseAction) (A : β ↝ ⊥) :
    (ξ.flexLitterPerm A).dom ⊆ {L | ¬Inflexible A L} := by
  sorry

def flexApprox' (ξ : BaseAction) (A : β ↝ ⊥) : BaseApprox where
  exceptions := ξ.atomPerm
  litters := ξ.flexLitterPerm A
  exceptions_permutative := ξ.atomPerm_permutative
  litters_permutative' := ξ.flexLitterPerm_permutative A
  exceptions_small := λ _ ↦ ξ.atomPerm_small.mono Set.inter_subset_right

def MapFlexible (ξ : BaseAction) (A : β ↝ ⊥) : Prop :=
  ∀ {L₁ L₂}, ξᴸ L₁ L₂ → (Inflexible A L₁ ↔ Inflexible A L₂)

theorem flexApprox_flexApprox' {ξ : BaseAction} {A : β ↝ ⊥} (hξ₁ : ξ.MapFlexible A) (hξ₂ : ξ.Nice) :
    ξ.FlexApprox A (ξ.flexApprox' A) := by
  sorry

/-- A flexible approximation for `ξ` along `A`. -/
def flexApprox (ξ : BaseAction) (A : β ↝ ⊥) : BaseApprox :=
  ξ.niceExtension.flexApprox' A

theorem niceExtension_mapFlexible {ξ : BaseAction} {A : β ↝ ⊥} (hξ : ξ.MapFlexible A) :
    ξ.niceExtension.MapFlexible A := by
  sorry

theorem flexApprox_flexApprox {ξ : BaseAction} {A : β ↝ ⊥} (hξ : ξ.MapFlexible A) :
    ξ.FlexApprox A (ξ.flexApprox A) := by
  sorry

end BaseAction
end ConNF
