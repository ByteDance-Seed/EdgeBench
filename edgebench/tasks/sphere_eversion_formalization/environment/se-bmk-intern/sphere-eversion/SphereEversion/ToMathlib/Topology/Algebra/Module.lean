import Mathlib.Topology.Algebra.Module.Equiv

namespace ContinuousLinearMap

variable {R₁ M₁ M₂ M₃ : Type*} [Semiring R₁]

variable [TopologicalSpace M₁] [AddCommMonoid M₁]
  [TopologicalSpace M₂] [AddCommMonoid M₂]
  [TopologicalSpace M₃] [AddCommMonoid M₃]
  [Module R₁ M₁] [Module R₁ M₂] [Module R₁ M₃]

theorem fst_prod_zero_add_zero_prod_snd [ContinuousAdd M₁] [ContinuousAdd M₂] :
    (ContinuousLinearMap.fst R₁ M₁ M₂).prod 0 +
        ContinuousLinearMap.prod 0 (ContinuousLinearMap.snd R₁ M₁ M₂) =
      ContinuousLinearMap.id R₁ (M₁ × M₂) := by
  sorry

end ContinuousLinearMap

variable {R₁ R₂ R₃ : Type*} [Semiring R₁] [Semiring R₂] [Semiring R₃]
  {σ₁₂ : R₁ →+* R₂} {σ₂₁ : R₂ →+* R₁} [RingHomInvPair σ₁₂ σ₂₁] [RingHomInvPair σ₂₁ σ₁₂]
  {σ₂₃ : R₂ →+* R₃} {σ₃₂ : R₃ →+* R₂} [RingHomInvPair σ₂₃ σ₃₂] [RingHomInvPair σ₃₂ σ₂₃]
  {σ₁₃ : R₁ →+* R₃} {σ₃₁ : R₃ →+* R₁} [RingHomInvPair σ₁₃ σ₃₁] [RingHomInvPair σ₃₁ σ₁₃]
  [RingHomCompTriple σ₁₂ σ₂₃ σ₁₃] [RingHomCompTriple σ₃₂ σ₂₁ σ₃₁]
  {M₁ : Type*} [TopologicalSpace M₁] [AddCommMonoid M₁]
  {M'₁ : Type*} [TopologicalSpace M'₁] [AddCommMonoid M'₁]
  {M₂ : Type*} [TopologicalSpace M₂] [AddCommMonoid M₂]
  {M₃ : Type*} [TopologicalSpace M₃] [AddCommMonoid M₃]
  [Module R₁ M₁] [Module R₁ M'₁] [Module R₂ M₂] [Module R₃ M₃]

section

end

namespace ContinuousLinearEquiv

theorem cancel_right {f f' : M₂ →SL[σ₂₃] M₃} {e : M₁ ≃SL[σ₁₂] M₂} :
    f.comp (e : M₁ →SL[σ₁₂] M₂) = f'.comp (e : M₁ →SL[σ₁₂] M₂) ↔ f = f' := by
  sorry

theorem cancel_left {e : M₂ ≃SL[σ₂₃] M₃} {f f' : M₁ →SL[σ₁₂] M₂} :
    (e : M₂ →SL[σ₂₃] M₃).comp f = (e : M₂ →SL[σ₂₃] M₃).comp f' ↔ f = f' := by
  sorry

end ContinuousLinearEquiv
