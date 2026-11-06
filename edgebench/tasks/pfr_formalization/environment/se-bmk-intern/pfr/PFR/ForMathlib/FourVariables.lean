module

public import PFR.Mathlib.Probability.Independence.Basic

public section

open MeasureTheory ProbabilityTheory

namespace ProbabilityTheory.iIndepFun

variable {Ω : Type*} [MeasureSpace Ω]
  {G : Type*} [hG : MeasurableSpace G]

variable {Z₁ Z₂ Z₃ Z₄ : Ω → G} (h_indep : iIndepFun ![Z₁, Z₂, Z₃, Z₄])

include h_indep

lemma reindex_four_dabc :
    iIndepFun ![Z₄, Z₁, Z₂, Z₃] := by
  sorry

lemma reindex_four_dbac :
    iIndepFun ![Z₄, Z₂, Z₁, Z₃] := by
  sorry

lemma reindex_four_dbca :
    iIndepFun ![Z₄, Z₂, Z₃, Z₁] := by
  sorry

private abbrev κ : Fin 3 → Type
  | 0 | 1 => Fin 1
  | 2   => Fin 2

private def κ_equiv : (Σ i, κ i) ≃ Fin 4 where
  toFun := fun x ↦ match x with
    | Sigma.mk 0 _ => 0
    | Sigma.mk 1 _ => 1
    | Sigma.mk 2 ⟨0, _⟩ => 2
    | Sigma.mk 2 ⟨1, _⟩ => 3
  invFun := ![Sigma.mk 0 ⟨0, zero_lt_one⟩, Sigma.mk 1 ⟨0, zero_lt_one⟩,
    Sigma.mk 2 ⟨0, zero_lt_two⟩, Sigma.mk 2 ⟨1, one_lt_two⟩]
  left_inv := by rintro ⟨i, j⟩; fin_cases i <;> fin_cases j <;> rfl
  right_inv i := by fin_cases i <;> rfl

private instance fintype_kappa : ∀ (i : Fin 3), Fintype (κ i)
  | 0 | 1 | 2 => inferInstanceAs (Fintype (Fin _))

end ProbabilityTheory.iIndepFun
