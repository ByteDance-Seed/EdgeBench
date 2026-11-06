import Mathlib.Analysis.InnerProductSpace.Basic
import Mathlib.Analysis.Normed.Operator.BoundedLinearMaps
import Mathlib.Analysis.Normed.Operator.Prod

noncomputable section

@[inherit_doc] local notation:70 u " ⬝ " φ:65 =>
  ContinuousLinearMap.comp (ContinuousLinearMap.toSpanSingleton ℝ u) φ

variable {𝕜 E F G Fₗ Gₗ X : Type*} [NontriviallyNormedField 𝕜] [NormedAddCommGroup E]
  [NormedAddCommGroup Fₗ] [NormedAddCommGroup Gₗ] [NormedAddCommGroup F] [NormedAddCommGroup G]
  [NormedSpace 𝕜 E] [NormedSpace 𝕜 Fₗ] [NormedSpace 𝕜 Gₗ] [NormedSpace 𝕜 F] [NormedSpace 𝕜 G]
  [TopologicalSpace X]

theorem ContinuousLinearMap.le_opNorm_of_le' {𝕜 : Type*} {𝕜₂ : Type*} {E : Type*} {F : Type*}
    [NormedAddCommGroup E] [SeminormedAddCommGroup F] [NontriviallyNormedField 𝕜]
    [NontriviallyNormedField 𝕜₂] [NormedSpace 𝕜 E] [NormedSpace 𝕜₂ F] {σ₁₂ : 𝕜 →+* 𝕜₂}
    [RingHomIsometric σ₁₂] (f : E →SL[σ₁₂] F) {x : E} (hx : x ≠ 0) {C : ℝ} (h : C * ‖x‖ ≤ ‖f x‖) :
    C ≤ ‖f‖ := by
  sorry

universe u₁ u₂ u₃ u₄

/-- The natural linear map `(M →ₗ[R] M₃) × (M₂ →ₗ[R] M₃) →ₗ[R] M × M₂ →ₗ[R] M₃` for `R`-modules `M`,
`M₂`, `M₃` over a commutative ring `R`.

If `f : M →ₗ[R] M₃` and `g : M₂ →ₗ[R] M₃` then `linear_map.coprodₗ (f, g)` is the map
`(m, n) ↦ f m + g n`. -/
def LinearMap.coprodₗ (R : Type u₁) (M : Type u₂) (M₂ : Type u₃) (M₃ : Type u₄) [CommRing R]
    [AddCommMonoid M] [AddCommMonoid M₂] [AddCommMonoid M₃] [Module R M] [Module R M₂]
    [Module R M₃] : (M →ₗ[R] M₃) × (M₂ →ₗ[R] M₃) →ₗ[R] M × M₂ →ₗ[R] M₃ where
  toFun p := p.1.coprod p.2
  map_add' p q := by
    apply LinearMap.coe_injective
    ext x
    simp only [Prod.fst_add, LinearMap.coprod_apply, LinearMap.add_apply, Prod.snd_add]
    module
  map_smul' r p := by
    apply LinearMap.coe_injective
    ext x
    simp only [Prod.smul_fst, Prod.smul_snd, LinearMap.coprod_apply, LinearMap.smul_apply,
      RingHom.id_apply, smul_add]

theorem isBoundedLinearMap_coprod (𝕜 : Type*) [NontriviallyNormedField 𝕜] (E : Type*)
    [NormedAddCommGroup E] [NormedSpace 𝕜 E] (F : Type*) [NormedAddCommGroup F] [NormedSpace 𝕜 F]
    (G : Type*) [NormedAddCommGroup G] [NormedSpace 𝕜 G] :
    IsBoundedLinearMap 𝕜 fun p : (E →L[𝕜] G) × (F →L[𝕜] G) ↦ p.1.coprod p.2 := by
  sorry

/-- The natural continuous linear map `((E →L[𝕜] G) × (F →L[𝕜] G)) →L[𝕜] (E × F →L[𝕜] G)` for
normed spaces `E`, `F`, `G` over a normed field `𝕜`.

If `g₁ : E →L[𝕜] G` and `g₂ : F →L[𝕜] G` then `continuous_linear_map.coprodL (g₁, g₂)` is the map
`(e, f) ↦ g₁ e + g₂ f`. -/
def ContinuousLinearMap.coprodL : (E →L[𝕜] G) × (F →L[𝕜] G) →L[𝕜] E × F →L[𝕜] G :=
  (isBoundedLinearMap_coprod 𝕜 E F G).toContinuousLinearMap

