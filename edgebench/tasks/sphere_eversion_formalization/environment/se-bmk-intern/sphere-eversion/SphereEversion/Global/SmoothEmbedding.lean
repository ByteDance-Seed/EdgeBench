import Mathlib.Analysis.Normed.Order.Lattice
import Mathlib.Geometry.Manifold.ContMDiff.Atlas
import Mathlib.Geometry.Manifold.ContMDiff.NormedSpace
import Mathlib.Geometry.Manifold.MFDeriv.SpecificFunctions
import Mathlib.Geometry.Manifold.Notation
import SphereEversion.Indexing
import SphereEversion.Notations
import SphereEversion.ToMathlib.Analysis.NormedSpace.Misc
import SphereEversion.ToMathlib.Geometry.Manifold.IsManifold.ExtChartAt
import SphereEversion.ToMathlib.Topology.Misc
import SphereEversion.ToMathlib.Topology.Paracompact

noncomputable section

open Set Equiv

open scoped Manifold Topology ContDiff

section General

variable {𝕜 : Type*} [NontriviallyNormedField 𝕜] {E : Type*} [NormedAddCommGroup E]
  [NormedSpace 𝕜 E] {H : Type*} [TopologicalSpace H] (I : ModelWithCorners 𝕜 E H) (M : Type*)
  [TopologicalSpace M] [ChartedSpace H M]
  {E' : Type*} [NormedAddCommGroup E'] [NormedSpace 𝕜 E'] {H' : Type*} [TopologicalSpace H']
  (I' : ModelWithCorners 𝕜 E' H') (M' : Type*) [TopologicalSpace M'] [ChartedSpace H' M']

structure OpenSmoothEmbedding where
  toFun : M → M'
  invFun : M' → M
  left_inv' : ∀ {x}, invFun (toFun x) = x
  isOpen_range : IsOpen (range toFun)
  contMDiff_to : CMDiff ∞ toFun
  contMDiffOn_inv : CMDiff[range toFun] ∞ invFun

attribute [coe] OpenSmoothEmbedding.toFun

-- Note: this cannot be a `FunLike` instance since `toFun` is not injective in general.
instance : CoeFun (OpenSmoothEmbedding I M I' M') fun _ ↦ M → M' :=
  ⟨OpenSmoothEmbedding.toFun⟩

namespace OpenSmoothEmbedding

variable {I I' M M'}

variable (f : OpenSmoothEmbedding I M I' M')

theorem coe_mk (f g h₁ h₂ h₃ h₄) : ⇑(⟨f, g, h₁, h₂, h₃, h₄⟩ : OpenSmoothEmbedding I M I' M') = f := by
  sorry

@[simp]
theorem left_inv (x : M) : f.invFun (f x) = x := by
  sorry

@[simp]
theorem invFun_comp_coe : f.invFun ∘ f = id := by
  sorry

@[simp]
theorem right_inv {y : M'} (hy : y ∈ range f) : f (f.invFun y) = y := by
  sorry

theorem contMDiffAt_inv {y : M'} (hy : y ∈ range f) : CMDiffAt ∞ f.invFun y := by
  sorry

theorem contMDiffAt_inv' {x : M} : CMDiffAt ∞ f.invFun (f x) := by
  sorry

protected theorem continuous : Continuous f := by
  sorry

theorem isOpenMap : IsOpenMap f := by
  sorry

theorem coe_comp_invFun_eventuallyEq (x : M) : f ∘ f.invFun =ᶠ[𝓝 (f x)] id := by
  sorry

section

variable [IsManifold I ∞ M] [IsManifold I' ∞ M']

/- Note that we are slightly abusing the fact that `TangentSpace I x` and
`TangentSpace I (f.invFun (f x))` are both definitionally `E` below. -/
def fderiv (x : M) : TangentSpace I x ≃L[𝕜] TangentSpace I' (f x) :=
  have h₁ : MDifferentiableAt I' I f.invFun (f x) :=
    ((f.contMDiffOn_inv (f x)
    (mem_range_self x)).mdifferentiableWithinAt (by simp)).mdifferentiableAt
    (f.isOpenMap.range_mem_nhds x)
  have h₂ : MDifferentiableAt I I' f x := f.contMDiff_to.mdifferentiableAt (by simp)
  ContinuousLinearEquiv.equivOfInverse (mfderiv% f x) (mfderiv% f.invFun (f x))
    (by
      intro v
      erw [← ContinuousLinearMap.comp_apply, ← mfderiv_comp x h₁ h₂, f.invFun_comp_coe, mfderiv_id,
        ContinuousLinearMap.coe_id', id])
    (by
      intro v
      have hx : x = f.invFun (f x) := by rw [f.left_inv]
      have hx' : f (f.invFun (f x)) = f x := by rw [f.left_inv]
      rw [hx] at h₂
      erw [hx, hx', ← ContinuousLinearMap.comp_apply, ← mfderiv_comp (f x) h₂ h₁,
        ((hasMFDerivAt_id (f x)).congr_of_eventuallyEq
            (f.coe_comp_invFun_eventuallyEq x)).mfderiv,
        ContinuousLinearMap.coe_id', id])

omit [IsManifold I ∞ M] [IsManifold I' ∞ M'] in
@[simp]
theorem fderiv_coe (x : M) :
    (f.fderiv x : TangentSpace I x →L[𝕜] TangentSpace I' (f x)) = mfderiv% f x := by
  sorry

omit [IsManifold I ∞ M] [IsManifold I' ∞ M'] in
@[simp]
theorem fderiv_symm_coe (x : M) :
    ((f.fderiv x).symm : TangentSpace I' (f x) →L[𝕜] TangentSpace I x) =
      mfderiv% f.invFun (f x) := by
  sorry

omit [IsManifold I ∞ M] [IsManifold I' ∞ M'] in

end

open Filter Topology

-- TODO: optimize this proof which is probably more complicated than it needs to be

variable (I M)

-- unused
/-- The identity map is a smooth open embedding. -/
@[simps]
nonrec def id : OpenSmoothEmbedding I M I M where
  toFun := id
  invFun := id
  left_inv' := rfl
  isOpen_range := IsOpenMap.id.isOpen_range
  contMDiff_to := contMDiff_id
  contMDiffOn_inv := contMDiffOn_id

variable {I M}

/- -- unused
@[simps!]
def comp {E'' : Type*} [NormedAddCommGroup E''] [NormedSpace 𝕜 E''] {H'' : Type*}
    [TopologicalSpace H''] {I'' : ModelWithCorners 𝕜 E'' H''} {M'' : Type*} [TopologicalSpace M'']
    [ChartedSpace H'' M''] [SmoothManifoldWithCorners I'' M'']
    (g : OpenSmoothEmbedding I' M' I'' M'') (f : OpenSmoothEmbedding I M I' M') :
    OpenSmoothEmbedding I M I'' M'' where
  toFun := g ∘ f
  invFun := f.invFun ∘ g.invFun
  left_inv' x := by simp only [Function.comp_apply, left_inv]
  isOpen_range := (g.isOpenMap.comp f.isOpenMap).isOpen_range
  smooth_to := g.smooth_to.comp f.smooth_to
  smooth_inv :=
    (f.smooth_inv.comp' g.smooth_inv).mono
      (by
        change range (g ∘ f) ⊆ range g ∩ g.inv_fun ⁻¹' range f
        refine subset_inter_iff.mpr ⟨range_comp_subset_range f g, ?_⟩
        rintro x' ⟨x, rfl⟩
        exact ⟨x, by simp only [left_inv]⟩) -/

end OpenSmoothEmbedding

namespace ContinuousLinearEquiv

variable (e : E ≃L[𝕜] E') [CompleteSpace E] [CompleteSpace E']

-- unused
@[simps]
def toOpenSmoothEmbedding : OpenSmoothEmbedding 𝓘(𝕜, E) E 𝓘(𝕜, E') E' where
  toFun := e
  invFun := e.symm
  left_inv' {x} := e.symm_apply_apply x
  isOpen_range := e.isOpenMap.isOpen_range
  contMDiff_to := (e : E →L[𝕜] E').contMDiff
  contMDiffOn_inv := (e.symm : E' →L[𝕜] E).contMDiff.contMDiffOn

end ContinuousLinearEquiv

end General

section WithoutBoundary

open Metric hiding mem_nhds_iff

open Function

universe u

variable {F H : Type*} (M : Type u) [NormedAddCommGroup F] [NormedSpace ℝ F] [TopologicalSpace H]
  [TopologicalSpace M] [ChartedSpace H M]
  (IF : ModelWithCorners ℝ F H) [IsManifold IF ∞ M]

/- Clearly should be generalised. Maybe what we really want is a theory of local diffeomorphisms.

Note that the input `f` is morally an `OpenSmoothEmbedding` but stated in terms of `ContDiff`
instead of `ContMDiff`. This is more convenient for our purposes. -/
def openSmoothEmbOfDiffeoSubsetChartTarget (x : M) {f : OpenPartialHomeomorph F F}
    (hf₁ : f.source = univ) (hf₂ : ContDiff ℝ ∞ f) (hf₃ : ContDiffOn ℝ ∞ f.symm f.target)
    (hf₄ : range f ⊆ IF '' (chartAt H x).target) : OpenSmoothEmbedding 𝓘(ℝ, F) F IF M
    where
  toFun := (extChartAt IF x).symm ∘ f
  invFun := f.invFun ∘ extChartAt IF x
  left_inv' {y} := by
    obtain ⟨z, hz, hz'⟩ := hf₄ (mem_range_self y)
    have aux : f.symm (IF z) = y := by rw [hz']; exact f.left_inv (hf₁.symm ▸ mem_univ _)
    simp only [← hz', (chartAt H x).right_inv hz, extChartAt, OpenPartialHomeomorph.extend,
      PartialEquiv.coe_trans, OpenPartialHomeomorph.invFun_eq_coe,
      ModelWithCorners.toPartialEquiv_coe, OpenPartialHomeomorph.coe_coe,
      PartialEquiv.coe_trans_symm, OpenPartialHomeomorph.coe_coe_symm,
      ModelWithCorners.left_inv, ModelWithCorners.toPartialEquiv_coe_symm, Function.comp_apply, aux]
  isOpen_range :=
    IsOpenMap.isOpen_range fun u hu ↦ by
      have aux : IsOpen (f '' u) := f.isOpen_image_of_subset_source hu (hf₁.symm ▸ subset_univ u)
      convert isOpen_extChartAt_preimage' x aux
      on_goal 1 => rw [image_comp]
      refine
        (extChartAt IF x).symm_image_eq_source_inter_preimage ((image_subset_range f u).trans ?_)
      rw [extChartAt, OpenPartialHomeomorph.extend_target']
      exact hf₄
  contMDiff_to := by
    refine (contMDiffOn_extChartAt_symm x).comp_contMDiff hf₂.contMDiff fun y ↦ ?_
    rw [extChartAt, OpenPartialHomeomorph.extend_target']
    exact hf₄ (mem_range_self y)
  contMDiffOn_inv := by
    rw [← OpenPartialHomeomorph.extend_target'] at hf₄
    have hf' : range ((extChartAt IF x).symm ∘ f) ⊆ extChartAt IF x ⁻¹' f.target := by
      rw [range_comp, ← image_subset_iff, ← f.image_source_eq_target, hf₁, image_univ]
      exact (PartialEquiv.image_symm_image_of_subset_target _ hf₄).subset
    have hf'' : range ((extChartAt IF x).symm ∘ f) ⊆ (chartAt H x).source := by
      rw [← extChartAt_source IF, range_comp, ← PartialEquiv.symm_image_target_eq_source]
      exact (monotone_image hf₄).trans Subset.rfl
    exact hf₃.contMDiffOn.comp (contMDiffOn_extChartAt.mono hf'') hf'

variable {M} (F)
variable [IF.Boundaryless] [FiniteDimensional ℝ F]
variable [T2Space M] [LocallyCompactSpace M] [SigmaCompactSpace M]

theorem nice_atlas' {ι : Type*} {s : ι → Set M} (s_op : ∀ j, IsOpen <| s j)
    (cov : (⋃ j, s j) = univ) (U : Set F) (hU₁ : (0 : F) ∈ U) (hU₂ : IsOpen U) :
    ∃ (ι' : Type u) (t : Set ι') (φ : t → OpenSmoothEmbedding 𝓘(ℝ, F) F IF M),
      t.Countable ∧
        (∀ i, ∃ j, range (φ i) ⊆ s j) ∧
          (LocallyFinite fun i ↦ range (φ i)) ∧ (⋃ i, φ i '' U) = univ := by
  sorry

variable [Nonempty M]

theorem nice_atlas {ι : Type*} {s : ι → Set M} (s_op : ∀ j, IsOpen <| s j)
    (cov : (⋃ j, s j) = univ) :
    ∃ n, ∃ φ : IndexType n → OpenSmoothEmbedding 𝓘(ℝ, F) F IF M,
        (∀ i, ∃ j, range (φ i) ⊆ s j) ∧
          (LocallyFinite fun i ↦ range (φ i)) ∧ (⋃ i, φ i '' ball 0 1) = univ := by
  sorry

end WithoutBoundary

namespace OpenSmoothEmbedding

section Updating

variable {𝕜 EX EM EY EN EM' X M Y N M' : Type*} [NontriviallyNormedField 𝕜]
  [NormedAddCommGroup EX] [NormedSpace 𝕜 EX] [NormedAddCommGroup EM] [NormedSpace 𝕜 EM]
  [NormedAddCommGroup EM'] [NormedSpace 𝕜 EM'] [NormedAddCommGroup EY] [NormedSpace 𝕜 EY]
  [NormedAddCommGroup EN] [NormedSpace 𝕜 EN]
  {HX : Type*} [TopologicalSpace HX] {IX : ModelWithCorners 𝕜 EX HX}
  {HY : Type*} [TopologicalSpace HY] {IY : ModelWithCorners 𝕜 EY HY}
  {HM : Type*} [TopologicalSpace HM] {IM : ModelWithCorners 𝕜 EM HM}
  {HM' : Type*} [TopologicalSpace HM'] {IM' : ModelWithCorners 𝕜 EM' HM'}
  {HN : Type*} [TopologicalSpace HN] {IN : ModelWithCorners 𝕜 EN HN}
  [TopologicalSpace X] [ChartedSpace HX X]
  [TopologicalSpace M] [ChartedSpace HM M]
  [TopologicalSpace M'] [ChartedSpace HM' M']

section NonMetric

variable [TopologicalSpace Y] [ChartedSpace HY Y] [TopologicalSpace N] [ChartedSpace HN N]
  (φ : OpenSmoothEmbedding IX X IM M) (ψ : OpenSmoothEmbedding IY Y IN N) (f : M → N) (g : X → Y)

section

attribute [local instance] Classical.dec

/-- This is definition `def:update` in the blueprint. -/
def update (m : M) : N :=
  if m ∈ range φ then ψ (g (φ.invFun m)) else f m

end

-- This small auxiliary result is used in the next two lemmas.

open Function

/-- This is lemma `lem:smooth_updating` in the blueprint. -/
theorem contMDiff_update (f : M' → M → N) (g : M' → X → Y) {k : M' → M} {K : Set X}
    (hK : IsClosed (φ '' K)) (hf : ContMDiff (IM'.prod IM) IN ∞ (uncurry f))
    (hg : ContMDiff (IM'.prod IX) IY ∞ (uncurry g)) (hk : CMDiff ∞ k)
    (hg' : ∀ y x, x ∉ K → f y (φ x) = ψ (g y x)) :
    CMDiff ∞ fun x ↦ update φ ψ (f x) (g x) (k x) := by
  sorry

end NonMetric

section Metric

variable [MetricSpace Y] [ChartedSpace HY Y] [MetricSpace N] [ChartedSpace HN N]
  (φ : OpenSmoothEmbedding IX X IM M)
  (ψ : OpenSmoothEmbedding IY Y IN N) (f : M → N) (g : X → Y)

end Metric

end Updating

end OpenSmoothEmbedding
