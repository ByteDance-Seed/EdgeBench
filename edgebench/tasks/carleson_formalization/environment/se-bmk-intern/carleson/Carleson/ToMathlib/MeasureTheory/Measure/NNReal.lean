module

public import Mathlib.MeasureTheory.Measure.Haar.OfBasis
public import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
public import Carleson.ToMathlib.MeasureTheory.Integral.Lebesgue

public section

open MeasureTheory NNReal ENNReal Set

noncomputable
instance NNReal.MeasureSpace : MeasureSpace ℝ≥0 := ⟨Measure.comap Subtype.val (volume : Measure ℝ)⟩

-- Upstreaming status:
-- The results in this file are generally worth having, but the proofs can be golfed
-- and refactored more (e.g., helper lemmas split out).

lemma NNReal.volume_val {s : Set ℝ≥0} : volume s = volume (Subtype.val '' s) := by
  sorry

-- sanity check: this measure is what you expect
example : volume (Ioo (3 : ℝ≥0) 5) = 2 := by
  sorry

-- integral over a function over NNReal equals the integral over the right set of real numbers

noncomputable
instance : MeasureSpace ℝ≥0∞ where
  volume := (volume : Measure ℝ≥0).map ENNReal.ofNNReal

--TODO: move these lemmas somewhere else?
lemma ENNReal.ofNNReal_preimage {s : Set ℝ≥0∞} :
    ENNReal.ofNNReal ⁻¹' s = ENNReal.toNNReal '' (s \ {⊤}) := by
  sorry

--TODO: move these lemmas somewhere else?
lemma ENNReal.map_toReal_eq_map_toReal_comap_ofReal {s : Set ℝ≥0∞} (h : ∞ ∉ s) :
    ENNReal.toReal '' s = NNReal.toReal '' (ENNReal.ofNNReal ⁻¹' s) := by
  sorry

lemma ENNReal.map_toReal_eq_map_toReal_comap_ofReal' {s : Set ℝ≥0∞} (h : ∞ ∈ s) :
    ENNReal.toReal '' s = NNReal.toReal '' (ENNReal.ofNNReal ⁻¹' s) ∪ {0}:= by
  sorry

lemma ENNReal.map_toReal_ae_eq_map_toReal_comap_ofReal {s : Set ℝ≥0∞} :
    ENNReal.toReal '' s =ᵐ[volume] NNReal.toReal '' (ENNReal.ofNNReal ⁻¹' s) := by
  sorry

lemma ENNReal.volume_val {s : Set ℝ≥0∞} (hs : MeasurableSet s) :
    volume s = volume (ENNReal.toReal '' s) := by
  sorry

instance : NoAtoms (@volume ℝ≥0∞ _) where
  measure_singleton := by
    intro x
    rw [ENNReal.volume_val (measurableSet_singleton _), image_singleton]
    simp

-- TODO: move this general result to an appropriate place
-- TODO: maybe generalize further to general measures restricted to a subtype
lemma Measure.Subtype.noAtoms {δ : Type*} [MeasureSpace δ] [NoAtoms (volume : Measure δ)] {p : δ → Prop} (hp : MeasurableSet p) :
    NoAtoms (Measure.Subtype.measureSpace.volume : Measure (Subtype p)) := by
  sorry

instance : NoAtoms (@volume ℝ≥0 _) := Measure.Subtype.noAtoms measurableSet_Ici

--TODO: move this general result to an appropriate place
--TODO: maybe generalize further to general measures restricted to a subtype
lemma Measure.Subtype.sigmaFinite {δ : Type*} [MeasureSpace δ] [sf : SigmaFinite (@volume δ _)] {p : δ → Prop} (hp : MeasurableSet p) :
    SigmaFinite (Measure.Subtype.measureSpace.volume : Measure (Subtype p)) := by
  sorry

instance : SigmaFinite (@volume ℝ≥0 _) := Measure.Subtype.sigmaFinite measurableSet_Ici

--TODO: move?
lemma measurableEmbedding_ofNNReal : MeasurableEmbedding ENNReal.ofNNReal := by
  sorry

instance : SigmaFinite (@volume ℝ≥0∞ _) := measurableEmbedding_ofNNReal.sigmaFinite_map

lemma NNReal.volume_eq_volume_ennreal {s : Set ℝ≥0} (hs : MeasurableSet (ofNNReal '' s)) :
    volume s = volume (ENNReal.ofNNReal '' s) := by
  sorry

theorem NNReal.smul_map_volume_mul_left {a : ℝ≥0} (h : a ≠ 0) :
    a • Measure.map (a * ·) volume = volume := by
  sorry

theorem NNReal.map_volume_mul_left {a : ℝ≥0} (h : a ≠ 0) :
    Measure.map (a * ·) volume = a⁻¹ • volume := by
  sorry

lemma ENNReal.volume_eq_volume_preimage {s : Set ℝ≥0∞} (hs : MeasurableSet s) :
    volume s = volume (ENNReal.ofReal ⁻¹' s ∩ Ici 0) := by
  sorry

lemma Ioo_zero_top_ae_eq_univ : Ioo 0 ∞ =ᶠ[ae volume] Set.univ := by
  sorry

lemma ae_in_Ioo_zero_top : ∀ᵐ x : ℝ≥0∞, x ∈ Ioo 0 ∞ := by
  sorry

lemma map_restrict_Ioi_eq_restrict_Ioi :
    (volume.restrict (Ioi 0)).map ENNReal.ofReal = volume.restrict (Ioi 0) := by
  sorry

lemma map_restrict_Ioi_eq_volume :
    (volume.restrict (Ioi 0)).map ENNReal.ofReal = volume := by
  sorry

--TODO: move somewhere else and add more lemmas for Ioo, Ico etc. ?
lemma NNReal.toReal_Iio_eq_Ico {b : ℝ≥0} :
    NNReal.toReal '' Set.Iio b = Set.Ico 0 b.toReal := by
  sorry

lemma NNReal.toReal_Ioi_eq_Ioi {b : ℝ≥0} :
    NNReal.toReal '' Set.Ioi b = Set.Ioi b.toReal := by
  sorry

lemma NNReal.toReal_Ioo_eq_Ioo {a b : ℝ≥0} :
    NNReal.toReal '' Set.Ioo a b = Set.Ioo a.toReal b.toReal := by
  sorry

theorem NNReal.Ici_eq {a : ℝ≥0} :
  Ici (↑a) = (Real.toNNReal ⁻¹' Ici a ∩ Ici 0) := by
  sorry

lemma NNReal.volume_Iio {b : ℝ≥0} : volume (Set.Iio b) = b := by
  sorry

lemma NNReal.volume_Ioi {b : ℝ≥0} : volume (Set.Ioi b) = ⊤ := by
  sorry

lemma NNReal.volume_Ioo {a b : ℝ≥0} : volume (Set.Ioo a b) = b - a:= by
  sorry

-- TODO: the proofs in the following lemmas feel quite repetitive
-- extract helper lemma to re-use some of the argument!

-- TODO: move somewhere else and add more lemmas for Ioo, Ico etc. ?
lemma ENNReal.toReal_Iio_eq_Ico {a : ℝ≥0∞} (ha : a ≠ ∞) :
    ENNReal.toReal '' Set.Iio a = Set.Ico 0 a.toReal := by
  sorry

lemma ENNReal.toReal_Iio_top_eq_Ici :
    ENNReal.toReal '' Set.Iio ⊤ = Set.Ici 0 := by
  sorry

-- TODO: move somewhere else and add more lemmas for Ioo, Ico etc. ?
lemma ENNReal.toReal_Icc_eq_Icc {a b : ℝ≥0∞} (ha : a ≠ ∞) (hb : b ≠ ∞) :
    ENNReal.toReal '' Set.Icc a b = Set.Icc a.toReal b.toReal := by
  sorry

-- TODO: move somewhere else and add more lemmas for Ioo, Ico etc. ?
lemma ENNReal.toReal_Ioo_eq_Ioo {a b : ℝ≥0∞} (ha : a ≠ ∞) (hb : b ≠ ∞) :
    ENNReal.toReal '' Set.Ioo a b = Set.Ioo a.toReal b.toReal := by
  sorry

-- TODO: move somewhere else and add more lemmas for Ioo, Ico etc. ?
lemma ENNReal.toReal_Ioo_top_eq_Ioi {a : ℝ≥0∞} (ha : a ≠ ∞) :
    ENNReal.toReal '' Set.Ioo a ⊤ = Set.Ioi a.toReal := by
  sorry

-- TODO: move somewhere else and add more lemmas for Ioo, Ico etc. ?
lemma ENNReal.toReal_Ioi_eq_Ioi {a : ℝ≥0∞} (ha : a ≠ ∞) :
    ENNReal.toReal '' Set.Ioi a = Set.Ioi a.toReal ∪ {0} := by
  sorry

lemma ENNReal.ofReal_Ioo_eq {a b : ℝ≥0∞} : ENNReal.ofReal ⁻¹' Set.Ioo a b
    = if a = ⊤ then ∅ else if a ≤ b ∧ b = ∞ then Set.Ioi a.toReal else Set.Ioo a.toReal b.toReal := by
  sorry

lemma ENNReal.ofReal_Iio_eq {b : ℝ≥0∞} : ENNReal.ofReal ⁻¹' Set.Iio b
    = if b = 0 then ∅ else if b = ∞ then Set.univ else Set.Iio b.toReal := by
  sorry

lemma ENNReal.toNNReal_Iio {b : ℝ≥0∞} : ENNReal.toNNReal '' Set.Iio b
    = if b = ∞ then Set.univ else Set.Iio b.toNNReal := by
  sorry

lemma ENNReal.volume_Ioi {a : ℝ≥0∞} (ha : a ≠ ∞) :
    volume (Set.Ioi a) = ⊤ := by
  sorry

-- TODO: move somewhere else?
theorem ENNReal.Ioi_eq_Ioc_top {a : ℝ≥0∞} : Ioi a = Ioc a ⊤ := by
  sorry

lemma ENNReal.volume_Iio {a : ℝ≥0∞} :
    volume (Set.Iio a) = a := by
  sorry

@[simp]
lemma ENNReal.range_toReal : range ENNReal.toReal = Ici 0 := by
  sorry

@[simp]
lemma ENNReal.volume_univ : volume (univ : Set ℝ≥0∞) = ⊤ := by
  sorry

@[simp]
lemma ENNReal.volume_Iic {a : ℝ≥0∞} :
    volume (Set.Iic a) = a := by
  sorry

lemma ENNReal.volume_Ioo {a b : ℝ≥0∞} :
    volume (Set.Ioo a b) = b - a := by
  sorry

instance : Measure.IsOpenPosMeasure (@volume ℝ≥0∞ _) where
  open_pos := by
    intro U open_U nonempty_U
    rcases open_U.exists_Ioo_subset nonempty_U with ⟨a, b, a_lt_b, Ioo_subset⟩
    rw [← ENNReal.bot_eq_zero, ← bot_lt_iff_ne_bot]
    apply lt_of_lt_of_le _ (measure_mono Ioo_subset)
    rw [ENNReal.volume_Ioo]
    simpa

instance : Measure.IsOpenPosMeasure (@volume ℝ≥0 _) where
  open_pos := by
    intro U open_U nonempty_U
    rcases open_U.exists_Ioo_subset nonempty_U with ⟨a, b, a_lt_b, Ioo_subset⟩
    rw [← ENNReal.bot_eq_zero, ← bot_lt_iff_ne_bot]
    apply lt_of_lt_of_le _ (measure_mono Ioo_subset)
    rw [NNReal.volume_Ioo]
    simpa

--TODO: prove analog of lemmas below for ℝ≥0

lemma ENNReal.volume_map_add_left_le_self {g : ℝ≥0∞} (hg : g ≠ ⊤) {s : Set ℝ≥0∞} (hs : MeasurableSet s) :
    Measure.map (g + ·) volume s ≤ volume s := by
  sorry

lemma ENNReal.volume_map_add_right_le_self {g : ℝ≥0∞} (hg : g ≠ ⊤) {s : Set ℝ≥0∞} (hs : MeasurableSet s) :
    Measure.map (· + g) volume s ≤ volume s := by
  sorry

lemma ENNReal.volume_Ico {a b : ℝ≥0∞} :
    volume (Set.Ico a b) = b - a := by
  sorry

-- sanity check: this measure is what you expect
example : volume (Set.Icc (3 : ℝ≥0∞) 42) = 39 := by
  sorry

lemma lintegral_nnreal_eq_lintegral_Ici_ofReal {f : ℝ≥0 → ℝ≥0∞} : ∫⁻ x : ℝ≥0, f x = ∫⁻ x in Ici (0 : ℝ), f x.toNNReal := by
  sorry

lemma lintegral_nnreal_Ici_eq_lintegral_Ici_ofReal {f : ℝ≥0 → ℝ≥0∞} {a : ℝ≥0} :
    ∫⁻ x in Ici a, f x = ∫⁻ x in Ici (a : ℝ), f x.toNNReal := by
  sorry

lemma lintegral_nnreal_eq_lintegral_Ioi_ofReal {f : ℝ≥0∞ → ℝ≥0∞} : ∫⁻ x : ℝ≥0, f x = ∫⁻ x in Ioi (0 : ℝ), f (.ofReal x) := by
  sorry

lemma lintegral_ennreal_eq_lintegral_of_nnreal {f : ℝ≥0∞ → ℝ≥0∞} :
    ∫⁻ x : ℝ≥0∞, f x = ∫⁻ x : ℝ≥0, f x := by
  sorry

lemma setLIntegral_ennreal_eq_setLintegral_of_nnreal {f : ℝ≥0∞ → ℝ≥0∞} {s : Set ℝ≥0∞} (hs : MeasurableSet s) :
    ∫⁻ x in s, f x = ∫⁻ x in (ofNNReal⁻¹' s), f x := by
  sorry

lemma lintegral_ennreal_eq_lintegral_Ioi_ofReal {f : ℝ≥0∞ → ℝ≥0∞} :
    ∫⁻ x : ℝ≥0∞, f x = ∫⁻ x in Ioi (0 : ℝ), f (.ofReal x) := by
  sorry

-- TODO: are there better names?
lemma lintegral_nnreal_eq_lintegral_toNNReal_Ioi (f : ℝ≥0 → ℝ≥0∞) :
    ∫⁻ x : ℝ≥0, f x = ∫⁻ x in Ioi (0 : ℝ), f x.toNNReal := by
  sorry

-- TODO: do we actually use this?
lemma lintegral_nnreal_toReal_eq_lintegral_Ioi (f : ℝ → ℝ≥0∞) :
    ∫⁻ x : ℝ≥0, f (x.toReal) = ∫⁻ x in Ioi (0 : ℝ), f x := by
  sorry

lemma lintegral_nnreal_toReal_eq_lintegral_Ici (f : ℝ → ℝ≥0∞) :
    ∫⁻ x : ℝ≥0, f (x.toReal) = ∫⁻ x in Ici (0 : ℝ), f x := by
  sorry

lemma setLIntegral_nnreal_Ici {f : ℝ≥0 → ℝ≥0∞} {a : ℝ≥0} :
    ∫⁻ (t : ℝ≥0) in Set.Ici a, f t = ∫⁻ (t : ℝ≥0), f (t + a) := by
  sorry

lemma lintegral_nnreal_scale_constant' {f : ℝ≥0 → ℝ≥0∞} {a : ℝ≥0} (h : a ≠ 0) :
    a * ∫⁻ x : ℝ≥0, f (a*x) = ∫⁻ x, f x := by
  sorry

-- TODO: lemmas about interaction with the Bochner integral
