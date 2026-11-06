module

public import Mathlib.NumberTheory.Cyclotomic.Basic
import FltRegular.NumberTheory.Cyclotomic.CyclRat
import Mathlib.Analysis.SpecialFunctions.Gamma.Basic
import Mathlib.CategoryTheory.Category.Init
import Mathlib.Data.Nat.Factorial.DoubleFactorial

@[expose] public section

open Finset Nat IsCyclotomicExtension Ideal Polynomial Int Basis

open scoped NumberField

namespace FltRegular

variable {p : ℕ} (hpri : p.Prime)

local notation "K" => CyclotomicField p ℚ

local notation "R" => 𝓞 K

namespace CaseI

theorem two_lt (hp5 : 5 ≤ p) : 2 < p := by linarith

section Zerok₁

theorem aux_cong0k₁ {k : Fin p} (hcong : k ≡ -1 [ZMOD p]) :
    k = ⟨p.pred, pred_lt hpri.ne_zero⟩ := by
  refine Fin.ext ?_
  rw [Fin.val_mk, ← ZMod.val_cast_of_lt (Fin.is_lt k)]
  suffices ((k : ℤ) : ZMod p).val = p.pred by simpa
  rw [← ZMod.intCast_eq_intCast_iff] at hcong
  rw [hcong, cast_neg, Int.cast_one, pred_eq_sub_one]
  haveI : NeZero p := ⟨hpri.ne_zero⟩
  haveI : Fact p.Prime := ⟨hpri⟩
  haveI : Fact (1 < p) := ⟨hpri.one_lt⟩
  simp [ZMod.neg_val, ZMod.val_one]

/-- Auxiliary function. -/
def f0k₁ (b : ℤ) (p : ℕ) : ℕ → ℤ := fun x => if x = 1 then b else if x = p.pred then -b else 0

theorem auxf0k₁ (hp5 : 5 ≤ p) (b : ℤ) : ∃ i : Fin p, f0k₁ b p (i : ℕ) = 0 := by
  refine ⟨⟨2, two_lt hp5⟩, ?_⟩
  have hpred : ((⟨2, two_lt hp5⟩ : Fin p) : ℕ) ≠ p.pred := by
    intro h
    simp only at h
    rw [Nat.pred_eq_sub_one] at h
    omega
  simp only [f0k₁, OfNat.ofNat_ne_one, ite_false, ite_eq_right_iff, neg_eq_zero]
  intro h2
  exfalso
  apply hpred
  simp [h2]

include hpri in
theorem aux0k₁ {a b c : ℤ} {ζ : R} (hp5 : 5 ≤ p) (hζ : IsPrimitiveRoot ζ p)
    (caseI : ¬↑p ∣ a * b * c) {k₁ k₂ : Fin p} (hcong : k₂ ≡ k₁ - 1 [ZMOD p])
    (hdiv : ↑p ∣ ↑a + ↑b * ζ - ↑a * ζ ^ (k₁ : ℕ) - ↑b * ζ ^ (k₂ : ℕ)) : 0 ≠ (k₁ : ℕ) := by
  symm
  intro habs
  rw [show (k₁ : ℤ) = 0 by simpa using habs, zero_sub] at hcong
  rw [habs, _root_.pow_zero, mul_one, add_sub_cancel_left, aux_cong0k₁ hpri hcong] at hdiv
  nth_rw 1 [show ζ = ζ ^ ((⟨1, hpri.one_lt⟩ : Fin p) : ℕ) by simp] at hdiv
  have key : ↑(p : ℤ) ∣ ∑ j ∈ range p, f0k₁ b p j • ζ ^ j := by
    convert hdiv using 1
    have h : 1 ≠ p.pred := fun h => by linarith [pred_eq_succ_iff.1 h.symm]
    simp_rw [f0k₁, ite_smul, sum_ite, filter_filter, ← Ne.eq_def, ne_and_eq_iff_right h,
      Finset.range_filter_eq]
    simp [hpri.one_lt, Nat.sub_lt hpri.pos, sub_eq_add_neg]
  rw [sum_range] at key
  refine caseI (Dvd.dvd.mul_right (Dvd.dvd.mul_left ?_ _) _)
  have : NeZero p := ⟨hpri.ne_zero⟩
  simpa [f0k₁] using dvd_coeff_cycl_integer hpri hζ (auxf0k₁ hp5 b) key ⟨1, hpri.one_lt⟩

end Zerok₁


end CaseI

end FltRegular
