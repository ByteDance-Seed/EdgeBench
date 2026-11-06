module

public import Mathlib.Analysis.SpecialFunctions.Gamma.Basic
-- Upstreaming status: upstreamed in
-- https://github.com/leanprover-community/mathlib4/pull/37597
public import Mathlib.Analysis.SumIntegralComparisons

public section

open scoped Nat
open Real MeasureTheory

lemma intervalIntegral_pow_mul_exp_neg_le {k : ℕ} {M c : ℝ} (hM : 0 ≤ M) (hc : 0 < c) :
    ∫ x in (0 : ℝ)..M, x ^ k * rexp (- (c * x)) ≤ k ! / c ^ (k + 1) := by
  sorry

lemma sum_Ico_pow_mul_exp_neg_le {k : ℕ} {M : ℕ} {c : ℝ} (hc : 0 < c) :
    ∑ i ∈ Finset.Ico 0 M, i ^ k * rexp (- (c * i)) ≤ rexp c * k ! / c ^ (k + 1) := by
  sorry

lemma sum_Iic_pow_mul_exp_neg_le {k : ℕ} {M : ℕ} {c : ℝ} (hc : 0 < c) :
    ∑ i ∈ Finset.Iic M, i ^ k * rexp (- (c * i)) ≤ rexp c * k ! / c ^ (k + 1) := by
  sorry

lemma sum_Iic_pow_mul_two_pow_neg_le {k : ℕ} {M : ℕ} {c : ℝ} (hc : 0 < c) :
    ∑ i ∈ Finset.Iic M, i ^ k * (2 : ℝ) ^ (- (c * i))
      ≤ 2 ^ c * k ! / (Real.log 2 * c) ^ (k + 1) := by
  sorry
