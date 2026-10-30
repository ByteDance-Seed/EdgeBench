module

public import Mathlib.Algebra.BigOperators.Fin

public section

open Finset

variable {M : Type*} [AddCommMonoid M] {n : ℕ}

-- TODO: Rename `Fin.sum_univ_castSucc` to `Fin.sum_univ_eq_castSucc`

