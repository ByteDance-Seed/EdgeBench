module

public import Carleson.ToMathlib.RealInterpolation.InterpolatedExponents
public import Carleson.ToMathlib.WeakType
public import Mathlib.Analysis.SpecialFunctions.ImproperIntegrals
public import Carleson.ToMathlib.MeasureTheory.Measure.NNReal

/-!
This file contains some miscellaneous prerequisites for proving the Marcinkiewisz real interpolation
theorem. There are the following sections:
- Interface for using cutoff functions
- Results about the particular choice of scale
- Some tools for measure theory computations
- Results about truncations of a function
- Measurability properties of truncations
- Truncations and Lp spaces

Upstreaming status:
- measure theory computations are basically ready
- truncations and their properties definitely belong into mathlib
- the details about cutoff functions and a particular scale function
  will depend on the particular proof chosen: design on the overall proof approach first
- except for using `distribution_lt_top`, this file does not use WeakType;
  it does use helper lemmas in `InterpolatedExponents`, though.
-/

@[expose] public section

noncomputable section

open ENNReal Real Set MeasureTheory

variable {p₀ q₀ p₁ q₁ p q t : ℝ≥0∞}

/-! ## Interface for using cutoff functions -/
section

open Real Set

/-- A ScaledPowerFunction is meant to represent a function of the form `t ↦ (t / d)^σ`,
    where `d` is strictly positive and either `σ > 0` or `σ < 0`. -/
structure ScaledPowerFunction where
  σ : ℝ
  d : ℝ≥0∞
  hd : 0 < d
  hd' : d ≠ ⊤
  hσ : (0 < σ) ∨ (σ < 0)

/-- A `ToneCouple` is a couple of two monotone functions that are practically inverses of each
    other. It is used in the proof of the real interpolation theorem.

    Note: originally it seemed useful to make the possible choice of this function general
    in the proof of the real inteprolation theorem. However, in the end really only one
    function works for all the different cases. This infrastructure, however, could potentially
    still be useful, if one would like to try to improve the constant. -/
structure ToneCouple where
  ton : ℝ≥0∞ → ℝ≥0∞
  inv : ℝ≥0∞ → ℝ≥0∞
  mon : Bool
  ton_is_ton : if mon then StrictMono ton else StrictAnti ton
  --ran_ton : ∀ t ∈ Ioi (0 : ℝ≥0∞), ton t ∈ Ioi 0
  --ran_inv : ∀ t ∈ Ioi (0 : ℝ≥0∞), inv t ∈ Ioi 0
  inv_pf : if mon
      then ∀ s t, (ton s < t ↔ s < inv t) ∧ (t < ton s ↔ inv t < s)
      else ∀ s t, (ton s < t ↔ inv t < s) ∧ (t < ton s ↔ s < inv t)

/-- A StrictRangeToneCouple is a `ToneCouple` for which the functions in the couple, when
    restricted to `Ioo 0 ∞`, map to `Ioo 0 ∞`. -/
structure StrictRangeToneCouple extends ToneCouple where
  ran_ton : ∀ t ∈ Ioo 0 ∞, ton t ∈ Ioo 0 ∞
  ran_inv : ∀ t ∈ Ioo 0 ∞, inv t ∈ Ioo 0 ∞

open scoped NNReal

/-- A scaled power function gives rise to a ToneCouple. -/
def spf_to_tc (spf : ScaledPowerFunction) : StrictRangeToneCouple where
  ton s := (s / spf.d) ^ spf.σ
  inv t := spf.d * t ^ spf.σ⁻¹
  mon := if 0 < spf.σ then true else false
  ran_ton := fun t ht ↦
      ⟨rpow_pos (ENNReal.div_pos ht.1.ne' spf.hd') ((div_lt_top ht.2.ne) spf.hd.ne').ne,
      rpow_lt_top_of_pos_ne_top_ne_zero (ENNReal.div_pos ht.1.ne' spf.hd').ne'
      ((div_lt_top ht.2.ne) spf.hd.ne').ne (by rcases spf.hσ <;> order)⟩
  ran_inv := fun t ht ↦
    ⟨ENNReal.mul_pos spf.hd.ne' (rpow_pos_of_pos_ne_top_ne_zero ht.1.ne' ht.2.ne
    (inv_ne_zero (by rcases spf.hσ <;> order))).ne',
    ENNReal.mul_lt_top spf.hd'.lt_top (rpow_lt_top_of_pos_ne_top_ne_zero ht.1.ne' ht.2.ne
    (inv_ne_zero (by rcases spf.hσ <;> order)))⟩
  ton_is_ton := by
    have := spf.hd
    have := spf.hd'
    split <;> rename_i sgn_σ
    · simp only [↓reduceIte]
      intro s t hst
      beta_reduce
      gcongr
    · simp only [Bool.false_eq_true, ↓reduceIte]
      intro s t hst
      rcases spf.hσ with σ_pos | σ_neg
      · exact (sgn_σ σ_pos).elim
      · by_cases ht' : t = ⊤
        · beta_reduce; rw [ht', top_div]
          simp only [spf.hd', ↓reduceIte, top_rpow_of_neg σ_neg]
          by_cases hs' : s = ⊤
          · simp_all [spf.hd']
          by_cases hs'' : s = 0
          · rewrite [hs'', ENNReal.zero_div, zero_rpow_of_neg σ_neg]; simp
          · have hs'' : 0 < s := pos_of_ne_zero hs''
            exact rpow_pos (ENNReal.div_pos hs''.ne' spf.hd') (div_ne_top hs' spf.hd.ne')
        by_cases hs : s = 0
        · beta_reduce
          rw [hs, ENNReal.zero_div, zero_rpow_of_neg σ_neg, ← neg_neg spf.σ, ENNReal.rpow_neg]
          have : 0 ≠ t := by order
          exact inv_lt_top.mpr <| rpow_pos (ENNReal.div_pos (by order) spf.hd') (by finiteness)
        · have hs' : 0 < s := pos_of_ne_zero hs
          apply rpow_lt_rpow_iff_neg ?_ ?_ ((ENNReal.div_lt_div spf.hd spf.hd').mpr hst) σ_neg
          · exact ENNReal.div_ne_zero.mpr ⟨hs'.ne', spf.hd'⟩
          · exact div_ne_top ht' spf.hd.ne'
  inv_pf := by
    split <;> rename_i sgn_σ
    · simp only [↓reduceIte]
      have : 0 < spf.σ⁻¹ := by simpa
      refine fun s t => ⟨?_, ?_⟩
      · rw [← ENNReal.rpow_lt_rpow_iff this, ENNReal.rpow_rpow_inv sgn_σ.ne',
            ENNReal.div_lt_iff (.inl spf.hd.ne') (.inl spf.hd'), mul_comm]
      · rw [← ENNReal.rpow_lt_rpow_iff this, ENNReal.rpow_rpow_inv sgn_σ.ne',
          ENNReal.lt_div_iff_mul_lt (.inl spf.hd.ne') (.inl spf.hd'), mul_comm]
    · intro s t
      rcases spf.hσ with σ_pos | σ_neg
      · contradiction
      · have : 0 < (-spf.σ)⁻¹ := by simpa
        constructor
        all_goals rw [← ENNReal.inv_lt_inv, ← ENNReal.rpow_neg, ← ENNReal.rpow_lt_rpow_iff this,
          ENNReal.rpow_rpow_inv (by simpa using σ_neg.ne)]
        on_goal 1 => rw [ENNReal.lt_div_iff_mul_lt (.inl spf.hd.ne') (.inl spf.hd')]
        on_goal 2 => rw [ENNReal.div_lt_iff (.inl spf.hd.ne') (.inl spf.hd')]
        all_goals rw [mul_comm, ENNReal.inv_rpow, inv_neg, ENNReal.rpow_neg, inv_inv]
end
noncomputable section

open NNReal ENNReal MeasureTheory Set ComputationsInterpolatedExponents
    ComputationsChoiceExponent

variable {α α' ε : Type*} {m : MeasurableSpace α} {m' : MeasurableSpace α'}
  {p p' q p₀ q₀ p₁ q₁ : ℝ≥0∞}
  {C₀ C₁ : ℝ≥0} {μ : Measure α}
  {a : ℝ≥0∞} -- truncation parameter
  [TopologicalSpace ε] [ESeminormedAddCommMonoid ε] {f : α → ε} {t : ℝ≥0∞}

/-! ## Results about the particular choice of scale

    The proof of the real interpolation theorem will estimate
    `distribution (trunc f A(t)) t` and `distribution (truncCompl f A(t)) t` for a
    function `A`. The function `A` can be given a closed-form expression that works for
    _all_ cases in the real interpolation theorem, because of the computation rules available
    for elements in `ℝ≥0∞` that avoid the need for a limiting procedure, e.g. `⊤⁻¹ = 0`.

    The function `A` will be of the form `A(t) = (t / d) ^ σ` for particular choices of `d` and
    `σ`. This section contatins results about the scale `d`.
-/
namespace ChoiceScale

def d :=
    (C₀ ^ (q₁⁻¹.toReal / (q₁⁻¹.toReal - q₀⁻¹.toReal)) * (eLpNorm f p μ ^ p.toReal) ^
      (p₀⁻¹.toReal * q₁⁻¹.toReal / (q₁⁻¹.toReal - q₀⁻¹.toReal)) /
    (C₁ ^ (q₀⁻¹.toReal / (q₁⁻¹.toReal - q₀⁻¹.toReal)) * (eLpNorm f p μ ^ p.toReal) ^
      (p₁⁻¹.toReal * q₀⁻¹.toReal / (q₁⁻¹.toReal - q₀⁻¹.toReal))))

lemma d_pos_aux₀ (hF : eLpNorm f p μ ∈ Ioo 0 ⊤) :
    0 < eLpNorm f p μ ^ p.toReal := by
  sorry

lemma d_ne_top_aux₀ {b : ℝ} {F : ℝ≥0∞} (hF : F ∈ Ioo 0 ⊤) : F ^ b ≠ ⊤ := by
  sorry

lemma d_ne_zero_aux₀ {b : ℝ} (hF : eLpNorm f p μ ∈ Ioo 0 ⊤) :
    (eLpNorm f p μ ^ p.toReal) ^ b ≠ 0 := by
  sorry

lemma d_ne_zero_aux₂ {C : ℝ≥0} {b c : ℝ} (hC : 0 < C)
    (hF : eLpNorm f p μ ∈ Ioo 0 ⊤) :
    C ^ c * (eLpNorm f p μ ^ p.toReal) ^ b ≠ 0 := by
  sorry

lemma d_ne_top_aux₂ {b : ℝ} (hF : eLpNorm f p μ ∈ Ioo 0 ⊤) :
    (eLpNorm f p μ ^ p.toReal) ^ b ≠ ⊤ := by
  sorry

lemma d_ne_top_aux₃ {C : ℝ≥0} {b c : ℝ} (hC : 0 < C)
    (hF : eLpNorm f p μ ∈ Ioo 0 ⊤) :
    C ^ c * (eLpNorm f p μ ^ p.toReal) ^ b ≠ ⊤ := by
  sorry

lemma d_ne_zero_aux₃ {b₀ c₀ b₁ c₁ : ℝ} (hC₀ : 0 < C₀) (hC₁ : 0 < C₁) (hF : eLpNorm f p μ ∈ Ioo 0 ⊤) :
    (C₀ ^ c₀ * (eLpNorm f p μ ^ p.toReal) ^ b₀) /
    (C₁ ^ c₁ * (eLpNorm f p μ ^ p.toReal) ^ b₁) ≠ 0 := by
  sorry

lemma d_ne_top_aux₄ {b₀ c₀ b₁ c₁ : ℝ} (hC₀ : 0 < C₀) (hC₁ : 0 < C₁) (hF : eLpNorm f p μ ∈ Ioo 0 ⊤) :
    (C₀ ^ c₀ * (eLpNorm f p μ ^ p.toReal) ^ b₀) /
    (C₁ ^ c₁ * (eLpNorm f p μ ^ p.toReal) ^ b₁) ≠ ⊤ := by
  sorry

-- If the `p`-norm of `f` is positive and finite, then `d` is positive
lemma d_pos (hC₀ : 0 < C₀) (hC₁ : 0 < C₁) (hF : eLpNorm f p μ ∈ Ioo 0 ⊤) :
    @d α ε m p p₀ q₀ p₁ q₁ C₀ C₁ μ _ _ f > 0 := by
  sorry

@[aesop (rule_sets := [finiteness]) unsafe apply]
lemma d_ne_top (hC₀ : 0 < C₀) (hC₁ : 0 < C₁) (hF : eLpNorm f p μ ∈ Ioo 0 ⊤) :
    @d α ε m p p₀ q₀ p₁ q₁ C₀ C₁ μ _ _ f ≠ ⊤ := by
  sorry

lemma d_eq_top₀ (hp₀ : 0 < p₀) (hq₁ : 0 < q₁) (hp₀' : p₀ ≠ ⊤) (hq₀' : q₀ = ⊤) (hq₀q₁ : q₀ ≠ q₁) :
    @d α ε m p p₀ q₀ p₁ q₁ C₀ C₁ μ _ _ f =
    (↑C₀ ^ p₀.toReal * eLpNorm f p μ ^ p.toReal) ^ p₀.toReal⁻¹ := by
  sorry

lemma d_eq_top₁ (hq₀ : 0 < q₀) (hp₁ : 0 < p₁) (hp₁' : p₁ ≠ ⊤) (hq₁' : q₁ = ⊤)
    (hq₀q₁ : q₀ ≠ q₁) (hC₁ : 0 < C₁) :
    @d α ε m p p₀ q₀ p₁ q₁ C₀ C₁ μ _ _ f =
    (↑C₁ ^ p₁.toReal * eLpNorm f p μ ^ p.toReal) ^ p₁.toReal⁻¹ := by
  sorry

lemma d_eq_top_of_eq (hC₁ : 0 < C₁) (hp₀ : 0 < p₀) (hq₀ : 0 < q₀) (hq₀' : q₀ ≠ ⊤)
(hp₀' : p₀ ≠ ⊤) (hp₁ : 0 < p₁) (hp₀p₁ : p₀ = p₁) (hpp₀ : p = p₀) (hq₁' : q₁ = ⊤) :
    @d α ε m p p₀ q₀ p₁ q₁ C₀ C₁ μ _ _ f = C₁ * eLpNorm f p μ := by
  sorry

lemma d_eq_top_top (hq₀ : 0 < q₀) (hq₀q₁ : q₀ ≠ q₁) (hp₁' : p₁ = ⊤) (hq₁' : q₁ = ⊤) :
    @d α ε m p p₀ q₀ p₁ q₁ C₀ C₁ μ _ _ f = C₁ := by
  sorry

/-- The particular choice of scaled power function that works in the proof of the
real interpolation theorem. -/
def spf_ch {t : ℝ} (ht : t ∈ Ioo 0 1) (hq₀q₁ : q₀ ≠ q₁) (hp₀ : 0 < p₀) (hq₀ : 0 < q₀)
    (hp₁ : 0 < p₁) (hq₁ : 0 < q₁) (hp₀p₁ : p₀ ≠ p₁) (hC₀ : 0 < C₀) (hC₁ : 0 < C₁)
    (hF : eLpNorm f p μ ∈ Ioo 0 ⊤) :
    ScaledPowerFunction where
  σ := ζ p₀ q₀ p₁ q₁ t
  d := @d _ ε _ p p₀ q₀ p₁ q₁ C₀ C₁ μ _ _ f
  hσ := lt_or_gt_of_ne <| Ne.symm <|
    (toReal_ofReal ht.1.le) ▸ (ζ_ne_zero (ofReal_mem_Ioo_0_1 t ht) hp₀ hq₀ hp₁ hq₁ hp₀p₁ hq₀q₁)
  hd := d_pos hC₀ hC₁ hF
  hd' := d_ne_top_aux₄ hC₀ hC₁ hF

end ChoiceScale

end

noncomputable section -- TODO: move these lemmas to a better location!

open NNReal ENNReal MeasureTheory Set

variable {α α' : Type*} {m : MeasurableSpace α} {m' : MeasurableSpace α'}
  {p p' q p₀ q₀ p₁ q₁ : ℝ≥0∞} {c : ℝ≥0} {μ : Measure α}

/-! ## Some tools for measure theory computations
    A collection of small lemmas to help with integral manipulations.
-/
namespace MeasureTheory

-- TODO: change lhs and rhs?
-- TODO: rewrite the condition in filter form?
lemma lintegral_double_restrict_set {A B : Set α} {f : α → ℝ≥0∞} (hA : MeasurableSet A)
  (hB : MeasurableSet B) (hf : ∀ᵐ (x : α) ∂μ, x ∈ A \ B → f x ≤ 0) :
    ∫⁻ x in A, f x ∂μ = ∫⁻ x in A ∩ B, f x ∂μ := by
  sorry

-- local convenience function
lemma lintegral_rw_aux {g : ℝ → ℝ≥0∞} {f₁ f₂ : ℝ → ℝ≥0∞} {A : Set ℝ}
    (heq : f₁ =ᶠ[ae (volume.restrict A)] f₂) :
    ∫⁻ s in A, g s * f₁ s = ∫⁻ s in A, g s * f₂ s := by
  sorry

lemma power_aux {p q : ℝ} :
    (fun s ↦ ENNReal.ofReal s ^ (p + q)) =ᶠ[ae (volume.restrict (Ioi (0 : ℝ)))]
    (fun s ↦ ENNReal.ofReal s ^ p * ENNReal.ofReal s ^ q ) := by
  sorry

lemma power_aux_2 {p q : ℝ} :
    (fun s ↦ ENNReal.ofReal (s ^ (p + q))) =ᶠ[ae (volume.restrict (Ioi (0 : ℝ)))]
    (fun s ↦ ENNReal.ofReal (s ^ p) * ENNReal.ofReal (s ^ q) ) := by
  sorry

lemma power_aux_3 {p q : ℝ} :
    (fun s : ℝ≥0∞ ↦ s ^ (p + q)) =ᶠ[ae volume] (fun s ↦ s ^ p * s ^ q ) := by
  sorry

lemma power_aux_4 {p : ℝ} :
    (fun s ↦ ENNReal.ofReal (s ^ p)) =ᶠ[ae (volume.restrict (Ioi (0 : ℝ)))]
    (fun s ↦ ENNReal.ofReal s ^ p) := by
  sorry

lemma ofReal_rpow_of_pos_aux {p : ℝ} :
    (fun s ↦ ENNReal.ofReal s ^ p) =ᶠ[ae (volume.restrict (Ioi (0 : ℝ)))]
    (fun s ↦ ENNReal.ofReal (s ^ p)) := by
  sorry

lemma extract_constant_double_integral_rpow {f : ℝ → ℝ → ℝ≥0∞} {q : ℝ} (hq : q ≥ 0) {a : ℝ≥0∞}
    (ha : a ≠ ⊤) :
    ∫⁻ (s : ℝ) in Ioi 0, (∫⁻ (t : ℝ) in Ioi 0, a * f s t) ^ q =
    a ^ q * ∫⁻ (s : ℝ) in Ioi 0, (∫⁻ (t : ℝ) in Ioi 0, f s t) ^ q := by
  sorry

lemma ofReal_rpow_rpow_aux {p : ℝ} :
    (fun s ↦ ENNReal.ofReal s ^ p) =ᶠ[ae (volume.restrict (Ioi (0 : ℝ)))]
    (fun s ↦ ENNReal.ofReal (s ^ p)) := by
  sorry

lemma lintegral_rpow_of_gt {β γ : ℝ} (hβ : 0 ≤ β) (hγ : -1 < γ) :
    ∫⁻ s : ℝ in Ioo 0 β, ENNReal.ofReal (s ^ γ) =
    ENNReal.ofReal (β ^ (γ + 1) / (γ + 1)) := by
  sorry

end MeasureTheory

end

noncomputable section

open NNReal ENNReal MeasureTheory Set ComputationsInterpolatedExponents

variable {α α' ε : Type*} {m : MeasurableSpace α} {m' : MeasurableSpace α'}
  {p p' q p₀ q₀ p₁ q₁ : ℝ≥0∞} {c : ℝ≥0} {a : ℝ}
  {μ : Measure α} {ν : Measure α'}
  [TopologicalSpace ε] [ESeminormedAddMonoid ε]
  {ε' : Type*} [TopologicalSpace ε'] [ENormedAddMonoid ε']
  {f : α → ε} {s t t' : ℝ≥0∞}

/-! ## Results about truncations of a function
-/
namespace MeasureTheory

/-- The `t`-truncation of a function `f`. -/
def trunc (f : α → ε) (t : ℝ≥0∞) (x : α) : ε := if ‖f x‖ₑ ≤ t then f x else 0

lemma trunc_eq_indicator : trunc f t = {x | ‖f x‖ₑ ≤ t}.indicator f := by
  sorry

@[simp]
lemma trunc_top : trunc f ∞ = f := by
  sorry

/-- The complement of a `t`-truncation of a function `f`. -/
def truncCompl (f : α → ε) (t : ℝ≥0∞) (x : α) : ε := if ‖f x‖ₑ ≤ t then 0 else f x

lemma truncCompl_eq_indicator : truncCompl f t = {x | ‖f x‖ₑ ≤ t}ᶜ.indicator f := by
  sorry

@[simp]
lemma truncCompl_top : truncCompl f ∞ = (fun _ ↦ 0) := by
  sorry

lemma truncCompl_eq {f : α → ε} :
    truncCompl f t = fun x ↦ if t < ‖f x‖ₑ then f x else 0 := by
  sorry

/-- A function to deal with truncations and complement of truncations in one go. -/
def trnc (j : Bool) (f : α → ε) (t : ℝ≥0∞) : α → ε :=
  match j with
  | false => truncCompl f t
  | true => trunc f t

@[simp]
lemma trnc_false : trnc false f t = truncCompl f t := by
  sorry

@[simp]
lemma trnc_true : trnc true f t = trunc f t := by
  sorry

/-- A function is the complement if its truncation and the complement of the truncation. -/
@[simp]
lemma trunc_add_truncCompl {t : ℝ≥0∞} : trunc f t + truncCompl f t = f := by
  sorry

alias trnc_true_add_trnc_false := trunc_add_truncCompl

/-- If the truncation parameter is non-positive, the truncation vanishes. -/
lemma trunc_of_nonpos {f : α → ε'} (ht : t ≤ 0) : trunc f t = 0 := by
  sorry

/-- If the truncation parameter is non-positive, the complement of the truncation is the
function itself. -/
lemma truncCompl_of_nonpos {f : α → ε'} (ht : t ≤ 0) : truncCompl f t = f := by
  sorry

/-! ## Measurability properties of truncations -/

-- @[measurability, fun_prop]
-- lemma _root_.Measurable.trunc [MeasurableSpace E₁] [NormedAddCommGroup E₁] [BorelSpace E₁]
--     (hf : Measurable f) : Measurable (trunc f t) := by
--   refine hf.ite (measurableSet_le ?_ ?_) measurable_const <;> fun_prop

-- @[measurability, fun_prop]
-- lemma _root_.Measurable.truncCompl [MeasurableSpace E₁] [NormedAddCommGroup E₁] [BorelSpace E₁]
--     (hf : Measurable f) :
--     Measurable (truncCompl f t) := by
--   rw [truncCompl_eq]
--   apply Measurable.ite ?_ hf measurable_const
--   exact measurableSet_lt measurable_const hf.norm

@[measurability]
protected lemma StronglyMeasurable.trunc (hf : StronglyMeasurable f) :
    StronglyMeasurable (trunc f t) := by
  sorry

@[measurability]
protected lemma StronglyMeasurable.truncCompl (hf : StronglyMeasurable f) :
    StronglyMeasurable (truncCompl f t) := by
  sorry

-- @[measurability, fun_prop]
-- lemma AEMeasurable.trunc [MeasurableSpace E₁] [NormedAddCommGroup E₁] [BorelSpace E₁]
--     (hf : AEMeasurable f μ) : AEMeasurable (trunc f t) μ := by
--   rcases hf with ⟨g, ⟨wg1, wg2⟩⟩
--   exists (trunc g t)
--   constructor
--   · apply wg1.indicator (s := {x | ‖g x‖ ≤ t}) (measurableSet_le wg1.norm measurable_const)
--   apply measure_mono_null ?_ wg2
--   intro x
--   contrapose
--   simp only [mem_compl_iff, mem_setOf_eq, not_not]
--   intro h₂
--   unfold trunc
--   rewrite [h₂]
--   rfl

-- @[measurability, fun_prop]
-- lemma AEMeasurable.truncCompl [MeasurableSpace E₁] [NormedAddCommGroup E₁] [BorelSpace E₁]
--     (hf : AEMeasurable f μ) : AEMeasurable (truncCompl f t) μ := by
--   rcases hf with ⟨g, ⟨wg1, wg2⟩⟩
--   exists (truncCompl g t)
--   constructor
--   · unfold truncCompl
--     rw [truncCompl_eq]
--     exact wg1.indicator (s := {x | t < ‖g x‖}) (measurableSet_lt measurable_const wg1.norm)
--   · apply measure_mono_null ?_ wg2
--     intro x
--     contrapose
--     simp only [mem_compl_iff, mem_setOf_eq, not_not]
--     intro f_eq_g; unfold truncCompl; unfold trunc; dsimp only [Pi.sub_apply]; rw [f_eq_g]

@[measurability]
nonrec lemma AEStronglyMeasurable.trunc (hf : AEStronglyMeasurable f μ) :
    AEStronglyMeasurable (trunc f t) μ := by
  sorry

@[measurability]
nonrec lemma AEStronglyMeasurable.truncCompl
    (hf : AEStronglyMeasurable f μ) : AEStronglyMeasurable (truncCompl f t) μ := by
  sorry

@[measurability]
lemma aestronglyMeasurable_trnc {j : Bool} (hf : AEStronglyMeasurable f μ) :
    AEStronglyMeasurable (trnc j f t) μ := by
  sorry

lemma trunc_le {f : α → ε} (x : α) : ‖trunc f t x‖ₑ ≤ max 0 t := by
  sorry

/-- A small lemma that is helpful for rewriting -/
lemma coe_coe_eq_ofReal (a : ℝ) : ofNNReal a.toNNReal = ENNReal.ofReal a := by
  sorry

lemma trunc_eLpNormEssSup_le {f : α → ε} (a : ℝ≥0∞) :
    eLpNormEssSup (trunc f a) μ ≤ (max 0 a) := by
  sorry

lemma trunc_mono {f : α → ε} {a b : ℝ≥0∞} (hab : a ≤ b) {x : α} : ‖trunc f a x‖ₑ ≤ ‖trunc f b x‖ₑ := by
  sorry

/-- The norm of the truncation is monotone in the truncation parameter -/
lemma eLpNorm_trunc_mono :
    Monotone fun s ↦ eLpNorm (trunc f s) p μ := by
  sorry

lemma trunc_buildup_enorm {x : α} :
    ‖trunc f t x‖ₑ + ‖truncCompl f t x‖ₑ = ‖f x‖ₑ := by
  sorry

lemma trunc_le_func {x : α} : ‖trunc f t x‖ₑ ≤ ‖f x‖ₑ := by
  sorry

lemma truncCompl_le_func {x : α} :
    ‖(truncCompl f t) x‖ₑ ≤ ‖f x‖ₑ := by
  sorry

lemma foo {A B C D : ℝ≥0∞} (hA : A ≠ ∞) (h : A ≤ C) (h' : A + B = C + D) : D ≤ B := by
  sorry

lemma truncCompl_anti {x : α} (hab : t ≤ s) (hf : ‖trunc f t x‖ₑ ≠ ⊤) :
    ‖truncCompl f s x‖ₑ ≤ ‖truncCompl f t x‖ₑ := by
  sorry

/-- The norm of the complement of the truncation is antitone in the truncation parameter -/
-- XXX: the conditions `hf` and `mf` may need to be tweaked
lemma eLpNorm_truncCompl_anti (hf : eLpNorm f 1 μ ≠ ⊤) (mf : AEStronglyMeasurable f μ) :
    Antitone (fun s ↦ eLpNorm (truncCompl f s) p μ) := by
  sorry

/-- The norm of the truncation is meaurable in the truncation parameter -/
@[measurability, fun_prop]
lemma eLpNorm_trunc_measurable :
    Measurable (fun s ↦ eLpNorm (trunc f s) p μ) := by
  sorry

/-- The norm of the complement of the truncation is measurable in the truncation parameter -/
@[measurability, fun_prop]
lemma eLpNorm_truncCompl_measurable (hf : eLpNorm f 1 μ ≠ ⊤) (mf : AEStronglyMeasurable f μ) :
    Measurable (fun s ↦ eLpNorm (truncCompl f s) p μ) := by
  sorry

lemma trnc_le_func {j : Bool} {a : ℝ≥0∞} {x : α} :
    ‖trnc j f a x‖ₑ ≤ ‖f x‖ₑ := by
  sorry

-- /-- ## Distribution functions of truncations -/

-- /-- The `t`-truncation of `f : α →ₘ[μ] E`. -/
-- def AEEqFun.trunc (f : α →ₘ[μ] E) (t : ℝ≥0∞) : α →ₘ[μ] E :=
--   AEEqFun.mk (trunc f t) (.trunc f.aestronglyMeasurable)

-- /-- A set of measurable functions is closed under truncation. -/
-- class IsClosedUnderTruncation (U : Set (α →ₘ[μ] E)) : Prop where
--   trunc_mem {f : α →ₘ[μ] E} (hf : f ∈ U) (t : ℝ≥0∞) : f.trunc t ∈ U

/-! ## Truncations and L-p spaces -/

lemma MemLp.trunc {p : ℝ≥0∞} (hf : MemLp f p μ) : MemLp (trunc f t) p μ := by
  sorry

-- lemma eLpNorm_truncCompl_le {p : ℝ≥0∞} :
--     eLpNorm (truncCompl f t) p μ ≤ eLpNorm f p μ :=
--   eLpNorm_mono (fun _ ↦ truncCompl_le_func)

lemma MemLp.truncCompl {p : ℝ≥0∞} (hf : MemLp f p μ) :
    MemLp (truncCompl f t) p μ := by
  sorry

lemma eLpNorm_truncCompl_le {q : ℝ≥0∞}
    (q_ne_zero : ¬ q = 0) (q_ne_top : q ≠ ⊤) :
    eLpNorm (truncCompl f t) q μ ^ q.toReal ≤
    ∫⁻ x : α in {x | t < ‖f x‖ₑ}, ‖f x‖ₑ ^ q.toReal ∂μ := by
  sorry

-- TODO: better name!
lemma estimate_eLpNorm_truncCompl {p q : ℝ≥0∞}
    (p_ne_top : p ≠ ⊤) (hpq : q ∈ Ioc 0 p) (hf : AEStronglyMeasurable f μ) (ht : 0 < t) :
    eLpNorm (truncCompl f t) q μ ^ q.toReal ≤
    (t ^ (q.toReal - p.toReal)) * eLpNorm f p μ ^ p.toReal := by
  sorry

-- TODO: better name!
lemma estimate_eLpNorm_trunc {p q : ℝ≥0∞}
    (hq : q ≠ ⊤) (hpq : p ∈ Ioc 0 q) {f : α → ε'} (hf : AEStronglyMeasurable f μ) :
    eLpNorm (trunc f t) q μ ^ q.toReal ≤
    (t ^ (q.toReal - p.toReal)) * eLpNorm f p μ ^ p.toReal := by
  sorry

-- TODO: is there a better name?
/-- If `f` is in `Lp`, the truncation is element of `Lq` for `q ≥ p`. -/
lemma trunc_Lp_Lq_higher (hpq : p ∈ Ioc 0 q) {f : α → ε'} (hf : MemLp f p μ) (ht : t ≠ ∞) :
    MemLp (trnc ⊤ f t) q μ := by
  sorry

lemma memLp_truncCompl_of_memLp_top (hf : MemLp f ⊤ μ) (h : μ {x | t < ‖f x‖ₑ} < ⊤) :
    MemLp (trnc ⊥ f t) p μ := by
  sorry

-- is there a better name?
/-- If `f` is in `Lp`, the complement of the truncation is in `Lq` for `q ≤ p`. -/
lemma truncCompl_Lp_Lq_lower
    (hp : p ≠ ⊤) (hpq : q ∈ Ioc 0 p) (ht : 0 < t) (hf : MemLp f p μ) :
    MemLp (trnc ⊥ f t) q μ := by
  sorry

-- Lemma 6.10 in Folland
-- XXX: is the `ContinuousAdd` hypothesis really necessary for `MemLp.add` (and hence here)?
lemma memLp_of_memLp_le_of_memLp_ge {f : α → ε'} [ContinuousAdd ε']
    {r : ℝ≥0∞} (hp : 0 < p) (hr' : q ∈ Icc p r)
    (hf : MemLp f p μ) (hf' : MemLp f r μ) : MemLp f q μ := by
  sorry

end MeasureTheory

end

noncomputable section

open NNReal ENNReal MeasureTheory Set

variable {α α' ε : Type*} {m : MeasurableSpace α} {m' : MeasurableSpace α'}
  {p p' q p₀ q₀ p₁ q₁ : ℝ≥0∞}
  {C₀ C₁ : ℝ≥0} {μ : Measure α} {ν : Measure α'}
  {a : ℝ≥0∞} -- truncation parameter
  [TopologicalSpace ε] [ESeminormedAddCommMonoid ε] {f : α → ε} {t : ℝ≥0∞}

/-! ## Some results about the integrals of truncations

-/
namespace MeasureTheory

def res (j : Bool) (β : ℝ≥0∞) : Set ℝ :=
  if β = ∞ then if j then Ioi (0 : ℝ) else ∅
  else if j then Ioo (0 : ℝ) β.toReal else Ioi β.toReal

lemma measurableSet_res {j : Bool} {β : ℝ≥0∞} : MeasurableSet (res j β) := by
  sorry

lemma res_subset_Ioi {j : Bool} {β : ℝ≥0∞} : res j β ⊆ Ioi 0 := by
  sorry

instance decidableMemRes {t : ℝ} {j : Bool} {β : ℝ≥0∞} : Decidable (t ∈ res j β) := by
  exact Classical.propDecidable (t ∈ res j β)

def res' (j : Bool) (β : ℝ≥0∞) : Set ℝ :=
  if β = ∞ then if j then Ioi (0 : ℝ) else ∅
  else if j then Ioc (0 : ℝ) β.toReal else Ioi 0 ∩ Ici β.toReal

-- TODO: this one is probably obsolete
lemma res'comp₀ (j : Bool) (β : ℝ≥0∞) (hβ : 0 < β) :
    Ioi (0 : ℝ) \ res' j β = res (¬j) β := by
  sorry

lemma res'comp (j : Bool) (β : ℝ≥0∞) :
    Ioi (0 : ℝ) \ res' j β = res (¬j) β := by
  sorry

lemma measurableSet_res' {j : Bool} {β : ℝ≥0∞} : MeasurableSet (res' j β) := by
  sorry

lemma res'subset_Ioi {j : Bool} {β : ℝ≥0∞} : res' j β ⊆ Ioi 0 := by
  sorry

lemma res'subset_Ici {j : Bool} {β : ℝ≥0∞} : res' j β ⊆ Ici 0 := by
  sorry

lemma lintegral_trunc_mul₀ {g : ℝ → ℝ≥0∞} {j : Bool} {x : α} {tc : ToneCouple} {p : ℝ} (hp : 0 < p)
    :
    ∫⁻ s : ℝ in Ioi 0, (g s) * ‖trnc j f (tc.ton (ENNReal.ofReal s)) x‖ₑ ^ p =
    ∫⁻ s : ℝ in res' (xor j tc.mon) (tc.inv ‖f x‖ₑ), (g s) *
        ‖trnc j f (tc.ton (ENNReal.ofReal s)) x‖ₑ ^ p := by
  sorry

lemma lintegral_trunc_mul₁ {g : ℝ → ℝ≥0∞} {j : Bool} {x : α} {p : ℝ} {tc : ToneCouple} :
    ∫⁻ s : ℝ in res' (xor j tc.mon) (tc.inv ‖f x‖ₑ), (g s) * ‖trnc j f (tc.ton (ENNReal.ofReal s)) x‖ₑ ^ p =
    ∫⁻ s : ℝ in res (xor j tc.mon) (tc.inv ‖f x‖ₑ), (g s) * ‖trnc j f (tc.ton (ENNReal.ofReal s)) x‖ₑ ^ p := by
  sorry

lemma lintegral_trunc_mul₂ {g : ℝ → ℝ≥0∞} {j : Bool} {x : α} {p : ℝ} {tc : ToneCouple} :
    ∫⁻ s : ℝ in res (xor j tc.mon) (tc.inv ‖f x‖ₑ), (g s) * ‖trnc j f (tc.ton (ENNReal.ofReal s)) x‖ₑ ^ p =
    ∫⁻ s : ℝ in res (xor j tc.mon) (tc.inv ‖f x‖ₑ), (g s) * ‖f x‖ₑ ^ p := by
  sorry

lemma lintegral_trunc_mul {g : ℝ → ℝ≥0∞} (hg : AEMeasurable g) {j : Bool} {x : α} {tc : ToneCouple} {p : ℝ}
    (hp : 0 < p) :
    ∫⁻ s : ℝ in Ioi 0, (g s) * ‖trnc j f (tc.ton (ENNReal.ofReal s)) x‖ₑ ^ p =
    (∫⁻ s : ℝ in res (xor j tc.mon) (tc.inv ‖f x‖ₑ), (g s)) * ‖f x‖ₑ ^ p := by
  sorry

/-! Extract expressions for the lower Lebesgue integral of power functions
TODO: move to a lower-level file! -/

lemma lintegral_rpow_of_gt_abs {β γ : ℝ} (hβ : 0 ≤ β) (hγ : γ > -1) :
    ∫⁻ s : ℝ in Ioo 0 β, ENNReal.ofReal (s ^ γ) =
    ENNReal.ofReal (β ^ (γ + 1) / |γ + 1|) := by
  sorry

-- TODO: treat symmetrically to Ioo case?
lemma lintegral_Ioi_rpow_of_lt_abs {β σ : ℝ} (hβ : 0 < β) (hσ : σ < -1) :
    ∫⁻ s : ℝ in Ioi β, ENNReal.ofReal (s ^ σ) =
    ENNReal.ofReal (β ^ (σ + 1) / |σ + 1|) := by
  sorry

lemma lintegral_rpow_Ioi_top {γ : ℝ} :
    ∫⁻ s : ℝ in Ioi 0, .ofReal (s ^ γ) = ∞ := by
  sorry

lemma value_lintegral_res₀ {j : Bool} {β : ℝ≥0∞} {γ : ℝ} (hγ : if j then γ > -1 else γ < -1) :
  ∫⁻ s : ℝ in res j β, ENNReal.ofReal (s ^ γ) = β ^ (γ + 1) / ENNReal.ofReal |γ + 1| := by
  sorry

lemma value_lintegral_res₁ {γ p' : ℝ} {spf : ScaledPowerFunction} (ht : 0 < t) (ht' : t ≠ ∞) :
    (((spf_to_tc spf).inv t) ^ (γ + 1) / ENNReal.ofReal |γ + 1| ) * (t ^ p') =
    (spf.d ^ (γ + 1) * t ^ (spf.σ⁻¹ * (γ + 1) + p') / ENNReal.ofReal |γ + 1|) := by
  sorry

lemma value_lintegral_res₂ {γ p' : ℝ} {spf : ScaledPowerFunction} (ht : 0 < t)
    (hσp' : 0 < spf.σ⁻¹ * (γ + 1) + p') :
    (((spf_to_tc spf).inv t) ^ (γ + 1) / ENNReal.ofReal |γ + 1| ) * (t ^ p') ≤
    (spf.d ^ (γ + 1) * t ^ (spf.σ⁻¹ * (γ + 1) + p') / ENNReal.ofReal |γ + 1|) := by
  sorry

-- TODO: move to a lower-level file!
lemma AEStronglyMeasurable.induction {α : Type*} {β : Type*} {mα : MeasurableSpace α} [TopologicalSpace β]
  {μ : Measure α} {motive : (α → β) → Prop}
  (ae_eq_implies : ∀ ⦃f g : α → β⦄ (_ : StronglyMeasurable f) (_ : f =ᶠ[ae μ] g), motive f → motive g)
  (measurable : ∀ ⦃f : α → β⦄ (_ : StronglyMeasurable f), motive f)
    ⦃f : α → β⦄ (hf : AEStronglyMeasurable f μ) : motive f := by
  sorry

end MeasureTheory

end
