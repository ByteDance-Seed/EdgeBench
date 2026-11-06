import ConNF.Background.Cardinal
import ConNF.Background.Rel

noncomputable section
open Cardinal

namespace Rel

variable {α β : Type _}

/-- TODO: Fix the paper version of this. -/
structure OrbitRestriction (s : Set α) (β : Type _) where
  sandbox : Set α
  sandbox_disjoint : Disjoint s sandbox
  categorise : α → β
  catPerm : Equiv.Perm β
  le_card_categorise (b : β) : max ℵ₀ #s ≤ #(sandbox ∩ categorise ⁻¹' {b} : Set α)

theorem le_card_categorise {r : Rel α α} (R : OrbitRestriction (r.dom ∪ r.codom) β) (b : β) :
    #((r.dom ∪ r.codom : Set α) × ℕ) ≤ #(R.sandbox ∩ R.categorise ⁻¹' {b} : Set α) := by
  sorry

def catInj {r : Rel α α} (R : OrbitRestriction (r.dom ∪ r.codom) β) (b : β) :
    (r.dom ∪ r.codom : Set α) × ℕ ↪ (R.sandbox ∩ R.categorise ⁻¹' {b} : Set α) :=
  Nonempty.some (le_card_categorise R b)

@[simp]
theorem catInj_inj {r : Rel α α} {R : OrbitRestriction (r.dom ∪ r.codom) β}
    {b₁ b₂ : β} {a₁ a₂ : α} {h₁ : a₁ ∈ r.dom ∪ r.codom} {h₂ : a₂ ∈ r.dom ∪ r.codom} {n₁ n₂ : ℕ} :
    (catInj R b₁ (⟨a₁, h₁⟩, n₁) : α) = catInj R b₂ (⟨a₂, h₂⟩, n₂) ↔
      b₁ = b₂ ∧ a₁ = a₂ ∧ n₁ = n₂ := by
  sorry

inductive newOrbits {r : Rel α α} (R : OrbitRestriction (r.dom ∪ r.codom) β) : Rel α α
  | left (a : α) (had : a ∈ r.dom) (hac : a ∉ r.codom) :
      newOrbits R (catInj R (R.catPerm.symm (R.categorise a)) (⟨a, Or.inl had⟩, 0)) a
  | leftStep (n : ℕ) (a : α) (had : a ∈ r.dom) (hac : a ∉ r.codom) :
      newOrbits R
        (catInj R (R.catPerm.symm^[n + 2] (R.categorise a)) (⟨a, Or.inl had⟩, n + 1))
        (catInj R (R.catPerm.symm^[n + 1] (R.categorise a)) (⟨a, Or.inl had⟩, n))
  | right (a : α) (had : a ∉ r.dom) (hac : a ∈ r.codom) :
      newOrbits R a (catInj R (R.catPerm (R.categorise a)) (⟨a, Or.inr hac⟩, 0))
  | rightStep (n : ℕ) (a : α) (had : a ∉ r.dom) (hac : a ∈ r.codom) :
      newOrbits R
        (catInj R (R.catPerm^[n + 1] (R.categorise a)) (⟨a, Or.inr hac⟩, n))
        (catInj R (R.catPerm^[n + 2] (R.categorise a)) (⟨a, Or.inr hac⟩, n + 1))

def permutativeExtension (r : Rel α α) (R : OrbitRestriction (r.dom ∪ r.codom) β) :
    Rel α α :=
  r ⊔ newOrbits R

def permutativeExtension' (r : Rel α α) (hr : r.OneOne) (s : Set α)
    (hs₁ : s.Infinite) (hs₂ : #r.dom ≤ #s) (hs₃ : Disjoint (r.dom ∪ r.codom) s) :
    Rel α α :=
  r.permutativeExtension {
    sandbox := s
    sandbox_disjoint := hs₃
    categorise := λ _ ↦ Unit.unit
    catPerm := 1
    le_card_categorise := by
      intro
      simp only [Set.mem_singleton_iff, Set.preimage_const_of_mem, Set.inter_univ, max_le_iff,
        le_refl, and_true]
      rw [← Set.infinite_coe_iff, Cardinal.infinite_iff] at hs₁
      refine ⟨hs₁, ?_⟩
      apply (mk_union_le _ _).trans
      apply add_le_of_le hs₁ hs₂
      exact (card_codom_le_of_coinjective hr.toCoinjective).trans hs₂
  }

end Rel
