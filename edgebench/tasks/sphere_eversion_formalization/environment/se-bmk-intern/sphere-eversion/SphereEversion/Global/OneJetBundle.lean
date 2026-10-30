/-
Copyright (c) 2022 Patrick Massot. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Patrick Massot, Floris van Doorn

! This file was ported from Lean 3 source module global.one_jet_bundle
-/
import Mathlib.Tactic.Common

import Mathlib.Analysis.Normed.Module.Completion
import Mathlib.Geometry.Manifold.Algebra.Monoid
import Mathlib.Geometry.Manifold.ContMDiffMFDeriv
import Mathlib.Geometry.Manifold.Notation
import SphereEversion.ToMathlib.Geometry.Manifold.VectorBundle.Misc
import Mathlib.Geometry.Manifold.VectorBundle.Hom
import Mathlib.Geometry.Manifold.VectorBundle.Pullback
import Mathlib.Tactic.Monotonicity.Lemmas

/-!
# 1-jet bundles

This file contains the definition of the 1-jet bundle `J¹(M, M')`, also known as
`OneJetBundle I M I' M'`.

We also define
* `OneJetExt I I' f : M → J¹(M, M')`: the 1-jet extension `j¹f` of a map `f : M → M'`

We prove
* If `f` is smooth, `j¹f` is smooth.
* If `x ↦ (f₁ x, f₂ x, ϕ₁ x) : N → J¹(M₁, M₂)` and `x ↦ (f₂ x, f₃ x, ϕ₂ x) : N → J¹(M₂, M₃)`
  are smooth, then so is `x ↦ (f₁ x, f₃ x, ϕ₂ x ∘ ϕ₁ x) : N → J¹(M₁, M₃)`.
-/

noncomputable section

open Filter Set Equiv Bundle ContinuousLinearMap

open scoped Manifold Topology Bundle ContDiff

variable {𝕜 : Type*} [NontriviallyNormedField 𝕜]
  {E : Type*} [NormedAddCommGroup E] [NormedSpace 𝕜 E]
  {H : Type*} [TopologicalSpace H] (I : ModelWithCorners 𝕜 E H)
  {M : Type*} [TopologicalSpace M] [ChartedSpace H M] [IsManifold I ∞ M]
  {E' : Type*} [NormedAddCommGroup E'] [NormedSpace 𝕜 E']
  {H' : Type*} [TopologicalSpace H'] (I' : ModelWithCorners 𝕜 E' H')
  {M' : Type*} [TopologicalSpace M'] [ChartedSpace H' M'] [IsManifold I' ∞ M']
  {E'' : Type*} [NormedAddCommGroup E''] [NormedSpace 𝕜 E'']
  {H'' : Type*} [TopologicalSpace H''] {I'' : ModelWithCorners 𝕜 E'' H''}
  {M'' : Type*} [TopologicalSpace M''] [ChartedSpace H'' M''] [IsManifold I'' ∞ M'']
  {F : Type*} [NormedAddCommGroup F] [NormedSpace 𝕜 F]
  {G : Type*} [TopologicalSpace G] (J : ModelWithCorners 𝕜 F G)
  {N : Type*} [TopologicalSpace N] [ChartedSpace G N]
  {F' : Type*} [NormedAddCommGroup F'] [NormedSpace 𝕜 F']
  {G' : Type*} [TopologicalSpace G'] (J' : ModelWithCorners 𝕜 F' G')
  {N' : Type*} [TopologicalSpace N'] [ChartedSpace G' N'] [IsManifold J' ∞ N']
  {E₂ : Type*} [NormedAddCommGroup E₂] [NormedSpace 𝕜 E₂]
  {H₂ : Type*} [TopologicalSpace H₂] {I₂ : ModelWithCorners 𝕜 E₂ H₂}
  {M₂ : Type*} [TopologicalSpace M₂] [ChartedSpace H₂ M₂] [IsManifold I₂ ∞ M₂]
  {E₃ : Type*} [NormedAddCommGroup E₃] [NormedSpace 𝕜 E₃]
  {H₃ : Type*} [TopologicalSpace H₃] {I₃ : ModelWithCorners 𝕜 E₃ H₃}
  {M₃ : Type*} [TopologicalSpace M₃] [ChartedSpace H₃ M₃] [IsManifold I₃ ∞ M₃]

@[inherit_doc] local notation "σ" => RingHom.id 𝕜

instance deleteme1 :
    ∀ x : M × M',
      Module 𝕜 (((ContMDiffMap.fst : C^∞⟮I.prod I', M × M'; I, M⟯) *ᵖ (TangentSpace I)) x) := by
        infer_instance

instance deleteme2 :
    ∀ x : M × M',
      Module 𝕜 (((ContMDiffMap.snd : C^∞⟮I.prod I', M × M'; I', M'⟯) *ᵖ (TangentSpace I')) x) := by
        infer_instance

instance deleteme3 :
    VectorBundle 𝕜 E ((ContMDiffMap.fst : C^∞⟮I.prod I', M × M'; I, M⟯) *ᵖ (TangentSpace I)) := by
  infer_instance

instance deleteme4 : VectorBundle 𝕜 E'
    ((ContMDiffMap.snd : C^∞⟮I.prod I', M × M'; I', M'⟯) *ᵖ (TangentSpace I')) := by
  infer_instance

instance deleteme5 : ContMDiffVectorBundle ∞ E
    ((ContMDiffMap.fst : C^∞⟮I.prod I', M × M'; I, M⟯) *ᵖ (TangentSpace I)) (I.prod I') := by
  infer_instance

instance deleteme6 : ContMDiffVectorBundle ∞ E'
    ((ContMDiffMap.snd : C^∞⟮I.prod I', M × M'; I', M'⟯) *ᵖ (TangentSpace I')) (I.prod I') := by
  infer_instance

set_option linter.unusedVariables false in
/-- The fibers of the one jet-bundle. -/
def OneJetSpace (p : M × M') : Type _ :=
  ((ContMDiffMap.fst : C^∞⟮I.prod I', M × M'; I, M⟯) *ᵖ (TangentSpace I)) p →SL[σ]
  ((ContMDiffMap.snd : C^∞⟮I.prod I', M × M'; I', M'⟯) *ᵖ (TangentSpace I')) p

instance (p : M × M') : TopologicalSpace (OneJetSpace I I' p) := by
  delta OneJetSpace
  infer_instance

instance (p : M × M') : AddCommGroup (OneJetSpace I I' p) := by
  delta OneJetSpace
  infer_instance

variable {I I'}

-- what is better notation for this?
/-- Local notation for the `OneJetSpace` on `M × M'`, w.r.t. `I` and `I'` -/
local notation "FJ¹MM'" => (OneJetSpace I I' : M × M' → Type _)

variable (I I')

instance (p : M × M') : FunLike (OneJetSpace I I' p) (TangentSpace I p.1) (TangentSpace I' p.2)
where
  coe := fun φ ↦ φ.toFun
  coe_injective' := fun _ _ h ↦ ContinuousLinearMap.ext (congrFun h)

variable (M M')

-- is empty if the base manifold is empty
/-- The space of one jets of maps between two smooth manifolds.
Defined in terms of `Bundle.TotalSpace` to be able to put a suitable topology on it. -/
@[reducible]
def OneJetBundle :=
  TotalSpace (E →L[𝕜] E') (OneJetSpace I I' : M × M' → Type _)

variable {I I' M M'}

@[inherit_doc] local notation "J¹MM'" => OneJetBundle I M I' M'

@[inherit_doc] local notation "HJ" => ModelProd (ModelProd H H') (E →L[𝕜] E')

omit [IsManifold I ∞ M] [IsManifold I' ∞ M'] in
@[ext]
theorem OneJetBundle.ext {x y : J¹MM'} (h : x.1.1 = y.1.1) (h' : x.1.2 = y.1.2) (h'' : x.2 = y.2) :
    x = y := by
  sorry

variable (I I' M M')

section OneJetBundleInstances

section

variable {M} (p : M × M')

instance (x : M × M') : Module 𝕜 (FJ¹MM' x) := by
  delta OneJetSpace
  infer_instance

end

instance : TopologicalSpace J¹MM' := by
  delta OneJetSpace OneJetBundle
  infer_instance

instance : FiberBundle (E →L[𝕜] E') FJ¹MM' := by
  delta OneJetSpace
  infer_instance

instance : VectorBundle 𝕜 (E →L[𝕜] E') FJ¹MM' := by
  delta OneJetSpace
  infer_instance

instance : ContMDiffVectorBundle ∞ (E →L[𝕜] E')
    (OneJetSpace I I' : M × M' → Type _) (I.prod I') := by
  delta OneJetSpace
  infer_instance

instance : ChartedSpace HJ J¹MM' := by
  delta OneJetSpace OneJetBundle
  infer_instance

instance : IsManifold ((I.prod I').prod 𝓘(𝕜, E →L[𝕜] E')) ∞ J¹MM' := by
  apply Bundle.TotalSpace.isManifold

end OneJetBundleInstances

variable {I M I' M' J J'}

-- Porting note: removed next line
-- attribute [simps] ContMDiffMap.fst ContMDiffMap.snd

theorem trivializationAt_oneJetBundle_target (x₀ : M × M') :
    (trivializationAt (E →L[𝕜] E') FJ¹MM' x₀).target =
      (Prod.fst ⁻¹' (trivializationAt E (TangentSpace I) x₀.1).baseSet ∩
          Prod.snd ⁻¹' (trivializationAt E' (TangentSpace I') x₀.2).baseSet) ×ˢ
        Set.univ := by
  sorry

section

section

universe u v w₁ w₂ U

variable {B : Type u} {F : Type v} {E : B → Type w₁} {B' : Type w₂}
  [TopologicalSpace B'] [TopologicalSpace (TotalSpace F E)]
  [TopologicalSpace F] [TopologicalSpace B] [(_b : B) → Zero (E _b)]
  {K : Type U} [FunLike K B' B] [ContinuousMapClass K B' B]
  [(x : B) → TopologicalSpace (E x)] [FiberBundle F E]

lemma trivializationAt_pullBack_baseSet (f : K) (x : B') :
    (trivializationAt F ((f : B' → B) *ᵖ E) x).baseSet =
    f ⁻¹' (trivializationAt F E (f x)).baseSet := by
  sorry
end

section
variable {𝕜 : Type*} [NontriviallyNormedField 𝕜] {E : Type*}
[NormedAddCommGroup E] [NormedSpace 𝕜 E] {E' : Type*} [NormedAddCommGroup E'] [NormedSpace 𝕜 E']
{H : Type*} [TopologicalSpace H] {H' : Type*} [TopologicalSpace H']
{I : ModelWithCorners 𝕜 E H} {I' : ModelWithCorners 𝕜 E' H'} {M : Type*} [TopologicalSpace M]
[ChartedSpace H M] {M' : Type*} [TopologicalSpace M'] [ChartedSpace H' M'] {n : ℕ∞}

@[simp]
lemma ContMDiffMap.coe_fst :
    ((ContMDiffMap.fst : C^n⟮I.prod I', M × M'; I, M⟯) : M × M' → M) = Prod.fst := by
  sorry

@[simp]
lemma ContMDiffMap.coe_snd :
    ((ContMDiffMap.snd : C^n⟮I.prod I', M × M'; I', M'⟯) : M × M' → M') = Prod.snd := by
  sorry

@[simp]
lemma ContMDiffMap.fst_apply (x : M) (x' : M') :
    (ContMDiffMap.fst : C^n⟮I.prod I', M × M'; I, M⟯) (x, x') = x := by
  sorry

@[simp]
lemma ContMDiffMap.snd_apply (x : M) (x' : M') :
    (ContMDiffMap.snd : C^n⟮I.prod I', M × M'; I', M'⟯) (x, x') = x' := by
  sorry

end

section Maps

theorem contMDiff_oneJetBundle_proj :
    ContMDiff ((I.prod I').prod 𝓘(𝕜, E →L[𝕜] E')) (I.prod I') ∞ (π (E →L[𝕜] E') FJ¹MM') := by
  sorry

theorem ContMDiff.oneJetBundle_proj {f : N → J¹MM'}
    (hf : ContMDiff J ((I.prod I').prod 𝓘(𝕜, E →L[𝕜] E')) ∞ f) :
    ContMDiff J (I.prod I') ∞ fun x ↦ (f x).1 := by
  sorry

theorem ContMDiffAt.oneJetBundle_proj {f : N → J¹MM'} {x₀ : N}
    (hf : ContMDiffAt J ((I.prod I').prod 𝓘(𝕜, E →L[𝕜] E')) ∞ f x₀) :
    ContMDiffAt J (I.prod I') ∞ (fun x ↦ (f x).1) x₀ := by
  sorry

/-- The constructor of `OneJetBundle`, in case `Sigma.mk` will not give the right type. -/
@[simp]
def OneJetBundle.mk (x : M) (y : M') (f : OneJetSpace I I' (x, y)) : J¹MM' :=
  ⟨(x, y), f⟩

omit [IsManifold I ∞ M] [IsManifold I' ∞ M'] in
@[simp, mfld_simps]
theorem oneJetBundle_mk_fst {x : M} {y : M'} {f : OneJetSpace I I' (x, y)} :
    (OneJetBundle.mk x y f).1 = (x, y) := by
  sorry

theorem contMDiffAt_oneJetBundle {f : N → J¹MM'} {x₀ : N} :
    ContMDiffAt J ((I.prod I').prod 𝓘(𝕜, E →L[𝕜] E')) ∞ f x₀ ↔
      CMDiffAt ∞ (fun x ↦ (f x).1.1) x₀ ∧
        CMDiffAt ∞ (fun x ↦ (f x).1.2) x₀ ∧
          ContMDiffAt J 𝓘(𝕜, E →L[𝕜] E') ∞
            (inTangentCoordinates I I' (fun x ↦ (f x).1.1) (fun x ↦ (f x).1.2) (fun x ↦ (f x).2)
              x₀) x₀ := by
  sorry

theorem ContMDiffAt.oneJetBundle_mk {f : N → M} {g : N → M'} {ϕ : N → E →L[𝕜] E'} {x₀ : N}
    (hf : CMDiffAt ∞ f x₀) (hg : CMDiffAt ∞ g x₀)
    (hϕ : ContMDiffAt J 𝓘(𝕜, E →L[𝕜] E') ∞ (inTangentCoordinates I I' f g ϕ x₀) x₀) :
    ContMDiffAt J ((I.prod I').prod 𝓘(𝕜, E →L[𝕜] E')) ∞
      (fun x ↦ OneJetBundle.mk (f x) (g x) (ϕ x) : N → J¹MM') x₀ := by
  sorry

variable (I I')

/-- The one-jet extension of a function -/
def oneJetExt (f : M → M') : M → OneJetBundle I M I' M' := fun x ↦
  OneJetBundle.mk x (f x) (mfderiv% f x)

variable {I I'}

theorem ContMDiffAt.oneJetExt {f : M → M'} {x : M} (hf : CMDiffAt ∞ f x) :
    ContMDiffAt I ((I.prod I').prod 𝓘(𝕜, E →L[𝕜] E')) ∞ (oneJetExt I I' f) x := by
  sorry

theorem ContMDiff.oneJetExt {f : M → M'} (hf : CMDiff ∞ f) :
    ContMDiff I ((I.prod I').prod 𝓘(𝕜, E →L[𝕜] E')) ∞ (oneJetExt I I' f) := by
  sorry

theorem ContMDiffAt.clm_comp_inTangentCoordinates {f : N → M} {g : N → M'} {h : N → N'}
    {ϕ' : N → E' →L[𝕜] F'} {ϕ : N → E →L[𝕜] E'} {n : N} (hg : ContinuousAt g n)
    (hϕ' : ContMDiffAt J 𝓘(𝕜, E' →L[𝕜] F') ∞ (inTangentCoordinates I' J' g h ϕ' n) n)
    (hϕ : ContMDiffAt J 𝓘(𝕜, E →L[𝕜] E') ∞ (inTangentCoordinates I I' f g ϕ n) n) :
    ContMDiffAt J 𝓘(𝕜, E →L[𝕜] F') ∞ (inTangentCoordinates I J' f h (fun n ↦ ϕ' n ∘L ϕ n) n) n := by
  sorry

variable (I')

variable [IsManifold J ∞ N]

omit [IsManifold J' ∞ N'] in

omit [IsManifold J' ∞ N'] in
theorem ContMDiff.oneJet_comp {f1 : N' → M} (f2 : N' → M') {f3 : N' → N}
    {h : ∀ x : N', OneJetSpace I' J (f2 x, f3 x)} {g : ∀ x : N', OneJetSpace I I' (f1 x, f2 x)}
    (hh : ContMDiff J' ((I'.prod J).prod 𝓘(𝕜, E' →L[𝕜] F)) ∞ fun x ↦ OneJetBundle.mk _ _ (h x))
    (hg : ContMDiff J' ((I.prod I').prod 𝓘(𝕜, E →L[𝕜] E')) ∞ fun x ↦ OneJetBundle.mk _ _ (g x)) :
    ContMDiff J' ((I.prod J).prod 𝓘(𝕜, E →L[𝕜] F)) ∞
      (fun x ↦ OneJetBundle.mk (f1 x) (f3 x) (h x ∘L g x) : N' → OneJetBundle I M J N) := by
  sorry

variable {I'}

open Trivialization in
omit [IsManifold J ∞ N] in
theorem ContMDiff.oneJet_add {f : N → M} {g : N → M'} {ϕ ϕ' : ∀ x : N, OneJetSpace I I' (f x, g x)}
    (hϕ : ContMDiff J ((I.prod I').prod 𝓘(𝕜, E →L[𝕜] E')) ∞ fun x ↦ OneJetBundle.mk _ _ (ϕ x))
    (hϕ' : ContMDiff J ((I.prod I').prod 𝓘(𝕜, E →L[𝕜] E')) ∞ fun x ↦ OneJetBundle.mk _ _ (ϕ' x)) :
    ContMDiff J ((I.prod I').prod 𝓘(𝕜, E →L[𝕜] E')) ∞ fun x ↦
      OneJetBundle.mk (f x) (g x) (ϕ x + ϕ' x) := by
  sorry

variable (I' J')

/-- A useful definition to define maps between two `OneJetBundle`s. -/
protected def OneJetBundle.map (f : M → N) (g : M' → N')
    (Dfinv : ∀ x : M, TangentSpace J (f x) →L[𝕜] TangentSpace I x) :
    OneJetBundle I M I' M' → OneJetBundle J N J' N' := fun p ↦
  OneJetBundle.mk (f p.1.1) (g p.1.2) ((mfderiv% g p.1.2 ∘L p.2) ∘L Dfinv p.1.1)

variable {I' J'}

omit [IsManifold I ∞ M] [IsManifold I' ∞ M']
  [IsManifold I₂ ∞ M₂] [IsManifold I₃ ∞ M₃]
  [IsManifold J' ∞ N'] [IsManifold J ∞ N] in
theorem OneJetBundle.map_map {f₂ : N → M₂} {f : M → N} {g₂ : N' → M₃} {g : M' → N'}
    {Dfinv : ∀ x : M, TangentSpace J (f x) →L[𝕜] TangentSpace I x}
    {Df₂inv : ∀ x : N, TangentSpace I₂ (f₂ x) →L[𝕜] TangentSpace J x} {x : J¹MM'}
    (hg₂ : MDifferentiableAt J' I₃ g₂ (g x.1.2)) (hg : MDifferentiableAt I' J' g x.1.2) :
    OneJetBundle.map J' I₃ f₂ g₂ Df₂inv (OneJetBundle.map I' J' f g Dfinv x) =
      OneJetBundle.map I' I₃ (f₂ ∘ f) (g₂ ∘ g) (fun x ↦ Dfinv x ∘L Df₂inv (f x)) x := by
  sorry

omit [IsManifold I ∞ M] [IsManifold I' ∞ M']
  [IsManifold I₂ ∞ M₂] [IsManifold I₃ ∞ M₃]
  [IsManifold J' ∞ N'] [IsManifold J ∞ N] in
theorem OneJetBundle.map_id (x : J¹MM') :
    OneJetBundle.map I' I' id id (fun x ↦ ContinuousLinearMap.id 𝕜 (TangentSpace I x)) x = x := by
  sorry

theorem ContMDiffAt.oneJetBundle_map {f : M'' → M → N} {g : M'' → M' → N'} {x₀ : M''}
    {Dfinv : ∀ (z : M'') (x : M), TangentSpace J (f z x) →L[𝕜] TangentSpace I x} {k : M'' → J¹MM'}
    (hf : ContMDiffAt (I''.prod I) J ∞ f.uncurry (x₀, (k x₀).1.1))
    (hg : ContMDiffAt (I''.prod I') J' ∞ g.uncurry (x₀, (k x₀).1.2))
    (hDfinv :
      ContMDiffAt I'' 𝓘(𝕜, F →L[𝕜] E) ∞
        (inTangentCoordinates J I (fun x ↦ f x (k x).1.1) (fun x ↦ (k x).1.1)
          (fun x ↦ Dfinv x (k x).1.1) x₀)
        x₀)
    (hk : ContMDiffAt I'' ((I.prod I').prod 𝓘(𝕜, E →L[𝕜] E')) ∞ k x₀) :
    ContMDiffAt I'' ((J.prod J').prod 𝓘(𝕜, F →L[𝕜] F')) ∞
      (fun z ↦ OneJetBundle.map I' J' (f z) (g z) (Dfinv z) (k z)) x₀ := by
  sorry

/-- A useful definition to define maps between two `OneJetBundle`s. -/
def mapLeft (f : M → N) (Dfinv : ∀ x : M, TangentSpace J (f x) →L[𝕜] TangentSpace I x) :
    J¹MM' → OneJetBundle J N I' M' := fun p ↦ OneJetBundle.mk (f p.1.1) p.1.2 (p.2 ∘L Dfinv p.1.1)

theorem ContMDiffAt.mapLeft {f : N' → M → N} {x₀ : N'}
    {Dfinv : ∀ (z : N') (x : M), TangentSpace J (f z x) →L[𝕜] TangentSpace I x} {g : N' → J¹MM'}
    (hf : ContMDiffAt (J'.prod I) J ∞ f.uncurry (x₀, (g x₀).1.1))
    (hDfinv :
      ContMDiffAt J' 𝓘(𝕜, F →L[𝕜] E) ∞
        (inTangentCoordinates J I (fun x ↦ f x (g x).1.1) (fun x ↦ (g x).1.1)
          (fun x ↦ Dfinv x (g x).1.1) x₀)
        x₀)
    (hg : ContMDiffAt J' ((I.prod I').prod 𝓘(𝕜, E →L[𝕜] E')) ∞ g x₀) :
    ContMDiffAt J' ((J.prod I').prod 𝓘(𝕜, F →L[𝕜] E')) ∞
      (fun z ↦ mapLeft (f z) (Dfinv z) (g z)) x₀ := by
  sorry

/-- The projection `J¹(E × P, F) → J¹(E, F)`. Not actually used. -/
def bundleFst : OneJetBundle (J.prod I) (N × M) I' M' → OneJetBundle J N I' M' :=
  mapLeft Prod.fst fun _ ↦ ContinuousLinearMap.inl 𝕜 F E

/-- The projection `J¹(P × E, F) → J¹(E, F)`. -/
def bundleSnd : OneJetBundle (J.prod I) (N × M) I' M' → J¹MM' :=
  mapLeft Prod.snd fun x ↦ mfderiv I (J.prod I) (fun y ↦ (x.1, y)) x.2

theorem contMDiff_bundleSnd :
    ContMDiff (((J.prod I).prod I').prod 𝓘(𝕜, F × E →L[𝕜] E')) ((I.prod I').prod 𝓘(𝕜, E →L[𝕜] E'))
      ∞ (bundleSnd : OneJetBundle (J.prod I) (N × M) I' M' → J¹MM') := by
  sorry

-- slow
end Maps

-- move

@[inherit_doc] local notation "𝓜" => ModelProd (ModelProd H H') (E →L[𝕜] E')

/-- In the `OneJetBundle` to the model space, the charts are just the canonical identification
between a product type and a bundle total space type, a.k.a. `Bundle.TotalSpace.toProd`. -/
@[simp, mfld_simps]
theorem oneJetBundle_model_space_chartAt (p : OneJetBundle I H I' H') :
    (chartAt 𝓜 p).toPartialEquiv =
      (Bundle.TotalSpace.toProd (H × H') (E →L[𝕜] E')).toPartialEquiv := by
  sorry

@[simp, mfld_simps]
theorem oneJetBundle_model_space_coe_chartAt (p : OneJetBundle I H I' H') :
    ⇑(chartAt 𝓜 p) = Bundle.TotalSpace.toProd (H × H') (E →L[𝕜] E') := by
  sorry

@[simp, mfld_simps]
theorem oneJetBundle_model_space_coe_chartAt_symm (p : OneJetBundle I H I' H') :
    ((chartAt 𝓜 p).symm : 𝓜 → OneJetBundle I H I' H') =
      (Bundle.TotalSpace.toProd (H × H') (E →L[𝕜] E')).symm := by
  sorry

variable (I I')

-- note: this proof works for all vector bundles where we have proven
-- `∀ p, chartAt _ p = f.toPartialEquiv`
/-- The canonical identification between the one-jet bundle to the model space and the product,
as a homeomorphism -/
def oneJetBundleModelSpaceHomeomorph : OneJetBundle I H I' H' ≃ₜ 𝓜 :=
  { Bundle.TotalSpace.toProd (H × H') (E →L[𝕜] E') with
    continuous_toFun := by
      let p : OneJetBundle I H I' H' := ⟨(I.symm (0 : E), I'.symm (0 : E')), 0⟩
      have : Continuous (chartAt 𝓜 p) := by
        rw [← continuousOn_univ]
        convert OpenPartialHomeomorph.continuousOn _
        simp only [mfld_simps]
      simpa only [mfld_simps] using this
    continuous_invFun := by
      let p : OneJetBundle I H I' H' := ⟨(I.symm (0 : E), I'.symm (0 : E')), 0⟩
      have : Continuous (chartAt 𝓜 p).symm := by
        rw [← continuousOn_univ]
        convert OpenPartialHomeomorph.continuousOn _
        simp only [mfld_simps]
      simpa only [mfld_simps] using this }

-- unused
@[simp, mfld_simps]
theorem oneJetBundleModelSpaceHomeomorph_coe :
    (oneJetBundleModelSpaceHomeomorph I I' : OneJetBundle I H I' H' → 𝓜) =
      Bundle.TotalSpace.toProd (H × H') (E →L[𝕜] E') := by
  sorry

-- unused
@[simp, mfld_simps]
theorem oneJetBundleModelSpaceHomeomorph_coe_symm :
    ((oneJetBundleModelSpaceHomeomorph I I').symm : 𝓜 → OneJetBundle I H I' H') =
      (Bundle.TotalSpace.toProd (H × H') (E →L[𝕜] E')).symm := by
  sorry

end
