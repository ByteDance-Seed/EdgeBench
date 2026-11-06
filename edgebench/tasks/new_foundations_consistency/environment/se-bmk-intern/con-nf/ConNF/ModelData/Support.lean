import ConNF.ModelData.PathEnumeration

/-!
# Supports

In this file, we define the notion of a support.

## Main declarations

* `ConNF.BaseSupport`: The type of supports of atoms.
* `ConNF.Support`: The type of supports of objects of arbitrary type indices.
-/

universe u

open Cardinal

namespace ConNF

variable [Params.{u}]

/-!
## Base supports
-/

structure BaseSupport where
  atoms : Enumeration Atom
  nearLitters : Enumeration NearLitter

namespace BaseSupport

instance : SuperA BaseSupport (Enumeration Atom) where
  superA := atoms

instance : SuperN BaseSupport (Enumeration NearLitter) where
  superN := nearLitters

@[simp]
theorem mk_nearLitters {a : Enumeration Atom} {N : Enumeration NearLitter} :
    (BaseSupport.mk a N)ᴺ = N := by
  sorry

@[ext]
theorem ext {S T : BaseSupport} (h₁ : Sᴬ = Tᴬ) (h₂ : Sᴺ = Tᴺ) : S = T := by
  sorry

instance : SMul BasePerm BaseSupport where
  smul π S := ⟨π • Sᴬ, π • Sᴺ⟩

@[simp]
theorem smul_atoms (π : BasePerm) (S : BaseSupport) :
    (π • S)ᴬ = π • Sᴬ := by
  sorry

@[simp]
theorem smul_nearLitters (π : BasePerm) (S : BaseSupport) :
    (π • S)ᴺ = π • Sᴺ := by
  sorry

@[simp]
theorem smul_atoms_eq_of_smul_eq {π : BasePerm} {S : BaseSupport}
    (h : π • S = S) :
    π • Sᴬ = Sᴬ := by
  sorry

@[simp]
theorem smul_nearLitters_eq_of_smul_eq {π : BasePerm} {S : BaseSupport}
    (h : π • S = S) :
    π • Sᴺ = Sᴺ := by
  sorry

instance : MulAction BasePerm BaseSupport where
  one_smul S := by
    apply ext
    · rw [smul_atoms, one_smul]
    · rw [smul_nearLitters, one_smul]
  mul_smul π₁ π₂ S := by
    apply ext
    · rw [smul_atoms, smul_atoms, smul_atoms, mul_smul]
    · rw [smul_nearLitters, smul_nearLitters, smul_nearLitters, mul_smul]

theorem smul_eq_smul_iff (π₁ π₂ : BasePerm) (S : BaseSupport) :
    π₁ • S = π₂ • S ↔ (∀ a ∈ Sᴬ, π₁ • a = π₂ • a) ∧ (∀ N ∈ Sᴺ, π₁ • N = π₂ • N) := by
  sorry

noncomputable instance : Add BaseSupport where
  add S T := ⟨Sᴬ + Tᴬ, Sᴺ + Tᴺ⟩

end BaseSupport

def baseSupportEquiv : BaseSupport ≃ Enumeration Atom × Enumeration NearLitter where
  toFun S := (Sᴬ, Sᴺ)
  invFun S := ⟨S.1, S.2⟩
  left_inv _ := rfl
  right_inv _ := rfl

theorem card_baseSupport : #BaseSupport = #μ := by
  sorry

/-!
## Structural supports
-/

structure Support (α : TypeIndex) where
  atoms : Enumeration (α ↝ ⊥ × Atom)
  nearLitters : Enumeration (α ↝ ⊥ × NearLitter)

namespace Support

variable {α β : TypeIndex}

instance : SuperA (Support α) (Enumeration (α ↝ ⊥ × Atom)) where
  superA := atoms

instance : SuperN (Support α) (Enumeration (α ↝ ⊥ × NearLitter)) where
  superN := nearLitters

instance : Derivative (Support α) (Support β) α β where
  deriv S A := ⟨Sᴬ ⇘ A, Sᴺ ⇘ A⟩

instance : Coderivative (Support β) (Support α) α β where
  coderiv S A := ⟨Sᴬ ⇗ A, Sᴺ ⇗ A⟩

instance : BotDerivative (Support α) BaseSupport α where
  botDeriv S A := ⟨Sᴬ ⇘. A, Sᴺ ⇘. A⟩
  botSderiv S := ⟨Sᴬ ↘., Sᴺ ↘.⟩
  botDeriv_single S h := by rw [botDeriv_single, botDeriv_single]

@[simp]
theorem sderiv_atoms {α β : TypeIndex} (S : Support α) (h : β < α) :
    Sᴬ ↘ h = (S ↘ h)ᴬ := by
  sorry

@[simp]
theorem sderiv_nearLitters {α β : TypeIndex} (S : Support α) (h : β < α) :
    Sᴺ ↘ h = (S ↘ h)ᴺ := by
  sorry

@[simp]
theorem coderiv_nearLitters {α β : TypeIndex} (S : Support β) (A : α ↝ β) :
    Sᴺ ⇗ A = (S ⇗ A)ᴺ := by
  sorry

@[simp]
theorem scoderiv_atoms {α β : TypeIndex} (S : Support β) (h : β < α) :
    Sᴬ ↗ h = (S ↗ h)ᴬ := by
  sorry

@[simp]
theorem scoderiv_nearLitters {α β : TypeIndex} (S : Support β) (h : β < α) :
    Sᴺ ↗ h = (S ↗ h)ᴺ := by
  sorry

theorem ext' {S T : Support α} (h₁ : Sᴬ = Tᴬ) (h₂ : Sᴺ = Tᴺ) : S = T := by
  sorry

@[ext]
theorem ext {S T : Support α} (h : ∀ A, S ⇘. A = T ⇘. A) : S = T := by
  sorry

@[simp]
theorem scoderiv_deriv_eq {α β γ : TypeIndex} (S : Support β) (A : β ↝ γ) (h : β < α) :
    S ↗ h ⇘ (A ↗ h) = S ⇘ A := by
  sorry

@[simp]
theorem coderiv_inj {α β : TypeIndex} (S T : Support β) (A : α ↝ β) :
    S ⇗ A = T ⇗ A ↔ S = T := by
  sorry

@[simp]
theorem scoderiv_inj {α β : TypeIndex} (S T : Support β) (h : β < α) :
    S ↗ h = T ↗ h ↔ S = T := by
  sorry

instance {α : TypeIndex} : SMul (StrPerm α) (Support α) where
  smul π S := ⟨π • Sᴬ, π • Sᴺ⟩

@[simp]
theorem smul_atoms {α : TypeIndex} (π : StrPerm α) (S : Support α) :
    (π • S)ᴬ = π • Sᴬ := by
  sorry

@[simp]
theorem smul_nearLitters {α : TypeIndex} (π : StrPerm α) (S : Support α) :
    (π • S)ᴺ = π • Sᴺ := by
  sorry

instance {α : TypeIndex} : MulAction (StrPerm α) (Support α) where
  one_smul S := by
    apply ext'
    · rw [smul_atoms, one_smul]
    · rw [smul_nearLitters, one_smul]
  mul_smul π₁ π₂ S := by
    apply ext'
    · rw [smul_atoms, smul_atoms, smul_atoms, mul_smul]
    · rw [smul_nearLitters, smul_nearLitters, smul_nearLitters, mul_smul]

noncomputable instance : Add (Support α) where
  add S T := ⟨Sᴬ + Tᴬ, Sᴺ + Tᴺ⟩

end Support

def supportEquiv {α : TypeIndex} : Support α ≃
    Enumeration (α ↝ ⊥ × Atom) × Enumeration (α ↝ ⊥ × NearLitter) where
  toFun S := (Sᴬ, Sᴺ)
  invFun S := ⟨S.1, S.2⟩
  left_inv _ := rfl
  right_inv _ := rfl

/-!
## Orders on supports
-/

-- TODO: Is this order used?
instance : LE BaseSupport where
  le S T := (∀ a ∈ Sᴬ, a ∈ Tᴬ) ∧ (∀ N ∈ Sᴺ, N ∈ Tᴺ)

instance : Preorder BaseSupport where
  le_refl S := ⟨λ _ ↦ id, λ _ ↦ id⟩
  le_trans S T U h₁ h₂ := ⟨λ a h ↦ h₂.1 _ (h₁.1 a h), λ N h ↦ h₂.2 _ (h₁.2 N h)⟩

def BaseSupport.Subsupport (S T : BaseSupport) : Prop :=
  Sᴬ.rel ≤ Tᴬ.rel ∧ Sᴺ.rel ≤ Tᴺ.rel

instance {α : TypeIndex} : LE (Support α) where
  le S T := ∀ A, S ⇘. A ≤ T ⇘. A

instance {α : TypeIndex} : Preorder (Support α) where
  le_refl S := λ A ↦ le_rfl
  le_trans S T U h₁ h₂ := λ A ↦ (h₁ A).trans (h₂ A)

def Support.Subsupport {α : TypeIndex} (S T : Support α) : Prop :=
  ∀ A, (S ⇘. A).Subsupport (T ⇘. A)

end ConNF
