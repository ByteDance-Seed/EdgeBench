import ConNF.Levels.StrSet
import ConNF.ModelData.Support

/-!
# Model data

In this file, we define what model data at a type index means.

## Main declarations

* `ConNF.ModelData`: The type of model data at a given type index.
-/

universe u

open Cardinal

namespace ConNF

variable [Params.{u}]

/-- The same as `ModelData` but without the propositions. -/
class PreModelData (α : TypeIndex) where
  TSet : Type u
  AllPerm : Type u
  [allPermGroup : Group AllPerm]
  [allAction : MulAction AllPerm TSet]
  tSetForget : TSet → StrSet α
  allPermForget : AllPerm → StrPerm α

export PreModelData (TSet AllPerm)

attribute [instance] PreModelData.allPermGroup PreModelData.allAction

instance {α : TypeIndex} [PreModelData α] : SuperU (TSet α) (StrSet α) where
  superU := PreModelData.tSetForget

instance {α : TypeIndex} [PreModelData α] : SuperU (AllPerm α) (StrPerm α) where
  superU := PreModelData.allPermForget

structure Support.Supports {X : Type _} {α : TypeIndex} [PreModelData α] [MulAction (AllPerm α) X]
    (S : Support α) (x : X) : Prop where
  supports (ρ : AllPerm α) : ρᵁ • S = S → ρ • x = x
  nearLitters_eq_empty_of_bot : α = ⊥ → Sᴺ = .empty

class ModelData (α : TypeIndex) extends PreModelData α where
  tSetForget_injective' : Function.Injective tSetForget
  tSetForget_surjective_of_bot' : α = ⊥ → Function.Surjective tSetForget
  allPermForget_injective' : Function.Injective allPermForget
  allPermForget_one' : allPermForget 1 = 1
  allPermForget_mul' (ρ₁ ρ₂ : AllPerm) :
    allPermForget (ρ₁ * ρ₂) = allPermForget ρ₁ * allPermForget ρ₂
  smul_forget' (ρ : AllPerm) (x : TSet) : tSetForget (ρ • x) = allPermForget ρ • tSetForget x
  exists_support (x : TSet) : ∃ S : Support α, S.Supports x

export ModelData (exists_support)

@[simp]
theorem allPermForget_one {α : TypeIndex} [ModelData α] :
    (1 : AllPerm α)ᵁ = 1 := by
  sorry

@[simp]
theorem allPermForget_mul {α : TypeIndex} [ModelData α] (ρ₁ ρ₂ : AllPerm α) :
    (ρ₁ * ρ₂)ᵁ = ρ₁ᵁ * ρ₂ᵁ := by
  sorry

@[simp]
theorem allPermForget_inv {α : TypeIndex} [ModelData α] (ρ : AllPerm α) : ρ⁻¹ᵁ = ρᵁ⁻¹ := by
  sorry

theorem Support.Supports.smul_eq_smul {X : Type _} {α : TypeIndex}
    [ModelData α] [MulAction (AllPerm α) X]
    {S : Support α} {x : X} (h : S.Supports x) {ρ₁ ρ₂ : AllPerm α} (hρ : ρ₁ᵁ • S = ρ₂ᵁ • S) :
    ρ₁ • x = ρ₂ • x := by
  sorry

theorem Support.Supports.smul {X : Type _} {α : TypeIndex}
    [ModelData α] [MulAction (AllPerm α) X]
    {S : Support α} {x : X} (h : S.Supports x) (ρ : AllPerm α) :
    (ρᵁ • S).Supports (ρ • x) := by
  sorry

instance {β α : TypeIndex} [ModelData β] [ModelData α] : TypedMem (TSet β) (TSet α) β α where
  typedMem h y x := yᵁ ∈[h] xᵁ

theorem TSet.forget_mem_forget {β α : TypeIndex} [ModelData β] [ModelData α] (h : β < α)
    {x : TSet β} {y : TSet α} :
    xᵁ ∈[h] yᵁ ↔ x ∈[h] y := by
  sorry

@[ext]
structure Tangle (α : TypeIndex) [ModelData α] where
  set : TSet α
  support : Support α
  support_supports : support.Supports set

instance {α : TypeIndex} [ModelData α] : SMul (AllPerm α) (Tangle α) where
  smul ρ t := ⟨ρ • t.set, ρᵁ • t.support, t.support_supports.smul ρ⟩

@[simp]
theorem Tangle.smul_set {α : TypeIndex} [ModelData α] (ρ : AllPerm α) (t : Tangle α) :
    (ρ • t).set = ρ • t.set := by
  sorry

@[simp]
theorem Tangle.smul_support {α : TypeIndex} [ModelData α] (ρ : AllPerm α) (t : Tangle α) :
    (ρ • t).support = ρᵁ • t.support := by
  sorry

instance {α : TypeIndex} [ModelData α] : MulAction (AllPerm α) (Tangle α) where
  one_smul t := by
    ext : 1
    · rw [Tangle.smul_set, one_smul]
    · rw [Tangle.smul_support, allPermForget_one, one_smul]
  mul_smul ρ₁ ρ₂ t := by
    ext : 1
    · rw [Tangle.smul_set, Tangle.smul_set, Tangle.smul_set, mul_smul]
    · rw [Tangle.smul_support, Tangle.smul_support, Tangle.smul_support,
        allPermForget_mul, mul_smul]

theorem Tangle.smul_eq {α : TypeIndex} [ModelData α] {ρ : AllPerm α} {t : Tangle α}
    (h : ρᵁ • t.support = t.support) :
    ρ • t = t := by
  sorry

/-!
## Criteria for supports
-/

theorem Support.supports_coe {α : Λ} {X : Type _} [PreModelData α] [MulAction (AllPerm α) X]
    (S : Support α) (x : X)
    (h : ∀ ρ : AllPerm α,
      (∀ A : α ↝ ⊥, ∀ a ∈ (S ⇘. A)ᴬ, ρᵁ A • a = a) →
      (∀ A : α ↝ ⊥, ∀ N ∈ (S ⇘. A)ᴺ, ρᵁ A • N = N) → ρ • x = x) :
    S.Supports x := by
  sorry

theorem Support.supports_bot {X : Type _} [PreModelData ⊥] [MulAction (AllPerm ⊥) X]
    (E : Enumeration (⊥ ↝ ⊥ × Atom)) (x : X)
    (h : ∀ ρ : AllPerm ⊥, (∀ A : ⊥ ↝ ⊥, ∀ x : Atom, (A, x) ∈ E → ρᵁ A • x = x) → ρ • x = x) :
    (⟨E, .empty⟩ : Support ⊥).Supports x := by
  sorry

/-!
## Model data at level `⊥`
-/

def botPreModelData : PreModelData ⊥ where
  TSet := Atom
  AllPerm := BasePerm
  tSetForget := StrSet.botEquiv.symm
  allPermForget ρ _ := ρ

def botModelData : ModelData ⊥ where
  tSetForget_injective' := Equiv.injective _
  tSetForget_surjective_of_bot' _ := Equiv.surjective _
  allPermForget_injective' _ _ h := congr_fun h Path.nil
  allPermForget_one' := rfl
  allPermForget_mul' _ _ := rfl
  smul_forget' ρ x := by
    apply StrSet.botEquiv.injective
    have : ∀ x : TSet ⊥, xᵁ = StrSet.botEquiv.symm x := λ _ ↦ rfl
    unfold PreModelData.allPermForget botPreModelData
    simp only [this, Equiv.apply_symm_apply, StrSet.strPerm_smul_bot]
  exists_support x := by
    use ⟨.singleton (Path.nil, x), .empty⟩
    apply Support.supports_bot
    intro ρ hc
    apply hc Path.nil x
    rw [Enumeration.mem_singleton_iff]
  __ := botPreModelData

end ConNF
