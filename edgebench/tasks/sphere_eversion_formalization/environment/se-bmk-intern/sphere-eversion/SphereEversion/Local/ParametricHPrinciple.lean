import SphereEversion.Local.HPrinciple
import SphereEversion.ToMathlib.Topology.Algebra.Module

/-!
In this file we prove the parametric version of the local h-principle.

We will not use this to prove the global version of the h-principle, but we do use this to conclude
the existence of sphere eversion from the local h-principle, which is proven in `Local.HPrinciple`.

The parametric h-principle states the following: Suppose that `R` is a local relation,
`𝓕₀ : P → J¹(E, F)` is a family of formal solutions of `R` that is holonomic near some set
`C ⊆ P × E`, `K ⊆ P × E` is compact and `ε : ℝ`,
then there exists a homotopy `𝓕 : ℝ × P → J¹(E, F)` between `𝓕` and a solution that is holonomic
near `K`, that agrees with `𝓕₀` near `C` and is everywhere `ε`-close to `𝓕₀`
-/

noncomputable section

open Metric FiniteDimensional Set Function RelLoc

open LinearMap (ker)

open scoped Topology Pointwise ContDiff

section ParameterSpace

variable {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
  {F : Type*} [NormedAddCommGroup F] [NormedSpace ℝ F]
  -- `G` will be `ℝ` in the proof of the parametric h-principle.
  -- It indicates the homotopy variable `t`.
  {G : Type*}
  [NormedAddCommGroup G] [NormedSpace ℝ G] {P : Type*} [NormedAddCommGroup P] [NormedSpace ℝ P]

variable {R : RelLoc E F}

/-- The projection `J¹(P × E, F) → J¹(E, F)`. -/
def oneJetSnd : OneJet (P × E) F → OneJet E F := fun p ↦
  (p.1.2, p.2.1, p.2.2 ∘L fderiv ℝ (fun y ↦ (p.1.1, y)) p.1.2)

variable (P)

/-- The relation `R.relativize P` (`𝓡 ^ P` in the blueprint) is the relation on `J¹(P × E, F)`
induced by `R`. -/
def RelLoc.relativize (R : RelLoc E F) : RelLoc (P × E) F :=
  oneJetSnd ⁻¹' R

variable {P} (R)

variable {R}

variable (P)

variable {P}

/-- Turn a family of sections of `J¹(E, E')` parametrized by `P` into a section of `J¹(P × E, E')`.
-/
@[simps]
def FamilyJetSec.uncurry (S : FamilyJetSec E F P) : JetSec (P × E) F where
  f p := S.f p.1 p.2
  φ p := fderiv ℝ (fun z : P × E ↦ S.f z.1 p.2) p + S.φ p.1 p.2 ∘L fderiv ℝ Prod.snd p
  f_diff := S.f_diff
  φ_diff := by
    refine (ContDiff.fderiv ?_ contDiff_id (m := ∞) le_rfl).add (S.φ_diff.clm_comp ?_)
    · exact S.f_diff.comp (contDiff_snd.fst.prodMk contDiff_fst.snd)
    · exact ContDiff.fderiv contDiff_snd.snd contDiff_id le_top

open ContinuousLinearMap
theorem FamilyJetSec.uncurry_mem_relativize (S : FamilyJetSec E F P) {s : P} {x : E} :
    ((s, x), S.uncurry (s, x)) ∈ R.relativize P ↔ (x, S s x) ∈ R := by
  sorry

/-- Turn a family of formal solutions of `R ⊆ J¹(E, E')` parametrized by `P` into a formal solution
of `R.relativize P`. -/
def RelLoc.FamilyFormalSol.uncurry (S : R.FamilyFormalSol P) : FormalSol (R.relativize P) := by
  refine ⟨S.toFamilyJetSec.uncurry, ?_⟩
  rintro ⟨s, x⟩
  exact S.toFamilyJetSec.uncurry_mem_relativize.mpr (S.is_sol s x)

/-- Turn a family of sections of `J¹(P × E, F)` parametrized by `G` into a family of sections of
`J¹(E, F)` parametrized by `G × P`. -/
def FamilyJetSec.curry (S : FamilyJetSec (P × E) F G) : FamilyJetSec E F (G × P) where
  f p x := (S p.1).f (p.2, x)
  φ p x := (S p.1).φ (p.2, x) ∘L fderiv ℝ (fun x ↦ (p.2, x)) x
  f_diff := S.f_diff.comp ((contDiff_prodAssoc : ContDiff ℝ ω (Equiv.prodAssoc G P E)).of_le le_top)
  φ_diff := by
    refine (S.φ_diff.comp
      ((contDiff_prodAssoc : ContDiff ℝ ω (Equiv.prodAssoc G P E)).of_le le_top)).clm_comp ?_
    refine ContDiff.fderiv ?_ contDiff_snd le_top
    exact contDiff_fst.fst.snd.prodMk contDiff_snd

theorem FamilyJetSec.curry_mem (S : FamilyJetSec (P × E) F G) {p : G × P} {x : E}
    (hR : ((p.2, x), S p.1 (p.2, x)) ∈ R.relativize P) : (x, S.curry p x) ∈ R := by
  sorry

/-- Turn a family of formal solutions of `R.relativize P` parametrized by `G` into a family of
formal solutions of `R` parametrized by `G × P`. -/
def RelLoc.FamilyFormalSol.curry (S : FamilyFormalSol G (R.relativize P)) :
    FamilyFormalSol (G × P) R :=
  ⟨S.toFamilyJetSec.curry, fun _ _ ↦ S.toFamilyJetSec.curry_mem (S.is_sol _ _)⟩

theorem RelLoc.FamilyFormalSol.curry_φ (S : FamilyFormalSol G (R.relativize P)) (p : G × P)
    (x : E) : (S.curry p).φ x = (S p.1).φ (p.2, x) ∘L fderiv ℝ (fun x ↦ (p.2, x)) x := by
  sorry

end ParameterSpace

section ParametricHPrinciple

variable {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] [FiniteDimensional ℝ E] {F : Type*}
  [NormedAddCommGroup F] [NormedSpace ℝ F] [FiniteDimensional ℝ F] {G : Type*}
  [NormedAddCommGroup G] [NormedSpace ℝ G] {P : Type*} [NormedAddCommGroup P] [NormedSpace ℝ P]
  [FiniteDimensional ℝ P]

variable {R : RelLoc E F} (h_op : IsOpen R) (h_ample : R.IsAmple) (L : Landscape E)

include h_op h_ample in
-- The local parametric h-principle.
theorem RelLoc.FamilyFormalSol.improve_htpy {ε : ℝ} (ε_pos : 0 < ε) (C : Set (P × E))
    (hC : IsClosed C) (K : Set (P × E)) (hK : IsCompact K) (𝓕₀ : FamilyFormalSol P R)
    (h_hol : ∀ᶠ p : P × E near C, (𝓕₀ p.1).IsHolonomicAt p.2) :
    ∃ 𝓕 : FamilyFormalSol (ℝ × P) R,
      (∀ s x, 𝓕 (0, s) x = 𝓕₀ s x) ∧
        (∀ᶠ p : P × E near C, ∀ t, 𝓕 (t, p.1) p.2 = 𝓕₀ p.1 p.2) ∧
          (∀ s x t, ‖(𝓕 (t, s)).f x - 𝓕₀.f s x‖ ≤ ε) ∧
            ∀ᶠ p : P × E near K, (𝓕 (1, p.1)).IsHolonomicAt p.2 := by
  sorry

open Filter

open scoped unitInterval

include h_op h_ample in
/-- A corollary of the local parametric h-principle, forgetting the homotopy and `ε`-closeness,
and just stating the existence of a solution that is holonomic near `K`.
Furthermore, we assume that `P = ℝ` and `K` is of the form `compact set × I`.
This is sufficient to prove sphere eversion. -/
theorem RelLoc.HtpyFormalSol.exists_sol (𝓕₀ : R.HtpyFormalSol) (C : Set (ℝ × E)) (hC : IsClosed C)
    (K : Set E) (hK : IsCompact K) (h_hol : ∀ᶠ p : ℝ × E near C, (𝓕₀ p.1).IsHolonomicAt p.2) :
    ∃ f : ℝ → E → F,
      (𝒞 ∞ <| uncurry f) ∧
        (∀ p ∈ C, f (p : ℝ × E).1 p.2 = (𝓕₀ p.1).f p.2) ∧
          ∀ x ∈ K, ∀ t ∈ I, (x, f t x, D (f t) x) ∈ R := by
  sorry

end ParametricHPrinciple
