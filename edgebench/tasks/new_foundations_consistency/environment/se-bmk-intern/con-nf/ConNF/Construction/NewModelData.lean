import Mathlib.Algebra.Group.Action.Option
import ConNF.Construction.Code

/-!
# Construction of model data

In this file, we construct model data at type `α`, given that it is defined at all types below `α`.

## Main declarations

* `ConNF.foo`: Something new.
-/

noncomputable section
universe u

open Cardinal Ordinal
open scoped Pointwise

namespace ConNF

variable [Params.{u}] [Level] [LtData]

@[ext]
structure NewPerm : Type u where
  sderiv : (β : TypeIndex) → [LtLevel β] → AllPerm β
  smul_fuzz' {β : TypeIndex} {γ : Λ} [LtLevel β] [LtLevel γ] (hβγ : β ≠ γ) (t : Tangle β) :
    (sderiv γ)ᵁ ↘. • fuzz hβγ t = fuzz hβγ (sderiv β • t)

instance : Mul NewPerm where
  mul ρ₁ ρ₂ := ⟨λ β _ ↦ ρ₁.sderiv β * ρ₂.sderiv β, by
    intro β γ _ _ hβγ t
    simp only [allPermForget_mul, mul_smul, Tree.mul_sderivBot, NewPerm.smul_fuzz']⟩

instance : One NewPerm where
  one := ⟨λ _ _ ↦ 1, by
    intro β γ _ _ hβγ t
    simp only [allPermForget_one, one_smul, Tree.one_sderivBot]⟩

instance : Inv NewPerm where
  inv ρ := ⟨λ β _ ↦ (ρ.sderiv β)⁻¹, by sorry⟩

instance : Group NewPerm where
  mul_assoc ρ₁ ρ₂ ρ₃ := by sorry
  one_mul ρ := by sorry
  mul_one ρ := by sorry
  inv_mul_cancel ρ := by sorry

instance : SMul NewPerm Code where
  smul ρ c := ⟨c.β, ρ.sderiv c.β • c.s, Set.smul_set_nonempty.mpr c.hs⟩

instance : MulAction NewPerm Code where
  one_smul := by sorry
  mul_smul := by sorry

@[simp]
theorem Code.smul_even {c : Code} (ρ : NewPerm) :
    (ρ • c).Even ↔ c.Even := by
  sorry

theorem Represents.smul {c d : Code} (h : Represents c d) (ρ : NewPerm) :
    Represents (ρ • c) (ρ • d) := by
  sorry

@[simp]
theorem NewPerm.smul_members (ρ : NewPerm) (c : Code) (β : TypeIndex) [LtLevel β] :
    (ρ • c).members β = ρ.sderiv β • c.members β := by
  sorry

instance : SuperU NewPerm (StrPerm α) where
  superU ρ := λ A ↦ A.recScoderiv (motive := λ β _ ↦ β ≠ ⊥ → β ≤ α → BasePerm)
    (λ h ↦ (h rfl).elim)
    (λ _β γ B hγβ _ _ hβα ↦ letI : LtLevel γ := ⟨hγβ.trans_le hβα⟩; (ρ.sderiv γ)ᵁ B)
    WithBot.coe_ne_bot le_rfl

@[simp]
theorem NewPerm.forget_mul (ρ₁ ρ₂ : NewPerm) :
    (ρ₁ * ρ₂)ᵁ = ρ₁ᵁ * ρ₂ᵁ := by
  sorry

@[simp]
theorem NewPerm.forget_one :
    (1 : NewPerm)ᵁ = 1 := by
  sorry

@[simp]
theorem NewPerm.forget_inv (ρ : NewPerm) :
    ρ⁻¹ᵁ = ρᵁ⁻¹ := by
  sorry

@[ext]
structure NewSet : Type u where
  c : Code
  hc : c.Even
  hS : ∃ S : Support α, ∀ ρ : NewPerm, ρᵁ • S = S → ρ • c = c

instance : SuperU NewSet (StrSet α) where
  superU x := StrSet.coeEquiv.symm
    λ β hβ ↦ letI : LtLevel β := ⟨hβ⟩; (·ᵁ) '' x.c.members β

instance : SMul NewPerm NewSet where
  smul ρ x := ⟨ρ • x.c, (Code.smul_even ρ).mpr x.hc, by
    obtain ⟨S, hS⟩ := x.hS
    use ρᵁ • S
    intro ρ' hρ'
    have := hS (ρ⁻¹ * ρ' * ρ) ?_
    · rwa [mul_smul, mul_smul, inv_smul_eq_iff] at this
    · rwa [NewPerm.forget_mul, NewPerm.forget_mul, mul_smul, mul_smul,
        NewPerm.forget_inv, inv_smul_eq_iff] ⟩

@[simp]
theorem NewSet.smul_c (ρ : NewPerm) (x : NewSet) :
    (ρ • x).c = ρ • x.c := by
  sorry

instance : MulAction NewPerm NewSet where
  one_smul x := by
    ext : 1
    rw [NewSet.smul_c, one_smul]
  mul_smul ρ₁ ρ₂ x := by
    ext : 1
    simp only [NewSet.smul_c, mul_smul]

def newPreModelData : PreModelData α where
  TSet := Option NewSet
  AllPerm := NewPerm
  tSetForget x := x.elim (StrSet.coeEquiv.symm λ _ _ ↦ ∅) (·ᵁ)
  allPermForget := (·ᵁ)

@[simp]
theorem newPreModelData.tSetForget_none :
    newPreModelData.tSetForget none = (StrSet.coeEquiv.symm λ _ _ ↦ ∅) := by
  sorry

@[simp]
theorem newPreModelData.tSetForget_some (x : NewSet) :
    newPreModelData.tSetForget (some x) = xᵁ := by
  sorry

@[simp]
theorem newPreModelData.tSetForget_none' :
    (show @TSet _ α newPreModelData from none)ᵁ = (StrSet.coeEquiv.symm λ _ _ ↦ ∅) := by
  sorry

@[simp]
theorem newPreModelData.tSetForget_some' (x : NewSet) :
    (show @TSet _ α newPreModelData from some x)ᵁ = xᵁ := by
  sorry

theorem NewPerm.forget_injective (ρ₁ ρ₂ : NewPerm) (h : ρ₁ᵁ = ρ₂ᵁ) : ρ₁ = ρ₂ := by
  sorry

theorem NewSet.forget_injective (x y : NewSet) (h : xᵁ = yᵁ) : x = y := by
  sorry

theorem NewPerm.smul_forget (ρ : NewPerm) (x : NewSet) : (ρ • x)ᵁ = ρᵁ • xᵁ := by
  sorry

theorem NewSet.exists_support (x : letI := newPreModelData; TSet α) :
    letI := newPreModelData
    ∃ S : Support α, S.Supports x := by
  sorry

theorem NewSet.coe_ne_empty (x : NewSet) : xᵁ ≠ (StrSet.coeEquiv.symm λ _ _ ↦ ∅) := by
  sorry

def newModelData : ModelData α where
  tSetForget_injective' := by
    rintro (_ | x) (_ | y) h
    · rfl
    · cases NewSet.coe_ne_empty y h.symm
    · cases NewSet.coe_ne_empty x h
    · rw [NewSet.forget_injective x y h]
  tSetForget_surjective_of_bot' := by rintro ⟨⟩
  allPermForget_injective' := NewPerm.forget_injective
  allPermForget_one' := NewPerm.forget_one
  allPermForget_mul' := NewPerm.forget_mul
  smul_forget' := by
    rintro ρ (_ | x)
    · rw [newPreModelData.tSetForget_none, StrSet.smul_none]
      rfl
    · exact NewPerm.smul_forget ρ x
  exists_support := NewSet.exists_support
  __ := newPreModelData

theorem Code.hasSet (c : Code)
    (hc : ∃ S : Support α, ∀ ρ : NewPerm, ρᵁ • S = S → ρ • c = c) :
    ∃ x : NewSet, Represents x.c c := by
  sorry

def Code.toSet (c : Code)
    (hc : ∃ S : Support α, ∀ ρ : NewPerm, ρᵁ • S = S → ρ • c = c) :
    NewSet :=
  (c.hasSet hc).choose

theorem Code.toSet_spec (c : Code)
    (hc : ∃ S : Support α, ∀ ρ : NewPerm, ρᵁ • S = S → ρ • c = c) :
    Represents (c.toSet hc).c c := by
  sorry

theorem Code.mem_toSet' (c : Code) {hc : ∃ S : Support α, ∀ ρ : NewPerm, ρᵁ • S = S → ρ • c = c}
    (y : TSet c.β) :
    yᵁ ∈[LtLevel.elim] (c.toSet hc)ᵁ ↔ y ∈ c.s := by
  sorry

theorem Code.mem_toSet {β : TypeIndex} [LtLevel β] {s : Set (TSet β)} {hs : s.Nonempty}
    {hc : ∃ S : Support α, ∀ ρ : NewPerm, ρᵁ • S = S → ρ • Code.mk β s hs = Code.mk β s hs}
    (y : TSet β) :
    yᵁ ∈[LtLevel.elim] (Code.toSet ⟨β, s, hs⟩ hc)ᵁ ↔ y ∈ s := by
  sorry

theorem NearLitter.code_aux {N : NearLitter} :
    {x : TSet ⊥ | StrSet.botEquiv xᵁ ∈ Nᴬ}.Nonempty := by
  sorry

def NearLitter.code (N : NearLitter) : Code :=
  ⟨⊥, {x | StrSet.botEquiv xᵁ ∈ Nᴬ}, NearLitter.code_aux⟩

theorem newTyped_aux {N : NearLitter} :
    ∃ S : Support α, ∀ ρ : NewPerm, ρᵁ • S = S → ρ • N.code = N.code := by
  sorry

def newTyped (N : NearLitter) : NewSet :=
  N.code.toSet newTyped_aux

theorem newTyped_c_eq (N : NearLitter) :
    (newTyped N).c = N.code := by
  sorry

theorem mem_newTyped_iff (a : TSet ⊥) (N : NearLitter) :
    aᵁ ∈[WithBot.bot_lt_coe _] (newTyped N)ᵁ ↔ StrSet.botEquiv aᵁ ∈ Nᴬ := by
  sorry

theorem newTyped_injective : Function.Injective newTyped := by
  sorry

theorem smul_newTyped (ρ : NewPerm) (N : NearLitter) :
    ρ • newTyped N = newTyped (ρᵁ ↘. • N) := by
  sorry

def newSingletonCode {γ : Λ} [LtLevel γ] (x : TSet γ) : Code :=
  ⟨γ, {x}, Set.singleton_nonempty x⟩

theorem newSingleton_aux {γ : Λ} [LtLevel γ] {x : TSet γ} :
    ∃ S : Support α, ∀ ρ : NewPerm, ρᵁ • S = S → ρ • newSingletonCode x = newSingletonCode x := by
  sorry

def newSingleton {γ : Λ} [LtLevel γ] (x : TSet γ) : NewSet :=
  (newSingletonCode x).toSet newSingleton_aux

local instance : ModelData α := newModelData

theorem mem_none_iff {β : TypeIndex} [LtLevel β] (y : TSet β) :
    y ∈[LtLevel.elim] (show TSet α from none) ↔
    yᵁ ∈[LtLevel.elim] (StrSet.coeEquiv.symm λ _ _ ↦ ∅) := by
  sorry

theorem mem_some_iff {β : TypeIndex} [LtLevel β] (y : TSet β) (x : NewSet) :
    y ∈[LtLevel.elim] (show TSet α from some x) ↔
    yᵁ ∈[LtLevel.elim] xᵁ := by
  sorry

theorem mem_newSingleton_iff {γ : Λ} [LtLevel γ] (x y : TSet γ) :
    y ∈[LtLevel.elim] (show TSet α from some (newSingleton x)) ↔ y = x := by
  sorry

theorem not_mem_none {β : TypeIndex} [LtLevel β] (z : TSet β) :
    ¬z ∈[LtLevel.elim] (show TSet α from none) := by
  sorry

theorem newModelData_ext (β : Λ) [LtLevel β] (x y : TSet α)
    (h : ∀ z : TSet β, z ∈[LtLevel.elim] x ↔ z ∈[LtLevel.elim] y) :
    x = y := by
  sorry

def newPositionDeny (t : Tangle α) : Set μ :=
  pos '' {N | t.set = some (newTyped N)} ∪
    pos '' (t.supportᴬ.image Prod.snd : Set Atom) ∪
    pos '' (t.supportᴺ.image Prod.snd : Set NearLitter)

theorem card_newPositionDeny (t : Tangle α) :
    #(newPositionDeny t) < (#μ).ord.cof := by
  sorry

def newPosition (h : #(Tangle α) ≤ #μ) : Position (Tangle α) where
  pos := ⟨funOfDeny h newPositionDeny card_newPositionDeny, funOfDeny_injective _ _ _⟩

theorem pos_atom_lt_newPosition (h : #(Tangle α) ≤ #μ) (t : Tangle α) (a : Atom)
    (A : α ↝ ⊥) (ha : a ∈ (t.support ⇘. A)ᴬ) :
    pos a < (newPosition h).pos t := by
  sorry

theorem pos_nearLitter_lt_newPosition (h : #(Tangle α) ≤ #μ) (t : Tangle α) (N : NearLitter)
    (A : α ↝ ⊥) (hN : N ∈ (t.support ⇘. A)ᴺ) :
    pos N < (newPosition h).pos t := by
  sorry

theorem pos_le_pos_of_typed (h : #(Tangle α) ≤ #μ) (N : NearLitter) (t : Tangle α)
    (ht : t.set = some (newTyped N)) :
    pos N ≤ (newPosition h).pos t := by
  sorry

theorem smul_newTyped' (ρ : AllPerm α) (N : NearLitter) :
    ρ • (show TSet α from some (newTyped N)) = some (newTyped (ρᵁ ↘. • N)) := by
  sorry

def newTypedNearLitters (h : #(Tangle α) ≤ #μ) :
    letI := newPosition h; TypedNearLitters α :=
  letI := newPosition h
  {
    typed := some ∘ newTyped
    typed_injective := (Option.some_injective _).comp newTyped_injective
    pos_le_pos_of_typed := pos_le_pos_of_typed h
    smul_typed := smul_newTyped'
  }

end ConNF
