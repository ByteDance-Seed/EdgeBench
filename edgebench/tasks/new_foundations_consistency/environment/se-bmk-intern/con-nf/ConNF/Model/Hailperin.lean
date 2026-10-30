import ConNF.Model.TTT

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

variable [Params.{u}] {α β γ δ ε ζ : Λ} (hβ : (β : TypeIndex) < α) (hγ : (γ : TypeIndex) < β)
  (hδ : (δ : TypeIndex) < γ) (hε : (ε : TypeIndex) < δ) (hζ : (ζ : TypeIndex) < ε)

namespace TSet

theorem exists_inter (x y : TSet α) :
    ∃ w : TSet α, ∀ z : TSet β, z ∈[hβ] w ↔ z ∈[hβ] x ∧ z ∈[hβ] y := by
  sorry

theorem exists_compl (x : TSet α) :
    ∃ y : TSet α, ∀ z : TSet β, z ∈[hβ] y ↔ ¬z ∈[hβ] x := by
  sorry

theorem exists_up (x y : TSet β) :
    ∃ w : TSet α, ∀ z : TSet β, z ∈[hβ] w ↔ z = x ∨ z = y := by
  sorry

/-- The unordered pair. -/
def up (x y : TSet β) : TSet α :=
  (exists_up hβ x y).choose

@[simp]
theorem mem_up_iff (x y z : TSet β) :
    z ∈[hβ] up hβ x y ↔ z = x ∨ z = y := by
  sorry

/-- The Kuratowski ordered pair. -/
def op (x y : TSet γ) : TSet α :=
  up hβ (singleton hγ x) (up hγ x y)

theorem up_injective {x y z w : TSet β} (h : up hβ x y = up hβ z w) :
    (x = z ∧ y = w) ∨ (x = w ∧ y = z) := by
  sorry

@[simp]
theorem up_inj (x y z w : TSet β) :
    up hβ x y = up hβ z w ↔ (x = z ∧ y = w) ∨ (x = w ∧ y = z) := by
  sorry

@[simp]
theorem up_self {x : TSet β} :
    up hβ x x = singleton hβ x := by
  sorry

@[simp]
theorem up_eq_singleton_iff (x y z : TSet β) :
    up hβ x y = singleton hβ z ↔ x = z ∧ y = z := by
  sorry

@[simp]
theorem singleton_eq_up_iff (x y z : TSet β) :
    singleton hβ z = up hβ x y ↔ x = z ∧ y = z := by
  sorry

theorem op_injective {x y z w : TSet γ} (h : op hβ hγ x y = op hβ hγ z w) :
    x = z ∧ y = w := by
  sorry

@[simp]
theorem op_inj (x y z w : TSet γ) :
    op hβ hγ x y = op hβ hγ z w ↔ x = z ∧ y = w := by
  sorry

@[simp]
theorem op_eq_singleton_iff (x y : TSet γ) (z : TSet β) :
    op hβ hγ x y = singleton hβ z ↔ singleton hγ x = z ∧ singleton hγ y = z := by
  sorry

@[simp]
theorem smul_up (x y : TSet β) (ρ : AllPerm α) :
    ρ • up hβ x y = up hβ (ρ ↘ hβ • x) (ρ ↘ hβ • y) := by
  sorry

@[simp]
theorem smul_op (x y : TSet γ) (ρ : AllPerm α) :
    ρ • op hβ hγ x y = op hβ hγ (ρ ↘ hβ ↘ hγ • x) (ρ ↘ hβ ↘ hγ • y) := by
  sorry

theorem exists_singletonImage (x : TSet β) :
    ∃ y : TSet α, ∀ z w,
    op hγ hδ (singleton hε z) (singleton hε w) ∈[hβ] y ↔ op hδ hε z w ∈[hγ] x := by
  sorry

theorem exists_insertion2 (x : TSet γ) :
    ∃ y : TSet α, ∀ a b c, op hγ hδ (singleton hε (singleton hζ a)) (op hε hζ b c) ∈[hβ] y ↔
    op hε hζ a c ∈[hδ] x := by
  sorry

theorem exists_insertion3 (x : TSet γ) :
    ∃ y : TSet α, ∀ a b c, op hγ hδ (singleton hε (singleton hζ a)) (op hε hζ b c) ∈[hβ] y ↔
    op hε hζ a b ∈[hδ] x := by
  sorry

theorem exists_cross (x : TSet γ) :
    ∃ y : TSet α, ∀ a, a ∈[hβ] y ↔ ∃ b c, a = op hγ hδ b c ∧ c ∈[hδ] x := by
  sorry

theorem exists_typeLower (x : TSet α) :
    ∃ y : TSet δ, ∀ a, a ∈[hε] y ↔ ∀ b, op hγ hδ b (singleton hε a) ∈[hβ] x := by
  sorry

theorem exists_converse (x : TSet α) :
    ∃ y : TSet α, ∀ a b, op hγ hδ a b ∈[hβ] y ↔ op hγ hδ b a ∈[hβ] x := by
  sorry

theorem exists_cardinalOne :
    ∃ x : TSet α, ∀ a : TSet β, a ∈[hβ] x ↔ ∃ b, a = singleton hγ b := by
  sorry

theorem exists_subset :
    ∃ x : TSet α, ∀ a b, op hγ hδ a b ∈[hβ] x ↔ ∀ c : TSet ε, c ∈[hε] a → c ∈[hε] b := by
  sorry

end TSet

end ConNF
