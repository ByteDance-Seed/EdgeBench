import ConNF.Model.Externalise

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

variable [Params.{u}] {β γ : Λ} {hγ : (γ : TypeIndex) < β}

namespace Support

variable [Level] [LtLevel β]

theorem not_mem_strong_botDeriv (S : Support γ) (N : NearLitter) :
    N ∉ ((S ↗ hγ).strong ⇘. (Path.nil ↘.))ᴺ := by
  sorry

theorem raise_preStrong' (S : Support α) (hS : S.Strong) (T : Support γ) (ρ : AllPerm β)
    (hγ : (γ : TypeIndex) < β) :
    (S + (ρᵁ • ((T ↗ hγ).strong +
      (S ↘ LtLevel.elim + (T ↗ hγ).strong).interferenceSupport)) ↗ LtLevel.elim).PreStrong := by
  sorry

theorem raise_closed' (S : Support α) (hS : S.Strong) (T : Support γ) (ρ : AllPerm β)
    (hγ : (γ : TypeIndex) < β)
    (hρ : ρᵁ • (S ↘ LtLevel.elim : Support β) = S ↘ LtLevel.elim) :
    (S + (ρᵁ • ((T ↗ hγ).strong +
      (S ↘ LtLevel.elim + (T ↗ hγ).strong).interferenceSupport)) ↗ LtLevel.elim).Closed := by
  sorry

theorem raise_strong' (S : Support α) (hS : S.Strong) (T : Support γ) (ρ : AllPerm β)
    (hγ : (γ : TypeIndex) < β)
    (hρ : ρᵁ • (S ↘ LtLevel.elim : Support β) = S ↘ LtLevel.elim) :
    (S + (ρᵁ • ((T ↗ hγ).strong +
      (S ↘ LtLevel.elim + (T ↗ hγ).strong).interferenceSupport)) ↗ LtLevel.elim).Strong := by
  sorry

theorem convAtoms_injective_of_fixes {S : Support α} {T : Support γ}
    {ρ₁ ρ₂ : AllPerm β} {hγ : (γ : TypeIndex) < β}
    (hρ₁ : ρ₁ᵁ • (S ↘ LtLevel.elim : Support β) = S ↘ LtLevel.elim)
    (hρ₂ : ρ₂ᵁ • (S ↘ LtLevel.elim : Support β) = S ↘ LtLevel.elim)
    (A : ↑α ↝ ⊥) :
    (convAtoms
      (S + (ρ₁ᵁ • ((T ↗ hγ).strong + (S ↘ LtLevel.elim + (T ↗ hγ).strong).interferenceSupport)) ↗
        LtLevel.elim)
      (S + (ρ₂ᵁ • ((T ↗ hγ).strong + (S ↘ LtLevel.elim + (T ↗ hγ).strong).interferenceSupport)) ↗
        LtLevel.elim) A).Injective := by
  sorry

theorem atomMemRel_le_of_fixes {S : Support α} {T : Support γ}
    {ρ₁ ρ₂ : AllPerm β} {hγ : (γ : TypeIndex) < β}
    (hρ₁ : ρ₁ᵁ • (S ↘ LtLevel.elim : Support β) = S ↘ LtLevel.elim)
    (hρ₂ : ρ₂ᵁ • (S ↘ LtLevel.elim : Support β) = S ↘ LtLevel.elim)
    (A : ↑α ↝ ⊥) :
    atomMemRel (S + (ρ₁ᵁ • ((T ↗ hγ).strong +
      (S ↘ LtLevel.elim + (T ↗ hγ).strong).interferenceSupport)) ↗ LtLevel.elim) A ≤
    atomMemRel (S + (ρ₂ᵁ • ((T ↗ hγ).strong +
      (S ↘ LtLevel.elim + (T ↗ hγ).strong).interferenceSupport)) ↗ LtLevel.elim) A := by
  sorry

theorem convNearLitters_cases {S : Support α} {T : Support γ}
    {ρ₁ ρ₂ : AllPerm β} {hγ : (γ : TypeIndex) < β}
    {A : α ↝ ⊥} {N₁ N₂ : NearLitter} :
  convNearLitters
    (S + (ρ₁ᵁ • ((T ↗ hγ).strong +
      (S ↘ LtLevel.elim + (T ↗ hγ).strong).interferenceSupport)) ↗ LtLevel.elim)
    (S + (ρ₂ᵁ • ((T ↗ hγ).strong +
      (S ↘ LtLevel.elim + (T ↗ hγ).strong).interferenceSupport)) ↗ LtLevel.elim) A N₁ N₂ →
    N₁ = N₂ ∧ N₁ ∈ (S ⇘. A)ᴺ ∨
    ∃ B : β ↝ ⊥, A = B ↗ LtLevel.elim ∧ (ρ₁ᵁ B)⁻¹ • N₁ = (ρ₂ᵁ B)⁻¹ • N₂ ∧
      (ρ₁ᵁ B)⁻¹ • N₁ ∈ (((T ↗ hγ).strong +
        (S ↘ LtLevel.elim + (T ↗ hγ).strong).interferenceSupport) ⇘. B)ᴺ := by
  sorry

theorem inflexible_of_inflexible_of_fixes {S : Support α} {T : Support γ}
    {ρ₁ ρ₂ : AllPerm β} {hγ : (γ : TypeIndex) < β}
    (hρ₁ : ρ₁ᵁ • (S ↘ LtLevel.elim : Support β) = S ↘ LtLevel.elim)
    (hρ₂ : ρ₂ᵁ • (S ↘ LtLevel.elim : Support β) = S ↘ LtLevel.elim)
    {A : α ↝ ⊥} {N₁ N₂ : NearLitter} :
    convNearLitters
      (S + (ρ₁ᵁ • ((T ↗ hγ).strong +
        (S ↘ LtLevel.elim + (T ↗ hγ).strong).interferenceSupport)) ↗ LtLevel.elim)
      (S + (ρ₂ᵁ • ((T ↗ hγ).strong +
        (S ↘ LtLevel.elim + (T ↗ hγ).strong).interferenceSupport)) ↗ LtLevel.elim) A N₁ N₂ →
      ∀ (P : InflexiblePath ↑α) (t : Tangle P.δ), A = P.A ↘ P.hε ↘. → N₁ᴸ = fuzz P.hδε t →
      ∃ ρ : AllPerm P.δ, N₂ᴸ = fuzz P.hδε (ρ • t) := by
  sorry

theorem atoms_of_inflexible_of_fixes {S : Support α} (hS : S.Strong) {T : Support γ}
    {ρ₁ ρ₂ : AllPerm β} {hγ : (γ : TypeIndex) < β}
    (hρ₁ : ρ₁ᵁ • (S ↘ LtLevel.elim : Support β) = S ↘ LtLevel.elim)
    (hρ₂ : ρ₂ᵁ • (S ↘ LtLevel.elim : Support β) = S ↘ LtLevel.elim)
    (A : α ↝ ⊥) (N₁ N₂ : NearLitter) (P : InflexiblePath ↑α) (t : Tangle P.δ) (ρ : AllPerm P.δ) :
    A = P.A ↘ P.hε ↘. → N₁ᴸ = fuzz P.hδε t → N₂ᴸ = fuzz P.hδε (ρ • t) →
    convNearLitters
      (S + (ρ₁ᵁ • ((T ↗ hγ).strong +
        (S ↘ LtLevel.elim + (T ↗ hγ).strong).interferenceSupport)) ↗ LtLevel.elim)
      (S + (ρ₂ᵁ • ((T ↗ hγ).strong +
        (S ↘ LtLevel.elim + (T ↗ hγ).strong).interferenceSupport)) ↗ LtLevel.elim) A N₁ N₂ →
    ∀ (B : P.δ ↝ ⊥), ∀ a ∈ (t.support ⇘. B)ᴬ, ∀ (i : κ),
      ((S + (ρ₁ᵁ • ((T ↗ hγ).strong + (S ↘ LtLevel.elim + (T ↗ hγ).strong).interferenceSupport)) ↗
        LtLevel.elim) ⇘. (P.A ↘ P.hδ ⇘ B))ᴬ.rel i a →
      ((S + (ρ₂ᵁ • ((T ↗ hγ).strong + (S ↘ LtLevel.elim + (T ↗ hγ).strong).interferenceSupport)) ↗
        LtLevel.elim) ⇘. (P.A ↘ P.hδ ⇘ B))ᴬ.rel i (ρᵁ B • a) := by
  sorry

theorem nearLitters_of_inflexible_of_fixes {S : Support α} (hS : S.Strong) {T : Support γ}
    {ρ₁ ρ₂ : AllPerm β} {hγ : (γ : TypeIndex) < β}
    (hρ₁ : ρ₁ᵁ • (S ↘ LtLevel.elim : Support β) = S ↘ LtLevel.elim)
    (hρ₂ : ρ₂ᵁ • (S ↘ LtLevel.elim : Support β) = S ↘ LtLevel.elim)
    (A : α ↝ ⊥) (N₁ N₂ : NearLitter) (P : InflexiblePath ↑α) (t : Tangle P.δ) (ρ : AllPerm P.δ) :
    A = P.A ↘ P.hε ↘. → N₁ᴸ = fuzz P.hδε t → N₂ᴸ = fuzz P.hδε (ρ • t) →
    convNearLitters
      (S + (ρ₁ᵁ • ((T ↗ hγ).strong +
        (S ↘ LtLevel.elim + (T ↗ hγ).strong).interferenceSupport)) ↗ LtLevel.elim)
      (S + (ρ₂ᵁ • ((T ↗ hγ).strong +
        (S ↘ LtLevel.elim + (T ↗ hγ).strong).interferenceSupport)) ↗ LtLevel.elim) A N₁ N₂ →
    ∀ (B : P.δ ↝ ⊥), ∀ N ∈ (t.support ⇘. B)ᴺ, ∀ (i : κ),
      ((S + (ρ₁ᵁ • ((T ↗ hγ).strong + (S ↘ LtLevel.elim + (T ↗ hγ).strong).interferenceSupport)) ↗
        LtLevel.elim) ⇘. (P.A ↘ P.hδ ⇘ B))ᴺ.rel i N →
      ((S + (ρ₂ᵁ • ((T ↗ hγ).strong + (S ↘ LtLevel.elim + (T ↗ hγ).strong).interferenceSupport)) ↗
        LtLevel.elim) ⇘. (P.A ↘ P.hδ ⇘ B))ᴺ.rel i (ρᵁ B • N) := by
  sorry

theorem litter_eq_of_flexible_of_fixes {S : Support α} {T : Support γ}
    {ρ₁ ρ₂ : AllPerm β} {hγ : (γ : TypeIndex) < β}
    (hρ₁ : ρ₁ᵁ • (S ↘ LtLevel.elim : Support β) = S ↘ LtLevel.elim)
    (hρ₂ : ρ₂ᵁ • (S ↘ LtLevel.elim : Support β) = S ↘ LtLevel.elim)
    {A : ↑α ↝ ⊥} {N₁ N₂ N₃ N₄ : NearLitter} :
    convNearLitters
      (S + (ρ₁ᵁ • ((T ↗ hγ).strong +
        (S ↘ LtLevel.elim + (T ↗ hγ).strong).interferenceSupport)) ↗ LtLevel.elim)
      (S + (ρ₂ᵁ • ((T ↗ hγ).strong +
        (S ↘ LtLevel.elim + (T ↗ hγ).strong).interferenceSupport)) ↗ LtLevel.elim) A N₁ N₂ →
    convNearLitters
      (S + (ρ₁ᵁ • ((T ↗ hγ).strong +
        (S ↘ LtLevel.elim + (T ↗ hγ).strong).interferenceSupport)) ↗ LtLevel.elim)
      (S + (ρ₂ᵁ • ((T ↗ hγ).strong +
        (S ↘ LtLevel.elim + (T ↗ hγ).strong).interferenceSupport)) ↗ LtLevel.elim) A N₃ N₄ →
      ¬Inflexible A N₁ᴸ → ¬Inflexible A N₂ᴸ → ¬Inflexible A N₃ᴸ → ¬Inflexible A N₄ᴸ →
      N₁ᴸ = N₃ᴸ → N₂ᴸ = N₄ᴸ := by
  sorry

theorem sameSpecLe_of_fixes (S : Support α) (hS : S.Strong) (T : Support γ) (ρ₁ ρ₂ : AllPerm β)
    (hγ : (γ : TypeIndex) < β)
    (hρ₁ : ρ₁ᵁ • (S ↘ LtLevel.elim : Support β) = S ↘ LtLevel.elim)
    (hρ₂ : ρ₂ᵁ • (S ↘ LtLevel.elim : Support β) = S ↘ LtLevel.elim) :
    SameSpecLE
    (S + (ρ₁ᵁ • ((T ↗ hγ).strong +
      (S ↘ LtLevel.elim + (T ↗ hγ).strong).interferenceSupport)) ↗ LtLevel.elim)
    (S + (ρ₂ᵁ • ((T ↗ hγ).strong +
      (S ↘ LtLevel.elim + (T ↗ hγ).strong).interferenceSupport)) ↗ LtLevel.elim) := by
  sorry

theorem spec_same_of_fixes (S : Support α) (hS : S.Strong) (T : Support γ) (ρ : AllPerm β)
    (hρ : ρᵁ • (S ↘ LtLevel.elim : Support β) = S ↘ LtLevel.elim) :
    (S + ((T ↗ hγ).strong +
      (S ↘ LtLevel.elim + (T ↗ hγ).strong).interferenceSupport) ↗ LtLevel.elim).spec =
    (S + (ρᵁ • ((T ↗ hγ).strong +
      (S ↘ LtLevel.elim + (T ↗ hγ).strong).interferenceSupport)) ↗ LtLevel.elim).spec := by
  sorry

theorem exists_allowable_of_fixes (S : Support α) (hS : S.Strong) (T : Support γ) (ρ : AllPerm β)
    (hγ : (γ : TypeIndex) < β)
    (hρ : ρᵁ • (S ↘ LtLevel.elim : Support β) = S ↘ LtLevel.elim) :
    ∃ ρ' : AllPerm α, ρ'ᵁ • S = S ∧ ρ'ᵁ ↘ LtLevel.elim ↘ hγ • T = ρᵁ ↘ hγ • T := by
  sorry

end Support

end ConNF
