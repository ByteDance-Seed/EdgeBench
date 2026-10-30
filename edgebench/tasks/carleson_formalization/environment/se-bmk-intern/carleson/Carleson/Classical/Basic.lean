module

public import Carleson.Classical.Helper
public import Carleson.Defs
public import Carleson.ToMathlib.MeasureTheory.Function.LpSeminorm.TriangleInequality
public import Mathlib.MeasureTheory.Function.LpSpace.ContinuousFunctions
public import Carleson.ToMathlib.Topology.Instances.AddCircle.Defs
public import Mathlib.Analysis.Fourier.AddCircle
public import Mathlib.Tactic.Field

@[expose] public section

/- This file contains basic definitions and lemmas. -/

open Finset Real MeasureTheory AddCircle

noncomputable section

--TODO: I think the measurability assumptions might be unnecessary
theorem fourierCoeff_eq_fourierCoeff_of_aeeq {T : ℝ} [hT : Fact (0 < T)] {n : ℤ} {f g : AddCircle T → ℂ}
    (hf : AEStronglyMeasurable f haarAddCircle) (hg : AEStronglyMeasurable g haarAddCircle)
    (h : f =ᵐ[haarAddCircle] g) : fourierCoeff f n = fourierCoeff g n := by
  sorry

def partialFourierSum' {T : ℝ} [hT : Fact (0 < T)] (N : ℕ) (f : AddCircle T → ℂ) : C(AddCircle T, ℂ) :=
    ∑ n ∈ Finset.Icc (-Int.ofNat N) N, fourierCoeff f n • fourier n

def partialFourierSumLp {T : ℝ} [hT : Fact (0 < T)] (p : ENNReal) [Fact (1 ≤ p)] (N : ℕ) (f : AddCircle T → ℂ) : Lp ℂ p (@haarAddCircle T hT) :=
    ∑ n ∈ Finset.Icc (-Int.ofNat N) N, fourierCoeff f n • fourierLp p n

lemma partialFourierSum_eq_partialFourierSum' [hT : Fact (0 < 2 * Real.pi)] (N : ℕ) (f : ℝ → ℂ) :
    liftIoc (2 * Real.pi) 0 (partialFourierSum N f) = partialFourierSum' N (liftIoc (2 * Real.pi) 0 f) := by
  sorry

lemma partialFourierSupLp_eq_partialFourierSupLp_of_aeeq {T : ℝ} [hT : Fact (0 < T)] {p : ENNReal} [Fact (1 ≤ p)] {N : ℕ} {f g : AddCircle T → ℂ}
    (hf : AEStronglyMeasurable f haarAddCircle) (hg : AEStronglyMeasurable g haarAddCircle)
    (h : f =ᶠ[ae haarAddCircle] g) : partialFourierSumLp p N f = partialFourierSumLp p N g := by
  sorry

lemma partialFourierSum'_eq_partialFourierSumLp {T : ℝ} [hT : Fact (0 < T)] (p : ENNReal) [Fact (1 ≤ p)] (N : ℕ) (f : AddCircle T → ℂ) :
    partialFourierSumLp p N f = MemLp.toLp (partialFourierSum' N f) ((partialFourierSum' N f).memLp haarAddCircle ℂ)  := by
  sorry

lemma partialFourierSum_aeeq_partialFourierSumLp [hT : Fact (0 < 2 * Real.pi)] (p : ENNReal) [Fact (1 ≤ p)] (N : ℕ) (f : ℝ → ℂ) (h_mem_Lp : MemLp (liftIoc (2 * Real.pi) 0 f) 2 haarAddCircle) :
    liftIoc (2 * Real.pi) 0 (partialFourierSum N f) =ᶠ[ae haarAddCircle] ↑↑(partialFourierSumLp p N (MemLp.toLp (liftIoc (2 * Real.pi) 0 f) h_mem_Lp)) := by
  sorry

local notation "S_" => partialFourierSum

@[simp]
lemma fourierCoeffOn_mul {a b : ℝ} {hab : a < b} {f : ℝ → ℂ} {c : ℂ} {n : ℤ} :
    fourierCoeffOn hab (fun x ↦ c * f x) n = c * (fourierCoeffOn hab f n) := by
  sorry

@[simp]
lemma fourierCoeffOn_neg {a b : ℝ} {hab : a < b} {f : ℝ → ℂ} {n : ℤ} :
    fourierCoeffOn hab (-f) n = - (fourierCoeffOn hab f n):= by
  sorry

@[simp]
lemma fourierCoeffOn_add {a b : ℝ} {hab : a < b} {f g : ℝ → ℂ} {n : ℤ}
    (hf : IntervalIntegrable f MeasureTheory.volume a b)
    (hg : IntervalIntegrable g MeasureTheory.volume a b) :
    fourierCoeffOn hab (f + g) n = fourierCoeffOn hab f n + fourierCoeffOn hab g n:= by
  sorry

@[simp]
lemma fourierCoeffOn_sub {a b : ℝ} {hab : a < b} {f g : ℝ → ℂ} {n : ℤ}
    (hf : IntervalIntegrable f MeasureTheory.volume a b)
    (hg : IntervalIntegrable g MeasureTheory.volume a b) :
    fourierCoeffOn hab (f - g) n = fourierCoeffOn hab f n - fourierCoeffOn hab g n:= by
  sorry

@[simp]
lemma partialFourierSum_add {f g : ℝ → ℂ} {N : ℕ}
    (hf : IntervalIntegrable f MeasureTheory.volume 0 (2 * π))
    (hg : IntervalIntegrable g MeasureTheory.volume 0 (2 * π)) :
  S_ N (f + g) = S_ N f + S_ N g := by
  sorry

@[simp]
lemma partialFourierSum_sub {f g : ℝ → ℂ} {N : ℕ}
    (hf : IntervalIntegrable f MeasureTheory.volume 0 (2 * π))
    (hg : IntervalIntegrable g MeasureTheory.volume 0 (2 * π)) :
    S_ N (f - g) = S_ N f - S_ N g := by
  sorry

@[simp]
lemma partialFourierSum_mul {f : ℝ → ℂ} {a : ℂ} {N : ℕ} :
  S_ N (fun x ↦ a * f x) = fun x ↦ a * S_ N f x := by
  sorry

lemma fourier_periodic {n : ℤ} :
    (fun (x : ℝ) ↦ fourier n (x : AddCircle (2 * π))).Periodic (2 * π) := by
  sorry

lemma partialFourierSum_periodic {f : ℝ → ℂ} {N : ℕ} : (S_ N f).Periodic (2 * π) := by
  sorry

--TODO: maybe generalize to (hc : ContinuousOn f (Set.Icc 0 T)) and leave out condition (hT : 0 < T)
lemma Function.Periodic.uniformContinuous_of_continuous {f : ℝ → ℂ} {T : ℝ} (hT : 0 < T)
    (hp : Function.Periodic f T) (hc : ContinuousOn f (Set.Icc (-T) (2 * T))) :
    UniformContinuous f := by
  sorry

lemma fourier_uniformContinuous {n : ℤ} :
    UniformContinuous (fun (x : ℝ) ↦ fourier n (x : AddCircle (2 * π))) := by
  sorry

lemma partialFourierSum_uniformContinuous {f : ℝ → ℂ} {N : ℕ} : UniformContinuous (S_ N f) := by
  sorry

theorem strictConvexOn_cos_Icc : StrictConvexOn ℝ (Set.Icc (π / 2) (π + π / 2)) Real.cos := by
  sorry

lemma lower_secant_bound_aux {η : ℝ} (ηpos : 0 < η) {x : ℝ} (le_abs_x : η ≤ x)
    (abs_x_le : x ≤ 2 * π - η) (x_le_pi : x ≤ π) (h : π / 2 < x) :
    2 / π * η ≤ ‖1 - Complex.exp (Complex.I * ↑x)‖ := by
  sorry

lemma lower_secant_bound' {η : ℝ} {x : ℝ} (le_abs_x : η ≤ |x|) (abs_x_le : |x| ≤ 2 * π - η) :
    (2 / π) * η ≤ ‖1 - Complex.exp (Complex.I * x)‖ := by
  sorry

/- Slightly weaker version of Lemma 11..1.9 (lower secant bound) with simplified constant. -/
lemma lower_secant_bound {η : ℝ} {x : ℝ} (xIcc : x ∈ Set.Icc (-2 * π + η) (2 * π - η)) (xAbs : η ≤ |x|) :
    η / 2 ≤ ‖(1 - Complex.exp (Complex.I * x))‖ := by
  sorry
