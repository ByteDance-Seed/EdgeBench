module

public import Mathlib.Data.Real.ConjExponents

public section

open scoped ENNReal

variable {p q : ℝ≥0∞} (h : p.HolderConjugate q)
include h

-- Upstreaming status: seems useful to have and good to go

protected lemma ENNReal.HolderConjugate.toReal_of_ne_top (hp : p ≠ ∞) (hq : q ≠ ∞) :
    p.toReal.HolderConjugate q.toReal := by
  sorry
