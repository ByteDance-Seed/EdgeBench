import Mathlib.Tactic

/-!
# Analysis I, Appendix A.3: The structure of proofs

Some examples of proofs

-/

/-- Proposition A.3.1 -/
example {A B C D: Prop} (hAC: A → C) (hCD: C → D) (hDB: D → B): A → B := by
  sorry

/-- Proposition A.3.2 -/
example {x:ℝ} : x = Real.pi → Real.sin (x/2) + 1 = 2 := by
  sorry

/-- Proposition A.3.1, alternate proof -/
example {A B C D: Prop} (hAC: A → C) (hCD: C → D) (hDB: D → B): A → B := by
  sorry

/-- Proposition A.3.2, alternate proof -/
example {x:ℝ} : x = Real.pi → Real.sin (x/2) + 1 = 2 := by
  sorry

/-- Proposition A.3.3 -/
example {r:ℝ} (h: 0 < r) (h': r < 1) : Summable (fun n:ℕ ↦ n * r^n) := by
  sorry

/-- Proposition A.3.1, third proof -/
example {A B C D: Prop} (hAC: A → C) (hCD: C → D) (hDB: D → B): A → B := by
  sorry

/-- Proposition A.3.4 -/
example {A B C D E F G H I:Prop} (hAE: A → E) (hEB: E ∧ B → F) (hADG : A → G → D) (hHI: H ∨ I) (hFHC : F ∧ H → C) (hAHG : A ∧ H → G) (hIG: I → G) (hIGC: G → C) : A ∧ B → C ∧ D := by
  sorry

/-- Proposition A.3.5 -/
example {A B C D:Prop} (hBC: B → C) (hAD: A → D) (hCD: D → ¬ C) : A → ¬ B := by
  sorry
