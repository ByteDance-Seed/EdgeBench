import ConNF.ModelData.Enumeration
import ConNF.Levels.StrPerm

/-!
# Enumerations over paths

In this file, we provide extra features to `Enumeration`s that take values of the form `α ↝ ⊥ × X`.

## Main declarations

* `ConNF.Enumeration.ext_path`: An extensionality principle for such `Enumeration`s.
-/

noncomputable section
universe u

open Cardinal Ordinal

namespace ConNF

variable [Params.{u}]

namespace Enumeration

/-- A helper function for making relations with domain and codomain of the form `α ↝ ⊥ × X`
by defining it on each branch. -/
def relWithPath {X Y : Type u} {α : TypeIndex} (f : α ↝ ⊥ → Rel X Y) :
    Rel (α ↝ ⊥ × X) (α ↝ ⊥ × Y) :=
  λ x y ↦ x.1 = y.1 ∧ f x.1 x.2 y.2

theorem relWithPath_coinjective {X Y : Type u} {α : TypeIndex} {f : α ↝ ⊥ → Rel X Y}
    (hf : ∀ A, (f A).Coinjective) :
    (relWithPath f).Coinjective := by
  sorry

instance (X : Type u) (α β : TypeIndex) :
    Derivative (Enumeration (α ↝ ⊥ × X)) (Enumeration (β ↝ ⊥ × X)) α β where
  deriv E A := E.invImage (λ x ↦ (x.1 ⇗ A, x.2))
    (λ x y h ↦ Prod.ext (Path.deriv_right_injective
      ((Prod.mk.injEq _ _ _ _).mp h).1) ((Prod.mk.injEq _ _ _ _).mp h).2)

theorem deriv_rel {X : Type _} {α β : TypeIndex} (E : Enumeration (α ↝ ⊥ × X)) (A : α ↝ β)
    (i : κ) (x : β ↝ ⊥ × X) :
    (E ⇘ A).rel i x ↔ E.rel i (x.1 ⇗ A, x.2) := by
  sorry

instance (X : Type u) (α β : TypeIndex) :
    Coderivative (Enumeration (β ↝ ⊥ × X)) (Enumeration (α ↝ ⊥ × X)) α β where
  coderiv E A := E.image (λ x ↦ (x.1 ⇗ A, x.2))

theorem coderiv_rel {X : Type _} {α β : TypeIndex} (E : Enumeration (β ↝ ⊥ × X)) (A : α ↝ β)
    (i : κ) (x : α ↝ ⊥ × X) :
    (E ⇗ A).rel i x ↔ ∃ B, x.1 = A ⇘ B ∧ E.rel i (B, x.2) := by
  sorry

theorem scoderiv_rel {X : Type _} {α β : TypeIndex} (E : Enumeration (β ↝ ⊥ × X)) (h : β < α)
    (i : κ) (x : α ↝ ⊥ × X) :
    (E ↗ h).rel i x ↔ ∃ B, x.1 = B ↗ h ∧ E.rel i (B, x.2) := by
  sorry

theorem eq_of_scoderiv_mem {X : Type _} {α β γ : TypeIndex} (E : Enumeration (β ↝ ⊥ × X))
    (h : β < α) (h' : γ < α)
    (i : κ) (A : γ ↝ ⊥) (x : X) (h : (E ↗ h).rel i ⟨A ↗ h', x⟩) :
    β = γ := by
  sorry

instance (X : Type u) (α : TypeIndex) :
    BotDerivative (Enumeration (α ↝ ⊥ × X)) (Enumeration X) α where
  botDeriv E A := E.invImage (λ x ↦ (A, x)) (Prod.mk_right_injective A)
  botSderiv E := E.invImage (λ x ↦ (Path.nil ↘., x)) (Prod.mk_right_injective (Path.nil ↘.))
  botDeriv_single E h := by
    cases α using WithBot.recBotCoe with
    | bot => cases lt_irrefl ⊥ h
    | coe => rfl

theorem derivBot_rel {X : Type _} {α : TypeIndex} (E : Enumeration (α ↝ ⊥ × X)) (A : α ↝ ⊥)
    (i : κ) (x : X) :
    (E ⇘. A).rel i x ↔ E.rel i (A, x) := by
  sorry

@[simp]
theorem mem_path_iff {X : Type _} {α : TypeIndex} (E : Enumeration (α ↝ ⊥ × X))
    (A : α ↝ ⊥) (x : X) :
    (A, x) ∈ E ↔ x ∈ E ⇘. A := by
  sorry

theorem mulAction_aux {X : Type _} {α : TypeIndex} [MulAction BasePerm X] (π : StrPerm α) :
    Function.Injective (λ x : α ↝ ⊥ × X ↦ (x.1, (π x.1)⁻¹ • x.2)) := by
  sorry

instance {X : Type _} {α : TypeIndex} [MulAction BasePerm X] :
    SMul (StrPerm α) (Enumeration (α ↝ ⊥ × X)) where
  smul π E := E.invImage (λ x ↦ (x.1, (π x.1)⁻¹ • x.2)) (mulAction_aux π)

@[simp]
theorem smulPath_rel {X : Type _} {α : TypeIndex} [MulAction BasePerm X]
    (π : StrPerm α) (E : Enumeration (α ↝ ⊥ × X)) (i : κ) (x : α ↝ ⊥ × X) :
    (π • E).rel i x ↔ E.rel i (x.1, (π x.1)⁻¹ • x.2) := by
  sorry

instance {X : Type _} {α : TypeIndex} [MulAction BasePerm X] :
    MulAction (StrPerm α) (Enumeration (α ↝ ⊥ × X)) where
  one_smul E := by
    ext i x
    · rfl
    · rw [smulPath_rel, Tree.one_apply, inv_one, one_smul]
  mul_smul π₁ π₂ E := by
    ext i x
    · rfl
    · rw [smulPath_rel, smulPath_rel, smulPath_rel, Tree.mul_apply, mul_inv_rev, mul_smul]

theorem smul_eq_smul_of_forall_smul_eq {X : Type _} {α : TypeIndex} [MulAction BasePerm X]
    {π₁ π₂ : StrPerm α} {E : Enumeration (α ↝ ⊥ × X)}
    (h : ∀ A : α ↝ ⊥, ∀ x : X, (A, x) ∈ E → π₁ A • x = π₂ A • x) :
    π₁ • E = π₂ • E := by
  sorry

theorem smul_eq_iff {X : Type _} {α : TypeIndex} [MulAction BasePerm X]
    (π : StrPerm α) (E : Enumeration (α ↝ ⊥ × X)) :
    π • E = E ↔ ∀ A : α ↝ ⊥, ∀ x : X, (A, x) ∈ E → π A • x = x := by
  sorry

end Enumeration

end ConNF
