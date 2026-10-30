module

public import Carleson.Classical.Basic
public import Mathlib.Analysis.Real.Pi.Bounds

@[expose] public section

/- This file contains definitions and lemmas regarding the Hilbert kernel. -/

noncomputable section

open scoped Real Interval
open Complex ComplexConjugate MeasureTheory

def k (x : ℝ) : ℂ := max (1 - |x|) 0 / (1 - exp (I * x))

/- Basic properties of k. -/

lemma k_of_neg_eq_conj_k {x : ℝ} : k (-x) = conj (k x) := by
  sorry

lemma k_of_abs_le_one {x : ℝ} (abs_le_one : |x| ≤ 1) : k x = (1 - |x|) / (1 - exp (I * x)) := by
  sorry

lemma k_of_one_le_abs {x : ℝ} (abs_le_one : 1 ≤ |x|) : k x = 0 := by
  sorry

@[fun_prop]
lemma k_measurable : Measurable k := by
  sorry

def K : ℝ → ℝ → ℂ := fun x y ↦ k (x - y)

lemma K_def : K = fun x y ↦ k (x - y) := by
  sorry

lemma Hilbert_kernel_conj_symm {x y : ℝ} : K y x = conj (K x y) := by
  sorry

@[fun_prop]
lemma Hilbert_kernel_measurable : Measurable (Function.uncurry K) := by
  sorry

/- Lemma 11.1.11 (Hilbert kernel bound) -/
lemma Hilbert_kernel_bound {x y : ℝ} : ‖K x y‖ ≤ 2 ^ (2 : ℝ) / (2 * |x - y|) := by
  sorry

/-Main part of the proof of Hilbert_kernel_regularity -/
/-TODO: This can be local, i.e. invisible to other files. -/
lemma Hilbert_kernel_regularity_main_part {y y' : ℝ} (yy'nonneg : 0 ≤ y ∧ 0 ≤ y') (ypos : 0 < y)
    (y2ley' : y / 2 ≤ y') (hy : y ≤ 1) (hy' : y' ≤ 1) :
    ‖k (-y) - k (-y')‖ ≤ 2 ^ 6 * (1 / |y|) * (|y - y'| / |y|) := by
  sorry

/- Lemma 11.1.12 (Hilbert kernel regularity) -/
lemma Hilbert_kernel_regularity {x y y' : ℝ} :
    2 * |y - y'| ≤ |x - y| → ‖K x y - K x y'‖ ≤ 2 ^ 8 * (1 / |x - y|) * (|y - y'| / |x - y|)  := by
  sorry
