module

public import Carleson.ToMathlib.BoundedFiniteSupport
public import Carleson.ToMathlib.Misc
public import Carleson.ToMathlib.Order.ConditionallyCompleteLattice.Basic
public import Mathlib.Analysis.SpecialFunctions.ImproperIntegrals
public import Mathlib.Analysis.SpecialFunctions.Pow.Integral

-- Upstreaming status: all of this should go into mathlib, eventually.
-- Most lemmas have the right form, but proofs can often be golfed.
-- Some enorm lemmas require some mathlib refactoring first, so they can be unified with their
-- analogue in current mathlib. Such refactorings include (1) adding a Weak(Pseudo)EMetricSpace
-- class, (2) generalising all lemmas about enorms and • to this setting.

@[expose] public section

noncomputable section

open NNReal ENNReal NormedSpace MeasureTheory Set Filter Topology Function

namespace MeasureTheory

variable {α α' ε ε₁ ε₂ ε₃ 𝕜 E E₁ E₂ E₃ : Type*} {m : MeasurableSpace α} {m : MeasurableSpace α'}
  {p p' q : ℝ≥0∞} {c : ℝ≥0∞}
  {μ : Measure α} {ν : Measure α'} [NontriviallyNormedField 𝕜]
  {t s x y : ℝ≥0∞} {T : (α → ε₁) → (α' → ε₂)}

section ENorm

variable [ENorm ε] {f g g₁ g₂ : α → ε}

/- Proofs for this file can be found in
Folland, Real Analysis. Modern Techniques and Their Applications, section 6.3. -/

/-- The superlevel set of a function `f`. -/
def superlevelSet (f : α → ε) (t : ℝ≥0∞) : Set α := {x | t < ‖f x‖ₑ}

lemma superlevelSet_antitone : Antitone (superlevelSet f) := by
  sorry

lemma superlevelSet_zero_eq_support {ε} [TopologicalSpace ε] [ENormedAddCommMonoid ε] {f : α → ε} :
    superlevelSet f 0 = f.support := by
  sorry

@[measurability]
lemma nullMeasurableSet_superlevelSet {ε} [TopologicalSpace ε] [ContinuousENorm ε] {f : α → ε}
  (hf : AEStronglyMeasurable f μ) :
    NullMeasurableSet (superlevelSet f t) μ := by
  sorry

@[measurability]
lemma measurableSet_superlevelSet {ε} [TopologicalSpace ε] [ContinuousENorm ε] [MeasurableSpace ε]
  [OpensMeasurableSpace ε] {f : α → ε} (hf : Measurable f) :
    MeasurableSet (superlevelSet f t) := by
  sorry

lemma superlevelSet_const {a : ε} :
    superlevelSet (const α a) t = if t < ‖a‖ₑ then univ else ∅ := by
  sorry

/-! # The distribution function `d_f` -/

/-- The distribution function of a function `f`.
Todo: rename to something more Mathlib-appropriate. -/
def distribution (f : α → ε) (t : ℝ≥0∞) (μ : Measure α) : ℝ≥0∞ :=
  μ { x | t < ‖f x‖ₑ }

lemma distribution_eq_measure_superlevelSet : distribution f t μ = μ (superlevelSet f t) := by
  sorry

@[simp]
lemma distibution_top (f : α → ε) (μ : Measure α) : distribution f ∞ μ = 0 := by
  sorry

@[gcongr]
lemma distribution_mono_right (h : t ≤ s) : distribution f s μ ≤ distribution f t μ := by
  sorry

lemma distribution_mono_right' : Antitone (fun t ↦ distribution f t μ) := by
  sorry

@[congr]
lemma distribution_congr_ae (h : ∀ᵐ x ∂μ, f x = g x) :
    distribution f t μ = distribution g t μ := by
  sorry

@[measurability, fun_prop]
lemma distribution_measurable₀ : Measurable (fun t ↦ distribution f t μ) := by
  sorry

@[measurability, fun_prop]
lemma distribution_measurable {g : α' → ℝ≥0∞} (hg : Measurable g) :
    Measurable (fun y : α' ↦ distribution f (g y) μ) := by
  sorry

lemma distribution_toReal_le {f : α → ℝ≥0∞} :
    distribution (ENNReal.toReal ∘ f) t μ ≤ distribution f t μ := by
  sorry

lemma distribution_toReal_eq {f : α → ℝ≥0∞} (hf : ∀ᵐ x ∂μ, f x ≠ ∞) :
    distribution (ENNReal.toReal ∘ f) t μ = distribution f t μ := by
  sorry

lemma distribution_add_le_of_enorm {A : ℝ≥0∞}
    (h : ∀ᵐ x ∂μ, ‖f x‖ₑ ≤ A * (‖g₁ x‖ₑ + ‖g₂ x‖ₑ)) :
    distribution f (A * (t + s)) μ ≤ distribution g₁ t μ + distribution g₂ s μ := by
  sorry

lemma approx_above_superset (t₀ : ℝ≥0∞) :
    ⋃ n, (fun n : ℕ ↦ {x | t₀ + (↑n)⁻¹ < ‖f x‖ₑ}) n = {x | t₀ < ‖f x‖ₑ} := by
  sorry

lemma tendsto_measure_iUnion_distribution (t₀ : ℝ≥0∞) :
    Filter.Tendsto (⇑μ ∘ (fun n : ℕ ↦ {x | t₀ + (↑n)⁻¹ < ‖f x‖ₑ}))
      Filter.atTop (nhds (μ ({x | t₀ < ‖f x‖ₑ}))) := by
  sorry

-- TODO: better lemma name!
lemma select_neighborhood_distribution (t₀ : ℝ≥0∞) (l : ℝ≥0∞)
    (hu : l < distribution f t₀ μ) :
    ∃ n : ℕ, l < distribution f (t₀ + (↑n)⁻¹) μ := by
  sorry

lemma continuousWithinAt_distribution (t₀ : ℝ≥0∞) :
    ContinuousWithinAt (distribution f · μ) (Ioi t₀) t₀ := by
  sorry

-- TODO: investigate generalising this to enorm classes
-- This requires adding enorm versions of NormOneClass and NormMulClass
lemma distribution_pow (ε : Type*) [SeminormedRing ε] [NormOneClass ε] [NormMulClass ε] (f : α → ε)
    (t : ℝ≥0∞) (μ : Measure α) {n : ℕ} (hn : n ≠ 0) :
    distribution (f ^ n) (t ^ n) μ = distribution f t μ := by
  sorry

section distribution

variable {ε' : Type*} [ENorm ε'] {f : α → ε} {g : α → ε'}

@[gcongr]
lemma distribution_mono_left (h : ∀ᵐ x ∂μ, ‖f x‖ₑ ≤ ‖g x‖ₑ) :
    distribution f t μ ≤ distribution g t μ := by
  sorry

@[gcongr]
lemma distribution_mono (h₁ : ∀ᵐ x ∂μ, ‖f x‖ₑ ≤ ‖g x‖ₑ) (h₂ : t ≤ s) :
    distribution f s μ ≤ distribution g t μ := by
  sorry

lemma distribution_eLpNormEssSup : distribution f (eLpNormEssSup f μ) μ = 0 := by
  sorry

lemma distribution_add_le' {A : ℝ≥0∞} {g₁ g₂ : α → ε}
    (h : ∀ᵐ x ∂μ, ‖f x‖ₑ ≤ A * (‖g₁ x‖ₑ + ‖g₂ x‖ₑ)) :
    distribution f (A * (t + s)) μ ≤ distribution g₁ t μ + distribution g₂ s μ := by
  sorry

lemma distribution_add_le {ε} [TopologicalSpace ε] [ESeminormedAddMonoid ε] {f g : α → ε} :
    distribution (f + g) (t + s) μ ≤ distribution f t μ + distribution g s μ := by
  sorry

-- TODO: make this an iff?
lemma distribution_eq_zero_of_ae_zero_enorm {f : α → ε} (h : enorm ∘ f =ᵐ[μ] 0) :
    distribution f t μ = 0 := by
  sorry

lemma distribution_eq_zero_of_ae_zero {ε} [TopologicalSpace ε] [ESeminormedAddMonoid ε] {f : α → ε}
  (h : f =ᵐ[μ] 0) :
    distribution f t μ = 0 := by
  sorry

@[simp] lemma distribution_zero {ε} [TopologicalSpace ε] [ENormedAddMonoid ε] :
    distribution (0 : α → ε) t μ = 0 := by
  sorry

lemma distribution_zero_eq_measure_support {ε} [TopologicalSpace ε] [ENormedAddMonoid ε]
  {f : α → ε} :
    distribution f 0 μ = μ f.support := by
  sorry

lemma distribution_indicator_eq {ε} [TopologicalSpace ε] [ESeminormedAddMonoid ε] {f : α → ε}
  {X : Set α} :
    distribution (X.indicator f) x μ = μ (X ∩ superlevelSet f x) := by
  sorry

-- Lemma 1.1.24 of [Ian Tice]
lemma distribution_indicator_le_measure {ε} [TopologicalSpace ε] [ESeminormedAddMonoid ε]
  {f : α → ε} {X : Set α} :
    distribution (X.indicator f) x μ ≤ μ X := by
  sorry

lemma distribution_indicator_const {ε} [TopologicalSpace ε] [ESeminormedAddMonoid ε] {s : Set α} {a : ε} :
    distribution (s.indicator (Function.const α a)) t μ = (Set.Iio ‖a‖ₑ).indicator (fun _ ↦ μ s) t := by
  sorry

lemma distribution_indicator_superlevelSet {ε} [TopologicalSpace ε] [ENormedAddMonoid ε]
  {f : α → ε} {t : ℝ≥0∞} :
    distribution ((superlevelSet f t).indicator f) x μ
      = min (distribution f t μ) (distribution f x μ) := by
  sorry

lemma distribution_indicator_superlevelSet_compl {ε} [TopologicalSpace ε] [ENormedAddMonoid ε]
  {f : α → ε} (hf : AEStronglyMeasurable f μ) {t : ℝ≥0∞} (ht : distribution f t μ ≠ ∞) :
    distribution ((superlevelSet f t)ᶜ.indicator f) x μ
      = distribution f x μ - distribution f t μ := by
  sorry

lemma distribution_eq_zero_iff {ε} [TopologicalSpace ε] [ESeminormedAddMonoid ε] {f : α → ε} :
    distribution f t μ = 0 ↔ eLpNormEssSup f μ ≤ t := by
  sorry

lemma support_distribution {ε} [TopologicalSpace ε] [ESeminormedAddMonoid ε] {f : α → ε} :
    (fun t ↦ distribution f t μ).support = Iio (eLpNormEssSup f μ) := by
  sorry

lemma distribution_add {ε} [TopologicalSpace ε] [ESeminormedAddMonoid ε] {f g : α → ε}
  (h : Disjoint (Function.support f) (Function.support g)) (hg : AEStronglyMeasurable g μ) :
    distribution (f + g) t μ = distribution f t μ + distribution g t μ := by
  sorry

lemma distribution_const_smul {f : α → ℝ≥0∞}
  {a : ℝ≥0∞} (h : a ≠ 0 ∨ t ≠ 0) (h' : a ≠ ⊤ ∨ t ≠ ⊤) :
    distribution (a • f) t μ = distribution f (t / a) μ := by
  sorry

lemma distribution_indicator_add_of_support_subset {ε} [TopologicalSpace ε] [ESeminormedAddMonoid ε]
  (enorm_add : ∀ a b : ε, ‖a + b‖ₑ = ‖a‖ₑ + ‖b‖ₑ) --TODO: new type class for this property?
  {f : α → ε} {c : ε} (hc : ‖c‖ₑ ≠ ⊤) {s : Set α}
  (hfs : Function.support f ⊆ s) :
    distribution (f + s.indicator (Function.const α c)) t μ = if t < ‖c‖ₑ then μ s else distribution f (t - ‖c‖ₑ) μ := by
  sorry

/- ENNReal version of the previous lemma -/
lemma distribution_indicator_add_of_support_subset_ennreal {f : α → ℝ≥0∞} {c : ℝ≥0∞} (hc : c ≠ ⊤)
  {s : Set α} (hfs : Function.support f ⊆ s) :
    distribution (f + s.indicator (Function.const α c)) t μ
      = if t < c then μ s else distribution f (t - c) μ := by
  sorry

/- NNReal version of the previous lemma -/
lemma distribution_indicator_add_of_support_subset_nnreal {f : α → ℝ≥0} {c : ℝ≥0}
  {s : Set α} (hfs : Function.support f ⊆ s) :
    distribution (f + s.indicator (Function.const α c)) t μ
      = if t < c then μ s else distribution f (t - c) μ := by
  sorry

lemma distribution_eq_distribution_prod {ε}
  [ENorm ε] {f : α → ε} {t : ℝ≥0∞}
  {β : Type*} {m' : MeasurableSpace β} {ν : Measure β} [IsProbabilityMeasure ν] :
    distribution f t μ = distribution (fun x : α × β ↦ f x.1) t (μ.prod ν) := by
  sorry

end distribution

end ENorm

end MeasureTheory
