import Mathlib.Analysis.Convex.AmpleSet
import Mathlib.Geometry.Manifold.Instances.Sphere
import SphereEversion.ToMathlib.LinearAlgebra.FiniteDimensional
import SphereEversion.ToMathlib.Geometry.Manifold.Immersion
import SphereEversion.ToMathlib.Analysis.InnerProductSpace.Rotation
import SphereEversion.Global.Gromov
import SphereEversion.Global.TwistOneJetSec

-- set_option trace.filter_inst_type true
noncomputable section

open Metric Module Set Function LinearMap Filter ContinuousLinearMap

open scoped Manifold Topology

-- Can't open ContDiff because `ω` conflicts with the notation for orientation below
local notation "∞" => ((⊤ : ℕ∞) : WithTop ℕ∞)

section General

variable {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
  {H : Type*} [TopologicalSpace H] (I : ModelWithCorners ℝ E H) {M : Type*} [TopologicalSpace M]
  [ChartedSpace H M] [IsManifold I ∞ M]
  {E' : Type*} [NormedAddCommGroup E'] [NormedSpace ℝ E']
  {H' : Type*} [TopologicalSpace H'] (I' : ModelWithCorners ℝ E' H')
  {M' : Type*} [TopologicalSpace M'] [ChartedSpace H' M'] [IsManifold I' ∞ M']
  {F : Type*} [NormedAddCommGroup F] [NormedSpace ℝ F] {G : Type*} [TopologicalSpace G]
  (J : ModelWithCorners ℝ F G)
  (N : Type*) [TopologicalSpace N] [ChartedSpace G N] [IsManifold J ∞ N]

@[inherit_doc] local notation "TM" => TangentSpace I
@[inherit_doc] local notation "TM'" => TangentSpace I'
@[inherit_doc] local notation "HJ" => ModelProd (ModelProd H H') (E →L[ℝ] E')
@[inherit_doc] local notation "ψJ" => chartAt HJ

variable (M M') in
/-- The relation of immersions for maps between two manifolds. -/
def immersionRel : RelMfld I M I' M' :=
  {σ | Injective σ.2}

omit [IsManifold I ∞ M] [IsManifold I' ∞ M'] in
@[simp]
theorem mem_immersionRel_iff {σ : OneJetBundle I M I' M'} :
    σ ∈ immersionRel I M I' M' ↔ Injective (σ.2 : TangentSpace I _ →L[ℝ] TangentSpace I' _) := by
  sorry

variable [FiniteDimensional ℝ E] [FiniteDimensional ℝ E']

/-- This is lemma `lem:open_ample_immersion` from the blueprint. -/
theorem immersionRel_open_ample (h : finrank ℝ E < finrank ℝ E') :
    IsOpen (immersionRel I M I' M') ∧ (immersionRel I M I' M').Ample := by
  sorry

end General

section Generalbis

variable {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] [FiniteDimensional ℝ E]
  {H : Type*} [TopologicalSpace H] (I : ModelWithCorners ℝ E H) [I.Boundaryless]
  {M : Type*} [TopologicalSpace M] [ChartedSpace H M] [IsManifold I ∞ M]
  {E' : Type*} [NormedAddCommGroup E'] [NormedSpace ℝ E'] [FiniteDimensional ℝ E']
  {H' : Type*} [TopologicalSpace H'] (I' : ModelWithCorners ℝ E' H') [I'.Boundaryless]
  {M' : Type*} [MetricSpace M'] [ChartedSpace H' M'] [IsManifold I' ∞ M']
  {EP : Type*} [NormedAddCommGroup EP] [NormedSpace ℝ EP] [FiniteDimensional ℝ EP]
  {HP : Type*} [TopologicalSpace HP] {IP : ModelWithCorners ℝ EP HP} [IP.Boundaryless]
  {P : Type*} [TopologicalSpace P] [ChartedSpace HP P] [IsManifold IP ∞ P]
  {C : Set (P × M)} {ε : M → ℝ}

variable (M M' IP P)

/-- parametric h-principle for immersions. -/
theorem immersionRel_satisfiesHPrincipleWith
    [T2Space P] [SigmaCompactSpace P] [T2Space M] [SigmaCompactSpace M] [SigmaCompactSpace M']
    (h : finrank ℝ E < finrank ℝ E') (hC : IsClosed C) (hε_pos : ∀ x, 0 < ε x)
    (hε_cont : Continuous ε) : (immersionRel I M I' M').SatisfiesHPrincipleWith IP C ε := by
  sorry

end Generalbis

/-! The inclusion and antipodal map on a sphere are immersions:
these results are not used directly, but are good sanity checks. -/
section sanitycheck

variable {n : ℕ} (E : Type*) [NormedAddCommGroup E] [InnerProductSpace ℝ E]
  [Fact (finrank ℝ E = n + 1)]

/-- The inclusion of `𝕊^n` into `ℝ^{n+1}` is an immersion. -/
theorem immersion_inclusion_sphere : Immersion (𝓡 n) 𝓘(ℝ, E)
    (fun x : sphere (0 : E) 1 ↦ (x : E)) ∞ := by
  sorry

/-- The antipodal map on `𝕊^n ⊆ ℝ^{n+1}` is an immersion. -/
theorem immersion_antipodal_sphere : Immersion (𝓡 n) 𝓘(ℝ, E)
    (fun x : sphere (0 : E) 1 ↦ -(x : E)) ∞ := by
  sorry

end sanitycheck

section sphere_eversion

variable (E : Type*) [NormedAddCommGroup E] [InnerProductSpace ℝ E] [Fact (finrank ℝ E = 3)]

set_option synthInstance.checkSynthOrder false
attribute [local instance] FiniteDimensional.of_fact_finrank_eq_succ
set_option synthInstance.checkSynthOrder true

@[inherit_doc] local notation "𝕊²" => sphere (0 : E) 1

-- TODO: generalise these statements to `n` dimensions
-- the only obstacle is the construction of rotations requires working on ℝ³.

-- The relation of immersion of a two-sphere into its ambient Euclidean space.
@[inherit_doc] local notation "𝓡_imm" => immersionRel (𝓡 2) 𝕊² 𝓘(ℝ, E) E

variable (ω : Orientation ℝ E (Fin 3))

-- this result holds mutatis mutandis in `ℝ^n`
theorem smooth_bs :
    ContMDiff (𝓘(ℝ, ℝ).prod (𝓡 2)) 𝓘(ℝ, E) ∞
      fun p : ℝ × (sphere (0 : E) 1) ↦ (1 - p.1) • (p.2 : E) + p.1 • -(p.2: E) := by
  sorry

def formalEversionAux : FamilyOneJetSec (𝓡 2) 𝕊² 𝓘(ℝ, E) E 𝓘(ℝ, ℝ) ℝ :=
  familyJoin (smooth_bs E) <|
    familyTwist (drop (oneJetExtSec ⟨((↑) : 𝕊² → E), contMDiff_coe_sphere.of_le le_top⟩))
      (fun p : ℝ × 𝕊² ↦ ω.rot (p.1, p.2))
      (by
        intro p
        have : ContMDiffAt 𝓘(ℝ, ℝ × E) 𝓘(ℝ, E →L[ℝ] E) ∞ ω.rot (p.1, p.2) := by
          refine ((ω.contDiff_rot ?_).of_le le_top).contMDiffAt
          exact ne_zero_of_mem_unit_sphere p.2
        apply this.comp p (f := fun (p : ℝ × sphere 0 1) ↦ (p.1, (p.2 : E)))
        apply contMDiff_fst.prodMk_space ((contMDiff_coe_sphere.of_le le_top).comp contMDiff_snd))

/-- A formal eversion of a two-sphere into its ambient Euclidean space. -/
def formalEversionAux2 : HtpyFormalSol 𝓡_imm :=
  { formalEversionAux E ω with
    is_sol' := fun t x ↦ (ω.isometry_rot t x).injective.comp (mfderiv_coe_sphere_injective x) }

def formalEversion : HtpyFormalSol 𝓡_imm :=
  (formalEversionAux2 E ω).reindex ⟨smoothStep, contMDiff_iff_contDiff.mpr smoothStep.smooth⟩

@[simp]
theorem formalEversion_bs (t : ℝ) :
    (formalEversion E ω t).bs = fun x : 𝕊² ↦
      (1 - smoothStep t : ℝ) • (x : E) + (smoothStep t : ℝ) • (-x : E) := by
  sorry

theorem formalEversion_zero (x : 𝕊²) : (formalEversion E ω 0).bs x = x := by
  sorry

theorem formalEversion_one (x : 𝕊²) : (formalEversion E ω 1).bs x = -x := by
  sorry

theorem formalEversionHolAtZero {t : ℝ} (ht : t < 1 / 4) :
    (formalEversion E ω t).toOneJetSec.IsHolonomic := by
  sorry

theorem formalEversionHolAtOne {t : ℝ} (ht : 3 / 4 < t) :
    (formalEversion E ω t).toOneJetSec.IsHolonomic := by
  sorry

theorem formalEversion_hol_near_zero_one :
    ∀ᶠ s : ℝ × 𝕊² near {0, 1} ×ˢ univ, (formalEversion E ω s.1).toOneJetSec.IsHolonomicAt s.2 := by
  sorry

-- general helper lemmas, useful for showing smoothness of the formal immersions below
section helper

variable {𝕜 : Type*} [NontriviallyNormedField 𝕜]
  {E F G : Type*} [NormedAddCommGroup E] [NormedSpace 𝕜 E] [NormedAddCommGroup F] [NormedSpace 𝕜 F]
  [NormedAddCommGroup G] [NormedSpace 𝕜 G]

-- move to Analysis.Calculus.ContDiff.Basic, or so

-- move to Analysis.Calculus.ContDiff.Defs, or so

-- is this form actually useful, compared to `uncurry_left`?
theorem ContDiff.uncurry_left' (n : ℕ∞) {f : E × F → G}
    (hf : ContDiff 𝕜 n f) (x : E) :
    ContDiff 𝕜 n (fun p : F ↦ f ⟨x, p⟩) := by
  sorry

theorem ContDiff.uncurry_left {f : E → F → G} (n : ℕ∞) (hf : ContDiff 𝕜 n ↿f) (x : E) :
    ContDiff 𝕜 n (f x) := by
  sorry

variable {𝕜 : Type*} [NontriviallyNormedField 𝕜]
  {E : Type*} [NormedAddCommGroup E] [NormedSpace 𝕜 E]
  {H : Type*} [TopologicalSpace H] (I : ModelWithCorners 𝕜 E H)
  {M : Type*} [TopologicalSpace M] [ChartedSpace H M]
  {E' : Type*} [NormedAddCommGroup E'] [NormedSpace 𝕜 E']
  {H' : Type*} [TopologicalSpace H'] (I' : ModelWithCorners 𝕜 E' H')
  {M' : Type*} [MetricSpace M'] [ChartedSpace H' M']
  {EP : Type*} [NormedAddCommGroup EP] [NormedSpace 𝕜 EP]
  {HP : Type*} [TopologicalSpace HP] (IP : ModelWithCorners 𝕜 EP HP)
  {P : Type*} [TopologicalSpace P] [ChartedSpace HP P]

-- move to Mathlib.Geometry.Manifold.ContMDiff.Product

-- move to Mathlib.Geometry.Manifold.ContMDiff.Product

end helper

theorem sphere_eversion :
    ∃ f : ℝ → 𝕊² → E,
      ContMDiff (𝓘(ℝ, ℝ).prod (𝓡 2)) 𝓘(ℝ, E) ∞ ↿f ∧
        (f 0 = fun x : 𝕊² ↦ (x : E)) ∧ (f 1 = fun x : 𝕊² ↦ -(x : E)) ∧
        ∀ t, Immersion (𝓡 2) 𝓘(ℝ, E) (f t) ∞ := by
  sorry

-- The next instance will be used in the main file.
instance (n : ℕ) : Fact (finrank ℝ (EuclideanSpace ℝ <| Fin n) = n) :=
  ⟨finrank_euclideanSpace_fin⟩

-- The next notation will be used in the main file.
notation "ℝ^" n:arg => EuclideanSpace ℝ (Fin n)

end sphere_eversion
