import PFR.ApproxHomPFR
import PFR.ImprovedPFR
import PFR.WeakPFR
import PFR.RhoFunctional
import PFR.TorsionEndgame

section PFR

open Pointwise

variable {G : Type*} [AddCommGroup G] [Module (ZMod 2) G] [Fintype G]

variable {G' : Type*} [AddCommGroup G'] [Module (ZMod 2) G'] [Fintype G']

/-- A self-contained version of the PFR conjecture using only Mathlib definitions. -/
example {A : Set G} {K : ℝ} (h₀A : A.Nonempty) (hA : Nat.card (A + A) ≤ K * Nat.card A) :
    ∃ (H : Submodule (ZMod 2) G) (c : Set G),
      Nat.card c < 2 * K ^ 12 ∧ Nat.card H ≤ Nat.card A ∧ A ⊆ c + H := by
  sorry

#print axioms PFR_conjecture

/-- The improved version -/
example {A : Set G} {K : ℝ} (h₀A : A.Nonempty) (hA : Nat.card (A + A) ≤ K * Nat.card A) :
    ∃ (H : Submodule (ZMod 2) G) (c : Set G),
      Nat.card c < 2 * K ^ 11 ∧ Nat.card H ≤ Nat.card A ∧ A ⊆ c + H := by
  sorry

#print axioms PFR_conjecture_improv

/-- The even more improved version -/
example {A : Set G} {K : ℝ} (h₀A : A.Nonempty) (hA : Nat.card (A + A) ≤ K * Nat.card A) :
    ∃ (H : Submodule (ZMod 2) G) (c : Set G),
      Nat.card c < 2 * K ^ 9 ∧ Nat.card H ≤ Nat.card A ∧ A ⊆ c + H := by
  sorry

#print axioms better_PFR_conjecture

/-- The homomorphism version of PFR. -/
example (f : G → G') (S : Set G') (hS : ∀ x y : G, f (x + y) - f x - f y ∈ S) :
    ∃ (φ : G →+ G') (T : Set G'), Nat.card T ≤ (Nat.card S)^10 ∧ ∀ x, f x - φ x ∈ T := by
  sorry

/-- The approximate homomorphism version of PFR -/
example (f : G → G') (K : ℝ) (hK : K > 0) [DecidableEq G']
    (hf : Finset.dens {x : G × G | f (x.1 + x.2) = f x.1 + f x.2} ≥ K⁻¹) :
    ∃ (φ : G →+ G') (c : G'),
      Nat.card {x : G | f x = φ x + c} ≥ (Nat.card G) / (2 ^ 144 * K ^ 122) := by
  sorry

/-- The bounded torsion version of PFR. -/
example [AddCommGroup G] [Finite G] {m : ℕ} (hm : m ≥ 2)
     (htorsion : ∀ x : G, m • x = 0) {A : Set G} [Finite A] {K : ℝ} (h₀A : A.Nonempty)
     (hA : Nat.card (A + A) ≤ K * A.ncard) :
     ∃ (H : AddSubgroup G) (c : Set G),
      Nat.card c < m * K ^ (256 * m ^ 3 + 1) ∧ (H : Set G).ncard ≤ A.ncard ∧ A ⊆ c + H := by
  sorry

#print axioms torsion_PFR

open Real

variable {H : Type*} [AddCommGroup H] [Module.Free ℤ H] [Module.Finite ℤ H]

/-- Weak PFR over the integers -/
example (A : Set H) [Finite A] (h'A : A.Nonempty) (K : ℝ)
    (hA : Nat.card (A - A) ≤ K * Nat.card A) :
    ∃ A' : Set H, A' ⊆ A ∧ (Nat.card A') ≥ K ^ (-17 : ℝ) * (Nat.card A) ∧
    AffineSpace.finrank ℤ A' ≤ (40 / log 2) * log K := by
  sorry

end PFR

section RealMeasure
-- some examples to showcase real-valued measures in a self-contained fashion.

open MeasureTheory ProbabilityTheory

variable {Ω : Type*} [MeasureSpace Ω] [IsProbabilityMeasure (ℙ : Measure Ω)]

/-- The probability measure ℙ, but taking values in the reals. Can be more convenient than
ENNReal-valued measures if one wishes to use operations such as subtraction. -/
local notation3 "ℙᵣ" => (ℙ : Measure Ω).real

example (E : Set Ω) : ℙᵣ E = (ℙ E).toReal := by
  sorry

example : ℙᵣ Set.univ = 1 := by
  sorry

example {A : Type*} [Fintype A] (E : A → Set Ω) : ℙᵣ (⋃ a, E a) ≤ ∑ a, ℙᵣ (E a) := by
  sorry

example {A : Type*} [Fintype A] (E : A → Set Ω) (hn : Pairwise fun x y ↦ Disjoint (E x) (E y))
    (h : ∀ i, MeasurableSet (E i)) : ℙᵣ (⋃ a, E a) = ∑ a, ℙᵣ (E a) := by
  sorry

/-- A simple example of applying real-valued subtraction. -/
example (E F : Set Ω) (h : NullMeasurableSet F ℙ) : ℙᵣ (E ∩ F) = ℙᵣ E - ℙᵣ (E \ F) := by
  sorry

example (E : Set Ω) : 0 ≤ ℙᵣ E ∧ ℙᵣ E ≤ 1 := by
  sorry

end RealMeasure

section Entropy
-- some examples to showcase Shannon entropy in a self-contained fashion. For simplicity we only
-- illustrate the notation for probability spaces with a canonical probability measure, but one can
-- also decouple the measure from the space if desired.

open MeasureTheory ProbabilityTheory

variable {Ω : Type*} [MeasureSpace Ω] [IsProbabilityMeasure (ℙ : Measure Ω)]

variable {S : Type*} [Fintype S] [Nonempty S] [MeasurableSpace S] [MeasurableSingletonClass S]
variable {T : Type*} [Fintype T] [Nonempty T] [MeasurableSpace T] [MeasurableSingletonClass T]
variable {U : Type*} [Fintype U] [Nonempty U] [MeasurableSpace U] [MeasurableSingletonClass U]

variable (X : Ω → S) (hX : Measurable X) (Y : Ω → T) (hY : Measurable Y) (Z : Ω → U)
  (hZ : Measurable Z)

/-- $H[X]$ is the Shannon entropy of $X$. -/
example : H[X] =
    - ∑ x, ((ℙ : Measure Ω).map X).real {x} * Real.log (((ℙ : Measure Ω).map X).real {x}) := by
  sorry

/-- $\langle X,Y \rangle$ is the random variable formed by pairing $X$ and $Y$. -/
example (ω : Ω) : (⟨X, Y⟩) ω = (X ω, Y ω) := by
  sorry

/-- $H[X|Y]$ is the conditional entropy of $X$ relative to $Y$. -/
example : H[X|Y] = H[⟨X,Y⟩] - H[Y] := by
  sorry

/-- $I[X:Y]$ is the mutual information between $X$ and $Y$. -/
example : I[X:Y] = H[X] + H[Y] - H[⟨X,Y⟩] := by
  sorry

/-- $I[X:Y|Z]$ is the conditional mutual information between $X$ and $Y$ relative to $Z$. -/
example : I[X:Y|Z] = H[X|Z] + H[Y|Z] - H[⟨X,Y⟩|Z] := by
  sorry

/-- Submodularity: conditional information is nonnegative. -/
example : 0 ≤ I[X : Y | Z] := by
  sorry

/-- Relation between conditional mutual information and conditional independence. -/
example : I[X : Y | Z] = 0 ↔ CondIndepFun X Y Z := by
  sorry

end Entropy

section RuzsaDistance
-- some examples to showcase Ruzsa distance in a self-contained fashion

open MeasureTheory ProbabilityTheory

variable {Ω : Type*} [MeasureSpace Ω] [IsProbabilityMeasure (ℙ : Measure Ω)]

variable {G : Type*} [hG : MeasurableSpace G] [MeasurableSingletonClass G] [AddCommGroup G]
  [MeasurableSub₂ G] [MeasurableAdd₂ G] [Fintype G]

variable (X : Ω → G) (hX : Measurable X) (Y : Ω → G) (hY : Measurable Y) (Z : Ω → G)
  (hZ : Measurable Z) (X' Y' : Ω → G)

/-- `d[X # Y]` is the Ruzsa distance when `X`, `Y` are independent. -/
example (h : IndepFun X Y) : d[X # Y] = H[X-Y] - H[X]/2 - H[Y]/2 := by
  sorry

/-- `d[X # Y]` depends only on the distribution of `X` and `Y`. -/
example (h1 : IdentDistrib X X') (h2 : IdentDistrib Y Y') : d[X # Y] = d[X' # Y'] := by
  sorry

/-- The Ruzsa triangle inequality. -/
example : d[X # Z] ≤ d[X # Y] + d[Y # Z] := by
  sorry

/-- The Kaimanovich-Vershik-Madiman inequality -/
example (h : iIndepFun ![X, Y, Z]) : H[X + Y + Z] - H[X + Y] ≤ H[Y + Z] - H[Y] := by
  sorry

/-- The entropic Balog--Szemeredi--Gowers inequality -/
example (h : Z = X + Y) :
    ((ℙ : Measure Ω).map Z)[fun z ↦ d[X ; ℙ[|Z ← z] # Y ; ℙ[|Z ← z]]]
      ≤ 3 * I[X : Y] + 2 * H[Z] - H[X] - H[Y] := by
  sorry

end RuzsaDistance

section Finiteness
-- some examples to showcase the Finiteness tactic

open ENNReal

example : (1:ℝ≥0∞) < ∞ := by
  sorry

example : (3:ℝ≥0∞) ≠ ∞ := by
  sorry

example (a : ℝ) (b : ℕ) : ENNReal.ofReal a + b < ∞ := by
  sorry

example {a : ℝ≥0∞} (ha : a ≠ ∞) : a + 3 < ∞ := by
  sorry
example {a : ℝ≥0∞} (ha : a < ∞) : a + 3 < ∞ := by
  sorry

example (a : ℝ) : (ENNReal.ofReal (1 + a ^ 2))⁻¹ < ∞ := by
  sorry

example {α : Type*} (f : α → ℕ) : ∀ i, (f i : ℝ≥0∞) ≠ ∞ := by
  sorry

open MeasureTheory

example {Ω Ω' : Type*} [MeasurableSpace Ω] (ν : Measure Ω) [IsFiniteMeasure ν] [MeasurableSpace Ω']
    (ν' : Measure Ω') [IsFiniteMeasure ν'] (E : Set (Ω × Ω')) :
    (ν.prod ν') E < ∞ := by
  sorry

end Finiteness

#print axioms approx_hom_pfr'
