/-
Copyright (c) 2022 Patrick Massot. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Patrick Massot, Floris van Doorn

! This file was ported from Lean 3 source module global.one_jet_sec
-/
import Mathlib.Order.Filter.Germ.Basic
import Mathlib.Geometry.Manifold.Notation
import SphereEversion.ToMathlib.Topology.Algebra.Module
import SphereEversion.Global.OneJetBundle

/-!
# Sections of 1-jet bundles

In this file we study sections of 1-jet bundles. This is the direct continuation
of `OneJetBundle.lean` but it imports more files, hence the cut.

## Main definitions

In this file we consider two manifolds `M` and `M'` with models `I` and `I'`

* `OneJetSet I M I' M'`: smooth sections of `OneJetBundle I M I' M' → M`
-/

noncomputable section

open Set Function Filter ChartedSpace

open scoped Topology Manifold ContDiff

section General

variable {𝕜 : Type*} [NontriviallyNormedField 𝕜]
  -- declare a smooth manifold `M` over the pair `(E, H)`.
  {E : Type*}
  [NormedAddCommGroup E] [NormedSpace 𝕜 E] {H : Type*} [TopologicalSpace H]
  (I : ModelWithCorners 𝕜 E H) (M : Type*) [TopologicalSpace M] [ChartedSpace H M]
  [IsManifold I ∞ M]
  -- declare a smooth manifold `M'` over the pair `(E', H')`.
  {E' : Type*}
  [NormedAddCommGroup E'] [NormedSpace 𝕜 E'] {H' : Type*} [TopologicalSpace H']
  (I' : ModelWithCorners 𝕜 E' H') (M' : Type*) [TopologicalSpace M'] [ChartedSpace H' M']
  [IsManifold I' ∞ M']

/-- A section of a 1-jet bundle seen as a bundle over the source manifold. -/
@[ext] structure OneJetSec where
  bs : M → M'
  ϕ : ∀ x : M, TangentSpace I x →L[𝕜] TangentSpace I' (bs x)
  contMDiff' : ContMDiff I ((I.prod I').prod 𝓘(𝕜, E →L[𝕜] E')) ∞
    fun x ↦ OneJetBundle.mk x (bs x) (ϕ x)

instance : FunLike (OneJetSec I M I' M') M (OneJetBundle I M I' M') where
  coe := fun S x ↦ OneJetBundle.mk x (S.bs x) (S.ϕ x)
  coe_injective' := by
    intro S T h
    dsimp at h
    ext x
    · simpa using (Bundle.TotalSpace.mk.inj (congrFun h x)).1
    have := heq_eq_eq _ _ ▸ (Bundle.TotalSpace.mk.inj (congrFun h x)).2
    exact congrFun (congrArg DFunLike.coe this) _

variable {I M I' M'}

namespace OneJetSec

protected def mk' (F : M → OneJetBundle I M I' M') (hF : ∀ m, (F m).1.1 = m)
    (h2F : ContMDiff I ((I.prod I').prod 𝓘(𝕜, E →L[𝕜] E')) ∞ F) : OneJetSec I M I' M' :=
  ⟨fun x ↦ (F x).1.2, fun x ↦ (F x).2,
   by convert h2F using 1; ext m; exacts [(hF m).symm, rfl, rfl]⟩

theorem fst_eq (F : OneJetSec I M I' M') (x : M) : (F x).1 = (x, F.bs x) := by
  sorry

theorem is_sec (F : OneJetSec I M I' M') (x : M) : (F x).1.1 = x := by
  sorry

protected theorem contMDiff (F : OneJetSec I M I' M') :
    ContMDiff I ((I.prod I').prod 𝓘(𝕜, E →L[𝕜] E')) ∞ F := by
  sorry

theorem contMDiff_eta (F : OneJetSec I M I' M') :
    ContMDiff I ((I.prod I').prod 𝓘(𝕜, E →L[𝕜] E')) ∞
      (fun x ↦ OneJetBundle.mk x (F.bs x) (F x).2 : M → OneJetBundle I M I' M') := by
  sorry

theorem contMDiff_bs (F : OneJetSec I M I' M') : CMDiff ∞ F.bs := by
  sorry

/-- A section of J¹(M, M') is holonomic at (x : M) if its linear map part is the derivative
of its base map at x. -/
def IsHolonomicAt (F : OneJetSec I M I' M') (x : M) : Prop :=
  mfderiv% F.bs x = (F x).2

/-- A map from M to J¹(M, M') is holonomic if its linear map part is the derivative
of its base map at every point. -/
def IsHolonomic (F : OneJetSec I M I' M') : Prop :=
  ∀ x, F.IsHolonomicAt x

end OneJetSec

def IsHolonomicGerm {x : M} (φ : Germ (𝓝 x) (OneJetBundle I M I' M')) : Prop :=
  Quotient.liftOn' φ (fun F ↦ mfderiv% (fun x' ↦ (F x').1.2) x = (F x).2)
    (by
      letI : Setoid (M → OneJetBundle I M I' M') := (𝓝 x).germSetoid (OneJetBundle I M I' M')
      have key :
        ∀ f g,
          f ≈ g →
            (fun F : M → OneJetBundle I M I' M' ↦
                  mfderiv% (fun x' : M ↦ (F x').proj.snd) x = (F x).snd)
                f →
              (fun F : M → OneJetBundle I M I' M' ↦
                  mfderiv% (fun x' : M ↦ (F x').proj.snd) x = (F x).snd)
                g :=
    by
        intro f g hfg hf
        have hfg' : (fun x' ↦ (f x').1.2) =ᶠ[𝓝 x] fun x' ↦ (g x').1.2 :=
          hfg.fun_comp fun s ↦ s.1.2
        rw [← hfg'.mfderiv_eq, hf, hfg.self_of_nhds]
      exact fun f g H ↦ propext ⟨key f g H, key g f H.symm⟩)

/-- The one-jet extension of a function, seen as a section of the 1-jet bundle. -/
def oneJetExtSec (f : C^∞⟮I, M; I', M'⟯) : OneJetSec I M I' M' :=
  ⟨f, mfderiv% f, f.contMDiff.oneJetExt⟩

end General

section Real

variable {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] {H : Type*} [TopologicalSpace H]
  (I : ModelWithCorners ℝ E H) (M : Type*) [TopologicalSpace M] [ChartedSpace H M]
  [IsManifold I ∞ M] {E' : Type*} [NormedAddCommGroup E'] [NormedSpace ℝ E']
  {H' : Type*} [TopologicalSpace H'] (I' : ModelWithCorners ℝ E' H') (M' : Type*)
  [TopologicalSpace M'] [ChartedSpace H' M'] [IsManifold I' ∞ M'] {F : Type*}
  [NormedAddCommGroup F] [NormedSpace ℝ F] {G : Type*} [TopologicalSpace G]
  (J : ModelWithCorners ℝ F G) (N : Type*) [TopologicalSpace N] [ChartedSpace G N]
  {F' : Type*} [NormedAddCommGroup F'] [NormedSpace ℝ F']
  {G' : Type*} [TopologicalSpace G'] (J' : ModelWithCorners ℝ F' G') (N' : Type*)
  [TopologicalSpace N'] [ChartedSpace G' N'] [IsManifold J' ∞ N'] {EP : Type*}
  [NormedAddCommGroup EP] [NormedSpace ℝ EP] {HP : Type*} [TopologicalSpace HP]
  {IP : ModelWithCorners ℝ EP HP} {P : Type*} [TopologicalSpace P] [ChartedSpace HP P]
  [IsManifold IP ∞ P]

/-- A family of jet sections indexed by manifold `N` is a function from `N` into jet sections
  in such a way that the function is smooth as a function of all arguments. -/
@[ext] structure FamilyOneJetSec where
  bs : N → M → M'
  ϕ : ∀ (n : N) (m : M), TangentSpace I m →L[ℝ] TangentSpace I' (bs n m)
  contMDiff' :
    ContMDiff (J.prod I) ((I.prod I').prod 𝓘(ℝ, E →L[ℝ] E')) ∞ fun p : N × M ↦
      OneJetBundle.mk p.2 (bs p.1 p.2) (ϕ p.1 p.2)

instance : FunLike (FamilyOneJetSec I M I' M' J N) N (OneJetSec I M I' M') where
  coe := fun S t ↦
    { bs := S.bs t
      ϕ := S.ϕ t
      contMDiff' x := (S.contMDiff' (t, x)).comp x <| contMDiffAt_const.prodMk contMDiffAt_id }
  coe_injective' := by
    intro S T h
    ext n : 2
    · exact (OneJetSec.mk.inj (congrFun h n)).1
    · exact (OneJetSec.mk.inj (congrFun h n)).2

namespace FamilyOneJetSec

variable {I M I' M' J N J' N'}

protected def mk' (FF : N → M → OneJetBundle I M I' M') (hF : ∀ n m, (FF n m).1.1 = m)
    (h2F : ContMDiff (J.prod I) ((I.prod I').prod 𝓘(ℝ, E →L[ℝ] E')) ∞ (uncurry FF)) :
    FamilyOneJetSec I M I' M' J N :=
  ⟨fun s x ↦ (FF s x).1.2, fun s x ↦ (FF s x).2,
   by convert h2F using 1; ext ⟨s, m⟩; exacts [(hF s m).symm, rfl, rfl]⟩

theorem coe_mk' (FF : N → M → OneJetBundle I M I' M') (hF : ∀ n m, (FF n m).1.1 = m)
    (h2F : ContMDiff (J.prod I) ((I.prod I').prod 𝓘(ℝ, E →L[ℝ] E')) ∞ (uncurry FF)) (x : N) :
    FamilyOneJetSec.mk' FF hF h2F x =
      OneJetSec.mk' (FF x) (hF x) (h2F.comp (contMDiff_const.prodMk contMDiff_id)) := by
  sorry

@[simp]
theorem bs_eq_coe_bs (S : FamilyOneJetSec I M I' M' J N) (s : N) : S.bs s = (S s).bs := by
  sorry

theorem bs_eq (S : FamilyOneJetSec I M I' M' J N) (s : N) (x : M) : S.bs s x = (S s x).1.2 := by
  sorry

@[simp]
theorem coe_ϕ (S : FamilyOneJetSec I M I' M' J N) (s : N) : (S s).ϕ = S.ϕ s := by
  sorry

protected theorem contMDiff (S : FamilyOneJetSec I M I' M' J N) :
    ContMDiff (J.prod I) ((I.prod I').prod 𝓘(ℝ, E →L[ℝ] E')) ∞ fun p : N × M ↦ S p.1 p.2 := by
  sorry

theorem contMDiff_bs (S : FamilyOneJetSec I M I' M' J N) :
    ContMDiff (J.prod I) I' ∞ fun p : N × M ↦ S.bs p.1 p.2 := by
  sorry

/-- Reindex a family along a smooth function `f`. -/
def reindex (S : FamilyOneJetSec I M I' M' J' N') (f : C^∞⟮J, N; J', N'⟯) :
    FamilyOneJetSec I M I' M' J N where
  bs t := S.bs (f t)
  ϕ t := S.ϕ (f t)
  contMDiff' x := (S.contMDiff' (f x.1, x.2)).comp x
    <| f.contMDiff.contMDiffAt.prodMap' contMDiffAt_id

/-- Turn a family of sections of `J¹(M, M')` parametrized by `N` into a section of `J¹(N × M, M')`.
-/
@[simps]
def uncurry (S : FamilyOneJetSec I M I' M' IP P) : OneJetSec (IP.prod I) (P × M) I' M' where
  bs p := S.bs p.1 p.2
  ϕ p :=
    (mfderiv (IP.prod I) I' (fun z : P × M ↦ S.bs z.1 p.2) p) +
      S.ϕ p.1 p.2 ∘L mfderiv (IP.prod I) I Prod.snd p
  contMDiff' := by
    refine ContMDiff.oneJet_add ?_ ?_
    · intro y
      refine contMDiffAt_id.oneJetBundle_mk (S.contMDiff_bs y) ?_
      have : ContMDiffAt ((IP.prod I).prod (IP.prod I)) I' ∞
          (Function.uncurry fun x z : P × M ↦ S.bs z.1 x.2) (y, y) :=
        S.contMDiff_bs.comp (contMDiff_snd.fst.prodMk contMDiff_fst.snd) (y, y)
      apply ContMDiffAt.mfderiv (fun x z : P × M ↦ S.bs z.1 x.2) id this contMDiffAt_id
        (mod_cast le_top)
    · exact ContMDiff.oneJet_comp I (fun p : P × M ↦ p.2) S.contMDiff contMDiff_snd.oneJetExt

theorem uncurry_ϕ' (S : FamilyOneJetSec I M I' M' IP P) (p : P × M) :
    S.uncurry.ϕ p =
      mfderiv% (fun z ↦ S.bs z p.2) p.1 ∘L ContinuousLinearMap.fst ℝ EP E +
        S.ϕ p.1 p.2 ∘L ContinuousLinearMap.snd ℝ EP E := by
  sorry

theorem isHolonomicAt_uncurry (S : FamilyOneJetSec I M I' M' IP P) {p : P × M} :
    S.uncurry.IsHolonomicAt p ↔ (S p.1).IsHolonomicAt p.2 := by
  sorry

end FamilyOneJetSec

/-- A homotopy of 1-jet sections is a family of 1-jet sections indexed by `ℝ` -/
@[reducible]
def HtpyOneJetSec :=
  FamilyOneJetSec I M I' M' 𝓘(ℝ, ℝ) ℝ

example : FunLike (HtpyOneJetSec I M I' M') ℝ (OneJetSec I M I' M') := by
  sorry

end Real
