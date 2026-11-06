import Mathlib.Tactic
import Analysis.Appendix_B_1

/-!
# Analysis I, Appendix B.2: The decimal representation of real numbers

An implementation of the decimal representation of Mathlib's real numbers {lean}`ℝ`.

This is separate from the way decimal numerals are already represented in Mathlib.  We also represent the integer part of the natural numbers just by {lean}`ℕ`, avoiding using the decimal representation from the
previous section, although we still retain the `AppendixB.Digit` class.
-/

namespace AppendixB

structure NNRealDecimal where
  intPart : ℕ
  fracPart : ℕ → Digit

open NNReal NNRealDecimal

#check mk

@[coe]
noncomputable def NNRealDecimal.toNNReal (d:NNRealDecimal) : NNReal :=
  d.intPart + ∑' i, (d.fracPart i) * (10:NNReal) ^ (-i-1:ℝ)

noncomputable instance NNRealDecimal.instCoeNNReal : Coe NNRealDecimal NNReal where
  coe := toNNReal

/-- Proposition B.2.2 -/
theorem NNRealDecimal.not_inj : (1:NNReal) = (mk 1 fun _ ↦ 0) ∧ (1:NNReal) = (mk 0 fun _ ↦ 9) := by
  sorry

inductive RealDecimal where
  | pos : NNRealDecimal → RealDecimal
  | neg : NNRealDecimal → RealDecimal

noncomputable instance RealDecimal.instCoeReal : Coe RealDecimal ℝ where
  coe := fun d ↦ match d with
    | RealDecimal.pos d => d.toNNReal
    | RealDecimal.neg d => -(d.toNNReal:ℝ)

theorem RealDecimal.surj (x:ℝ) : ∃ d:RealDecimal, x = d := by
  sorry

/-- Exercise B.2.2 -/
theorem RealDecimal.not_inj_one (d: RealDecimal) : (d:ℝ) = 1 ↔ (d = pos (mk 1 fun _ ↦ 0) ∨ d = pos (mk 0 fun _ ↦ 9)) := by
  sorry

/-- Exercise B.2.3 -/
abbrev TerminatingDecimal (x:ℝ) : Prop := ∃ (n:ℤ) (m:ℕ), x = n / (10:ℝ)^m

theorem RealDecimal.not_inj_terminating {x:ℝ} (hx: TerminatingDecimal x) : ∃ d₁ d₂:RealDecimal, d₁ ≠ d₂ ∧ ∀ d: RealDecimal, d = x ↔ d = d₁ ∨ d = d₂ := by
  sorry

theorem RealDecimal.inj_nonterminating {x:ℝ} (hx: ¬TerminatingDecimal x) : ∃! d:RealDecimal, d = x := by
  sorry

/-- Exercise B.2.4.  This is Corollary 8.3.4, but the intent is to rewrite the proof using the decimal system. -/
example : Uncountable ℝ := by
  sorry

end AppendixB
