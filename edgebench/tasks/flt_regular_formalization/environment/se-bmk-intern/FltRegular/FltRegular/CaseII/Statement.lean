module

public import FltRegular.NumberTheory.Cyclotomic.UnitLemmas
public import FltRegular.NumberTheory.RegularPrimes
import FltRegular.CaseII.InductionStep
import FltRegular.NumberTheory.Cyclotomic.MoreLemmas
import Mathlib.NumberTheory.NumberField.Cyclotomic.Basic
import Mathlib.Order.CompletePartialOrder

@[expose] public section

open scoped nonZeroDivisors NumberField
open Polynomial

variable {K : Type} {p : ℕ} [hpri : Fact p.Prime] [Field K] [NumberField K]
  [IsCyclotomicExtension {p} ℚ K] (hp : p ≠ 2) [Fintype (ClassGroup (𝓞 K))]
  (hreg : p.Coprime <| Fintype.card <| ClassGroup (𝓞 K))

variable {ζ : K} (hζ : IsPrimitiveRoot ζ p)

namespace FltRegular

lemma not_exists_Int_solution {p : ℕ} [hpri : Fact (Nat.Prime p)] (hreg : IsRegularPrime p)
    (hodd : p ≠ 2) : ¬∃ (x y z : ℤ), ¬↑p ∣ y ∧ ↑p ∣ z ∧ z ≠ 0 ∧ x ^ p + y ^ p = z ^ p := by
  sorry


/-- CaseII. -/
theorem caseII {a b c : ℤ} {p : ℕ} [hpri : Fact p.Prime] (hreg : IsRegularPrime p) (hodd : p ≠ 2)
    (hprod : a * b * c ≠ 0) (hgcd : ({a, b, c} : Finset ℤ).gcd id = 1)
    (caseII : ↑p ∣ a * b * c) : a ^ p + b ^ p ≠ c ^ p := by
  sorry

end FltRegular
