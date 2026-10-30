module

public import Mathlib.Algebra.GCDMonoid.Finset
public import Mathlib.Algebra.GCDMonoid.Nat
public import Mathlib.Data.Int.ModEq
public import Mathlib.Data.Nat.Prime.Defs
import Mathlib.FieldTheory.Finite.Basic

@[expose] public section

open Int Finset

namespace FltRegular

namespace MayAssume

theorem coprime {a b c : ℤ} {n : ℕ} (H : a ^ n + b ^ n = c ^ n) (hprod : a * b * c ≠ 0) :
    letI d := ({a, b, c} : Finset ℤ).gcd id
    (a / d) ^ n + (b / d) ^ n = (c / d) ^ n ∧
      ({a / d, b / d, c / d} : Finset ℤ).gcd id = 1 ∧ a / d * (b / d) * (c / d) ≠ 0 := by
  sorry

end MayAssume

theorem p_dvd_c_of_ab_of_anegc {p : ℕ} {a b c : ℤ} (hpri : p.Prime) (hp : p ≠ 3)
    (h : a ^ p + b ^ p = c ^ p) (hab : a ≡ b [ZMOD p]) (hbc : b ≡ -c [ZMOD p]) : ↑p ∣ c := by
  sorry

theorem a_not_cong_b {p : ℕ} {a b c : ℤ} (hpri : p.Prime) (hp5 : 5 ≤ p) (hprod : a * b * c ≠ 0)
    (h : a ^ p + b ^ p = c ^ p) (hgcd : ({a, b, c} : Finset ℤ).gcd id = 1)
    (caseI : ¬↑p ∣ a * b * c) :
    ∃ x y z : ℤ, x ^ p + y ^ p = z ^ p ∧
      ({x, y, z} : Finset ℤ).gcd id = 1 ∧ ¬x ≡ y [ZMOD p] ∧ x * y * z ≠ 0 ∧ ¬↑p ∣ x * y * z := by
  sorry

end FltRegular
