import SphereEversion.Global.Relation
import Mathlib.Analysis.Convex.AmpleSet

noncomputable section

open Set Function

open Filter hiding map_smul

open ChartedSpace

open LinearMap (ker)

open scoped Topology Manifold Pointwise ContDiff

section ParameterSpace

/-! ## Fundamental definitions -/

variable {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] {H : Type*} [TopologicalSpace H]
  {I : ModelWithCorners ℝ E H} {M : Type*} [TopologicalSpace M] [ChartedSpace H M]
  [IsManifold I ∞ M] {E' : Type*} [NormedAddCommGroup E'] [NormedSpace ℝ E']
  {H' : Type*} [TopologicalSpace H'] {I' : ModelWithCorners ℝ E' H'} {M' : Type*}
  [TopologicalSpace M'] [ChartedSpace H' M'] [IsManifold I' ∞ M'] {EP : Type*}
  [NormedAddCommGroup EP] [NormedSpace ℝ EP] {HP : Type*} [TopologicalSpace HP]
  {IP : ModelWithCorners ℝ EP HP} {P : Type*} [TopologicalSpace P] [ChartedSpace HP P]
  [IsManifold IP ∞ P] {F : Type*} [NormedAddCommGroup F] [NormedSpace ℝ F]
  {G : Type*} [TopologicalSpace G] {J : ModelWithCorners ℝ F G} {N : Type*} [TopologicalSpace N]
  [ChartedSpace G N] [IsManifold J ∞ N] {EX : Type*} [NormedAddCommGroup EX]
  [NormedSpace ℝ EX] {HX : Type*} [TopologicalSpace HX] {IX : ModelWithCorners ℝ EX HX}
  -- note: X is a metric space
  {X : Type*}
  [MetricSpace X] [ChartedSpace HX X] [IsManifold IX ∞ X]

variable {R : RelMfld I M I' M'}

variable (IP P) in
/-- The relation `𝓡 ^ P` -/
def RelMfld.relativize (R : RelMfld I M I' M') : RelMfld (IP.prod I) (P × M) I' M' :=
  bundleSnd ⁻¹' R

theorem RelMfld.isOpen_relativize (R : RelMfld I M I' M') (h2 : IsOpen R) :
    IsOpen (R.relativize IP P) := by
  sorry

/-
Porting note: the next statement has huge elaboration issue because of defEq abuse.
We force our way using hard type ascription, ie. using `id`.
The following commented out variables and check show the issue.
variable {σ : OneJetBundle (IP.prod I) (P × M) I' M'}
    {p : DualPair <| TangentSpace (IP.prod I) σ.1.1}(q : DualPair <| TangentSpace I σ.1.1.2)

#check  p.v
#check (p.v - (id ((0 : EP), (q.v : E)) : TangentSpace (IP.prod I) σ.proj.1))
#check (R.relativize IP P).slice σ p
#check (R.slice (bundleSnd σ) q : Set <| TangentSpace I' σ.proj.2) -/


variable (IP P) in
theorem FamilyOneJetSec.uncurry_mem_relativize (S : FamilyOneJetSec I M I' M' IP P) {s : P}
    {x : M} : S.uncurry (s, x) ∈ R.relativize IP P ↔ S s x ∈ R := by
  sorry

def FamilyFormalSol.uncurry (S : FamilyFormalSol IP P R) : FormalSol (R.relativize IP P) := by
  refine ⟨S.toFamilyOneJetSec.uncurry, ?_⟩
  rintro ⟨s, x⟩
  exact S.toFamilyOneJetSec.uncurry_mem_relativize.mpr (S.is_sol' s x)

theorem FamilyFormalSol.uncurry_ϕ' (S : FamilyFormalSol IP P R) (p : P × M) :
    S.uncurry.ϕ p =
      mfderiv IP I' (fun z ↦ S.bs z p.2) p.1 ∘L ContinuousLinearMap.fst ℝ EP E +
        S.ϕ p.1 p.2 ∘L ContinuousLinearMap.snd ℝ EP E := by
  sorry

def FamilyOneJetSec.curry (S : FamilyOneJetSec (IP.prod I) (P × M) I' M' J N) :
    FamilyOneJetSec I M I' M' (J.prod IP) (N × P)
    where
  bs p x := (S p.1).bs (p.2, x)
  ϕ p x := (S p.1).ϕ (p.2, x) ∘L mfderiv I (IP.prod I) (fun x ↦ (p.2, x)) x
  contMDiff' := by
    rintro ⟨⟨t, s⟩, x⟩
    refine contMDiffAt_snd.oneJetBundle_mk (S.contMDiff_bs.comp contMDiff_prod_assoc _) ?_
    have h1 :
      ContMDiffAt ((J.prod IP).prod I) 𝓘(ℝ, EP × E →L[ℝ] E') ∞
        (inTangentCoordinates (IP.prod I) I' (fun p : (N × P) × M ↦ (p.1.2, p.2))
          (fun p : (N × P) × M ↦ (S p.1.1).bs (p.1.2, p.2))
          (fun p : (N × P) × M ↦ (S p.1.1).ϕ (p.1.2, p.2)) ((t, s), x))
        ((t, s), x) := by
      apply (contMDiffAt_oneJetBundle.mp <|
        (S.contMDiff (t, (s, x))).comp ((t, s), x) (contMDiff_prod_assoc ((t, s), x))).2.2
    have h2 :
      ContMDiffAt ((J.prod IP).prod I) 𝓘(ℝ, E →L[ℝ] EP × E) ∞
        (inTangentCoordinates I (IP.prod I) Prod.snd (fun p : (N × P) × M ↦ (p.1.2, p.2))
          (fun p : (N × P) × M ↦ mfderiv I (IP.prod I) (fun x : M ↦ (p.1.2, x)) p.2) ((t, s), x))
        ((t, s), x) := by
      apply
        ContMDiffAt.mfderiv (fun (p : (N × P) × M) (x : M) ↦ (p.1.2, x)) Prod.snd
          (contMDiffAt_fst.fst.snd.prodMk contMDiffAt_snd :
            ContMDiffAt (((J.prod IP).prod I).prod I) (IP.prod I) ∞ _ (((t, s), x), x))
          (contMDiffAt_snd : ContMDiffAt ((J.prod IP).prod I) _ ∞ _ _) (mod_cast le_top)
    exact h1.clm_comp_inTangentCoordinates (continuousAt_fst.snd.prodMk continuousAt_snd) h2

theorem FamilyOneJetSec.curry_mem (S : FamilyOneJetSec (IP.prod I) (P × M) I' M' J N) {p : N × P}
    {x : M} (hR : S p.1 (p.2, x) ∈ R.relativize IP P) : S.curry p x ∈ R := by
  sorry

def FamilyFormalSol.curry (S : FamilyFormalSol J N (R.relativize IP P)) :
    FamilyFormalSol (J.prod IP) (N × P) R :=
  ⟨S.toFamilyOneJetSec.curry, fun _p _x ↦ S.toFamilyOneJetSec.curry_mem S.is_sol⟩

theorem curry_eq_iff_eq_uncurry {𝓕 : FamilyFormalSol J N (R.relativize IP P)}
    {𝓕₀ : FamilyFormalSol IP P R} {t : N} {x : M} {s : P} (h : 𝓕 t (s, x) = 𝓕₀.uncurry (s, x)) :
    (𝓕.curry (t, s)) x = 𝓕₀ s x := by
  sorry

theorem RelMfld.SatisfiesHPrinciple.satisfiesHPrincipleWith (R : RelMfld I M IX X) {C : Set (P × M)}
    (ε : M → ℝ) (h : (R.relativize IP P).SatisfiesHPrinciple C fun x ↦ ε x.2) :
    R.SatisfiesHPrincipleWith IP C ε := by
  sorry

end ParameterSpace
