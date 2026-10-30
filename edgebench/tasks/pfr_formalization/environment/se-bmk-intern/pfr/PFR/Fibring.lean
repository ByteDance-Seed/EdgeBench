module

public import PFR.ForMathlib.Entropy.RuzsaDist

/-!
# The fibring identity

The proof of the fibring identity, which is a key component of the proof of PFR.

## Main statement

* `sum_of_rdist_eq`: If $Y_1,Y_2,Y_3,Y_4$ are independent, then $d[Y_1; Y_2] + d[Y_3; Y_4]$ is equal
  to the sum of $$d[Y_1+Y_3; Y_2+Y_4] + d[Y_1|Y_1+Y_3; Y_2|Y_2+Y_4] $$ and
  $$ I[Y_1+Y_2 : Y_2 + Y_4 | Y_1+Y_2+Y_3+Y_4].$$

-/

public section

open MeasureTheory ProbabilityTheory Function

section GeneralFibring

-- $\pi : H \to H'$ is a homomorphism between additive groups.
variable {H : Type*} [AddCommGroup H] [Countable H] [hH : MeasurableSpace H]
  [MeasurableSingletonClass H]
  {H' : Type*} [AddCommGroup H'] [Countable H'] [hH' : MeasurableSpace H']
  [MeasurableSingletonClass H']
  (π : H →+ H')
variable {Ω Ω' : Type*} [mΩ : MeasurableSpace Ω] [mΩ' : MeasurableSpace Ω']
  {μ : Measure Ω} {μ' : Measure Ω'} [IsProbabilityMeasure μ] [IsProbabilityMeasure μ']

/-- If $Z_1, Z_2$ are independent, then $d[Z_1; Z_2]$ is equal to
$$ d[\pi(Z_1);\pi(Z_2)] + d[Z_1|\pi(Z_1); Z_2 |\pi(Z_2)]$$
plus
$$I( Z_1 - Z_2 : (\pi(Z_1), \pi(Z_2)) | \pi(Z_1 - Z_2) ).$$
-/
lemma rdist_of_indep_eq_sum_fibre {Z_1 Z_2 : Ω → H} (h : IndepFun Z_1 Z_2 μ)
    (h1 : Measurable Z_1) (h2 : Measurable Z_2) [FiniteRange Z_1] [FiniteRange Z_2] :
    d[Z_1; μ # Z_2; μ] = d[π ∘ Z_1; μ # π ∘ Z_2; μ] + d[Z_1|π∘Z_1; μ # Z_2|π∘Z_2; μ]
      + I[Z_1-Z_2 : ⟨π∘Z_1, π∘Z_2⟩ | π∘(Z_1 - Z_2); μ] := by
  sorry

lemma rdist_le_sum_fibre {Z_1 : Ω → H} {Z_2 : Ω' → H}
  (h1 : Measurable Z_1) (h2 : Measurable Z_2) [FiniteRange Z_1] [FiniteRange Z_2] :
  d[π ∘ Z_1; μ # π ∘ Z_2; μ'] + d[Z_1|π∘Z_1; μ # Z_2|π∘Z_2; μ'] ≤ d[Z_1; μ # Z_2; μ'] := by
  sorry

/-- \[d[X;Y]\geq d[\pi(X);\pi(Y)].\] -/
lemma rdist_of_hom_le {Z_1 : Ω → H} {Z_2 : Ω' → H}
    (h1 : Measurable Z_1) (h2 : Measurable Z_2) [FiniteRange Z_1] [FiniteRange Z_2] :
    d[π ∘ Z_1; μ # π ∘ Z_2; μ'] ≤ d[Z_1; μ # Z_2; μ'] := by
  sorry

end GeneralFibring

variable {G : Type*} [AddCommGroup G] [Finite G] [hG : MeasurableSpace G]
  [MeasurableSingletonClass G]
variable {Ω : Type*} [mΩ : MeasurableSpace Ω] {μ : Measure Ω} [IsProbabilityMeasure μ]

/-- Let $Y_1,Y_2,Y_3$ and $Y_4$ be independent $G$-valued random variables.
  Then
$$d[Y_1-Y_3; Y_2-Y_4] + d[Y_1|Y_1-Y_3; Y_2|Y_2-Y_4] $$
$$ + I[Y_1-Y_2 : Y_2 - Y_4 | Y_1-Y_2-Y_3+Y_4] = d[Y_1; Y_2] + d[Y_3; Y_4].$$
-/
lemma sum_of_rdist_eq (Y : Fin 4 → Ω → G) (h_indep : iIndepFun Y μ)
  (h_meas : ∀ i, Measurable (Y i)) :
    d[Y 0; μ # Y 1; μ] + d[Y 2; μ # Y 3; μ]
      = d[(Y 0) - (Y 2); μ # (Y 1) - (Y 3); μ]
        + d[Y 0 | (Y 0) - (Y 2); μ # Y 1 | (Y 1) - (Y 3); μ]
        + I[(Y 0) - (Y 1) : (Y 1) - (Y 3) | (Y 0) - (Y 1) - (Y 2) + (Y 3); μ] := by
  sorry

/-- Let $Y_1,Y_2,Y_3$ and $Y_4$ be independent $G$-valued random variables.
  Then
$$d[Y_1+Y_3; Y_2+Y_4] + d[Y_1|Y_1+Y_3; Y_2|Y_2+Y_4] $$
$$ + I[Y_1+Y_2 : Y_2 + Y_4 | Y_1+Y_2+Y_3+Y_4] = d[Y_1; Y_2] + d[Y_3; Y_4].$$
-/
lemma sum_of_rdist_eq_char_2
  [Module (ZMod 2) G] (Y : Fin 4 → Ω → G) (h_indep : iIndepFun Y μ)
  (h_meas : ∀ i, Measurable (Y i)) :
    d[Y 0; μ # Y 1; μ] + d[Y 2; μ # Y 3; μ]
      = d[(Y 0) + (Y 2); μ # (Y 1) + (Y 3); μ]
        + d[Y 0 | (Y 0) + (Y 2); μ # Y 1 | (Y 1) + (Y 3); μ]
        + I[(Y 0) + (Y 1) : (Y 1) + (Y 3) | (Y 0) + (Y 1) + (Y 2) + (Y 3); μ] := by
  sorry

lemma sum_of_rdist_eq_char_2' [Module (ZMod 2) G] (X Y X' Y' : Ω → G)
  (h_indep : iIndepFun ![X, Y, X', Y'] μ)
  (hX : Measurable X) (hY : Measurable Y) (hX' : Measurable X') (hY' : Measurable Y') :
  d[X ; μ # Y ; μ] + d[X' ; μ # Y' ; μ]
    = d[X + X' ; μ # Y + Y' ; μ] + d[X | X + X' ; μ # Y | Y + Y' ; μ]
      + I[X + Y : Y + Y' | X + Y + X' + Y' ; μ] := by
  sorry
