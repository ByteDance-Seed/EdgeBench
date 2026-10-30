module

public import Carleson.Classical.DirichletKernel
public import Carleson.Classical.HilbertKernel
public import Carleson.Classical.SpectralProjectionBound
public import Carleson.Defs
public import Carleson.ToMathlib.MeasureTheory.Integral.MeanInequalities
public import Carleson.TwoSidedCarleson.Basic
public import Mathlib.Algebra.BigOperators.Group.Finset.Indicator
public import Mathlib.Analysis.Real.Pi.Bounds
public import Mathlib.Tactic.Field
import Mathlib.Algebra.Order.Interval.Set.Group

@[expose] public section

/- This file contains the proof that the Hilbert kernel is a bounded operator. -/

noncomputable section

open scoped Real ENNReal
open Complex ComplexConjugate MeasureTheory Bornology Set Filter Function

section

/-- The volume measure on the real line is doubling. -/
@[reducible]
def doublingMeasure_real_two : DoublingMeasure ℝ 2 :=
  InnerProductSpace.DoublingMeasure.mono (by simp)

instance doublingMeasure_real_16 : DoublingMeasure ℝ (2 ^ 4 : ℕ) :=
  doublingMeasure_real_two.mono (by norm_num)
end

lemma czOperator_comp_add {g : ℝ → ℂ} {k : ℝ → ℂ} {r a : ℝ} :
    (czOperator (fun x y ↦ k (x - y)) r g) ∘ (fun x ↦ x + a) =
    czOperator (fun x y ↦ k (x - y)) r (g ∘ (fun x ↦ x + a)) := by
  sorry

/-- The modulation operator `M_n g`, defined in (11.3.1) -/
def modulationOperator (n : ℤ) (g : ℝ → ℂ) (x : ℝ) : ℂ :=
  g x * exp (I * n * x)

lemma Measurable.modulationOperator (n : ℤ) {g : ℝ → ℂ} (hg : Measurable g) :
    Measurable (modulationOperator n g) := by
  sorry

lemma AEMeasurable.modulationOperator (n : ℤ) {g : ℝ → ℂ} (hg : AEMeasurable g) :
    AEMeasurable (modulationOperator n g) := by
  sorry

/-- The approximate Hilbert transform `L_N g`, defined in (11.3.2).
defined slightly differently. -/
def approxHilbertTransform (n : ℕ) (g : ℝ → ℂ) (x : ℝ) : ℂ :=
  (n : ℂ)⁻¹ * ∑ k ∈ .Ico n (2 * n),
    modulationOperator (k) (partialFourierSum k (modulationOperator (-k) g)) x

/-- The kernel `k_r(x)` defined in (11.3.11).
When used, we may assume that `r ∈ Ioo 0 1`.
Todo: find better name? -/
def niceKernel (r : ℝ) (x : ℝ) : ℝ :=
  if exp (I * x) = 1 then r⁻¹ else
    min r⁻¹ (1 + r / normSq (1 - exp (.I * x)))

lemma niceKernel_pos {r x : ℝ} (hr : 0 < r) : 0 < niceKernel r x := by
  sorry

lemma niceKernel_le_inv {r x : ℝ} : niceKernel r x ≤ r⁻¹ := by
  sorry

lemma one_le_niceKernel {r x : ℝ} (hr : 0 < r) (h'r : r < 1) : 1 ≤ niceKernel r x := by
  sorry

lemma niceKernel_neg {r x : ℝ} : niceKernel r (-x) = niceKernel r x := by
  sorry

lemma niceKernel_periodic (r : ℝ) : Function.Periodic (niceKernel r) (2 * π) := by
  sorry

@[fun_prop] lemma measurable_niceKernel {r : ℝ} : Measurable (niceKernel r) := by
  sorry

lemma niceKernel_intervalIntegrable {r : ℝ} (a b : ℝ) (hr : r > 0) :
    IntervalIntegrable (niceKernel r) volume a b := by
  sorry

lemma niceKernel_eq_inv {r x : ℝ} (hr : 0 < r ∧ r < π) (hx : 0 ≤ x ∧ x ≤ r) :
    niceKernel r x = r⁻¹ := by
  sorry

lemma niceKernel_eq_inv' {r x : ℝ} (hr : 0 < r ∧ r < π) (hx : |x| ≤ r) :
    niceKernel r x = r⁻¹ := by
  sorry

lemma niceKernel_upperBound_aux {r x : ℝ} (hr : 0 < r) (hx : r ≤ x ∧ x ≤ π) :
    1 + r / ‖1 - exp (I * x)‖ ^ 2 ≤ 1 + 4 * r / x ^ 2 := by
  sorry

lemma niceKernel_upperBound {r x : ℝ} (hr : 0 < r) (hx : r ≤ x ∧ x ≤ π) :
    niceKernel r x ≤ 1 + 4 * r / x ^ 2 := by
  sorry

lemma niceKernel_lowerBound {r x : ℝ} (hr : 0 < r) (h'r : r < 1) (hx : r ≤ x ∧ x ≤ π) :
    1 + r / ‖1 - exp (I * x)‖ ^ 2 ≤ 5 * niceKernel r x := by
  sorry

lemma niceKernel_lowerBound' {r x : ℝ} (hr : 0 < r) (h'r : r < 1) (hx : r ≤ |x| ∧ |x| ≤ π) :
    1 + r / ‖1 - exp (I * x)‖ ^ 2 ≤ 5 * niceKernel r x := by
  sorry

/-- Lemma 11.1.8 -/
lemma mean_zero_oscillation {n : ℤ} (hn : n ≠ 0) :
    ∫ x in (0)..2 * π, exp (I * n * x) = 0 := by
  sorry

theorem AddCircle.haarAddCircle_eq_smul_volume {T : ℝ} [hT : Fact (0 < T)] :
    (@haarAddCircle T _) = (ENNReal.ofReal T)⁻¹ • (volume : Measure (AddCircle T)) := by
  sorry

open AddCircle in
/-- Lemma 11.1.10.
-/
-- todo: add lemma that relates `eLpNorm ((Ioc a b).indicator f)` to `∫ x in a..b, _`
lemma spectral_projection_bound {f : ℝ → ℂ} {n : ℕ} (hmf : AEMeasurable f) :
    eLpNorm ((Ioc 0 (2 * π)).indicator (partialFourierSum n f)) 2 ≤
    eLpNorm ((Ioc 0 (2 * π)).indicator f) 2 := by
  sorry

private lemma norm_modulationOperator (g : ℝ → ℂ) (n : ℤ) (x : ℝ) :
    ‖modulationOperator n g x‖ = ‖g x‖ := by
  sorry

private lemma indicator_modulationOperator (g : ℝ → ℂ) (n : ℤ) (s : Set ℝ) :
    s.indicator (modulationOperator n g) = modulationOperator n (s.indicator g) := by
  sorry

private lemma eLpNorm_modulationOperator (g : ℝ → ℂ) (n : ℤ) (p : ℝ≥0∞) :
    eLpNorm (modulationOperator n g) p = eLpNorm g p := by
  sorry

private lemma eLpNorm_indicator_modulationOperator (g : ℝ → ℂ) (n : ℤ) (p : ℝ≥0∞) (s : Set ℝ) :
    eLpNorm (s.indicator (modulationOperator n g)) p = eLpNorm (s.indicator g) p := by
  sorry

/-- Lemma 11.3.1.
-/
lemma modulated_averaged_projection {g : ℝ → ℂ} {n : ℕ} (hmg : AEMeasurable g) :
    eLpNorm ((Ioc 0 (2 * π)).indicator (approxHilbertTransform n g)) 2 ≤
    eLpNorm ((Ioc 0 (2 * π)).indicator g) 2 := by
  sorry

lemma modulated_averaged_projection' {g : ℝ → ℂ} {n : ℕ} (hmg : AEMeasurable g) :
    eLpNorm (approxHilbertTransform n g) 2 (volume.restrict (Ioc 0 (2 * π))) ≤
    eLpNorm g 2 (volume.restrict (Ioc 0 (2 * π))) := by
  sorry

/- Lemma 11.3.2 `periodic-domain-shift` is in Mathlib. -/

/-- Lemma 11.3.3.
-/
lemma young_convolution {f g : ℝ → ℝ} (hmf : AEMeasurable f)
    (hmg : AEMeasurable g) (periodic_g : g.Periodic (2 * π)) :
    eLpNorm (fun x ↦ ∫ y in (0)..2 * π, f y * g (x - y)) 2 (volume.restrict (Ioc 0 (2 * π))) ≤
      eLpNorm f 2 (volume.restrict (Ioc 0 (2 * π)))
      * eLpNorm g 1 (volume.restrict (Ioc 0 (2 * π))) := by
  sorry

/-- Lemma 11.3.4.
-/
lemma integrable_bump_convolution {f g : ℝ → ℝ}
    (hf : MemLp f ∞ volume) (hg : MemLp g ∞ volume) (periodic_g : g.Periodic (2 * π))
    {r : ℝ} (hr : r ∈ Ioo 0 π) (hle : ∀ x, |g x| ≤ niceKernel r x) :
    eLpNorm (fun x ↦ ∫ y in (0)..2 * π, f y * g (x - y)) 2 (volume.restrict (Ioc 0 (2 * π))) ≤
    17 * eLpNorm f 2 (volume.restrict (Ioc 0 (2 * π))) := by
  sorry

/-- The function `L'`, defined in the Proof of Lemma 11.3.5. -/
def dirichletApprox (n : ℕ) (x : ℝ) : ℂ :=
  (n : ℂ)⁻¹ * ∑ k ∈ .Ico n (2 * n), dirichletKernel k x * exp (I * k * x)

/-- Lemma 11.3.5, part 1. -/
@[fun_prop] lemma continuous_dirichletApprox {n : ℕ} : Continuous (dirichletApprox n) := by
  sorry

lemma norm_dirichletApprox_le {n : ℕ} {x : ℝ} :
    ‖dirichletApprox n x‖ ≤ 4 * n := by
  sorry

/-- Lemma 11.3.5, part 2. -/
lemma periodic_dirichletApprox (n : ℕ) : (dirichletApprox n).Periodic (2 * π) := by
  sorry

/-- Lemma 11.3.5, part 3.
-/
lemma approxHilbertTransform_eq_dirichletApprox {f : ℝ → ℂ} (hf : MemLp f ∞ volume)
    {n : ℕ} {x : ℝ} :
    approxHilbertTransform n f x =
      (2 * π)⁻¹ * ∫ y in (0)..2 * π, f y * dirichletApprox n (x - y) := by
  sorry

/-- The convolution with `dirichletApprox` is controlled on `(0, 2π]` in `L^2` norm. This
follows from the fact that it coincides (up to a constant) with `approxHilbertTransform`,
which is essentially an average of Fourier projections (which are all contractions in `L^2`). -/
lemma eLpNorm_convolution_dirichletApprox {g : ℝ → ℂ} {n : ℕ} (hg : MemLp g ∞ volume) :
    eLpNorm (fun x ↦ ∫ y in (0)..2 * π, g y * dirichletApprox n (x - y))
      2 (volume.restrict (Ioc 0 (2 * π))) ≤
    7 * eLpNorm g 2 (volume.restrict (Ioc 0 (2 * π))) := by
  sorry

/- To proceed, we will rewrite `dirichletApprox` as the sum of two terms: one is the kernel
of the Hilbert transform, and the other one will be uniformly bounded in `L^1` (and therefore
its action on `L^2` will be uniformly bounded). It will follow that the Hilberr transform
is bounded on `L^2 ((0, 2π]))`, from which the boundedness on the whole real line will follow.

The second term in the decomposition of `dirichletApprox` is built in terms of an auxiliary
kernel `dirichletApproxAux`.
-/

/-- The function `L''`, defined in the Proof of Lemma 11.3.5. -/
def dirichletApproxAux (n : ℕ) (x : ℝ) : ℂ :=
  (n : ℂ)⁻¹ * exp (I * 2 * n * x) / (1 - exp (-I * x)) * ∑ k ∈ .Ico 0 n, exp (I * 2 * k * x)

lemma dirichletApprox_eq_add_dirichletApproxAux
    {n : ℕ} {x : ℝ} (hx : exp (I * x) ≠ 1) (hn : n ≠ 0) :
    dirichletApprox n x = (1 - exp (I * x)) ⁻¹ + dirichletApproxAux n x := by
  sorry

lemma norm_dirichletApproxAux_le_of_re_nonneg {n : ℕ} {x r : ℝ} (hx : exp (I * x) ≠ 1)
    (h'x : 0 ≤ re (exp (I * x))) (hn : r⁻¹ ≤ n) (hr : 0 < r) :
    ‖dirichletApproxAux n x‖ ≤ 2 * (1 + r / ‖1 - exp (I * x)‖ ^ 2) := by
  sorry

lemma norm_dirichletApproxAux_le_of_re_nonpos {n : ℕ} {x r : ℝ}
    (h'x : re (exp (I * x)) ≤ 0) (hr : 0 < r) :
    ‖dirichletApproxAux n x‖ ≤ 2 * (1 + r / ‖1 - exp (I * x)‖ ^ 2) := by
  sorry

lemma norm_dirichletApproxAux_le {n : ℕ} {x r : ℝ} (hx : exp (I * x) ≠ 1)
    (hxr : r ≤ |x|) (hxpi : |x| ≤ π)
    (hn : r⁻¹ ≤ n) (hr : 0 < r) (h'r : r < 1) :
    ‖dirichletApproxAux n x‖ ≤ 10 * niceKernel r x := by
  sorry

lemma norm_sub_indicator_k {x r : ℝ} (hxr : r ≤ |x|) (hxpi : |x| ≤ π) (hr : 0 < r) (h'r : r < 1) :
    ‖(1 - exp (I * x))⁻¹ - {y | |y| ∈ Ico r 1}.indicator k x‖ ≤ 2 * niceKernel r x := by
  sorry

/-- Lemma 11.3.5, part 4.

The kernel `dirichletApprox` approximates well the kernel of the Hilbert transform, on `[-π, π]`,
up to an error which is uniformly bounded in `L^1` (as it is bounded by a constant multiple
of `niceKernel`).
-/
lemma dist_dirichletApprox_le
    {r : ℝ} (hr : r ∈ Ioo 0 1) {n : ℕ} (hn : n = ⌈r⁻¹⌉₊) {x : ℝ} (hx : x ∈ Icc (-π) π) :
    dist (dirichletApprox n x) ({y : ℝ | |y| ∈ Ico r 1}.indicator k x) ≤ 12 * niceKernel r x := by
  sorry

/-- As the kernel of the Hilbert transform is well approximated by `dirichletApprox`, up to an
error controlled by `12 * niceKernel r`, we may bound `czOperator K` in terms of these. As the
approximation only works in the interval `[-π, π]`, this statement is only true for a
point `x` in `[2, 3]` and a function supported in `[1, 4]`, as this means all values of the
approximation that will show up will be in `[-2, 2] ⊆ [-π, π]`. -/
lemma norm_czOperator_le_add
    {g : ℝ → ℂ} {r x : ℝ} (hr : r ∈ Ioo 0 1) {n : ℕ} (hn : n = ⌈r⁻¹⌉₊)
    (hg : MemLp g ∞ volume)
    (hx : 2 ≤ x) (h'x : x ≤ 3)
    (h'g : support g ⊆ Icc 1 4) :
    ‖czOperator K r g x‖ ≤ ‖∫ y in (0)..(2 * π), g y * dirichletApprox n (x - y)‖
      + 12 * ∫ y in Ioc 0 (2 * π), ‖g y‖ * niceKernel r (x - y) := by
  sorry

/-- The operator `czOperator K r` is bounded from `L^2 ([1, 4])` to `L^2 ([2, 3])`,
uniformly in `r`. This follows from the fact, proved in `norm_czOperator_le_add`, that it is
bounded by the sum of two operators which are both bounded: one is the convolution
with `dirichletApprox`, bounded as it is an average of Fourier projections, and the other one has
a kernel uniformly bounded in `L^1` and is therefore controlled by Young inequality.

In this version, we assume that the function is supported in `[1, 4]`, but we will drop this
assumption just after this lemma, in `eLpNorm_czOperator_restrict_two_three`.
-/
lemma eLpNorm_czOperator_restrict_two_three_of_support_subset {g : ℝ → ℂ} {r : ℝ}
    (hr : r ∈ Ioo 0 1) (hg : MemLp g ∞ volume) (h'g : support g ⊆ Icc 1 4) :
    eLpNorm (czOperator K r g) 2 (volume.restrict (Ioc 2 3)) ≤
      2 ^ 8 * eLpNorm g 2 (volume.restrict (Ioc 1 4)) := by
  sorry

/-- The operator `czOperator K r` is bounded from `L^2 [1, 4]` to `L^2 [2, 3]`,
uniformly in `r`. This follows from the fact, proved in `norm_czOperator_le_add`, that it is
bounded by the sum of two operators which are both bounded: one is the convolution
with `dirichletApprox`, bounded as it is an average of Fourier projections, and the other one has
a kernel uniformly bounded in `L^1` and is therefore controlled by Young inequality. -/
lemma eLpNorm_czOperator_restrict_two_three {g : ℝ → ℂ} {r : ℝ} (hr : r ∈ Ioo 0 1)
    (hg : MemLp g ∞ volume) :
    eLpNorm (czOperator K r g) 2 (volume.restrict (Ioc 2 3)) ≤
      2 ^ 8 * eLpNorm g 2 (volume.restrict (Ioc 1 4)) := by
  sorry

/-- The operator `czOperator K r` is bounded from `L^2 [a - 1, a + 2]` to `L^2 [a, a + 1]`,
uniformly in `r` and `a`. This follows from the same fact from `L^2 [1, 4]` to `L^2 [2, 3]`
proved using Fourier series, and translation invariance. -/
lemma eLpNorm_czOperator_restrict {g : ℝ → ℂ} {r a : ℝ} (hr : r ∈ Ioo 0 1)
    (hg : MemLp g ∞ volume) :
    eLpNorm (czOperator K r g) 2 (volume.restrict (Ioc a (a + 1))) ≤
      2 ^ 8 * eLpNorm g 2 (volume.restrict (Ioc (a - 1) (a + 2))) := by
  sorry

open Measure

lemma eLpNorm_czOperator_sq {g : ℝ → ℂ} {r : ℝ} (hr : r ∈ Ioo 0 1) (hg : MemLp g ∞ volume) :
    (eLpNorm (czOperator K r g) 2) ^ 2 ≤ 2 ^ 18 * (eLpNorm g 2) ^ 2 := by
  sorry

lemma eLpNorm_czOperator {g : ℝ → ℂ} {r : ℝ} (hr : 0 < r) (hg : MemLp g ∞ volume) :
    eLpNorm (czOperator K r g) 2 ≤ 2 ^ 9 * eLpNorm g 2 := by
  sorry

/- Lemma 11.1.6.
This verifies the assumption on the operators T_r in two-sided metric space Carleson.

Note: we might be able to simplify the proof in the blueprint by using real interpolation
`MeasureTheory.exists_hasStrongType_real_interpolation`.
-/
lemma Hilbert_strong_2_2 ⦃r : ℝ⦄ (hr : 0 < r) :
    HasBoundedStrongType (czOperator K r) 2 2 volume volume (C_Ts 4) := by
  sorry
