/-
Copyright (c) 2024 Joris Roos. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Joris Roos, Sébastien Gouëzel
-/
module

public import Carleson.ToMathlib.BoundedFiniteSupport
public import Carleson.ToMathlib.Misc

/-!

# Bounded compactly supported functions

The purpose of this file is to provide helper lemmas to streamline proofs that
functions are (essentially) bounded, compactly supported and measurable.

Most functions we need to deal with are of this class.
This can be a useful way to streamline proofs of `L^p` membership,
in particular integrability.

Todo: make `Mathlib.Tactic.FunProp` work for this

This can be expanded as needed

Upstreaming status: should be upstreamed, but need to clarify design questions first
- want to tag this with fun_prop first and make it work smoothly (see #499)
- this is similar to `BoundedFiniteSupport` (and in almost all cases, implies the latter)
  TODO: are there any advantages of using this and not BoundedFiniteSupport? for instance, is
  there any operation which preserves `BoundedCompactSupport` but not `BoundedFiniteSupport`?
  Decide if we want both classes in mathlib or just one of them. If the latter, rewrite all of
  Carleson/ToMathlib to use that one class.
  (Discussion on Zulip)
-/

public section

open Bornology Function Set HasCompactSupport
open scoped ENNReal

namespace MeasureTheory

section

variable {X E : Type*} [TopologicalSpace X] [MeasurableSpace X] {μ ν : Measure X} {f : X → E}

-- move near the MeasurePreserving/mono_measure analogues
variable {α : Type*} {m0 : MeasurableSpace α} {μ ν : Measure α}
  {ε : Type*} [TopologicalSpace ε] [ContinuousENorm ε] {f : α → ε} in
theorem eLpNorm_mono_ac (hμν : ν ≪ μ) : eLpNorm f ∞ ν ≤ eLpNorm f ∞ μ := by
  sorry

variable {α : Type*} {m0 : MeasurableSpace α} {μ ν : Measure α}
  {ε : Type*} [TopologicalSpace ε] [ContinuousENorm ε] {f : α → ε} in
theorem MemLp.mono_ac (hf : MemLp f ∞ μ) (hμν : ν ≪ μ) :
    MemLp f ∞ ν := by
  sorry

variable {α : Type*} {m0 : MeasurableSpace α} {μ : Measure α}
  {ε : Type*} [TopologicalSpace ε] [ContinuousENorm ε]
  {β : Type*} {mβ : MeasurableSpace β} {f : α → β} {g : β → ε} {ν : Measure β} in
theorem MemLp.comp_quasiMeasurePreserving
    (hg : MemLp g ∞ ν) (hf : Measure.QuasiMeasurePreserving f μ ν) : MemLp (g ∘ f) ∞ μ := by
  sorry

-- maybe don't upstream
variable {α : Type*} {m0 : MeasurableSpace α} {μ ν : Measure α}
  {E : Type*} [NormedAddCommGroup E] {f : α → E} in
theorem MemLp.ae_norm_le (hf : MemLp f ∞ μ) : ∀ᵐ x ∂μ, ‖f x‖ ≤ (eLpNorm f ⊤ μ).toReal := by
  sorry

variable [TopologicalSpace E] [ENorm E] [Zero E] in
/- currently we assume that the functions are a.e.-bounded, since that plays better with mathlib.
Since it might be nicer to work with suprema instead of essential suprema, we need to prove
everywhere-boundedness in one place. -/
/-- Bounded compactly supported measurable functions -/
@[fun_prop]
structure BoundedCompactSupport (f : X → E) (μ : Measure X := by volume_tac) :
    Prop where
  memLp_top : MemLp f ∞ μ
  hasCompactSupport : HasCompactSupport f

namespace BoundedCompactSupport

section General

open Bornology in
lemma _root_.isBounded_range_iff_forall_norm_le {α β} [SeminormedAddCommGroup α] {f : β → α} :
    IsBounded (range f) ↔ ∃ C, ∀ x, ‖f x‖ ≤ C := by
  sorry

variable [TopologicalSpace E] [ENorm E] [Zero E]

@[fun_prop]
theorem aestronglyMeasurable (hf : BoundedCompactSupport f μ) : AEStronglyMeasurable f μ := by
  sorry

theorem boundedFiniteSupport [IsFiniteMeasureOnCompacts μ] (hf : BoundedCompactSupport f μ) :
    BoundedFiniteSupport f μ := by
  sorry

end General

section ContinuousENorm

variable [TopologicalSpace E] [ContinuousENorm E] [Zero E]

theorem mono_ac (hf : BoundedCompactSupport f μ) (h : ν ≪ μ) :
    BoundedCompactSupport f ν := by
  sorry

theorem mono_measure (hf : BoundedCompactSupport f μ) (h : ν ≤ μ) : BoundedCompactSupport f ν := by
  sorry

@[fun_prop]
theorem restrict {s : Set X} (hf : BoundedCompactSupport f μ) :
    BoundedCompactSupport f (μ.restrict s) := by
  sorry

end ContinuousENorm

section ESeminormedAddCommMonoid
variable [TopologicalSpace E] [ESeminormedAddCommMonoid E]

/-- Bounded compactly supported functions are in all `Lᵖ` spaces. -/
theorem memLp [IsFiniteMeasureOnCompacts μ] (hf : BoundedCompactSupport f μ) (p : ℝ≥0∞) :
    MemLp f p μ := by
  sorry

end ESeminormedAddCommMonoid

section NormedAddCommGroup

variable [NormedAddCommGroup E]

-- todo: prove more results for ENorm-classes (awaiting-mathlib)

/-- Bounded compactly supported functions are integrable. -/
@[fun_prop]
theorem integrable [IsFiniteMeasureOnCompacts μ] (hf : BoundedCompactSupport f μ) :
    Integrable f μ := by
  sorry

@[fun_prop]
protected theorem zero : BoundedCompactSupport (fun (_ : X) ↦ (0 : E)) μ := by
  sorry

@[fun_prop]
theorem enorm (hf : BoundedCompactSupport f μ) : BoundedCompactSupport (‖f ·‖ₑ) μ := by
  sorry

-- preferably use `enorm`
@[fun_prop]
theorem norm (hf : BoundedCompactSupport f μ) : BoundedCompactSupport (‖f ·‖) μ := by
  sorry

theorem comp_left_norm {F} [NormedAddCommGroup F] {g : E → F} (hf : BoundedCompactSupport f μ)
    (hg : g 0 = 0) (hg1 : Continuous g) (hg2 : (∀ (a : E), ‖g a‖ = ‖a‖)) :
 BoundedCompactSupport (g ∘ f) μ := by
  sorry

@[fun_prop]
protected theorem neg (hf : BoundedCompactSupport f μ) : BoundedCompactSupport (- f) μ := by
  sorry

variable {𝕜 : Type*} [RCLike 𝕜] {g : X → E}

@[fun_prop]
protected theorem add (hf : BoundedCompactSupport f μ) (hg : BoundedCompactSupport g μ) :
    BoundedCompactSupport (f + g) μ := by
  sorry

@[fun_prop]
protected theorem sub (hf : BoundedCompactSupport f μ) (hg : BoundedCompactSupport g μ) :
    BoundedCompactSupport (f - g) μ := by
  sorry

section Mul

variable {f g : X → 𝕜}

@[fun_prop]
theorem mul_bdd_right (hf : BoundedCompactSupport f μ) (hg : MemLp g ∞ μ) :
    BoundedCompactSupport (f * g) μ := by
  sorry

@[fun_prop]
theorem mul_bdd_left (hf : BoundedCompactSupport f μ) (hg : MemLp g ∞ μ) :
    BoundedCompactSupport (g * f) μ := by
  sorry

@[fun_prop]
theorem mul (hf : BoundedCompactSupport f μ) (hg : BoundedCompactSupport g μ) :
    BoundedCompactSupport (f * g) μ := by
  sorry

-- doesn't use compact support but is convenient to have here
@[fun_prop]
theorem integrable_mul (hf : BoundedCompactSupport f μ) (hg : Integrable g μ) :
    Integrable (f * g) μ := by
  sorry

@[fun_prop]
theorem integrable_fun_mul (hf : BoundedCompactSupport f μ) (hg : Integrable g μ) :
    Integrable (fun x ↦ f x * g x) μ := by
  sorry

-- TODO: move the next three lemmas to their proper homes!
omit [MeasurableSpace X] in
lemma _root_.HasCompactSupport.star (hf : HasCompactSupport f) :
    HasCompactSupport fun i ↦ star (f i) := by
  sorry

omit [TopologicalSpace X] in
lemma _root_.AEStronglyMeasurable.star (hf : AEStronglyMeasurable f μ) :
    AEStronglyMeasurable (star f) μ := by
  sorry

omit [TopologicalSpace X] in
lemma eLpNorm_star : eLpNorm (star f) ⊤ μ = eLpNorm f ⊤ μ := by
  sorry

@[fun_prop]
theorem conj (hf : BoundedCompactSupport f μ) : BoundedCompactSupport (star f) μ := by
  sorry

-- This lemma is defeq to `BoundedCompactSupport.conj`, but `starRingEnd` and `conj` are both
-- simp normal forms, so a lemma for each is needed.
@[fun_prop]
theorem starRingEnd (hf : BoundedCompactSupport f μ) :
  BoundedCompactSupport (fun x ↦ (starRingEnd 𝕜) (f x)) μ := by
  sorry

@[fun_prop]
theorem const_mul (hf : BoundedCompactSupport f μ) (c : 𝕜) :
    BoundedCompactSupport (fun x ↦ c * f x) μ := by
  sorry

@[fun_prop]
theorem mul_const (hf : BoundedCompactSupport f μ) (c : 𝕜) :
    BoundedCompactSupport (fun x ↦ f x * c) μ := by
  sorry

end Mul

/-- If `‖f‖` is bounded by `g` and `g` is bounded compactly supported, then so is `f`. -/
theorem mono {g : X → ℝ≥0∞} (hg : BoundedCompactSupport g μ) (hf : AEStronglyMeasurable f μ)
    (hfg : ∀ x, ‖f x‖ₑ ≤ g x) : BoundedCompactSupport f μ := by
  sorry

-- use `mono` preferably
theorem mono_norm {g : X → ℝ} (hg : BoundedCompactSupport g μ) (hf : AEStronglyMeasurable f μ)
    (hfg : ∀ x, ‖f x‖ ≤ g x) : BoundedCompactSupport f μ := by
  sorry

@[fun_prop]
theorem toComplex {f : X → ℝ} (hf : BoundedCompactSupport f μ) :
    BoundedCompactSupport (fun x ↦ (f x : ℂ)) μ := by
  sorry

section Sum

variable {ι : Type*} {s : Finset ι} {F : ι → X → E}

/-- A finite sum of bounded compactly supported functions is bounded compactly supported. -/
@[fun_prop]
theorem finset_sum
    (hF : ∀ i ∈ s, BoundedCompactSupport (F i) μ) :
    BoundedCompactSupport (fun x ↦ ∑ i ∈ s, F i x) μ := by
  sorry

open Classical ComplexConjugate in
/-- Used in Proposition 2.0.4. -/
lemma sq_eLpNorm_le_sums [IsFiniteMeasureOnCompacts μ] {f : ι → X → ℂ}
    (hf : ∀ i, BoundedCompactSupport (f i) μ) {s : Finset ι} :
    eLpNorm (∑ i ∈ s, f i ·) 2 μ ^ 2 ≤
    ∑ i ∈ s, eLpNorm (f i) 2 μ ^ 2 +
    ∑ i ∈ s, ∑ j ∈ s with i ≠ j, ‖∫ x, f i x * conj (f j x) ∂μ‖ₑ := by
  sorry

end Sum

section Prod

variable {Y : Type*} [MeasureSpace Y] {f : X → 𝕜} {g : Y → 𝕜} {ν : Measure Y}
variable [TopologicalSpace Y]
variable [R1Space (X × Y)]

/-- An elementary tensor of bounded compactly supported functions is
bounded compactly supported. -/
@[fun_prop]
theorem prod_mul (hf : BoundedCompactSupport f μ) (hg : BoundedCompactSupport g ν) :
    BoundedCompactSupport (uncurry fun x y ↦ f x * g y) (μ.prod ν) := by
  sorry

variable [R1Space X] in
theorem indicator_of_isCompact_closure {f : X → E} (hf : MemLp f ∞ μ)
    {s : Set X} (h's : IsCompact (closure s)) (hs : MeasurableSet s) :
    BoundedCompactSupport (s.indicator f) μ := by
  sorry

@[fun_prop]
protected theorem indicator {f : X → E} (hf : BoundedCompactSupport f μ) {s : Set X}
    (hs : MeasurableSet s) : BoundedCompactSupport (s.indicator f) μ := by
  sorry

variable {F : X × Y → E}

-- -- prove when needed
-- theorem swap (hF : BoundedCompactSupport f μ) : BoundedCompactSupport (F ∘ Prod.swap)

variable {F : X × Y → E}

/- This and other fiberwise constructions are problematic with the current
choice of using a.e. boundedness in place of everywhere boundedness -/
-- ---- adapt and prove below when needed
-- theorem prod_left (hF : BoundedCompactSupport f μ) :
--     ∀ y, BoundedCompactSupport (fun x ↦ F (x, y)) := fun y ↦ {
--   memLp_top := by
--     rcases isBounded_range_iff_forall_norm_le.1 hF.isBounded with ⟨C, hC⟩
--     apply isBounded_range_iff_forall_norm_le.2 ⟨C, fun x ↦ ?_⟩
--     exact hC (x, y)
--   stronglyMeasurable := hF.stronglyMeasurable.comp_measurable measurable_prodMk_right
--   hasCompactSupport :=
--   -- by
--   --   apply HasCompactSupport.intro
-- }

-- theorem prod_right_ae (hF : BoundedCompactSupport f μ) :
--     ∀ᵐ x, BoundedCompactSupport (fun y ↦ F (x, y)) := hF.swap.prod_left_ae

-- theorem integral_prod_left (hF : BoundedCompactSupport f μ) :
--     BoundedCompactSupport (fun x ↦ ∫ y, F (x, y)) :=
-- --   have := hF.integrable.integrable_prod_left

-- theorem integral_prod_right (hF : BoundedCompactSupport f μ) :
--     BoundedCompactSupport (fun y ↦ ∫ x, F (x, y)) := hF.swap.integral_prod_left

end Prod

end NormedAddCommGroup

end BoundedCompactSupport

end

section Metric
namespace BoundedCompactSupport

variable {X E : Type*} [MetricSpace X] [MeasurableSpace X] {μ : Measure X}
  [TopologicalSpace E] [ENorm E] [Zero E]
  {f : X → E}

theorem isBoundedTSupport (hf : BoundedCompactSupport f μ) : IsBounded (tsupport f) := by
  sorry

theorem isBoundedSupport (hf : BoundedCompactSupport f μ) : IsBounded (support f) := by
  sorry

end BoundedCompactSupport

end Metric

end MeasureTheory

section

open Bornology ENNReal MeasureTheory Set

variable {X 𝕜 E F : Type*} [MeasurableSpace X] [MetricSpace X]
variable [NormedAddCommGroup E]
variable {Y W : Type*} [MeasurableSpace Y] [TopologicalSpace Y]
variable [MeasurableSpace W] [TopologicalSpace W] {μ : Measure W}
variable {f : X → 𝕜} {ν : Measure X} [RCLike 𝕜]

lemma BoundedCompactSupport.mul_bdd_right'' (hf : BoundedCompactSupport f ν) {e : W → X}
    {g : W → 𝕜} (he : Continuous e) (he1 : Measure.QuasiMeasurePreserving e μ ν)
    (hg : AEStronglyMeasurable g μ)
    (hg1 : ∀ K : Set X, IsCompact K -> IsCompact (e ⁻¹' K ∩ tsupport g))
    (hg2 : ∀ (A : Set X) (_hA : IsBounded A), IsBounded (g '' (e ⁻¹' A))) :
    BoundedCompactSupport (fun x ↦ f (e x) * g x) μ := by
  sorry

lemma BoundedCompactSupport.mul_bdd_left' (hf : BoundedCompactSupport f ν) {e : W → X} {g : W → 𝕜}
    (he : Continuous e) (he1 : Measure.QuasiMeasurePreserving e μ ν)
    (hg : AEStronglyMeasurable g μ)
    (hg1 : ∀ K : Set X, IsCompact K -> IsCompact (e ⁻¹' K ∩ tsupport g))
    (hg2 : ∀ (A : Set X) (_hA : IsBounded A), IsBounded (g '' (e ⁻¹' A))) :
    BoundedCompactSupport (fun x ↦ g x * f (e x)) μ:= by
  sorry

end
