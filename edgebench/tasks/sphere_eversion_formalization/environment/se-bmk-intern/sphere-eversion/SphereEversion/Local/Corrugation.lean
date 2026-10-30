import Mathlib.Analysis.Asymptotics.Lemmas
import Mathlib.LinearAlgebra.Dual.Lemmas
import Mathlib.Analysis.Calculus.ParametricIntegral
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Periodic
import SphereEversion.ToMathlib.Algebra.Ring.Periodic
import SphereEversion.ToMathlib.MeasureTheory.BorelSpace
import SphereEversion.Loops.Basic
import SphereEversion.Local.DualPair

/-! # Theillière's corrugation operation

This files introduces the fundamental calculus tool of convex integration. The version of convex
integration that we formalize is Theillière's corrugation-based convex integration.
It improves a map `f : E → F` by adding to it some corrugation map
`fun x ↦ (1/N) • ∫ t in 0..(N*π x), (γ x t - (γ x).average)` where `γ` is a family of loops in
`F` parametrized by `E` and `N` is some (very large) real number.

Under the assumption that `∀ x, (γ x).average = D f x p.v` for some dual pair `p`, this improved
map will have a derivative which is almost a value of `γ x` in direction `p.v` and almost the
derivative of `f` in direction `ker p.π`. More precisely, its derivative will be almost
`p.update (D f x) (γ x (N*p.π x))`. In addition the improved map will be very close to `f`
in C⁰ topology. All those "almost" and "very close" refer to the asymptotic behavior when `N`
is very large.

The main definition is `corrugation`. The main results are:
* `fderiv_corrugated_map` computing the difference between `D (f + corrugation p.π N γ) x` and
    `p.update (D f x) (γ x (N*p.π x)) + corrugation.remainder p.π N γ x`
* `remainder_c0_small_on` saying this difference is very small
* `corrugation.c0_small_on` saying that corrugations are C⁰-small

-/

noncomputable section

open Set Function Filter MeasureTheory ContinuousLinearMap
open scoped Topology unitInterval

variable {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
  {F : Type*} [NormedAddCommGroup F] [NormedSpace ℝ F] [FiniteDimensional ℝ F]
  {G : Type*} [NormedAddCommGroup G] [NormedSpace ℝ G]
  {H : Type*} [NormedAddCommGroup H] [NormedSpace ℝ H] [FiniteDimensional ℝ H]
  {π : E →L[ℝ] ℝ} (N : ℝ) (γ : E → Loop F)

open scoped Borelize

/-- Theillière's corrugations. -/
def corrugation (π : E →L[ℝ] ℝ) (N : ℝ) (γ : E → Loop F) : E → F := fun x ↦
  (1 / N) • ∫ t in (0)..N * π x, γ x t - (γ x).average

@[inherit_doc] local notation "𝒯" => corrugation π

variable (π)

open intervalIntegral in

variable {γ}

theorem corrugation.contDiff' {n : ℕ∞} {γ : G → E → Loop F} (hγ_diff : 𝒞 n ↿γ) {x : H → E}
    (hx : 𝒞 n x) {g : H → G} (hg : 𝒞 n g) : 𝒞 n fun h ↦ 𝒯 N (γ <| g h) <| x h := by
  sorry

theorem corrugation.contDiff [FiniteDimensional ℝ E] {n : ℕ∞} (hγ_diff : 𝒞 n ↿γ) : 𝒞 n (𝒯 N γ) := by
  sorry

notation "∂₁" => partialFDerivFst ℝ

/-- The remainder appearing when differentiating a corrugation.
-/
def corrugation.remainder (π : E → ℝ) (N : ℝ) (γ : E → Loop F) : E → E →L[ℝ] F := fun x ↦
  (1 / N) • ∫ t in (0)..N * π x, ∂₁ (fun x t ↦ (γ x).normalize t) x t

@[inherit_doc] local notation "R" => corrugation.remainder π

variable [FiniteDimensional ℝ E]

theorem remainder_eq (N : ℝ) {γ : E → Loop F} (h : 𝒞 1 ↿γ) :
    R N γ = fun x ↦ (1 / N) • ∫ t in (0)..N * π x, (Loop.diff γ x).normalize t := by
  sorry

-- The next lemma is a restatement of the above to emphasize that remainder is a corrugation
-- unused
theorem remainder_eq_corrugation (N : ℝ) {γ : E → Loop F} (h : 𝒞 1 ↿γ) :
    R N γ = 𝒯 N fun x ↦ Loop.diff γ x := by
  sorry

@[simp]
theorem remainder_eq_zero (N : ℝ) {γ : E → Loop F} (h : 𝒞 1 ↿γ) {x : E} (hx : x ∉ Loop.support γ) :
    R N γ x = 0 := by
  sorry

theorem corrugation.fderiv_eq {N : ℝ} (hN : N ≠ 0) (hγ_diff : 𝒞 1 ↿γ) :
    D (𝒯 N γ) = fun x : E ↦ ((γ x (N * π x) - (γ x).average) ⬝ π) + R N γ x := by
  sorry

theorem corrugation.fderiv_apply (hN : N ≠ 0) (hγ_diff : 𝒞 1 ↿γ) (x v : E) :
    D (𝒯 N γ) x v = π v • (γ x (N * π x) - (γ x).average) + R N γ x v := by
  sorry

theorem fderiv_corrugated_map (hN : N ≠ 0) (hγ_diff : 𝒞 1 ↿γ) {f : E → F} (hf : 𝒞 1 f)
    (p : DualPair E) {x} (hfγ : (γ x).average = D f x p.v) :
    D (f + corrugation p.π N γ) x =
      p.update (D f x) (γ x (N * p.π x)) + corrugation.remainder p.π N γ x := by
  sorry

open scoped ContDiff

theorem Remainder.smooth {γ : G → E → Loop F} (hγ_diff : 𝒞 ∞ ↿γ) {x : H → E} (hx : 𝒞 ∞ x)
    {g : H → G} (hg : 𝒞 ∞ g) : 𝒞 ∞ fun h ↦ R N (γ <| g h) <| x h := by
  sorry

set_option linter.style.multiGoal false in
theorem remainder_c0_small_on {K : Set E} (hK : IsCompact K) (hγ_diff : 𝒞 1 ↿γ) {ε : ℝ}
    (ε_pos : 0 < ε) : ∀ᶠ N in atTop, ∀ x ∈ K, ‖R N γ x‖ < ε := by
  sorry
