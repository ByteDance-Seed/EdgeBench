import ConNF.External.Basic

/-!
# New file

In this file...

We are roughly following Scott Fenton's development of NF:
<https://us.metamath.org/nfeuni/mmnf.html>.

## Main declarations

* `ConNF.foo`: Something new.
-/

noncomputable section
universe u

open Cardinal Ordinal ConNF.TSet

namespace ConNF

variable [Params.{u}] {α β γ δ ε ζ η : Λ} (hβ : (β : TypeIndex) < α) (hγ : (γ : TypeIndex) < β)
  (hδ : (δ : TypeIndex) < γ) (hε : (ε : TypeIndex) < δ) (hζ : (ζ : TypeIndex) < ε)
  (hη : (η : TypeIndex) < ζ)

/-- The set `{⟨x, y⟩ | x ∩ y = ∅}` (or rather, a set that contains only these Kuratowski pairs). -/
def disjoint : TSet α :=
  (image high high hβ
    (insertion3 high high hβ hγ hδ (subset hβ hγ hδ hε) ⊓[high]
      insertion2 high high hβ hγ hδ (subset hβ hγ hδ hε))
    (singletons hβ hγ (singletons hγ hδ (cardinalOne hδ hε))))ᶜ'

theorem mem_disjoint_iff' (x y : TSet δ) :
    ⟨x, y⟩' ∈' disjoint hβ hγ hδ hε ↔ ∀ z : TSet ε, ¬z ∈' x ⊓' y := by
  sorry

@[simp]
theorem mem_disjoint_iff (x y : TSet δ) :
    ⟨x, y⟩' ∈' disjoint hβ hγ hδ hε ↔ x ⊓' y = empty hε := by
  sorry

/-- The set `{⟨{{z}}, ⟨y, x⟩ | y ∪ z = x}` (or rather, again,
a set that contains only these pairs). -/
def unionEq : TSet α :=
  (image high high hβ
    (insertion2 high high hβ hγ hδ (insertion2 hβ hγ hδ hε hζ (subset hδ hε hζ hη)) ∆[high]
      (insertion2 high high hβ hγ hδ (insertion3 hβ hγ hδ hε hζ (subset hδ hε hζ hη)) ⊔[high]
      insertion3 high high hβ hγ hδ (singletonImage hβ hγ hδ hε
        (singletonImage hγ hδ hε hζ (subset hδ hε hζ hη)))))
    (singletons hβ hγ (singletons hγ hδ (singletons hδ hε
      (singletons hε hζ (cardinalOne hζ hη))))))ᶜ'

theorem mem_unionEq_iff' (x y z : TSet ζ) :
    ⟨ { {z}' }', ⟨y, x⟩' ⟩[hγ, hδ] ∈' unionEq hβ hγ hδ hε hζ hη ↔
      ∀ a : TSet η, ¬(a ∈' x ↔ ¬a ∈' y ∧ ¬a ∈' z) := by
  sorry

@[simp]
theorem mem_unionEq_iff (x y z : TSet ζ) :
    ⟨ { {z}' }', ⟨y, x⟩' ⟩[hγ, hδ] ∈' unionEq hβ hγ hδ hε hζ hη ↔ y ⊔' z = x := by
  sorry

/-- The binary partition relation: `{⟨x, y, z⟩ | x ∩ y = ∅ ∧ x ∪ y = z}`. -/
def binPartRel : TSet α :=
  insertion3 hβ hγ hδ hε hζ (disjoint hδ hε hζ hη) ⊓' unionEq hβ hγ hδ hε hζ hη

@[simp]
theorem mem_binPartRel_iff (x y z : TSet ζ) :
    ⟨ { {x}' }', ⟨y, z⟩' ⟩[hγ, hδ] ∈' binPartRel hβ hγ hδ hε hζ hη ↔
    x ⊓' y = empty hη ∧ x ⊔' y = z := by
  sorry

/-- The sum of two cardinals: `x + y = {a ∪ b | a ∈ x ∧ b ∈ y ∧ a ∩ b = ∅}`. -/
def cardAdd (x y : TSet α) : TSet α :=
  image high high hβ
    (image high high high
      (binPartRel high high high high hβ hγ)
      (singletons high high (singletons high hβ y))) x

@[simp]
theorem mem_cardAdd_iff (x y : TSet α) (z : TSet β) :
    z ∈' cardAdd hβ hγ x y ↔
    ∃ a b : TSet β, a ∈' x ∧ b ∈' y ∧ a ⊓' b = empty hγ ∧ a ⊔' b = z := by
  sorry

/-- The successor of a cardinal: `x + 1 = {a ∪ {b} | a ∈ x, b ∉ a}`. -/
def succ (x : TSet α) : TSet α :=
  cardAdd hβ hγ x (cardinalOne hβ hγ)

@[simp]
theorem mem_succ_iff (x : TSet α) (y : TSet β) :
    y ∈' succ hβ hγ x ↔
    ∃ a : TSet β, a ∈' x ∧ ∃ b : TSet γ, ¬b ∈' a ∧ y = a ⊔' {b}' := by
  sorry

def cardinalNat : ℕ → TSet α
  | 0 => { empty hγ }'
  | n + 1 => succ hβ hγ (cardinalNat n)

@[simp]
theorem mem_cardinalNat_iff (n : ℕ) :
    ∀ a : TSet β, a ∈' cardinalNat hβ hγ n ↔
    ∃ s : Finset (TSet γ), s.card = n ∧ ∀ b : TSet γ, b ∈' a ↔ b ∈ s := by
  sorry

end ConNF
