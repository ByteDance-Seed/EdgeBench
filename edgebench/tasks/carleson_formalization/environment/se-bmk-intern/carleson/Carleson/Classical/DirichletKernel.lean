/- This file contains definitions and lemmas regarding the Dirichlet kernel. -/
module

public import Carleson.Classical.Basic
public import Mathlib.Algebra.Order.BigOperators.Group.LocallyFinite
public import Mathlib.Tactic.Field

@[expose] public section

open scoped Real
open Finset Complex MeasureTheory

noncomputable section

def dirichletKernel (N : ℕ) : ℝ → ℂ :=
  fun x ↦ ∑ n ∈ Icc (-Int.ofNat N) N, fourier n (x : AddCircle (2 * π))

def dirichletKernel' (N : ℕ) : ℝ → ℂ :=
  fun x ↦ (exp (I * N * x) / (1 - exp (-I * x)) + exp (-I * N * x) / (1 - exp (I * x)))

variable {N : ℕ}

@[fun_prop]
lemma continuous_dirichletKernel : Continuous (dirichletKernel N) := by
  sorry

lemma dirichletKernel_periodic : Function.Periodic (dirichletKernel N) (2 * π) := by
  sorry

lemma dirichletKernel'_periodic : Function.Periodic (dirichletKernel' N) (2 * π) := by
  sorry

@[fun_prop, measurability]
lemma dirichletKernel'_measurable : Measurable (dirichletKernel' N) := by
  sorry

/-- Second part of Lemma 11.1.8 (Dirichlet kernel) from the paper. -/
lemma dirichletKernel_eq {x : ℝ} (h : cexp (I * x) ≠ 1) :
    dirichletKernel N x = dirichletKernel' N x := by
  sorry

lemma dirichletKernel'_eq_zero {x : ℝ} (h : cexp (I * x) = 1) : dirichletKernel' N x = 0 := by
  sorry

/- "a.e." version of previous lemma. -/
lemma dirichletKernel_eq_ae : ∀ᵐ (x : ℝ), dirichletKernel N x = dirichletKernel' N x := by
  sorry

lemma norm_dirichletKernel_le {x : ℝ} : ‖dirichletKernel N x‖ ≤ 2 * N + 1 := by
  sorry

lemma norm_dirichletKernel'_le {x : ℝ} : ‖dirichletKernel' N x‖ ≤ 2 * N + 1 := by
  sorry

/-- First part of lemma 11.1.8 (Dirichlet kernel) from the blueprint. -/
lemma partialFourierSum_eq_conv_dirichletKernel {f : ℝ → ℂ} {x : ℝ}
    (h : IntervalIntegrable f volume 0 (2 * π)) :
    partialFourierSum N f x =
      (1 / (2 * π)) * ∫ (y : ℝ) in (0 : ℝ)..(2 * π), f y * dirichletKernel N (x - y) := by
  sorry

lemma partialFourierSum_eq_conv_dirichletKernel' {f : ℝ → ℂ} {x : ℝ}
    (h : IntervalIntegrable f volume 0 (2 * π)) :
    partialFourierSum N f x =
      (1 / (2 * π)) * ∫ (y : ℝ) in (0 : ℝ)..(2 * π), f y * dirichletKernel' N (x - y) := by
  sorry
