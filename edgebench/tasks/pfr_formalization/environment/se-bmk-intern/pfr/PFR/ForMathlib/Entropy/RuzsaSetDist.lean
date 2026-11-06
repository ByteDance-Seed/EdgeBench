module

public import PFR.ForMathlib.Entropy.RuzsaDist

public section

open MeasureTheory Pointwise Real

namespace ProbabilityTheory

variable {G : Type*} [Countable G] [MeasurableSpace G] [MeasurableSingletonClass G]
  [AddCommGroup G]

/-- The Ruzsa distance between two subsets `A`, `B` of a group `G` is defined to be the Ruzsa
distance between their uniform probability distributions. Is only intended for use when `A`, `B` are
finite and non-empty. -/
noncomputable def setRuzsaDist (A B : Set G) : ℝ := Kernel.rdistm (uniformOn A) (uniformOn B)

@[inherit_doc setRuzsaDist]
notation3:max "dᵤ[" A " # " B "]" => setRuzsaDist A B

/-- Ruzsa distance between sets is nonnegative. -/
lemma setRuzsaDist_nonneg (A B : Set G) [hA : Finite A] [hB : Finite B] [Nonempty A] [Nonempty B] :
    0 ≤ dᵤ[A # B] := by
  sorry

/-- Ruzsa distance between sets is symmetric. -/
lemma setRuzsaDist_symm (A B : Set G) [hA : Finite A] [hB : Finite B] [Nonempty A] [Nonempty B] :
    dᵤ[A # B] = dᵤ[B # A] := by
  sorry

/-- Ruzsa distance between sets obeys the triangle inequality. -/
lemma setRuzsaDist_triangle (A B C : Set G) [hA : Finite A] [hB : Finite B] [hC : Finite C]
    [Nonempty A] [Nonempty B] [Nonempty C] : dᵤ[A # C] ≤ dᵤ[A # B] + dᵤ[B # C] := by
  sorry

end ProbabilityTheory
