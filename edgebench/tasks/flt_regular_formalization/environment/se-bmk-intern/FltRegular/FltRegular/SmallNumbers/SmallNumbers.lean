module

public import Mathlib.NumberTheory.FLT.Basic
import FltRegular.SmallNumbers.Five.FLT5
import FltRegular.SmallNumbers.Seven.FLT7
import Mathlib.NumberTheory.FLT.Four
import Mathlib.NumberTheory.FLT.Three
import Mathlib.Tactic.NormNum.NatFactorial
import Mathlib.Tactic.NormNum.Prime

@[expose] public section

theorem FLT_small {n : ℕ} (hn : n ∈ Finset.Icc 3 7) : FermatLastTheoremFor n := by
  fin_cases hn
  · exact fermatLastTheoremThree
  · exact fermatLastTheoremFour
  · exact fermatLastTheoremFive
  · apply FermatLastTheoremFor.mono (show 3 ∣ 6 by decide)
    exact fermatLastTheoremThree
  · exact fermatLastTheoremSeven
