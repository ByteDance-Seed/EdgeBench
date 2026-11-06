import Mathlib.Topology.MetricSpace.PartitionOfUnity
import SphereEversion.Global.SmoothEmbedding

noncomputable section

open scoped Manifold ContDiff

open Set Metric

section

variable {𝕜 : Type*} [NontriviallyNormedField 𝕜]
  {E : Type*} [NormedAddCommGroup E] [NormedSpace 𝕜 E]
  {H : Type*} [TopologicalSpace H] (I : ModelWithCorners 𝕜 E H)
  {M : Type*} [TopologicalSpace M] [ChartedSpace H M] [IsManifold I ∞ M]
  {E' : Type*} [NormedAddCommGroup E'] [NormedSpace 𝕜 E']
  {H' : Type*} [TopologicalSpace H'] (I' : ModelWithCorners 𝕜 E' H')
  {M' : Type*} [TopologicalSpace M'] [ChartedSpace H' M'] [IsManifold I' ∞ M']

/-- Definition `def:localisation_data`. -/
structure LocalisationData (f : M → M') where
  cont : Continuous f
  ι' : Type*
  N : ℕ
  φ : IndexType N → OpenSmoothEmbedding 𝓘(𝕜, E) E I M
  ψ : ι' → OpenSmoothEmbedding 𝓘(𝕜, E') E' I' M'
  j : IndexType N → ι'
  h₁ : (⋃ i, φ i '' ball (0 : E) 1) = univ
  h₂ : (⋃ i', ψ i' '' ball (0 : E') 1) = univ
  h₃ : ∀ i, range (f ∘ φ i) ⊆ ψ (j i) '' ball (0 : E') 1
  h₄ : LocallyFinite fun i' ↦ range (ψ i')
  lf_φ : LocallyFinite fun i ↦ range (φ i)

namespace LocalisationData

variable {f : M → M'} {I I'} (ld : LocalisationData I I' f)

abbrev ψj : IndexType ld.N → OpenSmoothEmbedding 𝓘(𝕜, E') E' I' M' :=
  ld.ψ ∘ ld.j

/-- The type indexing the source charts of the given localisation data. -/
def ι (L : LocalisationData I I' f) :=
  IndexType L.N

omit [IsManifold I ∞ M] [IsManifold I' ∞ M'] in
theorem iUnion_succ' {β : Type*} (s : ld.ι → Set β) (i : IndexType ld.N) :
    (⋃ j ≤ i, s j) = (⋃ j < i, s j) ∪ s i := by
  sorry

open Filter

end LocalisationData

end

section

open ModelWithCorners

variable {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] [FiniteDimensional ℝ E]
  {M : Type*} [TopologicalSpace M] [SigmaCompactSpace M] [LocallyCompactSpace M] [T2Space M]
  {H : Type*} [TopologicalSpace H] (I : ModelWithCorners ℝ E H) [Boundaryless I] [Nonempty M]
  [ChartedSpace H M] [IsManifold I ∞ M]
  (E' : Type*) [NormedAddCommGroup E'] [NormedSpace ℝ E'] [FiniteDimensional ℝ E']
  {H' : Type*} [TopologicalSpace H'] (I' : ModelWithCorners ℝ E' H') [Boundaryless I']
  {M' : Type*} [MetricSpace M'] [SigmaCompactSpace M'] [LocallyCompactSpace M']
  [Nonempty M'] [ChartedSpace H' M'] [IsManifold I' ∞ M']

variable (M')

theorem nice_atlas_target :
    ∃ n,
      ∃ ψ : IndexType n → OpenSmoothEmbedding 𝓘(ℝ, E') E' I' M',
        (LocallyFinite fun i' ↦ range (ψ i')) ∧ (⋃ i', ψ i' '' ball 0 1) = univ := by
  sorry

/-- A collection of charts on a manifold `M'` which are smooth open embeddings with domain the whole
model space, and which cover the manifold when restricted in each case to the unit ball. -/
def targetCharts (i' : IndexType (nice_atlas_target E' I' M').choose) :
    OpenSmoothEmbedding 𝓘(ℝ, E') E' I' M' :=
  (nice_atlas_target E' I' M').choose_spec.choose i'

theorem targetCharts_cover : (⋃ i', targetCharts E' I' M' i' '' ball (0 : E') 1) = univ := by
  sorry

variable (E) {M'}
variable {f : M → M'} (hf : Continuous f)

include hf in
theorem nice_atlas_domain :
    ∃ n,
      ∃ φ : IndexType n → OpenSmoothEmbedding 𝓘(ℝ, E) E I M,
        (∀ i, ∃ i', range (φ i) ⊆ f ⁻¹' (targetCharts E' I' M' i' '' ball (0 : E') 1)) ∧
          (LocallyFinite fun i ↦ range (φ i)) ∧ (⋃ i, φ i '' ball 0 1) = univ := by
  sorry

/-- Lemma `lem:ex_localisation`
  Any continuous map between manifolds has some localisation data. -/
def stdLocalisationData : LocalisationData I I' f where
  cont := hf
  N := (nice_atlas_domain E I E' I' hf).choose
  ι' := IndexType (nice_atlas_target E' I' M').choose
  φ := (nice_atlas_domain E I E' I' hf).choose_spec.choose
  ψ := targetCharts E' I' M'
  j i := ((nice_atlas_domain E I E' I' hf).choose_spec.choose_spec.1 i).choose
  h₁ := (nice_atlas_domain E I E' I' hf).choose_spec.choose_spec.2.2
  h₂ := targetCharts_cover E' I' M'
  h₃ i := by
    rw [range_comp]
    rintro - ⟨y, hy, rfl⟩
    exact ((nice_atlas_domain E I E' I' hf).choose_spec.choose_spec.1 i).choose_spec hy
  h₄ := (nice_atlas_target E' I' M').choose_spec.choose_spec.1
  lf_φ := (nice_atlas_domain E I E' I' hf).choose_spec.choose_spec.2.1

variable {E E' I I'}

section

omit [FiniteDimensional ℝ E] [SigmaCompactSpace M] [LocallyCompactSpace M] [T2Space M]
  [I.Boundaryless] [Nonempty M] [IsManifold I ∞ M] [I'.Boundaryless]
  [SigmaCompactSpace M'] [LocallyCompactSpace M'] [Nonempty M'] [IsManifold I' ∞ M']

/-- Lemma `lem:localisation_stability`. -/
theorem localisation_stability {f : M → M'} (ld : LocalisationData I I' f) :
    ∃ (ε : M → ℝ) (_hε : ∀ m, 0 < ε m) (_hε' : Continuous ε),
      ∀ (g : M → M') (_hg : ∀ m, dist (g m) (f m) < ε m) (i),
        range (g ∘ ld.φ i) ⊆ range (ld.ψj i) := by
  sorry

namespace LocalisationData

protected def ε (ld : LocalisationData I I' f) : M → ℝ :=
  (localisation_stability ld).choose

end LocalisationData
end

variable (I I')

open LocalisationData in
theorem _root_.exists_stability_dist {f : M → M'} (hf : Continuous f) :
    ∃ ε : M → ℝ, (∀ m, 0 < ε m) ∧ Continuous ε ∧
      ∀ x : M,
        ∃ φ : OpenSmoothEmbedding 𝓘(ℝ, E) E I M,
        ∃ ψ : OpenSmoothEmbedding 𝓘(ℝ, E') E' I' M',
          x ∈ range φ ∧
          ∀ (g : M → M'), (∀ m, dist (g m) (f m) < ε m) → range (g ∘ φ) ⊆ range ψ := by
  sorry

end
