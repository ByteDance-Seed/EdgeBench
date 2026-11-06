module

public import Carleson.ToMathlib.MeasureTheory.Function.LorentzSeminorm.Basic
public import Carleson.ToMathlib.MeasureTheory.Function.LpSeminorm.TriangleInequality
public import Mathlib.Analysis.MeanInequalitiesPow
public import Carleson.ToMathlib.MeasureTheory.Function.SimpleFunc
public import Carleson.ToMathlib.MeasureTheory.Function.LpSeminorm.CompareExp
public import Carleson.ToMathlib.MeasureTheory.Integral.Misc

/-!
# Triangle inequality for `Lorentz`-seminorm

In this file we prove several versions of the triangle inequality for the `Lorentz` seminorm,
as well as simple corollaries.
-/

@[expose] public section

@[expose] public section

-- Upstreaming status: statements should be checked to closely match the corresponding statements
-- for `eLpNorm`; proofs might still need some cleanup

open Filter
open scoped NNReal ENNReal Topology

namespace MeasureTheory

variable {α ε : Type*} {m : MeasurableSpace α}
  [TopologicalSpace ε] [ESeminormedAddMonoid ε]
  {p q : ℝ≥0∞} {μ : Measure α} {f g : α → ε}

open ENNReal in
theorem eLorentzNorm_add_le'' :
    eLorentzNorm (f + g) p q μ ≤ 2 ^ p.toReal⁻¹ * LpAddConst q * (eLorentzNorm f p q μ + eLorentzNorm g p q μ) := by
  sorry

/-- The function `k` in the proof of Theorem 6.7 in https://doi.org/10.1007/978-3-319-30034-4 -/
noncomputable def lorentz_helper (f : α → ε) (p q : ℝ≥0∞) (μ : Measure α) : ℝ≥0 → ℝ≥0∞ :=
  eLorentzNorm' f p q μ ^ (1 - q.toReal) •
    (fun (t : ℝ≥0) ↦ (t ^ (p⁻¹.toReal - q⁻¹.toReal) * rearrangement f t μ) ^ (q.toReal - 1))

lemma eLpNorm_lorentz_helper (p_ne_zero : p ≠ 0) (p_ne_top : p ≠ ⊤)
  (one_le_q : 1 ≤ q) (q_ne_top : q ≠ ⊤)
  (hf : eLorentzNorm' f p q μ ≠ 0) (hf' : eLorentzNorm' f p q μ ≠ ⊤) :
    eLpNorm (lorentz_helper f p q μ) q.conjExponent = 1 := by
  sorry

theorem antitone_rpow_inv_sub_inv (q_le_p : q ≤ p) (q_zero : q ≠ 0) :
    Antitone fun (x : ℝ≥0) ↦ (ENNReal.ofNNReal x) ^ (p.toReal⁻¹ - q.toReal⁻¹) := by
  sorry

lemma antitone_lorentz_helper (hq : 1 ≤ q) (q_le_p : q ≤ p) (p_top : p ≠ ⊤) :
    Antitone (lorentz_helper f p q μ) := by
  sorry

@[measurability, fun_prop]
lemma lorentz_helper_measurable : Measurable (lorentz_helper f p q μ) := by
  sorry

lemma eLorentzNorm'_eq_lintegral_lorentz_helper_mul (p_ne_zero : p ≠ 0) (p_ne_top : p ≠ ⊤)
  (hq : 1 ≤ q) (q_ne_top : q ≠ ⊤) (f_ne_top : eLorentzNorm' f p q μ ≠ ⊤) :
    eLorentzNorm' f p q μ
      = eLpNorm (lorentz_helper f p q μ * fun (t : ℝ≥0) ↦ t ^ (p⁻¹.toReal - q⁻¹.toReal) * rearrangement f t μ) 1 := by
  sorry

open ENNReal in
theorem eLorentzNorm_add_le [ContinuousAdd ε] (one_le_q : 1 ≤ q) (q_le_p : q ≤ p)
     (hf : AEStronglyMeasurable f μ) (hg : AEStronglyMeasurable g μ) :
      eLorentzNorm (f + g) p q μ ≤ eLorentzNorm f p q μ + eLorentzNorm g p q μ := by
  sorry

open ENNReal

/-- A constant for the inequality `‖f + g‖_{L^{p,q}} ≤ C * (‖f‖_{L^{p,q}} + ‖g‖_{L^{p,q}})`. It is equal to `1`
if `p = 0` or `1 ≤ r ≤ p` and `2^(1/p) * LpAddConst r` else. -/
noncomputable def LorentzAddConst (p r : ℝ≥0∞) : ℝ≥0∞ :=
  if p = 0 ∨ r ∈ Set.Icc 1 p then 1 else 2 ^ p.toReal⁻¹ * LpAddConst r

theorem LorentzAddConst_of_one_le (hr : q ∈ Set.Icc 1 p) : LorentzAddConst p q = 1 := by
  sorry

theorem LorentzAddConst_zero : LorentzAddConst 0 q = 1 := by
  sorry

theorem LorentzAddConst_lt_top : LorentzAddConst p q < ∞ := by
  sorry

lemma eLorentzNorm_add_le' [ContinuousAdd ε] (hf : AEStronglyMeasurable f μ) (hg : AEStronglyMeasurable g μ) :
    eLorentzNorm (f + g) p q μ ≤ LorentzAddConst p q * (eLorentzNorm f p q μ + eLorentzNorm g p q μ) := by
  sorry

lemma eLorentzNorm_add_lt_top [ContinuousAdd ε] (hf : MemLorentz f p q μ) (hg : MemLorentz g p q μ) :
    eLorentzNorm (f + g) p q μ < ⊤ := by
  sorry

lemma MemLorentz.add [ContinuousAdd ε] (hf : MemLorentz f p q μ)
    (hg : MemLorentz g p q μ) : MemLorentz (f + g) p q μ := by
  sorry

--currently unused
open ENNReal in
theorem eLorentzNorm_add_le_of_disjoint_support (h : Disjoint f.support g.support)
  (hg : AEStronglyMeasurable g μ) :
    eLorentzNorm (f + g) p q μ
      ≤ (LpAddConst p) * (LpAddConst q) * (eLorentzNorm f p q μ + eLorentzNorm g p q μ) := by
  sorry

end MeasureTheory
