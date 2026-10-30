import Mathlib.Analysis.Calculus.BumpFunction.InnerProduct
import Mathlib.Analysis.Convolution
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Periodic
import Mathlib.MeasureTheory.Measure.Haar.Unique
import Mathlib.Analysis.Calculus.BumpFunction.Normed
import SphereEversion.ToMathlib.Algebra.Ring.Periodic
import SphereEversion.ToMathlib.Analysis.ContDiff
import SphereEversion.Loops.Basic

/-!
# Delta mollifiers

A key ingredient in the proof of the reparametrization lemma is the existence of a smooth
approximation to the Dirac delta function. Such an approximation is a sequence of functions
`δ : ℕ × S¹ → S¹`, `(i, t) ↦ δᵢ t` such that:
 * `δᵢ` is smooth for all `i`,
 * `δᵢ` is non-negative for all `i`,
 * `∫ x in 0..1, (δᵢ x) = 1` for all `i`,
* `∫ x in 0..1, (δᵢ x) • f x → f 0`, as `i → ∞` for any continuous function `f` on `S¹`.

This file contains a construction `approxDirac` of such a family `δ` together with code which
packages this into the precise form required for the proof of the reparametrization lemma:
`deltaMollifier`, `Loop.mollify`.

The key ingredients are the existence of smooth "bump functions" and a powerful theory of
convolutions.
-/

noncomputable section

open Set Function MeasureTheory.MeasureSpace ContinuousLinearMap
open scoped Topology Filter Convolution ContDiff

variable {F : Type*} [NormedAddCommGroup F] [NormedSpace ℝ F]
section

/-! ## Bump family

In this section we construct `bump (n : ℕ)`, a bump function with support in
`Ioo (-1/(n+2)) (1/(n+2))`.
-/

/-- `bump n` is a bump function on `ℝ` which has support `Ioo (-(1/(n+2))) (1/(n+2))`
and equals one on `Icc (-(1/(n+3))) (1/(n+3))`.
-/
def bump (n : ℕ) : ContDiffBump (0 : ℝ) where
  rIn := 1 / (n + 3)
  rOut := 1 / (n + 2)
  rIn_pos := by positivity
  rIn_lt_rOut := by
    apply one_div_lt_one_div_of_lt
    · exact_mod_cast Nat.succ_pos _
    · exact_mod_cast lt_add_one (n + 2)

end

section

/-! # Periodize

In this section we turn any function `f : ℝ → E` into a 1-periodic function
`fun t : ℝ ↦ ∑ᶠ n : ℤ, f (t+n)`.
-/

variable {M : Type*} [AddCommMonoid M]

/-- Turn a function into a 1-periodic function. If its support lies in a (non-closed) interval
of length 1, then this will be that function made periodic with period 1. -/
def periodize (f : ℝ → M) (t : ℝ) : M :=
  ∑ᶠ n : ℤ, f (t + n)

variable {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]

theorem periodize_comp_sub (f : ℝ → M) (x t : ℝ) :
    periodize (fun x' ↦ f (x' - t)) x = periodize f (x - t) := by
  sorry

open MeasureTheory

-- if convenient we could set `[c,d] = [0,1]`

end

section DeltaApprox

/-! ## An approximate Dirac "on the circle". -/

/-- A periodized bump function, which we can view as a function from `𝕊¹ → ℝ`. As `n → ∞` this
tends to the Dirac delta function located at `0`. -/
def approxDirac (n : ℕ) : ℝ → ℝ :=
  periodize <| (bump n).normed volume

end DeltaApprox

section VersionOfDeltaMollifierUsingN

/-- A sequence of functions that converges to the Dirac delta function located at `t`, with the
properties that this sequence is everywhere positive and -/
def deltaMollifier (n : ℕ) (t : ℝ) : ℝ → ℝ := fun x ↦
  n / (n + 1) * approxDirac n (x - t) + 1 / (n + 1)

variable {n : ℕ} {t : ℝ}

open intervalIntegral

/-- `γ.mollify n t` is a weighted average of `γ` using weights `deltaMollifier n t`.
This means that as `n → ∞` this value tends to `γ t`, but because `deltaMollifier n t` is positive,
we know that we can reparametrize `γ` to obtain a loop that has `γ.mollify n t` as its actual
average. -/
def Loop.mollify (γ : Loop F) (n : ℕ) (t : ℝ) : F :=
  ∫ s in (0)..1, deltaMollifier n t s • γ s

end VersionOfDeltaMollifierUsingN
