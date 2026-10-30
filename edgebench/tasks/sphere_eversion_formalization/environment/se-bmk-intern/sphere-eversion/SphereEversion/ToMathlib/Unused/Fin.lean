import Mathlib.Data.Fin.SuccPred

-- not directly used
theorem Fin.coe_succ_le_iff_le {n : ℕ} {j k : Fin n} : j.castSucc ≤ k.castSucc ↔ j ≤ k := by
  sorry

-- not directly used
theorem Fin.coe_lt_succ {n : ℕ} (k : Fin n) : k.castSucc < k.succ := by
  sorry
