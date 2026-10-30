import Mathlib.LinearAlgebra.Basis.Flag
import Mathlib.LinearAlgebra.FreeModule.PID
import SphereEversion.Loops.Exists
import SphereEversion.Local.Corrugation
import SphereEversion.Local.AmpleRelation

/-!
# Local h-principle for open and ample relations

This file proves `lem:h_principle_open_ample_loc` from the blueprint. This is the local
version of the h-principle for open and ample relations. The proof brings together the
main result `exist_loops` from the loop folder (Chapter 1 in the blueprint) and
the corrugation technique.

One formalization issue is that the whole construction carries around a lot of data.
On paper it is easy to state one lemma listing once all this data and proving many properties.
Here it is more convenient to give each property its own lemma so carrying around data,
assumptions and constructions requires some planning. Our way to mitigate this issue
is to use two ad-hoc structures `Landscape` and `StepLandscape` which partly bundle
all this.

The `Landscape` structure record three sets in a vector space, a closed
set `C` and two nested compact sets `K₀` and `K₁`. This is the ambient data for
the local h-principle result. We call this partly bundled because it doesn't include
the data of the formal solution we want to improve. Instead we have a Prop-valued
structure `Landscape.accepts` that takes a landscape and a formal solution and assert
some compatibility conditions. There are four conditions, which is already enough
motivation to introduce a structure instead of one definition using the logical
conjunction operator that would lead to awkward and error prone access to the
individual conditions.

The proof of this proposition involves an induction on a flag of subspaces (nested
subspaces of increasing dimensions). For the purpose of this induction we use
a second structure `StepLandscape` that extends `Landscape` with two more pieces
of data, a subspace and a dual pair, and a compatibility condition, namely the subspace
has to be in the hyperplane defined by the dual pair.

In this setup, given `(L : StepLandscape E) {𝓕 : FormalSol R} (h : L.accepts R 𝓕)`,
the loop family constructed by Chapter 2 is `L.loop h`. Together with corrugation,
it is used to build `L.improveStep h` which is the homotopy of 1-jet sections improving
the formal solution `𝓕` in that step of the main inductive proof. A rather long series of
lemmas prove all the required properties of that homotopy, corresponding to
lemma `lem:integration_step` from the blueprint.

The inductive proof itself is the proof of `RelLoc.FormalSol.improve`.
Here all conclusions are stated at once this the induction requires to know about each
of them to proceed to the next step. We could have introduced one more ad-hoc structure
to record those conclusion but this isn't needed (at least in that Chapter) since we
need to access its components only once.

-/

noncomputable section

open scoped unitInterval Filter Topology ContDiff

open Filter Set RelLoc

open LinearMap (ker)

variable (E : Type*) [NormedAddCommGroup E] [NormedSpace ℝ E]
  {F : Type*} [NormedAddCommGroup F] [NormedSpace ℝ F]
  {G : Type*} [NormedAddCommGroup G] [NormedSpace ℝ G]

/-- The setup for local h-principle is two compact subsets `K₀ ⊆ K₁` in `E` with
`K₀ ⊆ interior K₁` and a closed subset `C`.
-/
structure Landscape where
  (C K₀ K₁ : Set E)
  hC : IsClosed C
  hK₀ : IsCompact K₀
  hK₁ : IsCompact K₁
  h₀₁ : K₀ ⊆ interior K₁

section ImproveStep

/-!
## Improvement step

This section proves `lem:integration_step`.
-/

/-- The setup for a one-step improvement towards a local h-principle is two compact subsets
`K₀ ⊆ K₁` in `E` with `K₀ ⊆ interior K₁` and a closed subset `C`
together with a dual pair `p` and a subspace `E'` of the corresponding hyperplane `ker p.π`.
-/
structure StepLandscape extends Landscape E where
  E' : Submodule ℝ E
  p : DualPair E
  hEp : E' ≤ p.π.ker

variable {E}

variable (R : RelLoc E F)

namespace StepLandscape

/-- A one-step improvement landscape accepts a formal solution if it can improve it. -/
structure Accepts (L : StepLandscape E) (𝓕 : JetSec E F) : Prop where
  h_op : IsOpen R
  hK₀ : ∀ᶠ x near L.K₀, 𝓕.IsPartHolonomicAt L.E' x
  hShort : ∀ x, 𝓕.IsShortAt R L.p x
  hC : ∀ᶠ x near L.C, 𝓕.IsHolonomicAt x

/-- The union of all slices of `R` corresponding to `𝓕`. -/
def Ω (L : StepLandscape E) (𝓕 : JetSec E F) : Set (E × F) :=
  {p | p.2 ∈ 𝓕.sliceAt R L.p p.1}

-- ⋃ x, ({x} : Set E) ×ˢ (connectedComponentIn (𝓕.sliceAt R L.p x) <| 𝓕.φ x L.p.v)
/-- The linear form in a `StepLandscape`, coming from the underlying dual pair. -/
def π (L : StepLandscape E) : E →L[ℝ] ℝ :=
  L.p.π

/-- The vector in a `StepLandscape`, coming from the underlying dual pair. -/
def v (L : StepLandscape E) : E :=
  L.p.v

/-- One more compact set in the landscape: K₁ ∩ C, needed as an input to the
loop construction. -/
def K (L : StepLandscape E) : Set E :=
  L.K₁ ∩ L.C

/-- The base function for the loop family associated in any jet section in a
step landscape. -/
def b (L : StepLandscape E) (𝓕 : JetSec E F) : E → F := fun x ↦ 𝓕.φ x L.v

/-- The desired average for the loop family associated in any jet section in a
step landscape. -/
def g (L : StepLandscape E) (𝓕 : JetSec E F) : E → F := fun x ↦ D 𝓕.f x L.v

theorem isCompact_K (L : StepLandscape E) : IsCompact L.K := by
  sorry

variable {R}

theorem Accepts.open [FiniteDimensional ℝ E] {L : StepLandscape E} {𝓕 : JetSec E F}
    (h : L.Accepts R 𝓕) : IsOpen (L.Ω R 𝓕) := by
  sorry

theorem smooth_b (L : StepLandscape E) (𝓕 : JetSec E F) : 𝒞 ∞ (L.b 𝓕) := by
  sorry

theorem smooth_g (L : StepLandscape E) (𝓕 : JetSec E F) : 𝒞 ∞ (L.g 𝓕) := by
  sorry

theorem Accepts.rel {L : StepLandscape E} {𝓕 : JetSec E F} (h : L.Accepts R 𝓕) :
    ∀ᶠ x : E near L.K, (L.g 𝓕) x = (L.b 𝓕) x := by
  sorry

variable [FiniteDimensional ℝ E] [FiniteDimensional ℝ F]

open scoped Borelize
variable (L : StepLandscape E) {𝓕 : FormalSol R} (h : L.Accepts R 𝓕)
-- Porting note: the elaboration smiley below was not necessary in Lean 3.
/-- The loop family to use in some landscape to improve a formal solution. -/
def loop (L : StepLandscape E) {𝓕 : FormalSol R} (h : L.Accepts R 𝓕) : ℝ → E → Loop F :=
  Classical.choose <|
    (exist_loops L.isCompact_K h.open (L.smooth_g 𝓕) (L.smooth_b 𝓕):) h.rel h.hShort

theorem nice (L : StepLandscape E) {𝓕 : FormalSol R} (h : L.Accepts R 𝓕) :
    NiceLoop (L.g ↑𝓕) (L.b ↑𝓕) (Ω R L 𝓕) L.K (L.loop h) := by
  sorry

theorem update_zero (L : StepLandscape E) {𝓕 : FormalSol R} (h : L.Accepts R 𝓕) (x : E) (s : ℝ) :
    L.p.update (𝓕.φ x) ((L.loop h 0 x) s) = 𝓕.φ x := by
  sorry

theorem loop_smooth (L : StepLandscape E) {𝓕 : FormalSol R} (h : L.Accepts R 𝓕) : 𝒞 ∞ ↿(L.loop h) := by
  sorry

theorem loop_smooth' (L : StepLandscape E) {𝓕 : FormalSol R} (h : L.Accepts R 𝓕) {t : G → ℝ}
    (ht : 𝒞 ∞ t) {s : G → ℝ} (hs : 𝒞 ∞ s) {x : G → E} (hx : 𝒞 ∞ x) :
    𝒞 ∞ fun g ↦ L.loop h (t g) (x g) (s g) := by
  sorry

theorem loop_C1 (L : StepLandscape E) {𝓕 : FormalSol R} (h : L.Accepts R 𝓕) :
    ∀ t, 𝒞 1 ↿(L.loop h t) := by
  sorry

variable (L : StepLandscape E)

/-- The cut-off function associated to a step landscape, equal to one near K₀ and
zero outside K₁. -/
def ρ (L : StepLandscape E) : E → ℝ :=
  (exists_contDiff_one_nhds_of_interior L.hK₀.isClosed L.h₀₁).choose

theorem ρ_smooth (L : StepLandscape E) : 𝒞 ∞ L.ρ := by
  sorry

/-- Homotopy of formal solutions obtained by corrugation in the direction of `p : dualPair E`
in some landscape to improve a formal solution `𝓕` from being `L.E'`-holonomic to
`L.E' ⊔ span {p.v}`-holonomic near `L.K₀`.
-/
def improveStep {𝓕 : FormalSol R} (h : L.Accepts R 𝓕) (N : ℝ) : HtpyJetSec E F where
  f t x := 𝓕.f x + (smoothStep t * L.ρ x) • corrugation L.π N (L.loop h t) x
  f_diff :=
    𝓕.f_diff.snd'.add <|
      (smoothStep.smooth.fst'.mul L.ρ_smooth.snd').smul <|
        corrugation.contDiff' _ N (L.loop_smooth h) contDiff_snd contDiff_fst
  φ t x :=
    L.p.update (𝓕.φ x) (L.loop h (smoothStep t * L.ρ x) x <| N * L.π x) +
      (smoothStep t * L.ρ x) • corrugation.remainder L.p.π N (L.loop h 1) x
  φ_diff := by
    apply ContDiff.add
    · apply L.p.smooth_update
      · exact 𝓕.φ_diff.snd'
      apply L.loop_smooth'
      · exact smoothStep.smooth.fst'.mul L.ρ_smooth.snd'
      · apply contDiff_const.mul L.π.contDiff.snd'
      · exact contDiff_snd
    · apply ContDiff.fun_smul
      · exact smoothStep.smooth.fst'.mul L.ρ_smooth.snd'
      · exact Remainder.smooth _ _ (L.loop_smooth h) contDiff_snd contDiff_const

variable {L}
variable {𝓕 : FormalSol R} (h : L.Accepts R 𝓕) (N : ℝ)

@[simp]
theorem improveStep_apply (t : ℝ) (x : E) :
    L.improveStep h N t x =
      (𝓕.f x + (smoothStep t * L.ρ x) • corrugation L.π N (L.loop h t) x,
        L.p.update (𝓕.φ x) (L.loop h (smoothStep t * L.ρ x) x <| N * L.π x) +
          (smoothStep t * L.ρ x) • corrugation.remainder L.p.π N (L.loop h 1) x) := by
  sorry

@[simp]
theorem improveStep_apply_f (t : ℝ) (x : E) :
    (L.improveStep h N t).f x = 𝓕.f x + (smoothStep t * L.ρ x) • corrugation L.π N (L.loop h t) x := by
  sorry

@[simp]
theorem improveStep_apply_φ (t : ℝ) (x : E) :
    (L.improveStep h N t).φ x =
      L.p.update (𝓕.φ x) (L.loop h (smoothStep t * L.ρ x) x <| N * L.π x) +
        (smoothStep t * L.ρ x) • corrugation.remainder L.p.π N (L.loop h 1) x := by
  sorry

variable {h N} in
theorem improveStep_of_support {t : ℝ} {x : E} (H : ∀ t, x ∉ Loop.support (L.loop h t)) :
    L.improveStep h N t x = 𝓕 x := by
  sorry

theorem improveStep_rel_t_eq_0 : L.improveStep h N 0 = 𝓕 := by
  sorry

theorem improveStep_rel_compl_K₁ {x} (hx : x ∉ L.K₁) (t) : L.improveStep h N t x = 𝓕 x := by
  sorry

theorem improveStep_rel_K : ∀ᶠ x near L.K, ∀ t, L.improveStep h N t x = 𝓕 x := by
  sorry

theorem improveStep_rel_C : ∀ᶠ x near L.C, ∀ t, L.improveStep h N t x = 𝓕 x := by
  sorry

-- In the next lemma, we reintroduce `F` to appease the unused argument linter
-- since `FiniteDimensional ℝ F` isn't needed here.

theorem improveStep_c0_close {ε : ℝ} (ε_pos : 0 < ε) :
    ∀ᶠ N in atTop, ∀ x t, ‖(L.improveStep h N t).f x - 𝓕.f x‖ ≤ ε := by
  sorry

theorem improveStep_part_hol {N : ℝ} (hN : N ≠ 0) :
    ∀ᶠ x near L.K₀, (L.improveStep h N 1).IsPartHolonomicAt (L.p.spanV ⊔ L.E') x := by
  sorry

theorem improveStep_formalSol : ∀ᶠ N in atTop, ∀ t, (L.improveStep h N t).IsFormalSol R := by
  sorry

end StepLandscape

end ImproveStep

section Improve

/-!
## Full improvement

This section proves `lem:h_principle_open_ample_loc`.
-/

open Submodule StepLandscape

variable {E}
variable [FiniteDimensional ℝ E] [FiniteDimensional ℝ F] {R : RelLoc E F} (h_op : IsOpen R)
  (h_ample : R.IsAmple)

variable (L : Landscape E)

variable {ε : ℝ} (ε_pos : 0 < ε)

include ε_pos h_op h_ample in
/--
Homotopy of formal solutions obtained by successive corrugations in some landscape `L` to improve a
formal solution `𝓕` until it becomes holonomic near `L.K₀`.
-/
theorem RelLoc.FormalSol.improve (𝓕 : FormalSol R) (h_hol : ∀ᶠ x near L.C, 𝓕.IsHolonomicAt x) :
    ∃ H : HtpyJetSec E F,
      (∀ᶠ t near Iic 0, H t = 𝓕) ∧
        (∀ᶠ t near Ici 1, H t = H 1) ∧
          (∀ᶠ x near L.C, ∀ t, H t x = 𝓕 x) ∧
            (∀ x ∉ L.K₁, ∀ t, H t x = 𝓕 x) ∧
              (∀ x t, ‖(H t).f x - 𝓕.f x‖ ≤ ε) ∧
                (∀ t, (H t).IsFormalSol R) ∧ ∀ᶠ x near L.K₀, (H 1).IsHolonomicAt x := by
  sorry

include ε_pos h_op h_ample in
/-- A repackaging of `RelLoc.FormalSol.improve` for convenience. -/
theorem RelLoc.FormalSol.improve_htpy' (𝓕 : FormalSol R)
    (h_hol : ∀ᶠ x near L.C, 𝓕.IsHolonomicAt x) :
    ∃ H : HtpyFormalSol R,
      (∀ᶠ t near Iic 0, H t = 𝓕) ∧
        (∀ᶠ t near Ici 1, H t = H 1) ∧
          (∀ᶠ x near L.C, ∀ t, H t x = 𝓕 x) ∧
            (∀ x ∉ L.K₁, ∀ t, H t x = 𝓕 x) ∧
              (∀ x t, ‖(H t).f x - 𝓕.f x‖ < ε) ∧ ∀ᶠ x near L.K₀, (H 1).IsHolonomicAt x := by
  sorry

end Improve
