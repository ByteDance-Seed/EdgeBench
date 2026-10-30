import Mathlib.Analysis.InnerProductSpace.Basic
import Mathlib.Analysis.SpecialFunctions.SmoothTransition
import SphereEversion.Notations

/-! # Spaces of 1-jets and their sections

For real normed spaces `E` and `F`, this file defines the space `OneJetSec E F` of 1-jets
of maps from `E` to `F` as `E × F × (E →L[ℝ] F)`.

A section `𝓕 : JetSet E F` of this space is a map `(𝓕.f, 𝓕.φ) : E → F × (E →L[ℝ] F)`.

It is holonomic at `x`, spelled `𝓕.IsHolonomicAt x` if the differential of `𝓕.f` at `x`
is `𝓕.φ x`.

We then introduced parametrized families of sections, and especially homotopies of sections,
with type `HtpyJetSec E F` and their concatenation operation `HtpyJetSec.comp`.

Implementation note: the time parameter `t` for homotopies is any real number, but all the
homotopies we will construct will be constant for `t ≤ 0` and `t ≥ 1`. It looks like this imposes
more smoothness constraints at `t = 0` and `t = 1` (requiring flat functions), but this is needed
for smooth concatenations anyway.
 -/

noncomputable section

open Set Function Real Filter

open scoped unitInterval Topology ContDiff

variable (E : Type*) [NormedAddCommGroup E] [NormedSpace ℝ E]
  (F : Type*) [NormedAddCommGroup F] [NormedSpace ℝ F]
  (P : Type*) [NormedAddCommGroup P] [NormedSpace ℝ P]

/-! ## Spaces of 1-jets -/

/-- The space of 1-jets of maps from `E` to `F`. -/
abbrev OneJet :=
  E × F × (E →L[ℝ] F)

instance : MetricSpace (OneJet E F) := inferInstanceAs (MetricSpace (E × F × (E →L[ℝ] F)))

/-- A smooth section of J¹(E, F) → E. -/
@[ext]
structure JetSec where
  f : E → F
  f_diff : 𝒞 ∞ f
  φ : E → E →L[ℝ] F
  φ_diff : 𝒞 ∞ φ

namespace JetSec

variable {E F}

instance : FunLike (JetSec E F) E (F × (E →L[ℝ] F)) where
  coe 𝓕 := fun x ↦ (𝓕.f x, 𝓕.φ x)
  coe_injective' := by
    rintro ⟨⟩ ⟨⟩ h; congr
    exacts [congr_arg (Prod.fst ∘ ·) h, congr_arg (Prod.snd ∘ ·) h]

@[simp]
theorem mk_apply (f : E → F) (f_diff φ φ_diff) (x : E) : mk f f_diff φ φ_diff x = (f x, φ x) := by
  sorry

theorem eq_iff {𝓕 𝓕' : JetSec E F} {x : E} : 𝓕 x = 𝓕' x ↔ 𝓕.f x = 𝓕'.f x ∧ 𝓕.φ x = 𝓕'.φ x := by
  sorry

theorem ext' {𝓕 𝓕' : JetSec E F} (h : ∀ x, 𝓕 x = 𝓕' x) : 𝓕 = 𝓕' := by
  sorry

/-! ## Holonomic sections-/

/-- A jet section `𝓕` is holonomic if its linear map part at `x`
is the derivative of its function part at `x`. -/
def IsHolonomicAt (𝓕 : JetSec E F) (x : E) : Prop :=
  D 𝓕.f x = 𝓕.φ x

/-- A formal solution `𝓕` of `R` is partially holonomic in the direction of some subspace `E'`
if its linear map part at `x` is the derivative of its function part at `x` in restriction to
`E'`. -/
def IsPartHolonomicAt (𝓕 : JetSec E F) (E' : Submodule ℝ E) (x : E) :=
  ∀ v ∈ E', D 𝓕.f x v = 𝓕.φ x v

theorem isPartHolonomicAt_top {𝓕 : JetSec E F} {x : E} :
    IsPartHolonomicAt 𝓕 ⊤ x ↔ IsHolonomicAt 𝓕 x := by
  sorry

end JetSec

/-! ## Homotopies of sections -/

section HtpyJetSec

/-- A parametrized family of sections of J¹(E, F). -/
structure FamilyJetSec where
  f : P → E → F
  f_diff : 𝒞 ∞ ↿f
  φ : P → E → E →L[ℝ] F
  φ_diff : 𝒞 ∞ ↿φ

/-- A homotopy of sections of J¹(E, F). -/
@[reducible]
def HtpyJetSec :=
  FamilyJetSec E F ℝ

variable {E F P}

namespace FamilyJetSec

instance : FunLike (FamilyJetSec E F P) P (JetSec E F) where
  coe S t :=
    { f := S.f t
      f_diff := S.f_diff.comp (contDiff_const.prodMk contDiff_id)
      φ := S.φ t
      φ_diff := S.φ_diff.comp (contDiff_const.prodMk contDiff_id) }
  coe_injective' := by
    rintro ⟨⟩ ⟨⟩ h
    simp only [funext_iff, DFunLike.ext_iff, JetSec.mk_apply, Prod.ext_iff] at h
    congr <;> ext <;> simp [h]

@[simp] theorem mk_apply_apply (f : P → E → F) (f_diff φ φ_diff t x) :
    mk f f_diff φ φ_diff t x = (f t x, φ t x) := by
  sorry

@[simp] theorem mk_apply_f (f : P → E → F) (f_diff φ φ_diff t) :
    (mk f f_diff φ φ_diff t).f = f t := by
  sorry

@[simp] theorem mk_apply_φ (f : P → E → F) (f_diff φ φ_diff t) :
    (mk f f_diff φ φ_diff t).φ = φ t := by
  sorry

theorem contDiff_f (𝓕 : FamilyJetSec E F P) {n : ℕ∞} : 𝒞 n ↿𝓕.f := by
  sorry

theorem contDiff_φ (𝓕 : FamilyJetSec E F P) {n : ℕ∞} : 𝒞 n ↿𝓕.φ := by
  sorry

end FamilyJetSec

/-- The constant homotopy of formal solutions at a given formal solution. It will be used
as junk value for constructions of formal homotopies that need additional assumptions and also
for trivial induction initialization. -/
def JetSec.constHtpy (𝓕 : JetSec E F) : HtpyJetSec E F where
  f _ := 𝓕.f
  f_diff := 𝓕.f_diff.snd'
  φ _ := 𝓕.φ
  φ_diff := 𝓕.φ_diff.snd'

/-! ## Concatenation of homotopies of sections

In this part of the file we build a concatenation operation for homotopies of 1-jet sections.
We first need to introduce a smooth step function on `ℝ`. There is already a version
of this in mathlib called `smooth_transition` but that version is not locally constant
near `0` and `1`, which is not convenient enough for gluing purposes.
-/

/-- A smooth step function on `ℝ`. -/
def smoothStep : ℝ → ℝ := fun t ↦ smoothTransition (2 * t - 1 / 2)

theorem smoothStep.smooth : 𝒞 ∞ smoothStep := by
  sorry

theorem smoothStep.of_lt {t : ℝ} (h : t < 1 / 4) : smoothStep t = 0 := by
  sorry

-- unused
theorem smoothStep.pos_of_gt {t : ℝ} (h : 1 / 4 < t) : 0 < smoothStep t := by
  sorry

theorem smoothStep.of_gt {t : ℝ} (h : 3 / 4 < t) : smoothStep t = 1 := by
  sorry

theorem htpy_jet_sec_comp_aux {f g : ℝ → E → F} (hf : 𝒞 ∞ ↿f) (hg : 𝒞 ∞ ↿g) (hfg : f 1 = g 0) :
    𝒞 ∞ ↿(fun t x ↦ if t ≤ 1 / 2 then f (smoothStep <| 2 * t) x
      else g (smoothStep <| 2 * t - 1) x : ℝ → E → F) := by
  sorry

/-- Concatenation of homotopies of formal solution. The result depend on our choice of
a smooth step function in order to keep smoothness with respect to the time parameter. -/
def HtpyJetSec.comp (𝓕 𝓖 : HtpyJetSec E F) (h : 𝓕 1 = 𝓖 0) : HtpyJetSec E F where
  f t x := if t ≤ 1 / 2 then 𝓕.f (smoothStep <| 2 * t) x else 𝓖.f (smoothStep <| 2 * t - 1) x
  f_diff := htpy_jet_sec_comp_aux 𝓕.f_diff 𝓖.f_diff (show (𝓕 1).f = (𝓖 0).f by rw [h])
  φ t x := if t ≤ 1 / 2 then 𝓕.φ (smoothStep <| 2 * t) x else 𝓖.φ (smoothStep <| 2 * t - 1) x
  φ_diff := htpy_jet_sec_comp_aux 𝓕.φ_diff 𝓖.φ_diff (show (𝓕 1).φ = (𝓖 0).φ by rw [h])

-- unused
-- @[simp] can prove this
theorem HtpyJetSec.comp_0 (𝓕 𝓖 : HtpyJetSec E F) (h) : 𝓕.comp 𝓖 h 0 = 𝓕 0 := by
  sorry

end HtpyJetSec
