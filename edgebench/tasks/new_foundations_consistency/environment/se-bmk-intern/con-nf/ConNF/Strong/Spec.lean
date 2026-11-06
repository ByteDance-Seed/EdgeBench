import ConNF.FOA.Inflexible
import ConNF.Strong.CodingFunction

/-!
# Specifications for supports

In this file, we define the notion of a specification for a support.

## Main declarations

* `ConNF.Spec`: Specifications for supports.
-/

noncomputable section
universe u

open Cardinal Ordinal

namespace ConNF

variable [Params.{u}] [Level] [CoherentData]

structure AtomCond where
  atoms : Set κ
  nearLitters : Set κ

structure FlexCond where
  nearLitters : Set κ

structure InflexCond (δ : TypeIndex) [LeLevel δ] where
  χ : CodingFunction δ
  atoms : Tree (Rel κ κ) δ
  nearLitters : Tree (Rel κ κ) δ

instance (δ : TypeIndex) [LeLevel δ] : SuperA (InflexCond δ) (Tree (Rel κ κ) δ) where
  superA := InflexCond.atoms

instance (δ : TypeIndex) [LeLevel δ] : SuperN (InflexCond δ) (Tree (Rel κ κ) δ) where
  superN := InflexCond.nearLitters

inductive NearLitterCond (β : TypeIndex) [LeLevel β]
  | flex : FlexCond → NearLitterCond β
  | inflex (P : InflexiblePath β) : InflexCond P.δ → NearLitterCond β

structure Spec (β : TypeIndex) [LeLevel β] where
  atoms : Tree (Enumeration AtomCond) β
  nearLitters : Tree (Enumeration (NearLitterCond β)) β

instance (β : TypeIndex) [LeLevel β] :
    SuperA (Spec β) (Tree (Enumeration AtomCond) β) where
  superA := Spec.atoms

instance (β : TypeIndex) [LeLevel β] :
    SuperN (Spec β) (Tree (Enumeration (NearLitterCond β)) β) where
  superN := Spec.nearLitters

variable {β : TypeIndex} [LeLevel β]

@[ext]
theorem Spec.ext {σ τ : Spec β} (h₁ : ∀ A, σᴬ A = τᴬ A) (h₂ : ∀ A, σᴺ A = τᴺ A) : σ = τ := by
  sorry

instance : LE (Spec β) where
  le σ τ := ∀ A,
    (σᴬ A).bound = (τᴬ A).bound ∧ (σᴬ A).rel ≤ (τᴬ A).rel ∧
    (σᴺ A).bound = (τᴺ A).bound ∧ (σᴺ A).rel ≤ (τᴺ A).rel

instance : PartialOrder (Spec β) where
  le_refl σ A := ⟨rfl, le_rfl, rfl, le_rfl⟩
  le_trans σ τ υ h₁ h₂ A := ⟨(h₁ A).1.trans (h₂ A).1, (h₁ A).2.1.trans (h₂ A).2.1,
    (h₁ A).2.2.1.trans (h₂ A).2.2.1, (h₁ A).2.2.2.trans (h₂ A).2.2.2⟩
  le_antisymm σ τ h₁ h₂ := Spec.ext
    (λ A ↦ Enumeration.ext (h₁ A).1 (le_antisymm (h₁ A).2.1 (h₂ A).2.1))
    (λ A ↦ Enumeration.ext (h₁ A).2.2.1 (le_antisymm (h₁ A).2.2.2 (h₂ A).2.2.2))

def nearLitterCondRelFlex (S : Support β) (A : β ↝ ⊥) :
    Rel NearLitter (NearLitterCond β) :=
  λ N c ↦ ¬Inflexible A Nᴸ ∧ c = .flex ⟨{i | ∃ N', (S ⇘. A)ᴺ.rel i N' ∧ Nᴸ = N'ᴸ}⟩

def nearLitterCondRelInflex (S : Support β) (A : β ↝ ⊥) :
    Rel NearLitter (NearLitterCond β) :=
  λ N c ↦ ∃ P : InflexiblePath β, ∃ t : Tangle P.δ, A = P.A ↘ P.hε ↘. ∧ Nᴸ = fuzz P.hδε t ∧
    c = .inflex P ⟨t.code,
      λ B ↦ (S ⇘. (P.A ↘ P.hδ ⇘ B))ᴬ.rel.comp (t.support ⇘. B)ᴬ.rel.inv,
      λ B ↦ (S ⇘. (P.A ↘ P.hδ ⇘ B))ᴺ.rel.comp (t.support ⇘. B)ᴺ.rel.inv⟩

def nearLitterCondRel (S : Support β) (A : β ↝ ⊥) :
    Rel NearLitter (NearLitterCond β) :=
  nearLitterCondRelFlex S A ⊔ nearLitterCondRelInflex S A

theorem nearLitterCondRel_coinjective (S : Support β) (A : β ↝ ⊥) :
    (nearLitterCondRel S A).Coinjective := by
  sorry

def Support.spec (S : Support β) : Spec β where
  atoms A := (S ⇘. A)ᴬ.image
    (λ a ↦ ⟨{i | (S ⇘. A)ᴬ.rel i a}, {i | ∃ N, (S ⇘. A)ᴺ.rel i N ∧ a ∈ Nᴬ}⟩)
  nearLitters A := (S ⇘. A)ᴺ.comp
    (nearLitterCondRel S A) (nearLitterCondRel_coinjective S A)

theorem Support.spec_atoms (S : Support β) (A : β ↝ ⊥) :
    S.specᴬ A = (S ⇘. A)ᴬ.image
      (λ a ↦ ⟨{i | (S ⇘. A)ᴬ.rel i a}, {i | ∃ N, (S ⇘. A)ᴺ.rel i N ∧ a ∈ Nᴬ}⟩) := by
  sorry

theorem Support.spec_nearLitters (S : Support β) (A : β ↝ ⊥) :
    S.specᴺ A = (S ⇘. A)ᴺ.comp
      (nearLitterCondRel S A) (nearLitterCondRel_coinjective S A) := by
  sorry

theorem Support.spec_atoms_dom (S : Support β) (A : β ↝ ⊥) :
    (S.specᴬ A).rel.dom = (S ⇘. A)ᴬ.rel.dom := by
  sorry

theorem Support.spec_nearLitters_dom (S : Support β) (A : β ↝ ⊥) :
    (S.specᴺ A).rel.dom = (S ⇘. A)ᴺ.rel.dom := by
  sorry

def convAtoms (S T : Support β) (A : β ↝ ⊥) : Rel Atom Atom :=
  (S ⇘. A)ᴬ.rel.inv.comp (T ⇘. A)ᴬ.rel

def convNearLitters (S T : Support β) (A : β ↝ ⊥) :
    Rel NearLitter NearLitter :=
  (S ⇘. A)ᴺ.rel.inv.comp (T ⇘. A)ᴺ.rel

omit [Level] [CoherentData] [LeLevel β] in

omit [Level] [CoherentData] [LeLevel β] in

omit [Level] [CoherentData] [LeLevel β] in
theorem convAtoms_dom_subset (S T : Support β) (A : β ↝ ⊥) :
    (convAtoms S T A).dom ⊆ (S ⇘. A)ᴬ := by
  sorry

omit [Level] [CoherentData] [LeLevel β] in
theorem convNearLitters_dom_subset (S T : Support β) (A : β ↝ ⊥) :
    (convNearLitters S T A).dom ⊆ (S ⇘. A)ᴺ := by
  sorry

def atomMemRel (S : Support β) (A : β ↝ ⊥) : Rel κ κ :=
  (S ⇘. A)ᴺ.rel.comp (Rel.comp (λ N a ↦ a ∈ Nᴬ) (S ⇘. A)ᴬ.rel.inv)

structure SameSpec (S T : Support β) : Prop where
(atoms_bound_eq : ∀ A, (S ⇘. A)ᴬ.bound = (T ⇘. A)ᴬ.bound)
(nearLitters_bound_eq : ∀ A, (S ⇘. A)ᴺ.bound = (T ⇘. A)ᴺ.bound)
(atoms_dom_eq : ∀ A, (S ⇘. A)ᴬ.rel.dom = (T ⇘. A)ᴬ.rel.dom)
(nearLitters_dom_eq : ∀ A, (S ⇘. A)ᴺ.rel.dom = (T ⇘. A)ᴺ.rel.dom)
(convAtoms_oneOne : ∀ A, (convAtoms S T A).OneOne)
(atomMemRel_eq : ∀ A, atomMemRel S A = atomMemRel T A)
(inflexible_iff : ∀ {A N₁ N₂}, convNearLitters S T A N₁ N₂ →
  ∀ P : InflexiblePath β, ∀ t : Tangle P.δ, A = P.A ↘ P.hε ↘. →
  ((∃ ρ : AllPerm P.δ, N₁ᴸ = fuzz P.hδε (ρ • t)) ↔
  (∃ ρ : AllPerm P.δ, N₂ᴸ = fuzz P.hδε (ρ • t))))
(litter_eq_iff_of_flexible : ∀ {A N₁ N₂ N₃ N₄},
  convNearLitters S T A N₁ N₂ → convNearLitters S T A N₃ N₄ →
  ¬Inflexible A N₁ᴸ → ¬Inflexible A N₂ᴸ → ¬Inflexible A N₃ᴸ → ¬Inflexible A N₄ᴸ →
  (N₁ᴸ = N₃ᴸ ↔ N₂ᴸ = N₄ᴸ))
(atoms_iff_of_inflexible : ∀ A, ∀ N₁ N₂ : NearLitter,
  ∀ P : InflexiblePath β, ∀ t : Tangle P.δ, ∀ ρ : AllPerm P.δ,
  A = P.A ↘ P.hε ↘. → N₁ᴸ = fuzz P.hδε t → N₂ᴸ = fuzz P.hδε (ρ • t) →
  convNearLitters S T A N₁ N₂ → ∀ B : P.δ ↝ ⊥, ∀ a ∈ (t.support ⇘. B)ᴬ,
  ∀ i, (S ⇘. (P.A ↘ P.hδ ⇘ B))ᴬ.rel i a ↔ (T ⇘. (P.A ↘ P.hδ ⇘ B))ᴬ.rel i (ρᵁ B • a))
(nearLitters_iff_of_inflexible : ∀ A, ∀ N₁ N₂ : NearLitter,
  ∀ P : InflexiblePath β, ∀ t : Tangle P.δ, ∀ ρ : AllPerm P.δ,
  A = P.A ↘ P.hε ↘. → N₁ᴸ = fuzz P.hδε t → N₂ᴸ = fuzz P.hδε (ρ • t) →
  convNearLitters S T A N₁ N₂ → ∀ B : P.δ ↝ ⊥, ∀ N ∈ (t.support ⇘. B)ᴺ,
  ∀ i, (S ⇘. (P.A ↘ P.hδ ⇘ B))ᴺ.rel i N ↔ (T ⇘. (P.A ↘ P.hδ ⇘ B))ᴺ.rel i (ρᵁ B • N))

/-- A variant of `SameSpec` in which most equalities have been turned into one-directional
implications. It can sometimes be easier to prove this in generality than to prove `SameSpec`
directly. -/
structure SameSpecLE (S T : Support β) : Prop where
(atoms_bound_eq : ∀ A, (S ⇘. A)ᴬ.bound = (T ⇘. A)ᴬ.bound)
(nearLitters_bound_eq : ∀ A, (S ⇘. A)ᴺ.bound = (T ⇘. A)ᴺ.bound)
(atoms_dom_subset : ∀ A, (S ⇘. A)ᴬ.rel.dom ⊆ (T ⇘. A)ᴬ.rel.dom)
(nearLitters_dom_subset : ∀ A, (S ⇘. A)ᴺ.rel.dom ⊆ (T ⇘. A)ᴺ.rel.dom)
(convAtoms_injective : ∀ A, (convAtoms S T A).Injective)
(atomMemRel_le : ∀ A, atomMemRel S A ≤ atomMemRel T A)
(inflexible_of_inflexible : ∀ {A N₁ N₂}, convNearLitters S T A N₁ N₂ →
  ∀ P : InflexiblePath β, ∀ t : Tangle P.δ, A = P.A ↘ P.hε ↘. →
  N₁ᴸ = fuzz P.hδε t → ∃ ρ : AllPerm P.δ, N₂ᴸ = fuzz P.hδε (ρ • t))
(litter_eq_of_flexible : ∀ {A N₁ N₂ N₃ N₄},
  convNearLitters S T A N₁ N₂ → convNearLitters S T A N₃ N₄ →
  ¬Inflexible A N₁ᴸ → ¬Inflexible A N₂ᴸ → ¬Inflexible A N₃ᴸ → ¬Inflexible A N₄ᴸ →
  N₁ᴸ = N₃ᴸ → N₂ᴸ = N₄ᴸ)
(atoms_of_inflexible : ∀ A, ∀ N₁ N₂ : NearLitter,
  ∀ P : InflexiblePath β, ∀ t : Tangle P.δ, ∀ ρ : AllPerm P.δ,
  A = P.A ↘ P.hε ↘. → N₁ᴸ = fuzz P.hδε t → N₂ᴸ = fuzz P.hδε (ρ • t) →
  convNearLitters S T A N₁ N₂ → ∀ B : P.δ ↝ ⊥, ∀ a ∈ (t.support ⇘. B)ᴬ,
  ∀ i, (S ⇘. (P.A ↘ P.hδ ⇘ B))ᴬ.rel i a → (T ⇘. (P.A ↘ P.hδ ⇘ B))ᴬ.rel i (ρᵁ B • a))
(nearLitters_of_inflexible : ∀ A, ∀ N₁ N₂ : NearLitter,
  ∀ P : InflexiblePath β, ∀ t : Tangle P.δ, ∀ ρ : AllPerm P.δ,
  A = P.A ↘ P.hε ↘. → N₁ᴸ = fuzz P.hδε t → N₂ᴸ = fuzz P.hδε (ρ • t) →
  convNearLitters S T A N₁ N₂ → ∀ B : P.δ ↝ ⊥, ∀ N ∈ (t.support ⇘. B)ᴺ,
  ∀ i, (S ⇘. (P.A ↘ P.hδ ⇘ B))ᴺ.rel i N → (T ⇘. (P.A ↘ P.hδ ⇘ B))ᴺ.rel i (ρᵁ B • N))

namespace Support

variable {S T : Support β}

theorem atoms_eq_of_spec_eq_spec (h : S.spec = T.spec) (A : β ↝ ⊥) :
    (S ⇘. A)ᴬ.image
      (λ a ↦ (⟨{i | (S ⇘. A)ᴬ.rel i a}, {i | ∃ N, (S ⇘. A)ᴺ.rel i N ∧ a ∈ Nᴬ}⟩ : AtomCond)) =
    (T ⇘. A)ᴬ.image
      (λ a ↦ ⟨{i | (T ⇘. A)ᴬ.rel i a}, {i | ∃ N, (T ⇘. A)ᴺ.rel i N ∧ a ∈ Nᴬ}⟩) := by
  sorry

theorem nearLitters_eq_of_spec_eq_spec (h : S.spec = T.spec) (A : β ↝ ⊥) :
    (S ⇘. A)ᴺ.comp
      (nearLitterCondRel S A) (nearLitterCondRel_coinjective S A) =
    (T ⇘. A)ᴺ.comp
      (nearLitterCondRel T A) (nearLitterCondRel_coinjective T A) := by
  sorry

theorem convAtoms_of_spec_eq_spec (h : S.spec = T.spec) {A : β ↝ ⊥} {a b : Atom} :
    convAtoms S T A a b →
    (∀ i, (S ⇘. A)ᴬ.rel i a ↔ (T ⇘. A)ᴬ.rel i b) ∧
    (∀ i, (∃ N, (S ⇘. A)ᴺ.rel i N ∧ a ∈ Nᴬ) ↔ (∃ N, (T ⇘. A)ᴺ.rel i N ∧ b ∈ Nᴬ)) := by
  sorry

theorem convNearLitters_of_spec_eq_spec (h : S.spec = T.spec) {A : β ↝ ⊥} {N₁ N₂ : NearLitter} :
    convNearLitters S T A N₁ N₂ →
    ∃ c, nearLitterCondRel S A N₁ c ∧ nearLitterCondRel T A N₂ c := by
  sorry

theorem atoms_bound_eq_of_spec_eq_spec (h : S.spec = T.spec) (A : β ↝ ⊥) :
    (S ⇘. A)ᴬ.bound = (T ⇘. A)ᴬ.bound := by
  sorry

theorem nearLitters_bound_eq_of_spec_eq_spec (h : S.spec = T.spec) (A : β ↝ ⊥) :
    (S ⇘. A)ᴺ.bound = (T ⇘. A)ᴺ.bound := by
  sorry

theorem atoms_dom_subset_of_spec_eq_spec (h : S.spec = T.spec) (A : β ↝ ⊥) :
    (S ⇘. A)ᴬ.rel.dom ⊆ (T ⇘. A)ᴬ.rel.dom := by
  sorry

theorem nearLitters_dom_subset_of_spec_eq_spec (h : S.spec = T.spec) (A : β ↝ ⊥) :
    (S ⇘. A)ᴺ.rel.dom ⊆ (T ⇘. A)ᴺ.rel.dom := by
  sorry

theorem convAtoms_injective_of_spec_eq_spec (h : S.spec = T.spec) (A : β ↝ ⊥) :
    (convAtoms S T A).Injective := by
  sorry

theorem atomMemRel_le_of_spec_eq_spec (h : S.spec = T.spec) (A : β ↝ ⊥) :
    atomMemRel S A ≤ atomMemRel T A := by
  sorry

theorem inflexible_of_inflexible_of_spec_eq_spec (h : S.spec = T.spec) {A : β ↝ ⊥}
    {N₁ N₂ : NearLitter} :
    convNearLitters S T A N₁ N₂ → ∀ (P : InflexiblePath β) (t : Tangle P.δ),
      A = P.A ↘ P.hε ↘. → N₁ᴸ = fuzz P.hδε t → ∃ ρ : AllPerm P.δ, N₂ᴸ = fuzz P.hδε (ρ • t) := by
  sorry

theorem litter_eq_of_flexible_of_spec_eq_spec (h : S.spec = T.spec) {A : β ↝ ⊥}
    {N₁ N₂ N₃ N₄ : NearLitter} :
    convNearLitters S T A N₁ N₂ → convNearLitters S T A N₃ N₄ →
    ¬Inflexible A N₁ᴸ → ¬Inflexible A N₂ᴸ → ¬Inflexible A N₃ᴸ → ¬Inflexible A N₄ᴸ →
    N₁ᴸ = N₃ᴸ → N₂ᴸ = N₄ᴸ := by
  sorry

theorem atoms_of_inflexible_of_spec_eq_spec (h : S.spec = T.spec) (A : β ↝ ⊥)
    (N₁ N₂ : NearLitter) (P : InflexiblePath β) (t : Tangle P.δ) (ρ : AllPerm P.δ) :
    A = P.A ↘ P.hε ↘. → N₁ᴸ = fuzz P.hδε t → N₂ᴸ = fuzz P.hδε (ρ • t) →
    convNearLitters S T A N₁ N₂ → ∀ (B : P.δ ↝ ⊥), ∀ a ∈ (t.support ⇘. B)ᴬ,
    ∀ i, (S ⇘. (P.A ↘ P.hδ ⇘ B))ᴬ.rel i a → (T ⇘. (P.A ↘ P.hδ ⇘ B))ᴬ.rel i (ρᵁ B • a) := by
  sorry

theorem nearLitters_of_inflexible_of_spec_eq_spec (h : S.spec = T.spec) (A : β ↝ ⊥)
    (N₁ N₂ : NearLitter) (P : InflexiblePath β) (t : Tangle P.δ) (ρ : AllPerm P.δ) :
    A = P.A ↘ P.hε ↘. → N₁ᴸ = fuzz P.hδε t → N₂ᴸ = fuzz P.hδε (ρ • t) →
    convNearLitters S T A N₁ N₂ → ∀ (B : P.δ ↝ ⊥), ∀ N ∈ (t.support ⇘. B)ᴺ,
    ∀ i, (S ⇘. (P.A ↘ P.hδ ⇘ B))ᴺ.rel i N → (T ⇘. (P.A ↘ P.hδ ⇘ B))ᴺ.rel i (ρᵁ B • N) := by
  sorry

theorem sameSpecLe_of_spec_eq_spec (h : S.spec = T.spec) :
    SameSpecLE S T := by
  sorry

theorem spec_le_spec_of_sameSpec (h : SameSpec S T) :
    S.spec ≤ T.spec := by
  sorry

theorem spec_eq_spec_iff (S T : Support β) :
    S.spec = T.spec ↔ SameSpec S T := by
  sorry

end Support

end ConNF
