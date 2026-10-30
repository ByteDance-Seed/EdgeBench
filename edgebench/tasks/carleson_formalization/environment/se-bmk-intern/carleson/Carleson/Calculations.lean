/-
This is a file for arithmetical lemmas -
lemmas that don't depend on any of Carleson's project definitions, or, really,
on any fancy definitions period.

Roughly speaking, if a lemma is in this file, it should be purely calculational/arithmetical,
e.g. `lemma calculation_1 : 2 + 2 = 4`.
All lemmas are prepended with a prefix `calculation_`.
-/
module

public import Carleson.ProofData
public import Mathlib.Tactic.Rify

public section

open ShortVariables
open scoped NNReal ENNReal
variable {X : Type*} {a : ℕ} {q : ℝ} {K : X → X → ℂ} {σ₁ σ₂ : X → ℤ} {F G : Set X}

lemma sixteen_times_le_cube (ha : 4 ≤ a) : 16 * a ≤ a ^ 3 := by
  sorry

lemma four_times_sq_le_cube (ha : 4 ≤ a) : 4 * a ^ 2 ≤ a ^ 3 := by
  sorry

lemma add_le_pow_two {R : Type*} [Semiring R] [PartialOrder R] [IsOrderedRing R]
    {p q r s : ℕ} (hp : p ≤ r) (hq : q ≤ r) (hr : r + 1 ≤ s) :
    (2 : R) ^ p + 2 ^ q ≤ 2 ^ s := by
  sorry

lemma add_le_pow_two₃ {R : Type*} [Semiring R] [PartialOrder R] [IsOrderedRing R]
    {p q r s t : ℕ} (hp : p ≤ s) (hq : q ≤ s) (hr : r ≤ s + 1) (ht : s + 2 ≤ t) :
    (2 : R) ^ p + 2 ^ q + 2 ^ r ≤ 2 ^ t := by
  sorry

lemma add_le_pow_two_add_cube {R : Type*} [Semiring R] [PartialOrder R] [IsOrderedRing R]
    {p q r : ℕ} (ha : 4 ≤ a) (hp : p ≤ r) (hq : q ≤ r) :
    (2 : R) ^ p + 2 ^ q ≤ 2 ^ (r + a ^ 3) := by
  sorry

lemma calculation_1 (s : ℤ) :
    4 * (D : ℝ) ^ (-2 : ℝ) * D ^ (s + 3) = 4 * D ^ (s + 1) := by
  sorry

lemma calculation_2 (s : ℤ) :
    ((8 : ℝ)⁻¹ * D ^ (- 3 : ℝ)) * D ^ (s + 3) = 8⁻¹ * D ^ s := by
  sorry

lemma calculation_10 (h : (100 : ℝ) < D) :
    ((100 : ℝ) + 4 * D ^ (-2 : ℝ) + 8⁻¹ * D ^ (-3 : ℝ)) * D ^ (-1 : ℝ) < 2 := by
  sorry

lemma calculation_3 [PseudoMetricSpace X] [ProofData a q K σ₁ σ₂ F G] {x y : ℤ} (h : x + 3 < y) :
    100 * D ^ (x + 3) + ((4 * D ^ (-2 : ℝ)) * D ^ (x + 3)) + (((8 : ℝ)⁻¹ * D ^ (-3 : ℝ)) * D ^ (x + 3)) + 8 * D ^ y < 10 * D ^ y := by
  sorry

lemma calculation_4 [PseudoMetricSpace X] [ProofData a q K σ₁ σ₂ F G]
    {s_1 s_2 s_3 : ℤ} {dist_a dist_b dist_c dist_d : ℝ}
    (lt_1 : dist_a < 100 * D ^ (s_1 + 3))
    (lt_2 : dist_b < 8 * D ^ s_3)
    (lt_3 : dist_c < 8⁻¹ * D ^ s_1)
    (lt_4 : dist_d < 4 * D ^ s_2)
    (three : s_1 + 3 < s_3) (plusOne : s_2 = s_1 + 1) :
    dist_a + dist_d + dist_c + dist_b < 10 * D ^ s_3 := by
  sorry

lemma calculation_logD_64 [PseudoMetricSpace X] [ProofData a q K σ₁ σ₂ F G] :
    Real.logb D 64 < 1 := by
  sorry

lemma calculation_5 {dist_1 dist_2 : ℝ}
    (h : dist_1 ≤ (2 ^ (a : ℝ)) ^ (6 : ℝ) * dist_2) :
    2 ^ ((-𝕔 : ℝ) * a) * dist_1 ≤ 2 ^ ((-(𝕔 - 6) : ℝ) * a) * dist_2 := by
  sorry

lemma calculation_6 (a : ℕ) (s : ℤ) :
    (D : ℝ) ^ (s + 3) = (D : ℝ) ^ (s + 2) * (D : ℝ) := by
  sorry

lemma calculation_7 (a : ℕ) (s : ℤ) :
    100 * (D ^ (s + 2) * D) = (defaultA a) ^ (𝕔 * a) * (100 * (D : ℝ) ^ (s + 2)) := by
  sorry

lemma calculation_8 {dist_1 dist_2 : ℝ}
    (h : dist_1 * 2 ^ ((𝕔 : ℝ) * a) ≤ dist_2) :
    dist_1 ≤ 2 ^ ((-𝕔 : ℝ) * a) * dist_2 := by
  sorry

lemma calculation_9 [PseudoMetricSpace X] [ProofData a q K σ₁ σ₂ F G]
    (h : 1 ≤ (2 : ℝ) ^ (-((𝕔 - 6) : ℝ) * a)) :
    False := by
  sorry

lemma calculation_11 [PseudoMetricSpace X] [ProofData a q K σ₁ σ₂ F G] (s : ℤ) :
    100 * (D : ℝ) ^ (s + 2) + 4 * D ^ (s + 1) < 128 * D^(s + 2) := by
  sorry

lemma calculation_12 (s : ℝ) :
    128 * (D : ℝ)^(s + 2) = 2^(2 * 𝕔 * a ^ 2 + 4) * (8 * D ^ s) := by
  sorry

lemma calculation_13 : (2 : ℝ) ^ (2 * 𝕔 * a ^ 3 + 4 * a) = (defaultA a) ^ (2 * 𝕔 * a ^ 2 + 4) := by
  sorry

lemma calculation_14 [PseudoMetricSpace X] [ProofData a q K σ₁ σ₂ F G] (n : ℕ) :
    (2 : ℝ) ^ ((Z : ℝ) * n / 2 - (2 * 𝕔 + 1) * a ^ 3) ≤
      2 ^ ((Z : ℝ) * n / 2 - (2 * 𝕔 * a ^ 3 + 4 * a)) := by
  sorry

lemma calculation_15 {dist zon : ℝ}
    (h : 2 ^ zon ≤ 2 ^ (2 * 𝕔 * a ^ 3 + 4 * a) * dist) :
    2 ^ (zon - (2 * 𝕔 * a^3 + 4*a)) ≤ dist := by
  sorry

lemma calculation_16 [PseudoMetricSpace X] [ProofData a q K σ₁ σ₂ F G] (s : ℤ) :
    4 * (D : ℝ) ^ s < 100 * D ^ (s + 1) := by
  sorry

lemma calculation_7_7_4 [PseudoMetricSpace X] [ProofData a q K σ₁ σ₂ F G] {n : ℕ} :
  (1:ℝ) ≤ 2 ^ (Z * (n + 1)) - 4 := by
  sorry

/-- A bound on the sum of a geometric series whose ratio is close to 1. -/
lemma near_1_geometric_bound {t : ℝ} (ht : t ∈ Set.Icc 0 1) :
    (1 - 2 ^ (-t))⁻¹ ≤ 2 * (ENNReal.ofReal t)⁻¹ := by
  sorry

lemma calculation_convexity_bound [PseudoMetricSpace X] [ProofData a q K σ₁ σ₂ F G]
    {n : ℕ} {t : ℝ} (ht : t ∈ Set.Icc 0 1) :
    ∑ k ∈ Finset.range n, ((D : ENNReal) ^ (-t)) ^ k ≤ 2 * (ENNReal.ofReal t)⁻¹ := by
  sorry

lemma calculation_7_6_2 [PseudoMetricSpace X] [ProofData a q K σ₁ σ₂ F G] {n : ℕ} :
    ∑ k ∈ Finset.range n, ((D : ENNReal) ^ (-(κ / 2))) ^ k ≤ 2 ^ (10 * a + 2) := by
  sorry

lemma calculation_150 [PseudoMetricSpace X] [ProofData a q K σ₁ σ₂ F G] :
    𝕔 * (3/2) * a ^ 2 * κ ≤ 1 := by
  sorry

lemma sq_le_two_pow_of_four_le (a4 : 4 ≤ a) : a ^ 2 ≤ 2 ^ a := by
  sorry

lemma calculation_6_1_6 (a4 : 4 ≤ a) : 8 * a ^ 4 ≤ 2 ^ (2 * a + 3) := by
  sorry
