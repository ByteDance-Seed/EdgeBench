import SphereEversion.Global.LocalisationData
import SphereEversion.Global.LocalizedConstruction
import SphereEversion.Global.ParametricityForFree
import SphereEversion.ToMathlib.Geometry.Manifold.Metrizable

/-!
# Gromov's theorem

We prove the h-principle for open and ample first order differential relations.
-/

noncomputable section

open Set Filter ModelWithCorners Metric

open scoped Topology Manifold ContDiff

variable {EM : Type*} [NormedAddCommGroup EM] [NormedSpace ℝ EM] [FiniteDimensional ℝ EM]
  {HM : Type*} [TopologicalSpace HM] {IM : ModelWithCorners ℝ EM HM} [Boundaryless IM]
  {M : Type*} [TopologicalSpace M] [ChartedSpace HM M] [IsManifold IM ∞ M]
  [T2Space M] [SigmaCompactSpace M]
  {EX : Type*} [NormedAddCommGroup EX] [NormedSpace ℝ EX] [FiniteDimensional ℝ EX]
  {HX : Type*} [TopologicalSpace HX] {IX : ModelWithCorners ℝ EX HX} [Boundaryless IX]
  -- note: X is a metric space
  {X : Type*}
  [MetricSpace X] [ChartedSpace HX X] [IsManifold IX ∞ X] [SigmaCompactSpace X]
  {R : RelMfld IM M IX X} {A : Set M} {δ : M → ℝ}

@[inherit_doc] local notation "J¹" => OneJetBundle IM M IX X

theorem RelMfld.Ample.satisfiesHPrinciple (hRample : R.Ample) (hRopen : IsOpen R) (hA : IsClosed A)
    (hδ_pos : ∀ x, 0 < δ x) (hδ_cont : Continuous δ) : R.SatisfiesHPrinciple A δ := by
  sorry

variable {EP : Type*} [NormedAddCommGroup EP] [NormedSpace ℝ EP] [FiniteDimensional ℝ EP]
  {HP : Type*} [TopologicalSpace HP] {IP : ModelWithCorners ℝ EP HP} [Boundaryless IP]
  {P : Type*} [TopologicalSpace P] [ChartedSpace HP P] [IsManifold IP ∞ P]
  [SigmaCompactSpace P] [T2Space P] {C : Set (P × M)}

/-
We now deduce the parametric case from the unparametric one using
`RelMfld.satisfiesHPrinciple.satisfiesHPrincipleWith` which reduces the parametric
`h`-principle to the non-parametric one for a different relation and `RelMfld.Ample.relativize`
which ensures the ampleness assumption survives this reduction.
-/
/-- **Gromov's Theorem** -/
theorem RelMfld.Ample.satisfiesHPrincipleWith (hRample : R.Ample) (hRopen : IsOpen R)
    (hC : IsClosed C) (hδ_pos : ∀ x, 0 < δ x) (hδ_cont : Continuous δ) :
    R.SatisfiesHPrincipleWith IP C δ := by
  sorry

variable {E' : Type*} [NormedAddCommGroup E'] [NormedSpace ℝ E'] [FiniteDimensional ℝ E']
  {H' : Type*} [TopologicalSpace H'] {I' : ModelWithCorners ℝ E' H'} [I'.Boundaryless]
  {M' : Type*} [TopologicalSpace M'] [ChartedSpace H' M']
  [IsManifold I' ∞ M'] [SigmaCompactSpace M'] [T2Space M']

/-
Since every (σ-compact) manifold is metrizable, the metric space assumption can be removed.
-/
/-- Gromov's Theorem without metric space assumption -/
theorem RelMfld.Ample.satisfiesHPrincipleWith' {R : RelMfld IM M I' M'} (hRample : R.Ample)
    (hRopen : IsOpen R) (hC : IsClosed C) (hδ_pos : ∀ x, 0 < δ x) (hδ_cont : Continuous δ) :
    letI := manifoldMetric I' M'
    R.SatisfiesHPrincipleWith IP C δ := by
  sorry
