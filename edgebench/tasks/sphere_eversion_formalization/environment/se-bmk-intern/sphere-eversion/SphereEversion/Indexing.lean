import Mathlib.Order.Interval.Finset.Fin
import Mathlib.Data.Fin.SuccPredOrder
import Mathlib.Data.Nat.SuccPred
import Mathlib.SetTheory.Cardinal.Basic
import Mathlib.Tactic.Cases
import SphereEversion.ToMathlib.Data.Nat.Basic
/-!
# Indexing types

This file introduces `IndexType : ℕ → Type` such that `IndexType 0 = ℕ` and
`IndexType (N+1) = Fin (N+1)`. Each `IndexType N` has a total order and and inductive principle
together with supporting lemmas.
-/

open Fin Set

/-- Our model indexing type depending on `n : ℕ` is `ℕ` if `n = 0` and `Fin n` otherwise -/
def IndexType (n : ℕ) : Type :=
  Nat.casesOn n ℕ fun k ↦ Fin <| k + 1

open Fin.NatCast in -- TODO: remove this, by making the cast explicit
def IndexType.fromNat : ∀ {N : ℕ}, ℕ → IndexType N
  | 0 => id
  | N + 1 => (Nat.cast : ℕ → Fin (N + 1))

def IndexType.toNat : ∀ {N}, IndexType N → ℕ
  | 0 => id
  | _ + 1 => Fin.val

@[simp]
theorem indexType_zero : IndexType 0 = ℕ := by
  sorry

set_option hygiene false in
run_cmd
  for n in [`LinearOrder, `LocallyFiniteOrder, `OrderBot, `Zero, `SuccOrder].map Lean.mkIdent do
  Lean.Elab.Command.elabCommand (← `(
    instance : ∀ n, $n (IndexType n)
    | 0 => inferInstanceAs ($n ℕ)
    | (N + 1) => inferInstanceAs ($n (Fin (N + 1)))
  ))

variable {n : ℕ}

theorem IndexType.not_lt_zero (j : IndexType n) : ¬j < 0 := by
  sorry

def IndexType.succ {N : ℕ} : IndexType N → IndexType N := Order.succ

theorem IndexType.succ_castSuccEmb (i : Fin n) :
    @IndexType.succ (n + 1) i.castSucc = i.succ := by
  sorry

theorem IndexType.succ_eq (i : IndexType n) : i.succ = i ↔ IsMax i := by
  sorry

theorem IndexType.le_max {i : IndexType n} (h : IsMax i) (j) : j ≤ i := by
  sorry

-- @[simp] can prove this
theorem IndexType.not_isMax (n : IndexType 0) : ¬IsMax n := by
  sorry

@[elab_as_elim]
theorem IndexType.induction {P : IndexType n → Prop} (h₀ : P 0)
    (ih : ∀ i, ¬IsMax i → P i → P i.succ) : ∀ i, P i := by
  sorry

-- We make `P` and `Q` explicit to help the elaborator when applying the lemma
-- (elab_as_eliminator isn't enough).

