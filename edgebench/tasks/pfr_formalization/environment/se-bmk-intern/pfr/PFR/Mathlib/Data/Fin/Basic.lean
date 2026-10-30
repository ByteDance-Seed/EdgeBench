module

public import Mathlib.Data.Fin.Basic

public section

theorem Fin.cast_surjective {k l : ℕ} (h : k = l) : Function.Surjective (Fin.cast h) := by
  sorry

theorem Fin.forall_fin_three {p : Fin 3 → Prop} : (∀ i, p i) ↔ p 0 ∧ p 1 ∧ p 2 := by
  sorry
