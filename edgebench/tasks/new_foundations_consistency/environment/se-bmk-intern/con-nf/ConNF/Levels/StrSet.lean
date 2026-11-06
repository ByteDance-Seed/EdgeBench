import ConNF.Levels.StrPerm

/-!
# Structural sets

In this file, we define structural sets, which serve as the environment inside which we will
construct the types of our model

## Main declarations

* `ConNF.StrSet`: The type family of structural sets.
-/

universe u

open scoped Pointwise

namespace ConNF

variable [Params.{u}]

def StrSet : TypeIndex → Type u
  | ⊥ => Atom
  | (α : Λ) => (β : TypeIndex) → β < α → Set (StrSet β)
termination_by α => α

namespace StrSet

theorem bot_eq :
    StrSet ⊥ = Atom := by
  sorry

theorem coe_eq (α : Λ) :
    StrSet α = ((β : TypeIndex) → β < α → Set (StrSet β)) := by
  sorry

def botEquiv :
    StrSet ⊥ ≃ Atom :=
  Equiv.cast bot_eq

def coeEquiv {α : Λ} :
    StrSet α ≃ ((β : TypeIndex) → β < α → Set (StrSet β)) :=
  Equiv.cast (coe_eq α)

/-- Extensionality for structural sets at proper type indices. If two structural sets have the same
extensions at every lower type index, then they are the same. -/
theorem coe_ext_iff' {α : Λ} {x y : StrSet α} :
    x = y ↔ ∀ β hβ z, z ∈ coeEquiv x β hβ ↔ z ∈ coeEquiv y β hβ := by
  sorry

def strPerm_smul : {α : TypeIndex} → StrPerm α → StrSet α → StrSet α
  | ⊥, π, x => botEquiv.symm <| π Path.nil • botEquiv x
  | (α : Λ), π, x => coeEquiv.symm <| λ β hβ ↦ strPerm_smul (π ↘ hβ) '' coeEquiv x β hβ
termination_by α => α

instance {α : TypeIndex} : SMul (StrPerm α) (StrSet α) where
  smul := strPerm_smul

@[simp]
theorem strPerm_smul_bot (π : StrPerm ⊥) (x : StrSet ⊥) :
    botEquiv (π • x) = π .nil • botEquiv x := by
  sorry

theorem one_strPerm_smul {α : TypeIndex} (x : StrSet α) : strPerm_smul 1 x = x := by
  sorry

theorem mul_strPerm_smul {α : TypeIndex} (π₁ π₂ : StrPerm α) (x : StrSet α) :
    strPerm_smul (π₁ * π₂) x = strPerm_smul π₁ (strPerm_smul π₂ x) := by
  sorry

instance {α : TypeIndex} : MulAction (StrPerm α) (StrSet α) where
  one_smul := one_strPerm_smul
  mul_smul := mul_strPerm_smul

theorem smul_none {α : Λ} (π : StrPerm α) :
    π • (StrSet.coeEquiv.symm λ _ _ ↦ ∅ : StrSet α) = StrSet.coeEquiv.symm λ _ _ ↦ ∅ := by
  sorry

end StrSet

/-!
## Notation for typed membership
-/

class TypedMem (X Y : Type _) (β α : outParam TypeIndex) where
  typedMem : β < α → X → Y → Prop

notation:50 x:50 " ∈[" h "] " y:50 => TypedMem.typedMem h x y
notation:50 x:50 " ∈' " y:50 => x ∈[by assumption] y

def typedSubset (X : Type _) {Y : Type _} {β α : TypeIndex} [TypedMem X Y β α]
    (h : β < α) (a b : Y) : Prop :=
  ∀ x : X, x ∈[h] a → x ∈[h] b

notation:50 x:50 " ⊆[" X ", " h "] " y:50 => typedSubset X h x y
notation:50 x:50 " ⊆[" X "] " y:50 => x ⊆[X, by assumption] y

instance {β α : TypeIndex} : TypedMem (StrSet β) (StrSet α) β α where
  typedMem h x y :=
    match α with
    | ⊥ => (not_lt_bot h).elim
    | (α : Λ) => x ∈ StrSet.coeEquiv y β h

theorem StrSet.mem_smul_iff {α β : TypeIndex} {x : StrSet β} {y : StrSet α}
    (h : β < α) (π : StrPerm α) :
    x ∈[h] π • y ↔ (π ↘ h)⁻¹ • x ∈[h] y := by
  sorry

end ConNF
