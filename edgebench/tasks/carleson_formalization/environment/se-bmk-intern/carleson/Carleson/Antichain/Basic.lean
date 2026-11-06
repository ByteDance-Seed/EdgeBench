module

public import Carleson.Calculations
public import Carleson.Operators
public import Carleson.ToMathlib.HardyLittlewood
public import Carleson.ToMathlib.MeasureTheory.Integral.MeanInequalities

/-!
# 6.1. The density arguments

This file contains the proofs of lemmas 6.1.1, 6.1.2 and 6.1.3 from the blueprint.

## Main results
- `tile_disjointness`: Lemma 6.1.1.
- `maximal_bound_antichain`: Lemma 6.1.2.
- `dens2_antichain`: Lemma 6.1.3.
-/

@[expose] public section

open scoped ShortVariables

section

variable {X : Type*} {a : ℕ} {q : ℝ} {K : X → X → ℂ} {σ₁ σ₂ : X → ℤ} {F G : Set X}
  [MetricSpace X] [ProofData a q K σ₁ σ₂ F G]

open ENNReal Set

namespace ShortVariables

/-- $\tilde{q}$ from definition 6.1.10, as a nonnegative real number. Note that
`(nnqt : ℝ)⁻¹ - 2⁻¹ = 2⁻¹ * q⁻¹`. -/
scoped notation "nnqt" => 2*nnq/(nnq + 1)

end ShortVariables

lemma inv_nnqt_eq : (nnqt : ℝ)⁻¹ = 2⁻¹ + 2⁻¹ * q⁻¹ := by
  sorry

lemma inv_nnqt_mem_Ico : (nnqt : ℝ)⁻¹ ∈ Ico (3 / 4) 1 := by
  sorry

lemma one_lt_nnqt : 1 < nnqt := by
  sorry

lemma one_lt_nnqt_coe : (1 : ℝ≥0∞) < nnqt := by
  sorry

lemma nnqt_lt_nnq : nnqt < nnq := by
  sorry

lemma nnqt_lt_nnq_coe : (nnqt : ℝ≥0∞) < nnq := by
  sorry

lemma nnqt_lt_two : nnqt < 2 := by
  sorry

lemma nnqt_lt_two_coe : (nnqt : ℝ≥0∞) < 2 := by
  sorry

end

variable {X : Type*} {a : ℕ} {q : ℝ} {K : X → X → ℂ} {σ₁ σ₂ : X → ℤ} {F G : Set X}
  [MetricSpace X] [ProofData a q K σ₁ σ₂ F G] [TileStructure Q D κ S o]

noncomputable section

open Complex MeasureTheory Set

/-- Lemma 6.1.1. -/
lemma tile_disjointness {𝔄 : Set (𝔓 X)} (h𝔄 : IsAntichain (· ≤ ·) (𝔄 : Set (𝔓 X)))
     {p p' : 𝔓 X} (hp : p ∈ 𝔄) (hp' : p' ∈ 𝔄) (hE : ¬Disjoint (E p) (E p')) : p = p' := by
  sorry

open ENNReal Metric NNReal Real

/-- Constant appearing in Lemma 6.1.2.
Has value `2 ^ (102 * a ^ 3)` in the blueprint. -/
noncomputable def C6_1_2 (a : ℕ) : ℕ := 2 ^ ((𝕔 + 2) * a ^ 3)

lemma C6_1_2_ne_zero (a : ℕ) : (C6_1_2 a : ℝ≥0∞) ≠ 0 := by
  sorry

private lemma ineq_6_1_7 (x : X) {𝔄 : Set (𝔓 X)} (p : 𝔄) :
    (2 : ℝ≥0∞) ^ a ^ 3 / volume (ball x (D ^ 𝔰 p.1 / (D * 4))) ≤
    2 ^ (5 * a + (𝕔 + 1) * a ^ 3) / volume (ball x (8 * D ^ 𝔰 p.1)) := by
  sorry

-- Composition of inequalities 6.1.6, 6.1.7, 6.1.8.
lemma norm_Ks_le' {x y : X} {𝔄 : Set (𝔓 X)} (p : 𝔄) (hxE : x ∈ E ↑p) (hy : Ks (𝔰 p.1) x y ≠ 0) :
    ‖Ks (𝔰 p.1) x y‖ₑ ≤ 2 ^ (6 * a + (𝕔 + 1) * a ^ 3) / volume (ball (𝔠 p.1) (8 * D ^ 𝔰 p.1)) := by
  sorry

/-- Lemma 6.1.2. -/
lemma maximal_bound_antichain {𝔄 : Set (𝔓 X)} (h𝔄 : IsAntichain (· ≤ ·) 𝔄)
    {f : X → ℂ} (hfm : Measurable f) (x : X) :
    ‖carlesonSum 𝔄 f x‖ₑ ≤ (C6_1_2 a) * MB volume 𝔄 𝔠 (fun 𝔭 ↦ 8*D ^ 𝔰 𝔭) f x := by
  sorry

/-- Constant appearing in Lemma 6.1.3.
Has value `2 ^ (103 * a ^ 3)` in the blueprint. -/
noncomputable def C6_1_3 (a : ℕ) (q : ℝ≥0) : ℝ≥0 := 2 ^ ((𝕔 + 3) * a ^ 3) * (q - 1)⁻¹

-- Namespace for auxiliaries used in the proof of Lemma 6.1.3.
namespace Lemma6_1_3

variable (𝔄 : Set (𝔓 X)) {f g : X → ℂ}

/-- The maximal function used in the proof of Lemma 6.1.3 -/
def 𝓜 := MB volume 𝔄 𝔠 (fun 𝔭 ↦ 8 * D ^ 𝔰 𝔭) (E := ℂ)

-- Define exponents used in the proof and collect some basic facts about them.
section

include a q K σ₁ σ₂ F G
variable (X)
--set_option linter.unusedSectionVars false
omit [TileStructure Q D κ S o]

/-- $\tilde{q}$ from definition 6.1.10, as a real number. -/
def qt := (nnqt : ℝ)

lemma inv_qt_eq : (qt X)⁻¹ = 2⁻¹ + 2⁻¹ * q⁻¹ := by
  sorry

/-- Exponent used for the application of Hölder's inequality in the proof of Lemma 6.1.3. -/
def p := (3 / 2 - (qt X)⁻¹)⁻¹

lemma inv_p_eq : (p X)⁻¹ = 3 / 2 - (qt X)⁻¹ := by
  sorry

lemma inv_p_eq' : (p X)⁻¹ = 1 - 2⁻¹ * q⁻¹ := by
  sorry

lemma p_pos : 0 < p X := by
  sorry

lemma one_lt_p : 1 < p X := by
  sorry

lemma p_lt_two : p X < 2 := by
  sorry

end

/-- The `p` maximal function used in the proof. -/
def 𝓜p (p : ℝ) := maximalFunction volume 𝔄 𝔠 (fun 𝔭 ↦ 8 * D ^ 𝔰 𝔭) p.toNNReal (E := ℂ)

/-- Maximal function bound needed in the proof -/
lemma eLpNorm_𝓜p_le (hf : MemLp f 2) :
    eLpNorm (𝓜p 𝔄 (p X) f) 2 ≤ C2_0_6 (defaultA a) (p X).toNNReal 2 * eLpNorm f 2 := by
  sorry

/-- A maximal function bound via an application of H\"older's inequality -/
lemma eLpNorm_𝓜_le_eLpNorm_𝓜p_mul (hf : Measurable f) (hfF : ∀ x, ‖f x‖ ≤ F.indicator 1 x)
    {p p' : ℝ} (hpp : p.HolderConjugate p') :
    eLpNorm (𝓜 𝔄 f) 2 ≤ (dens₂ 𝔄) ^ (p'⁻¹) * eLpNorm (𝓜p 𝔄 p f) 2 := by
  sorry

omit [TileStructure Q D κ S o] in
/-- Tedious check that the constants work out. -/
lemma const_check : C6_1_2 a * C2_0_6 (defaultA a) (p X).toNNReal 2 ≤ C6_1_3 a nnq := by
  sorry

end Lemma6_1_3

open Lemma6_1_3 in
/-- Lemma 6.1.3 (inequality 6.1.11). -/
lemma dens2_antichain {𝔄 : Set (𝔓 X)} (h𝔄 : IsAntichain (· ≤ ·) 𝔄)
    {f : X → ℂ} (hfF : ∀ x, ‖f x‖ ≤ F.indicator 1 x) (hf : Measurable f)
    {g : X → ℂ} (hgG : ∀ x, ‖g x‖ ≤ G.indicator 1 x) (hg : Measurable g) :
    ‖∫ x, ((starRingEnd ℂ) (g x)) * carlesonSum 𝔄 f x‖ₑ ≤
      (C6_1_3 a nnq) * (dens₂ (𝔄 : Set (𝔓 X))) ^ ((nnqt : ℝ)⁻¹ - 2⁻¹) *
        eLpNorm f 2 * eLpNorm g 2 := by
  sorry
