import SphereEversion.Loops.Reparametrization
import SphereEversion.ToMathlib.Analysis.CutOff
import Mathlib.Topology.MetricSpace.HausdorffDistance

noncomputable section

open Set Function Int Metric Filter Real MeasureTheory
open scoped  MeasureTheory.Measure Topology unitInterval ContDiff

variable {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] {F : Type*} [NormedAddCommGroup F]
  {g b : E → F} {Ω : Set (E × F)} {U K C : Set E}

variable [NormedSpace ℝ F] [FiniteDimensional ℝ F]

theorem exist_loops_aux1 (hK : IsCompact K) (hΩ_op : IsOpen Ω) (hb : 𝒞 ∞ b)
    (hgK : ∀ᶠ x near K, g x = b x)
    (hconv : ∀ x, g x ∈ hull (connectedComponentIn (Prod.mk x ⁻¹' Ω) <| b x)) :
    ∃ γ : E → ℝ → Loop F,
      ∃ V ∈ 𝓝ˢ K,
        ∃ ε > 0,
          SurroundingFamilyIn g b γ V Ω ∧
            (∀ x ∈ V, ball (x, b x) (ε + ε) ⊆ Ω) ∧ ∀ x ∈ V, ∀ (t s), dist (γ x t s) (b x) < ε := by
  sorry

attribute [fun_prop] Continuous.if_const

/- Some remarks about `exist_loops_aux2`:
  `δ`: loop after smoothing
  `γ`: loop before smoothing (defined on all of `E`)
  Requirements:
  (0) `δ x t` is a loop
  (1) `δ` lands in `Ω`
  (2) `δ` has the correct values: for `s = 0` and `t = 0` it should be `b`
  (3) `δ` should be constant on `t ≤ 0` and for `t ≥ 1`.
  (4) `δ x 1` surrounds `g x`.
  (5) Near `K`, the line connecting `b` and `δ` lies in `Ω`

  Strategy:
  (a) We need `ε₁` satisfying the following conditions:
  (a1) We need to ensure that an `ε₁ x`-ball around `(x, δ x s t)` lies in `Ω` for some
    continuous `ε₁`.
  (a4) Furthermore, `ε₁` should be small enough so that any function with that
    distance from `γ` still surrounds `g`, using `SurroundingFamily.surrounds_of_close`.
  (a5): `ε₁ x < ε₀` (obtained from `exist_loops_aux1`)
  (b) Replace `γ x t s` by `γ x (linearReparam t) (linearReparam s)`.
  (e) Let `δ' x` be a family of loops that is at most `ε₁` away from `γ` using
    `exists_smooth_and_eqOn`. Since `γ` is smooth near `s ∈ ℤ` and `t ≤ 0` we can also
    ensure that `δ' = γ` for those values (*).
    Now let `δ x t s = δ' x (smoothTransition t) (fract s)`
    We immediately get (0) and (3). We get (2) by (*).
    This is still smooth, since `δ'` is doesn't depend on `s` near `s ∈ ℤ`.
  (f) (a1) gives (1), (a4) gives (4) and (a5) gives (5).

  Note: to ensure (2) the reparamerization strategy that was originally in the blueprint
  (ensuring that `γ` is locally constant in the `t` and `s` directions)
  didn't work. Indeed it needed to take the convolution in the `x`-direction,
  meaning that the value won't stay the same, since `γ` is not constant in the `x`-direction.
-/
theorem exist_loops_aux2 [FiniteDimensional ℝ E] (hK : IsCompact K) (hΩ_op : IsOpen Ω) (hg : 𝒞 ∞ g)
    (hb : 𝒞 ∞ b) (hgK : ∀ᶠ x near K, g x = b x)
    (hconv : ∀ x, g x ∈ hull (connectedComponentIn (Prod.mk x ⁻¹' Ω) <| b x)) :
    ∃ γ : E → ℝ → Loop F,
      SurroundingFamilyIn g b γ univ Ω ∧
        𝒞 ∞ ↿γ ∧ ∀ᶠ x near K, ∀ t s, closedBall (x, b x) (dist (γ x t s) (b x)) ⊆ Ω := by
  sorry

variable (g b Ω U K)

/-- A "nice" family of loops consists of all the properties we want from the `exist_loops` lemma:
it is a smooth homotopy in `Ω` with fixed endpoints from the constant loop at `b x` to a loop with
average `g x` that is also constantly `b x` near `K`.
The first two conditions are implementation specific: the homotopy is constant outside the unit
interval. -/
structure NiceLoop (γ : ℝ → E → Loop F) : Prop where
  t_le_zero : ∀ x, ∀ t ≤ 0, γ t x = γ 0 x
  t_ge_one : ∀ x, ∀ t ≥ 1, γ t x = γ 1 x
  t_zero : ∀ x s, γ 0 x s = b x
  s_zero : ∀ x t, γ t x 0 = b x
  avg : ∀ x, (γ 1 x).average = g x
  mem_Ω : ∀ x t s, (x, γ t x s) ∈ Ω
  smooth : 𝒞 ∞ ↿γ
  rel_K : ∀ᶠ x in 𝓝ˢ K, ∀ t s, γ t x s = b x

variable {g b Ω U K}

theorem exist_loops [FiniteDimensional ℝ E] (hK : IsCompact K) (hΩ_op : IsOpen Ω) (hg : 𝒞 ∞ g)
    (hb : 𝒞 ∞ b) (hgK : ∀ᶠ x near K, g x = b x)
    (hconv : ∀ x, g x ∈ hull (connectedComponentIn (Prod.mk x ⁻¹' Ω) <| b x)) :
    ∃ γ : ℝ → E → Loop F, NiceLoop g b Ω K γ := by
  sorry
