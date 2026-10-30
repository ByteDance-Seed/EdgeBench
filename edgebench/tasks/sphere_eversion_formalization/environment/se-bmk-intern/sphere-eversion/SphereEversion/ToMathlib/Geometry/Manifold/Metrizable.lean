import Mathlib.Geometry.Manifold.Metrizable

noncomputable section

section

variable {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] [FiniteDimensional ℝ E] {H : Type*}
  [TopologicalSpace H] (I : ModelWithCorners ℝ E H) (M : Type*) [TopologicalSpace M]
  [ChartedSpace H M]

/-- A metric defining the topology on a σ-compact T₂ real manifold. -/
def manifoldMetric [T2Space M] [SigmaCompactSpace M] : MetricSpace M :=
  letI := Manifold.metrizableSpace I M
  TopologicalSpace.metrizableSpaceMetric _

end
