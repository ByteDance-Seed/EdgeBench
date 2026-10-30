import Mathlib.Analysis.Normed.Module.Completion
import Mathlib.Analysis.SpecialFunctions.SmoothTransition
import SphereEversion.ToMathlib.Topology.Misc

noncomputable section

open Set Function Filter

open scoped Topology ContDiff

namespace Real

end Real

section Calculus

open ContinuousLinearMap

variable {𝕜 : Type*} [NontriviallyNormedField 𝕜] {E : Type*} [NormedAddCommGroup E]
  [NormedSpace 𝕜 E] {E₁ : Type*} [NormedAddCommGroup E₁] [NormedSpace 𝕜 E₁] {E₂ : Type*}
  [NormedAddCommGroup E₂] [NormedSpace 𝕜 E₂] {E' : Type*} [NormedAddCommGroup E']
  [NormedSpace 𝕜 E'] {F : Type*} [NormedAddCommGroup F] [NormedSpace 𝕜 F] {G : Type*}
  [NormedAddCommGroup G] [NormedSpace 𝕜 G] {n : WithTop ℕ∞}

theorem fderiv_prod_left {x₀ : E} {y₀ : F} :
    fderiv 𝕜 (fun x ↦ (x, y₀)) x₀ = ContinuousLinearMap.inl 𝕜 E F := by
  sorry

variable (𝕜)

/-- The first partial derivative of a binary function. -/
def partialFDerivFst {F : Type*} (φ : E → F → G) : E → F → E →L[𝕜] G := fun (e₀ : E) (f₀ : F) ↦
  fderiv 𝕜 (fun e ↦ φ e f₀) e₀

/-- The second partial derivative of a binary function. -/
def partialFDerivSnd {E : Type*} (φ : E → F → G) : E → F → F →L[𝕜] G := fun (e₀ : E) (f₀ : F) ↦
  fderiv 𝕜 (fun f ↦ φ e₀ f) f₀

@[inherit_doc] local notation "∂₁" => partialFDerivFst

@[inherit_doc] local notation "∂₂" => partialFDerivSnd

variable {𝕜}

theorem ContDiff.partial_fst {φ : E → F → G} {n : ℕ∞} (h : ContDiff 𝕜 n <| uncurry φ) (f₀ : F) :
    ContDiff 𝕜 n fun e ↦ φ e f₀ := by
  sorry

theorem ContDiff.partial_snd {φ : E → F → G} {n : ℕ∞} (h : ContDiff 𝕜 n <| uncurry φ) (e₀ : E) :
    ContDiff 𝕜 n fun f ↦ φ e₀ f := by
  sorry

/-- Precomposition by a continuous linear map as a continuous linear map between spaces of
continuous linear maps. -/
def ContinuousLinearMap.compRightL (φ : E →L[𝕜] F) : (F →L[𝕜] G) →L[𝕜] E →L[𝕜] G :=
  precomp G φ

/-- Postcomposition by a continuous linear map as a continuous linear map between spaces of
continuous linear maps. -/
def ContinuousLinearMap.compLeftL (φ : F →L[𝕜] G) : (E →L[𝕜] F) →L[𝕜] E →L[𝕜] G :=
  postcomp E φ

nonrec theorem Differentiable.fderiv_partial_fst {φ : E → F → G}
    (hF : Differentiable 𝕜 (uncurry φ)) :
    ↿(∂₁ 𝕜 φ) = precomp G (inl 𝕜 E F) ∘ (fderiv 𝕜 <| uncurry φ) := by
  sorry

nonrec theorem Differentiable.fderiv_partial_snd {φ : E → F → G}
    (hF : Differentiable 𝕜 (uncurry φ)) :
    ↿(∂₂ 𝕜 φ) = precomp G (inr 𝕜 E F) ∘ (fderiv 𝕜 <| uncurry φ) := by
  sorry

/-- The first partial derivative of `φ : 𝕜 → F → G` seen as a function from `𝕜 → F → G` -/
def partialDerivFst (φ : 𝕜 → F → G) : 𝕜 → F → G := fun k f ↦ ∂₁ 𝕜 φ k f 1

/-- The second partial derivative of `φ : E → 𝕜 → G` seen as a function from `E → 𝕜 → G` -/
def partialDerivSnd (φ : E → 𝕜 → G) : E → 𝕜 → G := fun e k ↦ ∂₂ 𝕜 φ e k 1

omit [NormedAddCommGroup F] [NormedSpace 𝕜 F] in

omit [NormedAddCommGroup F] [NormedSpace 𝕜 F] in
@[simp]
theorem partialFDerivFst_one (φ : 𝕜 → F → G) (k : 𝕜) (f : F) :
    ∂₁ 𝕜 φ k f 1 = partialDerivFst φ k f := by
  sorry

omit [NormedAddCommGroup E] [NormedSpace 𝕜 E] in

omit [NormedAddCommGroup E] [NormedSpace 𝕜 E] in

@[to_additive]
nonrec theorem WithTop.le_mul_self {α : Type*} [CommMonoid α] [PartialOrder α]
    [CanonicallyOrderedMul α] (n m : α) :
    (n : WithTop α) ≤ (m * n : α) := by
  sorry

@[to_additive]
nonrec theorem WithTop.le_self_mul {α : Type*} [CommMonoid α] [PartialOrder α]
    [CanonicallyOrderedMul α] (n m : α) :
    (n : WithTop α) ≤ (n * m : α) := by
  sorry

theorem ContDiff.contDiff_partial_fst_apply {φ : E → F → G} {n : ℕ}
    (hF : ContDiff 𝕜 (n + 1) (uncurry φ)) {x : E} : ContDiff 𝕜 n ↿fun x' y ↦ ∂₁ 𝕜 φ x' y x := by
  sorry

-- XXX: fix this!

theorem ContDiff.contDiff_partial_snd_apply {φ : E → F → G} {n : ℕ}
    (hF : ContDiff 𝕜 (n + 1) (uncurry φ)) {y : F} : ContDiff 𝕜 n ↿fun x y' ↦ ∂₂ 𝕜 φ x y' y := by
  sorry

theorem ContDiff.continuous_partial_snd {φ : E → F → G} {n : ℕ}
    (h : ContDiff 𝕜 ((n + 1 : ℕ) : ℕ∞) <| uncurry φ) : Continuous ↿(∂₂ 𝕜 φ) := by
  sorry

-- FIXME: upgrade again to include analyticity

end Calculus

section RealCalculus -- PRed in #12673

open ContinuousLinearMap

variable {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] {F : Type*} [NormedAddCommGroup F]
  [NormedSpace ℝ F]

end RealCalculus

open Filter

