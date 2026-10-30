import ConNF.Strong.SMulSpec
import ConNF.Strong.SpecSame

/-!
# Counting support orbits

In this file, we prove an upper bound on the amount of orbits of supports that can exist.

## Main declarations

* `ConNF.card_supportOrbit_lt`: The amount of support orbits is strictly less than `μ`, given
  an inductive hypothesis about the amount of coding functions at lower levels.
-/

noncomputable section
universe u

open Cardinal Ordinal

namespace ConNF

variable [Params.{u}] [Level] [CoherentData] {β : TypeIndex} [LeLevel β]

-- TODO: fix in blueprint
structure WeakSpec (β : TypeIndex) [LeLevel β] where
  atomsBound : Tree κ β
  nearLittersBound : Tree κ β
  atoms : Tree (Set κ) β
  nearLitters : Tree (Set κ) β
  spec : Spec β

instance : SuperA (WeakSpec β) (Tree (Set κ) β) where
  superA := WeakSpec.atoms

instance : SuperN (WeakSpec β) (Tree (Set κ) β) where
  superN := WeakSpec.nearLitters

def WeakSpec.Specifies (σ : WeakSpec β) (S : Support β) : Prop :=
  ∃ T : Support β, T.Strong ∧ S.Subsupport T ∧ σ.spec = T.spec ∧
    (σ.atomsBound = λ A ↦ (S ⇘. A)ᴬ.bound) ∧
    (σ.nearLittersBound = λ A ↦ (S ⇘. A)ᴺ.bound) ∧
    (σᴬ = λ A ↦ (S ⇘. A)ᴬ.rel.dom) ∧
    (σᴺ = λ A ↦ (S ⇘. A)ᴺ.rel.dom)

theorem WeakSpec.exists (S : Support β) : ∃ σ : WeakSpec β, σ.Specifies S := by
  sorry

theorem WeakSpec.exists_conv (σ : WeakSpec β) {S T : Support β}
    (hS : σ.Specifies S) (hT : σ.Specifies T) :
    ∃ ρ : AllPerm β, ρᵁ • S = T := by
  sorry

def weakSpecEquiv :
    WeakSpec β ≃ Tree κ β × Tree κ β × Tree (Set κ) β × Tree (Set κ) β × Spec β where
  toFun σ := ⟨σ.atomsBound, σ.nearLittersBound, σᴬ, σᴺ, σ.spec⟩
  invFun σ := ⟨σ.1, σ.2.1, σ.2.2.1, σ.2.2.2.1, σ.2.2.2.2⟩
  left_inv _ := rfl
  right_inv _ := rfl

def specEquiv :
    Spec β ≃ Tree (Enumeration AtomCond) β × Tree (Enumeration (NearLitterCond β)) β where
  toFun σ := ⟨σᴬ, σᴺ⟩
  invFun σ := ⟨σ.1, σ.2⟩
  left_inv _ := rfl
  right_inv _ := rfl

def atomCondEquiv : AtomCond ≃ Set κ × Set κ where
  toFun x := ⟨x.1, x.2⟩
  invFun x := ⟨x.1, x.2⟩
  left_inv _ := rfl
  right_inv _ := rfl

def nearLitterCondEquiv :
    NearLitterCond β ≃ FlexCond ⊕ (P : InflexiblePath β) × InflexCond P.δ where
  toFun x := match x with
    | .flex y => .inl y
    | .inflex P y => .inr ⟨P, y⟩
  invFun x := x.elim .flex (λ x ↦ .inflex x.1 x.2)
  left_inv x := by cases x <;> rfl
  right_inv x := by cases x <;> rfl

def flexCondEquiv : FlexCond ≃ Set κ where
  toFun x := x.1
  invFun x := ⟨x⟩
  left_inv _ := rfl
  right_inv _ := rfl

def inflexCondEquiv (δ : TypeIndex) [LeLevel δ] :
    InflexCond δ ≃ CodingFunction δ × Tree (Rel κ κ) δ × Tree (Rel κ κ) δ where
  toFun x := (x.χ, x.atoms, x.nearLitters)
  invFun x := ⟨x.1, x.2.1, x.2.2⟩
  left_inv _ := rfl
  right_inv _ := rfl

theorem card_supportOrbit_lt' : #(SupportOrbit β) ≤ #(WeakSpec β) := by
  sorry

theorem card_supportOrbit_lt (h : ∀ δ < β, [LeLevel δ] → #(CodingFunction δ) < #μ) :
    #(SupportOrbit β) < #μ := by
  sorry

end ConNF
