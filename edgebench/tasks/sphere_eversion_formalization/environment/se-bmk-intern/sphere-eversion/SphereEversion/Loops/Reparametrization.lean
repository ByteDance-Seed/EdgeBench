import Mathlib.Analysis.Calculus.BumpFunction.Convolution
import Mathlib.Analysis.Calculus.BumpFunction.InnerProduct
import Mathlib.MeasureTheory.Integral.IntervalIntegral.IntegrationByParts
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Periodic
import SphereEversion.Loops.Surrounding
import SphereEversion.Loops.DeltaMollifier
import SphereEversion.ToMathlib.ExistsOfConvex
import SphereEversion.ToMathlib.Analysis.ContDiff

/-!
# The reparametrization lemma

This file contains a proof of Gromov's parametric reparametrization lemma. It concerns the behaviour
of the average value of a loop `γ : S¹ → F` when the loop is reparametrized by precomposing with a
diffeomorphism `S¹ → S¹`.

Given a loop `γ : S¹ → F` for some real vector space `F`, one may integrate to obtain its average
`∫ x in 0..1, (γ x)` in `F`. Although this average depends on the loop's parametrization, it
satisfies a contraint that depends only on the image of the loop: the average is contained in the
convex hull of the image of `γ`. The non-parametric version of the reparametrization lemma says that
conversely, given any point `g` in the interior of the convex hull of the image of `γ`, one may find
a reparametrization of `γ` whose average is `g`.

The reparametrization lemma thus allows one to reduce the problem of constructing a loop whose
average is a given point, to the problem of constructing a loop subject to a condition that depends
only on its image.

In fact the reparametrization lemma holds parametrically. Given a smooth family of loops:
`γ : E × S¹ → F`, `(x, t) ↦ γₓ t`, together with a smooth function `g : E → F`, such that `g x` is
contained in the interior of the convex hull of the image of `γₓ` for all `x`, there exists a smooth
family of diffeomorphism `φ : E × S¹ → S¹`, `(x, t) ↦ φₓ t` such that the average of `γₓ ∘ φₓ` is
`g x` for all `x`.

The idea of the proof is simple: since `g x` is contained in the interior of the convex hull of
the image of `γₓ` one may find `t₀, t₁, ..., tₙ` and barycentric coordinates `w₀, w₁, ..., wₙ` such
that `g x = ∑ᵢ wᵢ • γₓ(tᵢ)`. If there were no smoothness requirement on `φₓ` one could define
it to be a step function which spends time `wᵢ` at each `tᵢ`. However because there is a smoothness
condition, one rounds off the corners of the would-be step function by using a "delta mollifier"
(an approximation to a Dirac delta function).

The above construction works locally in the neighbourhood of any `x` in `E` and one uses a partition
of unity to globalise all the local solutions into the required family: `φ : E × S¹ → S¹`.

The key ingredients are theories of calculus, convex hulls, barycentric coordinates,
existence of delta mollifiers, partitions of unity, and the inverse function theorem.
-/

noncomputable section

open Set Function MeasureTheory Module intervalIntegral Filter
open scoped Topology Manifold ContDiff

variable {E F : Type*} [NormedAddCommGroup F] [NormedSpace ℝ F]

set_option hygiene false
notation "ι" => Fin (finrank ℝ F + 1)
set_option hygiene true

section MetricSpace

variable [MetricSpace E] [FiniteDimensional ℝ F]

theorem Loop.tendsto_mollify_apply (γ : E → Loop F) (h : Continuous ↿γ) (x : E) (t : ℝ) :
    Tendsto (fun z : E × ℕ ↦ (γ z.1).mollify z.2 t) (𝓝 x ×ˢ atTop) (𝓝 (γ x t)) := by
  sorry

end MetricSpace

variable [NormedAddCommGroup E] [NormedSpace ℝ E]

/-- Given a smooth function `g : E → F` between normed vector spaces, a smooth surrounding family
is a smooth family of loops `E → loop F`, `x ↦ γₓ` such that `γₓ` surrounds `g x` for all `x`. -/
structure SmoothSurroundingFamily (g : E → F) where
  smooth_surrounded : 𝒞 ∞ g
  toFun : E → Loop F
  smooth : 𝒞 ∞ ↿toFun
  Surrounds : ∀ x, (toFun x).Surrounds <| g x

namespace SmoothSurroundingFamily

variable {g : E → F} (γ : SmoothSurroundingFamily g) (x y : E)

instance : CoeFun (SmoothSurroundingFamily g) fun _ ↦ E → Loop F :=
  ⟨toFun⟩

/-- Given `γ : SmoothSurroundingFamily g` and `x : E`, `γ.surroundingParametersAt x` are the
`tᵢ : ℝ`, for `i = 0, 1, ..., dim F` such that `γ x tᵢ` surround `g x`. -/
def surroundingParametersAt : ι → ℝ :=
  Classical.choose (γ.Surrounds x)

/-- Given `γ : SmoothSurroundingFamily g` and `x : E`, `γ.surroundingPointsAt x` are the
points `γ x tᵢ` surrounding `g x` for parameters `tᵢ : ℝ`, `i = 0, 1, ..., dim F` (defined
by `γ.surroundingParametersAt x`). -/
def surroundingPointsAt : ι → F :=
  γ x ∘ γ.surroundingParametersAt x

/-- Given `γ : SmoothSurroundingFamily g` and `x : E`, `γ.surrounding_weights_at x` are the
barycentric coordinates of `g x` wrt to the points `γ x tᵢ`, for parameters `tᵢ : ℝ`,
`i = 0, 1, ..., dim F` (defined by `γ.surroundingParametersAt x`). -/
def surroundingWeightsAt : ι → ℝ :=
  Classical.choose (Classical.choose_spec (γ.Surrounds x))

/-- Note that we are mollifying the loop `γ y` at the surrounding parameters for `γ x`. -/
def approxSurroundingPointsAt (n : ℕ) (i : ι) : F :=
  (γ y).mollify n (γ.surroundingParametersAt x i)

variable [FiniteDimensional ℝ E] [CompleteSpace F] in
theorem approxSurroundingPointsAt_smooth (n : ℕ) :
    𝒞 ∞ fun y ↦ γ.approxSurroundingPointsAt x y n := by
  sorry

variable [FiniteDimensional ℝ F]

/-- The key property from which it should be easy to construct `localCenteringDensity`,
`localCenteringDensityNhd` etc below. -/
theorem eventually_exists_surroundingPts_approxSurroundingPointsAt :
    ∀ᶠ z : E × ℕ in 𝓝 x ×ˢ atTop,
      ∃ w, SurroundingPts (g z.1) (γ.approxSurroundingPointsAt x z.1 z.2) w := by
  sorry

/-- This is an auxiliary definition to help construct `centeringDensity` below.

Given `x : E`, it represents a smooth probability distribution on the circle with the property that:
`∫ s in 0..1, γ.localCenteringDensity x y s • γ y s = g y`
for all `y` in a neighbourhood of `x` (see `localCenteringDensity_average` below). -/
def localCenteringDensity [DecidablePred (· ∈ affineBases ι ℝ F)] : E → ℝ → ℝ := fun y ↦ by
  choose n hn₁ _ using
    Filter.eventually_iff_exists_mem.mp
      (γ.eventually_exists_surroundingPts_approxSurroundingPointsAt x)
  choose u _u v hv _huv using mem_prod_iff.mp hn₁
  choose m _hmv using mem_atTop_sets.mp hv
  exact ∑ i, evalBarycentricCoords ι ℝ F (g y) (γ.approxSurroundingPointsAt x y m) i •
      deltaMollifier m (γ.surroundingParametersAt x i)

/-- This is an auxiliary definition to help construct `centeringDensity` below. -/
def localCenteringDensityMp : ℕ := by
  choose n hn₁ _hn₂ using
    Filter.eventually_iff_exists_mem.mp
      (γ.eventually_exists_surroundingPts_approxSurroundingPointsAt x)
  choose u _hu v hv _huv using mem_prod_iff.mp hn₁
  choose m _hmv using mem_atTop_sets.mp hv
  exact m

theorem localCenteringDensity_spec [DecidablePred (· ∈ affineBases ι ℝ F)] :
    γ.localCenteringDensity x y =
      ∑ i,
        evalBarycentricCoords ι ℝ F (g y)
            (γ.approxSurroundingPointsAt x y (γ.localCenteringDensityMp x)) i •
          deltaMollifier (γ.localCenteringDensityMp x) (γ.surroundingParametersAt x i) := by
  sorry

/-- This is an auxiliary definition to help construct `centeringDensity` below. -/
def localCenteringDensityNhd : Set E := by
  choose n hn₁ _hn₂ using
    Filter.eventually_iff_exists_mem.mp
      (γ.eventually_exists_surroundingPts_approxSurroundingPointsAt x)
  choose u _hu v _hv _huv using mem_prod_iff.mp hn₁
  exact interior u

theorem localCenteringDensityNhd_isOpen : IsOpen <| γ.localCenteringDensityNhd x := by
  sorry

theorem localCenteringDensityNhd_self_mem : x ∈ γ.localCenteringDensityNhd x := by
  sorry

-- unused
theorem localCenteringDensityNhd_covers : univ ⊆ ⋃ x, γ.localCenteringDensityNhd x := by
  sorry

theorem approxSurroundingPointsAt_of_localCenteringDensityNhd
    (hy : y ∈ γ.localCenteringDensityNhd x) :
    ∃ w, SurroundingPts (g y)
      (γ.approxSurroundingPointsAt x y (γ.localCenteringDensityMp x)) w := by
  sorry

theorem approxSurroundingPointsAt_mem_affineBases (hy : y ∈ γ.localCenteringDensityNhd x) :
    γ.approxSurroundingPointsAt x y (γ.localCenteringDensityMp x) ∈ affineBases ι ℝ F := by
  sorry

section DecidablePred

variable [DecidablePred (· ∈ affineBases ι ℝ F)]

@[simp]
theorem localCenteringDensity_pos (hy : y ∈ γ.localCenteringDensityNhd x) (t : ℝ) :
    0 < γ.localCenteringDensity x y t := by
  sorry

theorem localCenteringDensity_periodic : Periodic (γ.localCenteringDensity x y) 1 := by
  sorry

variable [FiniteDimensional ℝ E] in
@[fun_prop]
theorem contDiffOn_localCenteringDensity :
    ContDiffOn ℝ ∞ ↿(γ.localCenteringDensity x)
      <| γ.localCenteringDensityNhd x ×ˢ (univ : Set ℝ) := by
  sorry

variable [FiniteDimensional ℝ E] in
@[fun_prop]
theorem localCenteringDensity_continuous (hy : y ∈ γ.localCenteringDensityNhd x) :
    Continuous fun t ↦ γ.localCenteringDensity x y t := by
  sorry

@[simp]
theorem localCenteringDensity_integral_eq_one (hy : y ∈ γ.localCenteringDensityNhd x) :
    ∫ s in (0 : ℝ)..1, γ.localCenteringDensity x y s = 1 := by
  sorry

@[simp]
theorem localCenteringDensity_average (hy : y ∈ γ.localCenteringDensityNhd x) :
    ∫ s in (0 : ℝ)..1, γ.localCenteringDensity x y s • γ y s = g y := by
  sorry

end DecidablePred

/-- Given `γ : SmoothSurroundingFamily g`, together with a point `x : E` and a map `f : ℝ → ℝ`,
`γ.is_centeringDensity x f` is the proposition that `f` is periodic, strictly positive, and
has integral one and that the average of `γₓ` with respect to the measure that `f` defines on
the circle is `g x`.

The continuity assumption is just a legacy convenience and should be dropped. -/
structure IsCenteringDensity (x : E) (f : ℝ → ℝ) : Prop where
  Pos : ∀ t, 0 < f t
  Periodic : Periodic f 1
  integral_one : ∫ s in (0 : ℝ)..1, f s = 1
  average : ∫ s in (0 : ℝ)..1, f s • γ x s = g x
  Continuous : Continuous f

omit [FiniteDimensional ℝ F] in
-- Can drop if/when have `intervalIntegrable.smul_continuous_on`
theorem isCenteringDensity_convex (x : E) : Convex ℝ { f | γ.IsCenteringDensity x f } := by
  sorry

variable [FiniteDimensional ℝ E]

theorem exists_smooth_isCenteringDensity (x : E) :
    ∃ U ∈ 𝓝 x,
      ∃ f : E → ℝ → ℝ,
        ContDiffOn ℝ ∞ (uncurry f) (U ×ˢ (univ : Set ℝ)) ∧
          ∀ y ∈ U, γ.IsCenteringDensity y (f y) := by
  sorry

/-- This the key construction. It represents a smooth probability distribution on the circle with
the property that:
`∫ s in 0..1, γ.centeringDensity x s • γ x s = g x`
for all `x : E` (see `centeringDensity_average` below). -/
def centeringDensity : E → ℝ → ℝ :=
  Classical.choose
    (exists_contDiff_of_convex₂ γ.isCenteringDensity_convex γ.exists_smooth_isCenteringDensity)

theorem centeringDensity_smooth : 𝒞 ∞ <| uncurry fun x t ↦ γ.centeringDensity x t := by
  sorry

theorem isCenteringDensityCenteringDensity (x : E) :
    γ.IsCenteringDensity x (γ.centeringDensity x) := by
  sorry

@[simp]
theorem centeringDensity_pos (t : ℝ) : 0 < γ.centeringDensity x t := by
  sorry

theorem centeringDensity_periodic : Periodic (γ.centeringDensity x) 1 := by
  sorry

@[simp]
theorem centeringDensity_integral_eq_one : ∫ s in (0)..1, γ.centeringDensity x s = 1 := by
  sorry

@[simp]
theorem centeringDensity_average : ∫ s in (0)..1, γ.centeringDensity x s • γ x s = g x := by
  sorry

theorem centeringDensity_continuous : Continuous (γ.centeringDensity x) := by
  sorry

theorem centeringDensity_intervalIntegrable (t₁ t₂ : ℝ) :
    IntervalIntegrable (γ.centeringDensity x) volume t₁ t₂ := by
  sorry

@[simp]
theorem integral_add_one_centeringDensity (t : ℝ) :
    ∫ s in (0)..t + 1, γ.centeringDensity x s = (∫ s in (0)..t, γ.centeringDensity x s) + 1 := by
  sorry

theorem deriv_integral_centeringDensity_pos (t : ℝ) :
    0 < deriv (fun t ↦ ∫ s in (0)..t, γ.centeringDensity x s) t := by
  sorry

theorem strictMono_integral_centeringDensity :
    StrictMono fun t ↦ ∫ s in (0)..t, γ.centeringDensity x s := by
  sorry

theorem surjective_integral_centeringDensity :
    Surjective fun t ↦ ∫ s in (0)..t, γ.centeringDensity x s := by
  sorry

/-- Given `γ : SmoothSurroundingFamily g`, `x ↦ γ.reparametrize x` is a smooth family of
diffeomorphisms of the circle such that reparametrizing `γₓ` by `γ.reparametrize x` gives a loop
with average `g x`.

This is the key construction and the main "output" of the reparametrization lemma. -/
def reparametrize : E → EquivariantEquiv := fun x ↦
  ({ toFun := fun t ↦ ∫ s in (0)..t, γ.centeringDensity x s
     invFun :=
       (StrictMono.orderIsoOfSurjective _ (γ.strictMono_integral_centeringDensity x)
           (γ.surjective_integral_centeringDensity x)).symm
     left_inv := StrictMono.orderIsoOfSurjective_symm_apply_self _ _ _
     right_inv := fun t ↦ StrictMono.orderIsoOfSurjective_self_symm_apply _
       (γ.strictMono_integral_centeringDensity x) _ t
     map_zero' := integral_same
     eqv' := γ.integral_add_one_centeringDensity x } : EquivariantEquiv).symm

theorem hasDerivAt_reparametrize_symm (s : ℝ) :
    HasDerivAt (γ.reparametrize x).symm (γ.centeringDensity x s) s := by
  sorry

-- 𝒞 ∞ ↿γ.reparametrize
theorem reparametrize_smooth : 𝒞 ∞ <| uncurry fun (x : E) (t : ℝ) ↦ γ.reparametrize x t := by
  sorry

@[simp]
theorem reparametrize_average :
    ((γ x).reparam <| (γ.reparametrize x).equivariantMap).average = g x := by
  sorry

end SmoothSurroundingFamily
