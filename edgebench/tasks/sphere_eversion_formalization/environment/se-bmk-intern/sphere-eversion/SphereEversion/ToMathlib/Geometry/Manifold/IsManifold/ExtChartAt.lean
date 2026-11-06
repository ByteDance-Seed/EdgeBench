import Mathlib.Geometry.Manifold.IsManifold.ExtChartAt

open scoped Topology

open Metric hiding mem_nhds_iff ball

open Set

section

variable {𝕜 E M H : Type*} [NontriviallyNormedField 𝕜]
  [TopologicalSpace H] [TopologicalSpace M] [ChartedSpace H M]
  [NormedAddCommGroup E] [NormedSpace 𝕜 E] (I : ModelWithCorners 𝕜 E H)

namespace ChartedSpace

/-- If `M` is a `ChartedSpace` we can use the preferred chart at any point to transfer a
ball in coordinate space into a set in `M`. These can be a useful neighbourhood basis. -/
def ball (x : M) (r : ℝ) :=
  (extChartAt I x).symm '' Metric.ball (extChartAt I x x) r

end ChartedSpace

end
