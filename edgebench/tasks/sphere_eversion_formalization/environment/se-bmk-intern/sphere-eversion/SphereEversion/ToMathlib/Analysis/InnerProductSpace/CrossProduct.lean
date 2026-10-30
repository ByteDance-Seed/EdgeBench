/-
Copyright (c) 2022 Heather Macbeth. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Heather Macbeth

! This file was ported from Lean 3 source module to_mathlib.analysis.inner_product_space.cross_product
-/
import Mathlib.Analysis.InnerProductSpace.Dual
import Mathlib.Analysis.InnerProductSpace.Orientation
import Mathlib.LinearAlgebra.Alternating.Curry

/-! # The cross-product on an oriented real inner product space of dimension three -/

noncomputable section

open scoped RealInnerProductSpace

open Module

set_option synthInstance.checkSynthOrder false
attribute [local instance] FiniteDimensional.of_fact_finrank_eq_succ
set_option synthInstance.checkSynthOrder true

variable (E : Type*) [NormedAddCommGroup E] [InnerProductSpace ℝ E]

/-- The identification of a finite-dimensional inner product space with its algebraic dual. -/
private def to_dual [FiniteDimensional ℝ E] : E ≃ₗ[ℝ] E →ₗ[ℝ] ℝ :=
  (InnerProductSpace.toDual ℝ E).toLinearEquiv ≪≫ₗ LinearMap.toContinuousLinearMap.symm

namespace Orientation

variable {E}
variable [Fact (finrank ℝ E = 3)] (ω : Orientation ℝ E (Fin 3))

/-- Linear map from `E` to `E →ₗ[ℝ] E` constructed from a 3-form `Ω` on `E` and an identification of
`E` with its dual.  Effectively, the Hodge star operation.  (Under appropriate hypotheses it turns
out that the image of this map is in `𝔰𝔬(E)`, the skew-symmetric operators, which can be identified
with `Λ²E`.) -/
def crossProduct : E →ₗ[ℝ] E →ₗ[ℝ] E := by
  let z : AlternatingMap ℝ E ℝ (Fin 0) ≃ₗ[ℝ] ℝ :=
    AlternatingMap.constLinearEquivOfIsEmpty.symm
  let y : AlternatingMap ℝ E ℝ (Fin 1) →ₗ[ℝ] E →ₗ[ℝ] ℝ :=
    LinearMap.llcomp ℝ E (AlternatingMap ℝ E ℝ (Fin 0)) ℝ z ∘ₗ AlternatingMap.curryLeftLinearMap
  let y' : AlternatingMap ℝ E ℝ (Fin 1) →ₗ[ℝ] E :=
    (LinearMap.llcomp ℝ (AlternatingMap ℝ E ℝ (Fin 1)) (E →ₗ[ℝ] ℝ) E (to_dual E).symm) y
  let u : AlternatingMap ℝ E ℝ (Fin 2) →ₗ[ℝ] E →ₗ[ℝ] E :=
    LinearMap.llcomp ℝ E (AlternatingMap ℝ E ℝ (Fin 1)) _ y' ∘ₗ AlternatingMap.curryLeftLinearMap
  exact u ∘ₗ AlternatingMap.curryLeftLinearMap (n := 2) ω.volumeForm

local infixl:100 "×₃" => ω.crossProduct

/-- The map `crossProduct`, upgraded from linear to continuous-linear; useful for calculus. -/
def crossProduct' : E →L[ℝ] E →L[ℝ] E :=
  LinearMap.toContinuousLinearMap
    (↑(LinearMap.toContinuousLinearMap : (E →ₗ[ℝ] E) ≃ₗ[ℝ] E →L[ℝ] E) ∘ₗ ω.crossProduct)

@[simp]
theorem crossProduct'_apply (v : E) :
    ω.crossProduct' v = LinearMap.toContinuousLinearMap (ω.crossProduct v) := by
  sorry

end Orientation
