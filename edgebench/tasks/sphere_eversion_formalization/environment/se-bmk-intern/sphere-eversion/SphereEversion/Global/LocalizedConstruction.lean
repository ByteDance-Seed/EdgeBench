import SphereEversion.Global.Localisation
import SphereEversion.Local.HPrinciple

noncomputable section

open Set Filter ModelWithCorners Metric

open scoped Topology Manifold ContDiff

variable {EM : Type*} [NormedAddCommGroup EM] [NormedSpace ℝ EM] [FiniteDimensional ℝ EM]
  {HM : Type*} [TopologicalSpace HM] {IM : ModelWithCorners ℝ EM HM}
  {M : Type*} [TopologicalSpace M] [ChartedSpace HM M] [IsManifold IM ∞ M]
  [T2Space M]
  {EX : Type*} [NormedAddCommGroup EX] [NormedSpace ℝ EX] [FiniteDimensional ℝ EX]
  {HX : Type*} [TopologicalSpace HX] {IX : ModelWithCorners ℝ EX HX}
  {X : Type*} [MetricSpace X] [ChartedSpace HX X] [IsManifold IX ∞ X]

theorem OpenSmoothEmbedding.improve_formalSol (φ : OpenSmoothEmbedding 𝓘(ℝ, EM) EM IM M)
    (ψ : OpenSmoothEmbedding 𝓘(ℝ, EX) EX IX X) {R : RelMfld IM M IX X} (hRample : R.Ample)
    (hRopen : IsOpen R) {C : Set M} (hC : IsClosed C) {δ : M → ℝ} (hδ_pos : ∀ x, 0 < δ x)
    (hδ_cont : Continuous δ) {F : FormalSol R} (hFφψ : F.bs '' range φ ⊆ range ψ)
    (hFC : ∀ᶠ x near C, F.IsHolonomicAt x) {K₀ K₁ : Set EM} (hK₀ : IsCompact K₀)
    (hK₁ : IsCompact K₁) (hK₀K₁ : K₀ ⊆ interior K₁) :
    ∃ F' : HtpyFormalSol R,
      (∀ᶠ t near Iic (0 : ℝ), F' t = F) ∧
        (∀ᶠ t near Ici (1 : ℝ), F' t = F' 1) ∧
          (∀ᶠ x near C, ∀ t, F' t x = F x) ∧
            (∀ t, ∀ x ∉ φ '' K₁, F' t x = F x) ∧
              (∀ t x, dist ((F' t).bs x) (F.bs x) < δ x) ∧
                ∀ᶠ x near C ∪ φ '' K₀, (F' 1).IsHolonomicAt x := by
  sorry
