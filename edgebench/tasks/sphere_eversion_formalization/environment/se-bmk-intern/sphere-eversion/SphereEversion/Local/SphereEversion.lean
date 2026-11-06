import Mathlib.Analysis.Convex.AmpleSet
import SphereEversion.ToMathlib.Analysis.InnerProductSpace.Rotation
import SphereEversion.ToMathlib.Analysis.InnerProductSpace.Dual
import SphereEversion.Local.ParametricHPrinciple

/-!
This is file proves the existence of a sphere eversion from the local verson of the h-principle.

We define the relation of immersions `R = immersion_sphere_rel ⊆ J¹(E, F)` which consist of all
`(x, y, ϕ)` such that if `x` is outside a ball around the origin with chosen radius `R < 1` then
`ϕ` must be injective on `(ℝ ∙ x)ᗮ` (the orthogonal complement of the span of `x`).
We show that `R` is open and ample.

Furthermore, we define a formal solution of sphere eversion that is holonomic near `0` and `1`.
We have to be careful since we're not actually working on the sphere,
but in the ambient space `E ≃ ℝ³`.
See `loc_formal_eversion` for the choice and constaints of the solution.

Finally, we obtain the existence of sphere eversion from the parametric local h-principle,
proven in `Local/ParametricHPrinciple`.
-/

noncomputable section

open Metric Module Set Function RelLoc InnerProductSpace Submodule

open Filter hiding mem_map

open LinearMap (ker)

open scoped Topology RealInnerProductSpace

section SphereEversion

variable {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E] {F : Type*}
  [NormedAddCommGroup F] [InnerProductSpace ℝ F]

@[inherit_doc] local notation "𝕊²" => sphere (0 : E) 1

@[inherit_doc] local notation "dim" => Module.finrank ℝ

@[inherit_doc] local notation "pr[" x "]ᗮ" => projSpanOrthogonal x

@[inherit_doc] local notation "B" => ball (0 : E) 0.9

/-- A map between vector spaces is a immersion viewed as a map on the sphere, when its
derivative at `x ∈ 𝕊²` is injective on the orthogonal complement of `x`
(the tangent space to the sphere). Note that this implies `f` is differentiable at every point
`x ∈ 𝕊²` since otherwise `D f x = 0`.
-/
def SphereImmersion (f : E → F) : Prop :=
  ∀ x ∈ 𝕊², InjOn (D f x) (ℝ ∙ x)ᗮ

variable (E F)

/-- The relation of immersionsof a two-sphere into its ambient Euclidean space. -/
def immersionSphereRel : RelLoc E F :=
  {w : OneJet E F | w.1 ∉ B → InjOn w.2.2 (ℝ ∙ w.1)ᗮ}

@[inherit_doc] local notation "R" => immersionSphereRel E F

variable {E F}

@[simp]
theorem mem_loc_immersion_rel {x y φ} :
    (⟨x, y, φ⟩ : OneJet E F) ∈ immersionSphereRel E F ↔ x ∉ B → InjOn φ (ℝ ∙ x)ᗮ := by
  sorry

section AssumeFiniteDimensional

variable [FiniteDimensional ℝ E]

-- The following is extracted from `loc_immersion_rel_open` because it is slow to typecheck

theorem loc_immersion_rel_open : IsOpen (immersionSphereRel E F) := by
  sorry

variable [FiniteDimensional ℝ F]

-- In the next lemma the assumption `dim E = n + 1` is for convenience
-- using `finrank_orthogonal_span_singleton`. We could remove it to treat empty spheres...
theorem loc_immersion_rel_ample (n : ℕ) [Fact (dim E = n + 1)] (h : finrank ℝ E ≤ finrank ℝ F) :
    (immersionSphereRel E F).IsAmple := by
  sorry

end AssumeFiniteDimensional

/-- The main ingredient of the linear map in the formal eversion of the sphere. -/
def locFormalEversionAuxφ [Fact (dim E = 3)] (ω : Orientation ℝ E (Fin 3)) (t : ℝ) (x : E) :
    E →L[ℝ] E :=
  ω.rot (t, x) - (2 * t) • Submodule.subtypeL (ℝ ∙ x) ∘L orthogonalProjection (ℝ ∙ x)

section AssumeFiniteDimensional
local notation "∞" => ((⊤ : ℕ∞) : WithTop ℕ∞)

variable [Fact (dim E = 3)] [FiniteDimensional ℝ E] (ω : Orientation ℝ E (Fin 3))

theorem smooth_at_locFormalEversionAuxφ {p : ℝ × E} (hx : p.2 ≠ 0) {n : WithTop ℕ∞} :
    ContDiffAt ℝ n (uncurry (locFormalEversionAuxφ ω)) p := by
  sorry

/-- A formal eversion of `𝕊²`, viewed as a homotopy. -/
def locFormalEversionAux : HtpyJetSec E E where
  f (t : ℝ) (x : E) := (1 - 2 * smoothStep t) • x
  φ t x := smoothStep (‖x‖ ^ 2) • locFormalEversionAuxφ ω (smoothStep t) x
  f_diff :=
    ContDiff.smul (contDiff_const.sub <| contDiff_const.mul <| smoothStep.smooth.comp contDiff_fst)
      contDiff_snd
  φ_diff := by
    refine contDiff_iff_contDiffAt.mpr fun x ↦ ?_
    obtain (hx | hx) := eq_or_ne x.2 0
    · refine (contDiffAt_const (c := 0)).congr_of_eventuallyEq ?_
      have : (fun x ↦ ‖x‖ ^ 2) ⁻¹' Iio (1 / 4) ∈ 𝓝 (0 : E) := by
        refine IsOpen.mem_nhds ?_ ?_
        · exact isOpen_Iio.preimage (contDiff_norm_sq ℝ (n :=∞)).continuous
        · simp_rw [mem_preimage, norm_zero, mem_Iio]
          norm_num
      have : (fun x ↦ smoothStep (‖x‖ ^ 2)) ⁻¹' {0} ∈ 𝓝 (0 : E) := by
        refine mem_of_superset this ?_
        erw [preimage_comp (g := smoothStep)]
        refine preimage_mono ?_
        intro x hx
        rw [mem_preimage, mem_singleton_iff, smoothStep.of_lt hx]
      have : (fun p : ℝ × E ↦ smoothStep (‖p.2‖ ^ 2)) ⁻¹' {0} ∈ 𝓝 x := by
        rw [← hx] at this
        exact continuousAt_snd.preimage_mem_nhds this
      filter_upwards [this]
      rintro ⟨t, x⟩ hx
      simp_rw [mem_preimage, mem_singleton_iff] at hx
      change smoothStep (‖x‖ ^ 2) • locFormalEversionAuxφ ω (smoothStep t) x = 0
      simp_rw [hx, zero_smul]
    refine ContDiffAt.smul ?_ ?_
    · exact (smoothStep.smooth.comp <| (contDiff_norm_sq ℝ).comp contDiff_snd).contDiffAt
    · exact (smooth_at_locFormalEversionAuxφ ω
        (show (Prod.map smoothStep id x).2 ≠ 0 from hx)).comp x
        (smoothStep.smooth.prodMap contDiff_id).contDiffAt

/-- A formal eversion of `𝕊²` into its ambient Euclidean space.
The corresponding map `E → E` is roughly a linear homotopy from `id` at `t = 0` to `- id` at
`t = 1`. The continuous linear maps are roughly rotations with angle `t * π`. However, we have to
keep track of a few complications:
* We need the formal solution to be holonomic near `0` and `1`.
  Therefore, we compose the above maps with a smooth step function that is constant `0` near `t = 0`
  and constant `1` near `t = 1`.
* We need to modify the derivative of `ω.rot` to also have the right behavior on `(ℝ ∙ x)`
  at `t = 1` (it is the identity, but it should be `-id`). Therefore, we subtract
  `(2 * t) • (submodule.subtypeL (ℝ ∙ x) ∘L orthogonal_projection (ℝ ∙ x))`,
  which is `2t` times the identity on `(ℝ ∙ x)`.
* We have to make sure the family of continuous linear map is smooth at `x = 0`. Therefore, we
  multiply the family with a factor of `smooth_step (‖x‖ ^ 2)`.
-/
def locFormalEversion : HtpyFormalSol (immersionSphereRel E E) :=
  { locFormalEversionAux ω with
    is_sol := by
      intro t x
      change x ∉ B →
        InjOn (smoothStep (HPow.hPow ‖x‖ 2) • locFormalEversionAuxφ ω (smoothStep t) x) (ℝ ∙ x)ᗮ
      intro hx
      have h2x : smoothStep (HPow.hPow ‖x‖ 2) = 1 := by
        refine smoothStep.of_gt ?_
        rw [mem_ball, not_lt, dist_zero_right] at hx
        refine (show (3 : ℝ) / 4 < (0.9 : ℝ) ^ 2 by norm_num).trans_le ?_
        rwa [sq_le_sq, show |(0.9 : ℝ)| = 0.9 by norm_num, abs_norm]
      rw [h2x, one_smul]
      have h3x : x ≠ 0 := by rintro rfl; apply hx; exact mem_ball_self (by norm_num)
      refine (EqOn.injOn_iff ?_).mpr (ω.injOn_rot_of_ne (smoothStep t) h3x)
      intro v hv
      simp_rw [locFormalEversionAuxφ, ContinuousLinearMap.sub_apply, ContinuousLinearMap.smul_apply,
        ContinuousLinearMap.comp_apply,
        orthogonalProjection_mem_subspace_orthogonalComplement_eq_zero hv, _root_.map_zero,
        smul_zero, sub_zero] }

@[simp]
theorem locFormalEversion_f (t : ℝ) :
    (locFormalEversion ω t).f = fun x : E ↦ ((1 : ℝ) - 2 * smoothStep t) • x := by
  sorry

theorem locFormalEversion_φ (t : ℝ) (x : E) (v : E) :
    (locFormalEversion ω t).φ x v =
      smoothStep (‖x‖ ^ 2) •
        (ω.rot (smoothStep t, x) v - (2 * smoothStep t) • orthogonalProjection (ℝ ∙ x) v) := by
  sorry

theorem locFormalEversion_zero (x : E) : (locFormalEversion ω 0).f x = x := by
  sorry

theorem locFormalEversion_one (x : E) : (locFormalEversion ω 1).f x = -x := by
  sorry

theorem locFormalEversionHolAtZero {t : ℝ} (ht : t < 1 / 4) {x : E}
    (hx : smoothStep (‖x‖ ^ 2) = 1) : (locFormalEversion ω t).IsHolonomicAt x := by
  sorry

theorem locFormalEversionHolAtOne {t : ℝ} (ht : 3 / 4 < t) {x : E} (hx : smoothStep (‖x‖ ^ 2) = 1) :
    (locFormalEversion ω t).IsHolonomicAt x := by
  sorry

theorem locFormalEversion_hol :
    ∀ᶠ p : ℝ × E near {0, 1} ×ˢ 𝕊², (locFormalEversion ω p.1).IsHolonomicAt p.2 := by
  sorry

end AssumeFiniteDimensional

open scoped unitInterval

local notation "∞" => ((⊤ : ℕ∞) : WithTop ℕ∞)

theorem sphere_eversion_of_loc [Fact (dim E = 3)] :
    ∃ f : ℝ → E → E,
      𝒞 ∞ ↿f ∧ (∀ x ∈ 𝕊², f 0 x = x) ∧ (∀ x ∈ 𝕊², f 1 x = -x) ∧ ∀ t ∈ I, SphereImmersion (f t) := by
  sorry

-- Stating the full statement with all type-class arguments and no uncommon notation.
example (E : Type*) [NormedAddCommGroup E] [InnerProductSpace ℝ E] [Fact (Module.finrank ℝ E = 3)] :
    ∃ f : ℝ → E → E,
      ContDiff ℝ ∞ (uncurry f) ∧
        (∀ x ∈ sphere (0 : E) 1, f 0 x = x) ∧
          (∀ x ∈ sphere (0 : E) 1, f 1 x = -x) ∧ ∀ t ∈ unitInterval, SphereImmersion (f t) := by
  sorry

end SphereEversion
