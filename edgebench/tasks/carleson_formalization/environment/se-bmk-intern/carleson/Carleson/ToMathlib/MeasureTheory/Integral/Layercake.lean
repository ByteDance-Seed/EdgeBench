/-
Copyright (c) 2022 Kalle Kytölä. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Kalle Kytölä
-/
module

public import Mathlib.MeasureTheory.Integral.Layercake
public import Carleson.ToMathlib.MeasureTheory.Measure.NNReal
public import Carleson.ToMathlib.MeasureTheory.Measure.AEMeasurable
public import Carleson.ToMathlib.MeasureTheory.Function.SimpleFunc
public import Carleson.ToMathlib.Distribution

/-
Upstreaming status: This ports the corresponding mathlib file to use `ℝ≥0` and integrals over `ℝ≥0`
instead of `ℝ≥0∞` and integrals over `ℝ≥0∞`. TODO: check if both of these changes are desirable for
the mathlib version
-/

/-!
# The layer cake formula / Cavalieri's principle / tail probability formula

In this file we prove the following layer cake formula.

Consider a non-negative measurable function `f` on a measure space. Apply pointwise
to it an increasing absolutely continuous function `G : ℝ≥0 → ℝ≥0` vanishing at the origin, with
derivative `G' = g` on the positive real line (in other words, `G` a primitive of a non-negative
locally integrable function `g` on the positive real line). Then the integral of the result,
`∫ G ∘ f`, can be written as the integral over the positive real line of the "tail measures" of `f`
(i.e., a function giving the measures of the sets on which `f` exceeds different positive real
values) weighted by `g`. In probability theory contexts, the "tail measures" could be referred to
as "tail probabilities" of the random variable `f`, or as values of the "complementary cumulative
distribution function" of the random variable `f`. The terminology "tail probability formula" is
therefore occasionally used for the layer cake formula (or a standard application of it).

The essence of the (mathematical) proof is Fubini's theorem.

We also give the most common application of the layer cake formula -
a representation of the integral of a nonnegative function f:
∫ f(ω) ∂μ(ω) = ∫ μ {ω | f(ω) ≥ t} dt

Variants of the formulas with measures of sets of the form {ω | f(ω) > t} instead of {ω | f(ω) ≥ t}
are also included.

## Main results

* `MeasureTheory.lintegral_comp_eq_lintegral_meas_le_mul`
  and `MeasureTheory.lintegral_comp_eq_lintegral_meas_lt_mul`:
  The general layer cake formulas with Lebesgue integrals, written in terms of measures of
  sets of the forms {ω | t ≤ f(ω)} and {ω | t < f(ω)}, respectively.
* `MeasureTheory.lintegral_eq_lintegral_meas_le` and
  `MeasureTheory.lintegral_eq_lintegral_meas_lt`:
  The most common special cases of the layer cake formulas, stating that for a nonnegative
  function f we have ∫ f(ω) ∂μ(ω) = ∫ μ {ω | f(ω) ≥ t} dt and
  ∫ f(ω) ∂μ(ω) = ∫ μ {ω | f(ω) > t} dt, respectively.
* `Integrable.integral_eq_integral_meas_lt`:
  A Bochner integral version of the most common special case of the layer cake formulas, stating
  that for an integrable and a.e.-nonnegative function f we have
  ∫ f(ω) ∂μ(ω) = ∫ μ {ω | f(ω) > t} dt.

## See also

Another common application, a representation of the integral of a real power of a nonnegative
function, is given in `Mathlib/Analysis/SpecialFunctions/Pow/Integral.lean`.

## Tags

layer cake representation, Cavalieri's principle, tail probability formula
-/

public section

noncomputable section

open scoped ENNReal MeasureTheory Topology

open Set MeasureTheory Filter Measure

namespace MeasureTheory

/-
section

variable {α R : Type*} [MeasurableSpace α] (μ : Measure α) [LinearOrder R]

theorem countable_meas_le_ne_meas_lt (g : α → R) :
    {t : R | μ {a : α | t ≤ g a} ≠ μ {a : α | t < g a}}.Countable := by
  -- the target set is contained in the set of points where the function `t ↦ μ {a : α | t ≤ g a}`
  -- jumps down on the right of `t`. This jump set is countable for any function.
  let F : R → ℝ≥0∞ := fun t ↦ μ {a : α | t ≤ g a}
  apply (countable_image_gt_image_Ioi F).mono
  intro t ht
  have : μ {a | t < g a} < μ {a | t ≤ g a} :=
    lt_of_le_of_ne (measure_mono (fun a ha ↦ le_of_lt ha)) (Ne.symm ht)
  exact ⟨μ {a | t < g a}, this, fun s hs ↦ measure_mono (fun a ha ↦ hs.trans_le ha)⟩

theorem meas_le_ae_eq_meas_lt {R : Type*} [LinearOrder R] [MeasurableSpace R]
    (ν : Measure R) [NoAtoms ν] (g : α → R) :
    (fun t => μ {a : α | t ≤ g a}) =ᵐ[ν] fun t => μ {a : α | t < g a} :=
  Set.Countable.measure_zero (countable_meas_le_ne_meas_lt μ g) _

end
-/

/-! ### Layercake formula -/

section Layercake

variable {α : Type*} [MeasurableSpace α] {f : α → ℝ≥0∞} {g : ℝ≥0∞ → ℝ≥0∞}

/-
/-- An auxiliary version of the layer cake formula (Cavalieri's principle, tail probability
formula), with a measurability assumption that would also essentially follow from the
integrability assumptions, and a sigma-finiteness assumption.

See `MeasureTheory.lintegral_comp_eq_lintegral_meas_le_mul` and
`MeasureTheory.lintegral_comp_eq_lintegral_meas_lt_mul` for the main formulations of the layer
cake formula. -/
theorem lintegral_comp_eq_lintegral_meas_le_mul_of_measurable_of_sigmaFinite'
    (μ : Measure α) [SFinite μ] (f_mble : Measurable f) (g_mble : AEMeasurable g) :
    ∫⁻ ω, (∫⁻ t in Set.Iic (f ω), g t) ∂μ =
      ∫⁻ t, μ {a : α | t ≤ f a} * g t := by
  simp_rw [← lintegral_indicator measurableSet_Iic]
  rw [lintegral_lintegral_swap]
  · apply congr_arg
    funext s
    have aux₁ :
      (fun x => (Iic (f x)).indicator (fun t => g t) s) = fun x =>
        g s *
          (Ici s).indicator (fun _ => (1 : ℝ≥0∞)) (f x) := by
      funext a
      unfold Set.indicator
      split_ifs with h h' h''
      · simp
      · exfalso
        exact h' h
      · exfalso
        exact h h''
      · simp
    simp_rw [aux₁]
    rw [lintegral_const_mul'' _ (by measurability)]
    simp_rw [show
        (fun a => (Ici s).indicator (fun _ => (1 : ℝ≥0∞)) (f a)) = fun a =>
          {a : α | s ≤ f a}.indicator (fun _ => 1) a
        by funext a; by_cases h : s ≤ f a <;> simp [h]]
    rw [lintegral_indicator₀]
    swap; · exact f_mble.nullMeasurable measurableSet_Ici
    rw [lintegral_one, Measure.restrict_apply MeasurableSet.univ, univ_inter, mul_comm]
  have aux₂ :
    (Function.uncurry fun (x : α) (y) =>
        (Iic (f x)).indicator (fun t => g t) y) =
      {p : α × ℝ≥0∞ | p.2 ∈ Iic (f p.1)}.indicator fun p => g p.2 := by
    funext p
    cases p with | mk p_fst p_snd => ?_
    rw [Function.uncurry_apply_pair]
    by_cases h : p_snd ∈ Iic (f p_fst)
    · have h' : (p_fst, p_snd) ∈ {p : α × ℝ≥0∞ | p.snd ∈ Iic (f p.fst)} := h
      rw [Set.indicator_of_mem h', Set.indicator_of_mem h]
    · have h' : (p_fst, p_snd) ∉ {p : α × ℝ≥0∞ | p.snd ∈ Iic (f p.fst)} := h
      rw [Set.indicator_of_notMem h', Set.indicator_of_notMem h]
  rw [aux₂]
  have mble₀ : MeasurableSet {p : α × ℝ≥0∞ | p.snd ∈ Iic (f p.fst)} := by measurability
  measurability

/-- An auxiliary version of the layer cake formula (Cavalieri's principle, tail probability
formula), with a measurability assumption that would also essentially follow from the
integrability assumptions.
Compared to `lintegral_comp_eq_lintegral_meas_le_mul_of_measurable_of_sigmaFinite`, we remove
the sigma-finite assumption.

See `MeasureTheory.lintegral_comp_eq_lintegral_meas_le_mul` and
`MeasureTheory.lintegral_comp_eq_lintegral_meas_lt_mul` for the main formulations of the layer
cake formula. -/
theorem lintegral_comp_eq_lintegral_meas_le_mul_of_measurable' (μ : Measure α)
  (f_mble : Measurable f) (g_intble : ∀ t > 0, AEMeasurable g (volume.restrict (Iic t))) (g_mble : AEMeasurable g) :
    ∫⁻ ω, (∫⁻ t in (Iic (f ω)), g t) ∂μ =
      ∫⁻ t, μ {a : α | t ≤ f a} * g t := by
  /- We will reduce to the sigma-finite case, after excluding two easy cases where the result
  is more or less obvious. -/
  --have f_nonneg : ∀ ω, 0 ≤ f ω := fun ω ↦ f_nn ω
  -- trivial case where `g` is ae zero. Then both integrals vanish.
  by_cases H1 : g =ᵐ[volume] 0
  · have A : ∫⁻ ω, (∫⁻ t in (Iic (f ω)), g t) ∂μ = 0 := by
      have : ∀ ω, ∫⁻ t in (Iic (f ω)), g t = ∫⁻ t in (Iic (f ω)), 0 := by
        intro ω
        apply setLIntegral_congr_fun_ae measurableSet_Iic
        filter_upwards [H1]
        intro a h _
        exact h
      simp [this]
    have B : ∫⁻ t, μ {a : α | t ≤ f a} * g t = 0 := by
      have : (fun t ↦ μ {a : α | t ≤ f a} * g t)
        =ᵐ[volume] 0 := by
          filter_upwards [H1] with t ht using by simp [ht]
      simp [lintegral_congr_ae this]
    rw [A, B]
  -- easy case where both sides are obviously infinite: for some `s`, one has
  -- `μ {a : α | s < f a} = ∞` and moreover `g` is not ae zero on `[0, s]`.
  by_cases! H2 : ∃ s > 0, 0 < ∫⁻ t in (Iic s), g t ∧ μ {a : α | s < f a} = ∞
  · rcases H2 with ⟨s, s_pos, hs, h's⟩
    /- The first integral is infinite, as for `t ∈ [0, s]` one has `μ {a : α | t ≤ f a} = ∞`,
    and moreover the additional integral `g` is not uniformly zero. -/
    have A : ∫⁻ t, μ {a : α | t ≤ f a} * g t = ∞ := by
      rw [eq_top_iff]
      calc
      ∞ = ∫⁻ t in Iic s, ∞ * g t := by
          rw [lintegral_const_mul'' _ (g_intble _ s_pos), ENNReal.top_mul hs.ne']
      _ ≤ ∫⁻ t in Iic s, μ {a : α | t ≤ f a} * g t := by
          apply setLIntegral_mono' measurableSet_Iic (fun x hx ↦ ?_)
          rw [← h's]
          gcongr
          exact fun ha ↦ hx.trans (le_of_lt ha)
      _ ≤ ∫⁻ t, μ {a : α | t ≤ f a} * g t := by
          apply setLIntegral_le_lintegral
    /- The second integral is infinite, as one integrates among other things on those `ω` where
    `f ω > s`: this is an infinite measure set, and on it the integrand is bounded below
    by `∫ t in 0..s, g t` which is positive. -/
    have B : ∫⁻ ω, (∫⁻ t in (Iic (f ω)), g t) ∂μ = ∞ := by
      rw [eq_top_iff]
      calc
      ∞ = ∫⁻ _ in {a | s < f a}, (∫⁻ t in (Iic s), g t) ∂μ := by
          simp only [lintegral_const, MeasurableSet.univ, Measure.restrict_apply, univ_inter,
            h's]
          rw [ENNReal.mul_top hs.ne']
      _ ≤ ∫⁻ ω in {a | s < f a}, (∫⁻ t in (Iic (f ω)), g t) ∂μ := by
          apply setLIntegral_mono' (measurableSet_lt measurable_const f_mble) (fun a ha ↦ ?_)
          --apply ENNReal.ofReal_le_ofReal
          gcongr
          exact ha.le
      _ ≤ ∫⁻ ω, (∫⁻ t in (Iic (f ω)), g t) ∂μ := setLIntegral_le_lintegral _ _
    rw [A, B]
  /- It remains to handle the interesting case, where `g` is not zero, but both integrals are
  not obviously infinite. Let `M` be the largest number such that `g = 0` on `[0, M]`. Then we
  may restrict `μ` to the points where `f ω > M` (as the other ones do not contribute to the
  integral). The restricted measure `ν` is sigma-finite, as `μ` gives finite measure to
  `{ω | f ω > a}` for any `a > M` (otherwise, we would be in the easy case above), so that
  one can write (a full measure subset of) the space as the countable union of the finite measure
  sets `{ω | f ω > uₙ}` for `uₙ` a sequence decreasing to `M`. Therefore,
  this case follows from the case where the measure is sigma-finite, applied to `ν`. -/
  have M_bdd : BddAbove {s | g =ᵐ[volume.restrict (Iic s)] 0} := by
    contrapose! H1
    have : ∀ (n : ℕ), g =ᵐ[volume.restrict (Iic (n : ℝ≥0∞))] 0 := by
      intro n
      rcases not_bddAbove_iff.1 H1 n with ⟨s, hs, ns⟩
      exact ae_restrict_of_ae_restrict_of_subset (Iic_subset_Iic.mpr ns.le) hs
    have Hg : g =ᵐ[volume.restrict (⋃ (n : ℕ), (Iic (n : ℝ≥0∞)))] 0 :=
      (ae_restrict_iUnion_iff _ _).2 this
    have : (⋃ (n : ℕ), Iic (n : ℝ≥0∞)) = Set.univ :=
      --iUnion_Ioc_eq_Ioi_self_iff.2 (fun x _ ↦ exists_nat_ge x)
      --TODO: not true in the current form! -> maybe use integral over NNReal instead of ENNReal
      sorry
    rwa [this, Measure.restrict_univ] at Hg
  -- let `M` be the largest number such that `g` vanishes ae on `(0, M]`.
  let M := sSup {s | g =ᵐ[volume.restrict (Iic s)] 0}
  have zero_mem : 0 ∈ {s | g =ᵐ[volume.restrict (Iic s)] 0} := by
    simp only [mem_setOf_eq]
    have : Iic (0 : ℝ≥0∞) = {0} := by unfold Iic; simp
    rw [this]
    simp only [restrict_singleton, measure_singleton, zero_smul, ae_zero]
    trivial
  have M_nonneg : 0 ≤ M := le_sSup zero_mem --M_bdd --zero_mem
  -- Then the function `g` indeed vanishes ae on `(0, M]`.
  have hgM : g =ᵐ[volume.restrict (Iic M)] 0 := by
    --rw [← restrict_Iic_eq_restrict_Ioc]
--#check lintegral_comp_eq_lintegral_meas_le_mul_of_measurable
    obtain ⟨u, -, uM, ulim⟩ : ∃ u, StrictMono u ∧ (∀ (n : ℕ), u n < Ioo 0 M) ∧ Tendsto u atTop (𝓝 M) :=
      --sorry
      exists_seq_strictMono_tendsto' M
    have I : ∀ n, g =ᵐ[volume.restrict (Iic (u n))] 0 := by
      intro n
      obtain ⟨s, hs, uns⟩ : ∃ s, g =ᶠ[ae (Measure.restrict volume (Iic s))] 0 ∧ u n < s :=
        exists_lt_of_lt_csSup (Set.nonempty_of_mem zero_mem) (uM n)
      exact ae_restrict_of_ae_restrict_of_subset (Iic_subset_Iic.mpr uns.le) hs
    have : g =ᵐ[volume.restrict (⋃ n, Iic (u n))] 0 := (ae_restrict_iUnion_iff _ _).2 I
    apply ae_restrict_of_ae_restrict_of_subset _ this
    rintro x xM
    obtain ⟨n, hn⟩ : ∃ n, x < u n := sorry --((tendsto_order.1 ulim).1 _ xM).exists
    --exact mem_iUnion.2 ⟨n, ⟨x_pos, hn.le⟩⟩
    sorry
  -- Let `ν` be the restriction of `μ` to those points where `f a > M`.
  let ν := μ.restrict {a : α | M < f a}
  -- This measure is sigma-finite (this is the whole point of the argument).
  have : SigmaFinite ν := by
    obtain ⟨u, -, uM, ulim⟩ : ∃ u, StrictAnti u ∧ (∀ (n : ℕ), M < u n) ∧ Tendsto u atTop (𝓝 M) :=
      sorry
      --exists_seq_strictAnti_tendsto M
    let s : ν.FiniteSpanningSetsIn univ :=
    { set := fun n ↦ {a | f a ≤ M} ∪ {a | u n < f a}
      set_mem := fun _ ↦ trivial
      finite := by
        intro n
        have I : ν {a | f a ≤ M} = 0 := by
          rw [Measure.restrict_apply (measurableSet_le f_mble measurable_const)]
          convert measure_empty (μ := μ)
          rw [← disjoint_iff_inter_eq_empty]
          exact disjoint_left.mpr (fun a ha ↦ by simpa using ha)
        have J : μ {a | u n < f a} < ∞ := by
          rw [lt_top_iff_ne_top]
          apply H2 _ (M_nonneg.trans_lt (uM n))
          by_contra H3
          rw [not_lt] at H3
          have J : ∀ᵐ t ∂(volume.restrict (Iic (u n))), g t = 0 := by
            rwa [le_zero_iff,
                 lintegral_eq_zero_iff' (g_intble _ (M_nonneg.trans_lt (uM n)))] at H3
          have : u n ≤ M := le_csSup M_bdd J
          exact lt_irrefl _ (this.trans_lt (uM n))
        refine lt_of_le_of_lt (measure_union_le _ _) ?_
        rw [I, zero_add]
        apply lt_of_le_of_lt _ J
        exact restrict_le_self _
      spanning := by
        apply eq_univ_iff_forall.2 (fun a ↦ ?_)
        rcases le_or_gt (f a) M with ha|ha
        · exact mem_iUnion.2 ⟨0, Or.inl ha⟩
        · obtain ⟨n, hn⟩ : ∃ n, u n < f a := ((tendsto_order.1 ulim).2 _ ha).exists
          exact mem_iUnion.2 ⟨n, Or.inr hn⟩ }
    exact ⟨⟨s⟩⟩
  -- the first integrals with respect to `μ` and to `ν` coincide, as points with `f a ≤ M` are
  -- weighted by zero as `g` vanishes there.
  have A : ∫⁻ ω, (∫⁻ t in Iic (f ω), g t) ∂μ
         = ∫⁻ ω, (∫⁻ t in Iic (f ω), g t) ∂ν := by
    have meas : MeasurableSet {a | M < f a} := measurableSet_lt measurable_const f_mble
    have I : ∫⁻ ω in {a | M < f a}ᶜ, (∫⁻ t in Iic (f ω), g t) ∂μ
             = ∫⁻ _ in {a | M < f a}ᶜ, 0 ∂μ := by
      apply setLIntegral_congr_fun meas.compl (fun s hs ↦ ?_)
      have : ∫⁻ t in Iic (f s), g t = ∫⁻ t in Iic (f s), 0 := by
        apply setLIntegral_congr_fun_ae measurableSet_Iic
        rw [← ae_restrict_iff'₀ (by measurability)]
        apply ae_mono (restrict_mono ?_ le_rfl) hgM
        simpa using hs
      simp only [mem_compl_iff, mem_setOf_eq, not_lt] at hs
      simp [this]
    simp only [lintegral_const, zero_mul] at I
    rw [← lintegral_add_compl _ meas, I, add_zero]
  -- the second integrals with respect to `μ` and to `ν` coincide, as points with `f a ≤ M` do not
  -- contribute to either integral since the weight `g` vanishes.
  have B : ∫⁻ t, μ {a : α | t ≤ f a} * g t
           = ∫⁻ t, ν {a : α | t ≤ f a} * g t := by
    have B1 : ∫⁻ t in Iic M, μ {a : α | t ≤ f a} * g t
         = ∫⁻ t in Iic M, ν {a : α | t ≤ f a} * g t := by
      apply lintegral_congr_ae
      filter_upwards [hgM] with t ht
      simp [ht]
    have B2 : ∫⁻ t in Ioi M, μ {a : α | t ≤ f a} * g t
              = ∫⁻ t in Ioi M, ν {a : α | t ≤ f a} * g t := by
      apply setLIntegral_congr_fun measurableSet_Ioi (fun t ht ↦ ?_)
      rw [Measure.restrict_apply (measurableSet_le measurable_const f_mble)]
      congr 3
      exact (inter_eq_left.2 (fun a ha ↦ (mem_Ioi.1 ht).trans_le ha)).symm
    have I : Set.univ = Iic M ∪ Ioi M := Iic_union_Ioi.symm
    have J : Disjoint (Iic M) (Ioi M) := Iic_disjoint_Ioi le_rfl
    rw [← setLIntegral_univ]
    symm
    rw [← setLIntegral_univ, I, lintegral_union measurableSet_Ioi J,
        lintegral_union measurableSet_Ioi J, B1, B2]
  -- therefore, we may replace the integrals w.r.t. `μ` with integrals w.r.t. `ν`, and apply the
  -- result for sigma-finite measures.
  rw [A, B]
  exact lintegral_comp_eq_lintegral_meas_le_mul_of_measurable_of_sigmaFinite'
    ν f_mble g_mble
-/

/-- The layer cake formula / **Cavalieri's principle** / tail probability formula:

Let `f` be a non-negative measurable function on a measure space. Let `G` be an
increasing absolutely continuous function on the positive real line, vanishing at the origin,
with derivative `G' = g`. Then the integral of the composition `G ∘ f` can be written as
the integral over the positive real line of the "tail measures" `μ {ω | f(ω) > t}` of `f`
weighted by `g`.

Roughly speaking, the statement is: `∫⁻ (G ∘ f) ∂μ = ∫⁻ t in 0..∞, g(t) * μ {ω | f(ω) > t}`.

See `MeasureTheory.lintegral_comp_eq_lintegral_meas_le_mul` for a version with sets of the form
`{ω | f(ω) ≥ t}` instead. -/
theorem lintegral_comp_eq_lintegral_distribution_mul (μ : Measure α)
    (f_mble : Measurable f) (g_mble : AEMeasurable g) :
    ∫⁻ ω, (∫⁻ t in (Iio (f ω)), g t) ∂μ =
      ∫⁻ t, distribution f t μ * g t := by
  sorry

theorem lintegral_comp_eq_lintegral_distribution_mul' (μ : Measure α)
    (f_mble : AEMeasurable f μ) (g_mble : AEMeasurable g) :
    ∫⁻ ω, (∫⁻ t in (Iio (f ω)), g t) ∂μ =
      ∫⁻ t, distribution f t μ * g t := by
  sorry

/-- The standard case of the layer cake formula / Cavalieri's principle / tail probability formula:

For a nonnegative function `f` on a measure space, the Lebesgue integral of `f` can
be written (roughly speaking) as: `∫⁻ f ∂μ = ∫⁻ t in 0..∞, μ {ω | f(ω) ≥ t}`.

See `MeasureTheory.lintegral_eq_lintegral_meas_lt` for a version with sets of the form
`{ω | f(ω) > t}` instead. -/
theorem lintegral_eq_lintegral_distribution (μ : Measure α)
    (f_mble : AEMeasurable f μ) :
    ∫⁻ ω, f ω ∂μ = ∫⁻ t, distribution f t μ := by
  sorry

end Layercake

section LayercakeLE

variable {α : Type*} [MeasurableSpace α]
variable {f : α → ℝ≥0∞} {g : ℝ≥0∞ → ℝ≥0∞}

/-- The layer cake formula / Cavalieri's principle / tail probability formula:

Let `f` be a non-negative measurable function on a measure space. Let `G` be an
increasing absolutely continuous function on the positive real line, vanishing at the origin,
with derivative `G' = g`. Then the integral of the composition `G ∘ f` can be written as
the integral over the positive real line of the "tail measures" `μ {ω | f(ω) ≥ t}` of `f`
weighted by `g`.

Roughly speaking, the statement is: `∫⁻ (G ∘ f) ∂μ = ∫⁻ t in 0..∞, g(t) * μ {ω | f(ω) ≥ t}`.

See `lintegral_comp_eq_lintegral_distribution_mul` for a version with sets of the form `{ω | f(ω) > t}`
instead. -/
--#check lintegral_comp_eq_lintegral_distribution_mul'
theorem lintegral_comp_eq_lintegral_meas_le_mul' (μ : Measure α)
    (f_mble : AEMeasurable f μ) (g_mble : AEMeasurable g) :
    ∫⁻ ω, (∫⁻ t in Set.Iio (f ω), g t) ∂μ =
      ∫⁻ t, μ {a : α | t ≤ f a} * g t := by
  sorry

/-- The standard case of the layer cake formula / Cavalieri's principle / tail probability formula:

For a nonnegative function `f` on a measure space, the Lebesgue integral of `f` can
be written (roughly speaking) as: `∫⁻ f ∂μ = ∫⁻ t in 0..∞, μ {ω | f(ω) > t}`.

See `lintegral_eq_lintegral_meas_le` for a version with sets of the form `{ω | f(ω) ≥ t}`
instead. -/
theorem lintegral_eq_lintegral_meas_le' (μ : Measure α)
    (f_mble : AEMeasurable f μ) :
    ∫⁻ ω, f ω ∂μ = ∫⁻ t, μ {a : α | t ≤ f a} := by
  sorry

end LayercakeLE

end MeasureTheory
