import SphereEversion.Global.Immersion

open Metric FiniteDimensional Set ModelWithCorners

open scoped Manifold Topology ContDiff

/-! # The sphere eversion project

The goal of this project was to formalize Gromov's flexibility theorem for open and ample
partial differential relation. A famous corollary of this theorem is Smale's sphere eversion
theorem: you can turn a sphere inside-out. Let us state this corollary first.
-/

section Smale

-- As usual, we denote by `ℝ³` the Euclidean 3-space and by `𝕊²` its unit sphere.
notation "ℝ³" => EuclideanSpace ℝ (Fin 3)

notation "𝕊²" => sphere (0 : ℝ³) 1

-- In the following statements, notation involving `𝓘` and `𝓡` denote smooth structures in the
-- sense of differential geometry.
theorem Smale :
    -- There exists a family of functions `f t` indexed by `ℝ` going from `𝕊²` to `ℝ³` such that
    ∃ f : ℝ → 𝕊² → ℝ³,
    -- it is smooth in both variables (for the obvious smooth structures on `ℝ × 𝕊²` and `ℝ³`) and
    ContMDiff (𝓘(ℝ, ℝ).prod (𝓡 2)) 𝓘(ℝ, ℝ³) ∞ ↿f ∧
    (-- `f 0` is the inclusion map, sending `x` to `x` and
    f 0 = fun x : 𝕊² ↦ (x : ℝ³)) ∧
    (-- `f 1` is the antipodal map, sending `x` to `-x` and
    f 1 = fun x : 𝕊² ↦ -(x : ℝ³)) ∧
    -- every `f t` is an immersion.
    ∀ t, Immersion (𝓡 2) 𝓘(ℝ, ℝ³) (f t) ∞ := by
  sorry

end Smale

/-
The above result is an easy corollary of a much more general theorem by Gromov.
The next three paragraphs lines simply introduce three real dimensional manifolds
`M`, `M'` and `P` and assume they are separated and σ-compact. They are rather verbose because
mathlib has a very general theory of manifolds (including manifolds with boundary and corners).
We will consider families of maps from `M` to `M'` parametrized by `P`.
Actually `M'` is assumed to be equipped with a preferred metric space structure in order to make it
easier to state the `𝓒⁰` approximation property.
-/
section Gromov

variable (n n' d : ℕ)
  {M : Type*} [TopologicalSpace M] [ChartedSpace (ℝ^n) M]
  [IsManifold (𝓡 n) ∞ M] [T2Space M] [SigmaCompactSpace M]
  {M' : Type*} [MetricSpace M'] [ChartedSpace (ℝ^n') M'] [IsManifold (𝓡 n') ∞ M']
  [SigmaCompactSpace M']
  {P : Type*} [TopologicalSpace P] [ChartedSpace (ℝ^d) P]
  [IsManifold (𝓡 d) ∞ P] [T2Space P] [SigmaCompactSpace P]

/-- Gromov's flexibility theorem for open and ample first order partial differential relations
for maps between manifolds. -/
theorem Gromov
    -- Let `R` be an open and ample first order partial differential relation for maps
    -- from `M` to `M'`.
    {R : RelMfld 𝓘(ℝ, ℝ^n) M 𝓘(ℝ, ℝ^n') M'}
    (hRample : R.Ample) (hRopen : IsOpen R)
    -- Let `C` be a closed subset in `P × M`
    {C : Set (P × M)}
    (hC : IsClosed C)
    -- Let `ε` be a continuous positive function on `M`
    {ε : M → ℝ}
    (ε_pos : ∀ x, 0 < ε x) (ε_cont : Continuous ε)
    -- Let `𝓕₀` be a family of formal solutions to `R` parametrized by `P`
    (𝓕₀ : FamilyFormalSol 𝓘(ℝ, ℝ^d) P R)
    -- Assume it is holonomic near `C`.
    (hhol :
      ∀ᶠ p : P × M in 𝓝ˢ C,
        (𝓕₀ p.1).IsHolonomicAt p.2) :-- then there is a homotopy of such families
    ∃ 𝓕 : FamilyFormalSol (𝓘(ℝ, ℝ).prod 𝓘(ℝ, ℝ^d)) (ℝ × P) R,
      (-- that agrees with `𝓕₀` at time `t = 0` for every parameter and every point in the source
        ∀ (p : P) (x : M), 𝓕 (0, p) x = 𝓕₀ p x) ∧
      (-- is holonomic everywhere for `t = 1`,
        ∀ p : P, (𝓕 (1, p)).toOneJetSec.IsHolonomic) ∧
      (-- agrees with `𝓕₀` near `C`,
        ∀ᶠ p : P × M in 𝓝ˢ C,
        ∀ t : ℝ, 𝓕 (t, p.1) p.2 = 𝓕₀ p.1 p.2) ∧
      -- and whose underlying maps are `ε`--close to `𝓕₀`.
        ∀ (t : ℝ) (p : P) (x : M), dist ((𝓕 (t, p)).bs x) ((𝓕₀ p).bs x) ≤ ε x := by
  sorry

end Gromov
