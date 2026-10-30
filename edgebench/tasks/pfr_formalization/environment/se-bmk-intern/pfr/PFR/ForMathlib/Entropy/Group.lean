module

public import PFR.ForMathlib.Entropy.Basic
public import PFR.ForMathlib.Entropy.Kernel.Group

public section

open Function MeasureTheory Measure Real
open scoped ENNReal NNReal Topology ProbabilityTheory

universe uΩ uS uT uU
variable {Ω : Type uΩ} {G : Type uS} {T : Type uT} {U : Type uU} [mΩ : MeasurableSpace Ω]
  [Countable G] [Countable T] [Countable U]
  [hG : MeasurableSpace G] [MeasurableSpace T] [MeasurableSpace U]
  [MeasurableSingletonClass G] [MeasurableSingletonClass T] [MeasurableSingletonClass U]
  [Group G] {X Y : Ω → G} {μ : Measure Ω}

namespace ProbabilityTheory
section entropy

@[to_additive (attr := simp)]
lemma entropy_mul_const (hX : Measurable X) (c : G) :
    H[X * fun _ ↦ c; μ] = H[X ; μ] := by
  sorry

/-- `H[Y * X, Y] = H[X, Y]` -/
@[to_additive /-- `H[Y + X, Y] = H[X, Y]` -/]
lemma entropy_mul_left (hX : Measurable X) (hY : Measurable Y) (μ : Measure Ω) :
    H[⟨Y * X, Y⟩; μ] = H[⟨X, Y⟩ ; μ] := by
  sorry

/-- `H[X * Y, Y] = H[X, Y]` -/
@[to_additive /-- `H[X + Y, Y] = H[X, Y]` -/]
lemma entropy_mul_left' (hX : Measurable X) (hY : Measurable Y) (μ : Measure Ω) :
    H[⟨X * Y, Y⟩; μ] = H[⟨X, Y⟩ ; μ] := by
  sorry

/-- `H[X, Y⁻¹] = H[X, Y]` -/
@[to_additive /-- `H[X, -Y] = H[X, Y]` -/]
lemma entropy_inv_right (hX : Measurable X) (hY : Measurable Y) (μ : Measure Ω) :
    H[⟨X, Y⁻¹⟩; μ] = H[⟨X, Y⟩ ; μ] := by
  sorry

/-- `H[X⁻¹, Y] = H[X, Y]` -/
@[to_additive /-- `H[-X, Y] = H[X, Y]` -/]
lemma entropy_inv_left (hX : Measurable X) (hY : Measurable Y) (μ : Measure Ω) :
    H[⟨X⁻¹, Y⟩; μ] = H[⟨X, Y⟩ ; μ] := by
  sorry

/-- `H[Y / X, Y] = H[X, Y]` -/
@[to_additive /-- `H[Y - X, Y] = H[X, Y]` -/]
lemma entropy_div_left (hX : Measurable X) (hY : Measurable Y) (μ : Measure Ω) :
    H[⟨Y / X, Y⟩; μ] = H[⟨X, Y⟩ ; μ] := by
  sorry

/-- `H[X / Y, Y] = H[X, Y]` -/
@[to_additive /-- `H[X - Y, Y] = H[X, Y]` -/]
lemma entropy_div_left' (hX : Measurable X) (hY : Measurable Y) (μ : Measure Ω) :
    H[⟨X / Y, Y⟩; μ] = H[⟨X, Y⟩ ; μ] := by
  sorry

/-- `H[X / Y] = H[Y / X]` -/
@[to_additive /-- `H[X - Y] = H[Y - X]` -/]
lemma entropy_div_comm {Y : Ω → G} (hX : Measurable X) (hY : Measurable Y) :
    H[X / Y ; μ] = H[Y / X ; μ] := by
  sorry

/-- `max(H[X | Z], H[Y | Z]) - I[X : Y | Z] ≤ H[X / Y | Z]` -/
@[to_additive /-- `max(H[X | Z], H[Y | Z]) - I[X : Y | Z] ≤ H[X - Y | Z]` -/]
lemma max_condEntropy_sub_condMutualInfo_le_condEntropy_div [FiniteRange X] [FiniteRange Y]
    {Z : Ω → T} (hX : Measurable X) (hY : Measurable Y) (hZ : Measurable Z)
    [IsProbabilityMeasure μ] [FiniteRange Z] :
    (max H[X | Z ; μ] H[Y | Z ; μ]) - I[X : Y | Z ; μ] ≤ H[X / Y | Z ; μ] := by
  sorry

end entropy

section condEntropy
variable [IsFiniteMeasure μ] [FiniteRange Y]

end condEntropy

section mutualInfo

variable [FiniteRange X] [FiniteRange Y]

/-- `I[X : X * Y] = H[X * Y] - H[Y]` iff `X, Y` are independent. -/
@[to_additive /-- `I[X : X + Y] = H[X + Y] - H[Y]` iff `X, Y` are independent. -/]
lemma mutualInfo_mul_right (hX : Measurable X) (hY : Measurable Y) {μ : Measure Ω}
    [IsProbabilityMeasure μ] (h : IndepFun X Y μ) :
    I[X : X * Y ; μ] = H[X * Y ; μ] - H[Y ; μ] := by
  sorry

end mutualInfo

section IsProbabilityMeasure
variable [IsProbabilityMeasure μ] {Y : Ω → G} [FiniteRange X] [FiniteRange Y]

/-- `H[X] - I[X : Y] ≤ H[X * Y]` -/
@[to_additive /-- `H[X] - I[X : Y] ≤ H[X + Y]` -/]
lemma entropy_sub_mutualInfo_le_entropy_mul (hX : Measurable X) (hY : Measurable Y) :
    H[X ; μ] - I[X : Y ; μ] ≤ H[X * Y ; μ] := by
  sorry

/-- `H[Y] - I[X : Y] ≤ H[X * Y]` -/
@[to_additive /-- `H[Y] - I[X : Y] ≤ H[X + Y]` -/]
lemma entropy_sub_mutualInfo_le_entropy_mul' (hX : Measurable X) (hY : Measurable Y) :
    H[Y ; μ] - I[X : Y ; μ] ≤ H[X * Y ; μ] := by
  sorry

/-- `H[X] - I[X : Y] ≤ H[X / Y]` -/
@[to_additive /-- `H[X] - I[X : Y] ≤ H[X - Y]` -/]
lemma entropy_sub_mutualInfo_le_entropy_div (hX : Measurable X) (hY : Measurable Y) :
    H[X ; μ] - I[X : Y ; μ] ≤ H[X / Y ; μ] := by
  sorry

/-- `H[Y] - I[X : Y] ≤ H[X / Y]` -/
@[to_additive /-- `H[Y] - I[X : Y] ≤ H[X - Y]` -/]
lemma entropy_sub_mutualInfo_le_entropy_div' (hX : Measurable X) (hY : Measurable Y) :
    H[Y ; μ] - I[X : Y ; μ] ≤ H[X / Y ; μ] := by
  sorry

/-- `max(H[X], H[Y]) - I[X : Y] ≤ H[X * Y]` -/
@[to_additive /-- `max(H[X], H[Y]) - I[X : Y] ≤ H[X + Y]` -/]
lemma max_entropy_sub_mutualInfo_le_entropy_mul (hX : Measurable X) (hY : Measurable Y) :
    max H[X ; μ] H[Y ; μ] - I[X : Y ; μ] ≤ H[X * Y ; μ] := by
  sorry

/-- `max(H[X], H[Y]) - I[X : Y] ≤ H[X / Y]` -/
@[to_additive /-- `max(H[X], H[Y]) - I[X : Y] ≤ H[X - Y]` -/]
lemma max_entropy_sub_mutualInfo_le_entropy_div (hX : Measurable X) (hY : Measurable Y) :
    max H[X ; μ] H[Y ; μ] - I[X : Y ; μ] ≤ H[X / Y ; μ] := by
  sorry

/-- `max(H[X | Z], H[Y | Z]) - I[X : Y | Z] ≤ H[X * Y | Z]` -/
@[to_additive /-- `max(H[X | Z], H[Y | Z]) - I[X : Y | Z] ≤ H[X + Y | Z]` -/]
lemma max_condEntropy_sub_condMutualInfo_le_condEntropy_mul {Z : Ω → T} [FiniteRange Z]
    (hX : Measurable X) (hY : Measurable Y) (hZ : Measurable Z) :
    max H[X | Z ; μ] H[Y | Z ; μ] - I[X : Y | Z ; μ] ≤ H[X * Y | Z ; μ] := by
  sorry

/-- If `X, Y` are independent, then `max(H[X], H[Y]) ≤ H[X * Y]`. -/
@[to_additive /-- If `X, Y` are independent, then `max(H[X], H[Y]) ≤ H[X + Y]` -/]
lemma max_entropy_le_entropy_mul (hX : Measurable X) (hY : Measurable Y) (h : IndepFun X Y μ) :
    max H[X ; μ] H[Y ; μ] ≤ H[X * Y ; μ] := by
  sorry

/-- If `X, Y` are independent, then `max(H[X], H[Y]) ≤ H[X / Y]`. -/
@[to_additive /-- If `X, Y` are independent, then `max(H[X], H[Y]) ≤ H[X - Y]`. -/]
lemma max_entropy_le_entropy_div (hX : Measurable X) (hY : Measurable Y) (h : IndepFun X Y μ) :
    max H[X ; μ] H[Y ; μ] ≤ H[X / Y ; μ] := by
  sorry

/-- If `X₁, ..., Xₙ` are independent and `s ⊆ {1, ..., n}`, then for all `i ∈ s`,
`H[Xᵢ] ≤ H[∏ j ∈ s, Xⱼ]`. -/
@[to_additive /-- If `X₁, ..., Xₙ` are independent and `s ⊆ {1, ..., n}`, then for all `i ∈ s`,
`H[Xᵢ] ≤ H[∑ j ∈ s, Xⱼ]`. -/]
lemma max_entropy_le_entropy_prod {G : Type*} [Countable G] [hG : MeasurableSpace G]
    [MeasurableSingletonClass G] [CommGroup G] [MeasurableMul₂ G]
    {I : Type*} {s : Finset I} {i₀ : I} (hi₀ : i₀ ∈ s) {X : I → Ω → G} [∀ i, FiniteRange (X i)]
    (hX : (i : I) → Measurable (X i)) (h_indep : iIndepFun X μ) :
    H[X i₀ ; μ] ≤ H[∏ i ∈ s, X i ; μ] := by
  sorry

end IsProbabilityMeasure
end ProbabilityTheory
