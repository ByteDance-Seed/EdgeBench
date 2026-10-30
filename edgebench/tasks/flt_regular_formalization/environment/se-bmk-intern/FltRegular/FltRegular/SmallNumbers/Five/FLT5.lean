module

public import FltRegular.NumberTheory.RegularPrimes
public import Mathlib.NumberTheory.FLT.Basic
import FltRegular.FltRegular
import Mathlib.NumberTheory.NumberField.Cyclotomic.PID

@[expose] public section

open Nat NumberField IsCyclotomicExtension

theorem isRegularPrime_five :
    haveI : Fact (Nat.Prime 5) := ⟨Nat.prime_five⟩
    IsRegularPrime 5 := by
  rw [IsRegularPrime, IsRegularNumber]
  convert coprime_one_right _
  exact classNumber_eq_one_iff.2 (Rat.five_pid (CyclotomicField _ ℚ))

theorem fermatLastTheoremFive : FermatLastTheoremFor 5 := by
  have : Fact (Nat.Prime 5) := ⟨Nat.prime_five⟩
  exact flt_regular isRegularPrime_five (by omega)
