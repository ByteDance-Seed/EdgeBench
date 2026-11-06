module

public import Carleson.ToMathlib.ENorm
public import Mathlib.Analysis.SpecialFunctions.Log.Base
public import Mathlib.Analysis.SpecialFunctions.Trigonometric.Bounds
public import Mathlib.MeasureTheory.Integral.Average
public import Mathlib.MeasureTheory.Measure.Haar.OfBasis
import Mathlib.Algebra.Order.Group.Pointwise.Bounds

@[expose] public section

/-! # Miscellaneous additions to mathlib, to be sorted

* This file can import all ToMathlib files.
* If adding more than a few results, please put them in a more appropriate file in ToMathlib.

Upstreaming status: need to split up this file (according to the lemmas' future location)
Most lemmas look ready to be upstreamed; some will require small tweaks.
-/

open Function Set
open scoped ENNReal

-- todo: rename and protect `Real.RCLike`

namespace Real
-- to Mathlib.Analysis.SpecialFunctions.Log.Base
lemma le_pow_natCeil_logb {b x : ℝ} (hb : 1 < b) (hx : 0 < x) :
    x ≤ b ^ ⌈Real.logb b x⌉₊ := by
  sorry

end Real

section ENNReal

open ENNReal

lemma tsum_one_eq' {α : Type*} (s : Set α) : ∑' (_:s), (1 : ℝ≥0∞) = s.encard := by
  sorry

lemma ENNReal.tsum_const_eq' {α : Type*} (s : Set α) (c : ℝ≥0∞) :
    ∑' (_:s), (c : ℝ≥0∞) = s.encard * c := by
  sorry

/-! ## `ENNReal` manipulation lemmas -/

lemma ENNReal.sum_geometric_two_pow_toNNReal {k : ℕ} (hk : k > 0) :
    ∑' (n : ℕ), (2 : ℝ≥0∞) ^ (-k * n : ℤ) = (1 / (1 - 1 / 2 ^ k) : ℝ).toNNReal := by
  sorry

lemma ENNReal.sum_geometric_two_pow_neg_one : ∑' (n : ℕ), (2 : ℝ≥0∞) ^ (-n : ℤ) = 2 := by
  sorry

lemma ENNReal.sum_geometric_two_pow_neg_two :
    ∑' (n : ℕ), (2 : ℝ≥0∞) ^ (-2 * n : ℤ) = ((4 : ℝ) / 3).toNNReal := by
  sorry

lemma tsum_geometric_ite_eq_tsum_geometric {k c : ℕ} :
    (∑' (n : ℕ), if k ≤ n then (2 : ℝ≥0∞) ^ (-c * (n - k) : ℤ) else 0) =
    ∑' (n : ℕ), 2 ^ (-c * n : ℤ) := by
  sorry

lemma ENNReal.toReal_zpow (x : ℝ≥0∞) (z : ℤ) : x.toReal ^ z = (x ^ z).toReal := by
  sorry

-- TODO: this helper lemma may be useful in other places to, for instance in `HardyLittlewood.lean`
lemma iSup_rpow {ι : Sort*} {f : ι → ℝ≥0∞} {p : ℝ} (hp : 0 < p) :
    (⨆ n, f n) ^ p = ⨆ n, f n ^ p := by
  sorry

end ENNReal

section NNReal

@[simp]
lemma _root_.ENNReal.nnorm_toReal {x : ℝ≥0∞} : ‖x.toReal‖₊ = x.toNNReal := by
  sorry

end NNReal

namespace Function
section support

lemma support_rpow_of_pos {α : Type*} {f : α → ℝ≥0∞} {p : ℝ} (p_pos : 0 < p) :
    support (fun x ↦ f x ^ p) = support f := by
  sorry

lemma support_rpow_of_neg {α : Type*} {f : α → ℝ≥0∞} {p : ℝ} (p_neg : p < 0) :
    support (fun x ↦ f x ^ p) = {x | f x ≠ ⊤} := by
  sorry

@[simp] lemma support_ofNNReal : Function.support ENNReal.ofNNReal = Set.Ioi 0 := by
  sorry

end support
end Function

namespace MeasureTheory

set_option linter.style.refine false in
variable {α : Type*} {β : Type*} {s : Set α} {f g : α → β}
  {m : MeasurableSpace α} {mβ : MeasurableSpace β} {μ : Measure α} in
@[measurability, fun_prop]
protected theorem _root_.AEMeasurable.piecewise {d : DecidablePred (· ∈ s)} (hs : MeasurableSet s)
    (hf : AEMeasurable f μ) (hg : AEMeasurable g μ) : AEMeasurable (piecewise s f g) μ := by
  sorry

variable {α : Type*} {β : Type*} {p : α → Prop} {f g : α → β}
  {m : MeasurableSpace α} {mβ : MeasurableSpace β} {μ : Measure α} in
@[measurability, fun_prop]
protected theorem _root_.AEMeasurable.ite {d : DecidablePred p} (hp : MeasurableSet {a | p a})
    (hf : AEMeasurable f μ) (hg : AEMeasurable g μ) :
    AEMeasurable (fun x => ite (p x) (f x) (g x)) μ := by
  sorry

/-! ## Partitioning an interval -/

lemma lintegral_Ioc_partition {a b : ℕ} {c : ℝ} {f : ℝ → ℝ≥0∞} (hc : 0 ≤ c) :
    ∫⁻ t in Ioc (a * c) (b * c), f t =
    ∑ l ∈ Finset.Ico a b, ∫⁻ t in Ioc (l * c) ((l + 1 : ℕ) * c), f t := by
  sorry

/-! ## Averaging -/

-- Named for consistency with `lintegral_add_left'`
-- Maybe add laverage/laverage theorems for all the other lintegral_add statements?
lemma laverage_add_left {α : Type*} {m0 : MeasurableSpace α} {μ : Measure α}
    {f g : α → ENNReal} (hf : AEMeasurable f μ) :
    ⨍⁻ x, (f x + g x) ∂μ = ⨍⁻ x, f x ∂μ + ⨍⁻ x, g x ∂μ := by
  sorry

-- Named for consistency with `lintegral_mono'`
lemma laverage_mono {α : Type*} {m0 : MeasurableSpace α} {μ : Measure α}
    {f g : α → ENNReal} (h : ∀ x, f x ≤ g x) :
    ⨍⁻ x, f x ∂μ ≤ ⨍⁻ x, g x ∂μ := by
  sorry

lemma laverage_const_mul {α : Type*} {m0 : MeasurableSpace α} {μ : Measure α}
    {f : α → ENNReal} {c : ENNReal} (hc : c ≠ ⊤) :
    c * ⨍⁻ x, f x ∂μ = ⨍⁻ x, c * f x ∂μ := by
  sorry

-- The following two lemmas are unused

-- Named for consistency with `lintegral_add_left'`
-- Maybe add laverage/setLaverage theorems for all the other lintegral_add statements?
lemma setLaverage_add_left' {α : Type*} {m0 : MeasurableSpace α} {μ : Measure α}
    {s : Set α} {f g : α → ENNReal} (hf : AEMeasurable f μ) :
    ⨍⁻ x in s, (f x + g x) ∂μ = ⨍⁻ x in s, f x ∂μ + ⨍⁻ x in s, g x ∂μ := by
  sorry

-- Named for consistency with `setLintegral_mono'`
lemma setLaverage_mono' {α : Type*} {m0 : MeasurableSpace α} {μ : Measure α}
    {s : Set α} (hs : MeasurableSet s) {f g : α → ENNReal} (h : ∀ x ∈ s, f x ≤ g x) :
    ⨍⁻ x in s, f x ∂μ ≤ ⨍⁻ x in s, g x ∂μ := by
  sorry

lemma AEStronglyMeasurable_continuousMap_coe {X Y : Type*} [TopologicalSpace X] [TopologicalSpace Y]
    [MeasurableSpace X] [OpensMeasurableSpace X] [TopologicalSpace.PseudoMetrizableSpace Y]
    [SecondCountableTopologyEither X Y]
    (f : C(X, Y)) : StronglyMeasurable f := by
  sorry

end MeasureTheory

namespace MeasureTheory
variable {α : Type*} {m : MeasurableSpace α} {μ : Measure α} {s : Set α}
  {F : Type*} [NormedAddCommGroup F]

attribute [fun_prop] Continuous.comp_aestronglyMeasurable
  AEStronglyMeasurable.mul AEStronglyMeasurable.prodMk
  AEMeasurable.restrict AEStronglyMeasurable.restrict
  AEStronglyMeasurable.const_smul AEStronglyMeasurable.const_smul'
  AEStronglyMeasurable.smul_const
  AEStronglyMeasurable.mul AEStronglyMeasurable.add
  AEStronglyMeasurable.mul_const AEStronglyMeasurable.const_mul
  AEStronglyMeasurable.inv AEStronglyMeasurable.div
attribute [gcongr] Measure.AbsolutelyContinuous.prod -- todo: also add one-sided versions for gcongr
attribute [fun_prop] AEStronglyMeasurable.comp_measurable
attribute [fun_prop] StronglyMeasurable.measurable

lemma measure_mono_ae' {A B : Set α} (h : μ (B \ A) = 0) : μ B ≤ μ A := by
  sorry

theorem AEStronglyMeasurable.ennreal_toReal {u : α → ℝ≥0∞} (hu : AEStronglyMeasurable u μ) :
    AEStronglyMeasurable (fun x ↦ (u x).toReal) μ := by
  sorry

lemma setLaverage_const_le {c : ℝ≥0∞} : ⨍⁻ _x in s, c ∂μ ≤ c := by
  sorry

theorem eLpNormEssSup_lt_top_of_ae_ennnorm_bound {f : α → F} {C : ℝ≥0∞}
    (hfC : ∀ᵐ x ∂μ, ‖f x‖₊ ≤ C) : eLpNormEssSup f μ ≤ C := by
  sorry

theorem restrict_absolutelyContinuous : μ.restrict s ≪ μ := by
  sorry

section eLpNorm

variable {p : ℝ≥0∞}

open NNReal ENNReal NormedSpace MeasureTheory Set Filter Topology Function

lemma eLpNormEssSup_toReal_le {f : α → ℝ≥0∞} :
    eLpNormEssSup (ENNReal.toReal ∘ f) μ ≤ eLpNormEssSup f μ := by
  sorry

lemma eLpNormEssSup_toReal_eq {f : α → ℝ≥0∞} (hf : ∀ᵐ x ∂μ, f x ≠ ∞) :
    eLpNormEssSup (ENNReal.toReal ∘ f) μ = eLpNormEssSup f μ := by
  sorry

lemma eLpNorm'_toReal_le {f : α → ℝ≥0∞} {p : ℝ} (hp : 0 ≤ p) :
    eLpNorm' (ENNReal.toReal ∘ f) p μ ≤ eLpNorm' f p μ := by
  sorry

lemma eLpNorm'_toReal_eq {f : α → ℝ≥0∞} {p : ℝ} (hf : ∀ᵐ x ∂μ, f x ≠ ∞) :
    eLpNorm' (ENNReal.toReal ∘ f) p μ = eLpNorm' f p μ := by
  sorry

lemma eLpNorm_toReal_le {f : α → ℝ≥0∞} :
    eLpNorm (ENNReal.toReal ∘ f) p μ ≤ eLpNorm f p μ := by
  sorry

lemma eLpNorm_toReal_eq {f : α → ℝ≥0∞} (hf : ∀ᵐ x ∂μ, f x ≠ ∞) :
    eLpNorm (ENNReal.toReal ∘ f) p μ = eLpNorm f p μ := by
  sorry

lemma sq_eLpNorm_two {ε : Type*} [ENorm ε] {f : α → ε} :
    eLpNorm f 2 μ ^ 2 = ∫⁻ x, ‖f x‖ₑ ^ 2 ∂μ := by
  sorry

open ComplexConjugate in
/-- One of the very few cases where a norm can be moved _out of_ an integral. -/
lemma eLpNorm_two_eq_enorm_integral_mul_conj {f : α → ℂ} (lpf : MemLp f 2 μ) :
    eLpNorm f 2 μ ^ 2 = ‖∫ x, f x * conj (f x) ∂μ‖ₑ := by
  sorry

end eLpNorm

namespace MemLp

variable {p : ℝ≥0∞}
theorem toReal {f : α → ℝ≥0∞} (hf : MemLp f p μ) : MemLp (f · |>.toReal) p μ := by
  sorry

end MemLp

theorem Integrable.toReal {f : α → ℝ≥0∞} (hf : Integrable f μ) : Integrable (f · |>.toReal) μ := by
  sorry

end MeasureTheory

section

open MeasureTheory Bornology
variable {E X : Type*} {p : ℝ≥0∞} [NormedAddCommGroup E] [TopologicalSpace X] [MeasurableSpace X]
  {μ : Measure X} [IsFiniteMeasureOnCompacts μ] {f : X → E}

---- now obsolete -> `BoundedCompactSupport.memLp`
-- lemma _root_.HasCompactSupport.memLp_of_isBounded (hf : HasCompactSupport f)
--     (h2f : IsBounded (range f))
--     (h3f : AEStronglyMeasurable f μ) {p : ℝ≥0∞} : MemLp f p μ := by
--   obtain ⟨C, hC⟩ := h2f.exists_norm_le
--   simp only [mem_range, forall_exists_index, forall_apply_eq_imp_iff] at hC
--   exact hf.memLp_of_bound h3f C <| .of_forall hC

end

/-! ## `EquivalenceOn` -/

/-- An equivalence relation on the set `s`. -/
structure EquivalenceOn {α : Type*} (r : α → α → Prop) (s : Set α) : Prop where
  /-- An equivalence relation is reflexive: `x ~ x` -/
  refl  : ∀ x ∈ s, r x x
  /-- An equivalence relation is symmetric: `x ~ y` implies `y ~ x` -/
  symm  : ∀ {x y}, x ∈ s → y ∈ s → r x y → r y x
  /-- An equivalence relation is transitive: `x ~ y` and `y ~ z` implies `x ~ z` -/
  trans : ∀ {x y z}, x ∈ s → y ∈ s → z ∈ s → r x y → r y z → r x z

namespace EquivalenceOn

variable {α : Type*} {r : α → α → Prop} {s : Set α} {hr : EquivalenceOn r s} {x y : α}

variable (hr) in
/-- The setoid defined from an equivalence relation on a set. -/
protected def setoid : Setoid s where
  r x y := r x y
  iseqv := {
    refl := fun x ↦ hr.refl x x.2
    symm := fun {x y} ↦ hr.symm x.2 y.2
    trans := fun {x y z} ↦ hr.trans x.2 y.2 z.2
  }

include hr in
lemma exists_rep (x : α) : ∃ y, x ∈ s → y ∈ s ∧ r x y := by
  sorry

open Classical in
variable (hr) in
/-- An arbitrary representative of `x` w.r.t. the equivalence relation `r`. -/
protected noncomputable def out (x : α) : α :=
  if hx : x ∈ s then (Quotient.out (s := hr.setoid) ⟦⟨x, hx⟩⟧ : s) else x

lemma out_mem (hx : x ∈ s) : hr.out x ∈ s := by
  sorry

@[simp]
lemma out_mem_iff : hr.out x ∈ s ↔ x ∈ s := by
  sorry

lemma out_rel (hx : x ∈ s) : r (hr.out x) x := by
  sorry

lemma rel_out (hx : x ∈ s) : r x (hr.out x) := by
  sorry

lemma out_inj (hx : x ∈ s) (hy : y ∈ s) (h : r x y) : hr.out x = hr.out y := by
  sorry

lemma out_inj' (hx : x ∈ s) (hy : y ∈ s) (h : r (hr.out x) (hr.out y)) : hr.out x = hr.out y := by
  sorry

variable (hr) in
/-- The set of representatives of an equivalence relation on a set. -/
def reprs : Set α := hr.out '' s

lemma out_mem_reprs (hx : x ∈ s) : hr.out x ∈ hr.reprs := by
  sorry

lemma reprs_subset : hr.reprs ⊆ s := by
  sorry

lemma reprs_inj (hx : x ∈ hr.reprs) (hy : y ∈ hr.reprs) (h : r x y) : x = y := by
  sorry

end EquivalenceOn

namespace Set.Finite

lemma biSup_eq {α : Type*} {ι : Type*} [CompleteLinearOrder α] {s : Set ι}
    (hs : s.Finite) (hs' : s.Nonempty) (f : ι → α) :
    ∃ i ∈ s, ⨆ j ∈ s, f j = f i := by
  sorry

end Set.Finite

lemma Real.self_lt_two_rpow (x : ℝ) : x < 2 ^ x := by
  sorry

@[fun_prop]
lemma Complex.measurable_starRingEnd : Measurable (starRingEnd ℂ) := by
  sorry

namespace ENNReal

lemma rpow_le_rpow_of_nonpos {x y : ℝ≥0∞} {z : ℝ} (hz : z ≤ 0) (h : x ≤ y) :
    y ^ z ≤ x ^ z := by
  sorry

lemma rpow_lt_rpow_of_neg {x y : ℝ≥0∞} {z : ℝ} (hz : z < 0) (h : x < y) :
    y ^ z < x ^ z := by
  sorry

lemma rpow_lt_rpow_iff_of_neg {x y : ℝ≥0∞} {z : ℝ} (hz : z < 0) :
    x ^ z < y ^ z ↔ y < x := by
  sorry

lemma rpow_le_rpow_iff_of_neg {x y : ℝ≥0∞} {z : ℝ} (hz : z < 0) :
    x ^ z ≤ y ^ z ↔ y ≤ x := by
  sorry

theorem rpow_le_self_of_one_le {x : ℝ≥0∞} {y : ℝ} (hx : 1 ≤ x) (hy : y ≤ 1) :
    x ^ y ≤ x := by
  sorry

end ENNReal

namespace Set

section Indicator

open ComplexConjugate

attribute [gcongr] Set.indicator_le_indicator mulIndicator_le_mulIndicator_of_subset

lemma indicator_eq_indicator' {α : Type*} {M : Type*} [Zero M] {s : Set α} {f g : α → M} (h : ∀ x ∈ s, f x = g x) :
    s.indicator f = s.indicator g := by
  sorry

lemma indicator_eq_indicator_one_mul {ι M : Type*} [MulZeroOneClass M]
    (s : Set ι) (f : ι → M) (x : ι) : s.indicator f x = s.indicator 1 x * f x := by
  sorry

lemma conj_indicator {α 𝕜 : Type*} [RCLike 𝕜] {f : α → 𝕜} (s : Set α) (x : α) :
    conj (s.indicator f x) = s.indicator (conj f) x := by
  sorry

lemma eq_indicator_one_mul_of_norm_le {X : Type*} {F : Set X} {f : X → ℂ}
    (hf : ∀ x, ‖f x‖ ≤ F.indicator 1 x) :
    f = (F.indicator 1) * f := by
  sorry

lemma indicator_one_le_one {X : Type*} {G : Set X} (x : X) :
    G.indicator (1 : X → ℝ) x ≤ 1 := by
  sorry

end Indicator

end Set

section Norm

open Complex

-- TODO: add enorm analogues of these lemmas when not present yet;
-- the first one will require a new class `ENormOneClass` (and maybe generalising much of
-- mathlib's lemmas to that class, as appropriate).

-- for mathlib?
lemma norm_indicator_one_le {α E}
    [SeminormedAddCommGroup E] [One E] [NormOneClass E] {s : Set α} (x : α) :
    ‖s.indicator (1 : α → E) x‖ ≤ 1 := by
  sorry

-- TODO: which of these lemmas have been upstreamed to mathlib already?

lemma norm_one_sub_exp_neg_I_mul_ofReal (x : ℝ) : ‖1 - exp (-(I * x))‖ = ‖1 - exp (I * x)‖ := by
  sorry

open Real in
lemma exp_I_mul_eq_one_iff_of_lt_of_lt (x : ℝ) (hx : -(2 * π) < x) (h'x : x < 2 * π) :
    exp (I * x) = 1 ↔ x = 0 := by
  sorry

end Norm

section BddAbove
-- move near BddAbove.range_add if that imports Finset.sum

variable {ι ι' α M : Type*} [Preorder M]

@[simp]
theorem BddAbove.range_const {c : M} : BddAbove (range (fun _ : ι ↦ c)) := by
  sorry

variable [One M] in
@[to_additive (attr := simp)]
theorem BddAbove.range_one : BddAbove (range (1 : ι → M)) := by
  sorry

variable [AddCommMonoid M] [AddLeftMono M] [AddRightMono M] in
theorem BddAbove.range_finsetSum {s : Finset ι} {f : ι → ι' → M}
    (hf : ∀ i ∈ s, BddAbove (range (f i))) :
    BddAbove (range (fun x ↦ ∑ i ∈ s, f i x)) := by
  sorry

-- TODO: should there be enorm versions of these lemmas?

open Bornology
@[to_additive isBounded_iff_bddAbove_norm]
lemma isBounded_iff_bddAbove_norm' {E} [SeminormedCommGroup E] {s : Set E} :
    IsBounded s ↔ BddAbove (Norm.norm '' s) := by
  sorry

lemma isBounded_range_iff_bddAbove_norm' {ι E} [SeminormedAddCommGroup E] {f : ι → E} :
    IsBounded (range f) ↔ BddAbove (range (‖f ·‖)) := by
  sorry

lemma isBounded_image_iff_bddAbove_norm' {ι E} [SeminormedAddCommGroup E] {f : ι → E} {s : Set ι} :
    IsBounded (f '' s) ↔ BddAbove ((‖f ·‖) '' s) := by
  sorry

end BddAbove

namespace MeasureTheory

open Metric Bornology
variable {𝕜 : Type*} [RCLike 𝕜] {X α : Type*}

-- TODO: can this be moved to HasCompactSupport? should it move there, when upstreaming?
namespace HasCompactSupport

variable [Zero α] {f : X → α}

variable [PseudoMetricSpace X] [ProperSpace X]

theorem of_support_subset_closedBall {x : X}
    {r : ℝ} (hf : support f ⊆ closedBall x r) :
    HasCompactSupport f := by
  sorry

theorem of_support_subset_isBounded {s : Set X}
    (hs : IsBounded s) (hf : support f ⊆ s) :
    HasCompactSupport f := by
  sorry

end HasCompactSupport

namespace Integrable

variable [MeasureSpace X]

-- must be in mathlib but can't find it
theorem indicator_const {c : ℝ} {s : Set X}
    (hs : MeasurableSet s) (h2s : volume s < ⊤) : Integrable (s.indicator (fun _ ↦ c)) := by
  sorry

end Integrable

-- Currently unused.
-- The assumption `int_f` can likely be removed, as otherwise the integral is zero.
open Classical in
theorem setIntegral_biUnion_le_sum_setIntegral {X : Type*} {ι : Type*} [MeasurableSpace X]
    {f : X → ℝ} (s : Finset ι) {S : ι → Set X} {μ : Measure X}
    (f_ae_nonneg : ∀ᵐ (x : X) ∂μ.restrict (⋃ i ∈ s, S i), 0 ≤ f x)
    (int_f : IntegrableOn f (⋃ i ∈ s, S i) μ) :
    ∫ x in (⋃ i ∈ s, S i), f x ∂μ ≤ ∑ i ∈ s, ∫ x in S i, f x ∂μ := by
  sorry

-- Analogous to `MeasureTheory.integral_smul_const` in Mathlib
theorem average_smul_const {X : Type*} {E : Type*} [MeasurableSpace X]
    {μ : MeasureTheory.Measure X} [NormedAddCommGroup E] [NormedSpace ℝ E] {𝕜 : Type*}
    [RCLike 𝕜] [NormedSpace 𝕜 E] [CompleteSpace E] (f : X → 𝕜) (c : E) :
    ⨍ (x : X), f x • c ∂μ = (⨍ (x : X), f x ∂μ) • c := by
  sorry

end MeasureTheory

namespace ENNReal

set_option backward.isDefEq.respectTransparency false in
theorem lintegral_Lp_smul {α : Type*} [MeasurableSpace α] {μ : MeasureTheory.Measure α}
    {f : α → ℝ≥0∞} (hf : AEMeasurable f μ) {p : ℝ} (hp : p > 0) (c : NNReal) :
    (∫⁻ x : α, (c • f) x ^ p ∂μ) ^ (1 / p) = c • (∫⁻ x : α, f x ^ p ∂μ) ^ (1 / p) := by
  sorry

-- Analogous to `ENNReal.ofReal_pow` in Mathlib
-- Currently unused
theorem ofReal_zpow {p : ℝ} (hp : 0 < p) (n : ℤ) :
    ENNReal.ofReal (p ^ n) = ENNReal.ofReal p ^ n := by
  sorry

end ENNReal

--TODO: to mathlib
@[to_additive (attr := simp)]
theorem prod_attach_insert {α β : Type*} {s : Finset α} {a : α} [DecidableEq α] [CommMonoid β]
    {f : { i // i ∈ insert a s } → β} (ha : a ∉ s) :
    ∏ x ∈ (insert a s).attach, f x =
    f ⟨a, Finset.mem_insert_self a s⟩ * ∏ x ∈ s.attach, f ⟨x, Finset.mem_insert_of_mem x.2⟩ := by
  sorry

@[to_additive]
lemma Finset.prod_finset_product_filter_right {α β γ : Type*} {s : Finset α} {t : Finset β}
    {p : α → Prop} {q : α → β → Prop} [DecidablePred p] [DecidableRel q]
    [DecidablePred fun r : α × β ↦ p r.1 ∧ q r.1 r.2] {f : α → β → γ} [CommMonoid γ] :
    ∏ x ∈ s with p x, ∏ y ∈ t with q x y, f x y =
    ∏ r ∈ s ×ˢ t with p r.1 ∧ q r.1 r.2, f r.1 r.2 := by
  sorry

open Classical ComplexConjugate in
lemma Finset.sum_range_mul_conj_sum_range {α : Type*} {s : Finset α} {f : α → ℂ} :
    ∑ j ∈ s, f j * conj (f j) + ∑ j ∈ s, ∑ j' ∈ s with j ≠ j', f j * conj (f j') =
    (∑ j ∈ s, f j) * conj (∑ j' ∈ s, f j') := by
  sorry

lemma Finset.pow_sum_comm {ι R : Type*} [Semiring R] {s : Finset ι} {f : ι → R}
    (hf : ∀ i ∈ s, ∀ j ∈ s, i ≠ j → f i * f j = 0) {n : ℕ} (hn : 1 ≤ n) :
    (∑ i ∈ s, f i) ^ n = ∑ i ∈ s, f i ^ n := by
  sorry

namespace MeasureTheory

lemma sum_sq_eLpNorm_indicator_le_of_pairwiseDisjoint
    {α ι F : Type*} [MeasurableSpace α] [NormedAddCommGroup F] {μ : Measure α}
    {s : Finset ι} {f : α → F} {t : ι → Set α} (meast : ∀ i, MeasurableSet (t i))
    (hpd : PairwiseDisjoint s t) :
    ∑ i ∈ s, eLpNorm ((t i).indicator f) 2 μ ^ 2 ≤ eLpNorm f 2 μ ^ 2 := by
  sorry

theorem measurable_measure_ball {α : Type*} [PseudoMetricSpace α] [SecondCountableTopology α]
    [MeasurableSpace α] [OpensMeasurableSpace α] {μ : Measure α} [SFinite μ] :
    Measurable fun (a, r) ↦ μ (Metric.ball a r) := by
  sorry

end MeasureTheory
