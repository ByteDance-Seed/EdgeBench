module

public import PFR.Mathlib.Probability.Independence.Basic
public import PFR.ForMathlib.Pair

public section

open MeasureTheory ProbabilityTheory

namespace ProbabilityTheory.iIndepFun

variable {Ω : Type*} [MeasureSpace Ω]
  {G : Type*} [hG : MeasurableSpace G]

variable {Z₁ Z₂ Z₃ : Ω → G} (h_indep : iIndepFun ![Z₁, Z₂, Z₃])

include h_indep

lemma reindex_three_abc :
    iIndepFun ![Z₁, Z₂, Z₃] := by
  sorry

lemma reindex_three_acb :
    iIndepFun ![Z₁, Z₃, Z₂] := by
  sorry

lemma reindex_three_bca :
    iIndepFun ![Z₂, Z₃, Z₁] := by
  sorry

lemma reindex_three_cab :
    iIndepFun ![Z₃, Z₁, Z₂] := by
  sorry

lemma reindex_three_cba :
    iIndepFun ![Z₃, Z₂, Z₁] := by
  sorry

private abbrev κ : Fin 2 → Type
  | 0 => Fin 1
  | 1 => Fin 2

private def κ_equiv : (Σ i, κ i) ≃ Fin 3 where
  toFun := fun x ↦ match x with
    | Sigma.mk 0 _ => 0
    | Sigma.mk 1 ⟨0, _⟩ => 1
    | Sigma.mk 1 ⟨1, _⟩ => 2
  invFun := ![Sigma.mk 0 ⟨0, zero_lt_one⟩,
    Sigma.mk 1 ⟨0, zero_lt_two⟩, Sigma.mk 1 ⟨1, one_lt_two⟩]
  left_inv := by rintro ⟨i, j⟩; fin_cases i <;> fin_cases j <;> rfl
  right_inv i := by fin_cases i <;> rfl

private instance fintype_kappa : ∀ (i : Fin 2), Fintype (κ i)
  | 0 | 1 => inferInstanceAs (Fintype (Fin _))

variable (G) in
private abbrev self_or_prod : Fin 2 → Type _
  | 0 => G
  | 1 => G × G

end ProbabilityTheory.iIndepFun
