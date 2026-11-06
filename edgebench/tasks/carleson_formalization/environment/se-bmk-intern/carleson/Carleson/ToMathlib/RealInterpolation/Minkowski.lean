module

public import Carleson.ToMathlib.MeasureTheory.Measure.NNReal
public import Carleson.ToMathlib.RealInterpolation.Misc

/-!
# Minkowski's integral inequality

In this file, we prove Minkowski's integral inequality and apply it to truncations.
We use this to deduce weak type estimates for truncations.

Upstreaming status:
- Minkowski's integral inequality belongs into mathlib, and is mostly ready
- applying it to truncations needs truncations upstreamed first
- weak type estimates are also desirable

Lemma names often need to be improved a bit; perhaps the code can also be golfed.

-/

@[expose] public section

noncomputable section

open NNReal ENNReal MeasureTheory Set ComputationsInterpolatedExponents
    ComputationsChoiceExponent

variable {α α' ε E₁ E₂ E₃ : Type*} {m : MeasurableSpace α} {m' : MeasurableSpace α'}
  {ε ε₁ ε₂ : Type*} [TopologicalSpace ε] [TopologicalSpace ε₁] [TopologicalSpace ε₂]
  {p p' q p₀ q₀ p₁ q₁ : ℝ≥0∞}
  {C₀ C₁ : ℝ≥0} {μ : Measure α} {ν : Measure α'}
  {f : α → E₁} {t : ℝ≥0∞}

/-! ## Minkowski's integral inequality -/

namespace MeasureTheory

def truncCut (f : α → ℝ≥0∞) (μ : Measure α) [SigmaFinite μ] :=
  fun n : ℕ ↦ indicator (spanningSets μ n) (fun x ↦ min (f x) n)

@[gcongr]
lemma truncCut_mono {μ : Measure α} [SigmaFinite μ] {f : α → ℝ≥0∞} (x : α) :
    Monotone (fun n ↦ truncCut f μ n x) := by
  sorry

lemma truncCut_mono₀ {μ : Measure α} [SigmaFinite μ] {f : α → ℝ≥0∞} :
    Monotone (truncCut f μ) := by
  sorry

lemma truncCut_sup {μ : Measure α} [SigmaFinite μ] {f : α → ℝ≥0∞} (x : α) :
    ⨆ n : ℕ, truncCut f μ n x = f x := by
  sorry

set_option linter.flexible false in
/-- Characterization of `∫⁻ x : α, f x ^ p ∂μ` by a duality argument. -/
lemma representationLp {μ : Measure α} [SigmaFinite μ] {f : α → ℝ≥0∞}
    (hf : AEMeasurable f μ) {p q : ℝ} (hp : p > 1) (hq : q ≥ 1)
    (hpq : p⁻¹ + q⁻¹ = 1) :
    (∫⁻ x : α, (f x) ^ p ∂μ) ^ (1 / p) =
    ⨆ g ∈ {g' : α → ℝ≥0∞ | AEMeasurable g' μ ∧ ∫⁻ x : α, (g' x) ^ q ∂μ ≤ 1},
    ∫⁻ x : α, (f x) * g x ∂μ := by
  sorry

-- TODO: better name!
lemma aemeasurability_prod₁ {α : Type u_1} {β : Type u_3}
    [MeasurableSpace α] [MeasurableSpace β]
    {μ : Measure α} {ν : Measure β} [SFinite ν]
    ⦃f : α × β → ENNReal⦄
    (hf : AEMeasurable f (μ.prod ν)) :
    ∀ᵐ x : α ∂μ, AEMeasurable (f ∘ (Prod.mk x)) ν := by
  sorry

-- TODO: better name!
lemma aemeasurability_prod₂ {α : Type u_1} {β : Type u_3}
    [MeasurableSpace α] [MeasurableSpace β]
    {μ : Measure α} {ν : Measure β} [SFinite ν]
    [SFinite μ] ⦃f : α × β → ENNReal⦄
    (hf : AEMeasurable f (μ.prod ν)) :
    ∀ᵐ y : β ∂ν, AEMeasurable (f ∘ (fun x ↦ Prod.mk x y)) μ := by
  sorry -- perf: convert is faster than exact

-- TODO: better name!
@[fun_prop]
lemma aemeasurable_integral_component {α : Type u_1} {β : Type u_3}
    [MeasurableSpace α] [MeasurableSpace β]
    {μ : Measure α} {ν : Measure β} [SFinite ν]
    ⦃f : α × β → ENNReal⦄
    (hf : AEMeasurable f (μ.prod ν)) :
    AEMeasurable (fun x ↦ ∫⁻ (y : β), f (x, y) ∂ν) μ := by
  sorry

/-- **Minkowsi's integral inequality**: TODO describe what it does -/
-- TODO: the condition on `μ` can probably be weakened to `SFinite μ`, by using a limit
-- argument
lemma lintegral_lintegral_pow_swap {α : Type u_1} {β : Type u_3} {p : ℝ} (hp : 1 ≤ p)
    [MeasurableSpace α] [MeasurableSpace β]
    {μ : Measure α} {ν : Measure β} [SFinite ν]
    [SigmaFinite μ] ⦃f : α → β → ENNReal⦄
    (hf : AEMeasurable (Function.uncurry f) (μ.prod ν)) :
    (∫⁻ (x : α), (∫⁻ (y : β), f x y ∂ν) ^ p ∂μ) ^ p⁻¹ ≤
    ∫⁻ (y : β), (∫⁻ (x : α), (f x y) ^ p ∂μ) ^ p⁻¹ ∂ν := by
  sorry

lemma lintegral_lintegral_pow_swap_rpow {α : Type u_1} {β : Type u_3} {p : ℝ} (hp : p ≥ 1)
    [MeasurableSpace α] [MeasurableSpace β]
    {μ : Measure α} {ν : Measure β} [SFinite ν]
    [SigmaFinite μ] ⦃f : α → β → ENNReal⦄
    (hf : AEMeasurable (Function.uncurry f) (μ.prod ν)) :
    (∫⁻ (x : α), (∫⁻ (y : β), f x y ∂ν) ^ p ∂μ) ≤
    (∫⁻ (y : β), (∫⁻ (x : α), (f x y) ^ p ∂μ) ^ p⁻¹ ∂ν) ^ p := by
  sorry

/-! ## Apply Minkowski's integral inequality to truncations
-/

@[measurability, fun_prop]
theorem aemeasurable_ton (tc : ToneCouple) : AEMeasurable tc.ton (volume.restrict (Ioi 0)) := by
  sorry

-- TODO: better name!
@[measurability]
lemma indicator_ton_measurable {g : α → E₁} [MeasurableSpace E₁]
    [TopologicalSpace E₁] [ESeminormedAddCommMonoid E₁] [BorelSpace E₁]
    (hg : AEMeasurable g μ) (tc : ToneCouple) :
    NullMeasurableSet {(s, x) : ℝ≥0∞ × α | ‖g x‖ₑ ≤ tc.ton s } ((volume.restrict (Ioi 0)).prod μ) := by
  sorry

-- TODO: better name!
@[measurability]
lemma indicator_ton_measurable_lt {g : α → E₁} [MeasurableSpace E₁]
    [TopologicalSpace E₁] [ESeminormedAddCommMonoid E₁]
    [BorelSpace E₁] (hg : AEMeasurable g μ) (tc : ToneCouple) :
    NullMeasurableSet {(s, x) : ℝ≥0∞ × α | tc.ton s < ‖g x‖ₑ }
      ((volume.restrict (Ioi 0)).prod μ) := by
  sorry

@[measurability, fun_prop]
lemma AEMeasurable.trunc_ton {f : α → E₁}
    [MeasurableSpace E₁] [TopologicalSpace E₁] [ESeminormedAddCommMonoid E₁] [BorelSpace E₁]
    (hf : AEMeasurable f μ) (tc : ToneCouple) :
    AEMeasurable (fun a : ℝ≥0∞ × α ↦ (trunc f (tc.ton a.1)) a.2)
      ((volume.restrict (Ioi 0)).prod (μ.restrict f.support)) := by
  sorry

@[measurability, fun_prop]
lemma AEMeasurable.truncCompl_ton {f : α → E₁}
    [MeasurableSpace E₁] [TopologicalSpace E₁] [ESeminormedAddCommMonoid E₁] [BorelSpace E₁]
    (hf : AEMeasurable f μ) (tc : ToneCouple) :
    AEMeasurable (fun a : ℝ≥0∞ × α ↦ ((truncCompl f (tc.ton a.1))) a.2)
    ((volume.restrict (Ioi 0)).prod (μ.restrict f.support )) := by
  sorry

-- TODO: better name!
lemma restrict_to_support {p : ℝ} (hp : 0 < p) [TopologicalSpace E₁] [ESeminormedAddCommMonoid E₁] (f : α → E₁) :
    ∫⁻ x : α in f.support, ‖trunc f t x‖ₑ ^ p ∂ μ = ∫⁻ x : α, ‖trunc f t x‖ₑ ^ p ∂μ := by
  sorry

-- TODO: better name!
lemma restrict_to_support_truncCompl {p : ℝ} [TopologicalSpace E₁] [ESeminormedAddCommMonoid E₁] (hp : 0 < p) (f : α → E₁) :
    ∫⁻ x : α in f.support, ‖(truncCompl f t) x‖ₑ ^ p ∂μ =
    ∫⁻ x : α, ‖(truncCompl f t) x‖ₑ ^ p ∂μ := by
  sorry

-- TODO: better name!
lemma restrict_to_support_trnc {p : ℝ} {j : Bool} [TopologicalSpace E₁] [ESeminormedAddCommMonoid E₁] (hp : 0 < p) (f : α → E₁) :
    ∫⁻ x : α in f.support, ‖trnc j f t x‖ₑ ^ p ∂μ =
    ∫⁻ x : α, ‖trnc j f t x‖ₑ ^ p ∂μ := by
  sorry

@[fun_prop]
theorem AEMeasurable.trnc_restrict
    [MeasurableSpace E₁] [TopologicalSpace E₁] [ESeminormedAddCommMonoid E₁] [BorelSpace E₁] {j : Bool}
    (hf : AEMeasurable f μ) (tc : ToneCouple) :
    AEMeasurable (fun a ↦ trnc j f (tc.ton a.1) a.2)
      ((volume.restrict (Ioi 0)).prod (μ.restrict f.support)) := by
  sorry

lemma lintegral_lintegral_pow_swap_truncCompl {q q₀ p₀ : ℝ} [MeasurableSpace E₁]
    [TopologicalSpace E₁] [ESeminormedAddCommMonoid E₁] [TopologicalSpace.PseudoMetrizableSpace E₁]
    [BorelSpace E₁] -- TODO: I needed to add these, is that acceptable?
    {j : Bool} {hμ : SigmaFinite (μ.restrict f.support)}
    (hp₀ : 0 < p₀) (hp₀q₀ : p₀ ≤ q₀)
    (hf : AEStronglyMeasurable f μ) (tc : ToneCouple) :
    ∫⁻ (s : ℝ) in Ioi 0,
        (∫⁻ (a : α) in f.support, ENNReal.ofReal (s ^ (q - q₀ - 1)) ^ (p₀⁻¹ * q₀)⁻¹ *
        ‖trnc j f (tc.ton (ENNReal.ofReal s)) a‖ₑ ^ p₀ ∂μ) ^ (p₀⁻¹ * q₀) ≤
    (∫⁻ a : α in f.support,
      (∫⁻ (s : ℝ) in Ioi 0,
        (ENNReal.ofReal (s ^ (q - q₀ - 1)) ^ (p₀⁻¹ * q₀)⁻¹ *
        ‖trnc j f (tc.ton (ENNReal.ofReal s)) a‖ₑ ^ p₀) ^ (p₀⁻¹ * q₀)) ^ (p₀⁻¹ * q₀)⁻¹ ∂μ) ^ (p₀⁻¹ * q₀) := by
  sorry

lemma lintegral_congr_support {f : α → E₁} {g h : α → ENNReal}
    [TopologicalSpace E₁] [ENormedAddCommMonoid E₁]
    (hf : AEStronglyMeasurable f μ) (hgh : ∀ x ∈ f.support, g x = h x) :
    ∫⁻ x : α in f.support, g x ∂μ = ∫⁻ x : α in f.support, h x ∂μ := by
  sorry

/-- One of the key estimates for the real interpolation theorem, not yet using
the particular choice of exponent and scale in the `ScaledPowerFunction`. -/
lemma estimate_trnc {p₀ q₀ q : ℝ} {spf : ScaledPowerFunction} {j : Bool}
    [TopologicalSpace E₁] [ENormedAddCommMonoid E₁] [MeasurableSpace E₁] [BorelSpace E₁]
    [TopologicalSpace.PseudoMetrizableSpace E₁]
    (hp₀ : 0 < p₀) (hq₀ : 0 < q₀) (hp₀q₀ : p₀ ≤ q₀)
    (hf : AEStronglyMeasurable f μ) (hf₂ : SigmaFinite (μ.restrict f.support))
    (hpowers : if xor j (spf_to_tc spf).mon = true then q₀ < q else q < q₀)
    (hpow_pos : 0 < q₀ + spf.σ⁻¹ * (q - q₀)) :
    ∫⁻ s : ℝ in Ioi 0,
    eLpNorm (trnc j f ((spf_to_tc spf).ton (ENNReal.ofReal s))) (ENNReal.ofReal p₀) μ ^ q₀ *
    ENNReal.ofReal (s ^ (q - q₀ - 1)) ≤
    (spf.d ^ (q - q₀)) * ENNReal.ofReal |q - q₀|⁻¹ *
    (∫⁻ (a : α) in f.support,
    ‖f a‖ₑ ^ (p₀ + spf.σ⁻¹ * (q - q₀) * (p₀ / q₀)) ∂μ) ^ (p₀⁻¹ * q₀) := by
  sorry

-- TODO: add a doc-string, explaining the purpose of this definition
def sel (j : Bool) (p₀ p₁ : ℝ≥0∞) := match j with | true => p₁ | false => p₀

/-- One of the key estimates for the real interpolation theorem, now using
the particular choice of exponent, but not yet using the
particular choice of scale in the `ScaledPowerFunction`. -/
lemma estimate_trnc₁ {spf : ScaledPowerFunction} {j : Bool}
    [TopologicalSpace E₁] [ENormedAddCommMonoid E₁] [MeasurableSpace E₁]
    [BorelSpace E₁] [TopologicalSpace.PseudoMetrizableSpace E₁] (ht : t ∈ Ioo 0 1)
    (hp₀ : 0 < p₀) (hq₀ : 0 < q₀) (hp₁ : 0 < p₁) (hq₁ : 0 < q₁) (hpq : sel j p₀ p₁ ≤ sel j q₀ q₁)
    (hp' : sel j p₀ p₁ ≠ ⊤) (hq' : sel j q₀ q₁ ≠ ⊤) (hp₀p₁ : p₀ < p₁)
    (hq₀q₁ : q₀ ≠ q₁) (hp : p⁻¹ = (1 - t) * p₀⁻¹ + t * p₁⁻¹)
    (hq : q⁻¹ = (1 - t) * q₀⁻¹ + t * q₁⁻¹)
    (hf : AEStronglyMeasurable f μ) (hf₂ : SigmaFinite (μ.restrict f.support))
    (hspf : spf.σ = ζ p₀ q₀ p₁ q₁ t.toReal) :
    ∫⁻ s : ℝ in Ioi 0,
    eLpNorm (trnc j f ((spf_to_tc spf).ton (ENNReal.ofReal s))) (sel j p₀ p₁) μ ^ (sel j q₀ q₁).toReal *
    ENNReal.ofReal (s ^ (q.toReal - (sel j q₀ q₁).toReal - 1)) ≤
    (spf.d ^ (q.toReal - (sel j q₀ q₁).toReal)) *
    ENNReal.ofReal |q.toReal - (sel j q₀ q₁).toReal|⁻¹ *
    ((eLpNorm f p μ) ^ p.toReal) ^ ((sel j p₀ p₁).toReal ⁻¹ * (sel j q₀ q₁).toReal) := by
  sorry

-- TODO: move this to WeakType.lean?
lemma wnorm_eq_zero_iff [ENormedAddMonoid ε] {f : α → ε} {p : ℝ≥0∞} (hp : p ≠ 0) :
    wnorm f p μ = 0 ↔ f =ᵐ[μ] 0 := by
  sorry

/-! ## Weaktype estimates applied to truncations -/

variable [TopologicalSpace E₁] [ESeminormedAddCommMonoid E₁] [TopologicalSpace E₂] [ESeminormedAddCommMonoid E₂]
  {E₁' E₂' : Type*} [TopologicalSpace E₁'] [ENormedAddCommMonoid E₁'] [TopologicalSpace E₂'] [ENormedAddCommMonoid E₂']

lemma eLpNorm_trnc_est {f : α → E₁} {j : Bool} :
    eLpNorm (trnc j f t) p μ ≤ eLpNorm f p μ := by
  sorry

variable [ContinuousENorm ε₁] [ContinuousENorm ε₂] {T : (α → ε₁) → (α' → ε₂)} in
lemma weaktype_estimate {C₀ : ℝ≥0} {p : ℝ≥0∞} {q : ℝ≥0∞} {f : α → ε₁}
      (hq : 0 < q) (hq' : q < ⊤) (hf : MemLp f p μ)
    (h₀T : HasWeakType T p q μ ν C₀) (ht : 0 < t) :
    distribution (T f) t ν ≤ C₀ ^ q.toReal *
        eLpNorm f p μ ^ q.toReal * (t ^ (-q.toReal)) := by
  sorry

variable [ContinuousENorm ε₁] [ContinuousENorm ε₂] {T : (α → ε₁) → (α' → ε₂)} in
lemma weaktype_estimate_top {C : ℝ≥0} {p : ℝ≥0∞} {q : ℝ≥0∞}
    (hq' : q = ⊤) {f : α → ε₁} (hf : MemLp f p μ)
    (hT : HasWeakType T p q μ ν C) (ht : C * eLpNorm f p μ ≤ t) :
    distribution (T f) t ν = 0 := by
  sorry

variable [ENormedAddMonoid ε₁] [ENormedAddMonoid ε₂] in
/-- If `T` has weaktype `p₀`-`p₁`, `f` is `AEStronglyMeasurable` and the `p`-norm of `f`
    vanishes, then the `q`-norm of `T f` vanishes. -/
lemma weaktype_aux₀ {f : α → ε₁} {T : (α → ε₁) → (α' → ε₂)}
    {p₀ q₀ p q : ℝ≥0∞} (hp₀ : 0 < p₀) (hq₀ : 0 < q₀) (hp : 0 < p) (hq : 0 < q)
    {C₀ : ℝ≥0} (h₀T : HasWeakType T p₀ q₀ μ ν C₀)
    (hf : AEStronglyMeasurable f μ) (hF : eLpNorm f p μ = 0) : eLpNorm (T f) q ν = 0 := by
  sorry

-- for the remaining lemmas we use too much measure theory that is just for normed spaces
-- try to generalize to ENorm-classes after Mathlib refactor
variable {T : (α → E₁) → (α' → E₂)} {T' : (α → E₁') → (α' → E₂')}

lemma weaktype_estimate_truncCompl {C₀ : ℝ≥0} {p p₀ : ℝ≥0∞} {f : α → E₁}
    (hp₀ : 0 < p₀) {q₀ : ℝ≥0∞} (hp : p ≠ ⊤) (hq₀ : 0 < q₀) (hq₀' : q₀ < ⊤)
    (hp₀p : p₀ ≤ p) (hf : MemLp f p μ)
    (h₀T : HasWeakType T p₀ q₀ μ ν C₀) (ht : 0 < t) {a : ℝ≥0∞} (ha : 0 < a) :
    distribution (T (truncCompl f a)) t ν ≤ C₀ ^ q₀.toReal *
        eLpNorm (truncCompl f a) p₀ μ ^ q₀.toReal * (t ^ (-q₀.toReal)) := by
  sorry

-- TODO: can we remove the hypothesis on a?
lemma weaktype_estimate_trunc {C₁ : ℝ≥0} {p p₁ q₁ : ℝ≥0∞} {f : α → E₁'}
    (hp : 0 < p) (hq₁ : 0 < q₁) (hq₁' : q₁ < ⊤) (hp₁p : p ≤ p₁) (hf : MemLp f p μ)
    (h₁T : HasWeakType T' p₁ q₁ μ ν C₁) (ht : 0 < t) {a : ℝ≥0∞} (ha : a ≠ ⊤) :
    distribution (T' (trunc f a)) t ν ≤ C₁ ^ q₁.toReal *
      eLpNorm (trunc f a) p₁ μ ^ q₁.toReal * (t ^ (-q₁.toReal)) := by
  sorry

lemma weaktype_estimate_trunc_top_top {a : ℝ≥0∞} {C₁ : ℝ≥0}
    (hC₁ : 0 < C₁) {p p₁ q₁ : ℝ≥0∞} (hp : 0 < p)
    (hp₁ : p₁ = ⊤) (hq₁ : q₁ = ⊤) (hp₁p : p ≤ p₁) {f : α → E₁'} (hf : MemLp f p μ)
    (h₁T : HasWeakType T' p₁ q₁ μ ν C₁) (ha : a = t / C₁) :
    distribution (T' (trunc f a)) t ν = 0 := by
  sorry

lemma weaktype_estimate_truncCompl_top {C₀ : ℝ≥0} (hC₀ : 0 < C₀) {p p₀ q₀ : ℝ≥0∞}
    (hp₀ : 0 < p₀) (hq₀ : q₀ = ⊤) (hp₀p : p₀ < p) (hp : p ≠ ⊤) {f : α → E₁'} (hf : MemLp f p μ)
    (h₀T : HasWeakType T' p₀ q₀ μ ν C₀) (ht : 0 < t) {a : ℝ≥0∞} {d : ℝ≥0∞} -- (hd : 0 < d)
    (ha : a = (t / d) ^ (p₀.toReal / (p₀.toReal - p.toReal)))
    (hdeq : d = ((ENNReal.ofNNReal C₀) ^ p₀.toReal * eLpNorm f p μ ^ p.toReal) ^ p₀.toReal⁻¹) :
    distribution (T' (truncCompl f a)) t ν = 0 := by
  sorry

-- NB. The assumptions `hd` is necessary: if `t ≠ ∞` and `f` has eLpNorm 0, then `d = 0` as well
-- (since p.toReal and p₁.toReal are positive), hence `a = ∞`
-- and the statement becomes `distribution (T f) t ν = 0`, which is false in general.
lemma weaktype_estimate_trunc_top {C₁ : ℝ≥0} (hC₁ : 0 < C₁) {p p₁ q₁ : ℝ≥0∞}
    (hp : 0 < p)
    (hp₁ : p₁ < ⊤) (hq₁ : q₁ = ⊤) (hp₁p : p < p₁) {f : α → E₁'} (hf : MemLp f p μ)
    (h₁T : HasWeakType T' p₁ q₁ μ ν C₁) (ht : 0 < t) {a : ℝ≥0∞} {d : ℝ≥0∞} (hd : 0 < d)
    (ha : a = (t / d) ^ (p₁.toReal / (p₁.toReal - p.toReal)))
    (hdeq : d = ((ENNReal.ofNNReal C₁) ^ p₁.toReal * eLpNorm f p μ ^ p.toReal) ^ p₁.toReal⁻¹) :
    distribution (T' (trunc f a)) t ν = 0 := by
  sorry

end MeasureTheory

end
