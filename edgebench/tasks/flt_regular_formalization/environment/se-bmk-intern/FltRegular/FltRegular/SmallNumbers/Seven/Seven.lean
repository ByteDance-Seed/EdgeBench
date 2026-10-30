module

public import Mathlib.NumberTheory.NumberField.Cyclotomic.Basic
import FltRegular.SmallNumbers.Cyclotomic
import FltRegular.SmallNumbers.OrderOf
import Mathlib.Tactic.NormNum.NatFactorial
import Mathlib.Tactic.NormNum.Prime

@[expose] public section

open NumberField Module NumberField.InfinitePlace Nat Real RingOfIntegers Finset Multiset
  IsCyclotomicExtension.Rat Polynomial cyclotomic UniqueFactorizationMonoid

variable {K : Type*} [Field K] [NumberField K]

local notation "M " K:70 => (4 / π) ^ nrComplexPlaces K *
  ((finrank ℚ K)! / (finrank ℚ K) ^ (finrank ℚ K) * √|discr K|)

instance Nat.fact_prime_seven : Fact (Nat.Prime 7) :=
  ⟨prime_seven⟩

variable [IsCyclotomicExtension {7} ℚ K]

theorem M7 : ⌊(M K)⌋₊ = 4 := by
  sorry

theorem cyclotomic_7 : cyclotomic 7 ℤ =
    X^6 + X^5 + X^4 + X^3 + X^2 + X + 1 := by
  simp [cyclotomic_prime, sum_range_succ]
  ring

set_option linter.unnecessarySeqFocus false in
set_option linter.flexible false in
set_option linter.style.longLine false in
set_option linter.unusedTactic false in
set_option linter.unreachableTactic false in
variable (K) in
theorem Rat.seven_pid : IsPrincipalIdealRing (𝓞 K) := by
  sorry
