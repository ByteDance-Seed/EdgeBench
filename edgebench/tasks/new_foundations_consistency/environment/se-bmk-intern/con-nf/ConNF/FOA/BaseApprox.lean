import ConNF.ModelData.Support
import ConNF.FOA.Coherent

/-!
# Base approximations

In this file, we define base approximations.

## Main declarations

* `ConNF.BaseApprox`: A base approximation consists of a partial permutation of atoms and a partial
  permutation of near-litters.
-/

noncomputable section
universe u

open Cardinal Ordinal Rel Set
open scoped symmDiff

namespace ConNF

variable [Params.{u}]

structure BaseApprox where
  exceptions : Rel Atom Atom
  litters : Rel Litter Litter
  exceptions_permutative : exceptions.Permutative
  litters_permutative' : litters.Permutative
  exceptions_small (L : Litter) : Small (Lᴬ ∩ exceptions.dom)

namespace BaseApprox

instance : SuperL BaseApprox (Rel Litter Litter) where
  superL := litters

@[simp]
theorem mk_litters (exceptions : Rel Atom Atom) (litters : Rel Litter Litter)
    (exceptions_permutative : exceptions.Permutative)
    (litters_permutative' : litters.Permutative)
    (exceptions_small : ∀ L, Small (Lᴬ ∩ exceptions.dom)) :
    (BaseApprox.mk exceptions litters exceptions_permutative
      litters_permutative' exceptions_small)ᴸ = litters := by
  sorry

@[ext]
theorem ext {ψ χ : BaseApprox} (h₁ : ψ.exceptions = χ.exceptions) (h₂ : ψᴸ = χᴸ) :
    ψ = χ := by
  sorry

theorem litters_permutative (ψ : BaseApprox) :
    ψᴸ.Permutative := by
  sorry

instance : Inv BaseApprox where
  inv ψ := {
    exceptions := ψ.exceptions.inv
    litters := ψᴸ.inv
    exceptions_permutative := ψ.exceptions_permutative.inv
    litters_permutative' := ψ.litters_permutative.inv
    exceptions_small := λ L ↦ ψ.exceptions_permutative.inv_dom ▸ ψ.exceptions_small L
  }

@[simp]
theorem inv_inv (ψ : BaseApprox) :
    ψ⁻¹⁻¹ = ψ := by
  sorry

def sublitterAtoms (ψ : BaseApprox) (L : Litter) : Set Atom :=
  Lᴬ \ ψ.exceptions.dom

theorem sublitterAtoms_near (ψ : BaseApprox) (L : Litter) : ψ.sublitterAtoms L ~ Lᴬ := by
  sorry

def sublitter (ψ : BaseApprox) (L : Litter) : NearLitter where
  litter := L
  atoms := ψ.sublitterAtoms L
  atoms_near_litter' := ψ.sublitterAtoms_near L

def nearLitterEquiv (N : NearLitter) : κ ≃ Nᴬ :=
  Nonempty.some (Cardinal.eq.mp N.card_atoms.symm)

inductive typical (ψ : BaseApprox) : Rel Atom Atom where
  | mk (L₁ L₂ : Litter) (h : ψᴸ L₁ L₂) (i : κ) :
      ψ.typical (nearLitterEquiv (ψ.sublitter L₁) i) (nearLitterEquiv (ψ.sublitter L₂) i)

theorem typical_iff {ψ : BaseApprox} {a₁ a₂ : Atom} :
    ψ.typical a₁ a₂ ↔ ψᴸ a₁ᴸ a₂ᴸ ∧ ∃ i,
      a₁ = nearLitterEquiv (ψ.sublitter a₁ᴸ) i ∧ a₂ = nearLitterEquiv (ψ.sublitter a₂ᴸ) i := by
  sorry

def atoms (ψ : BaseApprox) : Rel Atom Atom :=
  ψ.exceptions ⊔ ψ.typical

instance : SuperA BaseApprox (Rel Atom Atom) where
  superA := atoms

theorem exceptions_dom_subset_atoms_dom (ψ : BaseApprox) :
    ψ.exceptions.dom ⊆ ψᴬ.dom := by
  sorry

theorem atoms_permutative (ψ : BaseApprox) :
    ψᴬ.Permutative := by
  sorry

def nearLitters (ψ : BaseApprox) : Rel NearLitter NearLitter :=
  λ N₁ N₂ ↦ ψᴸ N₁ᴸ N₂ᴸ ∧ N₁ᴬ ⊆ ψᴬ.dom ∧ ψᴬ.image N₁ᴬ = N₂ᴬ

instance : SuperN BaseApprox (Rel NearLitter NearLitter) where
  superN := nearLitters

theorem nearLitters_codom_subset_dom (ψ : BaseApprox) : ψᴺ.codom ⊆ ψᴺ.dom := by
  sorry

theorem nearLitters_permutative (ψ : BaseApprox) : ψᴺ.Permutative := by
  sorry

instance : LE BaseApprox where
  le ψ χ := ψ.exceptions = χ.exceptions ∧ ψᴸ ≤ χᴸ

instance : PartialOrder BaseApprox where
  le_refl ψ := ⟨rfl, le_rfl⟩
  le_trans ψ₁ ψ₂ ψ₃ h₁ h₂ := ⟨h₁.1.trans h₂.1, h₁.2.trans h₂.2⟩
  le_antisymm ψ₁ ψ₂ h₁ h₂ := BaseApprox.ext h₁.1 (le_antisymm h₁.2 h₂.2)

/-- This creates new definitions of `·ᴬ` and `·ᴺ`, but the instances are definitionally equal
so no triangles are formed. -/
instance : BaseActionClass BaseApprox where
  atoms ψ := ψᴬ
  atoms_oneOne ψ := ψ.atoms_permutative.toOneOne
  nearLitters ψ := ψᴺ
  nearLitters_oneOne ψ := ψ.nearLitters_permutative.toOneOne

section addOrbit

def addOrbitLitters (f : ℤ → Litter) :
    Rel Litter Litter :=
  λ L₁ L₂ ↦ ∃ n : ℤ, L₁ = f n ∧ L₂ = f (n + 1)

theorem addOrbitLitters_permutative (f : ℤ → Litter)
    (hf : ∀ m n k, f m = f n → f (m + k) = f (n + k)) :
    (addOrbitLitters f).Permutative := by
  sorry

theorem disjoint_litters_dom_addOrbitLitters_dom
    (ψ : BaseApprox) (f : ℤ → Litter) (hfψ : ∀ n, f n ∉ ψᴸ.dom) :
    Disjoint ψᴸ.dom (addOrbitLitters f).dom := by
  sorry

def addOrbit (ψ : BaseApprox) (f : ℤ → Litter)
    (hf : ∀ m n k, f m = f n → f (m + k) = f (n + k)) (hfψ : ∀ n, f n ∉ ψᴸ.dom) : BaseApprox where
  exceptions := ψ.exceptions
  litters := ψ.litters ⊔ addOrbitLitters f
  exceptions_permutative := ψ.exceptions_permutative
  litters_permutative' :=
    sup_permutative ψ.litters_permutative (addOrbitLitters_permutative f hf)
      (disjoint_litters_dom_addOrbitLitters_dom ψ f hfψ)
  exceptions_small := ψ.exceptions_small

variable {ψ : BaseApprox} {f : ℤ → Litter} {hf : ∀ m n k, f m = f n → f (m + k) = f (n + k)}
  {hfψ : ∀ n, f n ∉ ψᴸ.dom}

end addOrbit

theorem upperBound_exceptions_small (c : Set BaseApprox) (hc : IsChain (· ≤ ·) c) (L : Litter) :
    Small (Lᴬ ∩ (⨆ ψ ∈ c, ψ.exceptions).dom) := by
  sorry

/-- An upper bound for a chain of base approximations. -/
def upperBound (c : Set BaseApprox) (hc : IsChain (· ≤ ·) c) : BaseApprox where
  exceptions := ⨆ ψ ∈ c, ψ.exceptions
  litters := ⨆ ψ ∈ c, ψᴸ
  exceptions_permutative := biSup_permutative_of_isChain
    (λ ψ _ ↦ ψ.exceptions_permutative) (hc.image _ _ _ (λ _ _ h ↦ h.1.le))
  litters_permutative' := biSup_permutative_of_isChain
    (λ ψ _ ↦ ψ.litters_permutative) (hc.image _ _ _ (λ _ _ h ↦ h.2))
  exceptions_small := upperBound_exceptions_small c hc

def Total (ψ : BaseApprox) : Prop :=
  ∀ L, L ∈ ψᴸ.dom

theorem Total.atoms_bijective {ψ : BaseApprox} (h : ψ.Total) :
    ψᴬ.Bijective := by
  sorry

theorem Total.litters_bijective {ψ : BaseApprox} (h : ψ.Total) :
    ψᴸ.Bijective := by
  sorry

theorem basePerm_apply_near_apply (ψ : BaseApprox) (h : ψ.Total) (s : Set Atom) (L : Litter) :
    s ~ Lᴬ → ψᴬ.toEquiv h.atoms_bijective '' s ~ (ψᴸ.toEquiv h.litters_bijective L)ᴬ := by
  sorry

def basePerm (ψ : BaseApprox) (h : ψ.Total) : BasePerm where
  atoms := ψᴬ.toEquiv h.atoms_bijective
  litters := ψᴸ.toEquiv h.litters_bijective
  apply_near_apply := basePerm_apply_near_apply ψ h

theorem basePerm_smul_atom_def {ψ : BaseApprox} {h : ψ.Total} {a : Atom} :
    ψ.basePerm h • a = ψᴬ.toFunction h.atoms_bijective.toFunctional a := by
  sorry

theorem basePerm_smul_litter_def {ψ : BaseApprox} {h : ψ.Total} {L : Litter} :
    ψ.basePerm h • L = ψᴸ.toFunction h.litters_bijective.toFunctional L := by
  sorry

@[simp]
theorem basePerm_smul_atom_eq_iff {ψ : BaseApprox} {h : ψ.Total} {a₁ a₂ : Atom} :
    ψ.basePerm h • a₁ = a₂ ↔ ψᴬ a₁ a₂ := by
  sorry

@[simp]
theorem basePerm_inv_smul_atom_eq_iff {ψ : BaseApprox} {h : ψ.Total} {a₁ a₂ : Atom} :
    (ψ.basePerm h)⁻¹ • a₁ = a₂ ↔ ψᴬ a₂ a₁ := by
  sorry

@[simp]
theorem basePerm_smul_litter_eq_iff {ψ : BaseApprox} {h : ψ.Total} {L₁ L₂ : Litter} :
    ψ.basePerm h • L₁ = L₂ ↔ ψᴸ L₁ L₂ := by
  sorry

@[simp]
theorem basePerm_inv_smul_litter_eq_iff {ψ : BaseApprox} {h : ψ.Total} {L₁ L₂ : Litter} :
    (ψ.basePerm h)⁻¹ • L₁ = L₂ ↔ ψᴸ L₂ L₁ := by
  sorry

@[simp]
theorem basePerm_smul_nearLitter_eq_iff {ψ : BaseApprox} {h : ψ.Total} {N₁ N₂ : NearLitter} :
    ψ.basePerm h • N₁ = N₂ ↔ ψᴺ N₁ N₂ := by
  sorry

structure Approximates (ψ : BaseApprox) (π : BasePerm) : Prop where
  atoms : ∀ a₁ a₂, ψᴬ a₁ a₂ → a₂ = π • a₁
  nearLitters : ∀ N₁ N₂, ψᴺ N₁ N₂ → N₂ = π • N₁

structure ExactlyApproximates (ψ : BaseApprox) (π : BasePerm) : Prop
    extends ψ.Approximates π where
  smul_litter : ∀ a, a ∉ ψ.exceptions.dom → (π • a)ᴸ = π • aᴸ
  inv_smul_litter : ∀ a, a ∉ ψ.exceptions.dom → (π⁻¹ • a)ᴸ = π⁻¹ • aᴸ

open scoped Pointwise in

open scoped Pointwise in

theorem approximates_basePerm {ψ : BaseApprox} (h : ψ.Total) :
    ψ.Approximates (ψ.basePerm h) := by
  sorry

theorem exactlyApproximates_basePerm {ψ : BaseApprox} (h : ψ.Total) :
    ψ.ExactlyApproximates (ψ.basePerm h) := by
  sorry

end BaseApprox

end ConNF
