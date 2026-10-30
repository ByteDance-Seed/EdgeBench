import Mathlib.Analysis.InnerProductSpace.Projection.Submodule

noncomputable section

open scoped RealInnerProductSpace Topology

open Submodule Function Set Filter

section GeneralStuff

-- Things in this section go to other files
@[simp]
theorem forall_mem_span_singleton {R M : Type*} [CommRing R] [AddCommGroup M] [Module R M]
    (P : M → Prop) (u : M) : (∀ x ∈ span R ({u} : Set M), P x) ↔ ∀ t : R, P (t • u) := by
  sorry

open scoped Pointwise

@[simp]
theorem Field.exists_unit {𝕜 : Type*} [Field 𝕜] (P : 𝕜 → Prop) :
    (∃ u : 𝕜ˣ, P u) ↔ ∃ u : 𝕜, u ≠ 0 ∧ P u := by
  sorry

end GeneralStuff

variable {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E] --[CompleteSpace E]

/-- The line (one-dimensional submodule of `E`) spanned by `x : E`. -/
@[reducible] def spanLine (x : E) : Submodule ℝ E := Submodule.span ℝ ({x} : Set E)

@[inherit_doc] local notation "Δ" => spanLine

/-- The orthogonal complement of the line spanned by `x : E`. -/
@[reducible] def spanOrthogonal (x : E) : Submodule ℝ E := (Δ x)ᗮ

/-- The orthogonal projection to the complement of `span x`. -/
@[reducible] def projSpanOrthogonal (x : E) :=
  orthogonalProjection (Submodule.span ℝ ({x} : Set E))ᗮ

@[inherit_doc] local notation "{." x "}ᗮ" => spanOrthogonal x

@[inherit_doc] local notation "pr[" x "]ᗮ" => projSpanOrthogonal x

variable (u v : E)

variable {x₀ x : E}

@[simp]
theorem mem_orthogonal_span_singleton_iff {x₀ x : E} : x ∈ {.x₀}ᗮ ↔ ⟪x₀, x⟫ = 0 := by
  sorry

theorem coe_orthogonalProjection_orthogonal_singleton {x y : E} :
    (pr[x]ᗮ y : E) = y - (⟪x, y⟫ / ⟪x, x⟫) • x := by
  sorry

theorem foo {x₀ x : E} (h : ⟪x₀, x⟫ ≠ 0) (y : E) (hy : y ∈ {.x₀}ᗮ) :
    (pr[x]ᗮ y : E) - (⟪x₀, pr[x]ᗮ y⟫ / ⟪x₀, x⟫) • x = y := by
  sorry

attribute [fun_prop] Continuous.inner

/-- Given two non-orthogonal vectors in an inner product space,
`orthogonal_projection_orthogonal_line_iso` is the continuous linear equivalence between their
orthogonal complements obtained from orthogonal projection. -/
def orthogonalProjectionOrthogonalLineIso {x₀ x : E} (h : ⟪x₀, x⟫ ≠ 0) : {.x₀}ᗮ ≃L[ℝ] {.x}ᗮ :=
  {
    pr[x]ᗮ.comp (subtypeL {.x₀}ᗮ) with
    invFun := fun y ↦
      ⟨y - (⟪x₀, y⟫ / ⟪x₀, x⟫) • x, by
        rw [mem_orthogonal_span_singleton_iff, inner_sub_right, inner_smul_right]
        simp [h]⟩
    left_inv := by
      rintro ⟨y, hy⟩
      ext
      exact foo h y hy
    right_inv := by
      rintro ⟨y, hy⟩
      ext
      dsimp
      rw [map_sub, map_smul, starProjection_apply, starProjection_apply,
        orthogonalProjection_orthogonalComplement_singleton_eq_zero, coe_zero,
        ← starProjection_apply, smul_zero, sub_zero, starProjection_eq_self_iff.mpr hy]
    continuous_toFun := (pr[x]ᗮ.comp (subtypeL {.x₀}ᗮ)).continuous
    continuous_invFun := by fun_prop }

variable (E)

-- Is this really missing??

theorem NormedSpace.continuousAt_iff' {E F : Type*} [SeminormedAddCommGroup E]
    [SeminormedAddCommGroup F] (f : E → F) (x : E) :
    ContinuousAt f x ↔ ∀ ε > 0, ∃ δ > 0, ∀ y, ‖y - x‖ ≤ δ → ‖f y - f x‖ ≤ ε := by
  sorry

-- Is this really missing??
theorem NormedSpace.continuous_iff {E F : Type*} [SeminormedAddCommGroup E]
    [SeminormedAddCommGroup F] (f : E → F) :
    Continuous f ↔ ∀ x, ∀ ε > 0, ∃ δ > 0, ∀ y, ‖y - x‖ < δ → ‖f y - f x‖ < ε := by
  sorry

theorem NormedSpace.continuous_iff' {E F : Type*} [SeminormedAddCommGroup E]
    [SeminormedAddCommGroup F] (f : E → F) :
    Continuous f ↔ ∀ x, ∀ ε > 0, ∃ δ > 0, ∀ y, ‖y - x‖ ≤ δ → ‖f y - f x‖ ≤ ε := by
  sorry

variable {E}

attribute [fun_prop] continuous_norm' continuous_norm

