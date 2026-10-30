import ConNF.Levels.Path

/-!
# Trees

In this file, we define the notion of a tree on a type.

## Main declarations

* `ConNF.Tree`: The type family of trees parametrised by a given type.
-/

universe u

open Cardinal

namespace ConNF

variable [Params.{u}] {X Y : Type _} {α β γ : TypeIndex}

/-- An `α`-tree of `X` associates an object of type `X` to each path `α ↝ ⊥`. -/
def Tree (X : Type _) (α : TypeIndex) :=
  (α ↝ ⊥) → X

namespace Tree

instance : Derivative (Tree X α) (Tree X β) α β where
  deriv T A B := T (A ⇘ B)

instance : BotDerivative (Tree X α) X α where
  botDeriv T A := T A
  botSderiv T := T <| Path.nil ↘.
  botDeriv_single T h := by
    cases α using WithBot.recBotCoe with
      | bot => cases lt_irrefl ⊥ h
      | coe => rfl

@[simp]
theorem botDeriv_eq (T : Tree X α) (A : α ↝ ⊥) :
    T ⇘. A = T A := by
  sorry

theorem botSderiv_eq (T : Tree X α) :
    T ↘. = T (Path.nil ↘.) := by
  sorry

/-- The group structure on the type of `α`-trees of `X` is given by "branchwise" multiplication,
given by `Pi.group`. -/
instance group [Group X] : Group (Tree X α) :=
  Pi.group

@[simp]
theorem one_apply [Group X] (A : α ↝ ⊥) :
    (1 : Tree X α) A = 1 := by
  sorry

@[simp]
theorem one_deriv [Group X] (A : α ↝ β) :
    (1 : Tree X α) ⇘ A = 1 := by
  sorry

@[simp]
theorem one_sderiv [Group X] (h : β < α) :
    (1 : Tree X α) ↘ h = 1 := by
  sorry

@[simp]
theorem one_sderivBot [Group X] :
    (1 : Tree X α) ↘. = 1 := by
  sorry

@[simp]
theorem mul_apply [Group X] (T₁ T₂ : Tree X α) (A : α ↝ ⊥) :
    (T₁ * T₂) A = T₁ A * T₂ A := by
  sorry

@[simp]
theorem mul_deriv [Group X] (T₁ T₂ : Tree X α) (A : α ↝ β) :
    (T₁ * T₂) ⇘ A = T₁ ⇘ A * T₂ ⇘ A := by
  sorry

@[simp]
theorem mul_sderiv [Group X] (T₁ T₂ : Tree X α) (h : β < α) :
    (T₁ * T₂) ↘ h = T₁ ↘ h * T₂ ↘ h := by
  sorry

@[simp]
theorem mul_sderivBot [Group X] (T₁ T₂ : Tree X α) :
    (T₁ * T₂) ↘. = T₁ ↘. * T₂ ↘. := by
  sorry

@[simp]
theorem npow_apply [Group X] (T : Tree X α) (A : α ↝ ⊥) (n : ℕ) :
    (T ^ n) A = (T A) ^ n := by
  sorry

/-- The partial order on the type of `α`-trees of `X` is given by "branchwise" comparison. -/
instance partialOrder [PartialOrder X] : PartialOrder (Tree X α) :=
  Pi.partialOrder

theorem le_iff [PartialOrder X] (T₁ T₂ : Tree X α) :
    T₁ ≤ T₂ ↔ ∀ A, T₁ A ≤ T₂ A := by
  sorry

end Tree

/-!
## Cardinality bounds on trees
-/

theorem card_tree_eq (h : #X = #μ) : #(Tree X α) = #μ := by
  sorry

end ConNF
