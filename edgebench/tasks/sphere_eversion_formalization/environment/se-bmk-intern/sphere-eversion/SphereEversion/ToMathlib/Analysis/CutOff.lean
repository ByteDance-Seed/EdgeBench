import Mathlib.Geometry.Manifold.PartitionOfUnity

open Set Filter

open scoped Manifold Topology ContDiff

-- The bundled versions of this lemma has been merged to mathlib.
-- TODO: add the unbundled version, or (better) re-write sphere-eversion accordingly.
theorem exists_contDiff_one_nhds_of_interior {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    [FiniteDimensional ℝ E] {s t : Set E} (hs : IsClosed s) (hd : s ⊆ interior t) :
    ∃ f : E → ℝ, ContDiff ℝ ∞ f ∧ (∀ᶠ x in 𝓝ˢ s, f x = 1) ∧ (∀ x ∉ t, f x = 0) ∧
      ∀ x, f x ∈ Icc (0 : ℝ) 1 := by
  sorry
