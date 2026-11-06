module

public import FltRegular.NumberTheory.RegularPrimes
import FltRegular.CaseI.AuxLemmas
import FltRegular.MayAssume.Lemmas
import FltRegular.NumberTheory.Cyclotomic.CaseI
import Mathlib.NumberTheory.FLT.Three

@[expose] public section

open Finset Nat IsCyclotomicExtension Ideal Polynomial Int Basis FltRegular.CaseI

open scoped NumberField

namespace FltRegular

variable {p : ℕ}

namespace CaseI

/-- Statement of case I with additional assumptions. -/
def SlightlyEasier : Prop :=
  ∀ ⦃a b c : ℤ⦄ {p : ℕ} [Fact p.Prime], IsRegularPrime p → 5 ≤ p →
    ({a, b, c} : Finset ℤ).gcd id = 1 → ¬a ≡ b [ZMOD p] → ¬↑p ∣ a * b * c → a ^ p + b ^ p ≠ c ^ p

/-- Statement of case I. -/
def Statement : Prop :=
  ∀ ⦃a b c : ℤ⦄ {p : ℕ} [Fact p.Prime], IsRegularPrime p → ¬↑p ∣ a * b * c → a ^ p + b ^ p ≠ c ^ p

theorem may_assume : SlightlyEasier → Statement := by
  sorry

end CaseI

theorem ab_coprime {a b c : ℤ} (H : a ^ p + b ^ p = c ^ p) (hpzero : p ≠ 0)
    (hgcd : ({a, b, c} : Finset ℤ).gcd id = 1) : IsCoprime a b := by
  sorry



local notation "K" => CyclotomicField p ℚ

local notation "R" => 𝓞 K


variable [hpri : Fact p.Prime]


theorem is_principal {a b c : ℤ} {ζ : R} (hreg : IsRegularPrime p) (hp5 : 5 ≤ p)
    (hgcd : ({ a, b, c } : Finset ℤ).gcd id = 1) (caseI : ¬↑p ∣ a * b * c)
    (H : a ^ p + b ^ p = c ^ p) (hζ : IsPrimitiveRoot ζ p) :
    ∃ (u : Rˣ) (α : R), ↑u * α ^ p = ↑a + ζ * ↑b := by
  sorry

theorem ex_fin_div {a b c : ℤ} {ζ : R} (hp5 : 5 ≤ p) (hreg : IsRegularPrime p)
    (hζ : IsPrimitiveRoot ζ p) (hgcd : ({a, b, c} : Finset ℤ).gcd id = 1) (caseI : ¬↑p ∣ a * b * c)
    (H : a ^ p + b ^ p = c ^ p) :
    ∃ k₁ k₂ : Fin p,
      k₂ ≡ k₁ - 1 [ZMOD p] ∧ ↑p ∣ ↑a + ↑b * ζ - ↑a * ζ ^ (k₁ : ℕ) - ↑b * ζ ^ (k₂ : ℕ) := by
  sorry

/-- Case I with additional assumptions. -/
theorem caseI_easier {a b c : ℤ} (hreg : IsRegularPrime p) (hp5 : 5 ≤ p)
    (hgcd : ({a, b, c} : Finset ℤ).gcd id = 1) (hab : ¬a ≡ b [ZMOD p]) (caseI : ¬↑p ∣ a * b * c) :
    a ^ p + b ^ p ≠ c ^ p := by
  sorry

/-- CaseI. -/
theorem caseI {a b c : ℤ} {p : ℕ} [Fact p.Prime] (hreg : IsRegularPrime p)
    (caseI : ¬↑p ∣ a * b * c) : a ^ p + b ^ p ≠ c ^ p := by
  sorry

end FltRegular
