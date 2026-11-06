import Mathlib.Data.Nat.Notation
import Mathlib.Logic.Function.Basic
import Mathlib.Tactic.Choose

-- The next lemma won't be used, it's a warming up exercise for the one below.
-- It could go to mathlib.
theorem exists_by_induction {α : Type*} {P : ℕ → α → Prop} (h₀ : ∃ a, P 0 a)
    (ih : ∀ n a, P n a → ∃ a', P (n + 1) a') : ∃ f : ℕ → α, ∀ n, P n (f n) := by
  sorry

-- We make `P` and `Q` explicit to help the elaborator when applying the lemma
-- (elab_as_eliminator isn't enough).

