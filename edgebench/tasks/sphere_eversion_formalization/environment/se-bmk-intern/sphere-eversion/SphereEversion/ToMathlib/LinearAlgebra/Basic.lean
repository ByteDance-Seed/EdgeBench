import Mathlib.Algebra.Module.Submodule.Ker
import Mathlib.LinearAlgebra.Span.Defs

/-! Note: some results should go to `LinearAlgebra.Span`. -/

open Submodule Function

section

variable {R : Type*} {R₂ : Type*} {M : Type*} {M₂ : Type*} [Semiring R] [Semiring R₂]
  [AddCommMonoid M] [AddCommMonoid M₂] {σ₁₂ : R →+* R₂} [Module R M] [Module R₂ M₂]

theorem Submodule.sup_eq_span_union (s t : Submodule R M) : s ⊔ t = span R (s ∪ t) := by
  sorry

end

section

variable {R : Type*} {R₂ : Type*} {M : Type*} {M₂ : Type*} [Ring R] [Ring R₂] [AddCommGroup M]
  [AddCommGroup M₂] {σ₁₂ : R →+* R₂} [Module R M] [Module R₂ M₂] {p q : Submodule R M}
  [RingHomSurjective σ₁₂]

theorem LinearMap.injective_iff_of_direct_sum (f : M →ₛₗ[σ₁₂] M₂) (hpq : p ⊓ q = ⊥)
    (hpq' : p ⊔ q = ⊤) :
    Injective f ↔ Disjoint p (LinearMap.ker f) ∧ Disjoint q (LinearMap.ker f) ∧
      Disjoint (map f p) (map f q) := by
  sorry

end
