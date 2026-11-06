module

public import Carleson.Calculations
public import Carleson.HolderVanDerCorput
public import Carleson.Operators
public import Carleson.ToMathlib.MeasureTheory.Integral.Bochner.ContinuousLinearMap

/-!
# 6.2. Proof of the Tile Correlation Lemma

This file contains the proofs of lemmas 6.2.1, 6.2.2, 6.2.3 and 6.1.5 from the blueprint.

## Main definitions
- `Tile.correlation` : the function `φ` defined in Lemma 6.2.1.

## Main results
- `Tile.mem_ball_of_correlation_ne_zero` and `Tile.correlation_kernel_bound`: Lemma 6.2.1.
- `Tile.range_support`: Lemma 6.2.2.
- `Tile.uncertainty` : Lemma 6.2.3.
- `Tile.correlation_le` and `Tile.correlation_zero_of_ne_subset`: Lemma 6.1.5.
-/

@[expose] public section

macro_rules | `(tactic |gcongr_discharger) => `(tactic | with_reducible assumption)

noncomputable section

open scoped ComplexConjugate ENNReal NNReal ShortVariables

open Complex Function MeasureTheory Measure Metric Set

namespace Tile

variable {X : Type*} {a : ℕ} {q : ℝ} {K : X → X → ℂ} {σ₁ σ₂ : X → ℤ} {F G : Set X} [MetricSpace X]
  [ProofData a q K σ₁ σ₂ F G]

/-- Def 6.2.1 (from Lemma 6.2.1), denoted by `φ(y)` in the blueprint. -/
def correlation (s₁ s₂ : ℤ) (x₁ x₂ y : X) : ℂ := conj (Ks s₁ x₁ y) * Ks s₂ x₂ y

@[fun_prop]
lemma measurable_correlation : Measurable (correlation (X := X)) := by
  sorry

/-- First part of Lemma 6.2.1 (eq. 6.2.2). -/
lemma mem_ball_of_correlation_ne_zero {s₁ s₂ : ℤ} {x₁ x₂ y : X}
    (hy : correlation s₁ s₂ x₁ x₂ y ≠ 0) : y ∈ ball x₁ (D ^ s₁) := by
  sorry

/-- The constant from lemma 6.2.1.
Has value `2 ^ (231 * a ^ 3)` in the blueprint. -/
def C6_2_1 (a : ℕ) : ℝ≥0 := 2 ^ ((2 * 𝕔 + 6 + 𝕔 / 4) * a ^ 3)

private lemma aux_6_2_3 (s₁ s₂ : ℤ) (x₁ x₂ y y' : X) :
    ‖Ks s₂ x₂ y‖ₑ * ‖Ks s₁ x₁ y - Ks s₁ x₁ y'‖ₑ ≤ C2_1_3 a / volume (ball x₂ (D ^ s₂)) *
    (D2_1_3 a / volume (ball x₁ (D ^ s₁)) * (edist y y' ^ τ / (D ^ s₁) ^ τ)) := by
  sorry

/-- Ineq. (6.2.5) ≤ (6.2.9) from the proof of Lemma 6.2.1. -/
private lemma e625 {s₁ s₂ : ℤ} {x₁ x₂ y y' : X} (hy' : y ≠ y') (hs : s₁ ≤ s₂) :
    (2 * D ^ s₁) ^ τ *
    (‖correlation s₁ s₂ x₁ x₂ y - correlation s₁ s₂ x₁ x₂ y'‖ₑ / edist y y' ^ τ) ≤
    2 ^ ((2 * 𝕔 + 5 + 𝕔 / 4) * a ^ 3) /
    (volume (ball x₁ (D ^ s₁)) * volume (ball x₂ (D ^ s₂))) := by
  sorry

/-- Second part of Lemma 6.2.1 (eq. 6.2.3). -/
lemma correlation_kernel_bound {s₁ s₂ : ℤ} {x₁ x₂ : X} (hs : s₁ ≤ s₂) :
    iHolENorm (correlation s₁ s₂ x₁ x₂) x₁ (2 * D ^ s₁) τ ≤
    C6_2_1 a / (volume (ball x₁ (D ^ s₁)) * volume (ball x₂ (D ^ s₂))) := by
  sorry

variable [TileStructure Q D κ S o]

/-- Lemma 6.2.2. -/
lemma range_support {p : 𝔓 X} {g : X → ℂ} {y : X} (hpy : adjointCarleson p g y ≠ 0) :
    y ∈ ball (𝔠 p) (5 * D ^ 𝔰 p) := by
  sorry -- uses hpos, hle.

/-- The constant from lemma 6.2.3. -/
def C6_2_3 (a : ℕ) : ℝ≥0 := 2 ^ (8 * a)

private lemma ineq_6_2_16 {p : 𝔓 X} {x : X} (hx : x ∈ E p) : dist_(p) (Q x) (𝒬 p) < 1 := by
  sorry

/-- Lemma 6.2.3 (dist version). -/
lemma uncertainty' (ha : 1 ≤ a) {p₁ p₂ : 𝔓 X} (hle : 𝔰 p₁ ≤ 𝔰 p₂)
    (hinter : (ball (𝔠 p₁) (5 * D ^ 𝔰 p₁) ∩ ball (𝔠 p₂) (5 * D ^ 𝔰 p₂)).Nonempty) {x₁ x₂ : X}
    (hx₁ : x₁ ∈ E p₁) (hx₂ : x₂ ∈ E p₂) :
    1 + dist_(p₁) (𝒬 p₁) (𝒬 p₂) ≤ C6_2_3 a * (1 + dist_{x₁, D ^ 𝔰 p₁} (Q x₁) (Q x₂)) := by
  sorry

/-- Lemma 6.2.3 (edist version). -/
lemma uncertainty (ha : 1 ≤ a) {p₁ p₂ : 𝔓 X} (hle : 𝔰 p₁ ≤ 𝔰 p₂)
    (hinter : (ball (𝔠 p₁) (5 * D ^ 𝔰 p₁) ∩ ball (𝔠 p₂) (5 * D ^ 𝔰 p₂)).Nonempty) {x₁ x₂ : X}
    (hx₁ : x₁ ∈ E p₁) (hx₂ : x₂ ∈ E p₂) :
    1 + edist_(p₁) (𝒬 p₁) (𝒬 p₂) ≤ C6_2_3 a * (1 + edist_{x₁, D ^ 𝔰 p₁} (Q x₁) (Q x₂)) := by
  sorry

section lemma_6_1_5

/-- The constant from lemma 6.1.5.
Has value `2 ^ (232 * a ^ 3)` in the blueprint. -/
def C6_1_5 (a : ℕ) : ℝ≥0 := 2 ^ ((2 * 𝕔 + 7 + 𝕔 / 4) * a ^ 3)

lemma C6_1_5_bound (ha : 4 ≤ a) :
    2 ^ ((2 * 𝕔 + 6 + 𝕔 / 4) * a ^ 3 + 1) * 2 ^ (11 * a) ≤ C6_1_5 a := by
  sorry

open GridStructure

set_option backward.isDefEq.respectTransparency false in
lemma complex_exp_lintegral {p : 𝔓 X} {g : X → ℂ} (y : X) :
    conj (∫ y1 in E p, conj (Ks (𝔰 p) y1 y) * exp (I * (Q y1 y1 - Q y1 y)) * g y1) =
    ∫ y1 in E p, Ks (𝔰 p) y1 y * exp (I * (-Q y1 y1 + Q y1 y)) * conj (g y1) := by
  sorry

/-- Definition (6.2.27). -/
def I12 (p p' : 𝔓 X) (g : X → ℂ) (x1 x2 : X) : ℝ≥0∞ :=
  ‖(∫ y, exp (I * (-Q x1 y + Q x2 y)) * correlation (𝔰 p') (𝔰 p) x1 x2 y) * g x1 * g x2‖ₑ

/-- Inequality (6.2.28). -/
lemma I12_le' {p p' : 𝔓 X} (hle : 𝔰 p' ≤ 𝔰 p) {g : X → ℂ} (x1 : E p') (x2 : E p) :
    I12 p p' g x1 x2 ≤
    2 ^ ((2 * 𝕔 + 6 + 𝕔 / 4) * a ^ 3 + 8 * a) *
      ((1 + edist_{x1.1, D ^ 𝔰 p'} (Q x1) (Q x2)) ^ (-(2 * a ^ 2 + a ^ 3 : ℝ)⁻¹)) /
    volume (ball x2.1 (D ^ 𝔰 p)) * ‖g x1‖ₑ * ‖g x2‖ₑ := by
  sorry

private lemma exp_ineq (ha : 4 ≤ a) : 0 < (8 * a : ℕ) * -(2 * a ^ 2 + a ^ 3 : ℝ)⁻¹ + 1 := by
  sorry

/-- Inequality (6.2.29). -/
lemma I12_le (ha : 4 ≤ a) {p p' : 𝔓 X} (hle : 𝔰 p' ≤ 𝔰 p) {g : X → ℂ}
    (hinter : (ball (𝔠 p') (5 * D ^ 𝔰 p') ∩ ball (𝔠 p) (5 * D ^ 𝔰 p)).Nonempty)
    (x1 : E p') (x2 : E p) :
    I12 p p' g x1 x2 ≤
    (2 ^ ((2 * 𝕔 + 6 + 𝕔 / 4) * a ^ 3 + 8 * a + 1) *
      ((1 + edist_(p') (𝒬 p') (𝒬 p)) ^ (-(2 * a ^ 2 + a ^ 3 : ℝ)⁻¹))) /
    volume (ball x2.1 (D ^ 𝔰 p)) * ‖g x1‖ₑ * ‖g x2‖ₑ := by
  sorry

/-- Inequality (6.2.32). -/
lemma volume_coeGrid_le {p : 𝔓 X} (x2 : E p) :
    volume (𝓘 p : Set X) ≤ 2 ^ (3 * a) * volume (ball x2.1 (D ^ 𝔰 p)) := by
  sorry

lemma bound_6_2_29 (ha : 4 ≤ a) {p p' : 𝔓 X} (x2 : E p) :
    2 ^ ((2 * 𝕔 + 6 + 𝕔 / 4) * a ^ 3 + 8 * a + 1) *
    (1 + edist_(p') (𝒬 p') (𝒬 p)) ^ (-(2 * a ^ 2 + a ^ 3 : ℝ)⁻¹) / volume (ball x2.1 (D ^ 𝔰 p)) ≤
    C6_1_5 a *
    (1 + edist_(p') (𝒬 p') (𝒬 p)) ^ (-(2 * a ^ 2 + a ^ 3 : ℝ)⁻¹) / volume (𝓘 p : Set X) := by
  sorry

omit [TileStructure Q D κ S o] in
lemma enorm_eq_zero_of_notMem_closedBall {g : X → ℂ} (hg1 : ∀ x, ‖g x‖ ≤ G.indicator 1 x)
    {x : X} (hx : x ∉ closedBall o (D ^ S / 4)) : ‖g x‖ₑ = 0 := by
  sorry

omit [TileStructure Q D κ S o] in
lemma eq_zero_of_notMem_closedBall {g : X → ℂ} (hg1 : ∀ x, ‖g x‖ ≤ G.indicator 1 x)
    {x : X} (hx : x ∉ closedBall o (D ^ S / 4)) : g x = 0 := by
  sorry

lemma boundedCompactSupport_star_Ks_mul_g {p' : 𝔓 X} {g : X → ℂ}
    (hg : Measurable g) (hg1 : ∀ x, ‖g x‖ ≤ G.indicator 1 x) :
    BoundedCompactSupport fun x : X × X ↦ conj (Ks (𝔰 p') x.1 x.2) * g x.1 := by
  sorry

lemma boundedCompactSupport_Ks_mul_star_g {p : 𝔓 X} {g : X → ℂ}
    (hg : Measurable g) (hg1 : ∀ x, ‖g x‖ ≤ G.indicator 1 x) :
    BoundedCompactSupport fun x : X × X ↦ Ks (𝔰 p) x.1 x.2 * (conj ∘ g) x.1 := by
  sorry

lemma boundedCompactSupport_aux_6_2_26 {p p' : 𝔓 X} {g : X → ℂ}
    (hg : Measurable g) (hg1 : ∀ x, ‖g x‖ ≤ G.indicator 1 x) :
    BoundedCompactSupport fun (x, z1, z2) ↦
      conj (Ks (𝔰 p') z1 x) * exp (I * (Q z1 z1 - Q z1 x)) * g z1 *
      (Ks (𝔰 p) z2 x * exp (I * (-Q z2 z2 + Q z2 x)) * conj (g z2)) := by
  sorry

set_option backward.isDefEq.respectTransparency false in
lemma bound_6_2_26_aux {p p' : 𝔓 X} {g : X → ℂ} :
    let f := fun (x, z1, z2) ↦
      conj (Ks (𝔰 p') z1 x) * exp (I * (Q z1 z1 - Q z1 x)) * g z1 *
      (Ks (𝔰 p) z2 x * exp (I * (-Q z2 z2 + Q z2 x)) * conj (g z2))
    ∫⁻ x in E p' ×ˢ E p, ‖∫ y, f (y, x)‖ₑ = ∫⁻ z in E p' ×ˢ E p, I12 p p' g z.1 z.2 := by
  sorry

set_option backward.isDefEq.respectTransparency false in
lemma bound_6_2_26 {p p' : 𝔓 X} {g : X → ℂ}
    (hg : Measurable g) (hg1 : ∀ x, ‖g x‖ ≤ G.indicator 1 x) :
    ‖∫ y, adjointCarleson p' g y * conj (adjointCarleson p g y)‖ₑ ≤
    ∫⁻ z in E p' ×ˢ E p, I12 p p' g z.1 z.2 := by
  sorry

-- We assume 6.2.23.
lemma correlation_le_of_nonempty_inter (ha : 4 ≤ a) {p p' : 𝔓 X} (hle : 𝔰 p' ≤ 𝔰 p) {g : X → ℂ}
    (hg : Measurable g) (hg1 : ∀ x, ‖g x‖ ≤ G.indicator 1 x)
    (hinter : (ball (𝔠 p') (5 * D ^ 𝔰 p') ∩ ball (𝔠 p) (5 * D ^ 𝔰 p)).Nonempty) :
    ‖∫ y, adjointCarleson p' g y * conj (adjointCarleson p g y)‖ₑ ≤
    C6_1_5 a * (1 + edist_(p') (𝒬 p') (𝒬 p)) ^ (-(2 * a ^ 2 + a ^ 3 : ℝ)⁻¹) /
    volume (𝓘 p : Set X) * (∫⁻ y in E p', ‖g y‖ₑ) * ∫⁻ y in E p, ‖g y‖ₑ := by
  sorry

/-- If (6.2.23) does not hold, the LHS is zero and the result follows trivially. -/
lemma correlation_le_of_empty_inter {p p' : 𝔓 X} {g : X → ℂ}
    (hinter : ¬(ball (𝔠 p') (5 * D ^ 𝔰 p') ∩ ball (𝔠 p) (5 * D ^ 𝔰 p)).Nonempty) :
    ‖∫ y, adjointCarleson p' g y * conj (adjointCarleson p g y)‖ₑ ≤
    C6_1_5 a * (1 + edist_(p') (𝒬 p') (𝒬 p)) ^ (-(2 * a ^ 2 + a ^ 3 : ℝ)⁻¹) /
    volume (𝓘 p : Set X) * (∫⁻ y in E p', ‖g y‖ₑ) * ∫⁻ y in E p, ‖g y‖ₑ := by
  sorry

/-- Part 1 of Lemma 6.1.5 (eq. 6.1.43). -/
lemma correlation_le {p p' : 𝔓 X} (hle : 𝔰 p' ≤ 𝔰 p) {g : X → ℂ}
    (hg : Measurable g) (hg1 : ∀ x, ‖g x‖ ≤ G.indicator 1 x) :
    ‖∫ y, adjointCarleson p' g y * conj (adjointCarleson p g y)‖ₑ ≤
    C6_1_5 a * (1 + edist_(p') (𝒬 p') (𝒬 p)) ^ (-(2 * a ^ 2 + a ^ 3 : ℝ)⁻¹) /
    volume (𝓘 p : Set X) * (∫⁻ y in E p', ‖g y‖ₑ) * ∫⁻ y in E p, ‖g y‖ₑ := by
  sorry

/-- Part 2 of Lemma 6.1.5 (claim 6.1.44). -/
lemma correlation_zero_of_ne_subset {p p' : 𝔓 X} (hle : 𝔰 p' ≤ 𝔰 p) {g : X → ℂ}
    (hp : ¬(𝓘 p' : Set X) ⊆ ball (𝔠 p) (14 * D ^ 𝔰 p)) :
    ‖∫ y, adjointCarleson p' g y * conj (adjointCarleson p g y)‖ₑ = 0 := by
  sorry

end lemma_6_1_5

end Tile
