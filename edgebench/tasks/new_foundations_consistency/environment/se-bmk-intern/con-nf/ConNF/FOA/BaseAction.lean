import ConNF.FOA.Coherent

/-!
# Base actions

In this file, we define base actions.

## Main declarations

* `ConNF.BaseAction`: The type of base actions.
-/

noncomputable section
universe u

open Cardinal Ordinal
open scoped symmDiff

namespace ConNF

variable [Params.{u}]

structure BaseAction where
  atoms : Rel Atom Atom
  nearLitters : Rel NearLitter NearLitter
  atoms_dom_small' : Small atoms.dom
  nearLitters_dom_small' : Small nearLitters.dom
  atoms_oneOne' : atoms.OneOne
  mem_iff_mem' {a₁ a₂ : Atom} {N₁ N₂ : NearLitter} :
    atoms a₁ a₂ → nearLitters N₁ N₂ → (a₁ ∈ N₁ᴬ ↔ a₂ ∈ N₂ᴬ)
  litter_eq_litter_iff' {N₁ N₂ N₃ N₄ : NearLitter} :
    nearLitters N₁ N₃ → nearLitters N₂ N₄ → (N₁ᴸ = N₂ᴸ ↔ N₃ᴸ = N₄ᴸ)
  interference_subset_dom' {N₁ N₂ : NearLitter} :
    N₁ ∈ nearLitters.dom → N₂ ∈ nearLitters.dom → interference N₁ N₂ ⊆ atoms.dom
  interference_subset_codom' {N₁ N₂ : NearLitter} :
    N₁ ∈ nearLitters.codom → N₂ ∈ nearLitters.codom → interference N₁ N₂ ⊆ atoms.codom

namespace BaseAction

theorem nearLitters_coinjective (ξ : BaseAction) : ξ.nearLitters.Coinjective := by
  sorry

theorem nearLitters_injective (ξ : BaseAction) : ξ.nearLitters.Injective := by
  sorry

instance : BaseActionClass BaseAction where
  atoms := atoms
  atoms_oneOne := atoms_oneOne'
  nearLitters := nearLitters
  nearLitters_oneOne ξ := ⟨ξ.nearLitters_injective, ξ.nearLitters_coinjective⟩

@[ext]
theorem ext {ξ ζ : BaseAction} (atoms : ξᴬ = ζᴬ) (nearLitters : ξᴺ = ζᴺ) : ξ = ζ := by
  sorry

theorem atoms_dom_small (ξ : BaseAction) : Small ξᴬ.dom := by
  sorry

theorem nearLitters_dom_small (ξ : BaseAction) : Small ξᴺ.dom := by
  sorry

theorem atoms_oneOne (ξ : BaseAction) : ξᴬ.OneOne := by
  sorry

theorem mem_iff_mem {ξ : BaseAction} {a₁ a₂ : Atom} {N₁ N₂ : NearLitter} :
    ξᴬ a₁ a₂ → ξᴺ N₁ N₂ → (a₁ ∈ N₁ᴬ ↔ a₂ ∈ N₂ᴬ) := by
  sorry

theorem litter_eq_litter_iff {ξ : BaseAction} {N₁ N₂ N₃ N₄ : NearLitter} :
    ξᴺ N₁ N₃ → ξᴺ N₂ N₄ → (N₁ᴸ = N₂ᴸ ↔ N₃ᴸ = N₄ᴸ) := by
  sorry

theorem interference_subset_dom {ξ : BaseAction} {N₁ N₂ : NearLitter} :
    N₁ ∈ ξᴺ.dom → N₂ ∈ ξᴺ.dom → interference N₁ N₂ ⊆ ξᴬ.dom := by
  sorry

theorem interference_subset_codom {ξ : BaseAction} {N₁ N₂ : NearLitter} :
    N₁ ∈ ξᴺ.codom → N₂ ∈ ξᴺ.codom → interference N₁ N₂ ⊆ ξᴬ.codom := by
  sorry

theorem atoms_codom_small (ξ : BaseAction) : Small ξᴬ.codom := by
  sorry

theorem nearLitters_codom_small (ξ : BaseAction) : Small ξᴺ.codom := by
  sorry

def inv (ξ : BaseAction) : BaseAction where
  atoms := ξᴬ.inv
  nearLitters := ξᴺ.inv
  atoms_dom_small' := ξ.atoms_codom_small
  nearLitters_dom_small' := ξ.nearLitters_codom_small
  atoms_oneOne' := ξ.atoms_oneOne.inv
  mem_iff_mem' h₁ h₂ := (ξ.mem_iff_mem h₁ h₂).symm
  litter_eq_litter_iff' h₁ h₂ := (ξ.litter_eq_litter_iff h₁ h₂).symm
  interference_subset_dom' := ξ.interference_subset_codom
  interference_subset_codom' := ξ.interference_subset_dom

instance : Inv BaseAction where
  inv := inv

@[simp]
theorem inv_inv (ξ : BaseAction) : ξ⁻¹⁻¹ = ξ := by
  sorry

theorem nearLitters_oneOne (ξ : BaseAction) : ξᴺ.OneOne := by
  sorry

inductive litters (ξ : BaseAction) : Rel Litter Litter
  | mk {N₁ N₂ : NearLitter} : ξᴺ N₁ N₂ → ξ.litters N₁ᴸ N₂ᴸ

instance : SuperL BaseAction (Rel Litter Litter) where
  superL := litters

theorem litters_iff {ξ : BaseAction} (L₁ L₂ : Litter) :
    ξᴸ L₁ L₂ ↔ ∃ N₁ N₂, N₁ᴸ = L₁ ∧ N₂ᴸ = L₂ ∧ ξᴺ N₁ N₂ := by
  sorry

theorem litters_dom_small (ξ : BaseAction) : Small ξᴸ.dom := by
  sorry

theorem litters_oneOne (ξ : BaseAction) : ξᴸ.OneOne := by
  sorry

instance : LE BaseAction where
  le ξ ζ := ξᴬ ≤ ζᴬ ∧ ξᴺ = ζᴺ

instance : PartialOrder BaseAction where
  le_refl _ := ⟨le_rfl, rfl⟩
  le_trans _ _ _ h₁ h₂ := ⟨h₁.1.trans h₂.1, h₁.2.trans h₂.2⟩
  le_antisymm _ _ h₁ h₂ := ext (le_antisymm h₁.1 h₂.1) h₁.2

theorem inv_le_inv_iff {ξ ζ : BaseAction} :
    ξ⁻¹ ≤ ζ⁻¹ ↔ ξ ≤ ζ := by
  sorry

/-- A definition that can be used to reduce the proof obligations of extending a base action. -/
def extend (ξ : BaseAction) (r : Rel Atom Atom) (r_dom_small : Small r.dom) (r_oneOne : r.OneOne)
    (r_dom_disjoint : Disjoint ξᴬ.dom r.dom) (r_codom_disjoint : Disjoint ξᴬ.codom r.codom)
    (r_mem_iff_mem : ∀ {a₁ a₂ N₁ N₂}, r a₁ a₂ → ξᴺ N₁ N₂ → (a₁ ∈ N₁ᴬ ↔ a₂ ∈ N₂ᴬ)) :
    BaseAction where
  atoms := ξᴬ ⊔ r
  nearLitters := ξᴺ
  atoms_dom_small' := by
    rw [Rel.sup_dom]
    exact small_union ξ.atoms_dom_small r_dom_small
  nearLitters_dom_small' := ξ.nearLitters_dom_small
  atoms_oneOne' := Rel.sup_oneOne ξ.atoms_oneOne r_oneOne r_dom_disjoint r_codom_disjoint
  mem_iff_mem' ha hN := by
    obtain (ha | ha) := ha
    · exact ξ.mem_iff_mem ha hN
    · exact r_mem_iff_mem ha hN
  litter_eq_litter_iff' := ξ.litter_eq_litter_iff
  interference_subset_dom' h₁ h₂ a ha := by
    rw [Rel.sup_dom]
    exact Or.inl (ξ.interference_subset_dom h₁ h₂ ha)
  interference_subset_codom' h₁ h₂ a ha := by
    rw [Rel.sup_codom]
    exact Or.inl (ξ.interference_subset_codom h₁ h₂ ha)

@[mk_iff]
structure Nice (ξ : BaseAction) : Prop where
  symmDiff_subset_dom : ∀ N ∈ ξᴺ.dom, Nᴬ ∆ Nᴸᴬ ⊆ ξᴬ.dom
  symmDiff_subset_codom : ∀ N ∈ ξᴺ.codom, Nᴬ ∆ Nᴸᴬ ⊆ ξᴬ.codom

/-!
## Extending orbits inside near-litters
-/

/-- The set of atoms contained in near-litters but not the corresponding litters. -/
def inside (ξ : BaseAction) : Set Atom :=
  {a | ∃ N ∈ ξᴺ.dom, a ∈ Nᴬ ∧ aᴸ ≠ Nᴸ}

@[mk_iff]
structure InsideCandidate (ξ : BaseAction) (L : Litter) (a : Atom) : Prop where
  litter_eq : aᴸ = L
  not_mem_codom : a ∉ ξᴬ.codom
  mem_nearLitter {N : NearLitter} : N ∈ ξᴺ.codom → Nᴸ = L → a ∈ Nᴬ

theorem card_inside_lt_card_insideCandidates (ξ : BaseAction) (L : Litter) :
    #ξ.inside < #{a | ξ.InsideCandidate L a} := by
  sorry

def insideMap (ξ : BaseAction) (L : Litter) :
    ξ.inside ↪ {a | ξ.InsideCandidate L a} :=
  Nonempty.some (ξ.card_inside_lt_card_insideCandidates L).le

def insideRel (ξ : BaseAction) : Rel Atom Atom :=
    λ a₁ a₂ ↦ ∃ N₁ N₂ h, ξᴺ N₁ N₂ ∧ a₁ ∉ ξᴬ.dom ∧ a₂ = ξ.insideMap N₂ᴸ ⟨a₁, N₁, h⟩

theorem insideRel_dom_small (ξ : BaseAction) : Small ξ.insideRel.dom := by
  sorry

theorem insideRel_oneOne (ξ : BaseAction) : ξ.insideRel.OneOne := by
  sorry

theorem insideRel_dom (ξ : BaseAction) : Disjoint ξᴬ.dom ξ.insideRel.dom := by
  sorry

theorem insideRel_codom (ξ : BaseAction) : Disjoint ξᴬ.codom ξ.insideRel.codom := by
  sorry

theorem insideRel_mem_iff_mem {ξ : BaseAction} {a₁ a₂ : Atom} {N₁ N₂ : NearLitter}
    (ha : ξ.insideRel a₁ a₂) (hN : ξᴺ N₁ N₂) :
    a₁ ∈ N₁ᴬ ↔ a₂ ∈ N₂ᴬ := by
  sorry

def insideExtension (ξ : BaseAction) : BaseAction :=
  ξ.extend ξ.insideRel ξ.insideRel_dom_small ξ.insideRel_oneOne
    ξ.insideRel_dom ξ.insideRel_codom insideRel_mem_iff_mem

/-!
## Extending orbits outside near-litters
-/

@[mk_iff]
structure Sandbox (ξ : BaseAction) (L : Litter) : Prop where
  atom_not_mem (a : Atom) : a ∈ ξᴬ.codom → aᴸ ≠ L
  nearLitter_not_mem (N : NearLitter) (a : Atom) : aᴸ = L → N ∈ ξᴺ.codom → a ∉ Nᴬ

def not_sandbox_eq (ξ : BaseAction) :
    {L | ¬ξ.Sandbox L} = (⋃ a ∈ ξᴬ.codom, {aᴸ}) ∪ (⋃ N ∈ ξᴺ.codom, ⋃ a ∈ Nᴬ, {aᴸ}) := by
  ext L
  simp only [sandbox_iff, Set.mem_union, Set.mem_iUnion, exists_prop,
    not_and_or, not_forall, not_not]
  constructor
  · rintro (⟨a, ha, rfl⟩ | ⟨N, a, rfl, hN, ha⟩)
    · exact Or.inl ⟨a, ha, rfl⟩
    · exact Or.inr ⟨N, hN, a, ha, rfl⟩
  · rintro (⟨a, ha, rfl⟩ | ⟨N, hN, a, ha, rfl⟩)
    · exact Or.inl ⟨a, ha, rfl⟩
    · exact Or.inr ⟨N, a, rfl, hN, ha⟩

theorem exists_sandbox (ξ : BaseAction) : {L | ξ.Sandbox L}.Nonempty := by
  sorry

def sandbox (ξ : BaseAction) : Litter :=
  ξ.exists_sandbox.some

def outside (ξ : BaseAction) : Set Atom :=
  {a | ∃ N ∈ ξᴺ.dom, a ∉ Nᴬ ∧ aᴸ = Nᴸ}

theorem card_outside_lt_card_sandbox (ξ : BaseAction) :
    #ξ.outside < #ξ.sandboxᴬ := by
  sorry

def outsideMap (ξ : BaseAction) : ξ.outside ↪ ξ.sandboxᴬ :=
  Nonempty.some ξ.card_outside_lt_card_sandbox.le

def outsideRel (ξ : BaseAction) : Rel Atom Atom :=
  λ a₁ a₂ ↦ a₁ ∉ ξᴬ.dom ∧ ∃ h, a₂ = ξ.outsideMap ⟨a₁, h⟩

theorem outsideRel_dom_small (ξ : BaseAction) : Small ξ.outsideRel.dom := by
  sorry

theorem outsideRel_oneOne (ξ : BaseAction) : ξ.outsideRel.OneOne := by
  sorry

theorem outsideRel_dom (ξ : BaseAction) : Disjoint ξᴬ.dom ξ.outsideRel.dom := by
  sorry

theorem outsideRel_codom (ξ : BaseAction) : Disjoint ξᴬ.codom ξ.outsideRel.codom := by
  sorry

theorem outsideRel_mem_iff_mem {ξ : BaseAction} (hξ : ∀ N ∈ ξᴺ.dom, Nᴬ \ Nᴸᴬ ⊆ ξᴬ.dom)
    {a₁ a₂ : Atom} {N₁ N₂ : NearLitter}
    (ha : ξ.outsideRel a₁ a₂) (hN : ξᴺ N₁ N₂) :
    a₁ ∈ N₁ᴬ ↔ a₂ ∈ N₂ᴬ := by
  sorry

def outsideExtension (ξ : BaseAction) (hξ : ∀ N ∈ ξᴺ.dom, Nᴬ \ Nᴸᴬ ⊆ ξᴬ.dom) : BaseAction :=
  ξ.extend ξ.outsideRel ξ.outsideRel_dom_small ξ.outsideRel_oneOne
    ξ.outsideRel_dom ξ.outsideRel_codom (ξ.outsideRel_mem_iff_mem hξ)

/-!
## Nice extensions
-/

def doubleInsideExtension (ξ : BaseAction) : BaseAction :=
  ξ.insideExtension⁻¹.insideExtension⁻¹

theorem doubleInsideExtension_dom {ξ : BaseAction} (N : NearLitter) (hN : N ∈ ξᴺ.dom) :
    Nᴬ \ Nᴸᴬ ⊆ ξ.doubleInsideExtensionᴬ.dom := by
  sorry

theorem niceExtension_aux {ξ : BaseAction} (N : NearLitter) (hN : N ∈ ξᴺ.codom) :
    Nᴬ \ Nᴸᴬ ⊆ (ξ.doubleInsideExtension.outsideExtension ξ.doubleInsideExtension_dom)⁻¹ᴬ.dom := by
  sorry

def niceExtension (ξ : BaseAction) : BaseAction :=
  ((ξ.doubleInsideExtension.outsideExtension ξ.doubleInsideExtension_dom)⁻¹.outsideExtension
    ξ.niceExtension_aux)⁻¹

theorem le_niceExtension (ξ : BaseAction) :
    ξ ≤ ξ.niceExtension := by
  sorry

theorem niceExtension_nice (ξ : BaseAction) : ξ.niceExtension.Nice := by
  sorry

@[simp]
theorem niceExtension_nearLitters (ξ : BaseAction) :
    ξ.niceExtensionᴺ = ξᴺ := by
  sorry

@[simp]
theorem niceExtension_litters (ξ : BaseAction) :
    ξ.niceExtensionᴸ = ξᴸ := by
  sorry

end BaseAction

end ConNF
