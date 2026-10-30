import Mathlib.Analysis.Calculus.InverseFunctionTheorem.FDeriv
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.Calculus.Deriv.MeanValue
import Mathlib.Analysis.InnerProductSpace.Calculus
import Mathlib.Analysis.InnerProductSpace.Dual
import SphereEversion.ToMathlib.Analysis.Calculus
import SphereEversion.ToMathlib.Analysis.NormedSpace.OperatorNorm.Prod

noncomputable section

open scoped Topology Filter ContDiff
open Function

section

universe u₁ u₂ u₃ u₄ u₅

open ContinuousLinearMap

variable {𝕜 : Type u₁} [NontriviallyNormedField 𝕜]
  {M₁ : Type u₂} [NormedAddCommGroup M₁] [NormedSpace 𝕜 M₁]
  {M₂ : Type u₃} [NormedAddCommGroup M₂] [NormedSpace 𝕜 M₂]
  {M₃ : Type u₄} [NormedAddCommGroup M₃] [NormedSpace 𝕜 M₃]
  {M₄ : Type u₅} [NormedAddCommGroup M₄] [NormedSpace 𝕜 M₄]

-- The next definition won't be used here, it's practice before the next one.
/-- Defines continuous linear maps between two products by blocks:
given `(A : M₁ →L[𝕜] M₃)`, `(B : M₂ →L[𝕜] M₃)`, `(C : M₁ →L[𝕜] M₄)` and `(D : M₂ →L[𝕜] M₄)`,
construct the continuous linear map with "matrix":
A B
C D. -/
def ContinuousLinearMap.blocks (A : M₁ →L[𝕜] M₃) (B : M₂ →L[𝕜] M₃) (C : M₁ →L[𝕜] M₄)
    (D : M₂ →L[𝕜] M₄) : M₁ × M₂ →L[𝕜] M₃ × M₄ :=
  (A.coprod B).prod (C.coprod D)

/-- Given `(A : M₁ ≃L[𝕜] M₃)`, `(C : M₁ →L[𝕜] M₄)` and `(D : M₂ ≃L[𝕜] M₄)`,
construct the continuous linear equiv with "matrix"
A 0
C D.
-/
-- TODO: generalise this to larger constructors? or is this useful as-is?
def ContinuousLinearEquiv.lowerTriangular (A : M₁ ≃L[𝕜] M₃) (C : M₁ →L[𝕜] M₄) (D : M₂ ≃L[𝕜] M₄) :
    (M₁ × M₂) ≃L[𝕜] M₃ × M₄ :=
  ContinuousLinearEquiv.equivOfInverse (((A : M₁ →L[𝕜] M₃).comp (fst 𝕜 M₁ M₂)).prod (C.coprod D))
    (((A.symm : M₃ →L[𝕜] M₁).comp (fst 𝕜 M₃ M₄)).prod
      ((-((D.symm : M₄ →L[𝕜] M₂).comp C).comp (A.symm : M₃ →L[𝕜] M₁)).coprod D.symm))
    (fun ⟨x, y⟩ ↦ by simp)
    fun ⟨x, y⟩ ↦ by simp

end

section

variable (𝕜 : Type*) [NontriviallyNormedField 𝕜] {E : Type*} [NormedAddCommGroup E]
  [NormedSpace 𝕜 E] {F : Type*} [NormedAddCommGroup F] [NormedSpace 𝕜 F] {G : Type*}
  [NormedAddCommGroup G] [NormedSpace 𝕜 G] {n : WithTop ℕ∞}

-- The next two definitions aren't used in the end, but they may still go to mathlib
/-- The proposition that a function between two normed spaces has a strict derivative at a given
point. -/
def StrictDifferentiableAt (f : E → F) (x) :=
  ∃ φ : E →L[𝕜] F, HasStrictFDerivAt f φ x

/-- The proposition that a function between two normed spaces has a strict derivative at every
point. -/
def StrictDifferentiable (f : E → F) :=
  ∀ x, StrictDifferentiableAt 𝕜 f x

variable {𝕜}

theorem StrictDifferentiableAt.differentiableAt {f : E → F} {x : E}
    (h : StrictDifferentiableAt 𝕜 f x) : DifferentiableAt 𝕜 f x := by
  sorry

variable [CompleteSpace E]

theorem Homeomorph.contDiffAt_symm (f : Homeomorph E F) {f₀' : E ≃L[𝕜] F} {a : F}
    (hf' : HasFDerivAt f (f₀' : E →L[𝕜] F) (f.symm a)) (hf : ContDiffAt 𝕜 n f (f.symm a)) :
    ContDiffAt 𝕜 n f.symm a := by
  sorry

theorem Equiv.continuous_symm_of_contDiff (φ : E ≃ F) {Dφ : E → E ≃L[𝕜] F}
    (hφ : ∀ x, HasStrictFDerivAt φ (Dφ x : E →L[𝕜] F) x) : Continuous φ.symm := by
  sorry

/-- A bijection that is strictly differentiable at every point is a homeomorphism. -/
def Equiv.toHomeomorphOfContDiff (φ : E ≃ F) {Dφ : E → E ≃L[𝕜] F}
    (hφ : ∀ x, HasStrictFDerivAt φ (Dφ x : E →L[𝕜] F) x) : E ≃ₜ F :=
  { φ with
    continuous_toFun := Differentiable.continuous fun x ↦ (hφ x).differentiableAt
    continuous_invFun := φ.continuous_symm_of_contDiff hφ }

end

section

variable {𝕜 : Type*} [RCLike 𝕜] {E : Type*} [NormedAddCommGroup E] [NormedSpace 𝕜 E] {F : Type*}
  [NormedAddCommGroup F] [NormedSpace 𝕜 F] {G : Type*} [NormedAddCommGroup G] [NormedSpace 𝕜 G]
  {n : WithTop ℕ∞}

@[inherit_doc] local notation "∂₁" => partialFDerivFst 𝕜

@[inherit_doc] local notation "∂₂" => partialFDerivSnd 𝕜

theorem contDiff_parametric_symm [CompleteSpace E] [CompleteSpace F] {f : E → F ≃ G}
    {f' : E → F → F ≃L[𝕜] G} (hf : ContDiff 𝕜 ∞ fun p : E × F ↦ f p.1 p.2)
    (hf' : ∀ x y, ∂₂ (fun x y ↦ f x y) x y = f' x y) :
    ContDiff 𝕜 ∞ fun p : E × G ↦ (f p.1).symm p.2 := by
  sorry

end

section

variable {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] [CompleteSpace E]

theorem contDiff_parametric_symm_of_deriv_pos {f : E → ℝ → ℝ} (hf : ContDiff ℝ ∞ ↿f)
    (hderiv : ∀ x t, 0 < partialDerivSnd f x t) (hsurj : ∀ x, Surjective <| f x) :
    ContDiff ℝ ∞ fun p : E × ℝ ↦
      (StrictMono.orderIsoOfSurjective (f p.1) (strictMono_of_deriv_pos <| hderiv p.1)
            (hsurj p.1)).symm p.2 := by
  sorry

end

section

variable (𝕜 : Type*) [NontriviallyNormedField 𝕜]

end

section

variable {𝕜 : Type*} [RCLike 𝕜]

variable {E : Type*} [NormedAddCommGroup E] [InnerProductSpace 𝕜 E] [CompleteSpace E]

-- variant of `Submodule.orthogonalProjection_singleton`

end

section

open Submodule

variable {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E] [CompleteSpace E]

end

section Arithmetic

variable {𝕜 : Type*} [NontriviallyNormedField 𝕜] {E : Type*} [NormedAddCommGroup E]
  [NormedSpace 𝕜 E] {𝔸 : Type*} [NormedRing 𝔸] [NormedAlgebra 𝕜 𝔸] {n : WithTop ℕ∞}
  {f : E → 𝔸} {s : Set E} {x : E}

theorem ContDiffWithinAt.mul_const (hf : ContDiffWithinAt 𝕜 n f s x) {c : 𝔸} :
    ContDiffWithinAt 𝕜 n (fun x : E ↦ f x * c) s x := by
  sorry

theorem ContDiffOn.mul_const (hf : ContDiffOn 𝕜 n f s) {c : 𝔸} :
    ContDiffOn 𝕜 n (fun x : E ↦ f x * c) s := by
  sorry

theorem ContDiff.mul_const (hf : ContDiff 𝕜 n f) {c : 𝔸} : ContDiff 𝕜 n fun x : E ↦ f x * c := by
  sorry

end Arithmetic

section

variable {𝕜 : Type*} [NontriviallyNormedField 𝕜] {E : Type*} [NormedAddCommGroup E]
  [NormedSpace 𝕜 E] {F : Type*} [NormedAddCommGroup F] [NormedSpace 𝕜 F]

end
