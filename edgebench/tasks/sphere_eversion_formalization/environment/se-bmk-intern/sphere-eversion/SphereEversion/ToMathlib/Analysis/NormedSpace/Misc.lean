import Mathlib.Analysis.InnerProductSpace.EuclideanDist
import Mathlib.Topology.OpenPartialHomeomorph.Constructions

variable {F : Type*} [NormedAddCommGroup F] [NormedSpace ℝ F]

open Set Metric
open scoped ContDiff

noncomputable section

variable [FiniteDimensional ℝ F] (c : F) (r : ℝ)

theorem OpenPartialHomeomorph.exists_contDiff_source_univ_target_subset_ball :
    ∃ f : OpenPartialHomeomorph F F, ContDiff ℝ ∞ f ∧ ContDiffOn ℝ ∞ f.symm f.target ∧
      f.source = univ ∧ (0 < r → f.target ⊆ ball c r) ∧ f 0 = c := by
  sorry

/-- A variant of `InnerProductSpace.diffeomorphToNhd` which provides a function satisfying the
weaker condition `range_diffeomorph_to_nhd_subset_ball` but which applies to any `NormedSpace`.

In fact one could demand this stronger property but it would be more work and we don't need it. -/
def diffeomorphToNhd (c : F) (r : ℝ) : OpenPartialHomeomorph F F :=
  (OpenPartialHomeomorph.exists_contDiff_source_univ_target_subset_ball c r).choose

variable {r} in
@[simp]
theorem range_diffeomorphToNhd_subset_ball (hr : 0 < r) :
    range (diffeomorphToNhd c r) ⊆ ball c r := by
  sorry

@[simp]
theorem contDiff_diffeomorphToNhd {n : ℕ∞} :
    ContDiff ℝ n <| diffeomorphToNhd c r := by
  sorry

@[simp]
theorem contDiffOn_diffeomorphToNhd_inv {n : ℕ∞} :
    ContDiffOn ℝ n (diffeomorphToNhd c r).symm (diffeomorphToNhd c r).target := by
  sorry
