import ConNF.Background.Cardinal
import ConNF.Background.Rel

universe u

noncomputable section
open Cardinal Relation

namespace Rel

variable {α : Type u} {r : Rel α α} {κ : Cardinal}

def reflTransGen₁ (r : Rel α α) (s : Set α) : Set α :=
  ⋃ x ∈ s, {y | r y x}

def reflTransGenₙ (r : Rel α α) : ℕ → Set α → Set α :=
  Nat.iterate (reflTransGen₁ r)

def reflTransGen' (r : Rel α α) : Rel α α :=
  λ x y ↦ x ∈ ⋃ n, {x | reflTransGenₙ r n {y} x}

theorem reflTransGen'_iff (r : Rel α α) (x y : α) :
    reflTransGen' r x y ↔ ReflTransGen r x y := by
  sorry

theorem card_transGen_lt (hr : ∀ y, #{x | r x y} < κ) (hκ₁ : κ.IsRegular) (hκ₂ : ℵ₀ < κ) (y : α) :
    #{x | TransGen r x y} < κ := by
  sorry

theorem card_transGen_le (hr : ∀ y, #{x | r x y} ≤ κ) (hκ : ℵ₀ ≤ κ) (y : α) :
    #{x | TransGen r x y} ≤ κ := by
  sorry

end Rel
