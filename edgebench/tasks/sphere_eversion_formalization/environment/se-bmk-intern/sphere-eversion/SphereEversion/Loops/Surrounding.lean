import SphereEversion.InductiveConstructions
import SphereEversion.Loops.Basic
import SphereEversion.ToMathlib.ExistsOfConvex
import SphereEversion.ToMathlib.SmoothBarycentric
import SphereEversion.ToMathlib.Topology.Path
import Mathlib.Analysis.Convex.Caratheodory
import Mathlib.Analysis.Normed.Module.FiniteDimension

/-!
# Surrounding families of loops

In order to carry out the corrugation technique of convex integration, one needs to a family of
loops with various prescribed properties.

This file begins the work of constructing such a family.

The key definitions are:
 * `Surrounded`
 * `SurroundingPts`
 * `SurroundingFamily`

The key results are:
 * `surrounded_iff_mem_interior_convexHull_aff_basis`
 * `surrounded_of_convexHull`
 * `smooth_surrounding`
 * `eventually_surroundingPts_of_tendsto_of_tendsto`
 * `surrounding_loop_of_convexHull`
 * `local_loops`
 * `satisfied_or_refund`
 * `extend_loops`
 * `exists_surrounding_loops`
-/

-- to obtain that normed spaces are locally connected
open Set Function Module Int Prod Path Filter
open scoped Topology unitInterval ContDiff

namespace IsPathConnected

-- we redo `exists_path_through_family` to use `def`s
variable {X : Type*} [TopologicalSpace X] {F : Set X}

/-- An arbitrary path joining `x` and `y` in `F`. -/
noncomputable def somePath (hF : IsPathConnected F) {x y : X} (hx : x ∈ F) (hy : y ∈ F) :
    Path x y :=
  (hF.joinedIn x hx y hy).somePath

theorem range_somePath_subset (hF : IsPathConnected F) {x y : X} (hx : x ∈ F) (hy : y ∈ F) :
    range (hF.somePath hx hy) ⊆ F := by
  sorry

open Fin.NatCast in -- TODO: fix this
/-- A path through `p 0`, ..., `p n`. Usually this is used with `n := m`. -/
noncomputable def pathThrough (hF : IsPathConnected F) {m : ℕ} {p : Fin (m + 1) → X}
    (hp : ∀ i, p i ∈ F) : ∀ n : ℕ, Path (p 0) (p n)
  | 0 => Path.refl (p 0)
  | n + 1 => (pathThrough hF hp n).trans <| hF.somePath (hp _) (hp _)

attribute [simp] Path.trans_range

end IsPathConnected

noncomputable section

variable {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] {F : Type*} [NormedAddCommGroup F]
  [NormedSpace ℝ F]

set_option hygiene false
@[inherit_doc] local notation "d" => finrank ℝ F
set_option hygiene true

/-
The definition below gets a prime because it clashes with a manifold definition
in mathlib which is in the root namespace.
XXX: this is no longer true.
-/
/-- `f` is smooth at `x` if `f` is smooth on some neighborhood of `x`. -/
def SmoothAt' (f : E → F) (x : E) : Prop :=
  ∃ s ∈ 𝓝 x, ContDiffOn ℝ ∞ f s

section SurroundingPoints

set_option hygiene false
@[inherit_doc] local notation "ι" => Fin (d + 1)
set_option hygiene true

-- def:surrounds_points
/-- `p` is a collection of points surrounding `f` with weights `w` (that are positive and sum to 1)
if the weighted average of the points `p` is `f` and the points `p` form an affine basis of the
space. -/
structure SurroundingPts (f : F) (p : ι → F) (w : ι → ℝ) : Prop where
  indep : AffineIndependent ℝ p
  w_pos : ∀ i, 0 < w i
  w_sum : ∑ i, w i = 1
  avg : ∑ i, w i • p i = f

/-- `f` is surrounded by a set `s` if there is an affine basis `p` in `s` with weighted average `f`.
-/
def Surrounded (f : F) (s : Set F) : Prop :=
  ∃ p w, SurroundingPts f p w ∧ ∀ i, p i ∈ s

--- `prop:surrounded_by_open`

/- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation -/
-- `lem:smooth_barycentric_coord`

theorem smooth_surroundingPts [FiniteDimensional ℝ F] {x : F} {p : ι → F} {w : ι → ℝ}
    (h : SurroundingPts x p w) :
    ∃ W : F → (ι → F) → ι → ℝ,
      ∀ᶠ yq : F × (ι → F) in 𝓝 (x, p),
        SmoothAt' (uncurry W) yq ∧ SurroundingPts yq.1 yq.2 (W yq.1 yq.2) := by
  sorry

end SurroundingPoints

section SurroundingPointsLimits

variable {X Y : Type*} [FiniteDimensional ℝ F]

local macro:arg "ι" : term => `(Fin (finrank ℝ F + 1))

theorem eventually_surroundingPts_of_tendsto_of_tendsto {l : Filter X} {m : Filter Y} {v : ι → F}
    {q : F} {p : ι → X → F} {f : Y → F} (hq : ∃ w, SurroundingPts q v w)
    (hp : ∀ i, Tendsto (p i) l (𝓝 (v i))) (hf : Tendsto f m (𝓝 q)) :
    ∀ᶠ z : X × Y in l ×ˢ m, ∃ w, SurroundingPts (f z.2) (fun i ↦ p i z.1) w := by
  sorry

theorem eventually_surroundingPts_of_tendsto_of_tendsto' {v : ι → F} {q : F} {p : ι → X → F}
    {l : Filter X} {f : X → F} (hq : ∃ w, SurroundingPts q v w)
    (hp : ∀ i, Tendsto (p i) l (𝓝 (v i))) (hf : Tendsto f l (𝓝 q)) :
    ∀ᶠ y in l, ∃ w, SurroundingPts (f y) (fun i ↦ p i y) w := by
  sorry

end SurroundingPointsLimits

namespace Loop

variable {γ γ' : Loop F} {x y : F} {t : ℝ}

/-- A loop `γ` surrounds a point `x` if `x` is surrounded by values of `γ`. -/
def Surrounds (γ : Loop F) (x : F) : Prop :=
  ∃ t w : Fin (d + 1) → ℝ, SurroundingPts x (γ ∘ t) w

theorem surrounds_iff_range_subset_range :
    γ.Surrounds x ↔
      ∃ (p : Fin (d + 1) → F) (w : Fin (d + 1) → ℝ), SurroundingPts x p w ∧ range p ⊆ range γ := by
  sorry

/-- This is only a stepping stone potentially useful for `SurroundingFamily.surrounds_of_close`,
  but not needed by itself. -/
theorem Surrounds.eventually_surrounds [FiniteDimensional ℝ F] (h : γ.Surrounds x) :
    ∃ ε > 0,
      ∀ (γ' : Loop F) (y : F), (∀ z, dist (γ' z) (γ z) < ε) → dist y x < ε → γ'.Surrounds y := by
  sorry

end Loop

section surroundingLoop

variable {O : Set F} {b : F} {p : Fin (d + 1) → F} (O_conn : IsPathConnected O)
  (hp : ∀ i, p i ∈ O) (hb : b ∈ O)

/-- witness of `surrounding_loop_of_convexHull` -/
def surroundingLoop : ℝ → Loop F :=
  Loop.roundTripFamily <| (O_conn.somePath hb (hp 0)).trans <| O_conn.pathThrough hp d

variable {O_conn hp hb}

-- unused
theorem surroundingLoop_of_le_zero (s : ℝ) {t : ℝ} (ht : t ≤ 0) :
    surroundingLoop O_conn hp hb t s = b := by
  sorry

-- unused
theorem surroundingLoop_of_ge_one (s : ℝ) {t : ℝ} (ht : 1 ≤ t) :
    surroundingLoop O_conn hp hb t s = surroundingLoop O_conn hp hb 1 s := by
  sorry

theorem surrounding_loop_of_convexHull [FiniteDimensional ℝ F] {f b : F} {O : Set F}
    (O_op : IsOpen O) (O_conn : IsConnected O) (hsf : f ∈ convexHull ℝ O) (hb : b ∈ O) :
    ∃ γ : ℝ → Loop F,
      Continuous ↿γ ∧
        (∀ t, γ t 0 = b) ∧
          (∀ s, γ 0 s = b) ∧
            (∀ s t, γ (projI t) s = γ t s) ∧ (∀ t s, γ t s ∈ O) ∧ (γ 1).Surrounds f := by
  sorry

end surroundingLoop

/-- `γ` forms a family of loops surrounding `g` with base `b`.
In contrast to the notes we assume that `base` and `t₀` hold universally. -/
structure SurroundingFamily (g b : E → F) (γ : E → ℝ → Loop F) (U : Set E) : Prop where
  protected base : ∀ (x : E) (t : ℝ), γ x t 0 = b x
  protected t₀ : ∀ (x : E) (s : ℝ), γ x 0 s = b x
  protected projI : ∀ (x : E) (t : ℝ) (s : ℝ), γ x (projI t) s = γ x t s
  protected surrounds : ∀ x ∈ U, (γ x 1).Surrounds <| g x
  protected cont : Continuous ↿γ

/-- `γ` forms a family of loops surrounding `g` with base `b` in `Ω`. -/
structure SurroundingFamilyIn (g b : E → F) (γ : E → ℝ → Loop F) (U : Set E)
    (Ω : Set <| E × F) : Prop extends SurroundingFamily g b γ U where
  val_in' : ∀ x ∈ U, ∀ t ∈ I, ∀ s ∈ I, (x, γ x t s) ∈ Ω

namespace SurroundingFamily

variable {g b : E → F} {γ : E → ℝ → Loop F} {U : Set E}

omit [NormedSpace ℝ E]

protected theorem one (h : SurroundingFamily g b γ U) (x : E) (t : ℝ) : γ x t 1 = b x := by
  sorry

variable [NormedSpace ℝ E] in
protected theorem surrounds_of_close_univ [FiniteDimensional ℝ E] [FiniteDimensional ℝ F]
    (hg : Continuous g) (h : SurroundingFamily g b γ univ) :
    ∃ ε : E → ℝ,
      (∀ x, 0 < ε x) ∧
        Continuous ε ∧
          ∀ (x) (γ' : Loop F), (∀ z, dist (γ' z) (γ x 1 z) < ε x) → γ'.Surrounds (g x) := by
  sorry

-- proof using `surrounds_of_close`
-- begin
--   obtain ⟨ε, hε, hcε, hγε⟩ := h.surrounds_of_close hg isOpen_univ,
--   exact ⟨ε, λ x, hε x (mem_univ _), continuous_iff_continuous_on_univ.mpr hcε,
--     λ x, hγε x (mem_univ _)⟩
-- end
/-- A surrounding family induces a family of paths from `b x` to `b x`.
We defined the concatenation we need on `path`, so we need to turn a surrounding
family into the family of paths. -/
@[simps]
protected def path (h : SurroundingFamily g b γ U) (x : E) (t : ℝ) : Path (b x) (b x) where
  toFun s := γ x t s
  continuous_toFun :=
    (h.cont.comp₃ continuous_const continuous_const continuous_id).comp continuous_subtype_val
  source' := h.base x t
  target' := h.one x t

end SurroundingFamily

variable {g b : E → F} {U K C : Set E} {Ω : Set (E × F)}

namespace SurroundingFamilyIn

variable {γ : E → ℝ → Loop F}

omit [NormedSpace ℝ E]

/-- Abbreviation for `toSurroundingFamily` -/
theorem to_sf (h : SurroundingFamilyIn g b γ U Ω) : SurroundingFamily g b γ U := by
  sorry

/-- Continuously reparameterize a `surroundingFamilyIn` so that it is constant near
  `s ∈ {0,1}` and `t ∈ {0,1}` -/
protected theorem reparam (h : SurroundingFamilyIn g b γ U Ω) :
    SurroundingFamilyIn g b (fun x t ↦ (γ x (linearReparam t)).reparam linearReparam) U Ω := by
  sorry

end SurroundingFamilyIn

section local_loops

variable {x₀ : E} (hΩ_conn : IsPathConnected (Prod.mk x₀ ⁻¹' Ω)) (hb_in : (x₀, b x₀) ∈ Ω)
  {p : Fin (d + 1) → F} (hp : ∀ i, p i ∈ Prod.mk x₀ ⁻¹' Ω)

omit [NormedSpace ℝ E]

/- ./././Mathport/Syntax/Translate/Expr.lean:177:8: unsupported: ambiguous notation -/
-- /-- The witness of `local_loops`. -/
-- def local_loops_def (x : E) (t : ℝ) : loop F :=
-- b x - b x₀ +ᵥ surrounding_loop hΩ_conn hp hb_in t
/-- Note: The conditions in this lemma are currently a bit weaker than the ones mentioned in the
blueprint.
TODO: use `local_loops_def`
-/
theorem local_loops [FiniteDimensional ℝ F] {x₀ : E} (hΩ_op : ∃ U ∈ 𝓝 x₀, IsOpen (Ω ∩ fst ⁻¹' U))
    (hg : ContinuousAt g x₀) (hb : Continuous b)
    (hconv : g x₀ ∈ convexHull ℝ (connectedComponentIn (Prod.mk x₀ ⁻¹' Ω) <| b x₀)) :
    ∃ γ : E → ℝ → Loop F, ∃ U ∈ 𝓝 x₀, SurroundingFamilyIn g b γ U Ω := by
  sorry

/-- A tiny reformulation of `local_loops` where the existing `U` is open. -/
theorem local_loops_open [FiniteDimensional ℝ F] {x₀ : E}
    (hΩ_op : ∃ U ∈ 𝓝 x₀, IsOpen (Ω ∩ fst ⁻¹' U)) (hg : ContinuousAt g x₀) (hb : Continuous b)
    (hconv : g x₀ ∈ convexHull ℝ (connectedComponentIn (Prod.mk x₀ ⁻¹' Ω) <| b x₀)) :
    ∃ (γ : E → ℝ → Loop F) (U : Set E), IsOpen U ∧ x₀ ∈ U ∧ SurroundingFamilyIn g b γ U Ω := by
  sorry

end local_loops

/-- Function used in `satisfied_or_refund`. Rename. -/
def ρ (t : ℝ) : ℝ :=
  projI <| 2 * (1 - t)

@[simp]
theorem ρ_eq_one {x : ℝ} : ρ x = 1 ↔ x ≤ 1 / 2 := by
  sorry

@[simp]
theorem ρ_eq_zero {x : ℝ} : ρ x = 0 ↔ 1 ≤ x := by
  sorry

section satisfied_or_refund

variable {γ₀ γ₁ : E → ℝ → Loop F}

variable (h₀ : SurroundingFamily g b γ₀ U) (h₁ : SurroundingFamily g b γ₁ U)

/-- The homotopy of surrounding families of loops used in lemma `satisfied_or_refund`.
  Having this as a separate definition is useful, because the construction actually gives some
  more information about the homotopy than the theorem `satisfied_or_refund` gives. -/
def sfHomotopy (τ : ℝ) (x : E) (t : ℝ) :=
  Loop.ofPath <|
    (h₀.path x <| ρ τ * projI t).strans (h₁.path x <| ρ (1 - τ) * projI t) <|
      projIcc 0 1 zero_le_one (1 - τ)

variable {h₀ h₁}

omit [NormedSpace ℝ E]

attribute [fun_prop] continuous_projIcc

theorem surroundingFamily_sfHomotopy [NormedSpace ℝ E] [FiniteDimensional ℝ E] (τ : ℝ) :
    SurroundingFamily g b (sfHomotopy h₀ h₁ τ) U := by
  sorry

/-- A more precise version of `sfHomotopy_in`. -/
theorem sfHomotopy_in' {ι} (h₀ : SurroundingFamily g b γ₀ U) (h₁ : SurroundingFamily g b γ₁ U)
    (τ : ι → ℝ) (x : ι → E) (i : ι) {V : Set E} (hx : x i ∈ V) {t : ℝ} (ht : t ∈ I) {s : ℝ}
    (h_in₀ : ∀ i, x i ∈ V → ∀ t ∈ I, ∀ (s : ℝ), τ i ≠ 1 → (x i, γ₀ (x i) t s) ∈ Ω)
    (h_in₁ : ∀ i, x i ∈ V → ∀ t ∈ I, ∀ (s : ℝ), τ i ≠ 0 → (x i, γ₁ (x i) t s) ∈ Ω) :
    (x i, sfHomotopy h₀ h₁ (τ i) (x i) t s) ∈ Ω := by
  sorry

theorem sfHomotopy_in (h₀ : SurroundingFamilyIn g b γ₀ U Ω) (h₁ : SurroundingFamilyIn g b γ₁ U Ω)
    (τ : ℝ) ⦃x : E⦄ (hx : x ∈ U) {t : ℝ} (ht : t ∈ I) {s : ℝ} :
    (x, sfHomotopy h₀.to_sf h₁.to_sf τ x t s) ∈ Ω := by
  sorry

theorem surroundingFamilyIn_sfHomotopy [NormedSpace ℝ E] [FiniteDimensional ℝ E]
    (h₀ : SurroundingFamilyIn g b γ₀ U Ω) (h₁ : SurroundingFamilyIn g b γ₁ U Ω) (τ : ℝ) :
    SurroundingFamilyIn g b (sfHomotopy h₀.to_sf h₁.to_sf τ) U Ω := by
  sorry

theorem satisfied_or_refund [NormedSpace ℝ E] [FiniteDimensional ℝ E] {γ₀ γ₁ : E → ℝ → Loop F}
    (h₀ : SurroundingFamilyIn g b γ₀ U Ω) (h₁ : SurroundingFamilyIn g b γ₁ U Ω) :
    ∃ γ : ℝ → E → ℝ → Loop F,
      (∀ τ, SurroundingFamilyIn g b (γ τ) U Ω) ∧ γ 0 = γ₀ ∧ γ 1 = γ₁ ∧ Continuous ↿γ := by
  sorry

end satisfied_or_refund

section extend_loops

variable [FiniteDimensional ℝ E]

/-
Note: we also want add the condition that `γ = γ₀` outside a neighborhood of `U₁ᶜ`.
This makes it easier to find the limit of a sequence of these constructions.
-/
theorem extend_loops {U₀ U₁ K₀ K₁ : Set E} (hU₀ : IsOpen U₀) (hU₁ : IsOpen U₁) (hK₀ : IsClosed K₀)
    (hK₁ : IsClosed K₁) (hKU₀ : K₀ ⊆ U₀) (hKU₁ : K₁ ⊆ U₁) {γ₀ γ₁ : E → ℝ → Loop F}
    (h₀ : SurroundingFamilyIn g b γ₀ U₀ Ω) (h₁ : SurroundingFamilyIn g b γ₁ U₁ Ω) :
    ∃ U ∈ 𝓝ˢ (K₀ ∪ K₁),
      ∃ γ : E → ℝ → Loop F,
        SurroundingFamilyIn g b γ U Ω ∧
          (∀ᶠ x in 𝓝ˢ K₀, γ x = γ₀ x) ∧ ∀ᶠ x in 𝓝ˢ (U₁ᶜ), γ x = γ₀ x := by
  sorry

end extend_loops

def ContinuousGerm {x : E} (φ : Germ (𝓝 x) (ℝ → Loop F)) : Prop :=
  Quotient.liftOn' φ
    (fun γ ↦ ∀ t s : ℝ, ContinuousAt (fun p : E × ℝ × ℝ ↦ γ p.1 p.2.1 p.2.2) (x, t, s))
    (by
      rintro γ γ' (h : {x | γ x = γ' x} ∈ 𝓝 x)
      ext
      refine forall_congr' fun t ↦ forall_congr' fun s ↦ continuousAt_congr ?_
      rw [nhds_prod_eq]
      apply mem_of_superset (Filter.prod_mem_prod h univ_mem)
      rintro ⟨x', p⟩ ⟨hx' : γ x' = γ' x', -⟩
      simp only [mem_setOf_eq, hx'])

variable (g b Ω)
omit [NormedSpace ℝ E]

structure LoopFamilyGerm (x : E) (φ : Germ (𝓝 x) (ℝ → Loop F)) : Prop where
  base : ∀ t, φ.value t 0 = b x
  t₀ : ∀ s, φ.value 0 s = b x
  projI : ∀ (t : ℝ) (s : ℝ), φ.value (projI t) s = φ.value t s
  cont : ContinuousGerm φ

structure SurroundingFamilyGerm (x : E) (φ : Germ (𝓝 x) (ℝ → Loop F)) : Prop where
  Surrounds : (φ.value 1).Surrounds <| g x
  val_in' : ∀ t ∈ I, ∀ s ∈ I, (x, φ.value t s) ∈ Ω

variable {g b Ω}

/-
The following proof is slightly tedious because the definition of `surroundingFamilyIn`
splits weirdly into `SurroundingFamily` which includes one condition on `C`
and one extra condition on `C` instead of putting everything which does not depend on `C`
on one side and the two conditions depending on `C` on the other side as we do here.
-/
theorem surroundingFamilyIn_iff_germ {γ : E → ℝ → Loop F} :
    SurroundingFamilyIn g b γ C Ω ↔
      (∀ x, LoopFamilyGerm b x γ) ∧ ∀ x ∈ C, SurroundingFamilyGerm g Ω x γ := by
  sorry

variable [NormedSpace ℝ E] [FiniteDimensional ℝ E] [FiniteDimensional ℝ F]
  [SecondCountableTopology E]

theorem exists_surrounding_loops (hK : IsClosed K) (hΩ_op : IsOpen Ω) (hg : ∀ x, ContinuousAt g x)
    (hb : Continuous b)
    (hconv : ∀ x, g x ∈ convexHull ℝ (connectedComponentIn (Prod.mk x ⁻¹' Ω) <| b x))
    {γ₀ : E → ℝ → Loop F} (hγ₀_surr : ∃ V ∈ 𝓝ˢ K, SurroundingFamilyIn g b γ₀ V Ω) :
    ∃ γ : E → ℝ → Loop F, SurroundingFamilyIn g b γ univ Ω ∧ ∀ᶠ x in 𝓝ˢ K, γ x = γ₀ x := by
  sorry
