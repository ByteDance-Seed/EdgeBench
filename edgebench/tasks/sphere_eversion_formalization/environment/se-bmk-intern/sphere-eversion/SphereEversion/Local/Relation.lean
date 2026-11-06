import Mathlib.Topology.MetricSpace.HausdorffDistance
import SphereEversion.Local.OneJet

/-!
# Local partial differential relations and their formal solutions

This file defines `RelLoc E F`, the type of first order partial differential relations
for maps between two real normed spaces `E` and `F`.

To any `R : RelLoc E F` we associate the type `sol R` of maps `f : E → F` of
solutions of `R`, and its formal counterpart `FormalSol R`.
(FIXME(grunweg): `sol` is never mentioned; is this docstring outdated?)

The h-principle question is whether we can deform any formal solution into a solution.
The type of deformations is `HtpyJetSet E F` (homotopies of 1-jet sections).
-/

noncomputable section

open Set Function Real Filter

open scoped unitInterval Topology

variable (E : Type*) [NormedAddCommGroup E] [NormedSpace ℝ E]
  (F : Type*) [NormedAddCommGroup F] [NormedSpace ℝ F]
  (P : Type*) [NormedAddCommGroup P] [NormedSpace ℝ P]

/-- A first order relation for maps between real vector spaces. -/
abbrev RelLoc :=
  Set (OneJet E F)

instance : Membership (E × F × (E →L[ℝ] F)) (RelLoc E F) := by delta RelLoc; infer_instance

variable {E F}

/-- A predicate stating that a 1-jet section is a formal solution to a first order relation for
maps between vector spaces. -/
def JetSec.IsFormalSol (𝓕 : JetSec E F) (R : RelLoc E F) : Prop :=
  ∀ x, (x, 𝓕.f x, 𝓕.φ x) ∈ R

namespace RelLoc

/-- A formal solution to a local relation `R`. -/
@[ext]
structure FormalSol (R : RelLoc E F) extends JetSec E F where
  is_sol : ∀ x, (x, f x, φ x) ∈ R

attribute [coe] FormalSol.toJetSec

instance (R : RelLoc E F) : CoeOut (FormalSol R) (JetSec E F) :=
  ⟨FormalSol.toJetSec⟩

-- Note: syntactic tautology
@[simp]
theorem FormalSol.toJetSec_eq_coe {R : RelLoc E F} (𝓕 : FormalSol R) :
    𝓕.toJetSec = (𝓕 : JetSec E F) := by
  sorry

@[simp]
theorem FormalSol.coeIsFormalSol {R : RelLoc E F} (𝓕 : FormalSol R) :
    (𝓕 : JetSec E F).IsFormalSol R := by
  sorry

/-- Bundling a formal solution from a 1-jet section that is a formal solution. -/
def _root_.JetSec.IsFormalSol.formalSol {𝓕 : JetSec E F} {R : RelLoc E F} (h : 𝓕.IsFormalSol R) :
    FormalSol R :=
  { 𝓕 with is_sol := h }

instance (R : RelLoc E F) : FunLike (FormalSol R) E (F × (E →L[ℝ] F)) :=
  ⟨fun 𝓕 x ↦ (𝓕.f x, 𝓕.φ x),
  by
     intros 𝓕 𝓕' h
     ext x : 2 <;> replace h := Prod.mk_inj.mp <| congrFun h x
     exacts [h.1, h.2]⟩

@[simp]
theorem FormalSol.coe_apply {R : RelLoc E F} (𝓕 : FormalSol R) (x : E) : (𝓕 : JetSec E F) x = 𝓕 x := by
  sorry

variable {R : RelLoc E F}

theorem FormalSol.eq_iff {𝓕 𝓕' : FormalSol R} {x : E} :
    𝓕 x = 𝓕' x ↔ 𝓕.f x = 𝓕'.f x ∧ 𝓕.φ x = 𝓕'.φ x := by
  sorry

/-- A formal solution (f, φ) is holonomic at `x` if the differential of `f` at `x` is `φ x`. -/
def FormalSol.IsHolonomicAt (𝓕 : FormalSol R) (x : E) : Prop :=
  D 𝓕.f x = 𝓕.φ x

-- TODO: this should come from a lemma about `JetSec`

/-- A family of formal solutions is a 1-parameter family of formal solutions. -/
@[ext]
structure FamilyFormalSol (R : RelLoc E F) extends FamilyJetSec E F P where
  is_sol : ∀ t x, (x, f t x, φ t x) ∈ R

/-- A homotopy of formal solutions is a 1-parameter family of formal solutions. -/
@[reducible]
def HtpyFormalSol (R : RelLoc E F) :=
  R.FamilyFormalSol ℝ

def HtpyFormalSol.toHtpyJetSec {R : RelLoc E F} (𝓕 : R.HtpyFormalSol) : HtpyJetSec E F :=
  𝓕.toFamilyJetSec

open RelLoc

instance (R : RelLoc E F) : FunLike (FamilyFormalSol P R) P (JetSec E F) :=
  ⟨fun S ↦ S.toFamilyJetSec, by
      intros S S' h
      ext p x : 3 <;> replace h := congrFun h p
      exacts [congrFun (JetSec.ext_iff.1 h).1 x, congrFun (JetSec.ext_iff.1 h).2 x]⟩

end RelLoc
