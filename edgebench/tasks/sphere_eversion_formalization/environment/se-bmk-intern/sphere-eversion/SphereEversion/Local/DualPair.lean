import Mathlib.Analysis.Calculus.ContDiff.FiniteDimension
import Mathlib.Analysis.Complex.Norm
import Mathlib.Analysis.Normed.Module.Completion
import Mathlib.LinearAlgebra.Dual.Lemmas
import SphereEversion.Notations
import SphereEversion.ToMathlib.Analysis.NormedSpace.OperatorNorm.Prod
import SphereEversion.ToMathlib.LinearAlgebra.Basic

/-! # Dual pairs

Convex integration improves maps by successively modify their derivative in a direction of a
vector field (almost) without changing their derivative along some complementary hyperplace.

In this file we introduce the linear algebra part of the story of such modifications.
The main gadget here are dual pairs on a real topological vector space `E`.
Each `p : DualPair E` is made of a (continuous) linear form `p.π : E →L[ℝ] ℝ` and a vector
`p.v : E` such that `p.π p.v = 1`.

Those pairs are used to build the updating operation turning `φ : E →L[ℝ] F` into
`p.update φ w` which equals `φ` on `ker p.π` and sends `v` to the given `w : F`.

After formalizing the above definitions, we first record a number of trivial algebraic lemmas.
Then we prove a lemma which is geometrically obvious but not so easy to formalize:
`injective_update_iff` states, starting with an injective `φ`, that the updated
map `p.update φ w` is injective if and only if `w` isn't in the image of `ker p.π` under `φ`.
This is crucial in order to apply convex integration to immersions.

Then we prove continuity and smoothness lemmas for this operation.
-/

noncomputable section

open Function ContinuousLinearMap

open LinearMap (ker)

open scoped ContDiff

/-! ## General theory -/

section NoNorm

variable (E : Type*) {E' F G : Type*}

variable [AddCommGroup E] [Module ℝ E] [TopologicalSpace E]

variable [AddCommGroup E'] [Module ℝ E'] [TopologicalSpace E']

variable [NormedAddCommGroup F] [NormedSpace ℝ F] [NormedAddCommGroup G] [NormedSpace ℝ G]

/-- A continuous linear form `π` and a vector `v` that pair to one. In particular `ker π` is a
hyperplane and `v` spans a complement of this hyperplane. -/
structure DualPair where
  π : E →L[ℝ] ℝ
  v : E
  pairing : π v = 1

namespace DualPair

variable {E}

attribute [local simp] ContinuousLinearMap.toSpanSingleton_apply

/-- Given a dual pair `p`, `p.span_v` is the line spanned by `p.v`. -/
def spanV (p : DualPair E) : Submodule ℝ E :=
  Submodule.span ℝ {p.v}

theorem mem_spanV (p : DualPair E) {u : E} : u ∈ p.spanV ↔ ∃ t : ℝ, u = t • p.v := by
  sorry

/-- Update a continuous linear map `φ : E →L[ℝ] F` using a dual pair `p` on `E` and a
vector `w : F`. The new map coincides with `φ` on `ker p.π` and sends `p.v` to `w`. -/
def update (p : DualPair E) (φ : E →L[ℝ] F) (w : F) : E →L[ℝ] F :=
  φ + (w - φ p.v) ⬝ p.π

-- useful with `DualPair.decomp`

/-- Map a dual pair under a linear equivalence. -/
@[simps]
def map (p : DualPair E) (L : E ≃L[ℝ] E') : DualPair E' :=
  ⟨p.π ∘L ↑L.symm, L p.v, (congr_arg p.π <| L.symm_apply_apply p.v).trans p.pairing⟩

/-! ## Injectivity criterion -/

@[simp]
theorem injective_update_iff (p : DualPair E) {φ : E →L[ℝ] F} (hφ : Injective φ) {w : F} :
    Injective (p.update φ w) ↔ w ∉ (p.π.ker).map (φ : E →ₛₗ[.id ℝ] F) := by
  sorry

end DualPair

end NoNorm

/-! ## Smoothness and continuity -/

namespace DualPair

variable {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] {F : Type*} [NormedAddCommGroup F]
  [NormedSpace ℝ F]

/- In the next two lemmas, finite dimensionality of `E` is clearly uneeded, but allows
to use `contDiff_clm_apply_iff` and `continuous_clm_apply`. -/
theorem smooth_update [FiniteDimensional ℝ E] (p : DualPair E) {G : Type*} [NormedAddCommGroup G]
    [NormedSpace ℝ G] {φ : G → E →L[ℝ] F} (hφ : 𝒞 ∞ φ) {w : G → F} (hw : 𝒞 ∞ w) :
    𝒞 ∞ fun g ↦ p.update (φ g) (w g) := by
  sorry

end DualPair

variable {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] {F : Type*} [NormedAddCommGroup F]
  [NormedSpace ℝ F]

/-- Given a finite basis `e : basis ι ℝ E`, and `i : ι`,
`e.DualPair i` is given by the `i`th basis element and its dual. -/
def Module.Basis.dualPair [FiniteDimensional ℝ E] {ι : Type*} [Fintype ι] [DecidableEq ι]
    (e : Basis ι ℝ E) (i : ι) : DualPair E where
  π := LinearMap.toContinuousLinearMap (e.dualBasis i)
  v := e i
  pairing := by simp
