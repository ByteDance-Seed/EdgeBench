module

public import FltRegular.NumberTheory.RegularPrimes
public import Mathlib.NumberTheory.FLT.Basic
import FltRegular.FltRegular
import FltRegular.SmallNumbers.Seven.Seven
import Mathlib.Tactic.NormNum.NatFactorial
import Mathlib.Tactic.NormNum.Prime

@[expose] public section

open Nat NumberField IsCyclotomicExtension

theorem isRegularPrime_seven :
    haveI : Fact (Nat.Prime 7) := ⟨Nat.prime_seven⟩
    IsRegularPrime 7 := by
  sorry

theorem fermatLastTheoremSeven : FermatLastTheoremFor 7 := by
  sorry
