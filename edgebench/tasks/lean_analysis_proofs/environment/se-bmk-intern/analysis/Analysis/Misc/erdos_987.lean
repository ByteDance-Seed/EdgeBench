import Mathlib

/-! A solution to Erdos problem \#987.  It is convenient to rephrase things using
elements $$z_j = e(x_j)$$ on the unit circle, and to index the sequence starting from 0
rather than 1, for greater compatibility with Mathlib.

The proof follows the second proof given in https://www.erdosproblems.com/987
 -/

open Filter Complex Finset

theorem Erdos_987 (z: ℕ → Circle) :
  atTop.limsup (fun k:ℕ ↦ atTop.limsup (fun n:ℕ ↦ (‖∑ j ∈ range n, ((z j)^k:ℂ)‖:EReal) )) = ⊤ := by
  sorry
