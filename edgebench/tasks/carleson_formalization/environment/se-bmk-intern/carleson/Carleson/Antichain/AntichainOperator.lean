module

public import Carleson.Antichain.AntichainTileCount
public import Carleson.Antichain.TileCorrelation

/-!
# 6. Proof of the Antichain Operator Proposition

This file contains the proofs of Lemma 6.1.4 and Proposition 2.0.3 from the blueprint. Three
versions of the latter are provided.

## Main results
- `dens1_antichain` : Lemma 6.1.4.
- `antichain_operator`: Proposition 2.0.3.
-/

@[expose] public section
noncomputable section

open scoped ShortVariables ComplexConjugate GridStructure
open Set Complex MeasureTheory Metric NNReal ENNReal

variable {X : Type*} {a : ℕ} {q : ℝ} {K : X → X → ℂ} {σ₁ σ₂ : X → ℤ} {F G : Set X}
  [MetricSpace X] [ProofData a q K σ₁ σ₂ F G] [TileStructure Q D κ S o]
  {𝔄 : Set (𝔓 X)} {f g : X → ℂ}

-- set_option trace.Meta.Tactic.fun_prop true in
open Classical in
lemma dens1_antichain_rearrange (bg : BoundedCompactSupport g) :
    eLpNorm (adjointCarlesonSum 𝔄 g) 2 ^ 2 ≤
      2 * ∑ p with p ∈ 𝔄, ∑ p' with p' ∈ 𝔄 ∧ 𝔰 p' ≤ 𝔰 p,
        ‖∫ x, adjointCarleson p' g x * conj (adjointCarleson p g x)‖ₑ := by
  sorry

open Classical in
/-- `h(p)` in the proof of Lemma 6.1.4 (**d**ens₁ **a**nti**c**hain **h**). -/
def dach (𝔄 : Set (𝔓 X)) (p : 𝔓 X) (g : X → ℂ) : ℝ≥0∞ :=
  (volume (ball (𝔠 p) (14 * D ^ 𝔰 p)))⁻¹ *
  ∫⁻ x, ∑ p' with (p' ∈ 𝔄 ∧ 𝔰 p' ≤ 𝔰 p) ∧ (𝓘 p' : Set X) ⊆ ball (𝔠 p) (14 * D ^ 𝔰 p),
    (1 + edist_(p') (𝒬 p') (𝒬 p)) ^ (-(2 * a ^ 2 + a ^ 3 : ℝ)⁻¹) * (E p').indicator (‖g ·‖ₑ) x

open Classical in
lemma dens1_antichain_dach (hg : Measurable g) (hgG : ∀ x, ‖g x‖ ≤ G.indicator 1 x) :
    eLpNorm (adjointCarlesonSum 𝔄 g) 2 ^ 2 ≤
      Tile.C6_1_5 a * 2 ^ (6 * a + 1) * ∑ p with p ∈ 𝔄, dach 𝔄 p g * ∫⁻ y in E p, ‖g y‖ₑ := by
  sorry

/-- The `maximalFunction` instance that appears in Lemma 6.1.4's proof. -/
def M14 (𝔄 : Set (𝔓 X)) (p : ℝ) (g : X → ℂ) : X → ℝ≥0∞ :=
  maximalFunction volume 𝔄 𝔠 (14 * D ^ 𝔰 ·) p g

lemma eLpNorm_le_M14 {p : 𝔓 X} (mp : p ∈ 𝔄) {x₀ : X} (hx : x₀ ∈ ball (𝔠 p) (14 * D ^ 𝔰 p))
    {r : ℝ} (hr : 0 < r) :
    eLpNorm ((ball (𝔠 p) (14 * D ^ 𝔰 p)).indicator (‖g ·‖ₑ)) (ENNReal.ofReal r) volume ≤
      volume (ball (𝔠 p) (14 * D ^ 𝔰 p)) ^ r⁻¹ * M14 𝔄 r g x₀ := by
  sorry

open Antichain in
/-- Equations (6.1.34) to (6.1.37) in Lemma 6.1.4. -/
lemma dach_bound (h𝔄 : IsAntichain (· ≤ ·) 𝔄) {p : 𝔓 X} (mp : p ∈ 𝔄) (hg : Measurable g)
    (hgG : ∀ x, ‖g x‖ ≤ G.indicator 1 x) {x₀ : X} (hx : x₀ ∈ ball (𝔠 p) (14 * D ^ 𝔰 p)) :
    dach 𝔄 p g ≤ C6_1_6 a * dens₁ 𝔄 ^ (p₆ a : ℝ)⁻¹ * M14 𝔄 (q₆ a) g x₀ := by
  sorry

open Antichain in
lemma M14_bound (hg : MemLp g 2 volume) :
    eLpNorm (M14 𝔄 (q₆ a) g) 2 ≤ 2 ^ (a + 2) * eLpNorm g 2 := by
  sorry

/-- Constant appearing in Lemma 6.1.4.
Has value `2 ^ (117 * a ^ 3)` in the blueprint. -/
irreducible_def C6_1_4 (a : ℕ) : ℝ≥0 := 2 ^ ((𝕔 + 5 + 𝕔 / 8) * a ^ 3)

lemma le_C6_1_4 (a4 : 4 ≤ a) :
    Tile.C6_1_5 a * 2 ^ (6 * a + 1) * Antichain.C6_1_6 a * 2 ^ (a + 2) ≤ C6_1_4 a ^ 2 := by
  sorry

open Classical Antichain in
lemma dens1_antichain_sq (h𝔄 : IsAntichain (· ≤ ·) 𝔄)
    (hg : Measurable g) (hgG : ∀ x, ‖g x‖ ≤ G.indicator 1 x) :
    eLpNorm (adjointCarlesonSum 𝔄 g) 2 ^ 2 ≤
      (C6_1_4 a * dens₁ 𝔄 ^ (8 * a ^ 4 : ℝ)⁻¹ * eLpNorm g 2 volume) ^ 2 := by
  sorry

/-- Lemma 6.1.4. -/
lemma dens1_antichain (h𝔄 : IsAntichain (· ≤ ·) 𝔄) (hf : Measurable f)
    (hfF : ∀ x, ‖f x‖ ≤ F.indicator 1 x) (hg : Measurable g) (hgG : ∀ x, ‖g x‖ ≤ G.indicator 1 x) :
    ‖∫ x, conj (g x) * carlesonSum 𝔄 f x‖ₑ ≤
      C6_1_4 a * dens₁ 𝔄 ^ (8 * a ^ 4 : ℝ)⁻¹ * eLpNorm f 2 volume * eLpNorm g 2 volume := by
  sorry

/-- The constant appearing in Proposition 2.0.3.
Has value `2 ^ (117 * a ^ 3)` in the blueprint. -/
def C2_0_3 (a : ℕ) (q : ℝ≥0) : ℝ≥0 := 2 ^ ((𝕔 + 5 + 𝕔 / 8) * a ^ 3) / (q - 1)

variable (X) in
omit [TileStructure Q D κ S o] in
private lemma ineq_aux_2_0_3 :
    ((2 ^ ((𝕔 + 5 + 𝕔 / 8 : ℕ) * a ^ 3) : ℝ≥0) : ℝ≥0∞) ^ (q - 1) *
    (((2 ^ ((𝕔 + 3) * a ^ 3) : ℝ≥0) : ℝ≥0∞) * (nnq - 1)⁻¹) ^ (2 - q) ≤
    (2 ^ ((𝕔 + 5 + 𝕔 / 8 : ℕ) * a ^ 3) / (nnq - 1) : ℝ≥0) := by
  sorry

/-- Proposition 2.0.3. -/
theorem antichain_operator (h𝔄 : IsAntichain (· ≤ ·) 𝔄) (hf : Measurable f)
    (hf1 : ∀ x, ‖f x‖ ≤ F.indicator 1 x) (hg : Measurable g) (hg1 : ∀ x, ‖g x‖ ≤ G.indicator 1 x) :
    ‖∫ x, conj (g x) * carlesonSum 𝔄 f x‖ₑ ≤
      C2_0_3 a nnq * dens₁ 𝔄 ^ ((q - 1) / (8 * a ^ 4)) * dens₂ 𝔄 ^ (q⁻¹ - 2⁻¹) *
        eLpNorm f 2 volume * eLpNorm g 2 volume := by
  sorry

/-- Version of the antichain operator theorem, but controlling the integral of the norm instead of
the integral of the function multiplied by another function. -/
theorem antichain_operator' {A : Set X} (h𝔄 : IsAntichain (· ≤ ·) 𝔄)
    (hf : Measurable f) (hfF : ∀ x, ‖f x‖ ≤ F.indicator 1 x) (hA : A ⊆ G) :
    ∫⁻ x in A, ‖carlesonSum 𝔄 f x‖ₑ ≤
    C2_0_3 a nnq * dens₁ 𝔄 ^ ((q - 1) / (8 * a ^ 4)) * dens₂ 𝔄 ^ (q⁻¹ - 2⁻¹) *
    eLpNorm f 2 volume * volume G ^ (1/2 : ℝ) := by
  sorry

/-- Version of the antichain operator theorem, but controlling the integral of the norm instead of
the integral of the function multiplied by another function, and with the upper bound in terms
of `volume F` and `volume G`. -/
theorem antichain_operator_le_volume {A : Set X} (h𝔄 : IsAntichain (· ≤ ·) 𝔄)
    (hf : Measurable f) (hfF : ∀ x, ‖f x‖ ≤ F.indicator 1 x) (hA : A ⊆ G) :
    ∫⁻ x in A, ‖carlesonSum 𝔄 f x‖ₑ ≤
    C2_0_3 a nnq * dens₁ 𝔄 ^ ((q - 1) / (8 * a ^ 4)) * dens₂ 𝔄 ^ (q⁻¹ - 2⁻¹) *
    volume F ^ (1/2 : ℝ) * volume G ^ (1/2 : ℝ) := by
  sorry
