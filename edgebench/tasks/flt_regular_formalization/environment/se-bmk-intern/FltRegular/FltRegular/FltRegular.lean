module

public import Mathlib.NumberTheory.FLT.Basic
public import FltRegular.NumberTheory.RegularPrimes
import FltRegular.CaseI.Statement
import FltRegular.CaseII.Statement
import FltRegular.MayAssume.Lemmas

@[expose] public section

open FltRegular

/-- Fermat's last theorem for regular primes. -/
theorem flt_regular {p : ℕ} [Fact p.Prime] (hreg : IsRegularPrime p) (hodd : p ≠ 2) :
    FermatLastTheoremFor p := by
  sorry
