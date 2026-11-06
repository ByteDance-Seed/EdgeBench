module

public import Mathlib.LinearAlgebra.Quotient.Basic

public section

instance Submodule.Quotient.finite {R M : Type*} [Ring R] [AddCommGroup M] [Module R M] [Finite M]
    (S : Submodule R M) : Finite (M ⧸ S) := by
  cases nonempty_fintype M; infer_instance
