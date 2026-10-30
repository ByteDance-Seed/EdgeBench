module

public import Mathlib.MeasureTheory.Constructions.UnitInterval
public import Carleson.ToMathlib.MeasureTheory.Measure.NNReal
public import Carleson.ToMathlib.MeasureTheory.Integral.Layercake
public import Carleson.ToMathlib.Distribution
public import Carleson.ToMathlib.NoAtoms

@[expose] public section

noncomputable section

-- Upstreaming status: Needs significant clean-up (refactoring, code style, extracting lemmas etc.)

open scoped NNReal ENNReal

variable {α ε ε' : Type*} {m : MeasurableSpace α}

namespace MeasureTheory

section rearrangement
variable [ENorm ε] [ENorm ε']

/-! # Decreasing rearrangements `f^#` -/
/- many lemma statements were initially taken from
https://github.com/fpvandoorn/BonnAnalysis/blob/master/BonnAnalysis/LorentzSpace.lean -/

/-- The decreasing rearrangement function `f^#`. It equals `μ univ` for `t = 0`.
Note that unlike the notes, we also define this for `t = ∞`. -/
def rearrangement (f : α → ε) (t : ℝ≥0∞) (μ : Measure α) : ℝ≥0∞ :=
  sInf {σ | distribution f σ μ ≤ t}

variable {f : α → ε} {g : α → ε'} {μ : Measure α} {x y : ℝ≥0∞}

@[simp] lemma rearrangement_top : rearrangement f ⊤ μ = 0 := by
  sorry

lemma rearrangement_eq_zero_of_ae_zero_enorm (h : enorm ∘ f =ᵐ[μ] 0) :
    rearrangement f x μ = 0 := by
  sorry

lemma rearrangement_eq_zero_of_ae_zero {ε} [TopologicalSpace ε] [ESeminormedAddMonoid ε] {f : α → ε}
  (h : f =ᵐ[μ] 0) :
    rearrangement f x μ = 0 := by
  sorry

@[simp] lemma rearrangement_zero {ε} [TopologicalSpace ε] [ENormedAddMonoid ε] :
    rearrangement (0 : α → ε) x μ = 0 := by
  sorry

@[gcongr] lemma rearrangement_antitone' (h : x ≤ y) :
    rearrangement f y μ ≤ rearrangement f x μ := by
  sorry

lemma rearrangement_antitone : (Antitone (fun t ↦ rearrangement f t μ)) := by
  sorry

@[gcongr] lemma rearrangement_mono_fun (h : ∀ᵐ x ∂μ, ‖f x‖ₑ ≤ ‖g x‖ₑ) :
    rearrangement f x μ ≤ rearrangement g x μ := by
  sorry

@[gcongr] lemma rearrangement_le_rearrangement (h1 : ∀ᵐ x ∂μ, ‖f x‖ₑ ≤ ‖g x‖ₑ) (h2 : x ≤ y) :
    rearrangement f y μ ≤ rearrangement g x μ := by
  sorry

lemma rearrangment_eq_rearrangement_of_distribution_eq_distribution {β : Type*}
  {m' : MeasurableSpace β} {ν : Measure β} {g : β → ε'} {t : ℝ≥0∞}
  (h : ∀ ⦃s⦄, distribution f s μ = distribution g s ν) :
    rearrangement f t μ = rearrangement g t ν := by
  sorry

@[measurability, fun_prop]
lemma rearrangement_measurable₀ : Measurable (fun t ↦ rearrangement f t μ) := by
  sorry

@[measurability, fun_prop]
lemma rearrangement_measurable {α' : Type*} {m : MeasurableSpace α'} {g : α' → ℝ≥0∞}
  (hg : Measurable g) :
    Measurable (fun y : α' ↦ rearrangement f (g y) μ) := by
  sorry

lemma rearrangement_distribution_le : rearrangement f (distribution f x μ) μ ≤ x := by
  sorry

lemma distribution_rearrangement_le : distribution f (rearrangement f x μ) μ ≤ x := by
  sorry

-- Lemma 1.1.22 of [Ian Tice]
lemma lt_rearrangement_iff_lt_distribution {f : α → ε} {μ : Measure α} {t : ℝ≥0∞} {y : ℝ≥0∞} :
    y < rearrangement f t μ ↔ t < distribution f y μ := by
  sorry

lemma rearrangement_le_iff_distribution_le {f : α → ε} {μ : Measure α} {t : ℝ≥0∞} {y : ℝ≥0∞} :
    rearrangement f t μ ≤ y ↔ distribution f y μ ≤ t := by
  sorry

@[simp]
lemma distribution_rearrangement_eq_distribution {f : α → ε} {μ : Measure α} {t : ℝ≥0∞} :
    distribution (rearrangement f · μ) t volume = distribution f t μ := by
  sorry

@[simp]
lemma support_rearrangement_eq {ε} [TopologicalSpace ε] [ENormedAddMonoid ε] {f : α → ε} :
    (rearrangement f · μ).support = Set.Iio (μ f.support) := by
  sorry

lemma ae_eq_zero_of_rearrangement_ae_eq_zero {ε} [TopologicalSpace ε] [ENormedAddMonoid ε] {f : α → ε}
  (h : (fun t ↦ rearrangement f t μ) =ᵐ[volume] 0) :
    f =ᵐ[μ] 0 := by
  sorry

-- Lemma 1.1.22 of [Ian Tice]
lemma continuousWithinAt_rearrangement :
    ContinuousWithinAt (rearrangement f · μ) (Set.Ici x) x := by
  sorry

lemma rearrangement_eq_rearrangement_prod {ε}
  [ENorm ε] {f : α → ε} {t : ℝ≥0∞}
  {β : Type*} {m' : MeasurableSpace β} {ν : Measure β} [IsProbabilityMeasure ν] :
    rearrangement f t μ = rearrangement (fun x : α × β ↦ f x.1) t (μ.prod ν) := by
  sorry

-- Lemma 1.1.24 of [Ian Tice]
lemma rearrangement_indicator_le {ε} [TopologicalSpace ε] [ESeminormedAddMonoid ε] {f : α → ε}
  {X : Set α} :
    rearrangement (X.indicator f) x μ ≤
      Set.indicator (Set.Iio (μ X)) (rearrangement f · μ) x := by
  sorry

@[simp]
lemma rearrangement_indicator_const {ε} [TopologicalSpace ε] [ESeminormedAddMonoid ε] {s : Set α} {a : ε} :
  rearrangement (s.indicator (Function.const _ a)) x μ
    = ((Set.Iio (μ s)).indicator (Function.const _ ‖a‖ₑ) x) := by
  sorry

lemma rearrangement_const_smul {f : α → ℝ≥0∞} {a : ℝ≥0∞} :
    rearrangement (a • f) x μ = a * rearrangement f x μ := by
  sorry

section superlevelSet

lemma rearrangement_indicator_superlevelSet {ε} [TopologicalSpace ε] [ENormedAddMonoid ε]
  {f : α → ε} {t : ℝ≥0∞} :
    rearrangement ((superlevelSet f t).indicator f) x μ
      = (superlevelSet (rearrangement f · μ) t).indicator (rearrangement f · μ) x := by
  sorry

lemma rearrangement_indicator_superlevelSet_compl {ε} [TopologicalSpace ε] [ENormedAddMonoid ε]
  {f : α → ε} (hf : AEStronglyMeasurable f μ) {t : ℝ≥0∞} (ht : distribution f t μ ≠ ∞) :
    rearrangement ((superlevelSet f t)ᶜ.indicator f) x μ
      = rearrangement f (x + distribution f t μ) μ := by
  sorry

end superlevelSet

section comp

lemma measure_enorm_mem_eq_volume_rearrangement_mem_of_support_finite' {ε} [TopologicalSpace ε]
  [ENormedAddMonoid ε]
  {f : α → ε} (hf : AEStronglyMeasurable f μ) (hf' : μ f.support < ∞) {s : Set ℝ≥0∞}
  (hs : MeasurableSet s) :
    μ {x | ‖f x‖ₑ ∈ s \ {0}} = volume {x | rearrangement f x μ ∈ s \ {0}} := by
  sorry

lemma measure_enorm_mem_eq_volume_rearrangement_mem_of_support_finite {ε} [TopologicalSpace ε]
  [ENormedAddMonoid ε]
  {f : α → ε} (hf : AEStronglyMeasurable f μ) (hf' : μ f.support < ∞) {s : Set ℝ≥0∞}
  (hs : MeasurableSet s) (zero_notin_s : 0 ∉ s) :
    μ {x | ‖f x‖ₑ ∈ s} = volume {x | rearrangement f x μ ∈ s} := by
  sorry

lemma measure_enorm_mem_eq_volume_rearrangement_mem' {ε} [TopologicalSpace ε] [ENormedAddMonoid ε]
  {f : α → ε} (hf : AEStronglyMeasurable f μ) {s : Set ℝ≥0∞}
  (hs : MeasurableSet s) (zero_notin_s : 0 ∉ s) (h : ∃ T, (∀ t ∈ s, T < t) ∧ distribution f T μ < ∞) :
    μ {x | ‖f x‖ₑ ∈ s} = volume {x | rearrangement f x μ ∈ s} := by
  sorry

lemma measure_enorm_eq_eq_volume_rearrangement_eq {ε} [TopologicalSpace ε] [ENormedAddMonoid ε]
  {f : α → ε} (hf : AEStronglyMeasurable f μ) {a : ℝ≥0∞}
  (ha : distribution f a μ ≠ ∞) (h : μ {x | ‖f x‖ₑ = a} = ⊤) :
    volume {x | rearrangement f x μ = a} = ⊤ := by
  sorry

lemma measure_enorm_mem_eq_volume_rearrangement_mem {ε} [TopologicalSpace ε] [ENormedAddMonoid ε]
  {f : α → ε} (hf : AEStronglyMeasurable f μ) {s : Set ℝ≥0∞}
  (hs : MeasurableSet s) (zero_notin_s : 0 ∉ s) (inf_not_mem : sInf s ∉ s)
  (hs' : ∀ t ∈ s, distribution f t μ < ∞) :
    μ {x | ‖f x‖ₑ ∈ s} = volume {x | rearrangement f x μ ∈ s} := by
  sorry

lemma distribution_comp_eq_distribution_comp_rearrangement' {ε} [TopologicalSpace ε] [ENormedAddMonoid ε] {f : α → ε}
  (hf : AEStronglyMeasurable f μ) {g : ℝ≥0∞ → ℝ≥0∞} (hg : Measurable g) (g_zero : g 0 = 0)
  {t : ℝ≥0∞} (h : ∃ T, (∀ s ≤ T, g s ≤ t) ∧ distribution f T μ < ∞) :
    distribution (fun x ↦ g ‖f x‖ₑ) t μ = distribution (g ∘ (rearrangement f · μ)) t volume := by
  sorry

lemma distribution_comp_eq_distribution_comp_rearrangement {ε} [TopologicalSpace ε] [ENormedAddMonoid ε] {f : α → ε}
  (hf : AEStronglyMeasurable f μ) (hf' : ∀ σ > 0, distribution f σ μ < ∞) {g : ℝ≥0∞ → ℝ≥0∞} {t : ℝ≥0∞}
  (hg : Measurable g) (g_zero : g 0 = 0) :
    distribution (fun x ↦ g ‖f x‖ₑ) t μ = distribution (g ∘ (rearrangement f · μ)) t volume := by
  sorry

lemma lintegral_comp_rearrangement' {ε} [TopologicalSpace ε] [ENormedAddMonoid ε] {f : α → ε}
  (hf : AEStronglyMeasurable f μ) {g : ℝ≥0∞ → ℝ≥0∞} (hg : Measurable g) (g_zero : g 0 = 0)
  (hg' : ∀ t > 0, distribution f t μ = ∞ → ∃ S > 0, ∀ y > t, S < g y) :
    ∫⁻ x, g ‖f x‖ₑ ∂μ = ∫⁻ t, g (rearrangement f t μ) := by
  sorry

lemma lintegral_comp_rearrangement_of_distribution_finite {ε} [TopologicalSpace ε]
  [ENormedAddMonoid ε] {f : α → ε} (hf : AEStronglyMeasurable f μ)
  (hf' : ∀ t > 0, distribution f t μ ≠ ⊤) {g : ℝ≥0∞ → ℝ≥0∞} (hg : Measurable g) (g_zero : g 0 = 0) :
    ∫⁻ x, g ‖f x‖ₑ ∂μ = ∫⁻ t, g (rearrangement f t μ) := by
  sorry

lemma lintegral_comp_rearrangement {ε} [TopologicalSpace ε] [ENormedAddMonoid ε] {f : α → ε}
  (hf : AEStronglyMeasurable f μ) {g : ℝ≥0∞ → ℝ≥0∞} (hg : Measurable g) (g_zero : g 0 = 0)
  (hg' : ∀ t > 0, ∃ S > 0, ∀ y > t, S < g y) :
    ∫⁻ x, g ‖f x‖ₑ ∂μ = ∫⁻ t, g (rearrangement f t μ) := by
  sorry

lemma lintegral_comp_rearrangement_of_strictmono {ε} [TopologicalSpace ε] [ENormedAddMonoid ε] {f : α → ε}
  (hf : AEStronglyMeasurable f μ) {g : ℝ≥0∞ → ℝ≥0∞} (hg : Measurable g) (g_zero : g 0 = 0)
  (hg' : StrictMono g) :
    ∫⁻ x, g ‖f x‖ₑ ∂μ = ∫⁻ t, g (rearrangement f t μ) := by
  sorry

--TODO: more versions with more general assumptions on g

-- Lemma 1.1.22 of [Ian Tice]
lemma lintegral_rearrangement_pow {ε} [TopologicalSpace ε] [ENormedAddMonoid ε] {f : α → ε}
  (hf : AEStronglyMeasurable f μ) {p : ℝ} (hp : 0 < p) :
    ∫⁻ t, (rearrangement f t μ) ^ p = ∫⁻ x, ‖f x‖ₑ ^ p ∂μ := by
  sorry

lemma lintegral_rearrangement {ε} [TopologicalSpace ε] [ENormedAddMonoid ε] {f : α → ε}
  (hf : AEStronglyMeasurable f μ) :
    ∫⁻ t, (rearrangement f t μ) = ∫⁻ x, ‖f x‖ₑ ∂μ := by
  sorry

end comp

lemma rearrangement_add_le {ε} [TopologicalSpace ε] [ESeminormedAddMonoid ε] {f g : α → ε} :
    rearrangement (f + g) (x + y) μ ≤ rearrangement f x μ + rearrangement g y μ := by
  sorry

-- Lemma 1.1.22 of [Ian Tice]
lemma sSup_rearrangement :
    ⨆ t > 0, rearrangement f t μ = rearrangement f 0 μ := by
  sorry

section eLpNorm

-- Lemma 1.1.22 of [Ian Tice]
lemma rearrangement_zero_eq_eLpNormEssSup :
    rearrangement f 0 μ = eLpNormEssSup f μ  := by
  sorry

--TODO: do we need these lemmas?
/-
lemma eLpNormEssSup_rearrangement {ε} [TopologicalSpace ε] [ENormedAddMonoid ε] {f : α → ε} :
    eLpNormEssSup (rearrangement f · μ) volume = eLpNormEssSup f μ := by
  /-
  rw [eLpNorm, ENNReal.rpow_zero, one_mul]
  exact rearrangement_zero_eq_eLpNormEssSup
  -/
  --distribution_eLpNormEssSup
  sorry
-/

lemma eLpNorm'_rearrangement {ε} [TopologicalSpace ε] [ENormedAddMonoid ε] {f : α → ε}
  (hf : AEStronglyMeasurable f μ) {p : ℝ} (hp : 0 < p) :
    eLpNorm' (rearrangement f · μ) p volume = eLpNorm' f p μ := by
  sorry

--TODO: do we need these lemmas?
/-
lemma eLpNorm_rearrangement {ε} [TopologicalSpace ε] [ENormedAddMonoid ε] {f : α → ε}
  (hf : AEStronglyMeasurable f μ) {p : ℝ≥0∞} :
    eLpNorm (rearrangement f · μ) p volume = eLpNorm f p μ := by
  unfold eLpNorm
  split_ifs with p_zero p_top
  · rfl
  · exact eLpNormEssSup_rearrangement
  · exact eLpNorm'_rearrangement hf (ENNReal.toReal_pos p_zero p_top)
-/

end eLpNorm

section lintegral

--TODO: prove these lemmas when needed
/-
--Theorem 4.15 in https://doi.org/10.1007/978-3-319-30034-4
/-- Hardy-Littlewood rearrangement inequality -/
lemma lintegral_mul_le_lintegral_rearrangement_mul_rearrangement {ε} [TopologicalSpace ε] [ContinuousENorm ε] {f g : α → ε}
  (hf : AEStronglyMeasurable f μ) (hg : AEStronglyMeasurable g μ) :
    ∫⁻ x, ‖f x‖ₑ * ‖g x‖ₑ ∂μ ≤ ∫⁻ t, rearrangement f t μ * rearrangement g t μ := by
  sorry

lemma lintegral_withDensity_le_lintegral_rearrangement_withDensity {ε} [TopologicalSpace ε]
  [ContinuousENorm ε] {f : α → ε} {d : α → ℝ≥0∞} (hf : AEStronglyMeasurable f μ)
  (hd : AEMeasurable d μ) :
    ∫⁻ x, ‖f x‖ₑ ∂μ.withDensity d ≤ ∫⁻ t, rearrangement f t μ ∂volume.withDensity (rearrangement d · μ) := by
    rw [lintegral_withDensity_eq_lintegral_mul₀' hd (by fun_prop)]
    dsimp only [Pi.mul_apply]
    conv in (d _) => rw [← enorm_eq_self (d _)]
    calc _
      _ ≤ ∫⁻ s, rearrangement d s μ * rearrangement f s μ := by
        apply lintegral_mul_le_lintegral_rearrangement_mul_rearrangement hd.aestronglyMeasurable hf.enorm.aestronglyMeasurable
      _ = ∫⁻ t, rearrangement f t μ ∂volume.withDensity (rearrangement d · μ) := by
        rw [lintegral_withDensity_eq_lintegral_mul₀' (by fun_prop) (by fun_prop)]
        simp
-/

-- Lemma 1.1.24 of [Ian Tice]
lemma setLIntegral_enorm_le_lintegral_rearrangement {ε} [TopologicalSpace ε] [ENormedAddMonoid ε] {f : α → ε}
  (hf : AEStronglyMeasurable f μ) {X : Set α} (hX : MeasurableSet X) :
    ∫⁻ x in X, ‖f x‖ₑ ∂μ ≤
      ∫⁻ t in (Set.Iio (μ X)), rearrangement f t μ := by
  sorry

lemma setLIntegral_enorm_eq {ε} [TopologicalSpace ε] [ContinuousENorm ε] {f : α → ε}
  (hf : AEStronglyMeasurable f μ) {X : Set α} (hX : NullMeasurableSet X μ) :
    ∫⁻ x in X, ‖f x‖ₑ ∂μ =
      ∫⁻ t, μ (X ∩ {x | t < ‖f x‖ₑ}) := by
  sorry

lemma setLIntegral_eq {f : α → ℝ≥0∞}
  (hf : AEMeasurable f μ) {X : Set α} (hX : NullMeasurableSet X μ) :
    ∫⁻ x in X, f x ∂μ =
      ∫⁻ t, μ (X ∩ {x | t < f x}) := by
  sorry

lemma lintegral_rearrangement_eq' {f : α → ε} {t : ℝ≥0∞} :
    ∫⁻ s in Set.Iio t, rearrangement f s μ = ∫⁻ s, min (distribution f s μ) t := by
  sorry

lemma lintegral_rearrangement_eq'' {ε} [TopologicalSpace ε] [ContinuousENorm ε] {f : α → ε}
  (hf : AEStronglyMeasurable f μ) {t : ℝ≥0∞} :
    ∫⁻ s in Set.Iio (distribution f t μ), rearrangement f s μ = ∫⁻ x in {y | t < ‖f y‖ₑ}, ‖f x‖ₑ ∂μ := by
  sorry

--Theorem 4.17 in https://doi.org/10.1007/978-3-319-30034-4
lemma lintegral_rearrangement_eq {ε} [TopologicalSpace ε] [ContinuousENorm ε] [NoAtoms' μ] {f : α → ε}
  (hf : AEStronglyMeasurable f μ) {t : ℝ≥0∞} :
    ∫⁻ s in Set.Iio t, rearrangement f s μ
      = ⨆ (E : Set α) (_ : NullMeasurableSet E μ) (_ : μ E ≤ t), ∫⁻ x in E, ‖f x‖ₑ ∂μ := by
  sorry

lemma lintegral_rearrangement_eq_and {ε} [TopologicalSpace ε] [ContinuousENorm ε] [NoAtoms' μ] {f : α → ε}
  (hf : AEStronglyMeasurable f μ) {t : ℝ≥0∞} :
    ∫⁻ s in Set.Iio t, rearrangement f s μ = ⨆ (E : Set α) (_ : NullMeasurableSet E μ ∧ μ E ≤ t), ∫⁻ x in E, ‖f x‖ₑ ∂μ := by
  sorry

lemma Antitone.lintegral_withDensity_le {f d : ℝ≥0∞ → ℝ≥0∞} (hf : Antitone f)
  (hf' : AEMeasurable f) (hd : d ≤ 1) (hd' : AEMeasurable d) :
    ∫⁻ t, f t ∂volume.withDensity d ≤ ∫⁻ t in Set.Iio (∫⁻ t, d t), f t := by
  sorry

/-
--Upgrade of Theorem 4.17 in https://doi.org/10.1007/978-3-319-30034-4
lemma lintegral_rearrangement_eq''' {ε} [TopologicalSpace ε] [ContinuousENorm ε] {f : α → ε}
  (hf : AEStronglyMeasurable f μ) {t : ℝ≥0∞} :
    ∫⁻ s in Set.Iio t, rearrangement f s μ =
      ⨆ (d : α → ℝ≥0∞) (_ : ∀ x, d x ≤ 1) (_ : ∫⁻ x, d x ∂μ = t), (∫⁻ x, ‖f x‖ₑ ∂μ.withDensity d) := by
  --TODO: might need to require some measurability of d
  apply le_antisymm
  · sorry --TODO: get this from lintegral_rearrangement_eq by taking product with the unit interval
  · simp only [iSup_le_iff]
    intro d d_le_one d_int
    apply (lintegral_withDensity_le_lintegral_rearrangement_withDensity hf sorry).trans --TODO: assume measurability for d?
    apply (Antitone.lintegral_withDensity_le rearrangement_antitone (by fun_prop) _ (by fun_prop)).trans_eq
    · congr
      rw [← d_int, lintegral_rearrangement sorry] --TODO: assume measurability for d?
      simp
    · intro x
      rw [rearrangement_le_iff_distribution_le]
      simp only [Pi.one_apply]
      unfold distribution
      convert zero_le'
      convert OuterMeasureClass.measure_empty μ
      aesop
-/

--Remark 4.18 in https://doi.org/10.1007/978-3-319-30034-4
lemma lintegral_rearrangement_add_rearrangement_le_add_lintegral {ε}
  [TopologicalSpace ε] [ESeminormedAddMonoid ε] [ContinuousAdd ε] {f g : α → ε}
    (hf : AEStronglyMeasurable f μ) (hg : AEStronglyMeasurable g μ) {t : ℝ≥0∞} :
      ∫⁻ (s : ℝ≥0∞) in Set.Iio t, rearrangement (f + g) s μ
        ≤ (∫⁻ (s : ℝ≥0∞) in Set.Iio t, rearrangement f s μ)
          + ∫⁻ (s : ℝ≥0∞) in Set.Iio t, rearrangement g s μ := by
  sorry

end lintegral

--TODO: do we need these lemmas?
/-
section Filter

open Filter Topology

-- Lemma 1.1.23 of [Ian Tice]
lemma tendsto_rearrangement [TopologicalSpace ε] {s : ℕ → α → ε}
  (hs : ∀ᶠ i in atTop, AEStronglyMeasurable (s i) μ) (hf : AEStronglyMeasurable f μ)
    (h2s : ∀ᵐ x ∂μ, Monotone (fun n ↦ ‖s n x‖ₑ))
      (h : ∀ᵐ x ∂μ, Tendsto (‖s · x‖ₑ) atTop (𝓝 ‖f x‖ₑ)) :
        Tendsto s atTop (𝓝 f) := sorry

-- Lemma 1.1.23 of [Ian Tice]
lemma liminf_rearrangement [TopologicalSpace ε] {s : ℕ → α → ε}
  (hs : ∀ᶠ i in atTop, AEStronglyMeasurable (s i) μ) (hf : AEStronglyMeasurable f μ)
    (h : ∀ᵐ x ∂μ, ‖f x‖ₑ ≤ liminf (‖s · x‖ₑ) atTop) :
      rearrangement f x μ ≤ liminf (fun i ↦ rearrangement (s i) x μ) atTop := sorry

end Filter
-/

--TODO: do we need a lemma like this?
/-
lemma _root_.ContinuousLinearMap.rearrangement_le {f : α → E₁} {g : α → E₂} :
    rearrangement (fun x ↦ L (f x) (g x)) (‖L‖₊ * x * y) μ ≤
    rearrangement f x μ + rearrangement g y μ := sorry
-/

end rearrangement

end MeasureTheory
