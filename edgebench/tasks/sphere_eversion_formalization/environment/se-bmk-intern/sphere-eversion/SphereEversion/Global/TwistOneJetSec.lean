/-
Copyright (c) 2022 Heather Macbeth. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Heather Macbeth

! This file was ported from Lean 3 source module global.twist_one_jet_sec
-/
import SphereEversion.Global.OneJetSec

noncomputable section

open Set Equiv Bundle ContinuousLinearMap

open scoped Manifold Bundle Topology ContDiff

section ArbitraryField
universe u v

variable {𝕜 : Type*} [NontriviallyNormedField 𝕜] {E : Type u} [NormedAddCommGroup E]
  [NormedSpace 𝕜 E] {H : Type*} [TopologicalSpace H] (I : ModelWithCorners 𝕜 E H) (M : Type*)
  [TopologicalSpace M] [ChartedSpace H M] [IsManifold I ∞ M] {F : Type*}
  [NormedAddCommGroup F] [NormedSpace 𝕜 F] {G : Type*} [TopologicalSpace G]
  {J : ModelWithCorners 𝕜 F G} {N : Type*} [TopologicalSpace N] [ChartedSpace G N]
  (V : Type*) [NormedAddCommGroup V] [NormedSpace 𝕜 V]
  (V' : Type*) [NormedAddCommGroup V'] [NormedSpace 𝕜 V']

section Smoothness

notation "J¹[" 𝕜 ", " E ", " I ", " M ", " V "]" => TotalSpace (E →L[𝕜] V)
  (fun b ↦ (TangentSpace I : M → _) b →L[𝕜] (Bundle.Trivial M V) b)
variable {I M V}
variable {f : N → J¹[𝕜, E, I, M, V]}

-- todo: remove or use to prove `contMDiff_one_jet_eucl_bundle`
theorem contMDiffAt_one_jet_eucl_bundle' {x₀ : N} :
    ContMDiffAt J (I.prod 𝓘(𝕜, E →L[𝕜] V)) ∞ f x₀ ↔ CMDiffAt ∞ (fun x  ↦ (f x).1) x₀ ∧
    ContMDiffAt J 𝓘(𝕜, E →L[𝕜] V) ∞ (fun x  ↦ show E →L[𝕜] V from
      (f x).2 ∘L (trivializationAt E (TangentSpace I : M → _) (f x₀).1).symmL 𝕜 (f x).1) x₀ := by
  sorry

theorem ContMDiffAt.one_jet_eucl_bundle_mk' {f : N → M} {ϕ : N → E →L[𝕜] V} {x₀ : N}
    (hf : CMDiffAt ∞ f x₀)
    (hϕ : ContMDiffAt J 𝓘(𝕜, E →L[𝕜] V) ∞ (fun x ↦ show E →L[𝕜] V from
            ϕ x ∘L (trivializationAt E (TangentSpace I : M → _) (f x₀)).symmL 𝕜 (f x)) x₀) :
    ContMDiffAt J (I.prod 𝓘(𝕜, E →L[𝕜] V)) ∞
      (fun x ↦ Bundle.TotalSpace.mk (f x) (ϕ x) : N → J¹[𝕜, E, I, M, V]) x₀ := by
  sorry

end Smoothness

section Sections

/-- A section of a 1-jet bundle seen as a bundle over the source manifold. -/
@[ext]
structure OneJetEuclSec where
  toFun : M → J¹[𝕜, E, I, M, V]
  is_sec' : ∀ p, (toFun p).1 = p
  contMDiff' : ContMDiff I (I.prod 𝓘(𝕜, E →L[𝕜] V)) ∞ toFun

variable {I M V}

instance : DFunLike (OneJetEuclSec I M V) M fun _  ↦ J¹[𝕜, E, I, M, V] where
  coe := OneJetEuclSec.toFun
  coe_injective' := by
    intro S T h
    ext x <;> rw [h]

@[simp]
theorem OneJetEuclSec.is_sec (s : OneJetEuclSec I M V) (p : M) : (s p).1 = p := by
  sorry

@[simp]
theorem OneJetEuclSec.contMDiff (s : OneJetEuclSec I M V) :
    ContMDiff I (I.prod 𝓘(𝕜, E →L[𝕜] V)) ∞ s := by
  sorry

end Sections

section proj

instance piBugInstanceRestatement (x : M) : TopologicalSpace
    (TangentSpace I x →L[𝕜] Trivial M V x) := by
  infer_instance

instance piBugInstanceRestatement2 (x : M × V) : TopologicalSpace (OneJetSpace I 𝓘(𝕜, V) x) := by
  infer_instance

/- Given a smooth manifold `M` and a normed space `V`, there is a canonical projection from the
one-jet bundle of maps from `M` to `V` to the bundle of homomorphisms from `TM` to `V`. This is
constructed using the fact that each tangent space to `V` is canonically isomorphic to `V`. -/
def proj (v : OneJetBundle I M 𝓘(𝕜, V) V) : J¹[𝕜, E, I, M, V] :=
  ⟨v.1.1, v.2⟩

theorem contMDiff_proj : ContMDiff ((I.prod 𝓘(𝕜, V)).prod 𝓘(𝕜, E →L[𝕜] V)) (I.prod 𝓘(𝕜, E →L[𝕜] V))
    ∞ (proj I M V) := by
  sorry

variable {I M V}

def drop (s : OneJetSec I M 𝓘(𝕜, V) V) : OneJetEuclSec I M V where
  toFun := (proj I M V).comp s
  is_sec' _ := rfl
  contMDiff' := (contMDiff_proj I M V).comp s.contMDiff

end proj

section incl

/- Given a smooth manifold `M` and a normed space `V`, there is a canonical map from the
the product with V of the bundle of homomorphisms from `TM` to `V` to the one-jet bundle of maps
from `M` to `V`. In fact this map is a diffeomorphism.  This is constructed using the fact that each
tangent space to `V` is canonically isomorphic to `V`. -/
def incl (v : J¹[𝕜, E, I, M, V] × V) : OneJetBundle I M 𝓘(𝕜, V) V :=
  ⟨(v.1.1, v.2), v.1.2⟩

theorem contMDiff_incl : ContMDiff ((I.prod 𝓘(𝕜, E →L[𝕜] V)).prod 𝓘(𝕜, V))
    ((I.prod 𝓘(𝕜, V)).prod 𝓘(𝕜, E →L[𝕜] V)) ∞ (incl I M V) := by
  sorry

omit [IsManifold I ∞ M] in
@[simp]
theorem incl_fst_fst (v : J¹[𝕜, E, I, M, V] × V) : (incl I M V v).1.1 = v.1.1 := by
  sorry

omit [IsManifold I ∞ M] in
@[simp]
theorem incl_snd (v : J¹[𝕜, E, I, M, V] × V) : (incl I M V v).1.2 = v.2 := by
  sorry

end incl

end ArbitraryField

section familyTwist

variable {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] {H : Type*} [TopologicalSpace H]
  (I : ModelWithCorners ℝ E H) (M : Type*) [TopologicalSpace M] [ChartedSpace H M]
  [IsManifold I ∞ M] (V : Type*) [NormedAddCommGroup V] [NormedSpace ℝ V]
  (V' : Type*) [NormedAddCommGroup V'] [NormedSpace ℝ V'] {F : Type*} [NormedAddCommGroup F]
  [NormedSpace ℝ F] {G : Type*} [TopologicalSpace G] (J : ModelWithCorners ℝ F G) (N : Type*)
  [TopologicalSpace N] [ChartedSpace G N]

/-- A section of a 1-jet bundle seen as a bundle over the source manifold. -/
@[ext]
structure FamilyOneJetEuclSec where
  toFun : N × M → J¹[ℝ, E, I, M, V]
  is_sec' : ∀ p, (toFun p).1 = p.2
  contMDiff' : ContMDiff (J.prod I) (I.prod 𝓘(ℝ, E →L[ℝ] V)) ∞ toFun

instance : FunLike (FamilyOneJetEuclSec I M V J N) (N × M) J¹[ℝ, E, I, M, V] where
  coe := FamilyOneJetEuclSec.toFun
  coe_injective' := by
    intro S T h
    ext x <;> rw [h]

variable {I M V J N}

@[simp]
theorem FamilyOneJetEuclSec.is_sec (s : FamilyOneJetEuclSec I M V J N) (p : N × M) :
    (s p).1 = p.2 := by
  sorry

@[simp]
theorem FamilyOneJetEuclSec.contMDiff (s : FamilyOneJetEuclSec I M V J N) :
    ContMDiff (J.prod I) (I.prod 𝓘(ℝ, E →L[ℝ] V)) ∞ s := by
  sorry

variable {V'}

def familyJoin {f : N × M → V} (hf : ContMDiff (J.prod I) 𝓘(ℝ, V) ∞ f)
    (s : FamilyOneJetEuclSec I M V J N) : FamilyOneJetSec I M 𝓘(ℝ, V) V J N
    where
  bs n m := (incl I M V (s (n, m), f (n, m))).1.2
  ϕ n m := (incl I M V (s (n, m), f (n, m))).2
  contMDiff' := by
    convert (contMDiff_incl I M V).comp (s.contMDiff.prodMk hf)
    ext : 1 <;> simp

def familyTwist (s : OneJetEuclSec I M V) (i : N × M → V →L[ℝ] V')
    (hi : ∀ x₀ : N × M, ContMDiffAt (J.prod I) 𝓘(ℝ, V →L[ℝ] V') ∞ i x₀) :
    FamilyOneJetEuclSec I M V' J N
    where
  toFun p := ⟨p.2, (i p).comp (s p.2).2⟩
  is_sec' p := rfl
  contMDiff' := by
    refine fun x₀ ↦ contMDiffAt_snd.one_jet_eucl_bundle_mk' ?_
    simp_rw [ContinuousLinearMap.comp_assoc]
    have : ContMDiffAt (J.prod I) _ ∞ (fun x : N × M  ↦ _) x₀ := s.contMDiff.comp contMDiff_snd x₀
    rw [contMDiffAt_one_jet_eucl_bundle'] at this
    refine (hi x₀).clm_comp ?_
    convert this.2 <;> simp [s.is_sec]

end familyTwist
