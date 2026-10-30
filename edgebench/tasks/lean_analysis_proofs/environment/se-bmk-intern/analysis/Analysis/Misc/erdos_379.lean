import Mathlib

/-! Formalizing a proof of Erdos problem \#379, arising from conversations between Stijn Cambie, Vjeko Kovac, and Terry Tao.  See the discussion at https://www.erdosproblems.com/forum/thread/379 -/

open Nat

noncomputable abbrev S (n:ℕ) : ℕ := sSup { r | ∀ k ∈ Finset.Ico 1 n, ∃ p, p.Prime ∧ p^r ∣ (n.choose k) }

/-- A positive resolution to Erdos problem \#379.-/
theorem erdos_379 : Filter.atTop.limsup (fun n ↦ (S n:ENat)) = ⊤ := by
  sorry
