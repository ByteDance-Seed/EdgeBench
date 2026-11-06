import SphereEversion.ToMathlib.Partition
import Mathlib.Geometry.Manifold.Notation

noncomputable section

open scoped Topology Manifold ContDiff

open Set Function Filter

section

variable {ι : Type*}

variable {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] [FiniteDimensional ℝ E] {H : Type*}
  [TopologicalSpace H] {I : ModelWithCorners ℝ E H} {M : Type*} [TopologicalSpace M]
  [ChartedSpace H M] [IsManifold I ∞ M] [SigmaCompactSpace M] [T2Space M]

section

variable {F : Type*} [AddCommGroup F] [Module ℝ F]

end

variable {F : Type*} [NormedAddCommGroup F] [NormedSpace ℝ F]

variable {G : Type*} [NormedAddCommGroup G] [NormedSpace ℝ G] {HG : Type*} [TopologicalSpace HG]
  (IG : ModelWithCorners ℝ G HG) {N : Type*} [TopologicalSpace N] [ChartedSpace HG N]
  [IsManifold IG ∞ N]

variable (I)

omit [FiniteDimensional ℝ E] [IsManifold I ∞ M] [SigmaCompactSpace M] [T2Space M] in

theorem exists_contMDiff_of_convex {P : M → F → Prop} (hP : ∀ x, Convex ℝ {y | P x y}) {n : ℕ∞}
    (hP' : ∀ x : M, ∃ U ∈ 𝓝 x, ∃ f : M → F, CMDiff[U] n f ∧ ∀ x ∈ U, P x (f x)) :
    ∃ f : M → F, CMDiff n f ∧ ∀ x, P x (f x) := by
  sorry

theorem exists_contDiff_of_convex {P : E → F → Prop} (hP : ∀ x, Convex ℝ {y | P x y}) {n : ℕ∞}
    (hP' : ∀ x : E, ∃ U ∈ 𝓝 x, ∃ f : E → F, ContDiffOn ℝ n f U ∧ ∀ x ∈ U, P x (f x)) :
    ∃ f : E → F, ContDiff ℝ n f ∧ ∀ x, P x (f x) := by
  sorry

end

section

variable {E₁ E₂ F : Type*}
  [NormedAddCommGroup E₁] [NormedSpace ℝ E₁] [FiniteDimensional ℝ E₁]
  [NormedAddCommGroup E₂] [NormedSpace ℝ E₂] [FiniteDimensional ℝ E₂]
  [NormedAddCommGroup F] [NormedSpace ℝ F]

variable {H₁ M₁ H₂ M₂ : Type*}
  [TopologicalSpace H₁] (I₁ : ModelWithCorners ℝ E₁ H₁)
  [TopologicalSpace M₁] [ChartedSpace H₁ M₁] [IsManifold I₁ ∞ M₁]
  [TopologicalSpace H₂] (I₂ : ModelWithCorners ℝ E₂ H₂)
  [TopologicalSpace M₂] [ChartedSpace H₂ M₂] [IsManifold I₂ ∞ M₂]

@[inherit_doc] local notation "𝓒" => ContMDiff (I₁.prod I₂) 𝓘(ℝ, F)

@[inherit_doc] local notation "𝓒_on" => ContMDiffOn (I₁.prod I₂) 𝓘(ℝ, F)

omit [FiniteDimensional ℝ E₁] [FiniteDimensional ℝ E₂]
  [IsManifold I₁ ∞ M₁] [IsManifold I₂ ∞ M₂] in

omit [FiniteDimensional ℝ E₂] [IsManifold I₂ ∞ M₂] in
theorem exists_contMDiff_of_convex₂ {P : M₁ → (M₂ → F) → Prop} [SigmaCompactSpace M₁] [T2Space M₁]
    (hP : ∀ x, Convex ℝ {f | P x f}) {n : ℕ∞}
    (hP' : ∀ x : M₁, ∃ U ∈ 𝓝 x, ∃ f : M₁ → M₂ → F,
      𝓒_on n (uncurry f) (U ×ˢ (univ : Set M₂)) ∧ ∀ y ∈ U, P y (f y)) :
    ∃ f : M₁ → M₂ → F, 𝓒 n (uncurry f) ∧ ∀ x, P x (f x) := by
  sorry

omit [FiniteDimensional ℝ E₂] in
theorem exists_contDiff_of_convex₂ {P : E₁ → (E₂ → F) → Prop} (hP : ∀ x, Convex ℝ {f | P x f})
    {n : ℕ∞}
    (hP' : ∀ x : E₁, ∃ U ∈ 𝓝 x, ∃ f : E₁ → E₂ → F,
      ContDiffOn ℝ n (uncurry f) (U ×ˢ (univ : Set E₂)) ∧ ∀ y ∈ U, P y (f y)) :
    ∃ f : E₁ → E₂ → F, ContDiff ℝ n (uncurry f) ∧ ∀ x, P x (f x) := by
  sorry

end

section

variable {ι : Type*}

variable {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] [FiniteDimensional ℝ E] {H : Type*}
  [TopologicalSpace H] {I : ModelWithCorners ℝ E H} {M : Type*} [TopologicalSpace M]
  [ChartedSpace H M] [IsManifold I ∞ M] [SigmaCompactSpace M] [T2Space M]

open TopologicalSpace

example {f : E → ℝ} (h : ∀ x : E, ∃ U ∈ 𝓝 x, ∃ ε : ℝ, ∀ x' ∈ U, 0 < ε ∧ ε ≤ f x') :
    ∃ f' : E → ℝ, ContDiff ℝ ∞ f' ∧ ∀ x, 0 < f' x ∧ f' x ≤ f x := by
  sorry

variable {F : Type*} [NormedAddCommGroup F] [NormedSpace ℝ F]

-- lemma exists_smooth_and_eqOn_aux1 {f : E → F} {ε : E → ℝ} (hf : continuous f)
--   (hε : continuous ε) (h2ε : ∀ x, 0 < ε x) (x₀ : E) :
--   ∃ U ∈ 𝓝 x₀, ∀ x ∈ U, dist (f x₀) (f x) < ε x :=
-- begin
--   have h0 : ∀ x, dist (f x) (f x) < ε x := λ x, by simp_rw [dist_self, h2ε],
--   refine ⟨_, (isOpen_lt (continuous_const.dist hf) hε).mem_nhds $ h0 x₀, λ x hx, hx⟩
-- end
-- lemma exists_smooth_and_eqOn_aux2 {n : ℕ∞} {f : E → F} {ε : E → ℝ} (hf : continuous f)
--   (hε : continuous ε) (h2ε : ∀ x, 0 < ε x)
--   {s : set E} (hs : is_closed s) (hfs : ∃ U ∈ 𝓝ˢ s, cont_diff_on ℝ n f U)
--   (x₀ : E) :
--   ∃ U ∈ 𝓝 x₀, ∀ x ∈ U, dist (f x₀) (f x) < ε x :=
-- begin
--   have h0 : ∀ x, dist (f x) (f x) < ε x := λ x, by simp_rw [dist_self, h2ε],
--   refine ⟨_, (isOpen_lt (continuous_const.dist hf) hε).mem_nhds $ h0 x₀, λ x hx, hx⟩
-- end
theorem exists_smooth_and_eqOn {n : ℕ∞} {f : E → F} {ε : E → ℝ} (hf : Continuous f)
    (hε : Continuous ε) (h2ε : ∀ x, 0 < ε x) {s : Set E} (hs : IsClosed s)
    (hfs : ∃ U ∈ 𝓝ˢ s, ContDiffOn ℝ n f U) :
    ∃ f' : E → F, ContDiff ℝ n f' ∧ (∀ x, dist (f' x) (f x) < ε x) ∧ EqOn f' f s := by
  sorry

end
