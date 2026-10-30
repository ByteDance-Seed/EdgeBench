import ConNF.Strong.SpecSame

/-!
# Coding the base type

In this file, we prove a consequence of freedom of action for `⊥`: a base support can support at
most `2 ^ #κ`-many different sets of atoms under the action of base permutations.

## Main declarations

* `ConNF.foo`: Something new.
-/

noncomputable section
universe u

open Cardinal Ordinal

namespace ConNF

variable [Params.{u}]

def addAtom' (S : BaseSupport) (a : Atom) : BaseSupport where
  atoms := Sᴬ + .singleton a
  nearLitters := Sᴺ

theorem addAtom'_nearLitters (S : BaseSupport) (a : Atom) :
    (addAtom' S a)ᴺ = Sᴺ := by
  sorry

theorem addAtom'_atoms_rel (S : BaseSupport) (a : Atom) (i : κ) (b : Atom) :
    (addAtom' S a)ᴬ.rel i b ↔ Sᴬ.rel i b ∨ (b = a ∧ i = Sᴬ.bound) := by
  sorry

def Support.ofBase (S : BaseSupport) : Support ⊥ where
  atoms :=
    Sᴬ.invImage Prod.snd (λ _ _ ↦ Prod.ext ((Path.eq_nil _).trans (Path.eq_nil _).symm))
  nearLitters :=
    Sᴺ.invImage Prod.snd (λ _ _ ↦ Prod.ext ((Path.eq_nil _).trans (Path.eq_nil _).symm))

@[simp]
theorem Support.ofBase_derivBot (S : BaseSupport) (A : ⊥ ↝ ⊥) :
    Support.ofBase S ⇘. A = S := by
  sorry

variable [Level] [CoherentData]

def addAtom (S : BaseSupport) (a : Atom) : Support ⊥ :=
  .ofBase (addAtom' S a)

theorem addAtom_spec_eq_spec {S : BaseSupport} {a₁ a₂ : Atom}
    (ha₁ : a₁ ∉ Sᴬ) (ha₂ : a₂ ∉ Sᴬ) (ha : ∀ N ∈ Sᴺ, a₁ ∈ Nᴬ ↔ a₂ ∈ Nᴬ) :
    (addAtom S a₁).spec = (addAtom S a₂).spec := by
  sorry

theorem exists_swap {S : BaseSupport} (h : S.Closed) {a₁ a₂ : Atom}
    (ha₁ : a₁ ∉ Sᴬ) (ha₂ : a₂ ∉ Sᴬ) (ha : ∀ N ∈ Sᴺ, a₁ ∈ Nᴬ ↔ a₂ ∈ Nᴬ) :
    ∃ π : BasePerm, π • S = S ∧ π • a₁ = a₂ := by
  sorry

open scoped Pointwise

theorem mem_iff_mem_of_supports {S : BaseSupport} (h : S.Closed) {s : Set Atom}
    (hs : ∀ π : BasePerm, π • S = S → π • s = s)
    {a₁ a₂ : Atom} (h₁ : a₁ ∉ Sᴬ) (h₂ : a₂ ∉ Sᴬ) (ha : ∀ N ∈ Sᴺ, a₁ ∈ Nᴬ ↔ a₂ ∈ Nᴬ) :
    a₁ ∈ s ↔ a₂ ∈ s := by
  sorry

structure Information : Type u where
  atoms : Set κ
  nearLitters : Set κ
  outside : Prop

def information (S : BaseSupport) (s : Set Atom) : Information where
  atoms := {i | ∃ a ∈ s, Sᴬ.rel i a}
  nearLitters := {i | ∃ N : NearLitter, ((Nᴬ ∩ s) \ Sᴬ).Nonempty ∧ Sᴺ.rel i N}
  outside := ∀ a, a ∉ Sᴬ → (∀ N ∈ Sᴺ, a ∉ Nᴬ) → a ∈ s

theorem subset_of_information_eq {S : BaseSupport} (hS : S.Closed) {s t : Set Atom}
    (hs : ∀ π : BasePerm, π • S = S → π • s = s) (ht : ∀ π : BasePerm, π • S = S → π • t = t)
    (h : information S s = information S t) : s ⊆ t := by
  sorry

theorem eq_of_information_eq {S : BaseSupport} (hS : S.Closed) {s t : Set Atom}
    (hs : ∀ π : BasePerm, π • S = S → π • s = s) (ht : ∀ π : BasePerm, π • S = S → π • t = t)
    (h : information S s = information S t) : s = t := by
  sorry

theorem card_supports_le_of_closed' {S : BaseSupport} (hS : S.Closed) :
    #{s : Set Atom // ∀ π : BasePerm, π • S = S → π • s = s} ≤ #Information := by
  sorry

def informationEquiv : Information ≃ Set κ × Set κ × Prop where
  toFun i := ⟨i.atoms, i.nearLitters, i.outside⟩
  invFun i := ⟨i.1, i.2.1, i.2.2⟩
  left_inv _ := rfl
  right_inv _ := rfl

omit [Level] [CoherentData] in

theorem card_supports_le_of_closed {S : BaseSupport} (hS : S.Closed) :
    #{s : Set Atom // ∀ π : BasePerm, π • S = S → π • s = s} ≤ 2 ^ #κ := by
  sorry

omit [Level] [CoherentData] in

theorem card_supports_le (S : BaseSupport) :
    #{s : Set Atom // ∀ π : BasePerm, π • S = S → π • s = s} ≤ 2 ^ #κ := by
  sorry

end ConNF
