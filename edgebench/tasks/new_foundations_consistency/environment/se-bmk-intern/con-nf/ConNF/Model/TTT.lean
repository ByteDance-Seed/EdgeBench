import ConNF.Model.RaiseStrong

/-!
# New file

In this file...

## Main declarations

* `ConNF.foo`: Something new.
-/

noncomputable section
universe u

open Cardinal Ordinal

open scoped Pointwise

namespace ConNF

variable [Params.{u}]

/-- A redefinition of the derivative of allowable permutations that is invariant of level,
but still has nice definitional properties. -/
@[default_instance 200]
instance {β γ : TypeIndex} : Derivative (AllPerm β) (AllPerm γ) β γ where
  deriv ρ A :=
    A.recSderiv
    (motive := λ (δ : TypeIndex) (A : β ↝ δ) ↦
      letI : Level := ⟨δ.recBotCoe (Nonempty.some inferInstance) id⟩
      letI : LeLevel δ := ⟨δ.recBotCoe (λ _ ↦ bot_le) (λ _ h ↦ WithBot.coe_le_coe.mpr h.le)
        (show δ.recBotCoe (Nonempty.some inferInstance) id = Level.α from rfl)⟩
      AllPerm δ)
    ρ (λ δ ε A h ρ ↦
      letI : Level := ⟨δ.recBotCoe (Nonempty.some inferInstance) id⟩
      letI : LeLevel δ := ⟨δ.recBotCoe (λ _ ↦ bot_le) (λ _ h ↦ WithBot.coe_le_coe.mpr h.le)
        (show δ.recBotCoe (Nonempty.some inferInstance) id = Level.α from rfl)⟩
      letI : LeLevel ε := ⟨h.le.trans LeLevel.elim⟩
      PreCoherentData.allPermSderiv h ρ)

@[simp]
theorem allPerm_deriv_nil' {β : TypeIndex}
    (ρ : AllPerm β) :
    ρ ⇘ (.nil : β ↝ β) = ρ := by
  sorry

@[simp]
theorem allPerm_deriv_sderiv' {β γ δ : TypeIndex}
    (ρ : AllPerm β) (A : β ↝ γ) (h : δ < γ) :
    ρ ⇘ (A ↘ h) = ρ ⇘ A ↘ h := by
  sorry

@[simp]
theorem allPermSderiv_forget' {β γ : TypeIndex} (h : γ < β) (ρ : AllPerm β) :
    (ρ ↘ h)ᵁ = ρᵁ ↘ h := by
  sorry

@[simp]
theorem allPerm_inv_sderiv' {β γ : TypeIndex} (h : γ < β) (ρ : AllPerm β) :
    ρ⁻¹ ↘ h = (ρ ↘ h)⁻¹ := by
  sorry

def Symmetric {α β : Λ} (s : Set (TSet β)) (hβ : (β : TypeIndex) < α) : Prop :=
  ∃ S : Support α, ∀ ρ : AllPerm α, ρᵁ • S = S → ρ ↘ hβ • s = s

def newSetEquiv {α : Λ} :
    letI : Level := ⟨α⟩
    @TSet _ α newModelData.toPreModelData ≃ TSet α :=
  letI : Level := ⟨α⟩
  castTSet (D₁ := newModelData) (D₂ := globalModelData) rfl
    (by rw [globalModelData, motive_eq, constructMotive, globalLtData_eq])

@[simp]
theorem newSetEquiv_forget {α : Λ}
    (x : letI : Level := ⟨α⟩; @TSet _ α newModelData.toPreModelData) :
    (newSetEquiv x)ᵁ = xᵁ := by
  sorry

def allPermEquiv {α : Λ} :
    letI : Level := ⟨α⟩
    NewPerm ≃ AllPerm α :=
  letI : Level := ⟨α⟩
  castAllPerm (D₁ := newModelData) (D₂ := globalModelData) rfl
    (by rw [globalModelData, motive_eq, constructMotive, globalLtData_eq])

@[simp]
theorem allPermEquiv_forget {α : Λ} (ρ : letI : Level := ⟨α⟩; NewPerm) :
    (allPermEquiv ρ)ᵁ = ρᵁ := by
  sorry

theorem allPermEquiv_sderiv {α β : Λ}
    (ρ : letI : Level := ⟨α⟩; NewPerm) (hβ : (β : TypeIndex) < α) :
    letI : Level := ⟨α⟩
    letI : LtLevel β := ⟨hβ⟩
    allPermEquiv ρ ↘ hβ = ρ.sderiv β := by
  sorry

theorem TSet.exists_of_symmetric {α β : Λ} (s : Set (TSet β)) (hβ : (β : TypeIndex) < α)
    (hs : Symmetric s hβ) :
    ∃ x : TSet α, ∀ y : TSet β, y ∈[hβ] x ↔ y ∈ s := by
  sorry

theorem TSet.exists_support {α : Λ} (x : TSet α) :
    ∃ S : Support α, ∀ ρ : AllPerm α, ρᵁ • S = S → ρ • x = x := by
  sorry

theorem TSet.symmetric {α β : Λ} (x : TSet α) (hβ : (β : TypeIndex) < α) :
    Symmetric {y : TSet β | y ∈[hβ] x} hβ := by
  sorry

theorem tSet_ext' {α β : Λ} (hβ : (β : TypeIndex) < α) (x y : TSet α)
    (h : ∀ z : TSet β, z ∈[hβ] x ↔ z ∈[hβ] y) : x = y := by
  sorry

@[simp]
theorem TSet.mem_smul_iff' {α β : TypeIndex}
    {x : TSet β} {y : TSet α} (h : β < α) (ρ : AllPerm α) :
    x ∈[h] ρ • y ↔ ρ⁻¹ ↘ h • x ∈[h] y := by
  sorry  -- For some reason, using `exact` instead of term mode speeds this up!

def singleton {α β : Λ} (hβ : (β : TypeIndex) < α) (x : TSet β) : TSet α :=
  letI : Level := ⟨α⟩
  letI : LeLevel α := ⟨le_rfl⟩
  letI : LtLevel β := ⟨hβ⟩
  PreCoherentData.singleton hβ x

@[simp]
theorem typedMem_singleton_iff' {α β : Λ} (hβ : (β : TypeIndex) < α) (x y : TSet β) :
    y ∈[hβ] singleton hβ x ↔ y = x := by
  sorry

@[simp]
theorem smul_singleton {α β : Λ} (hβ : (β : TypeIndex) < α) (x : TSet β) (ρ : AllPerm α) :
    ρ • singleton hβ x = singleton hβ (ρ ↘ hβ • x) := by
  sorry

theorem singleton_injective {α β : Λ} (hβ : (β : TypeIndex) < α) :
    Function.Injective (singleton hβ) := by
  sorry

@[simp]
theorem singleton_inj {α β : Λ} {hβ : (β : TypeIndex) < α} {x y : TSet β} :
    singleton hβ x = singleton hβ y ↔ x = y := by
  sorry

theorem sUnion_singleton_symmetric_aux' {α β γ : Λ}
    (hγ : (γ : TypeIndex) < β) (hβ : (β : TypeIndex) < α) (s : Set (TSet γ)) (S : Support α)
    (hS : ∀ ρ : AllPerm α, ρᵁ • S = S → ρ ↘ hβ • singleton hγ '' s = singleton hγ '' s) :
    letI : Level := ⟨α⟩
    letI : LeLevel α := ⟨le_rfl⟩
    ∀ (ρ : AllPerm β), ρᵁ • S.strong ↘ hβ = S.strong ↘ hβ → ρ ↘ hγ • s ⊆ s := by
  sorry

theorem sUnion_singleton_symmetric_aux {α β γ : Λ}
    (hγ : (γ : TypeIndex) < β) (hβ : (β : TypeIndex) < α) (s : Set (TSet γ)) (S : Support α)
    (hS : ∀ ρ : AllPerm α, ρᵁ • S = S → ρ ↘ hβ • singleton hγ '' s = singleton hγ '' s) :
    letI : Level := ⟨α⟩
    letI : LeLevel α := ⟨le_rfl⟩
    ∀ (ρ : AllPerm β), ρᵁ • S.strong ↘ hβ = S.strong ↘ hβ → ρ ↘ hγ • s = s := by
  sorry

theorem sUnion_singleton_symmetric {α β γ : Λ} (hγ : (γ : TypeIndex) < β) (hβ : (β : TypeIndex) < α)
    (s : Set (TSet γ)) (hs : Symmetric (singleton hγ '' s) hβ) :
    Symmetric s hγ := by
  sorry

end ConNF
